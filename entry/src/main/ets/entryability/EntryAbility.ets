import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { playerManager } from '../utils/AvPlayerManager';
import { sessionManager } from '../utils/AvSessionManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private async initializeAudio(): Promise<void> {
    const playerReady = await playerManager.init()
    const sessionReady = await sessionManager.init(this.context)
    if (!playerReady || !sessionReady) {
      hilog.error(
        DOMAIN,
        'MymusicAudio',
        'Audio initialization incomplete. player=%{public}s session=%{public}s',
        playerReady.toString(),
        sessionReady.toString()
      )
    }
  }

  private async releaseAudioResources(): Promise<void> {
    await sessionManager.destroy()
    await playerManager.release()
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    // 准备播放器
    this.initializeAudio().catch((err: Error) => {
      hilog.error(DOMAIN, 'MymusicAudio', 'Audio initialization failed: %{public}s', JSON.stringify(err))
    })
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    //注销会话   释放播放器
    this.releaseAudioResources().catch((err: Error) => {
      hilog.error(DOMAIN, 'MymusicAudio', 'Audio release failed: %{public}s', JSON.stringify(err))
    })
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
