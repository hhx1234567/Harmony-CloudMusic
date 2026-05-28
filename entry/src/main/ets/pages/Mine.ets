interface userBaseType {
  name: string
  desc: string
}

interface mineStatType {
  label: string
  count: string
}
const user: userBaseType = {
  name: 'Feast-aw',
  desc: '二十二岁的你，一无所有，也拥有一切！',
}

const stats: mineStatType[] = [
  { label: '关注', count: '604' },
  { label: '粉丝', count: '23382' },
  { label: '点赞', count: '5482' },
]
@ComponentV2
export  struct Mine {
  build() {
    Column() {
      // 顶部图片区：70%
      Stack({ alignContent: Alignment.Bottom }) {
        // 下层：大图背景
        Image($r('app.media.img'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)

        // 上层：Logo
        Image($r('app.media.ic_music'))
          .width(80)
          .height(80)
          //.objectFit(ImageFit.Cover)
          //.margin({bottom: 20})
          .border({radius: 20})
      }
      .width('100%')
      .height('70%')

      // 底部介绍区：30%
      Column({ space: 10 }) {
        // 第一行：软件名字
        Text('Music')
          .fontColor(Color.White)
          .fontSize(22)
          .fontWeight(700)

        // 第二行：用户基本信息
        Text(user.name + '  ·  ' + user.desc)
          .fontColor('#7A7A7A')
          .fontSize(14)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 第三行：关注/粉丝/点赞（数字与文字水平排列）
        Row({ space: 18 }) {
          ForEach(stats, (item: mineStatType, index: number) => {
            Row({ space: 6 }) {
              Text(item.label)
                .fontColor('#8F8F8F')
                .fontSize(13)

              Text(item.count)
                .fontColor(Color.White)
                .fontSize(13)
                .fontWeight(700)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          })
        }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
        Row() {
          TextInput({placeholder: '为您推荐符合今天情绪的歌曲'})
            .placeholderColor(Color.Gray)
            .fontColor(Color.White)
            .padding({left: 5})
            .layoutWeight(1)
          Button('推荐')
            .fontColor(Color.White)
            .onClick(() => {

            })
        }
          .border({radius: 20})
          .backgroundColor('#2D2B29')
      }
      .width('100%')
      .height('30%')
      .padding({ left: 18, right: 18, top: 16 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131215')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}