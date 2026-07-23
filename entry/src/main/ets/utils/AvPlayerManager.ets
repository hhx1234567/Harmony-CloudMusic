import { media } from '@kit.MediaKit'
import { GlobalMusic } from '../models/globalMusic'
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { sessionManager } from './AvSessionManager'

class AvPlayerManager {
  player: media.AVPlayer | null = null
  currentSong: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  private playOperationSequence: number = 0

  async init(): Promise<boolean> {
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
    const index = this.currentSong.playIndex
    if (this.currentSong.playList.length === 0 || index < 0 || index >= this.currentSong.playList.length) {
      return null
    }
    return this.currentSong.playList[index]
  }

  private copySong(song: SongItemType): SongItemType {
    return {
      id: song.id,
      name: song.name,
      author: song.author,
      img: song.img,
      url: song.url
    }
  }

  private upsertPlayListSong(targetSong: SongItemType): number {
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
    action.then((applied: boolean) => {
      if (!applied) {
        console.info(`[AvPlayerManager] ${source}未应用`)
      }
    }).catch((err: Error) => {
      console.error(`[AvPlayerManager] ${source}异常：` + JSON.stringify(err))
    })
  }

  async singPlay(song: SongItemType): Promise<boolean> {
    const operationId = ++this.playOperationSequence
    console.info(`[PlayerOperation][${operationId}] 收到播放请求`)

    const player = this.player
    if (!player) {
      console.error(`[PlayerOperation][${operationId}] 播放器尚未初始化`)
      return false
    }
    if (!song) {
      console.error(`[PlayerOperation][${operationId}] 歌曲数据为空`)
      return false
    }
    if (!song.url || !song.url.trim()) {
      console.error(`[PlayerOperation][${operationId}] 歌曲URL为空：${song.name}`)
      return false
    }

    const targetSong = this.copySong(song)

    try {
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

    if (this.currentSong.url === targetSong.url) {
      if (!this.playPlayer(player, `[PlayerOperation][${operationId}] 恢复当前歌曲`)) {
        return false
      }
      const targetIndex = this.upsertPlayListSong(targetSong)
      this.currentSong.playIndex = targetIndex
      this.currentSong.img = targetSong.img
      this.currentSong.name = targetSong.name
      this.currentSong.author = targetSong.author
      this.currentSong.url = targetSong.url
      console.info(`[PlayerOperation][${operationId}] 同一资源无需reset，已恢复播放`)
      return true
    }

    const applied = await this.changeSong(targetSong, operationId)
    if (operationId !== this.playOperationSequence) {
      console.info(`[PlayerOperation][${operationId}] changeSong执行期间操作已过期`)
      return false
    }
    return applied
  }

  private async changeSong(targetSong: SongItemType, operationId: number): Promise<boolean> {
    const player = this.player
    if (!player) {
      console.error(`[PlayerOperation][${operationId}] 切歌时播放器不可用`)
      return false
    }

    console.info(`[PlayerOperation][${operationId}] 开始reset：${targetSong.name}`)
    try {
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
      player.url = targetSong.url
    } catch (err) {
      console.error(`[PlayerOperation][${operationId}] 设置播放器URL失败：` + JSON.stringify(err))
      return false
    }

    const latestIndex = this.upsertPlayListSong(targetSong)
    this.currentSong.playIndex = latestIndex
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

  async prevPlay(): Promise<boolean> {
    const playList = this.currentSong.playList
    if (playList.length === 0) {
      console.info('[AvPlayerManager] 播放列表为空，忽略上一首')
      return false
    }

    const currentIndex = this.getCurrentPlayListSong() ? this.currentSong.playIndex : 0
    let targetIndex: number
    if (this.currentSong.playMode === 'random') {
      targetIndex = Math.floor(Math.random() * playList.length)
    } else {
      targetIndex = currentIndex > 0 ? currentIndex - 1 : playList.length - 1
    }
    return await this.singPlay(playList[targetIndex])
  }

  async nextPlay(autoNextPlay: boolean = false): Promise<boolean> {
    const playList = this.currentSong.playList
    if (playList.length === 0) {
      console.info('[AvPlayerManager] 播放列表为空，忽略下一首')
      return false
    }

    const currentIndex = this.getCurrentPlayListSong() ? this.currentSong.playIndex : 0
    let targetIndex: number
    if (this.currentSong.playMode === 'repeat' && autoNextPlay) {
      targetIndex = currentIndex
    } else if (this.currentSong.playMode === 'random') {
      targetIndex = Math.floor(Math.random() * playList.length)
    } else {
      targetIndex = (currentIndex + 1) % playList.length
    }
    return await this.singPlay(playList[targetIndex])
  }

  async removeSong(index: number): Promise<boolean> {
    const playList = this.currentSong.playList
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
      playList.splice(index, 1)
      if (index < this.currentSong.playIndex) {
        this.currentSong.playIndex--
      }
      return true
    }

    if (playList.length > 1) {
      playList.splice(index, 1)
      const targetIndex = index >= playList.length ? 0 : index
      const targetSong = playList[targetIndex]
      return await this.singPlay(targetSong)
    }

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

    this.currentSong.reset()
    console.info(`[PlayerOperation][${operationId}] 播放列表已安全清空`)
    return true
  }

  async release(): Promise<void> {
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
