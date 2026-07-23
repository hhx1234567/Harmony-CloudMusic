import { GlobalMusic } from "../models/globalMusic"
import { SongItemType } from "../models/music"
import { AppStorageV2 } from "@kit.ArkUI"
import { playerManager } from "../utils/AvPlayerManager"
import { PlayViewModel } from "../viewmodels/PlayViewModel"

// 跳转页面入口函数
@Builder
export function PlayBuilder() {
  Play()
}

@ComponentV2
struct Play {
  @Local vm: PlayViewModel = new PlayViewModel()
  pathStack : NavPathStack = new NavPathStack();

  // 当前播放的歌曲
  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  //playState:SongItemType = this.songs[0]

  private handlePlaybackAction(action: Promise<boolean>, source: string): void {
    action.then((applied: boolean) => {
      if (!applied) {
        console.info(`[Play] ${source}未应用`)
      }
    }).catch((err: Error) => {
      console.error(`[Play] ${source}异常：` + JSON.stringify(err))
    })
  }

  private playCurrentSong(): void {
    if (this.playState.isPlay) {
      playerManager.paused()
      return
    }

    const index = this.playState.playIndex
    if (this.playState.playList.length === 0 || index < 0 || index >= this.playState.playList.length) {
      console.info('[Play] 播放列表为空或当前索引无效，忽略播放按钮')
      return
    }
    this.handlePlaybackAction(playerManager.singPlay(this.playState.playList[index]), '播放当前歌曲')
  }

  private removePlayListSong(index: number): void {
    playerManager.removeSong(index).then((removed: boolean) => {
      if (removed && this.playState.playList.length === 0) {
        this.pathStack.pop()
      }
    }).catch((err: Error) => {
      console.error('[Play] 删除播放列表歌曲异常：' + JSON.stringify(err))
    })
  }


