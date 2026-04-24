import { AppStorageV2 } from '@kit.ArkUI';

@Entry
@ComponentV2
struct SystemRoutingTable {
  //pathStack : NavPathStack = new NavPathStack();
  pathStack : NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!

  build() {
    //Navigation是所有页面的根容器，只有一个，套上这个外壳App就拥有了切换等功能
    Navigation(this.pathStack)
    {

    }
    //应用点开后直接进入广告页
    .onAppear(() => {
      this.pathStack.pushPathByName('Start', null, false);
    })
    .hideNavBar(true)
  }
}