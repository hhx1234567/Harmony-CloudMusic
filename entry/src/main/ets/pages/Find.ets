import { SongItemType } from "../models/music"
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalMusic } from "../models/globalMusic";
import { FindPageCache } from "../models/cache";
import { getRandomMusic, getSongRealUrl, searchMusic } from '../services/MusicService';
import { FindViewModel } from '../viewmodels/FindViewModel'

@ComponentV2
export struct Find {
  songAuthor: string[] = ['宇多田光', 'HOYO-MIX', 'reol', '鸣潮先约电台','Utada','松下悠也','凤凰传奇','徐良']
  pathStack : NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  //把缓存数据放入全局变量
  @Local cacheData: FindPageCache = AppStorageV2.connect(FindPageCache, 'FIND_CACHE_KEY', () => new FindPageCache())!
  @Local vm: FindViewModel = new FindViewModel()

  private runTask(task: Promise<void>, source: string): void {
    task.catch((err: Error) => {
      console.error(`[Find] ${source}异常：` + JSON.stringify(err))
    })
  }

  aboutToAppear(): void {
    //拦截器：如果歌曲列表有歌曲了，直接return，不发送请求
    if (this.cacheData && this.cacheData.songs.length > 0)
    {
      this.vm.isLoading = false
      return
    }
    //页面即将渲染时调用
    this.runTask(this.vm.loadRandomSongs(this.songAuthor, this.cacheData), '加载推荐歌曲')
  }
  // 获取音频真实链接
  async getSongUrl(id: string): Promise<string> {
    return await getSongRealUrl(id)
  }


  build() {
    Column() {
      if (this.vm.isLoading) {
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
        TextInput({placeholder: '为您推荐符合今天情绪的歌曲', text: this.vm.userInput})
          .onChange((value: string) => {
            this.vm.userInput = value
          })
          .placeholderColor(Color.White)
          .fontColor(Color.White)
          .backgroundColor(Color.Gray)
          .width('90%')       // 占据屏幕 90% 的宽度，两边留白才好看
          .height(45)         // 给一个黄金比例的固定高度（45vp 适合手指点击）
          .borderRadius(20)   // (锦上添花) 给个圆角，立刻变身现代 UI！
          .margin({ bottom: 15 }) // 和下面的按钮拉开一点距离
        Button(this.vm.isAILoading ? 'AI 正在深度思考...' : '让 AI 推荐歌曲')
          .fontColor(Color.White)
          .enabled(!this.vm.isAILoading && this.vm.userInput.length > 0)
          .onClick(() => {
            this.runTask(this.vm.askAI(), 'AI推荐')
          })
        if (this.vm.aiKeyword) {
          Column({ space: 10 }) {
            Text('🎵 AI 推荐搜索词：' + this.vm.aiKeyword)
              .fontColor('#ff6600')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)

            Text('💡 AI 的理由：' + this.vm.aiReason)
              .fontColor(Color.Gray)
              .fontSize(14)
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#f0f0f0')
          .borderRadius(10)
        }
        //$$意味变量和组件是双向连通，触发了框架的下拉动作时，ArkUI框架在底层会自动把 isRefreshing 变成 true
        Refresh({ refreshing: $$this.vm.isRefreshing}) {
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
                .onClick(() => {
                  this.runTask(this.vm.playSong(item, this.pathStack), '播放歌曲')
                })
              }
            })
          }
          .scrollBar(BarState.Off)
        }
        .onRefreshing(() => {
          console.info('用户触发下拉刷新，开始重新请求随机歌曲')
          this.runTask(this.vm.loadRandomSongs(this.songAuthor, this.cacheData), '刷新推荐歌曲')
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
