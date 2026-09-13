import { PlayMode } from '../models/globalMusic'
import { SongItemType } from '../models/music'

export interface PlaybackQueueContext {
  playList: SongItemType[]
  targetIndex: number
}

/**
 * 播放队列索引策略。
 * 只负责计算，不访问 AVPlayer 或页面状态，因此可以脱离设备做稳定的单元测试。
 */
export class PlaybackQueuePolicy {
  private static copySong(song: SongItemType): SongItemType {
    return {
      id: song.id,
      name: song.name,
      author: song.author,
      img: song.img,
      url: song.url
    }
  }

  static buildContext(sourceList: SongItemType[], targetSong: SongItemType): PlaybackQueueContext {
    const playList = sourceList.map((song: SongItemType) => PlaybackQueuePolicy.copySong(song))
    const targetSnapshot = PlaybackQueuePolicy.copySong(targetSong)
    const targetIndex = playList.findIndex((song: SongItemType) => song.id === targetSnapshot.id)

    if (targetIndex >= 0) {
      playList.splice(targetIndex, 1, targetSnapshot)
      return { playList: playList, targetIndex: targetIndex }
    }

    playList.unshift(targetSnapshot)
    return { playList: playList, targetIndex: 0 }
  }

  private static normalizeIndex(listLength: number, currentIndex: number): number {
    if (listLength <= 0) {
      return -1
    }
    return currentIndex >= 0 && currentIndex < listLength ? currentIndex : 0
  }

  private static randomIndex(listLength: number, currentIndex: number, randomValue: number): number {
    if (listLength <= 0) {
      return -1
    }
    const safeIndex = PlaybackQueuePolicy.normalizeIndex(listLength, currentIndex)
    if (listLength === 1) {
      return safeIndex
    }
    const normalizedRandom = Number.isFinite(randomValue) ? Math.max(0, Math.min(randomValue, 0.999999)) : 0
    // 只在“除当前歌曲外”的候选中抽取，避免用户点击随机下一首后听起来毫无变化。
    const candidateIndex = Math.floor(normalizedRandom * (listLength - 1))
    return candidateIndex >= safeIndex ? candidateIndex + 1 : candidateIndex
  }

  static previousIndex(
    listLength: number,
    currentIndex: number,
    mode: PlayMode,
    randomValue: number = Math.random()
  ): number {
    const safeIndex = PlaybackQueuePolicy.normalizeIndex(listLength, currentIndex)
    if (safeIndex < 0) {
      return -1
    }
    if (mode === 'random') {
      return PlaybackQueuePolicy.randomIndex(listLength, safeIndex, randomValue)
    }
    return safeIndex > 0 ? safeIndex - 1 : listLength - 1
  }

  static nextIndex(
    listLength: number,
    currentIndex: number,
    mode: PlayMode,
    autoNextPlay: boolean = false,
    randomValue: number = Math.random()
  ): number {
    const safeIndex = PlaybackQueuePolicy.normalizeIndex(listLength, currentIndex)
    if (safeIndex < 0) {
      return -1
    }
    if (mode === 'repeat' && autoNextPlay) {
      return safeIndex
    }
    if (mode === 'random') {
      return PlaybackQueuePolicy.randomIndex(listLength, safeIndex, randomValue)
    }
    return (safeIndex + 1) % listLength
  }

  private static orderedCandidates(listLength: number, firstIndex: number, step: number): number[] {
    if (listLength <= 0 || firstIndex < 0) {
      return []
    }

    const candidates: number[] = []
    for (let offset: number = 0; offset < listLength; offset++) {
      candidates.push((firstIndex + step * offset + listLength) % listLength)
    }
    return candidates
  }

  static previousCandidates(
    listLength: number,
    currentIndex: number,
    mode: PlayMode,
    randomValue: number = Math.random()
  ): number[] {
    const firstIndex = PlaybackQueuePolicy.previousIndex(listLength, currentIndex, mode, randomValue)
    return PlaybackQueuePolicy.orderedCandidates(listLength, firstIndex, -1)
  }

  static nextCandidates(
    listLength: number,
    currentIndex: number,
    mode: PlayMode,
    autoNextPlay: boolean = false,
    randomValue: number = Math.random()
  ): number[] {
    const firstIndex = PlaybackQueuePolicy.nextIndex(
      listLength,
      currentIndex,
      mode,
      autoNextPlay,
      randomValue
    )
    if (mode === 'repeat' && autoNextPlay) {
      return firstIndex < 0 ? [] : [firstIndex]
    }
    return PlaybackQueuePolicy.orderedCandidates(listLength, firstIndex, 1)
  }
}
