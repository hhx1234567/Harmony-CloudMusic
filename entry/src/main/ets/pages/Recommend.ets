interface RecommendDailyType {
  img: string
  title: string
  description: string
}

interface RecommendListType {
  img: string
  title: string
  tag: string
}

@ComponentV2
export struct Recommend {
  @Param onOpenFind: () => void = () => {}

  swiperList: string[] = [
    'https://p1.ssl.qhimg.com/t01898737667e9c6909.jpg',
    'https://ts1.tc.mm.bing.net/th/id/OIP-C.Qahit69EGdw9SaQG56jJlQHaE8?rs=1&pid=ImgDetMain&o=7&rm=3',
    'https://ts1.tc.mm.bing.net/th/id/OIP-C.pArPRE1Px6UVGb4kCPaHPgHaDt?rs=1&pid=ImgDetMain&o=7&rm=3',
    'https://ts2.tc.mm.bing.net/th/id/OIP-C.0e_jHUDEqJwqvAbSRx-y8wHaFj?rs=1&pid=ImgDetMain&o=7&rm=3',
    'https://ts4.tc.mm.bing.net/th/id/OIP-C.8bcnNLJVw4xgA1CQDLwmAQHaHa?rs=1&pid=ImgDetMain&o=7&rm=3'
  ]

  dailyRecommend: RecommendDailyType[] = [
    {
      img: 'https://ts2.tc.mm.bing.net/th/id/OIP-C.mbNQTBWd_IjVoiIB0c1bPAHaE8?rs=1&pid=ImgDetMain&o=7&rm=3',
      title: '今日随机推荐',
      description: '从在线曲库随机发现歌曲，点击即可进入可播放列表。'
    },
    {
      img: 'https://ts2.tc.mm.bing.net/th/id/OIP-C.tre0oMX_gE7tna90ghZBKgHaHV?rs=1&pid=ImgDetMain&o=7&rm=3',
      title: '按歌手发现',
      description: '支持输入歌手或歌曲关键词，快速筛选真实搜索结果。'
    },
    {
      img: 'https://tse3-mm.cn.bing.net/th/id/OIP-C.2BqcsSi93nIxyrYBlo-l7wHaHa?w=180&h=180&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '离线也能听',
      description: '在线服务不可用时自动切换到内置演示曲库。'
    },
    {
      img: 'https://ts3.tc.mm.bing.net/th/id/OIP-C.i2VhnAww9asZPX2AvgKGiwHaFj?rs=1&pid=ImgDetMain&o=7&rm=3',
      title: '后台持续播放',
      description: '离开应用后仍可通过系统媒体卡片控制播放。'
    }
  ]

  recommendList: RecommendListType[] = [
    {
      img: 'https://p1.music.126.net/KuLDlZwVsGOCEHiCw___4Q==/109951170267901684.jpg?param=640y500',
      title: '在线歌曲随心听',
      tag: '在线曲库'
    },
    {
      img: 'https://tse1-mm.cn.bing.net/th/id/OIP-C.Merl50gED57KT5mLdhPTagHaJe?w=136&h=180&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '搜索喜欢的歌曲与歌手',
      tag: '关键词搜索'
    },
    {
      img: 'https://tse1-mm.cn.bing.net/th/id/OIP-C.8IUirwQYo6iWdgf9NTIOmgHaHp?w=170&h=180&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '收藏喜欢的旋律',
      tag: '本地收藏'
    },
    {
      img: 'https://tse1-mm.cn.bing.net/th/id/OIP-C.oiNPUc29Pe0nBNZxtgD4bAAAAA?w=158&h=180&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '顺序、随机与单曲循环',
      tag: '播放模式'
    },
    {
      img: 'https://tse3-mm.cn.bing.net/th/id/OIP-C.2jWX3uomMPix3ZvaKKbiQQHaHa?w=185&h=185&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '网络异常时自动兜底',
      tag: '离线可用'
    }
  ]

  @Builder
  titleBuilder(title: string) {
    Row() {
      Text(title)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      Text('查看歌曲  ›')
        .fontColor('#E85A88')
        .fontSize(13)
        .onClick(() => {
          this.onOpenFind()
        })
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: 10 }) {
      Row({ space: 10 }) {
        Image($r('app.media.search'))
          .width(22)
          .fillColor('#B8B8B8')
        Column({ space: 2 }) {
          Text('搜索歌曲或歌手')
            .width('100%')
            .fontColor(Color.White)
            .fontSize(15)
          Text('进入在线曲库搜索')
            .width('100%')
            .fontColor('#8C8C8C')
            .fontSize(11)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('前往')
          .fontColor('#E85A88')
          .fontSize(14)
      }
      .width('100%')
      .height(52)
      .padding({ left: 14, right: 14 })
      .backgroundColor('#2D2B29')
      .borderRadius(26)
      .onClick(() => {
        this.onOpenFind()
      })

      Swiper() {
        ForEach(this.swiperList, (item: string) => {
          Image(item)
            .width('100%')
            .height('100%')
            .borderRadius(10)
            .objectFit(ImageFit.Cover)
        }, (item: string) => item)
      }
      .autoPlay(true)
      .width('100%')
      .height(180)

      this.titleBuilder('功能推荐')
      List({ space: 10 }) {
        ForEach(this.dailyRecommend, (item: RecommendDailyType) => {
          ListItem() {
            Column() {
              Image(item.img)
                .width('100%')
                .height(120)
                .objectFit(ImageFit.Cover)
              Column({ space: 5 }) {
                Text(item.title)
                  .width('100%')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                Text(item.description)
                  .width('100%')
                  .fontSize(12)
                  .fontColor('#B8B8B8')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .padding(10)
              .backgroundColor('#242326')
            }
            .width(170)
            .borderRadius(10)
            .clip(true)
            .onClick(() => {
              this.onOpenFind()
            })
          }
        }, (item: RecommendDailyType) => item.title)
      }
      .listDirection(Axis.Horizontal)
      .height(218)
      .scrollBar(BarState.Off)

      this.titleBuilder('项目能力')
      List({ space: 10 }) {
        ForEach(this.recommendList, (item: RecommendListType) => {
          ListItem() {
            Column({ space: 6 }) {
              Stack({ alignContent: Alignment.TopStart }) {
                Image(item.img)
                  .width('100%')
                  .height(100)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)
                Text(item.tag)
                  .fontColor(Color.White)
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                  .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                  .margin(6)
                  .backgroundColor('#B8000000')
                  .borderRadius(10)
              }
              Text(item.title)
                .fontColor(Color.White)
                .fontSize(13)
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width(150)
            .onClick(() => {
              this.onOpenFind()
            })
          }
        }, (item: RecommendListType) => item.title)
      }
      .listDirection(Axis.Horizontal)
      .height(150)
      .scrollBar(BarState.Off)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 80 })
    }
    .height('100%')
    .width('100%')
    .scrollBar(BarState.Off)
    .backgroundColor('#131215')
  }
}
