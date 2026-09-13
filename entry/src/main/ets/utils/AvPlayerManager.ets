import { media } from '@kit.MediaKit'
import { GlobalMusic } from '../models/globalMusic'
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { sessionManager } from './AvSessionManager'
import { PlaybackQueueContext, PlaybackQueuePolicy } from './PlaybackQueuePolicy'
import { getSongRealUrl } from '../services/MusicService'
import { SongPlaybackResolver } from './SongPlaybackResolver'

class AvPlayerManager {
  // AVPlayer 是真正播放声音的系统对象；GlobalMusic 是页面正在观察的共享 UI 状态。
  // 两者必须在同一次有效操作中一起更新，否则就会出现“页面显示 B，声音却还是 A”。
  player: media.AVPlayer | null = null
  currentSong: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  // 播放器自己的“取号机”。它覆盖发现页、动态页、播放列表、上下首和系统播控等所有入口。
  private playOperationSequence: number = 0

  async init(): Promise<boolean> {
    // 已创建时直接复用，避免重复创建系统播放器和重复注册监听。
    if (this.player) {
      return true
    }

    try {
      const player = await media.createAVPlayer()
      this.player = player
      if (!this.registerPlayerEvents(player)) {
        await player.release()
        this.player = null
        return false
      }
      console.info('[AvPlayerManager] 播放器初始化成功')
      return true
    } catch (err) {
      this.player = null
      console.error('[AvPlayerManager] 播放器初始化失败：' + JSON.stringify(err))
      return false
    }
  }

  private registerPlayerEvents(player: media.AVPlayer): boolean {
    try {
      player.on('stateChange', (state: string) => {
        // AVPlayer 采用状态驱动：设置 url 后会进入 initialized，prepare 完成后进入 prepared。
        switch (state) {
          case 'initialized':
            player.prepare().catch((err: Error) => {
              console.error('[AvPlayerManager] prepare失败：' + JSON.stringify(err))
            })
            break
          case 'prepared':
            this.playPlayer(player, 'prepared状态自动播放')
            break
          case 'playing':
            this.currentSong.isPlay = true
            sessionManager.setAVPlayBackState()
            break
          case 'paused':
            this.currentSong.isPlay = false
            sessionManager.setAVPlayBackState()
            break
          case 'completed':
            this.handlePlaybackAction(this.nextPlay(true), '自动下一首')
            break
          case 'released':
            this.currentSong.reset()
            break
          default:
            console.info(`[AvPlayerManager] 未处理的播放器状态: ${state}`)
            break
        }
      })

      player.on('durationUpdate', (duration: number) => {
        // 回调可能在清空列表或切歌期间到达，所以访问 playList[playIndex] 前必须先检查边界。
        const song = this.getCurrentPlayListSong()
        if (!song) {
          console.info('[AvPlayerManager] 播放列表为空或索引无效，忽略durationUpdate元数据')
          return
        }
        this.currentSong.duration = duration
        sessionManager.setAVMetadata(song)
      })

      player.on('timeUpdate', (time: number) => {
        if (!this.getCurrentPlayListSong()) {
          return
        }
        this.currentSong.time = time
      })
      return true
    } catch (err) {
      console.error('[AvPlayerManager] 播放器事件注册失败：' + JSON.stringify(err))
      return false
    }
  }

  private getCurrentPlayListSong(): SongItemType | null {
    // 把容易遗漏的“空列表 + 索引越界”判断集中在一个方法里。
    const index = this.currentSong.playIndex
    if (this.currentSong.playList.length === 0 || index < 0 || index >= this.currentSong.playList.length) {
      return null
    }
    return this.currentSong.playList[index]
  }

  private copySong(song: SongItemType): SongItemType {
    // 播放器保存自己的快照，不持有页面缓存对象，避免某一层修改 URL 时连带污染另一层。
    return {
      id: song.id,
      name: song.name,
      author: song.author,
      img: song.img,
      url: song.url
    }
  }

  private upsertPlayListSong(targetSong: SongItemType): number {
    // 同一歌曲已在列表中时替换整条快照，从而更新刚获取到的真实 URL；不存在才插入。
    const targetIndex = this.currentSong.playList.findIndex(
      (item: SongItemType) => item.id === targetSong.id
    )
    if (targetIndex >= 0) {
      this.currentSong.playList.splice(targetIndex, 1, targetSong)
      return targetIndex
    }

    this.currentSong.playList.unshift(targetSong)
    return 0
  }

