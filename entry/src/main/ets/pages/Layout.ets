import { Find } from "./Find";
import { Mine } from "./Mine";
import { Moment } from "./Moment";
import { Recommend } from "./Recommend";

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
  @Local currtentIndex: number = 0
  // 控制跳转的对象
  pathStack: NavPathStack = new NavPathStack();

  tabData: tabClass[] = [
    {text: '推荐', icon: $r('app.media.icon_recommend')},
    {text: '发现', icon: $r('app.media.icon_find')},
    {text: '动态', icon: $r('app.media.icon_moment')},
    {text: '我的', icon: $r('app.media.icon_mine')},
  ]

  @Builder tabBuilder (item: tabClass, index: number) {
    Column() {
      Image(item.icon)
        .width(24)
        .fillColor(this.currtentIndex === index ? '#E85A88' : '#63AAAA')
      Text(item.text)
        .fontColor('#63AAAA')
        .fontColor(this.currtentIndex === index ? '#E85A88' : '#63AAAA')
    }
  }
  build() {
    NavDestination() {
      Tabs({ barPosition : BarPosition.End}) {
        ForEach(this.tabData, (item: tabClass,index: number) => {
          TabContent() {
            if (this.currtentIndex === 0) {
              Recommend()
            }
            else if (this.currtentIndex === 1) {
              Find()
            }
            else if (this.currtentIndex === 2) {
              Moment()
            }
            else if (this.currtentIndex === 3) {
              Mine()
            }
          }
            .tabBar(this.tabBuilder(item, index)) //自定义导航栏 ->  @Builder
            .backgroundColor('#131215')
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
        })
      }
        .backgroundColor('#3B3F42')
        .onChange((index: number) =>{
          this.currtentIndex = index
        })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    }
    //.title('布局页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}