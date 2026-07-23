export class ApiConfig {

    // AI功能必须经过自己的服务端代理，客户端不保存厂商密钥。
    static readonly ENABLE_AI: boolean = false
    //环境开关，上线时改为true
    static readonly IS_PROD: boolean = false
    //定义生产环境域名（必须是HTTPS）
    private static readonly PROD_API_BASE: string = 'https://api.yourdomain.com'
    // 3. 定义开发环境 IP（目前允许 HTTP 用于本地调试）
    private static readonly DEV_API_BASE: string = 'http://192.168.10.2:3000'
    //统一对外暴露的 BaseUrl
    static get MUSIC_API_BASE():string {
        return this.IS_PROD ? this.PROD_API_BASE : this.DEV_API_BASE
    }
}