  private applyPlayContext(targetSong: SongItemType, sourceList?: SongItemType[]): number {
    if (!sourceList || sourceList.length === 0) {
      return this.upsertPlayListSong(targetSong)
    }

    const context: PlaybackQueueContext = PlaybackQueuePolicy.buildContext(sourceList, targetSong)
    this.currentSong.playList = context.playList
    return context.targetIndex
  }

  private playPlayer(player: media.AVPlayer, source: string): boolean {
    try {
      player.play()
      return true
    } catch (err) {
      console.error(`[AvPlayerManager] ${source}失败：` + JSON.stringify(err))
      return false
    }
  }

  private handlePlaybackAction(action: Promise<boolean>, source: string): void {
    // 状态回调不能直接 await，因此在这里统一接住 Promise，避免异常变成未处理的 Promise。
    action.then((applied: boolean) => {
      if (!applied) {
        console.info(`[AvPlayerManager] ${source}未应用`)
      }
    }).catch((err: Error) => {
      console.error(`[AvPlayerManager] ${source}异常：` + JSON.stringify(err))
    })
  }

  async singPlay(song: SongItemType, sourceList?: SongItemType[]): Promise<boolean> {
    // 每个入口一进入这里就取新号码；后来的操作天然淘汰先前仍在等待的操作。
    const operationId = ++this.playOperationSequence
    console.info(`[PlayerOperation][${operationId}] 收到播放请求`)

    // 在发生任何耗时操作前先验证播放器和参数，失败时不碰播放列表与全局状态。
    const player = this.player
    if (!player) {
      console.error(`[PlayerOperation][${operationId}] 播放器尚未初始化`)
      return false
    }
    if (!song) {
      console.error(`[PlayerOperation][${operationId}] 歌曲数据为空`)
      return false
    }
    // 在线歌单只为用户首次点击的歌曲解析 URL；上下首、系统播控和列表点击可能拿到空 URL。
    // 所有入口都在播放器层按需补齐地址，避免只有发现页能够播放在线歌曲。
    const targetSong = await SongPlaybackResolver.resolve(song, getSongRealUrl)
    if (operationId !== this.playOperationSequence) {
      console.info(`[PlayerOperation][${operationId}] URL解析期间操作已过期：${song.name}`)
      return false
    }
    if (!targetSong) {
      console.error(`[PlayerOperation][${operationId}] 歌曲URL不可用：${song.name}`)
      return false
    }

    try {
      // 后台任务申请是异步的，等待结束后必须确认当前号码仍然最新。
      const backgroundTaskReady = await sessionManager.startBackgroundTask()
      if (operationId !== this.playOperationSequence) {
        console.info(`[PlayerOperation][${operationId}] 后台任务等待期间操作已过期`)
        return false
      }
      if (!backgroundTaskReady) {
        console.info(`[PlayerOperation][${operationId}] 后台任务未启动，继续前台播放`)
      }
    } catch (err) {
      if (operationId !== this.playOperationSequence) {
        console.info(`[PlayerOperation][${operationId}] 后台任务异常后操作已过期`)
        return false
      }
      console.error(`[PlayerOperation][${operationId}] 后台任务异常：` + JSON.stringify(err))
    }

    // 当前 URL 完全相同时只恢复播放，不做 reset，避免声音被无意义地中断。
    if (this.currentSong.url === targetSong.url) {
      if (!this.playPlayer(player, `[PlayerOperation][${operationId}] 恢复当前歌曲`)) {
        return false
      }
      const targetIndex = this.applyPlayContext(targetSong, sourceList)
      this.currentSong.playIndex = targetIndex
      this.currentSong.id = targetSong.id
      this.currentSong.img = targetSong.img
      this.currentSong.name = targetSong.name
      this.currentSong.author = targetSong.author
      this.currentSong.url = targetSong.url
      console.info(`[PlayerOperation][${operationId}] 同一资源无需reset，已恢复播放`)
      return true
    }

    // 真正切歌交给 changeSong；返回后再检查一次，覆盖 changeSong 整段等待时间。
    const applied = await this.changeSong(targetSong, operationId, sourceList)
    if (operationId !== this.playOperationSequence) {
      console.info(`[PlayerOperation][${operationId}] changeSong执行期间操作已过期`)
      return false
    }
    return applied
  }

