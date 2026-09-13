import { avSession } from '@kit.AVSessionKit'
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager'
import { wantAgent } from '@kit.AbilityKit'
import { SongItemType } from '../models/music'
import { GlobalMusic } from '../models/globalMusic'
import { AppStorageV2 } from '@kit.ArkUI'
import { playerManager } from './AvPlayerManager'

class AvSessionManager {
  // AVSession 负责锁屏卡片、蓝牙耳机等系统播控；它不直接保存音频，只转发控制指令。
  session: avSession.AVSession | null = null
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  private context: Context | null = null
  // 这个值必须反映系统任务的真实结果，申请失败时不能“假装已经运行”。
  private isTaskRunning: boolean = false
  private isSessionActive: boolean = false

  async init(context: Context): Promise<boolean> {
    // 保存 Ability 的 Context，之后申请/停止后台长时任务都需要它。
    this.context = context
    if (this.session) {
      return await this.activateSession()
    }

    try {
      const session = await avSession.createAVSession(context, 'bgPlay', 'audio')
      this.session = session
      await session.activate()
      this.isSessionActive = true
      if (!this.registerEvent(session)) {
        await session.destroy()
        this.session = null
        return false
      }
      console.info('[AvSessionManager] AVSession初始化成功')
      return true
    } catch (err) {
      this.session = null
      this.isSessionActive = false
      console.error('[AvSessionManager] AVSession初始化失败：' + JSON.stringify(err))
      return false
    }
  }

  private async activateSession(): Promise<boolean> {
    let session = this.session
    if (!session) {
      const context = this.context
      if (!context) {
        return false
      }
      // 播放列表清空时会销毁旧会话以移除系统缓存卡片；下一次播放在这里自动重建。
      return await this.init(context)
    }
    if (this.isSessionActive) {
      return true
    }

    try {
      await session.activate()
      this.isSessionActive = true
      console.info('[AvSessionManager] AVSession已重新激活')
      return true
    } catch (err) {
      console.error('[AvSessionManager] AVSession激活失败：' + JSON.stringify(err))
      return false
    }
  }

  async startBackgroundTask(): Promise<boolean> {
    // 清空播放列表时会停用会话；再次播放前必须重新激活，系统媒体卡片才能重新出现。
    if (!await this.activateSession()) {
      console.info('[AvSessionManager] AVSession未激活，无法启动完整后台播放能力')
      return false
    }
    // 已成功申请过时直接复用，避免每次点歌都向系统重复申请。
    if (this.isTaskRunning) {
      console.info('[AvSessionManager] 后台长时任务已在运行，拦截重复申请')
      return true
    }
    if (!this.context) {
      console.info('[AvSessionManager] Context尚未初始化，无法申请后台长时任务')
      return false
    }

    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: 'com.huanghongxin.mymusic',
          abilityName: 'EntryAbility'
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    }

