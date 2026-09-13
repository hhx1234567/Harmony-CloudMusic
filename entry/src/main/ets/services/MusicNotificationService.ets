// UIAbilityContext：用于把系统通知授权弹窗绑定到当前 Ability。
import { common } from '@kit.AbilityKit'
// BusinessError：HarmonyOS Kit 抛出的标准业务异常，里面包含可识别的错误码 code。
import { BusinessError } from '@kit.BasicServicesKit'
// notificationManager：Notification Kit 提供的权限检查、发布和取消通知入口。
import { notificationManager } from '@kit.NotificationKit'
// hilog：系统日志工具。本类只记录执行结果和错误码，不记录歌曲名称等业务内容。
import { hilog } from '@kit.PerformanceAnalysisKit'

// hilog 要求每条日志带 domain 和 tag，便于在 DevEco Studio 的 HiLog 中筛选。
const DOMAIN: number = 0x0000
const TAG: string = 'MusicNotification'
// 系统使用“通知 ID + label”识别一条通知。固定 label 后，相同 ID 会更新旧通知而不是新增一条。
const DOWNLOAD_NOTIFICATION_LABEL: string = 'download_result'
// 把下载类通知统一放到 10 亿以上的 ID 区间，降低与项目中其他通知 ID 冲突的概率。
const DOWNLOAD_NOTIFICATION_ID_BASE: number = 1000000000
const DOWNLOAD_NOTIFICATION_ID_RANGE: number = 1000000000
// Notification Kit 对文本长度有限制。这里先限制字符数，避免异常输入生成过长通知。
const MAX_SONG_NAME_LENGTH: number = 200

// enum 把通知结果限制为两个合法值，调用内部方法时不能随意传入其他字符串。
enum DownloadNotificationResult {
  COMPLETED = 'completed',
  FAILED = 'failed'
}

/**
 * 普通业务通知服务。
 *
 * 这里只负责通知授权、通知内容构造、发布和取消，不负责歌曲下载，
 * 也不参与 AVSession、AVPlayer 或后台音频任务的生命周期。
 */
export class MusicNotificationService {
  /**
   * 授权弹窗必须绑定 UIAbilityContext，所以 Service 需要保存 EntryAbility 传入的 Context。
   * 初始值是 null，表示 Service 还没有初始化；每个公开方法都会先检查这个状态。
   */
  private context: common.UIAbilityContext | null = null

  /**
   * 初始化只保存 Context，不检查权限、不弹窗、也不发布通知。
   * 返回 boolean 是为了让调用者能够知道初始化是否成功，而不是依赖异常控制流程。
   */
  init(context: common.UIAbilityContext): boolean {
    if (!context) {
      hilog.error(DOMAIN, TAG, 'Notification service initialization failed: context is unavailable')
      return false
    }

    this.context = context
    hilog.info(DOMAIN, TAG, 'Notification service initialized')
    return true
  }

  release(): void {
    // 单例 Service 不会随页面自动销毁，因此 Ability 销毁时要主动断开对 Context 的引用。
    this.context = null
    hilog.info(DOMAIN, TAG, 'Notification service context released')
  }

  /**
   * 检查当前应用的通知总开关。
   * Promise<boolean> 表示这是异步操作：true 为允许，false 包含未授权、未初始化和检查失败。
   */
  async isNotificationEnabled(): Promise<boolean> {
    if (!this.context) {
      hilog.warn(DOMAIN, TAG, 'Notification permission check skipped: service is not initialized')
      return false
    }

    try {
      // 该 API 只读取系统设置，不会弹出授权对话框。
      return await notificationManager.isNotificationEnabled()
    } catch (error) {
      // ArkTS 严格模式不允许直接给 catch 变量标注类型，所以在 catch 内显式转换。
      const businessError = error as BusinessError
      hilog.error(
        DOMAIN,
        TAG,
        'Notification permission check failed. code=%{public}d',
        businessError.code
      )
      return false
    }
  }

