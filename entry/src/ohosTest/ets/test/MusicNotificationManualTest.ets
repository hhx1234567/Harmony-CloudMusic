import { musicNotificationService } from '../../../main/ets/services/MusicNotificationService'

/**
 * 设备手动测试辅助方法，不会被 List.test.ets 自动执行，也不会进入正式 HAP。
 * 启动 EntryAbility 后，可在调试器中逐个调用这些方法观察权限框和通知栏结果。
 * 四个方法故意分开，方便观察“授权 -> 发布 -> 同 ID 更新 -> 取消”的每一步效果。
 */
export class MusicNotificationManualTest {
  private static readonly TEST_SONG_ID: string = 'notification_manual_test_song'
  private static readonly TEST_SONG_NAME: string = 'Notification Kit 测试歌曲'

  static async requestPermission(): Promise<boolean> {
    return await musicNotificationService.requestNotificationPermission()
  }

  static async publishCompleted(): Promise<boolean> {
    // 使用固定 songId，多次执行都对应同一条测试通知。
    return await musicNotificationService.publishDownloadCompleted(
      MusicNotificationManualTest.TEST_SONG_ID,
      MusicNotificationManualTest.TEST_SONG_NAME
    )
  }

  static async publishFailed(): Promise<boolean> {
    // songId 与成功通知相同，所以系统应更新上一条通知，而不是新增第二条。
    return await musicNotificationService.publishDownloadFailed(
      MusicNotificationManualTest.TEST_SONG_ID,
      MusicNotificationManualTest.TEST_SONG_NAME
    )
  }

  static async cancel(): Promise<boolean> {
    // 取消接口需要数字 ID，因此先用与正式业务相同的规则从 songId 计算 ID。
    const notificationId = musicNotificationService.getDownloadNotificationId(
      MusicNotificationManualTest.TEST_SONG_ID
    )
    if (notificationId === null) {
      return false
    }
    return await musicNotificationService.cancel(notificationId)
  }
}
