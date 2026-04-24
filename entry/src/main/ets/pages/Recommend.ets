interface recommendDailyType {
  img: string  //图片
  title: string  //标题文字
  type: string  //简介文字
  top: string  //标题背景色
  bottom: string  //简介背景色
}

interface recommendListType {
  img: string
  title: string
  count: string
}
@Component
export  struct Recommend {

  //轮播图数据
  swiperList: string[] = [
    'https://p1.ssl.qhimg.com/t01898737667e9c6909.jpg',
    'https://ts1.tc.mm.bing.net/th/id/OIP-C.Qahit69EGdw9SaQG56jJlQHaE8?rs=1&pid=ImgDetMain&o=7&rm=3',
    'https://ts1.tc.mm.bing.net/th/id/OIP-C.pArPRE1Px6UVGb4kCPaHPgHaDt?rs=1&pid=ImgDetMain&o=7&rm=3',
    'https://ts2.tc.mm.bing.net/th/id/OIP-C.0e_jHUDEqJwqvAbSRx-y8wHaFj?rs=1&pid=ImgDetMain&o=7&rm=3',
    'https://ts4.tc.mm.bing.net/th/id/OIP-C.8bcnNLJVw4xgA1CQDLwmAQHaHa?rs=1&pid=ImgDetMain&o=7&rm=3'
  ]

  //每日推荐数据
  dailyRecommend: recommendDailyType[] = [
    {
      img: 'https://ts2.tc.mm.bing.net/th/id/OIP-C.mbNQTBWd_IjVoiIB0c1bPAHaE8?rs=1&pid=ImgDetMain&o=7&rm=3',
      title: '每日推荐1',
      type: '今日份歌单已送达，愿旋律治愈所有疲惫，把温柔与美好都留给你。',
      top: '#660000',
      bottom: '#382e2f'
    },
    {
      img: 'https://ts2.tc.mm.bing.net/th/id/OIP-C.tre0oMX_gE7tna90ghZBKgHaHV?rs=1&pid=ImgDetMain&o=7&rm=3',
      title: '每日推荐2',
      type: '耳机是人间避难所，音乐是情绪解药，今天也好好听歌，好好生活。',
      top: '#660000',
      bottom: '#382e2f'
    },
    {
      img: 'https://tse3-mm.cn.bing.net/th/id/OIP-C.2BqcsSi93nIxyrYBlo-l7wHaHa?w=180&h=180&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '每日推荐3',
      type: '把心事交给旋律，让晚风带走烦恼，愿你在歌声里，遇见温柔的自己。',
      top: '#660000',
      bottom: '#382e2f'
    },
    {
      img: 'https://ts3.tc.mm.bing.net/th/id/OIP-C.i2VhnAww9asZPX2AvgKGiwHaFj?rs=1&pid=ImgDetMain&o=7&rm=3',
      title: '每日推荐4',
      type: '生活偶尔匆忙，别忘留一点时间给自己。听一首喜欢的歌，慢慢治愈。',
      top: '#660000',
      bottom: '#382e2f'
    },
    {
      img: 'https://tse3-mm.cn.bing.net/th/id/OIP-C.NIs7uQMwGLaoq355hXCIXgHaFj?w=249&h=187&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '每日推荐5',
      type: '音乐不停，热爱不止。愿你今日被旋律包围，眼里有光，心中有暖。',
      top: '#660000',
      bottom: '#382e2f'
    },
  ]

