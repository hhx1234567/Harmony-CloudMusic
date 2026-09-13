import { describe, it, expect } from '@ohos/hypium';
import { PlayViewModel } from '../main/ets/viewmodels/PlayViewModel';

export default function PlayViewModelTest() {
  describe('PlayViewModelTest', () => {

    const vm = new PlayViewModel();

    it('number2time_should_format_regular_duration', 0, () => {
      expect(vm.number2time(65000)).assertEqual('01:05');
      expect(vm.number2time(125000)).assertEqual('02:05');
    });

    it('number2time_should_handle_boundary_values', 0, () => {
      expect(vm.number2time(30000)).assertEqual('00:30');
      expect(vm.number2time(0)).assertEqual('00:00');
    });

    it('number2time_should_clamp_invalid_values', 0, () => {
      expect(vm.number2time(-1000)).assertEqual('00:00');
      expect(vm.number2time(Number.NaN)).assertEqual('00:00');
    });

    it('getNextPlayMode_should_cycle_all_modes', 0, () => {
      expect(vm.getNextPlayMode('auto')).assertEqual('random');
      expect(vm.getNextPlayMode('random')).assertEqual('repeat');
      expect(vm.getNextPlayMode('repeat')).assertEqual('auto');
    });
  });
}