  private async changeSong(
    targetSong: SongItemType,
    operationId: number,
    sourceList?: SongItemType[]
  ): Promise<boolean> {
    // 保存局部 player 引用，确保这一轮操作始终针对开始时验证过的系统对象。
    const player = this.player
    if (!player) {
      console.error(`[PlayerOperation][${operationId}] 切歌时播放器不可用`)
      return false
    }

    console.info(`[PlayerOperation][${operationId}] 开始reset：${targetSong.name}`)
    try {
      // reset 是关键异步边界。它完成前绝不能先把页面状态改成目标歌曲。
      await player.reset()
    } catch (err) {
      console.error(`[PlayerOperation][${operationId}] reset失败：` + JSON.stringify(err))
      return false
    }

    if (operationId !== this.playOperationSequence) {
      console.info(`[PlayerOperation][${operationId}] reset完成后操作已过期，丢弃：${targetSong.name}`)
      return false
    }

    try {
      // 先把 URL 真正交给播放器；设置失败时 GlobalMusic 仍保持旧歌曲，不会“假切歌”。
      player.url = targetSong.url
    } catch (err) {
      console.error(`[PlayerOperation][${operationId}] 设置播放器URL失败：` + JSON.stringify(err))
      return false
    }

    // 从这里到方法返回之间没有 await，不会被另一轮点击插入；可以一次性提交 UI 状态。
    const latestIndex = this.applyPlayContext(targetSong, sourceList)
    this.currentSong.playIndex = latestIndex
    this.currentSong.id = targetSong.id
    this.currentSong.duration = 0
    this.currentSong.time = 0
    this.currentSong.img = targetSong.img
    this.currentSong.name = targetSong.name
    this.currentSong.author = targetSong.author
    this.currentSong.url = targetSong.url

    console.info(`[PlayerOperation][${operationId}] 已应用最新URL：${targetSong.name}`)
    return true
  }

  seekPlay(value: number): void {
    try {
      this.player?.seek(value)
    } catch (err) {
      console.error('[AvPlayerManager] seek失败：' + JSON.stringify(err))
    }
  }

  paused(): void {
    try {
      this.player?.pause()
    } catch (err) {
      console.error('[AvPlayerManager] 暂停失败：' + JSON.stringify(err))
    }
  }

  private async findFirstPlayableSong(candidateIndices: number[], source: string): Promise<SongItemType | null> {
    // 一次“上一首/下一首”只领取一个筛选序号；解析多个候选期间若出现新操作，立即停止搜索。
    const selectionId = ++this.playOperationSequence
    for (let attempt: number = 0; attempt < candidateIndices.length; attempt++) {
      const targetIndex = candidateIndices[attempt]
      const candidate = this.currentSong.playList[targetIndex]
      if (!candidate) {
        continue
      }

      const resolvedSong = await SongPlaybackResolver.resolve(candidate, getSongRealUrl)
      if (selectionId !== this.playOperationSequence) {
        console.info(`[PlayerOperation][${selectionId}] ${source}候选解析期间操作已过期`)
        return null
      }
      if (resolvedSong) {
        if (attempt > 0) {
          console.info(`[PlayerOperation][${selectionId}] ${source}跳过${attempt}首不可播放歌曲`)
        }
        return resolvedSong
      }
    }

    console.info(`[PlayerOperation][${selectionId}] ${source}没有可播放候选`)
    return null
  }

  async prevPlay(): Promise<boolean> {
    const playList = this.currentSong.playList
    // Math.random() 和数组取值都要求列表非空，因此第一步就做空列表保护。
    if (playList.length === 0) {
      console.info('[AvPlayerManager] 播放列表为空，忽略上一首')
      return false
    }

    // 在线搜索结果可能包含无播放地址歌曲，按逆序尝试直到找到可播放项。
    const candidateIndices = PlaybackQueuePolicy.previousCandidates(
      playList.length,
      this.currentSong.playIndex,
      this.currentSong.playMode
    )
    const targetSong = await this.findFirstPlayableSong(candidateIndices, '上一首')
    return targetSong ? await this.singPlay(targetSong) : false
  }