  //推荐歌单数据
  recommendList: recommendListType[] = [
    {
      img: 'https://p1.music.126.net/KuLDlZwVsGOCEHiCw___4Q==/109951170267901684.jpg?param=640y500',
      title: '音乐不停，热爱不止。愿你今日被旋律包围，眼里有光，心中有暖。',
      count: '1000.0万'
    },
    {
      img: 'https://tse1-mm.cn.bing.net/th/id/OIP-C.Merl50gED57KT5mLdhPTagHaJe?w=136&h=180&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '生活偶尔匆忙，别忘留一点时间给自己。听一首喜欢的歌，慢慢治愈。',
      count: '1000.0万'
    },
    {
      img: 'https://tse1-mm.cn.bing.net/th/id/OIP-C.8IUirwQYo6iWdgf9NTIOmgHaHp?w=170&h=180&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '把心事交给旋律，让晚风带走烦恼，愿你在歌声里，遇见温柔的自己。',
      count: '1000.0万'
    },
    {
      img: 'https://tse1-mm.cn.bing.net/th/id/OIP-C.oiNPUc29Pe0nBNZxtgD4bAAAAA?w=158&h=180&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '耳机是人间避难所，音乐是情绪解药，今天也好好听歌，好好生活。',
      count: '1000.0万'
    },
    {
      img: 'https://tse3-mm.cn.bing.net/th/id/OIP-C.2jWX3uomMPix3ZvaKKbiQQHaHa?w=185&h=185&c=7&r=0&o=7&pid=1.7&rm=3',
      title: '今日份歌单已送达，愿旋律治愈所有疲惫，把温柔与美好都留给你。',
      count: '1000.0万'
    }
  ]

  @Builder
  titleBuilder (title: string) {
    Row(){
      Text(title)
        .fontColor('#fff')
        .fontWeight(700)
        .layoutWeight(1)
      Image($r('app.media.more'))
        .width(22)
        .fillColor('#fff')
    }
  }

  build() {
    Column({space: 10}){
      //搜索区域
      Row(){
        Image($r('app.media.search'))
          .width(22)
          .fillColor(Color.Gray)
        TextInput({placeholder: '请输入文本'})
          .placeholderColor(Color.Gray)
          .fontColor(Color.White)
          .padding({left: 5})
          .layoutWeight(1)
        Image($r('app.media.scan'))
          .width(22)
          .fillColor(Color.Gray)
      }
        .width('100%')
        .backgroundColor('#2D2B29')
        .border({radius: 20})
        .padding({left: 5,right: 5})
      //轮播图区域
      Swiper() {
        ForEach(this.swiperList, (item: string) => {
          Image(item)
            .width('100%')
            .height('100%')
            .border({radius: 10})
            //等比例填满容器，超出裁剪，保证不变形+尺寸统一
            .objectFit(ImageFit.Cover)
        })
      }
        .autoPlay(true)
        .width('100%')
        //固定轮播图高度，用vp适配不同屏幕
        .height('180.vp')
      this.titleBuilder('每日推荐')
      List() {
        ForEach(this.dailyRecommend, (item: recommendDailyType) => {
          ListItem() {
            Column() {
              Text(item.title)
                .width('100%')
                .height(40)
                .backgroundColor(item.top)
                .padding({left: 5})
                .fontSize(14)
                .fontColor('#fff')
              Image(item.img)
                .width('100%')
                .height('120.vp')
                .objectFit(ImageFit.Cover)
              Text(item.type)
                .width('100%')
                .height('50.vp')
                .backgroundColor(item.bottom)
                .padding({left: 5})
                .fontSize(14)
                .fontColor('#fff')
                //最大显示行数
                .maxLines(2)
                //文字溢出显示方式,此处显示为省略号
                .textOverflow({overflow: TextOverflow.Ellipsis})
            }
              .width('40%')
              .border({radius: 10})
              .margin({right: 10})
              .clip(true) //裁剪
          }
        })
      }
        //调整list布局方向
        .listDirection(Axis.Horizontal)
        .height(230)
        //隐藏滑动条
        .scrollBar(BarState.Off)
      this.titleBuilder('推荐歌单')
      List() {
        ForEach(this.recommendList, (item: recommendListType) => {
          ListItem() {
            Column() {
              Stack({alignContent: Alignment.TopStart}) {
                Image(item.img)
                  .width('100%')
                  .height(100)
                  .border({radius: 8})
                Text(item.count)
                  .fontColor('#fff')
                  .fontSize(12)
                  .fontWeight(700)
                  .margin(5)
              }
              Text(item.title)
                .fontColor('#fff')
                .fontSize(14)
                .width('100%')
                .padding(5)
                .maxLines(2)
                .textOverflow({overflow: TextOverflow.Ellipsis})
            }
              .width('30%')
              .border({radius: 10})
              .margin({right: 10})
          }
        })
      }
        .listDirection(Axis.Horizontal)
    }
      .width('100%')
      .height('100%')
      .padding({left: 10,right: 10,top: 5,bottom: 5})
  }
}