import { preferences } from '@kit.ArkData'
import { PlayMode } from '../models/globalMusic'
import { SongItemType } from '../models/music'
import { FavoriteSongsPolicy } from '../utils/FavoriteSongsPolicy'

const PREFERENCES_NAME: string = 'music_settings'
const PLAY_MODE_KEY: string = 'play_mode'
const FAVORITE_SONGS_KEY: string = 'favorite_songs'
const DEFAULT_PLAY_MODE: PlayMode = 'auto'

class MusicSettingsRepository {
  private store: preferences.Preferences | null = null

  /**
   * 获取 Preferences 实例。
   * 应用启动时调用一次即可。
   */
  async init(context: Context): Promise<void> {
    if (this.store) {
      return
    }

    try {
      this.store = await preferences.getPreferences(context, { name: PREFERENCES_NAME })
      console.info('[MusicSettingsRepository] Preferences初始化成功')
    } catch (error) {
      console.error(`[MusicSettingsRepository] Preferences初始化失败：${JSON.stringify(error)}`)
      throw new Error('播放设置初始化失败')
    }
  }

  /**
   * 读取播放模式。
   * 数据不存在或内容不合法时返回auto。
   */
  getPlayMode(): PlayMode {
    const store = this.store

    if (!store) {
      console.info(
        '[MusicSettingsRepository] Preferences尚未初始化，使用默认播放模式'
      )
      return DEFAULT_PLAY_MODE
    }

    try {
      const value = store.getSync(PLAY_MODE_KEY, DEFAULT_PLAY_MODE)

      if (value === 'auto' || value === 'random' || value === 'repeat') {
        return value
      }
    } catch (error) {
      console.error(`[MusicSettingsRepository] 播放模式读取失败：${JSON.stringify(error)}`)
    }

    console.info(
      '[MusicSettingsRepository] 播放模式数据无效，使用默认值'
    )
    return DEFAULT_PLAY_MODE
  }

  /**
   * 保存播放模式。
   */
  async savePlayMode(mode: PlayMode): Promise<void> {
    const store = this.store

    if (!store) {
      throw new Error(
        'MusicSettingsRepository尚未初始化'
      )
    }

    try {
      // putSync先更新Preferences内存数据。
      store.putSync(PLAY_MODE_KEY, mode)

      // flush把数据真正写入持久化文件。
      await store.flush()

      console.info(
        `[MusicSettingsRepository] 播放模式已保存：${mode}`
      )
    } catch (error) {
      console.error(`[MusicSettingsRepository] 播放模式保存失败：${JSON.stringify(error)}`)
      throw new Error('播放模式保存失败')
    }
  }

  getFavoriteSongs(): SongItemType[] {
    const store = this.store
    if (!store) {
      return []
    }

    try {
      const rawValue = store.getSync(FAVORITE_SONGS_KEY, '') as string
      if (!rawValue) {
        return []
      }
      const parsedSongs = JSON.parse(rawValue) as SongItemType[]
      if (!Array.isArray(parsedSongs)) {
        return []
      }
      return FavoriteSongsPolicy.normalize(parsedSongs)
    } catch (error) {
      console.error(`[MusicSettingsRepository] 收藏歌曲读取失败：${JSON.stringify(error)}`)
      return []
    }
  }

  async saveFavoriteSongs(songs: SongItemType[]): Promise<void> {
    const store = this.store
    if (!store) {
      throw new Error('MusicSettingsRepository尚未初始化')
    }

    try {
      const normalizedSongs = FavoriteSongsPolicy.normalize(songs)
      store.putSync(FAVORITE_SONGS_KEY, JSON.stringify(normalizedSongs))
      await store.flush()
      console.info(`[MusicSettingsRepository] 收藏歌曲已保存：${normalizedSongs.length}首`)
    } catch (error) {
      console.error(`[MusicSettingsRepository] 收藏歌曲保存失败：${JSON.stringify(error)}`)
      throw new Error('收藏歌曲保存失败')
    }
  }
}

export const musicSettingsRepository = new MusicSettingsRepository()
