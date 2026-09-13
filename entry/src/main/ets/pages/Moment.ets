import { SongItemType } from '../models/music'
import { playerManager } from '../utils/AvPlayerManager'
import { DEFAULT_SONGS, DEFAULT_momentList, momentListType} from '../models/defaultSongs'

//interface songItemType extends SongItemType {}

@ComponentV2
export struct Moment {
  // 歌曲数据（供 momentList 渲染歌单信息 + 点击播放）
  //songs: SongItemType[] = DEFAULT_SONGS

  @Local momentList: momentListType[] = DEFAULT_momentList

  private playMomentSong(song: SongItemType): void {
    // 动态页不经过 FindViewModel，所以直接进入播放器自己的操作序列，并处理 boolean 结果。
    playerManager.singPlay(song).then((applied: boolean) => {
      if (!applied) {
        console.info('[Moment] 播放请求未应用')
      }
    }).catch((err: Error) => {
      console.error('[Moment] 播放请求异常：' + JSON.stringify(err))
    })
  }

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
                this.playMomentSong(item.song)
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
