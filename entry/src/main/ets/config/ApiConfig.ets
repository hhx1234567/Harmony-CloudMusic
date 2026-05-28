export class ApiConfig {
    static readonly DEEPSEEK_API_KEY: string = 'sk-d76f0201fccc4451aac00201adc14308'
    //环境开关，上线时改为true
    static readonly IS_PROD: boolean = false
    //定义生产环境域名（必须是HTTPS）
    private static readonly PROD_API_BASE: string = 'https://api.yourdomain.com'
    // 3. 定义开发环境 IP（目前允许 HTTP 用于本地调试）
    private static readonly DEV_API_BASE: string = 'http://10.27.105.249:3000'
    //统一对外暴露的 BaseUrl
    static get MUSIC_API_BASE():string {
        return this.IS_PROD ? this.PROD_API_BASE : this.DEV_API_BASE
    }
}