import { describe, it, expect } from '@ohos/hypium'
import { FindViewModel } from '../main/ets/viewmodels/FindViewModel'
import { FindPageCache } from '../main/ets/models/cache'
import { SongItemType } from '../main/ets/models/music'

function createSong(id: string, name: string): SongItemType {
  return {
    id: id,
    name: name,
    author: 'test-author',
    img: 'https://example.com/cover.jpg',
    url: ''
  }
}

export default function FindViewModelTest() {
  describe('FindViewModelTest', () => {
    it('empty_search_should_not_call_provider', 0, async () => {
      const vm = new FindViewModel()
      const cache = new FindPageCache()
      let providerCalled: boolean = false
      vm.searchKeyword = '   '

      await vm.searchSongs(cache, async (): Promise<SongItemType[]> => {
        providerCalled = true
        return []
      })

      expect(providerCalled).assertEqual(false)
      expect(vm.loadErrorMessage).assertEqual('请输入歌曲名或歌手名')
    })

    it('successful_search_should_trim_keyword_and_replace_list', 0, async () => {
      const vm = new FindViewModel()
      const cache = new FindPageCache()
      cache.songs = [createSong('old', 'old-song')]
      vm.searchKeyword = ' 周杰伦 '
      let requestedKeyword: string = ''

      await vm.searchSongs(cache, async (keyword: string): Promise<SongItemType[]> => {
        requestedKeyword = keyword
        return [createSong('new', 'new-song')]
      })

      expect(requestedKeyword).assertEqual('周杰伦')
      expect(cache.songs[0].id).assertEqual('new')
      expect(vm.listTitle).assertEqual('“周杰伦”的搜索结果')
      expect(vm.isSearching).assertEqual(false)
    })

    it('empty_result_should_keep_existing_list', 0, async () => {
      const vm = new FindViewModel()
      const cache = new FindPageCache()
      cache.songs = [createSong('cached', 'cached-song')]
      vm.searchKeyword = 'unknown'

      await vm.searchSongs(cache, async (): Promise<SongItemType[]> => [])

      expect(cache.songs[0].id).assertEqual('cached')
      expect(vm.loadErrorMessage).assertEqual('未找到结果或网络不可用，已保留当前歌单')
    })

    it('search_error_should_keep_existing_list', 0, async () => {
      const vm = new FindViewModel()
      const cache = new FindPageCache()
      cache.songs = [createSong('cached', 'cached-song')]
      vm.searchKeyword = 'network-error'

      await vm.searchSongs(cache, async (): Promise<SongItemType[]> => {
        throw new Error('network unavailable')
      })

      expect(cache.songs[0].id).assertEqual('cached')
      expect(vm.loadErrorMessage).assertEqual('搜索失败，已保留当前歌单')
      expect(vm.isSearching).assertEqual(false)
    })
  })
}
