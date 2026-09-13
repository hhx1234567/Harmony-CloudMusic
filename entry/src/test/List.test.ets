import localUnitTest from './LocalUnit.test';
import AvPlayerManagerTest from './AvPlayerManager.test'; // 引入你的测试
import PlayViewModelTest from './PlayViewModel.test';
import PlaybackQueuePolicyTest from './PlaybackQueuePolicy.test';
import AIAssistantTest from './AIAssistant.test';
import SongPlaybackResolverTest from './SongPlaybackResolver.test';
import FindViewModelTest from './FindViewModel.test';
import FavoriteSongsPolicyTest from './FavoriteSongsPolicy.test';

export default function testsuite() {
  localUnitTest();
  AvPlayerManagerTest();
  PlayViewModelTest()
  PlaybackQueuePolicyTest()
  AIAssistantTest()
  SongPlaybackResolverTest()
  FindViewModelTest()
  FavoriteSongsPolicyTest()
}
