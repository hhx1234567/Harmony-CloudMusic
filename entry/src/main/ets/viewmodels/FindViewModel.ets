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
  @Trace pendingSongId: string = ''

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
  async playSong(item: SongItemType, pathStack: NavPathStack) {
    this.pendingSongId = item.id
    const currentIntentId = item.id
    pathStack.pushPathByName('Play', null, false)
    let realUrl = await getSongRealUrl(item.id)
    if (this.pendingSongId !== currentIntentId) {
      console.info(`[Race Condition] 丢弃过期的播放请求: ${item.name}`)
    }
    if (realUrl) {
      item.url = realUrl
      playerManager.singPlay(item)
    }
  }

}
