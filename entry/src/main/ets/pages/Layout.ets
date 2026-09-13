import { Find } from "./Find";
import { Mine } from "./Mine";
import { Moment } from "./Moment";
import { Recommend } from "./Recommend";
import { AppStorageV2 } from '@kit.ArkUI';
import { GlobalMusic } from '../models/globalMusic';
import { SongItemType } from '../models/music';
import { playerManager } from '../utils/AvPlayerManager';
import { HomeNavigationState } from '../models/homeNavigationState';

interface tabClass {
  text : string
  icon : ResourceStr
}
// 跳转页面入口函数
@Builder
export function LayoutBuilder() {
  Layout();
}

@ComponentV2
struct Layout {
  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  @Local
  navigationState: HomeNavigationState = AppStorageV2.connect(
    HomeNavigationState,
    'HOME_NAVIGATION_KEY',
    () => new HomeNavigationState()
  )!
  // 控制跳转的对象
  pathStack: NavPathStack = new NavPathStack();
  tabData: tabClass[] = [
    { text: '推荐', icon: $r('app.media.icon_recommend') },
    { text: '发现', icon: $r('app.media.icon_find') },
    { text: '动态', icon: $r('app.media.icon_moment') },
    { text: '我的', icon: $r('app.media.icon_mine') },
  ]

  @Builder
  tabBuilder(item: tabClass, index: number) {
    Column() {
      Image(item.icon)
        .width(24)
        .fillColor(this.navigationState.currentTabIndex === index ? '#E85A88' : '#63AAAA')
      Text(item.text)
        .fontColor('#63AAAA')
        .fontColor(this.navigationState.currentTabIndex === index ? '#E85A88' : '#63AAAA')
    }
  }

  private openFind(): void {
    this.navigationState.currentTabIndex = 1
  }

  private openPlayPageOnce(): void {
    if (!this.pathStack.getAllPathName().includes('Play')) {
      this.pathStack.pushPathByName('Play', null, false)
    }
  }

  private toggleMiniPlayback(): void {
    if (this.playState.isPlay) {
      playerManager.paused()
      return
    }

    const index = this.playState.playIndex
    if (this.playState.playList.length === 0 || index < 0 || index >= this.playState.playList.length) {
      console.info('[Layout] 迷你播放器当前歌曲无效，忽略播放操作')
      return
    }

    const song: SongItemType = this.playState.playList[index]
    playerManager.singPlay(song).then((applied: boolean) => {
      if (!applied) {
        console.info('[Layout] 迷你播放器恢复播放未生效')
      }
    }).catch((error: Error) => {
      console.error('[Layout] 迷你播放器恢复播放失败：' + JSON.stringify(error))
    })
  }

  private playNextFromMiniPlayer(): void {
    playerManager.nextPlay().then((applied: boolean) => {
      if (!applied) {
        console.info('[Layout] 迷你播放器下一首未生效')
      }
    }).catch((error: Error) => {
      console.error('[Layout] 迷你播放器下一首失败：' + JSON.stringify(error))
    })
  }

  @Builder
  miniPlayerBuilder() {
    Row({ space: 12 }) {
      Image(this.playState.img)
        .width(48)
        .height(48)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .onClick(() => {
          this.openPlayPageOnce()
        })

      Column({ space: 4 }) {
        Text(this.playState.name)
          .width('100%')
          .fontColor(Color.White)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.playState.author)
          .width('100%')
          .fontColor('#A5A5A5')
          .fontSize(12)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .onClick(() => {
        this.openPlayPageOnce()
      })

      Image(this.playState.isPlay ? $r('app.media.ic_paused') : $r('app.media.ic_play'))
        .width(34)
        .fillColor(Color.White)
        .onClick(() => {
          this.toggleMiniPlayback()
        })

      Image($r('app.media.ic_next'))
        .width(26)
        .fillColor(Color.White)
        .onClick(() => {
          this.playNextFromMiniPlayer()
        })
    }
    .width('94%')
    .height(64)
    .padding({ left: 8, right: 14 })
    .margin({ bottom: 64 })
    .backgroundColor('#F2242326')
    .borderRadius(14)
    .shadow({ radius: 16, color: '#66000000', offsetY: 4 })
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Bottom }) {
        Tabs({ barPosition: BarPosition.End, index: this.navigationState.currentTabIndex }) {
        ForEach(
          this.tabData,
          (item: tabClass, index: number) => {
            TabContent() {
              // index 表示“这个 Tab 固定是谁”，因此每个容器始终构建自己的页面。
              // currentIndex 只表示用户当前选中了谁，不能用它决定所有 Tab 的内容。
              if (index === 0) {
                Recommend({ onOpenFind: () => this.openFind() })
              } else if (index === 1) {
                Find()
              } else if (index === 2) {
                Moment()
              } else if (index === 3) {
                Mine()
              }
            }
            .tabBar(this.tabBuilder(item, index))
            .backgroundColor('#131215')
            .expandSafeArea(
              [SafeAreaType.SYSTEM],
              [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]
            )
          },
          // 稳定 key 帮助 ArkUI 识别同一个 Tab，切换和刷新时不会把页面实例认错。
          (item: tabClass) => item.text
        )
        }
        .backgroundColor('#3B3F42')
        .onChange((index: number) => {
          // 这里只更新选中位置，用于 tabBuilder 中的图标和文字高亮。
          this.navigationState.currentTabIndex = index
        })
        .expandSafeArea(
          [SafeAreaType.SYSTEM],
          [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]
        )

        if (this.playState.id) {
          this.miniPlayerBuilder()
        }
      }
      .width('100%')
      .height('100%')
    }
    //.title('布局页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}
