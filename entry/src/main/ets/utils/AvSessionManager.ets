import { avSession } from '@kit.AVSessionKit'
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager'
import { wantAgent } from '@kit.AbilityKit'
import { SongItemType } from '../models/music'
import { GlobalMusic } from '../models/globalMusic'
import { AppStorageV2 } from '@kit.ArkUI'
import { playerManager } from './AvPlayerManager'

class AvSessionManager {
  session: avSession.AVSession | null = null
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  private context: Context | null = null
  private isTaskRunning: boolean = false

  async init(context: Context): Promise<boolean> {
    this.context = context
    if (this.session) {
      return true
    }

    try {
      const session = await avSession.createAVSession(context, 'bgPlay', 'audio')
      this.session = session
      await session.activate()
      if (!this.registerEvent(session)) {
        await session.destroy()
        this.session = null
        return false
      }
      console.info('[AvSessionManager] AVSession初始化成功')
      return true
    } catch (err) {
      this.session = null
      console.error('[AvSessionManager] AVSession初始化失败：' + JSON.stringify(err))
      return false
    }
  }

  async startBackgroundTask(): Promise<boolean> {
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
          bundleName: 'com.example.mymusic',
          abilityName: 'EntryAbility'
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    }

    try {
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
      if (JSON.stringify(err).includes('9800005')) {
        this.isTaskRunning = true
        console.info('[AvSessionManager] 后台长时任务已存在，保持运行状态')
        return true
      }
      this.isTaskRunning = false
      console.error('[AvSessionManager] 后台长时任务申请失败：' + JSON.stringify(err))
      return false
    }
  }

  setAVMetadata(song: SongItemType): void {
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
    if (!this.isTaskRunning) {
      return true
    }
    if (!this.context) {
      return false
    }

    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      this.isTaskRunning = false
      console.info('[AvSessionManager] 后台长时任务已注销')
      return true
    } catch (err) {
      console.error('[AvSessionManager] 注销后台任务失败：' + JSON.stringify(err))
      return false
    }
  }

  async destroy(): Promise<void> {
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
    }
  }
}

export const sessionManager: AvSessionManager = new AvSessionManager()
