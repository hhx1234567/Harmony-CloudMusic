//整个网络请求收发器
import { http } from '@kit.NetworkKit';
import { ApiConfig } from '../config/ApiConfig';
//1.设立一个对外暴露窗口，谁要发送告诉我要去哪个接口，请求方法是什么，带了什么数据
//2.准备纸箱，创建一个底层的网络请求对象，拼接上网络请求完整前缀
//3.请求拦截，发件前操作：1.设置超时时间  2.把全局通行证塞进Header
//4.正式发件等待回信，设置try-catch
//5.相应拦截，收到回信：1.200，把干净数据拿出来；2.401无权限，扔掉包裹并弹窗重新登录，给请求方返回null;3.500如服务器炸了，扔掉回个null
//6.不管这次请求是否成功，纸箱必须销毁，不然会导致快递室塞满垃圾（内存泄漏）

export class HttpClient {

  // 对应骨架 1：设立寄件窗口 (传参)
  static async request(
    endpoint: string,
    method: http.RequestMethod = http.RequestMethod.GET,
    extraData?: Object,
    customHeader?: Record<string, string>
  ): Promise<object | null> {

    // 对应骨架 2：准备纸箱子和完整地址
    let httpRequest = http.createHttp();
    let fullUrl = endpoint;


    let finalHeader: Record<string, string> = {
      'Content-Type': 'application/json'
    };

    if (customHeader) {
      let keys = Object.keys(customHeader);
      for (let key of keys) {
        finalHeader[key] = customHeader[key];
      }
    }

    try {
      // 对应骨架 3 + 4：【请求拦截】发件，塞 Header，等回信
      console.info(`【网络拦截器】准备发射: ${method} -> ${fullUrl}`);
      let response = await httpRequest.request(fullUrl, {
        method: method,
        header: finalHeader,
        extraData: extraData,
        connectTimeout: 10000, // 统一设置超时
        readTimeout: 15000 // 因为你要呼叫 AI，这里最好给个 15 秒的读取时间
      });

      // 对应骨架 5：【响应拦截】拆包裹判断
      if (response.responseCode === 200) {
        return JSON.parse(response.result as string); // 200 成功：拿干净数据
      } else if (response.responseCode === 401) {
        console.error('没权限'); return null; // 401 失败：拦截报错
      } else {
        console.error('服务器异常'); return null; // 其他失败：拦截报错
      }

    } catch (err) {
      // 对应骨架 4 的翻车情况：断网
      console.error('网络彻底断开', err);
      return null;

    } finally {
      // 对应骨架 6：打扫卫生，必须销毁！
      httpRequest.destroy();
    }
  }
}