import { SongItemType } from './music'

@ObservedV2
export class FavoriteMusic {
  @Trace songs: SongItemType[] = []
}
