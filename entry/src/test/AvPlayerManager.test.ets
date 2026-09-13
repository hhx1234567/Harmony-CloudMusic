import { describe, it, expect } from '@ohos/hypium';
import { playerManager } from '../main/ets/utils/AvPlayerManager';
import { SongItemType } from '../main/ets/models/music';

export default function AvPlayerManagerTest() {
  describe('AvPlayerManagerTest', () => {

    // 这个用例不依赖真机播放器：播放器未初始化时必须安全拒绝，也不能污染播放列表。
    it('singPlay_should_reject_when_player_is_unavailable', 0, async () => {
      let testSong: SongItemType = {
        id: 'test_999',
        name: '测试之歌',
        author: '测试工程师',
        url: '',
        img: 'http://test.com/test.jpg'
      };
      let initialLength = playerManager.currentSong.playList.length;

      const applied = await playerManager.singPlay(testSong);

      expect(applied).assertFalse();
      expect(playerManager.currentSong.playList.length).assertEqual(initialLength);
    });

  });
}
