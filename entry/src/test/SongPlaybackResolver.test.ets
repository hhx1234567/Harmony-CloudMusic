import { describe, it, expect } from '@ohos/hypium'
import { SongItemType } from '../main/ets/models/music'
import { SongPlaybackResolver } from '../main/ets/utils/SongPlaybackResolver'

export default function SongPlaybackResolverTest() {
  describe('SongPlaybackResolverTest', () => {
    const createSong = (url: string = ''): SongItemType => {
      return {
        id: '1001',
        name: 'online song',
        author: 'artist',
        img: 'https://example.com/cover.jpg',
        url: url
      }
    }

    it('existing_url_should_be_used_without_network_resolution', 0, async () => {
      let resolveCount: number = 0
      const song = createSong('https://example.com/existing.m4a')

      const result = await SongPlaybackResolver.resolve(song, async () => {
        resolveCount++
        return 'https://example.com/new.m4a'
      })

      expect(result?.url).assertEqual('https://example.com/existing.m4a')
      expect(resolveCount).assertEqual(0)
    })

    it('empty_url_should_be_resolved_without_mutating_source', 0, async () => {
      const song = createSong()

      const result = await SongPlaybackResolver.resolve(song, async (songId: string) => {
        expect(songId).assertEqual('1001')
        return 'https://example.com/resolved.m4a'
      })

      expect(result?.url).assertEqual('https://example.com/resolved.m4a')
      expect(song.url).assertEqual('')
    })

    it('empty_resolved_url_should_be_rejected', 0, async () => {
      const result = await SongPlaybackResolver.resolve(createSong(), async () => '')

      expect(result === null).assertTrue()
    })
  })
}
