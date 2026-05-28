// 跳转页面入口函数
@Builder
export function StartBuilder() {
  Start();
}

@ComponentV2
struct Start {
  // 控制跳转的对象
  pathStack: NavPathStack = new NavPathStack();
  //过三秒自动跳转到layout，start页面打开计时三秒
  aboutToAppear(): void {   //生命周期
    setTimeout(() => {
      this.pathStack.replacePathByName("Layout", null, false)
    },3000)
  }

  build() {
    //任何想要被跳转的页面最外层必须是NavDestination
    NavDestination() {
      //层叠容器及调整内容对齐方式
      Stack({ alignContent: Alignment.TopEnd}) {
        Image($r('app.media.Utada1'))
          .width('100%')
          .height('100%')
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
        Button('跳过')
          .backgroundColor(Color.Gray)
          .margin(15)
          .onClick(() => {
            //用replacePathByName不让返回广告页面，用pushPathByName可以返回页面
            this.pathStack.replacePathByName("Layout", null, false)
          })
      }
    }
    //.title('广告页')
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
  }
}