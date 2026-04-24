import { SongItemType } from "../models/music"
import { AppStorageV2 } from '@kit.ArkUI';
import { playerManager } from "../utils/AvPlayerManager";
import { GlobalMusic } from "../models/globalMusic";
import http from '@ohos.net.http';
import { FindPageCache } from "../models/cache";
import { aiAssistant } from '../utils/AIAssistant';

//歌手画像
interface NetEaseArtist {
  name: string
}
//专辑画像
interface NetEaseAlbum {
  picUrl: string
}
//歌曲本尊画像，只挑了要的字段来写
interface NetEaseSong {
  id: number,
  name: string,
  ar: NetEaseArtist[],//歌手是个数组
  al: NetEaseAlbum //专辑是个对象
}

interface NetEaseResult {
  songs: NetEaseSong[];
}

interface NetEaseResponse {
  code: number;
  result: NetEaseResult
}
interface NetEaseUrl {
  url: string
}
interface NetEaseDataUrl {
  code: number,
  data: NetEaseUrl[]
}

@ComponentV2
export struct Find {
  /*songs: SongItemType[] = [
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.jpg',
      name: '直到世界的尽头',
      author: 'WANDS',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.m4a',
      id: '0000'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.jpg',
      name: '画',
      author: '赵磊',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.mp3',
      id: '0001'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.jpg',
      name: 'Sweet Dreams',
      author: 'TPaul Sax / Eurythmics',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.mp3',
      id: '0002'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.jpg',
      name: '奢香夫人',
      author: '凤凰传奇',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.m4a',
      id: '0003'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.jpg',
      name: '空心',
      author: '光泽',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.mp3',
      id: '0004'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.jpg',
      name: '反转地球',
      author: '潘玮柏',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.mp3',
      id: '0005'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.jpg',
      name: 'No.9',
      author: 'T-ara',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.m4a',
      id: '0006'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.jpg',
      name: '孤独',
      author: 'G.E.M.邓紫棋',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.m4a',
      id: '0007'
    },

    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.jpg',
      name: 'Lose Control',
      author: 'Hedley',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.m4a',
      id: '0008'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.jpg',
      name: '倩女幽魂',
      author: '张国荣',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.m4a',
      id: '0009'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.jpg',
      name: '北京北京',
      author: '汪峰',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.m4a',
      id: '0010'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.jpg',
      name: '苦笑',
      author: '汪苏泷',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.mp3',
      id: '0011'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.jpg',
      name: '一生所爱',
      author: '卢冠廷 / 莫文蔚',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.m4a',
      id: '0012'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.jpg',
      name: '月半小夜曲',
      author: '李克勤',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.mp3',
      id: '0013'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.jpg',
      name: 'Rolling in the Deep',
      author: 'Adele',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.m4a',
      id: '0014'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.jpg',
      name: '海阔天空',
      author: 'Beyond',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.m4a',
      id: '0015'
    }
  ]*/
  songAuthor: string[] = ['宇多田光', 'HOYO-MIX', 'reol', '鸣潮先约电台','Utada','松下悠也']
  pathStack : NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  //把缓存数据放入全局变量
  @Local cacheData: FindPageCache = AppStorageV2.connect(FindPageCache, 'FIND_CACHE_KEY', () => new FindPageCache())!
  //正在加载状态
  @Local isLoading: boolean = true
  //控制下拉刷新状态的变量
  @Local isRefreshing: boolean = false
  //用户输入的心情
  @Local userInput: string = ''
  //控制按钮防抖与 Loading 动画
  @Local isAILoading: boolean = false
  //接收大模型的推荐关键词和理由
  @Local aiKeyword: string = ''
  @Local aiReason: string = ''


  aboutToAppear(): void {
    //拦截器：如果歌曲列表有歌曲了，直接return，不发送请求
    if (this.cacheData && this.cacheData.songs.length > 0)
    {
      this.isLoading = false
      return
    }
    //页面即将渲染时调用
    this.getRealSongs()
  }
  //核心方法
  async getRealSongs() {
    //确保一开始一定是加载状态
    this.isLoading = true
    //创建HTTP请求实例，创建一个httpRequest对象用于后续发送请求
    let httpRequest = http.createHttp()
    try {
      // 1. 防御性拦截：如果数组是空的，直接退出，不发请求
      if (!this.songAuthor || this.songAuthor.length === 0) {
        console.warn("⚠️ 歌手列表为空，请先获取歌手数据！");
        return;
      }
      // 2. 随机抽取歌手
      let currentAuthor = this.songAuthor[Math.floor(Math.random() * this.songAuthor.length)];
      console.info("🎲 抽中了歌手: " + currentAuthor);
      // 3. 核心装甲：对歌手名字进行 URL 编码（比如把空格变成 %20）
      let safeKeyword = encodeURIComponent(currentAuthor);
      //发送网络请求
      let res = await httpRequest.request(
        `http://10.27.105.249:3000/cloudsearch?keywords=${safeKeyword}`,
        {
          method: http.RequestMethod.GET, //请求方法
          connectTimeout: 10000 //十秒超时
        })
      if (res.responseCode === 200) {
        //解析传回来的JSON字符穿
        let rawObj = JSON.parse(res.result as string) as NetEaseResponse
        if (rawObj.code === 200 && rawObj.result?.songs){
          let cleanSongs: SongItemType[] = rawObj.result.songs.map((rawItem) => {
            return {
              id: rawItem.id.toString(),
              name: rawItem.name,
              author: (rawItem.ar && rawItem.ar.length > 0) ? rawItem.ar[0].name : '未知歌手',
              img: rawItem.al.picUrl.replace('http://', 'https://'),
              url: ''
            } as SongItemType
          })
          this.cacheData.songs = cleanSongs
        }
      }
      else {
        console.error('服务器开小差了，状态码：',res.responseCode)
      }
    }
    catch (err) {
      console.error('网络请求出问题了：',JSON.stringify(err))
    }
    finally {
      //无论是否成功最后都要关掉转圈圈
      this.isLoading = false
      //销毁HttpRequest实例，释放系统内存，避免内存泄漏
      httpRequest.destroy()
      //无论成功与否把刷新的圈圈关掉
      this.isRefreshing = false
    }
  }

