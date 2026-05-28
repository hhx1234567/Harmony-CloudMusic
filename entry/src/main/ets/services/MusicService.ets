import http from '@ohos.net.http';
import { SongItemType } from "../models/music"
import { ApiConfig } from '../config/ApiConfig'
//歌手画像
interface NetEaseArtist {
  name: string
}
//专辑画像
interface NetEaseAlbum {
  picUrl: string
}
//歌曲本尊画像，只挑了要的字段来写
interface NetEaseSong {
  id: number,
  name: string,
  ar: NetEaseArtist[],//歌手是个数组
  al: NetEaseAlbum //专辑是个对象
}

interface NetEaseResult {
  songs: NetEaseSong[];
}

interface NetEaseResponse {
  code: number;
  result: NetEaseResult
}
interface NetEaseUrl {
  url: string
}
interface NetEaseDataUrl {
  code: number,
  data: NetEaseUrl[]
}


// --- 核心方法 1：根据确切关键词搜索歌曲 ---
export async function searchMusic(keyword: string): Promise<SongItemType[]> {
  if (!keyword) return []
  let httpRequest = http.createHttp()
  let safeKeyword = encodeURIComponent(keyword)

  try {
    let res = await httpRequest.request(
      `${ApiConfig.MUSIC_API_BASE}/cloudsearch?keywords=${safeKeyword}`,
      { method: http.RequestMethod.GET, connectTimeout: 10000 }
    )
    if (res.responseCode === 200) {
      let rawObj = JSON.parse(res.result as string) as NetEaseResponse
      if (rawObj.code === 200 && rawObj.result?.songs) {
        let cleanSongs: SongItemType[] = rawObj.result.songs.map((rawItem) => {
          return {
            id: rawItem.id.toString(),
            name: rawItem.name,
            author: (rawItem.ar && rawItem.ar.length > 0) ? rawItem.ar[0].name : '未知歌手',
            img: rawItem.al.picUrl.replace('http://', 'https://'),
            url: ''
          } as SongItemType
        })
        return cleanSongs // 返回清洗后的纯净数据
      }
    }
    return []
  } catch (err) {
    console.error('搜索请求异常：', JSON.stringify(err))
    return []
  } finally {
    httpRequest.destroy()
  }
}


// --- 核心方法 2：随机抽取歌手搜索（用于发现页列表） ---
export async function getRandomMusic(authors: string[]): Promise<SongItemType[]> {
  if (!authors || authors.length === 0) return []
  let currentAuthor = authors[Math.floor(Math.random() * authors.length)]
  console.info("🎲 [网络服务] 抽中了歌手: " + currentAuthor)
  // 直接复用上面的基础搜索方法！
  return await searchMusic(currentAuthor)
}

// --- 核心方法 3：获取真实的 MP3 音频播放链接 ---
export async function getSongRealUrl(id: string): Promise<string> {
  let httpRequest = http.createHttp()
  try {
    let res = await httpRequest.request(
      `${ApiConfig.MUSIC_API_BASE}/song/url/v1?id=${id}&level=standard`,
      { method: http.RequestMethod.GET }
    )
    if (res.responseCode === 200) {
      let rawObj = JSON.parse(res.result as string) as NetEaseDataUrl
      if (rawObj.code === 200 && rawObj.data && rawObj.data.length > 0) {
        return rawObj.data[0].url as string
      }
    }
  } catch (err) {
    console.error("获取链接失败", JSON.stringify(err))
  } finally {
    httpRequest.destroy()
  }
  return ''
}


