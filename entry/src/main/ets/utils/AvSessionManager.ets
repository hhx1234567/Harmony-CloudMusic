import { avSession } from '@kit.AVSessionKit'
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager'
import { wantAgent } from '@kit.AbilityKit';
import { SongItemType } from '../models/music';
import { GlobalMusic } from '../models/globalMusic';
import { AppStorageV2 } from '@kit.ArkUI';
import { playerManager } from './AvPlayerManager';
import { common } from '@kit.MDMKit';

class AvSessionManager {
  session: avSession.AVSession | null = null
  //拿到当前播放歌曲的数据
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  private context: Context | null = null
  private isTaskRunning: boolean = false

  //init只在APP启动时调用一次
  async  init(content: Context) {
    this.context = content
    this.session = await avSession.createAVSession(content, 'bgPlay', 'audio') //向系统申请创建一个叫bgPlay的音频会话
    //关键代码
    this.session?.activate() //告诉系统已准备好接管媒体控制中心
    this.registerEvent() //装上接听系统指令的专线电话
  }

  //申请长时任务
  async  startBackgroundTask() {
    //核心防御：如果已经办过通行证了，直接退回
    if (this.isTaskRunning) {
      console.info('[AvSessionManager] 🛡️ 后台长时任务已在运行，拦截重复申请')
      return
    }
    if (!this.context) return
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName: 'com.example.mymusic',
          abilityName: 'EntryAbility'
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      // 车钥匙长时任务子类型，从API version 16开始支持。只有申请bluetoothInteraction类型的长时任务，车钥匙子类型才能生效。
      // 确保extraInfo参数中的Key值为backgroundTaskManager.BackgroundModeType.SUB_MODE，否则子类型不生效。
      // extraInfo: {
      // [backgroundTaskManager.BackgroundModeType.SUB_MODE] :backgroundTaskManager.BackgroundSubMode.CAR_KEY
      // }
    };
    const want = await wantAgent.getWantAgent(wantAgentInfo)
    //调用方法，核心参数是AUDIO_PLAYBACK，系统看到后会明白这是音乐软件，破例让你在后台消耗CPU和网络
    backgroundTaskManager.startBackgroundRunning(this.context, backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK, want) .then(() => {
      console.info('👉👉👉 [BackgroundTask] 长时任务运行中！')
    }).catch((err: Error) => {
      // 🔪 把 err 转成字符串，看里面有没有 9800005 这个数字
      if (JSON.stringify(err).includes('9800005')) {
        console.info('👉👉👉 [BackgroundTask] 长时任务已存在，无需重复申请。')
      } else {
        console.error('❌❌❌ [BackgroundTask] 失败：', JSON.stringify(err))
      }
    })
    this.isTaskRunning = true
    console.info('[AvSessionManager] ✅ 后台长时任务申请成功')
  }

  //设置元数据，把静态情报推给锁屏控制中心
  setAVMetadata (song: SongItemType) {
    this.session?.setAVMetadata({
      assetId: song.id,        // ID
      title: song.name,       // 歌名
      artist: song.author,        // 歌手
      mediaImage: song.img, //歌曲封面，不能传递几兆的高清大图，这是跨进程通信（IPC），如果传递的话会瞬间撑爆系统的共享内存通道（ashmem），导致App闪退
      duration: this.playState.duration //总时长，只有在刚切歌或者获取到歌曲总时长时才会调用一次
    }).then(() => {
      console.info('👉👉👉 [AVSession] 元数据(测试版)推流成功！')
    }).catch((err: Error) => {
      console.error('❌❌❌ [AVSession] 元数据推流失败：', JSON.stringify(err))
    })
  }

  //设置播放状态，把当前播放器的实时动态推给锁屏控制中心；每次暂停，恢复播放，拖拽进度都必须调用它
  setAVPlayBackState () {
    this.session?.setAVPlaybackState({
      state: this.playState.isPlay ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      speed: 1,
      position: {
        elapsedTime: this.playState.time,  //歌曲播放时间
        updateTime: new Date().getTime()  //系统时间
      },
      duration: this.playState.duration
    }).then(() => {
      console.info('👉👉👉 [AVSession] 播放状态推流成功！当前状态：', this.playState.isPlay ? '播放' : '暂停')
    }).catch((err: Error) => {
      console.error('❌❌❌ [AVSession] 状态设置失败：', JSON.stringify(err))
    })
  }

  //注册事件，监听用户在锁屏界面或蓝牙耳机上按下的操作，并反向控制App
  registerEvent () {
    this.session?.on('play', () => {
      playerManager.resumePlay()
    })
    this.session?.on('pause', () => {
      playerManager.paused()
    })
    this.session?.on('playPrevious', () => {
      playerManager.prevPlay()
    })
    this.session?.on('playNext', () => {
      playerManager.nextPlay()
    })
    this.session?.on('seek', (value: number) => {
      this.playState.time = value
      this.setAVPlayBackState()
      playerManager.seekPlay(value)
    })
    this.session?.activate()
  }
  //注销长时任务并解锁
  async stopBackgroundTask() {
    if (!this.isTaskRunning || !this.context) return
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      this.isTaskRunning = false
      console.info('[AvSessionManager] 🛑 后台长时任务已安全注销，状态已解锁')
    } catch (err) {
      console.error('❌❌❌ [AvSessionManager] 注销后台任务失败：', JSON.stringify(err))
    }
  }
  //注销会话
  async  destroy () {
    //停止后台长时任务（同时会自动把 isTaskRunning 置为 false）
    await this.stopBackgroundTask()
    // 2. 销毁控制中心的卡片会话
    await this.session?.destroy()
    this.session = null
    console.info('[AvSessionManager] 🗑️ 会话与底层资源已彻底清理')
  }
}


export const sessionManager: AvSessionManager = new AvSessionManager()