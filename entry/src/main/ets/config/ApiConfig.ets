export class ApiConfig {

    // AI 功能必须经过自己的服务端代理，客户端不保存厂商密钥。
    static readonly ENABLE_AI: boolean = false
    // 环境开关，上线时改为 true。
    static readonly IS_PROD: boolean = false
    // 生产环境必须使用 HTTPS，并替换为实际服务端域名。
    private static readonly PROD_API_BASE: string = 'https://api.yourdomain.com'
    // 开发环境使用设备可访问的电脑局域网地址；换网络后需按 README 更新。
    private static readonly DEV_API_BASE: string = 'http://10.27.61.193:3000'
    // 统一对外暴露 BaseUrl。
    static get MUSIC_API_BASE(): string {
        return this.IS_PROD ? this.PROD_API_BASE : this.DEV_API_BASE
    }
}
