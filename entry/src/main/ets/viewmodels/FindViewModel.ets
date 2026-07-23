import { aiAssistant } from '../utils/AIAssistant';
import { getRandomMusic, getSongRealUrl } from '../services/MusicService';
import { FindPageCache } from '../models/cache';
import { SongItemType } from '../models/music'
import { playerManager } from '../utils/AvPlayerManager';

@ObservedV2
export class FindViewModel {
  // 1. 将原来组件里的局部状态全部搬移到这里，用 @Trace 追踪变化
  @Trace isLoading: boolean = true;
  @Trace isRefreshing: boolean = false;
  @Trace userInput: string = '';
  @Trace isAILoading: boolean = false;
  @Trace aiKeyword: string = '';
  @Trace aiReason: string = '';
  // 仅用于内部并发控制，不驱动 UI，因此不使用 @Trace。
  private playIntentSequence: number = 0

  // 2. 将加载歌曲的逻辑搬过来
  async loadRandomSongs(songAuthor: string[], cacheData: FindPageCache): Promise<void> {
    this.isLoading = true;
    let songs = await getRandomMusic(songAuthor);
    if (songs && songs.length > 0) {
      cacheData.songs = songs;
    }
    this.isLoading = false;
    this.isRefreshing = false;
  }

  // 3. 将请求 AI 的逻辑搬过来
  async askAI(): Promise<void> {
    if (!this.userInput) return;
    this.isAILoading = true;
    this.aiKeyword = '';
    this.aiReason = '';

    let result = await aiAssistant.ask(this.userInput);

    this.aiKeyword = result.keyword;
    this.aiReason = result.reason;
    this.isAILoading = false;
  }

  private openPlayPageOnce(pathStack: NavPathStack): void {
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

    pathStack.pushPathByName('Play', null, false)

    console.info(
      '[Navigation] 首次进入Play页面'
    )
  }

  async playSong(item: SongItemType, pathStack: NavPathStack): Promise<void> {
    // 每次点击都生成一个新的意图序号。
    const intentId = ++this.playIntentSequence

    // 创建快照，避免直接修改发现页缓存里的原对象。
    const targetSong: SongItemType = {
      id: item.id,
      name: item.name,
      author: item.author,
      img: item.img,
      url: item.url
    }

    console.info(
      `[PlayIntent][${intentId}] 开始解析歌曲URL：` + `${targetSong.name} (${targetSong.id})`
    )

    let realUrl: string = ''
    try {
      realUrl = await getSongRealUrl(targetSong.id)
      console.info(
        `[PlayIntent][${intentId}] URL请求返回：${targetSong.name}，` +
          `结果${realUrl ? '有效' : '为空'}`
      )
    } catch (err) {
      console.error(
        `[PlayIntent][${intentId}] URL请求异常：${targetSong.name}，` +
          JSON.stringify(err)
      )
      return
    }

    // URL返回时检查：该请求是否仍然是用户的最新意图。
    if (intentId !== this.playIntentSequence) {
      console.info(
        `[PlayIntent][${intentId}] 网络结果过期，当前最新意图为` +
          `${this.playIntentSequence}，丢弃歌曲：${targetSong.name}`
      )
      return
    }

    if (!realUrl) {
      console.error(
        `[PlayIntent][${intentId}] 获取播放地址失败：` + `${targetSong.name}`
      )
      return
    }

    targetSong.url = realUrl

    console.info(
      `[PlayIntent][${intentId}] 进入播放器层：${targetSong.name}`
    )

    let applied: boolean = false
    try {
      applied = await playerManager.singPlay(targetSong)
    } catch (err) {
      console.error(
        `[PlayIntent][${intentId}] 播放器执行异常：${targetSong.name}，` +
          JSON.stringify(err)
      )
      return
    }

    // 第二处检查：
    // 播放器reset期间可能又产生了新点击。
    if (intentId !== this.playIntentSequence) {
      console.info(
        `[PlayIntent][${intentId}] ` + `播放器执行期间过期，不再导航`
      )
      return
    }

    if (!applied) {
      console.info(
        `[PlayIntent][${intentId}] 播放器未接受该操作`
      )
      return
    }

    console.info(
      `[PlayIntent][${intentId}] 最终有效，准备检查导航栈：${targetSong.name}`
    )
    this.openPlayPageOnce(pathStack)
  }

}
