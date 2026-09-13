import { aiAssistant } from '../utils/AIAssistant';
import { getRandomMusic, getSongRealUrl, searchMusic } from '../services/MusicService';
import { FindPageCache } from '../models/cache';
import { SongItemType } from '../models/music'
import { playerManager } from '../utils/AvPlayerManager';
import { DEFAULT_SONGS } from '../models/defaultSongs'

export type SongSearchProvider = (keyword: string) => Promise<SongItemType[]>

@ObservedV2
export class FindViewModel {
  readonly isAIEnabled: boolean = aiAssistant.isEnabled();
  // 1. 将原来组件里的局部状态全部搬移到这里，用 @Trace 追踪变化
  @Trace isLoading: boolean = true;
  @Trace isRefreshing: boolean = false;
  @Trace isSearching: boolean = false;
  @Trace searchKeyword: string = '';
  @Trace listTitle: string = '猜你喜欢';
  @Trace userInput: string = '';
  @Trace isAILoading: boolean = false;
  @Trace aiKeyword: string = '';
  @Trace aiReason: string = '';
  @Trace loadErrorMessage: string = '';
  @Trace playErrorMessage: string = '';
  // 记录最近一次点击播放所生成的请求编号。
  // 它只用于淘汰过期请求，不直接显示在 UI 上，因此不需要 @Trace。
  private latestPlayRequestId: number = 0

  /**
   * 为本次点击生成请求编号。
   * 例如先点 B、再点 C：B 得到 1，C 得到 2，latestPlayRequestId 最终为 2。
   */
  private createPlayRequestId(): number {
    this.latestPlayRequestId += 1
    return this.latestPlayRequestId
  }

  /** 只有编号等于 latestPlayRequestId 的请求，才是用户最后一次点击。 */
  private isLatestPlayRequest(requestId: number): boolean {
    return requestId === this.latestPlayRequestId
  }

  private useOfflineSongs(pageCache: FindPageCache): void {
    if (pageCache.songs.length > 0) {
      return
    }
    // 使用快照，避免播放器更新真实 URL 时污染全局演示数据。
    pageCache.songs = DEFAULT_SONGS.map((song: SongItemType) => {
      return {
        id: song.id,
        name: song.name,
        author: song.author,
        img: song.img,
        url: song.url
      } as SongItemType
    })
  }

  /**
   * 加载推荐歌曲并直接写入 Find 页面传来的共享缓存对象。
   * pageCache 与 Find.findPageCache 是同一个对象，所以这里无需返回 songs。
   */
  async loadRandomSongs(songAuthor: string[], pageCache: FindPageCache): Promise<void> {
    const hadCachedSongs = pageCache.songs.length > 0
    this.isLoading = !hadCachedSongs;
    this.loadErrorMessage = '';
    try {
      const songs = await getRandomMusic(songAuthor);
      if (songs && songs.length > 0) {
        // 这里修改的正是 Find 页面持有的同一个 FindPageCache 对象。
        pageCache.songs = songs;
        this.listTitle = '猜你喜欢';
      } else if (hadCachedSongs) {
        // 刷新失败时保留当前内容，避免列表突然被离线数据覆盖或清空。
        this.loadErrorMessage = '在线曲库刷新失败，已保留当前歌单';
      } else {
        this.useOfflineSongs(pageCache)
        this.loadErrorMessage = '在线曲库暂不可用，已切换到离线演示曲库';
      }
    } catch (error) {
      console.error(`[FindViewModel] 推荐歌曲加载失败：${JSON.stringify(error)}`)
      if (hadCachedSongs) {
        this.loadErrorMessage = '网络开小差了，已保留当前歌单';
      } else {
        this.useOfflineSongs(pageCache)
        this.loadErrorMessage = '网络开小差了，已切换到离线演示曲库';
      }
    } finally {
      this.isLoading = false;
      this.isRefreshing = false;
    }
  }

  async searchSongs(
    pageCache: FindPageCache,
    searchProvider: SongSearchProvider = searchMusic
  ): Promise<void> {
    const keyword = this.searchKeyword.trim()
    if (!keyword) {
      this.loadErrorMessage = '请输入歌曲名或歌手名'
      return
    }

    const hadCachedSongs = pageCache.songs.length > 0
    this.isSearching = true
    this.loadErrorMessage = ''
    this.playErrorMessage = ''

    try {
      const songs = await searchProvider(keyword)
      if (songs.length > 0) {
        pageCache.songs = songs
        this.listTitle = `“${keyword}”的搜索结果`
        return
      }

      if (!hadCachedSongs) {
        this.useOfflineSongs(pageCache)
        this.listTitle = '离线演示曲库'
      }
      this.loadErrorMessage = hadCachedSongs
        ? '未找到结果或网络不可用，已保留当前歌单'
        : '未找到结果或网络不可用，已展示离线演示曲库'
    } catch (error) {
      console.error(`[FindViewModel] 搜索歌曲失败：${JSON.stringify(error)}`)
      if (!hadCachedSongs) {
        this.useOfflineSongs(pageCache)
        this.listTitle = '离线演示曲库'
      }
      this.loadErrorMessage = hadCachedSongs
        ? '搜索失败，已保留当前歌单'
        : '搜索失败，已展示离线演示曲库'
    } finally {
      this.isSearching = false
    }
  }

