import { media } from '@kit.MediaKit'
import { GlobalMusic } from '../models/globalMusic'
import { SongItemType } from '../models/music'
import { AppStorageV2 } from '@kit.ArkUI'
import { sessionManager } from './AvSessionManager'

class AvPlayerManager {
  //属性+方法
  //播放器
  player: media.AVPlayer | null = null
  //共享播放数据  AppStorageV2类似公共储物柜，'SONG_KEY'是柜子的标签，connect是柜子钥匙，GlobalMusic是物品类型
  currentSong: GlobalMusic = AppStorageV2.connect(GlobalMusic, 'SONG_KEY', () => new GlobalMusic())!

  //定义方法 创建播放器 + 监听播放器状态  在onWindowStageCreate里直接调用方法
  async init () {
    if (!this.player) {
      this.player = await media.createAVPlayer()
    }
    //监听状态变化
    this.player.on('stateChange', (state) => {
      if (state === 'initialized') {
        this.player?.prepare()
      }
      else if (state === 'prepared') {
        this.player?.play()
        //this.currentSong.isPlay = true
      }
      else if (state === 'playing') {
        // 【核心修改 1】：确立唯一真相！只有底层真的出声了，才去改状态和通知锁屏！
        this.currentSong.isPlay = true
        sessionManager.setAVPlayBackState()
      }
      else if (state === 'paused') {
        // 【核心修改 2】：只有底层真的暂停了，才去改状态和通知锁屏！
        this.currentSong.isPlay = false
        sessionManager.setAVPlayBackState()
      }
      else if (state === 'completed') {
        this.nextPlay(true) //自动下一首
      }
      else if (state === 'released') {
        this.currentSong.reset()
      }
    })
    //监听时间变化
    //总时长
    this.player.on('durationUpdate', (duration) => {
      this.currentSong.duration = duration
      sessionManager.setAVMetadata(this.currentSong.playList[this.currentSong.playIndex])
    })
    //当前播放时间
    this.player.on('timeUpdate', (time) => {
      this.currentSong.time = time
      //sessionManager.setAVPlayBackState()
    })
  }
  //设置播放器
  //singPlay (song: SongItemType) {
  //  this.player!.url = song.url
  //  this.currentSong.img = song.img
  //}
  singPlay (song: SongItemType){
    //申请长时任务
    sessionManager.startBackgroundTask()
    //sessionManager.setAVPlayBackState()       此时还没准备好播放，不能提前骗锁屏

    //是否在列表 -> some 检查数组里面的song数据与传过来的item数据是否满足条件 -> 只要有一个满足 some 返回 true
    const inList = this.currentSong.playList.some(item => item.id === song.id)
    if (inList)
    {
      //在列表里 -> 是否是正在播放的歌曲 -> currentSong.url === song.url
      if (this.currentSong.url === song.url)
      {
        this.player?.play()
        //状态交给上面的 'playing' 去改    this.currentSong.isPlay = true
      }
      else
      {
        //设置新的索引 -> 找到列表里对应的索引来切歌
        this.currentSong.playIndex = this.currentSong.playList.findIndex(item => item.id === song.id)
        //切歌
        this.changeSong()
      }
    }
    else
    {
      //不在列表里 -> 添加到列表 + 切换歌曲     把传过来的song放进playList数组中
      this.currentSong.playList.unshift(song)
      this.currentSong.playIndex = 0
      //切换歌曲
      this.changeSong()
    }
  }

  //切换歌曲 -> 重新播放器
  async changeSong() {
    await this.player?.reset()
    this.currentSong.duration = 0
    this.currentSong.time = 0
    this.currentSong.img = this.currentSong.playList[this.currentSong.playIndex].img
    this.currentSong.name = this.currentSong.playList[this.currentSong.playIndex].name
    this.currentSong.author = this.currentSong.playList[this.currentSong.playIndex].author
    this.currentSong.url = this.currentSong.playList[this.currentSong.playIndex].url
    this.player!.url = this.currentSong.url
  }

  //跳转进度 seek
  seekPlay(value: number) {
    this.player?.seek(value)
  }

  //暂停
  paused() {
    this.player?.pause()
    //this.currentSong.isPlay = false
    //sessionManager.setAVPlayBackState()
  }
  //上一首
  prevPlay() {
    if (this.currentSong.playMode === 'random')
    {
      this.currentSong.playIndex = Math.floor(Math.random() * this.currentSong.playList.length)
    }
    else
    {
      this.currentSong.playIndex--
      if (this.currentSong.playIndex < 0) {
        this.currentSong.playIndex = this.currentSong.playList.length - 1
      }
    }
    this.singPlay(this.currentSong.playList[this.currentSong.playIndex])
  }
  //下一首:根据播放模式计算索引
  //真的重复播放 -> 播放模式为repeat 并且播放器自动下一首 -> completed 传入一个数据表示是自动的
  nextPlay(autoNextPlay?: boolean) {
    //一首歌播完，播放机状态变为completed后调用nextPlay()并传入参数true，来实现重复播放，用户点击下一首不用传参，如果不传参数的，当Mode为repeat时，点击下一首也会重复播放
    if (this.currentSong.playMode === 'repeat' && autoNextPlay)
    {
      this.currentSong.playIndex = this.currentSong.playIndex
    }
    else if (this.currentSong.playMode === 'random')
    {
      this.currentSong.playIndex = Math.floor(Math.random() * this.currentSong.playList.length)
    }
    else
    {
      this.currentSong.playIndex++
      if (this.currentSong.playIndex >= this.currentSong.playList.length)
      {
        this.currentSong.playIndex = 0
      }
    }
    this.singPlay(this.currentSong.playList[this.currentSong.playIndex])
  }

  //列表移除歌曲
  removeSong (index: number) {
    //删除正在播放的
    if (index === this.currentSong.playIndex) {
      //列表里有多首歌
      if (this.currentSong.playList.length > 1) {
        this.currentSong.playList.splice(index, 1)
        //播放索引如果大于等于了长度，回第一首播放
        if (this.currentSong.playIndex >= this.currentSong.playList.length) {
          this.currentSong.playIndex = 0
        }
        this.singPlay(this.currentSong.playList[this.currentSong.playIndex])
      }
      else {
        //列表只有一首歌
        this.player?.reset()
        this.currentSong.reset()
      }
    }
    else {
      //删除的不是正在播放的
      if (index < this.currentSong.playIndex) {
        //要删除的在播放的前面
        this.currentSong.playIndex--
      }
      // 移除 -> 删除的索引， 删除个数
      this.currentSong.playList.splice(index, 1)
    }
  }

  //释放播放器和播放数据
  async  release () {
    await this.player?.release()
  }

  resumePlay() {
    if (this.player && this.currentSong.isPlay === false) {
      this.player?.play()
      //this.currentSong.isPlay = true
      //sessionManager.setAVPlayBackState()
    }
  }
  
}


//放在onWindowStageCreate里去准备播放器
export const playerManager: AvPlayerManager = new AvPlayerManager()