  /**
   * 在前台、由用户操作触发时申请通知授权。
   * 发布方法只检查授权，不会在下载结束等后台时机擅自弹出授权框。
   *
   * 执行顺序：检查现状 -> 未授权时申请 -> 再检查一次系统最终状态。
   */
  async requestNotificationPermission(): Promise<boolean> {
    const context = this.context
    if (!context) {
      hilog.warn(DOMAIN, TAG, 'Notification permission request skipped: service is not initialized')
      return false
    }

    try {
      // 已经授权时直接结束，避免重复请求系统弹窗。
      if (await notificationManager.isNotificationEnabled()) {
        return true
      }

      // requestEnableNotification 必须接收 UIAbilityContext，系统用它承载授权弹窗。
      await notificationManager.requestEnableNotification(context)
      // 用户可能拒绝，因此 API 调用结束后仍以系统查询结果为准，不能假设已经授权。
      const enabled = await notificationManager.isNotificationEnabled()
      if (!enabled) {
        hilog.warn(DOMAIN, TAG, 'Notification permission was not granted')
      }
      return enabled
    } catch (error) {
      const businessError = error as BusinessError
      // 1600004 是“用户拒绝/通知被禁用”，属于可预期结果，用 warn 而不是崩溃处理。
      if (businessError.code === 1600004) {
        hilog.warn(DOMAIN, TAG, 'Notification permission was declined by the user')
      } else {
        hilog.error(
          DOMAIN,
          TAG,
          'Notification permission request failed. code=%{public}d',
          businessError.code
        )
      }
      return false
    }
  }

  /**
   * 把 songId 转换为稳定的数字通知 ID。
   *
   * “稳定”指同一个 songId 在应用重启后仍会得到相同结果。成功和失败通知都调用本方法，
   * 所以同一首歌的状态变化会更新原通知，而不会在通知栏不断累积。
   */
  getDownloadNotificationId(songId: string): number | null {
    // trim() 去掉首尾空格，使 "123" 和 " 123 " 被视为同一个业务 ID。
    const normalizedSongId = songId.trim()
    if (!normalizedSongId) {
      hilog.warn(DOMAIN, TAG, 'Cannot create notification ID: songId is empty')
      return null
    }

    // FNV-1a 逐个处理字符，得到可重复计算的整数；这里只用于业务映射，不用于密码学安全。
    let hash: number = 0x811c9dc5
    for (let index: number = 0; index < normalizedSongId.length; index++) {
      // charCodeAt() 取得字符编码，^ 是按位异或，Math.imul() 执行稳定的 32 位整数乘法。
      hash = Math.imul(hash ^ normalizedSongId.charCodeAt(index), 0x01000193)
    }
    // >>> 0 把可能为负数的有符号 32 位结果转换为非负数。
    const unsignedHash = hash >>> 0
    // 最终限制在预留的下载通知 ID 区间内。
    return DOWNLOAD_NOTIFICATION_ID_BASE + unsignedHash % DOWNLOAD_NOTIFICATION_ID_RANGE
  }

  /** 下载成功的对外业务接口；具体公共流程交给 publishDownloadResult()。 */
  async publishDownloadCompleted(songId: string, songName: string): Promise<boolean> {
    return await this.publishDownloadResult(songId, songName, DownloadNotificationResult.COMPLETED)
  }

  /** 下载失败的对外业务接口；与成功通知共用 ID，因此可以覆盖同一任务的旧状态。 */
  async publishDownloadFailed(songId: string, songName: string): Promise<boolean> {
    return await this.publishDownloadResult(songId, songName, DownloadNotificationResult.FAILED)
  }

