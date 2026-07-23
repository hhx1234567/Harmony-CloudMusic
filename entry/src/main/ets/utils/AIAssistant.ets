import { ApiConfig } from '../config/ApiConfig'

// 1. 定义大模型返回的数据结构防腐层,只提取 UI 真正需要的数据
export interface AIResponseFormat {
  keyword: string;//推荐关键词
  reason: string;//推荐理由
}

export class AIAssistant {
  /**
   * AI 厂商密钥不能保存在客户端。服务端代理完成前只返回安全提示。
   * @param userInput 用户的自然语言输入
   * @returns 可直接展示的推荐结果或停用提示
   */
  async ask(userInput: string): Promise<AIResponseFormat> {
    if (!userInput.trim()) {
      return {
        keyword: '',
        reason: '请输入希望推荐的音乐类型或心情'
      }
    }

    if (!ApiConfig.ENABLE_AI) {
      return {
        keyword: '',
        reason: 'AI推荐功能正在进行安全后端改造'
      }
    }

    return {
      keyword: '',
      reason: 'AI推荐功能暂不可用'
    }
  }
}

export const aiAssistant = new AIAssistant();
