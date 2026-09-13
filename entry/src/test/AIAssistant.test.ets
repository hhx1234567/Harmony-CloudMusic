import { describe, it, expect } from '@ohos/hypium'
import { aiAssistant } from '../main/ets/utils/AIAssistant'

export default function AIAssistantTest() {
  describe('AIAssistantTest', () => {
    it('blank_input_should_return_validation_message', 0, async () => {
      const result = await aiAssistant.ask('   ')
      expect(result.keyword).assertEqual('')
      expect(result.reason).assertContain('请输入')
    })

    it('disabled_feature_should_not_expose_provider_request', 0, async () => {
      const result = await aiAssistant.ask('适合学习时听的歌')
      expect(aiAssistant.isEnabled()).assertFalse()
      expect(result.keyword).assertEqual('')
      expect(result.reason).assertContain('安全后端')
    })
  })
}