    try {
      // WantAgent 描述用户点击后台播放通知后，系统应重新打开哪个 Ability。
      const notificationWant = await wantAgent.getWantAgent(wantAgentInfo)
      await backgroundTaskManager.startBackgroundRunning(
        this.context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
        notificationWant
      )
      this.isTaskRunning = true
      console.info('[AvSessionManager] 后台长时任务申请成功')
      return true
    } catch (err) {
      // 9800005 表示系统中已经存在同类任务，此时“正在运行”仍然是真实状态。
      if (JSON.stringify(err).includes('9800005')) {
        this.isTaskRunning = true
        console.info('[AvSessionManager] 后台长时任务已存在，保持运行状态')
        return true
      }
      // 其他错误都代表申请没有成功，必须保持 false，下一次播放才能重试。
      this.isTaskRunning = false
      console.error('[AvSessionManager] 后台长时任务申请失败：' + JSON.stringify(err))
      return false
    }
  }

  setAVMetadata(song: SongItemType): void {
    // 元数据是锁屏界面显示的歌名、歌手、封面和时长；没有会话时安静跳过。
    const session = this.session
    if (!session || !song) {
      return
    }

    try {
      session.setAVMetadata({
        assetId: song.id,
        title: song.name,
        artist: song.author,
        mediaImage: song.img,
        duration: this.playState.duration
      }).then(() => {
        console.info('[AVSession] 元数据推流成功')
      }).catch((err: Error) => {
        console.error('[AVSession] 元数据推流失败：' + JSON.stringify(err))
      })
    } catch (err) {
      console.error('[AVSession] 设置元数据异常：' + JSON.stringify(err))
    }
  }

  setAVPlayBackState(): void {
    // 播放状态包含播放/暂停、当前进度和总时长，供系统控制中心展示。
    const session = this.session
    if (!session) {
      return
    }

    try {
      session.setAVPlaybackState({
        state: this.playState.isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY :
          avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
        speed: 1,
        position: {
          elapsedTime: this.playState.time,
          updateTime: new Date().getTime()
        },
        duration: this.playState.duration
      }).then(() => {
        console.info('[AVSession] 播放状态推流成功')
      }).catch((err: Error) => {
        console.error('[AVSession] 播放状态推流失败：' + JSON.stringify(err))
      })
    } catch (err) {
      console.error('[AVSession] 设置播放状态异常：' + JSON.stringify(err))
    }
  }

  private handlePlaybackAction(action: Promise<boolean>, source: string): void {
    // AVSession 的事件回调本身不是 async，这里负责接住上一首/下一首返回的 Promise。
    action.then((applied: boolean) => {
      if (!applied) {
        console.info(`[AVSession] ${source}未应用`)
      }
    }).catch((err: Error) => {
      console.error(`[AVSession] ${source}异常：` + JSON.stringify(err))
    })
  }

  private registerEvent(session: avSession.AVSession): boolean {
    try {
      // 系统按钮最终仍调用 AvPlayerManager，让所有入口共享同一套操作序列和边界保护。
      session.on('play', () => {
        playerManager.resumePlay()
      })
      session.on('pause', () => {
        playerManager.paused()
      })
      session.on('playPrevious', () => {
        this.handlePlaybackAction(playerManager.prevPlay(), '系统上一首')
      })
      session.on('playNext', () => {
        this.handlePlaybackAction(playerManager.nextPlay(), '系统下一首')
      })
      session.on('seek', (value: number) => {
        this.playState.time = value
        this.setAVPlayBackState()
        playerManager.seekPlay(value)
      })
      return true
    } catch (err) {
      console.error('[AvSessionManager] 系统播控事件注册失败：' + JSON.stringify(err))
      return false
    }
  }

  async stopBackgroundTask(): Promise<boolean> {
    // 没有运行中的任务时无需调用系统 API，可直接视为已经停止。
    if (!this.isTaskRunning) {
      return true
    }
    if (!this.context) {
      return false
    }

    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      // 只有系统确认停止后才解锁状态；失败时保留 true，避免错误地重复申请。
      this.isTaskRunning = false
      console.info('[AvSessionManager] 后台长时任务已注销')
      return true
    } catch (err) {
      console.error('[AvSessionManager] 注销后台任务失败：' + JSON.stringify(err))
      return false
    }
  }

  async clearPlayback(): Promise<boolean> {
    let cleared: boolean = true
    const session = this.session

    if (session) {
      try {
        // 先把状态切到停止，再销毁会话。仅 deactivate 会让部分系统继续展示“最近播放”卡片。
        await session.setAVPlaybackState({
          state: avSession.PlaybackState.PLAYBACK_STATE_STOP,
          speed: 1,
          position: {
            elapsedTime: 0,
            updateTime: new Date().getTime()
          },
          duration: 0
        })
        await session.destroy()
        this.session = null
        this.isSessionActive = false
        console.info('[AvSessionManager] 播放状态已清空，AVSession已销毁')
      } catch (err) {
        cleared = false
        console.error('[AvSessionManager] 清空播放会话失败：' + JSON.stringify(err))
      }
    }

    if (!await this.stopBackgroundTask()) {
      cleared = false
    }
    return cleared
  }

  async destroy(): Promise<void> {
    // 先停止后台任务，再销毁系统媒体会话，顺序与初始化相反。
    await this.stopBackgroundTask()
    const session = this.session
    if (!session) {
      return
    }

    try {
      await session.destroy()
      console.info('[AvSessionManager] AVSession资源已释放')
    } catch (err) {
      console.error('[AvSessionManager] AVSession释放失败：' + JSON.stringify(err))
    } finally {
      this.session = null
      this.isSessionActive = false
    }
  }
}

export const sessionManager: AvSessionManager = new AvSessionManager()