  /**
   * 按通知 ID 取消本应用发布的通知。
   * 失败只返回 false，不向外抛异常，因此调用它不会改变原下载业务的成功或失败结果。
   */
  async cancel(notificationId: number): Promise<boolean> {
    if (!this.context) {
      hilog.warn(DOMAIN, TAG, 'Notification cancellation skipped: service is not initialized')
      return false
    }
    // Notification Kit 接收整数 ID；提前拒绝小数、NaN 和负数，可以得到更明确的日志。
    if (!Number.isInteger(notificationId) || notificationId < 0) {
      hilog.warn(DOMAIN, TAG, 'Notification cancellation skipped: invalid notification ID')
      return false
    }

    try {
      // cancel() 返回 Promise<void>；await 正常结束就表示系统已经接受取消操作。
      await notificationManager.cancel(notificationId)
      hilog.info(DOMAIN, TAG, 'Notification cancelled. id=%{public}d', notificationId)
      return true
    } catch (error) {
      const businessError = error as BusinessError
      hilog.error(
        DOMAIN,
        TAG,
        'Notification cancellation failed. code=%{public}d',
        businessError.code
      )
      return false
    }
  }

  private async publishDownloadResult(
    songId: string,
    songName: string,
    result: DownloadNotificationResult
  ): Promise<boolean> {
    // 第一步：确认 EntryAbility 已经为 Service 注入 Context。
    if (!this.context) {
      hilog.warn(DOMAIN, TAG, 'Notification publication skipped: service is not initialized')
      return false
    }

    // 第二步：校验并标准化业务参数。通知 ID 来自 songId，显示文本来自 songName。
    const notificationId = this.getDownloadNotificationId(songId)
    const normalizedSongName = songName.trim().substring(0, MAX_SONG_NAME_LENGTH)
    if (notificationId === null || !normalizedSongName) {
      hilog.warn(DOMAIN, TAG, 'Notification publication skipped: required parameter is empty')
      return false
    }

    // 第三步：发布前只检查权限。这里故意不申请权限，避免后台任务突然弹出 UI。
    if (!await this.isNotificationEnabled()) {
      hilog.warn(DOMAIN, TAG, 'Notification publication skipped: notification is not authorized')
      return false
    }

    // 第四步：把业务数据转换成 Notification Kit 认识的 NotificationRequest。
    const request = this.createDownloadRequest(notificationId, normalizedSongName, result)
    try {
      // 第五步：真正交给系统通知中心。只有 await 成功结束才返回 true。
      await notificationManager.publish(request)
      hilog.info(
        DOMAIN,
        TAG,
        'Notification published. type=%{public}s id=%{public}d',
        result,
        notificationId
      )
      return true
    } catch (error) {
      // 发布通知是附加能力：失败时记录错误并返回 false，绝不能反过来修改下载结果。
      const businessError = error as BusinessError
      hilog.error(
        DOMAIN,
        TAG,
        'Notification publication failed. code=%{public}d',
        businessError.code
      )
      return false
    }
  }

  private createDownloadRequest(
    notificationId: number,
    songName: string,
    result: DownloadNotificationResult
  ): notificationManager.NotificationRequest {
    // 布尔变量让下面的标题和正文选择更容易阅读。
    const completed = result === DownloadNotificationResult.COMPLETED
    return {
      // id 与 label 相同的后续通知会更新当前通知。
      id: notificationId,
      label: DOWNLOAD_NOTIFICATION_LABEL,
      // OTHER_TYPES 是普通业务通知渠道，不占用媒体播放通知的 AVSession 通道。
      notificationSlotType: notificationManager.SlotType.OTHER_TYPES,
      content: {
        // BASIC_TEXT 使用系统标准文本样式，不需要自己编写通知布局。
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: completed ? '下载完成' : '下载失败',
          text: completed ? `${songName} 已下载完成` : `${songName} 下载失败，请稍后重试`
        }
      }
    }
  }
}

// 导出一个全局单例，让不同业务调用者共享相同 Context 和通知规则，避免重复创建 Service。
export const musicNotificationService: MusicNotificationService = new MusicNotificationService()
