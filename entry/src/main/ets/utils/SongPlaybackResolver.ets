import { SongItemType } from '../models/music'

export type SongUrlResolver = (songId: string) => Promise<string>

/**
 * 为任意播放入口准备可播放歌曲快照。
 * 页面缓存保持原样；在线歌曲缺少 URL 时才调用解析器。
 */
export class SongPlaybackResolver {
  static async resolve(song: SongItemType, resolver: SongUrlResolver): Promise<SongItemType | null> {
    const snapshot: SongItemType = {
      id: song.id,
      name: song.name,
      author: song.author,
      img: song.img,
      url: song.url.trim()
    }

    if (snapshot.url) {
      return snapshot
    }
    if (!snapshot.id.trim()) {
      return null
    }

    try {
      const resolvedUrl = (await resolver(snapshot.id)).trim()
      if (!resolvedUrl) {
        return null
      }
      snapshot.url = resolvedUrl
      return snapshot
    } catch (err) {
      console.error('[SongPlaybackResolver] 歌曲地址解析失败：' + JSON.stringify(err))
      return null
    }
  }
}