  // 3. 将请求 AI 的逻辑搬过来
  async askAI(): Promise<void> {
    if (!this.userInput) return;
    this.isAILoading = true;
    this.aiKeyword = '';
    this.aiReason = '';

    try {
      const result = await aiAssistant.ask(this.userInput);
      this.aiKeyword = result.keyword;
      this.aiReason = result.reason;
    } catch (error) {
      console.error(`[FindViewModel] AI推荐失败：${JSON.stringify(error)}`)
      this.aiReason = 'AI 推荐暂时不可用，请稍后重试';
    } finally {
      this.isAILoading = false;
    }
  }

  private openPlayPageOnce(pathStack: NavPathStack): void {
    // 直接读取真实导航栈，而不是自己维护一个布尔值；这样返回、替换页面后不会和真实状态失同步。
    const pathNames: string[] = pathStack.getAllPathName()

    console.info(
      `[Navigation] 当前导航栈：${JSON.stringify(pathNames)}`
    )

    if (pathNames.includes('Play')) {
      console.info(
        '[Navigation] Play页面已经存在，拦截重复跳转'
      )
      return
    }

    // 只有栈中还没有 Play 时才压入页面，避免出现 Layout -> Play -> Play。
    pathStack.pushPathByName('Play', null, false)

    console.info(
      '[Navigation] 首次进入Play页面'
    )
  }

  async playSong(
    selectedSong: SongItemType,
    pathStack: NavPathStack,
    visibleSongList: SongItemType[] = []
  ): Promise<void> {
    // 本次调用只保存自己的编号；以后再点击其他歌曲，只会改变 latestPlayRequestId。
    const currentRequestId = this.createPlayRequestId()
    this.playErrorMessage = ''

    // 创建本次播放专用的歌曲副本。后面修改 URL 时，不会改变发现页缓存中的 selectedSong。
    const targetSong: SongItemType = {
      id: selectedSong.id,
      name: selectedSong.name,
      author: selectedSong.author,
      img: selectedSong.img,
      url: selectedSong.url
    }

    console.info(
      `[PlayRequest][${currentRequestId}] 开始解析歌曲URL：` + `${targetSong.name} (${targetSong.id})`
    )

    // 离线演示曲库已经提供可播放的 HTTPS 地址；在线搜索结果才需要二次解析。
    let realUrl: string = targetSong.url.trim()
    try {
      // 第一个异步边界：请求期间用户可能已经点了另一首歌。
      if (!realUrl) {
        realUrl = await getSongRealUrl(targetSong.id)
      }
      console.info(
        `[PlayRequest][${currentRequestId}] URL请求返回：${targetSong.name}，` +
          `结果${realUrl ? '有效' : '为空'}`
      )
    } catch (err) {
      console.error(
        `[PlayRequest][${currentRequestId}] URL请求异常：${targetSong.name}，` +
          JSON.stringify(err)
      )
      // 过期请求不能覆盖最新请求已经显示的错误信息。
      if (this.isLatestPlayRequest(currentRequestId)) {
        this.playErrorMessage = '歌曲地址获取失败，请稍后重试'
      }
      return
    }

    // URL 返回后比较“本次编号”和“最新编号”；不相等说明用户后来又点了其他歌曲。
    if (!this.isLatestPlayRequest(currentRequestId)) {
      console.info(
        `[PlayRequest][${currentRequestId}] 网络结果过期，当前最新请求为` +
          `${this.latestPlayRequestId}，丢弃歌曲：${targetSong.name}`
      )
      return
    }

    if (!realUrl) {
      console.error(
        `[PlayRequest][${currentRequestId}] 获取播放地址失败：` + `${targetSong.name}`
      )
      this.playErrorMessage = '这首歌暂时无法播放，请换一首试试'
      return
    }

    targetSong.url = realUrl

    console.info(
      `[PlayRequest][${currentRequestId}] 进入播放器层：${targetSong.name}`
    )

    let wasPlaybackApplied: boolean = false
    try {
      // 第二个异步边界：播放器 reset 期间也可能出现新的点击。
      wasPlaybackApplied = await playerManager.singPlay(targetSong, visibleSongList)
    } catch (err) {
      console.error(
        `[PlayRequest][${currentRequestId}] 播放器执行异常：${targetSong.name}，` +
          JSON.stringify(err)
      )
      if (this.isLatestPlayRequest(currentRequestId)) {
        this.playErrorMessage = '播放器启动失败，请稍后重试'
      }
      return
    }

    // 播放器返回后再次比较编号；旧请求不能在最新请求之后打开播放页。
    if (!this.isLatestPlayRequest(currentRequestId)) {
      console.info(
        `[PlayRequest][${currentRequestId}] 播放器执行期间过期，不再导航`
      )
      return
    }

    if (!wasPlaybackApplied) {
      console.info(
        `[PlayRequest][${currentRequestId}] 播放器未接受该操作`
      )
      this.playErrorMessage = '播放请求未生效，请重新点击'
      return
    }

    // URL、点击意图和播放器应用结果三项都有效，最后才允许导航。
    console.info(
      `[PlayRequest][${currentRequestId}] 最终有效，准备检查导航栈：${targetSong.name}`
    )
    this.openPlayPageOnce(pathStack)
  }

}
