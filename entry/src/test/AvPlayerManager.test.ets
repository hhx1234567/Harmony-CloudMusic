import { describe, it, expect } from '@ohos/hypium';
import { playerManager } from '../main/ets/utils/AvPlayerManager';
import { SongItemType } from '../main/ets/models/music';

export default function AvPlayerManagerTest() {
  describe('AvPlayerManagerTest', () => {

    // 无效URL必须在接触播放器和播放列表前被拒绝。
    it('singPlay_should_reject_empty_url', 0, async () => {
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
