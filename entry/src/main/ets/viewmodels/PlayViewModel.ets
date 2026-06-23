import { playerManager } from '../utils/AvPlayerManager';

@ObservedV2
export class PlayViewModel {
  // 1. 追踪播放列表面板的动画状态
  @Trace panelHeight: string = '0%';
  @Trace panelOpacity: number = 0;

  // 2. 核心计算：毫秒转换时间戳格式 (纯计算逻辑剥离)
  number2time(number: number): string {
    if (number > 60 * 1000) {
      const s = Math.floor(number / 1000 % 60);
      const m = Math.floor(number / 1000 / 60);
      const second = s.toString().padStart(2, '0');
      const minute = m.toString().padStart(2, '0');
      return minute + ':' + second;
    } else {
      const s = Math.floor(number / 1000 % 60);
      const second = s.toString().padStart(2, '0');
      return '00:' + second;
    }
  }

  // 3. 面板行为控制
  showListPanel() {
    this.panelHeight = '50%';
    this.panelOpacity = 1;
  }

  hideListPanel() {
    this.panelHeight = '0%';
    this.panelOpacity = 0;
  }

  // 4. 进度条拖拽事件转发
  handleSeek(value: number) {
    playerManager.seekPlay(value);
  }
}