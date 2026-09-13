import { describe, it, expect } from '@ohos/hypium'
import { PlaybackQueuePolicy } from '../main/ets/utils/PlaybackQueuePolicy'
import { SongItemType } from '../main/ets/models/music'

export default function PlaybackQueuePolicyTest() {
  describe('PlaybackQueuePolicyTest', () => {
    it('should_return_invalid_index_for_empty_list', 0, () => {
      expect(PlaybackQueuePolicy.previousIndex(0, 0, 'auto')).assertEqual(-1)
      expect(PlaybackQueuePolicy.nextIndex(0, 0, 'auto')).assertEqual(-1)
    })

    it('previous_should_move_backward_and_wrap', 0, () => {
      expect(PlaybackQueuePolicy.previousIndex(3, 2, 'auto')).assertEqual(1)
      expect(PlaybackQueuePolicy.previousIndex(3, 0, 'auto')).assertEqual(2)
    })

    it('next_should_move_forward_and_wrap', 0, () => {
      expect(PlaybackQueuePolicy.nextIndex(3, 1, 'auto')).assertEqual(2)
      expect(PlaybackQueuePolicy.nextIndex(3, 2, 'auto')).assertEqual(0)
    })

    it('repeat_should_only_hold_for_automatic_next', 0, () => {
      expect(PlaybackQueuePolicy.nextIndex(3, 1, 'repeat', true)).assertEqual(1)
      expect(PlaybackQueuePolicy.nextIndex(3, 1, 'repeat', false)).assertEqual(2)
    })

    it('random_should_be_deterministic_with_injected_value', 0, () => {
      expect(PlaybackQueuePolicy.previousIndex(4, 0, 'random', 0.75)).assertEqual(3)
      expect(PlaybackQueuePolicy.nextIndex(4, 0, 'random', false, 0.25)).assertEqual(1)
      expect(PlaybackQueuePolicy.nextIndex(4, 2, 'random', false, 0.50)).assertEqual(1)
    })

    it('random_should_clamp_out_of_range_values', 0, () => {
      expect(PlaybackQueuePolicy.nextIndex(4, 0, 'random', false, -1)).assertEqual(1)
      expect(PlaybackQueuePolicy.nextIndex(4, 0, 'random', false, 1)).assertEqual(3)
      expect(PlaybackQueuePolicy.nextIndex(4, 0, 'random', false, Number.NaN)).assertEqual(1)
    })

    it('random_should_not_repeat_current_song_when_alternatives_exist', 0, () => {
      expect(PlaybackQueuePolicy.nextIndex(2, 0, 'random', false, 0)).assertEqual(1)
      expect(PlaybackQueuePolicy.nextIndex(2, 1, 'random', false, 0.999)).assertEqual(0)
      expect(PlaybackQueuePolicy.previousIndex(5, 3, 'random', 0.75)).assertEqual(4)
    })

    it('random_should_keep_the_only_song_in_single_item_list', 0, () => {
      expect(PlaybackQueuePolicy.nextIndex(1, 0, 'random', false, 0.5)).assertEqual(0)
      expect(PlaybackQueuePolicy.previousIndex(1, 0, 'random', 0.5)).assertEqual(0)
    })

    it('invalid_current_index_should_recover_from_first_song', 0, () => {
      expect(PlaybackQueuePolicy.nextIndex(3, 99, 'auto')).assertEqual(1)
      expect(PlaybackQueuePolicy.previousIndex(3, -1, 'auto')).assertEqual(2)
    })

    it('build_context_should_keep_full_source_list_and_select_target', 0, () => {
      const sourceList: SongItemType[] = [
        { id: '1', name: 'one', author: 'a', img: '1.jpg', url: '' },
        { id: '2', name: 'two', author: 'b', img: '2.jpg', url: '' },
        { id: '3', name: 'three', author: 'c', img: '3.jpg', url: '' }
      ]
      const resolvedTarget: SongItemType = {
        id: '2', name: 'two', author: 'b', img: '2.jpg', url: 'https://example.com/2.m4a'
      }

      const context = PlaybackQueuePolicy.buildContext(sourceList, resolvedTarget)

      expect(context.playList.length).assertEqual(3)
      expect(context.targetIndex).assertEqual(1)
      expect(context.playList[1].url).assertEqual('https://example.com/2.m4a')
      expect(sourceList[1].url).assertEqual('')
    })

    it('build_context_should_prepend_target_missing_from_source', 0, () => {
      const sourceList: SongItemType[] = [
        { id: '1', name: 'one', author: 'a', img: '1.jpg', url: '' }
      ]
      const target: SongItemType = { id: '2', name: 'two', author: 'b', img: '2.jpg', url: '2.m4a' }

      const context = PlaybackQueuePolicy.buildContext(sourceList, target)

      expect(context.playList.length).assertEqual(2)
      expect(context.targetIndex).assertEqual(0)
      expect(context.playList[0].id).assertEqual('2')
    })

    it('next_candidates_should_wrap_in_play_order', 0, () => {
      const candidates = PlaybackQueuePolicy.nextCandidates(4, 0, 'auto')

      expect(JSON.stringify(candidates)).assertEqual('[1,2,3,0]')
      expect(JSON.stringify(PlaybackQueuePolicy.nextCandidates(4, 2, 'repeat', true))).assertEqual('[2]')
    })

    it('previous_candidates_should_wrap_in_reverse_order', 0, () => {
      const candidates = PlaybackQueuePolicy.previousCandidates(4, 0, 'auto')

      expect(JSON.stringify(candidates)).assertEqual('[3,2,1,0]')
    })
  })
}
