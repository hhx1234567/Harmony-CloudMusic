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
  //待处理歌的ID
  //@Trace pendingSongId: string = ''

  private playIntentSequence: number = 0

  // 2. 将加载歌曲的逻辑搬过来
  async loadRandomSongs(songAuthor: string[], cacheData: FindPageCache) {
    this.isLoading = true;
    let songs = await getRandomMusic(songAuthor);
    if (songs && songs.length > 0) {
      cacheData.songs = songs;
    }
    this.isLoading = false;
    this.isRefreshing = false;
  }

  // 3. 将请求 AI 的逻辑搬过来
  async askAI() {
    if (!this.userInput) return;
    this.isAILoading = true;
    this.aiKeyword = '';
    this.aiReason = '';

    let result = await aiAssistant.ask(this.userInput);

    this.aiKeyword = result.keyword;
    this.aiReason = result.reason;
    this.isAILoading = false;
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

    const realUrl = await getSongRealUrl(targetSong.id)

    // URL返回时检查：该请求是否仍然是用户的最新意图。
    if (intentId !== this.playIntentSequence) {
      console.info(
        `[PlayIntent][${intentId}] 已过期，当前最新意图为` + `${this.playIntentSequence}，丢弃歌曲：${targetSong.name}`
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
      `[PlayIntent][${intentId}] URL有效，交给播放器：` + `${targetSong.name}`
    )

    playerManager.singPlay(targetSong)

    // 只让最终有效的意图进入播放页。
    pathStack.pushPathByName('Play', null, false)

  }
}