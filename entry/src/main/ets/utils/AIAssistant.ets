import { ApiConfig } from '../config/ApiConfig'

// 1. 定义大模型返回的数据结构防腐层,只提取 UI 真正需要的数据
export interface AIResponseFormat {
  keyword: string;//推荐关键词
  reason: string;//推荐理由
}

export class AIAssistant {
  isEnabled(): boolean {
    return ApiConfig.ENABLE_AI
  }

  /**
   * AI 厂商密钥不能保存在客户端。服务端代理完成前只返回安全提示。
   * 可以把客户端理解成“发给每位用户的透明盒子”：写进安装包的密钥最终都能被取出，
   * 所以这里故意不保留接口地址、密钥和网络请求代码。
   * @param userInput 用户的自然语言输入
   * @returns 可直接展示的推荐结果或停用提示
   */
  async ask(userInput: string): Promise<AIResponseFormat> {
    // 先处理空输入，让 UI 能给用户明确提示，而不是继续执行后面的功能判断。
    if (!userInput.trim()) {
      return {
        keyword: '',
        reason: '请输入希望推荐的音乐类型或心情'
      }
    }

    // 当前开关为 false。以后即使恢复 AI，也应请求“自己的业务后端”，不能在这里直连 AI 厂商。
    if (!ApiConfig.ENABLE_AI) {
      return {
        keyword: '',
        reason: 'AI推荐功能正在进行安全后端改造'
      }
    }

    // 安全兜底：有人误开开关但服务端代理尚未接入时，也不会发起不安全的请求。
    return {
      keyword: '',
      reason: 'AI推荐功能暂不可用'
    }
  }
}

export const aiAssistant = new AIAssistant();
