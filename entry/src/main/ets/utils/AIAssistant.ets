import http from '@ohos.net.http';
import { ApiConfig } from '../config/ApiConfig'
import { HttpClient } from '../utils/HttpClient'
// 1. 定义大模型返回的数据结构防腐层,只提取 UI 真正需要的数据
export interface AIResponseFormat {
  keyword: string;//推荐关键词
  reason: string;//推荐理由
}
//大模型返回的字符串格式：{ "choices": [ { "message": { "content": "..." } } ] }
interface LLMMessage {
  content: string
}
interface LLMChoice {
  message: LLMMessage
}
interface LLMResponse {
  choices: LLMChoice[]
}



interface DeepSeekMessage {
  role: string;
  content: string;
}

interface DeepSeekResponseFormat {
  type: string;
}

interface DeepSeekRequestBody {
  model: string;
  messages: DeepSeekMessage[];
  response_format: DeepSeekResponseFormat;
}


export class AIAssistant {

  //不要把密钥直接写进业务组件内

  private readonly API_URL = 'https://api.deepseek.com/v1/chat/completions';

  /**
   * 向 AI 发起询问
   * @param userInput 用户的自然语言输入
   * @returns 返回解析后的 JSON 对象，如果出错则返回 null
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

  /**
  async ask(userInput: string): Promise<AIResponseFormat> {
    console.info("🤖 [AIAssistant] 正在呼叫 AI 音乐大脑...");

    let requestBody: DeepSeekRequestBody = {
      model: "deepseek-chat",
      messages: [
        { role: "system", content: "你是一个专业的AI音乐推荐助手。不要闲聊，不要输出 markdown，不要包含任何格式化符号。必须、且只能输出一个标准的 JSON 对象，格式为：{\"keyword\": \"歌手名 歌曲名\", \"reason\": \"一句话推荐理由\"}" },
        { role: "user", content: userInput }
      ],
      response_format: { type: "json_object" }
    };

    // 👇 2. 把包装好的合法对象，直接丢给收发室
    let llmResult = await HttpClient.request(
      this.API_URL,
      http.RequestMethod.POST,
      requestBody,                              // 直接传合法变量 requestBody！
      {
        'Authorization': `Bearer ${ApiConfig.DEEPSEEK_API_KEY}`
      }
    ) as LLMResponse | null;

    // --- 下面的逻辑，专心处理 AI 的文本解析防腐层 ---

    // 如果拦截器返回 null（说明网络断了或 Key 错了），直接走兜底
    if (!llmResult) {
      return { keyword: "周杰伦", reason: "网络信号不佳，请检查网络" };
    }

    if (llmResult.choices && llmResult.choices.length > 0) {
      let contentString = llmResult.choices[0].message.content;
      console.info("🤖 [AIAssistant] AI 提取的内容: " + contentString);

      let cleanString = contentString.replace(/```json/g, '').replace(/```/g, '').trim();

      try {
        let aiAdvice = JSON.parse(cleanString) as AIResponseFormat;
        if (aiAdvice && aiAdvice.keyword) {
          return aiAdvice;
        } else {
          throw new Error('JSON 格式正确，但缺少关键字段');
        }
      } catch (parseError) {
        console.error('❌ [AIAssistant] AI 返回的数据无法解析为 JSON');
        return { keyword: "周杰伦", reason: "AI 刚才思考得太入神，为您随机推荐了一组经典歌曲。" };
      }
    }

    return { keyword: "", reason: "AI 接口调用失败" };
  }
  */
}

export const aiAssistant = new AIAssistant();