import { SongItemType } from '../models/music'
import { playerManager } from '../utils/AvPlayerManager'

interface songItemType extends SongItemType {}

interface momentListType {
  author: string
  avatar: string
  content: string
  comment: number
  like: number
  song: songItemType
}

@Component
export struct Moment {
  // 歌曲数据（供 momentList 渲染歌单信息 + 点击播放）
  songs: songItemType[] = [
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.jpg',
      name: '直到世界的尽头',
      author: 'WANDS',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/0.m4a',
      id: '0000'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.jpg',
      name: '画',
      author: '赵磊',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/1.mp3',
      id: '0001'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.jpg',
      name: 'Sweet Dreams',
      author: 'TPaul Sax / Eurythmics',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/2.mp3',
      id: '0002'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.jpg',
      name: '奢香夫人',
      author: '凤凰传奇',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/3.m4a',
      id: '0003'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.jpg',
      name: '空心',
      author: '光泽',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/4.mp3',
      id: '0004'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.jpg',
      name: '反转地球',
      author: '潘玮柏',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/5.mp3',
      id: '0005'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.jpg',
      name: 'No.9',
      author: 'T-ara',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/6.m4a',
      id: '0006'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.jpg',
      name: '孤独',
      author: 'G.E.M.邓紫棋',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/7.m4a',
      id: '0007'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.jpg',
      name: 'Lose Control',
      author: 'Hedley',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/8.m4a',
      id: '0008'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.jpg',
      name: '倩女幽魂',
      author: '张国荣',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/9.m4a',
      id: '0009'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.jpg',
      name: '北京北京',
      author: '汪峰',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/10.m4a',
      id: '0010'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.jpg',
      name: '苦笑',
      author: '汪苏泷',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/11.mp3',
      id: '0011'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.jpg',
      name: '一生所爱',
      author: '卢冠廷 / 莫文蔚',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/12.m4a',
      id: '0012'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.jpg',
      name: '月半小夜曲',
      author: '李克勤',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/13.mp3',
      id: '0013'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.jpg',
      name: 'Rolling in the Deep',
      author: 'Adele',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/14.m4a',
      id: '0014'
    },
    {
      img: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.jpg',
      name: '海阔天空',
      author: 'Beyond',
      url: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/15.m4a',
      id: '0015'
    }
  ]

  momentList: momentListType[] = [
    {
      author: 'Feast-aws',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h0.jpg',
      content: '二十几岁的你，一无所有，也拥有一切！',
      comment: 604,
      like: 23382,
      song: this.songs[0]
    },
    {
      author: 'CeeYet',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h1.jpg',
      content: '画一个姑娘陪着我,再画一个姑娘陪着我',
      comment: 1237,
      like: 5482,
      song: this.songs[1]
    },
    {
      author: 'Z_HOUSC',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h2.jpg',
      content: '这个事还得从两个职业选手说起',
      comment: 8425,
      like: 4234,
      song: this.songs[2]
    },
    {
      author: '逆转大师',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h3.jpg',
      content: '听奢香夫人，做上岸女人！',
      comment: 7658,
      like: 11545,
      song: this.songs[3]
    },
    {
      author: 'Moriaty',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h4.jpg',
      content: '别一厢情愿的付出，他如果拒绝你了就别再纠缠了，别一次次满满热情得到的都是敷衍冷淡的回复，你不该这样的，你应该酷一点，别打扰真的是最好的选择。',
      comment: 543,
      like: 2234,
      song: this.songs[4]
    },
    {
      author: '丶你要去哪里',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h5.jpg',
      content: '当年会一段潘帅的RAP是很拉风的事情',
      comment: 14415,
      like: 36297,
      song: this.songs[5]
    },
    {
      author: '一个人的某泥',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h6.jpg',
      content: '抗韩二十年，死于朴智妍',
      comment: 1237,
      like: 5482,
      song: this.songs[6]
    },
    {
      author: '曾经那个少年1993',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h7.jpg',
      content: '一个人去游泳，像投河；倒过来，一个人去投河，像游泳，太孤独。 ———-陈小三',
      comment: 7628,
      like: 36448,
      song: this.songs[7]
    },
    {
      author: '柳崽崽阿',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h8.jpg',
      content: '哎呦，B站来的跟我一起摇💃',
      comment: 1237,
      like: 5482,
      song: this.songs[8]
    },
    {
      author: '李富贵他哥',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h9.jpg',
      content: '我弟弟老是偷我的裙子丝袜穿，我担心他在女装的道路上越走越远，这让我这个当哥哥的很是担心啊',
      comment: 7362,
      like: 11482,
      song: this.songs[9]
    },
    {
      author: '一檀溪一',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h10.jpg',
      content: '想起张雪峰说过的全世界最大的社区天通苑，住了400w人，光是地铁修了三站，去赶早上第一班天通苑的地铁，那才是真正的北京，真的是哭辽',
      comment: 6496,
      like: 8526,
      song: this.songs[10]
    },
    {
      author: '-_Dimple_',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h11.jpg',
      content: '今天为了赶地铁在电梯上摔了一跤，手磕破了，马上起来进了地铁结果发现一着急坐反了。某一刻觉得自己长大了，摔倒了不是先难受，想哭觉得丢脸，而是想着快点赶上地铁。大概成年人的无奈就是没时间让我难过一会儿吧。',
      comment: 1237,
      like: 5482,
      song: this.songs[11]
    },
    {
      author: 'h奔放小青年',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h12.jpg',
      content: '关于这部电影看到过一个评论：当年大学毕业以后我和女友各奔东西，曾经一个晚上，偶然又看了这部电影，当至尊宝拥吻紫霞的时候荡气回肠的歌声也让我潸然泪下。。。。。第二天我打起行囊踏上火车往她家赶，如今十年过去，我们已经有了一个可爱的女儿。 我想，这是对一部电影最好的肯定吧',
      comment: 1237,
      like: 5482,
      song: this.songs[12]
    },
    {
      author: '您的坑友已上线',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h13.jpg',
      content: '李克勤说他唱了三十多年的歌，当接下面具的时候还很紧张，还很担心自己能不能被大家认出来，然后当《红日》想起来的时候，自己都被感动了。前天看张信哲在央视的开讲啦，坦言面对"过气“一次能够接受，撒贝宁说的很好，这批歌迷也许不会通过刷微博来支持，但是他在这些人的心里比微博上更重要。',
      comment: 1237,
      like: 5482,
      song: this.songs[13]
    },
    {
      author: '一个人的某泥',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h14.jpg',
      content: '11年初三，无意中听到这首歌，推荐给同学，他们都说一般般。当我在家外放这首歌时，我奶奶对我说：“这什么歌，这么好听。',
      comment: 1237,
      like: 5482,
      song: this.songs[14]
    },
    {
      author: '不想早起',
      avatar: 'http://yjy-teach-oss.oss-cn-beijing.aliyuncs.com/HeimaCloudMusic/h15.jpg',
      content: '文不黑周树人 武不黑李小龙 音不黑黄家驹 影不黑周星驰',
      comment: 1237,
      like: 5482,
      song: this.songs[15]
    }
  ]

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('互动广场')
          .fontColor(Color.White)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      List() {
        ForEach(this.momentList, (item: momentListType, index: number) => {
          ListItem() {
            Column({ space: 10 }) {
              // 头像 + 描述（水平布局，头像顶部对齐）
              Row({ space: 12 }) {
                Image(item.avatar)
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .objectFit(ImageFit.Cover)

                Column({ space: 6 }) {
                  Text(item.author)
                    .fontSize(14)
                    .fontColor(Color.White)

                  Text(item.content)
                    .fontSize(12)
                    .fontColor('#8F8F8F')
                    .maxLines(3)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)

              // 歌曲卡片
              Row() {
                Image(item.song.img)
                  .width(64)
                  .height(48)
                  .borderRadius(8)
                  .objectFit(ImageFit.Cover)

                Column({ space: 6 }) {
                  Text(item.song.name)
                    .fontSize(13)
                    .fontColor(Color.White)
                    .maxLines(1)

                  Text(item.song.author)
                    .fontSize(11)
                    .fontColor('#7A7A7A')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Stack({ alignContent: Alignment.Center }) {
                  Image($r('app.media.ic_play'))
                    .width(16)
                    .fillColor(Color.White)
                }
                .width(34)
                .height(34)
                .borderRadius(17)
                .backgroundColor('#2D2B29')
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor('#3B3F42')
              .borderRadius(10)
              .onClick(() => {
                // 点击播放对应歌曲
                playerManager.singPlay(item.song)
              })

              // 评论/点赞
              Row({ space: 24 }) {
                Row({ space: 8 }) {
                  Image($r('app.media.ic_comment_o'))
                    .width(16)
                    .fillColor('#8F8F8F')

                  Text(item.comment.toString())
                    .fontSize(12)
                    .fontColor('#8F8F8F')
                }

                Row({ space: 8 }) {
                  Image($r('app.media.ic_like'))
                    .width(16)
                    .fillColor('#8F8F8F')

                  Text(item.like.toString())
                    .fontSize(12)
                    .fontColor('#8F8F8F')
                }
              }
              .width('100%')
              .padding({ left: 6, right: 6 })
            }
            .width('100%')
            .height('30%')
          }
          .border({ width: { bottom: 1 }, color: '#2D2B29' })
        })
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#131215')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}