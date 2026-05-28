import http from '@ohos.net.http';
import { ApiConfig } from '../config/ApiConfig'

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

export class AIAssistant {

  //不要把密钥直接写进业务组件内

  private readonly API_URL = 'https://api.deepseek.com/v1/chat/completions';

  /**
   * 向 AI 发起询问
   * @param userInput 用户的自然语言输入
   * @returns 返回解析后的 JSON 对象，如果出错则返回 null
   */
  async ask(userInput: string): Promise<AIResponseFormat> {
    let httpRequest = http.createHttp();

    try {
      console.info("🤖 [AIAssistant] 正在呼叫 AI 音乐大脑...");

      let res = await httpRequest.request(
        this.API_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${ApiConfig.DEEPSEEK_API_KEY}`
          },
          // 核心魔法：系统提示词与强迫输出 JSON
          extraData: {
            model: "deepseek-chat", // 确保模型名称正确
            messages: [
              {
                role: "system",
                content: "你是一个专业的AI音乐推荐助手。不要闲聊，不要输出 markdown，不要包含任何格式化符号。必须、且只能输出一个标准的 JSON 对象，格式为：{\"keyword\": \"歌手名 歌曲名\", \"reason\": \"一句话推荐理由\"}"
              },
              {
                role: "user",
                content: userInput//用户输入的内容
              }
            ],
            // 某些模型支持强行指定输出格式，如果不支持可以注释掉这一行，靠上面的 prompt 约束
            response_format: { type: "json_object" }
          },
          readTimeout: 15000, // 给大模型多一点思考时间
          connectTimeout: 15000
        }
      );

      if (res.responseCode === 200) {
        // 1. 打印原始字符串看看，以防 API 报错（比如 Key 填错了）
        console.info("🤖 [AIAssistant] 原始网络返回: " + res.result);

        // 2. 强转为我们刚才定义的 LLMResponse 类型 ，解析整个网络包
        let llmResult = JSON.parse(res.result as string) as LLMResponse;

        // 3. 安全防御：确保 choices 真的存在且有数据，防止空指针闪退
        if (llmResult.choices && llmResult.choices.length > 0) {

          let contentString = llmResult.choices[0].message.content;
          console.info("🤖 [AIAssistant] AI 提取的内容: " + contentString);
          //解析 AI 说的那段话（即 content 字符串）
          //先尝试清理大模型可能带上的 Markdown 标记（非常常见的问题）
          let cleanString = contentString.replace(/```json/g, '').replace(/```/g, '').trim();

          //专门为 JSON 解析加一层 try-catch
          try {
            let aiAdvice = JSON.parse(cleanString) as AIResponseFormat;

            //校验一下核心字段存不存在
            if (aiAdvice && aiAdvice.keyword) {
              return aiAdvice;
            } else {
              throw new Error('JSON 格式正确，但缺少关键字段');
            }
          } catch (parseError) {
            console.error('❌ [AIAssistant] AI 返回的数据无法解析为 JSON:', contentString);
            // 返回一个友好的降级提示，而不是直接抛出网络异常
            return {
              keyword: "周杰伦", // 兜底搜索词
              reason: "AI 刚才思考得太入神，格式出错了，为您随机推荐了一组经典歌曲。" // 兜底理由
            };
          }

        } else {
          console.error("❌ [AIAssistant] 数据解析失败，大模型返回格式不对");
          return { keyword: "", reason: "网络信号不佳，请检查网络" };
        }
      }else {
        // 🛑 核心修复：补上这个 else！处理 400, 401, 404, 500 等各种 HTTP 错误！
        console.error(`❌ [AIAssistant] 请求失败，HTTP 状态码: ${res.responseCode}`);
        return { keyword: "", reason: "AI 接口调用失败，请检查 API Key 或网络" };
      }
    } catch (err) {
      console.error("❌ [AIAssistant] 网络请求异常", JSON.stringify(err));
      return { keyword: "", reason: "服务连接超时，请重试" };
    } finally {
      httpRequest.destroy();
    }
  }
}

// 导出一个单例，方便全局使用
export const aiAssistant = new AIAssistant();