  // 获取音频真实链接
  async getSongUrl(id: string): Promise<string> {
    let httpRequest = http.createHttp()
    try {
      let res = await httpRequest.request(
        `http://10.27.105.249:3000/song/url/v1?id=${id}&level=standard`,
        { method: http.RequestMethod.GET }
      )
      if (res.responseCode === 200) {
        let rawObj = JSON.parse(res.result as string) as NetEaseDataUrl
        // 网易云返回的结构是 { data: [{ url: '...' }] }
        if (rawObj.code && rawObj.data && rawObj.data.length > 0) {
          return rawObj.data[0].url as string
        }
      }
    } catch (err) {
      console.error("获取链接失败", JSON.stringify(err))
    } finally {
      httpRequest.destroy()
    }
    return ''
  }


  build() {
    Column() {
      if (this.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
        Text('正在连接服务器......')
          .fontColor('#ffa118c4')
      }
      else {
        Text('猜你喜欢')
          .fontColor('#fff')
          .width('100%')
          .margin({ bottom: 10 })
        //text: this.userInput:强迫输入死死地盯着this.userInput，无论你穿什么衣服，输入都必须无条件反射出来   赋予代码随时接管、篡改、恢复 UI 文本的绝对权力
        TextInput({placeholder: '为您推荐符合今天情绪的歌曲', text: this.userInput})
          .onChange((value: string) => {
            this.userInput = value
          })
          .placeholderColor(Color.White)
          .fontColor(Color.White)
          .backgroundColor(Color.Gray)
          .width('90%')       // 占据屏幕 90% 的宽度，两边留白才好看
          .height(45)         // 给一个黄金比例的固定高度（45vp 适合手指点击）
          .borderRadius(20)   // (锦上添花) 给个圆角，立刻变身现代 UI！
          .margin({ bottom: 15 }) // 和下面的按钮拉开一点距离
        Button(this.isAILoading ? 'AI 正在深度思考...' : '让 AI 推荐歌曲')
          .fontColor(Color.White)
          .enabled(!this.isAILoading && this.userInput.length > 0)
          .onClick(async () => {
            this.isAILoading = true
            this.aiKeyword = ''
            this.aiReason = ''
            let result = await aiAssistant.ask(this.userInput)
            this.aiKeyword = result.keyword
            this.aiReason = result.reason
            this.isAILoading = false
          })
        if (this.aiKeyword) {
          Column({ space: 10 }) {
            Text('🎵 AI 推荐搜索词：' + this.aiKeyword)
              .fontColor('#ff6600')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('💡 AI 的理由：' + this.aiReason)
              .fontColor(Color.Gray)
              .fontSize(14)
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#f0f0f0')
          .borderRadius(10)
        }
        Refresh({ refreshing: $$this.isRefreshing}) {
          List() {
            ForEach(this.cacheData.songs, (item: SongItemType, index: number) => {
              ListItem() {
                Row() {
                  // 图
                  Stack() {
                    Image(item.img)
                      .width(80)
                      .border({ radius: 8 })
                      .margin({ right: 10 })
                    //条件渲染: 正在播放的音乐才渲染这个图 -> currentSong.url === song.url 且 isPlay = true
                    if (this.playState.url === item.url && this.playState.isPlay) {
                      Image($r('app.media.wave'))
                        .width(24)
                    }

                  }

                  // 字
                  Column() {
                    Text(item.name)
                      .fontColor('#F3F3F3')
                      .width('100%')
                      .fontWeight(700)
                      .margin({ bottom: 15 })
                    Row() {
                      Text('VIP')
                        .fontColor('#9A8E28')
                        .border({ width: 1, color: '#9A8E28', radius: 12 })
                        .padding({
                          left: 5,
                          right: 5,
                          top: 3,
                          bottom: 3
                        })
                        .margin({ right: 10 })
                      Text(item.author)
                        .fontColor('#696969')
                    }
                    .width('100%')
                  }
                  .layoutWeight(1)

                  // 更多
                  Image($r('app.media.more'))
                    .width(24)
                    .fillColor('#FEFEFE')
                }
                .width('100%')
                .height(80)
                // .backgroundColor(Color.Pink)
                .margin({ bottom: 10 })
                .onClick(async  () => {
                  this.pathStack.pushPathByName('Play',null, false)
                  let realUrl = await this.getSongUrl(item.id)
                  if (realUrl) {
                    item.url = realUrl
                    playerManager.singPlay(item)
                  }
                })
              }
            })
          }
          .scrollBar(BarState.Off)
        }
        .onRefreshing(() => {
          console.info('用户触发下拉刷新，开始重新请求随机歌曲')
          this.getRealSongs()
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131313')
    .padding({ left: 10, right: 10 })
    // 扩充组件安全区域
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}