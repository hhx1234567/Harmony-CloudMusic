import { playerManager } from '../utils/AvPlayerManager';
import { PlayMode } from '../models/globalMusic'
import { musicSettingsRepository } from '../repository/MusicSettingsRepository'
import { SongItemType } from '../models/music'
import { FavoriteSongsPolicy, FavoriteToggleResult } from '../utils/FavoriteSongsPolicy'
@ObservedV2
export class PlayViewModel {
  // 1. 追踪播放列表面板的动画状态
  @Trace panelHeight: string = '0%';
  @Trace panelOpacity: number = 0;
  @Trace favoriteErrorMessage: string = ''

  // 2. 核心计算：毫秒转换时间戳格式 (纯计算逻辑剥离)
  number2time(milliseconds: number): string {
    const safeMilliseconds = Number.isFinite(milliseconds) && milliseconds > 0 ? milliseconds : 0
    const totalSeconds = Math.floor(safeMilliseconds / 1000)
    const seconds = totalSeconds % 60
    const minutes = Math.floor(totalSeconds / 60)
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
  }

  // 3. 面板行为控制
  showListPanel() {
    this.panelHeight = '50%';
    this.panelOpacity = 1;
  }

  hideListPanel() {
    this.panelHeight = '0%';
    this.panelOpacity = 0;
  }

  // 4. 进度条拖拽事件转发
  handleSeek(value: number) {
    playerManager.seekPlay(value);
  }

  getNextPlayMode(currentMode: PlayMode): PlayMode {
    if (currentMode === 'auto') {
      return 'random'
    }

    if (currentMode === 'random') {
      return 'repeat'
    }

    return 'auto'
  }

  async savePlayMode(mode: PlayMode): Promise<void> {
    await musicSettingsRepository.savePlayMode(mode)
  }

  isFavorite(favoriteSongs: SongItemType[], songId: string): boolean {
    return FavoriteSongsPolicy.contains(favoriteSongs, songId)
  }

  async toggleFavorite(song: SongItemType, favoriteSongs: SongItemType[]): Promise<FavoriteToggleResult> {
    const result: FavoriteToggleResult = FavoriteSongsPolicy.toggle(favoriteSongs, song)
    this.favoriteErrorMessage = ''

    try {
      await musicSettingsRepository.saveFavoriteSongs(result.songs)
      return result
    } catch (error) {
      this.favoriteErrorMessage = '收藏保存失败，请稍后重试'
      throw new Error('收藏歌曲保存失败')
    }
  }
}
