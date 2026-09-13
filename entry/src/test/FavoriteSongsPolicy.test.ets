import { describe, it, expect } from '@ohos/hypium'
import { FavoriteSongsPolicy } from '../main/ets/utils/FavoriteSongsPolicy'
import { SongItemType } from '../main/ets/models/music'

function createSong(id: string, name: string): SongItemType {
  return {
    id: id,
    name: name,
    author: 'test-author',
    img: 'https://example.com/cover.jpg',
    url: 'https://example.com/song.mp3'
  }
}

export default function FavoriteSongsPolicyTest() {
  describe('FavoriteSongsPolicyTest', () => {
    it('toggle_should_add_new_song_without_mutating_source', 0, () => {
      const source: SongItemType[] = [createSong('1', 'one')]
      const result = FavoriteSongsPolicy.toggle(source, createSong('2', 'two'))

      expect(result.isFavorite).assertEqual(true)
      expect(result.songs.length).assertEqual(2)
      expect(result.songs[0].id).assertEqual('2')
      expect(source.length).assertEqual(1)
    })

    it('toggle_should_remove_existing_song', 0, () => {
      const source: SongItemType[] = [createSong('1', 'one'), createSong('2', 'two')]
      const result = FavoriteSongsPolicy.toggle(source, createSong('1', 'one'))

      expect(result.isFavorite).assertEqual(false)
      expect(result.songs.length).assertEqual(1)
      expect(result.songs[0].id).assertEqual('2')
    })

    it('normalize_should_remove_blank_and_duplicate_ids', 0, () => {
      const normalized = FavoriteSongsPolicy.normalize([
        createSong('', 'blank'),
        createSong('1', 'one'),
        createSong('1', 'duplicate')
      ])

      expect(normalized.length).assertEqual(1)
      expect(normalized[0].name).assertEqual('one')
    })

    it('contains_should_use_song_id', 0, () => {
      const songs: SongItemType[] = [createSong('1', 'same-name')]

      expect(FavoriteSongsPolicy.contains(songs, '1')).assertEqual(true)
      expect(FavoriteSongsPolicy.contains(songs, '2')).assertEqual(false)
      expect(FavoriteSongsPolicy.contains(songs, '')).assertEqual(false)
    })
  })
}