  @Builder
  deleteButton(index: number) {
    Button('删除')
      .backgroundColor('#ec5c87')
      .fontColor('#fff')
      .width(80)
      .height('100%')
      .type(ButtonType.Normal)
      .onClick(() => {
        this.removePlayListSong(index)
      })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        // 播放
        Stack() {
          // 变色背景
          Image(this.playState.img)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .blur(40)
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          //(新增的遮罩层)紧挨着写在 Image 后面，这样它就会盖在背景图上面，但垫在所有的 UI 控件下面
          Row()
            .width('100%')
            .height('100%')
            .backgroundColor('rgba(0, 0, 0, 0.4)') // 40%透明度的黑膜
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          // 内容
          Column() {
            // //   播放界面
            Column() {
              // 图片
              Stack({ alignContent: Alignment.Top }) {
                Row() {
                  Row() {
                    Image(this.playState.img)
                      .width('70%')
                      .borderRadius(400)
                  }
                  .backgroundImage($r('app.media.ic_cd'))
                  .backgroundImageSize(ImageSize.Cover)
                  .justifyContent(FlexAlign.Center)
                  .width('100%')
                  .borderRadius(400)
                  .clip(true)
                  .aspectRatio(1)
                }
                .margin({
                  top: 50
                })
                .width('90%')
                .aspectRatio(1)
                .justifyContent(FlexAlign.Center)
                .padding(24)
                // 唱针
                Image($r('app.media.ic_stylus'))
                  .width(200)
                  .aspectRatio(1)
                  .rotate({
                    angle: -55,
                    centerX: 100,
                    centerY: 30
                  })
                  .animation({
                    duration: 500
                  })
              }
              // 歌曲信息
              // 🟢 歌曲信息（优化版：单层渲染 + 阴影霓虹效果）
              Column({ space: 8 }) {
                Text(this.playState.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  // 利用 textShadow 还原你原来三层叠加想要的那种“发光/霓虹”效果
                  .textShadow({ radius: 8, color: '#ec5c87', offsetX: 0, offsetY: 0 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(this.playState.author)
                  .fontSize(18)
                  .fontColor('#B3B3B3') // 浅灰色增加层次感
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)

              // 操作
              Row() {
                Badge({ value: '99+', style: { badgeSize: 12, badgeColor: '#45CCCCCC' } }) {
                  Image($r("app.media.ic_like"))
                    .fillColor(Color.White)
                    .width(24)
                }

                Badge({ value: '10W', style: { badgeSize: 12, badgeColor: '#45cccccc' } }) {
                  Image($r("app.media.ic_comment_o"))
                    .fillColor(Color.White)
                    .width(18)
                }

                Badge({ value: 'hot', style: { badgeSize: 12, badgeColor: '#a8ff3131' } }) {
                  Image($r("app.media.ic_bells_o"))
                    .fillColor(Color.White)
                    .width(24)
                }

                Badge({ value: 'vip', style: { badgeSize: 12, badgeColor: '#b7efd371' } }) {
                  Image($r("app.media.ic_download_o"))
                    .fillColor(Color.White)
                    .width(24)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceAround)
              // 播放
              Column() {
                // 进度条
                Row({ space: 4 }) {
                  Text(this.vm.number2time(this.playState.time))
                    .fontSize(12)
                    .fontColor(Color.White)
                  Slider({
                    value: this.playState.time,
                    min: 0,
                    max: this.playState.duration
                  })
                    .layoutWeight(1)
                    .blockColor(Color.White)
                    .selectedColor(Color.White)
                    .trackColor('#ccc5c5c5')
                    .trackThickness(2)
                    .onChange((value) => {
                      this.vm.handleSeek(value)
                    })
                  Text(this.vm.number2time(this.playState.duration))
                    .fontSize(12)
                    .fontColor(Color.White)
                }
                .width('100%')
                .padding(24)
                // 切换
                Row() {
                  if (this.playState.playMode === 'auto') {
                    Image($r('app.media.ic_auto'))
                      .fillColor(Color.White)
                      .width(30)
                      .onClick(() => {
                        this.playState.playMode = 'random'
                      })
                  } else if (this.playState.playMode === 'random') {
                    Image($r('app.media.ic_random'))
                      .fillColor(Color.White)
                      .width(30)
                      .onClick(() => {
                        this.playState.playMode = 'repeat'
                      })
                  } else if (this.playState.playMode === 'repeat') {
                    Image($r('app.media.ic_repeat'))
                      .fillColor(Color.White)
                      .width(30)
                      .onClick(() => {
                        this.playState.playMode = 'auto'
                      })
                  }

                  Image($r("app.media.ic_prev"))
                    .fillColor(Color.White)
                    .width(30)
                    .onClick(() => {
                      this.handlePlaybackAction(playerManager.prevPlay(), '上一首')
                    })

                  // 播放按钮
                  Image(this.playState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
                    .fillColor(Color.White)
                    .width(50)
                    .onClick(() => {
                      this.playCurrentSong()
                    })
                  // 下一首
                  Image($r('app.media.ic_next'))
                    .fillColor(Color.White)
                    .width(30)
                    .onClick(() => {
                      this.handlePlaybackAction(playerManager.nextPlay(), '下一首')
                    })
                  // 播放列表
                  Image($r('app.media.ic_song_list'))
                    .fillColor(Color.White)
                    .width(30)
                    .onClick(() => {
                      this.vm.showListPanel()
                    })
                }
                .width('100%')
                .padding({
                  bottom: 24
                })
                .justifyContent(FlexAlign.SpaceAround)
              }
              .width('100%')
            }
            .layoutWeight(1)
            .width('100%')
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)


        // 列表
        Column() {
          Column() {

          }
          .width('100%')
          .layoutWeight(1)
          .onClick(() => {
            this.vm.hideListPanel()
          })

          Column() {
            Row() {
              Row() {
                Image($r("app.media.ic_play"))
                  .width(20)
                  .fillColor('#ff5186')
              }
              .width(50)
              .aspectRatio(1)
              .justifyContent(FlexAlign.Center)

              Row({ space: 8 }) {
                Text(`播放列表 (${ this.playState.playList.length})`)
                  .fontColor(Color.White)
                  .fontSize(14)
              }
              .layoutWeight(1)

              Image($r('app.media.ic_close'))
                .fillColor('#ffa49a9a')
                .width(24)
                .height(24)
                .margin({ right: 16 })
                .onClick(() => {
                  this.vm.hideListPanel()
                })
            }
            .width('100%')
            .backgroundColor('#ff353333')
            .padding(8)
            .border({
              width: { bottom: 1 },
              color: '#12ec5c87'
            })
            .borderRadius({
              topLeft: 4,
              topRight: 4
            })

            // 播放列表
            List() {
              //通过读取数组内容把每首歌的歌名和作者画在播放列表面板上
              ForEach(this.playState.playList, (item: SongItemType, index: number) => {
                ListItem() {
                  Row() {
                    Row() {
                      Text((index + 1).toString())
                        .fontColor('#ffa49a9a')
                    }
                    .width(50)
                    .aspectRatio(1)
                    .justifyContent(FlexAlign.Center)

                    // 列表
                    Row({ space: 10 }) {
                      Column() {
                        Text(item.name)
                          .fontSize(14)
                          .fontColor('#ffa49a9a')
                        Text(item.author)
                          .fontSize(12)
                          .fontColor( Color.Gray)
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)
                      .justifyContent(FlexAlign.Center)
                    }
                    .layoutWeight(1)

                    Image($r('app.media.more'))
                      .width(24)
                      .height(24)
                      .margin({ right: 16 })
                      .fillColor(Color.Gray)
                  }
                  .alignItems(VerticalAlign.Center)
                  .onClick(() => {
                    this.handlePlaybackAction(playerManager.singPlay(item), '播放列表切歌')
                  })
                }
                .swipeAction({
                  //调用方法把下标传回给playerManager.removeSong()
                  end: this.deleteButton(index)
                })
                .border({
                  width: { bottom: 1 },
                  color: '#12ec5c87'
                })
              })
            }
            .layoutWeight(1)
            .backgroundColor('#ff353333')

          }
          .height(400)
        }
        .height(this.vm.panelHeight)
        // .height('100%')
        .animation({
          duration: 300
        })
        .backgroundColor('#ff353333')
        .opacity(this.vm.panelOpacity)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])


      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)

    }
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
    .hideTitleBar(true)  // 隐藏标题栏
  }
}
