import http from '@ohos.net.http';
import { SongItemType } from "../models/music"
import { ApiConfig } from '../config/ApiConfig'
import { HttpClient } from '../utils/HttpClient'
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
  let safeKeyword = encodeURIComponent(keyword)

  let rawObj = await HttpClient.request(
    `${ApiConfig.MUSIC_API_BASE}/cloudsearch?keywords=${safeKeyword}`,
    http.RequestMethod.GET
  ) as NetEaseResponse | null; // 因为拦截器可能返回 null，所以加上 | null

  // 直接判断拿到的干净数据
  if (rawObj && rawObj.code === 200 && rawObj.result?.songs) {
    let cleanSongs: SongItemType[] = rawObj.result.songs.map((rawItem) => {
      return {
        id: rawItem.id.toString(),
        name: rawItem.name,
        author: (rawItem.ar && rawItem.ar.length > 0) ? rawItem.ar[0].name : '未知歌手',
        img: (rawItem.al?.picUrl || '').replace('http://', 'https://'),
        url: ''
      } as SongItemType
    })
    return cleanSongs
  }
  return [] // 如果 rawObj 是 null，直接返回空数组
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
  // 💥 核心重构：再次秒杀原来的冗余代码
  let rawObj = await HttpClient.request(
    `${ApiConfig.MUSIC_API_BASE}/song/url/v1?id=${id}&level=standard`,
    http.RequestMethod.GET
  ) as NetEaseDataUrl | null;

  if (rawObj && rawObj.code === 200 && rawObj.data && rawObj.data.length > 0) {
    return rawObj.data[0].url as string
  }

  return ''
}


