import { AppStorageV2 } from '@kit.ArkUI'
import { FavoriteMusic } from '../models/favoriteMusic'
import { GlobalMusic } from '../models/globalMusic'
import { SongItemType } from '../models/music'
import { musicSettingsRepository } from '../repository/MusicSettingsRepository'
import { FavoriteSongsPolicy, FavoriteToggleResult } from '../utils/FavoriteSongsPolicy'
import { playerManager } from '../utils/AvPlayerManager'

@ComponentV2
export struct Mine {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'navStack', () => new NavPathStack())!
  @Local
  favoriteState: FavoriteMusic = AppStorageV2.connect(
    FavoriteMusic,
    'FAVORITE_SONGS_KEY',
    () => new FavoriteMusic()
  )!
  @Local
  playState: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!
  @Local errorMessage: string = ''

  private copyForPlayback(song: SongItemType): SongItemType {
    // 离线演示歌曲保留静态URL；在线URL可能过期，重新进入播放器时按ID获取新地址。
    const isOfflineDemo = song.id.length === 4 && song.id.startsWith('00')
    return {
      id: song.id,
      name: song.name,
      author: song.author,
      img: song.img,
      url: isOfflineDemo ? song.url : ''
    }
  }

  private openPlayPageOnce(): void {
    if (!this.pathStack.getAllPathName().includes('Play')) {
      this.pathStack.pushPathByName('Play', null, false)
    }
  }

  private playFavorite(songId: string): void {
    this.errorMessage = ''
    const playList = this.favoriteState.songs.map((song: SongItemType) => this.copyForPlayback(song))
    const targetSong = playList.find((song: SongItemType) => song.id === songId)
    if (!targetSong) {
      this.errorMessage = '收藏歌曲不存在，请刷新后重试'
      return
    }

    playerManager.singPlay(targetSong, playList).then((applied: boolean) => {
      if (applied) {
        this.openPlayPageOnce()
      } else {
        this.errorMessage = '这首收藏歌曲暂时无法播放'
      }
    }).catch((error: Error) => {
      console.error('[Mine] 播放收藏歌曲失败：' + JSON.stringify(error))
      this.errorMessage = '播放失败，请稍后重试'
    })
  }

  private removeFavorite(song: SongItemType): void {
    const previousSongs = this.favoriteState.songs
    const result: FavoriteToggleResult = FavoriteSongsPolicy.toggle(previousSongs, song)
    this.favoriteState.songs = result.songs
    this.errorMessage = ''

    musicSettingsRepository.saveFavoriteSongs(result.songs).catch((error: Error) => {
      this.favoriteState.songs = previousSongs
      this.errorMessage = '取消收藏失败，请稍后重试'
      console.error('[Mine] 取消收藏保存失败：' + JSON.stringify(error))
    })
  }

  @Builder
  deleteButton(song: SongItemType) {
    Button('取消收藏')
      .backgroundColor('#C62F2F')
      .fontColor(Color.White)
      .height('100%')
      .type(ButtonType.Normal)
      .onClick(() => {
        this.removeFavorite(song)
      })
  }

  build() {
    Column() {
      Row() {
        Column({ space: 6 }) {
          Text('我的收藏')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(`${this.favoriteState.songs.length} 首歌曲`)
            .fontSize(14)
            .fontColor('#8F8F8F')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 28, bottom: 18 })

      if (this.errorMessage) {
        Text(this.errorMessage)
          .width('100%')
          .padding(10)
          .fontSize(14)
          .fontColor('#FFB4AB')
          .backgroundColor('#3A2020')
          .borderRadius(8)
          .margin({ bottom: 12 })
      }

      if (this.favoriteState.songs.length === 0) {
        Column({ space: 16 }) {
          Image($r('app.media.ic_music'))
            .width(88)
            .height(88)
            .opacity(0.55)
          Text('还没有收藏歌曲')
            .fontSize(20)
            .fontColor(Color.White)
          Text('在播放页点击“收藏”，歌曲会出现在这里')
            .fontSize(14)
            .fontColor('#8F8F8F')
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.favoriteState.songs, (item: SongItemType) => {
            ListItem() {
              Row({ space: 14 }) {
                Stack() {
                  Image(item.img)
                    .width(72)
                    .height(72)
                    .borderRadius(10)
                    .objectFit(ImageFit.Cover)
                  if (this.playState.id === item.id && this.playState.isPlay) {
                    Image($r('app.media.wave'))
                      .width(24)
                  }
                }

                Column({ space: 8 }) {
                  Text(item.name)
                    .width('100%')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Color.White)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.author)
                    .width('100%')
                    .fontSize(14)
                    .fontColor('#8F8F8F')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Image($r('app.media.ic_play'))
                  .width(28)
                  .fillColor('#ec5c87')
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#242326')
              .borderRadius(12)
              .onClick(() => {
                this.playFavorite(item.id)
              })
            }
            .swipeAction({ end: this.deleteButton(item) })
          }, (item: SongItemType) => item.id)
        }
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 18, right: 18 })
    .backgroundColor('#131215')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
