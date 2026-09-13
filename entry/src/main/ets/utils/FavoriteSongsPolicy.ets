import { SongItemType } from '../models/music'

export interface FavoriteToggleResult {
  songs: SongItemType[]
  isFavorite: boolean
}

export class FavoriteSongsPolicy {
  private static copySong(song: SongItemType): SongItemType {
    return {
      id: song.id,
      name: song.name,
      author: song.author,
      img: song.img,
      url: song.url
    }
  }

  static normalize(songs: SongItemType[]): SongItemType[] {
    const normalized: SongItemType[] = []
    songs.forEach((song: SongItemType) => {
      if (!song.id || normalized.some((item: SongItemType) => item.id === song.id)) {
        return
      }
      normalized.push(FavoriteSongsPolicy.copySong(song))
    })
    return normalized
  }

  static contains(songs: SongItemType[], songId: string): boolean {
    return !!songId && songs.some((song: SongItemType) => song.id === songId)
  }

  static toggle(songs: SongItemType[], targetSong: SongItemType): FavoriteToggleResult {
    const normalized = FavoriteSongsPolicy.normalize(songs)
    if (!targetSong.id) {
      return { songs: normalized, isFavorite: false }
    }

    const targetIndex = normalized.findIndex((song: SongItemType) => song.id === targetSong.id)
    if (targetIndex >= 0) {
      normalized.splice(targetIndex, 1)
      return { songs: normalized, isFavorite: false }
    }

    normalized.unshift(FavoriteSongsPolicy.copySong(targetSong))
    return { songs: normalized, isFavorite: true }
  }
}
