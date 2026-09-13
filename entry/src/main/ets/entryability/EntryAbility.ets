import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppStorageV2, window } from '@kit.ArkUI';
import { playerManager } from '../utils/AvPlayerManager';
import { sessionManager } from '../utils/AvSessionManager';
import { GlobalMusic } from '../models/globalMusic'
import { musicSettingsRepository } from '../repository/MusicSettingsRepository'
import { musicNotificationService } from '../services/MusicNotificationService'
import { FavoriteMusic } from '../models/favoriteMusic'


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private globalMusic: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  private favoriteMusic: FavoriteMusic = AppStorageV2.connect(
    FavoriteMusic,
    'FAVORITE_SONGS_KEY',
    () => new FavoriteMusic()
  )!
  private async initializeSettings(): Promise<void> {
    await musicSettingsRepository.init(this.context)

    const savedPlayMode = musicSettingsRepository.getPlayMode()

    this.globalMusic.playMode = savedPlayMode
    this.favoriteMusic.songs = musicSettingsRepository.getFavoriteSongs()

    hilog.info(
      DOMAIN,
      'MyMusicSettings',
      'Play mode restored: %{public}s',
      savedPlayMode
    )
  }
  private async initializeAudio(): Promise<void> {
    // 先创建播放器，再创建系统媒体会话；这样系统播控触发时播放器已经具备接收能力。
    const playerReady = await playerManager.init()
    const sessionReady = await sessionManager.init(this.context)
    if (!playerReady || !sessionReady) {
      hilog.error(
        DOMAIN,
        'MyMusicAudio',
        'Audio initialization incomplete. player=%{public}s session=%{public}s',
        playerReady.toString(),
        sessionReady.toString()
      )
    }
  }
  private async initializeApplication(): Promise<void> {
    // 先恢复用户设置，再初始化播放器资源。
    await this.initializeSettings()
    await this.initializeAudio()
  }
  private async releaseAudioResources(): Promise<void> {
    // 与初始化相反：先撤销系统会话和后台任务，再释放真正的播放器。
    await sessionManager.destroy()
    await playerManager.release()
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // EntryAbility 是长期生命周期入口，适合把 UIAbilityContext 统一交给通知 Service。
    // init() 只保存引用：应用启动时不会自动弹权限框，也不会生成测试通知。
    musicNotificationService.init(this.context)
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'MyMusicLifecycle', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'MyMusicLifecycle', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    // Service 是全局单例，不会像页面组件一样自动回收。
    // Ability 销毁时清理 Context，可以避免后续误用已经失效的生命周期对象。
    musicNotificationService.release()
    hilog.info(DOMAIN, 'MyMusicLifecycle', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    // 准备播放器
    // 生命周期方法不能在这里阻塞页面加载，因此启动异步初始化并显式接住异常。
    // 如果用户在初始化完成前点击歌曲，singPlay() 还会用 player null 检查安全拒绝。
    this.initializeApplication().catch((err: Error) => {
      hilog.error(
        DOMAIN,
        'MyMusicInit',
        'Application initialization failed: %{public}s',
        JSON.stringify(err)
      )
    })
    hilog.info(DOMAIN, 'MyMusicLifecycle', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'MyMusicLifecycle', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'MyMusicLifecycle', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    //注销会话   释放播放器
    // 显式处理释放 Promise，避免 Ability 已销毁后留下未捕获异常。
    this.releaseAudioResources().catch((err: Error) => {
      hilog.error(DOMAIN, 'MyMusicAudio', 'Audio release failed: %{public}s', JSON.stringify(err))
    })
    hilog.info(DOMAIN, 'MyMusicLifecycle', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'MyMusicLifecycle', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'MyMusicLifecycle', '%{public}s', 'Ability onBackground');
  }
}
