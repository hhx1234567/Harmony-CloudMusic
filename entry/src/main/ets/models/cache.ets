import { Type } from '@kit.ArkUI'; // 引入 V2 相关的包
import { SongItemType } from './music';

@ObservedV2
export class FindPageCache {
  // 用 @Trace 追踪数组变化，只要数据一变，UI 瞬间刷新
  @Trace songs: SongItemType[] = [];
}