  async nextPlay(autoNextPlay: boolean = false): Promise<boolean> {
    const playList = this.currentSong.playList
    if (playList.length === 0) {
      console.info('[AvPlayerManager] 播放列表为空，忽略下一首')
      return false
    }

    // 自动播放结束时 repeat 只尝试当前项；其他模式会跳过无地址歌曲寻找下一个可播放项。
    const candidateIndices = PlaybackQueuePolicy.nextCandidates(
      playList.length,
      this.currentSong.playIndex,
      this.currentSong.playMode,
      autoNextPlay
    )
    const targetSong = await this.findFirstPlayableSong(candidateIndices, '下一首')
    return targetSong ? await this.singPlay(targetSong) : false
  }

  async removeSong(index: number): Promise<boolean> {
    const playList = this.currentSong.playList
    // 删除入口可能来自滑动操作，先拒绝空列表和过期索引，避免 splice 或数组访问越界。
    if (playList.length === 0 || index < 0 || index >= playList.length) {
      console.info(`[AvPlayerManager] 删除索引无效：${index}`)
      return false
    }

    const currentIndexValid = this.getCurrentPlayListSong() !== null
    if (!currentIndexValid) {
      playList.splice(index, 1)
      if (playList.length === 0) {
        this.currentSong.reset()
      } else {
        this.currentSong.playIndex = Math.min(index, playList.length - 1)
      }
      return true
    }

    if (index !== this.currentSong.playIndex) {
      // 删除的不是当前歌曲时不需要重置播放器，只需修正受影响的当前索引。
      playList.splice(index, 1)
      if (index < this.currentSong.playIndex) {
        this.currentSong.playIndex--
      }
      return true
    }

    if (playList.length > 1) {
      // 先在副本中计算删除结果，切歌成功时由 singPlay 一次性提交新列表。
      // 如果 reset 或 URL 设置失败，原播放列表仍然保留，不会出现“歌没切成但当前项已消失”。
      const remainingList = playList.map((song: SongItemType) => this.copySong(song))
      remainingList.splice(index, 1)
      const targetIndex = index >= remainingList.length ? 0 : index
      const targetSong = remainingList[targetIndex]
      return await this.singPlay(targetSong, remainingList)
    }

    // 最后一首被删除属于一个新的播放器操作，也要取新号码来淘汰仍在等待的旧切歌。
    const operationId = ++this.playOperationSequence
    const player = this.player
    if (player) {
      try {
        await player.reset()
      } catch (err) {
        console.error(`[PlayerOperation][${operationId}] 清空列表时reset失败：` + JSON.stringify(err))
        return false
      }
      if (operationId !== this.playOperationSequence) {
        console.info(`[PlayerOperation][${operationId}] 清空列表操作已过期`)
        return false
      }
    }

    const playbackCleared = await sessionManager.clearPlayback()
    if (operationId !== this.playOperationSequence) {
      console.info(`[PlayerOperation][${operationId}] 清空媒体会话期间操作已过期`)
      return false
    }
    if (!playbackCleared) {
      console.info(`[PlayerOperation][${operationId}] 系统媒体会话未完全清空，应用列表仍继续重置`)
    }

    this.currentSong.reset()
    console.info(`[PlayerOperation][${operationId}] 播放列表已安全清空`)
    return true
  }

  async release(): Promise<void> {
    // 释放前递增序号，使所有尚未完成的播放操作立即失效。
    ++this.playOperationSequence
    const player = this.player
    if (!player) {
      return
    }

    try {
      player.off('stateChange')
      player.off('durationUpdate')
      player.off('timeUpdate')
      await player.release()
      console.info('[AvPlayerManager] 播放器资源已释放')
    } catch (err) {
      console.error('[AvPlayerManager] 播放器释放失败：' + JSON.stringify(err))
    } finally {
      this.player = null
    }
  }

  resumePlay(): void {
    if (!this.player || this.currentSong.isPlay || !this.getCurrentPlayListSong()) {
      return
    }
    this.playPlayer(this.player, '恢复播放')
  }
}

export const playerManager: AvPlayerManager = new AvPlayerManager()
