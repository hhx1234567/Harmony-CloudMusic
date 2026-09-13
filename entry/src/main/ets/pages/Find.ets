import { SongItemType } from "../models/music"
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalMusic } from "../models/globalMusic";
import { FindPageCache } from "../models/cache";
import { FindViewModel } from '../viewmodels/FindViewModel'

@ComponentV2
export struct Find {
  songAuthor: string[] = ['宇多田光', 'HOYO-MIX', 'reol', '鸣潮先约电台','Utada','松下悠也','凤凰传奇','徐良']
  pathStack : NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  // 发现页使用的内存缓存。相同 FIND_CACHE_KEY 会取得同一个 FindPageCache 对象。
  // ViewModel 修改 findPageCache.songs 后，当前页面会直接读取到新数据。
  @Local findPageCache: FindPageCache = AppStorageV2.connect(
    FindPageCache,
    'FIND_CACHE_KEY',
    () => new FindPageCache()
  )!
  @Local viewModel: FindViewModel = new FindViewModel()

  /**
   * 给已经启动的异步任务补上统一的异常处理。
   * task 传进来之前，对应的 ViewModel 方法已经被调用，并返回了 Promise。
   */
  private observeAsyncTask(task: Promise<void>, source: string): void {
    task.catch((err: Error) => {
      console.error(`[Find] ${source}异常：` + JSON.stringify(err))
    })
  }

  /** 加载或刷新推荐歌曲，并把返回结果写入发现页共享缓存。 */
  private loadRecommendedSongs(source: string): void {
    const loadTask: Promise<void> = this.viewModel.loadRandomSongs(
      this.songAuthor,
      this.findPageCache
    )
    this.observeAsyncTask(loadTask, source)
  }

  /** 使用输入框中的关键字搜索歌曲，搜索结果仍写入同一个发现页缓存。 */
  private searchCurrentKeyword(): void {
    const searchTask: Promise<void> = this.viewModel.searchSongs(this.findPageCache)
    this.observeAsyncTask(searchTask, '搜索歌曲')
  }

  /** 请求 AI 推荐；该功能只更新 FindViewModel 中的推荐文案。 */
  private requestAIRecommendation(): void {
    const aiTask: Promise<void> = this.viewModel.askAI()
    this.observeAsyncTask(aiTask, 'AI推荐')
  }

  /**
   * 播放用户点击的歌曲。
   * selectedSong 表示当前歌曲，findPageCache.songs 表示它所在的完整歌单。
   */
  private playSelectedSong(selectedSong: SongItemType): void {
    const playTask: Promise<void> = this.viewModel.playSong(
      selectedSong,
      this.pathStack,
      this.findPageCache.songs
    )
    this.observeAsyncTask(playTask, '播放歌曲')
  }

  aboutToAppear(): void {
    // 缓存已有歌曲时直接复用，避免切换 Tab 后重复请求服务器。
    if (this.findPageCache.songs.length > 0) {
      this.viewModel.isLoading = false
      return
    }
    this.loadRecommendedSongs('加载推荐歌曲')
  }
  build() {
    Column() {
      if (this.viewModel.isLoading) {
        LoadingProgress()
          .width(50)
          .height(50)
        Text('正在连接服务器......')
          .fontColor('#ffa118c4')
      }
      else {
        if (this.viewModel.loadErrorMessage) {
          Row({ space: 12 }) {
            Text(this.viewModel.loadErrorMessage)
              .fontColor('#FFB4AB')
              .fontSize(14)
              .layoutWeight(1)
            Button('重试')
              .fontSize(13)
              .height(32)
              .onClick(() => {
                this.loadRecommendedSongs('重试加载推荐歌曲')
              })
          }
          .width('100%')
          .padding(10)
          .margin({ bottom: 10 })
          .backgroundColor('#3A2020')
          .borderRadius(8)
        }
        Text(this.viewModel.listTitle)
          .fontColor('#fff')
          .width('100%')
          .margin({ bottom: 10 })
        Row({ space: 10 }) {
          TextInput({ placeholder: '搜索歌曲或歌手', text: this.viewModel.searchKeyword })
            .onChange((value: string) => {
              this.viewModel.searchKeyword = value
            })
            .placeholderColor('#8C8C8C')
            .fontColor(Color.White)
            .backgroundColor('#2D2B29')
            .height(44)
            .borderRadius(22)
            .layoutWeight(1)
          Button(this.viewModel.isSearching ? '搜索中' : '搜索')
            .height(44)
            .fontColor(Color.White)
            .backgroundColor('#C62F2F')
            .enabled(!this.viewModel.isSearching && this.viewModel.searchKeyword.trim().length > 0)
            .onClick(() => {
              this.searchCurrentKeyword()
            })
        }
        .width('100%')
        .margin({ bottom: 12 })
        if (this.viewModel.isAIEnabled) {
          TextInput({placeholder: '为您推荐符合今天情绪的歌曲', text: this.viewModel.userInput})
            .onChange((value: string) => {
              this.viewModel.userInput = value
            })
            .placeholderColor(Color.White)
            .fontColor(Color.White)
            .backgroundColor(Color.Gray)
            .width('90%')
            .height(45)
            .borderRadius(20)
            .margin({ bottom: 15 })
          Button(this.viewModel.isAILoading ? 'AI 正在深度思考...' : '让 AI 推荐歌曲')
            .fontColor(Color.White)
            .enabled(!this.viewModel.isAILoading && this.viewModel.userInput.length > 0)
            .onClick(() => {
              this.requestAIRecommendation()
            })
          if (this.viewModel.aiKeyword || this.viewModel.aiReason) {
            Column({ space: 10 }) {
              if (this.viewModel.aiKeyword) {
                Text('🎵 AI 推荐搜索词：' + this.viewModel.aiKeyword)
                  .fontColor('#ff6600')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
              }

              Text('💡 AI 的理由：' + this.viewModel.aiReason)
                .fontColor(Color.Gray)
                .fontSize(14)
            }
            .width('90%')
            .padding(15)
            .backgroundColor('#f0f0f0')
            .borderRadius(10)
          }
        }
        if (this.viewModel.playErrorMessage) {
          Text(this.viewModel.playErrorMessage)
            .width('100%')
            .padding(10)
            .margin({ top: 10 })
            .fontColor('#FFB4AB')
            .backgroundColor('#3A2020')
            .borderRadius(8)
        }
        //$$意味变量和组件是双向连通，触发了框架的下拉动作时，ArkUI框架在底层会自动把 isRefreshing 变成 true
        Refresh({ refreshing: $$this.viewModel.isRefreshing}) {
          List() {
            ForEach(this.findPageCache.songs, (item: SongItemType, index: number) => {
              ListItem() {
                Row() {
                  // 图
                  Stack() {
                    Image(item.img)
                      .width(80)
                      .border({ radius: 8 })
                      .margin({ right: 10 })
                    // 在线列表的原始URL为空，使用稳定的歌曲ID判断当前播放项。
                    if (this.playState.id === item.id && this.playState.isPlay) {
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
                  this.playSelectedSong(item)
                })
              }
            })
          }
          .scrollBar(BarState.Off)
        }
        .onRefreshing(() => {
          console.info('用户触发下拉刷新，开始重新请求随机歌曲')
          this.viewModel.searchKeyword = ''
          this.loadRecommendedSongs('刷新推荐歌曲')
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
