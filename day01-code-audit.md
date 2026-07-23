# Day 1 核心代码审计

## 一、项目当前架构

### Models
- SongItemType
- GlobalMusic
- FindPageCache
- 默认歌曲和动态数据

### Views
- Index
- Start
- Layout
- Recommend
- Find
- Moment
- Mine
- Play

### ViewModels
- FindViewModel
- PlayViewModel

### Services / Managers
- MusicService
- HttpClient
- AIAssistant
- AvPlayerManager
- AvSessionManager

## 二、已经具备的能力

- MVVM基础分层
- @ObservedV2 / @Trace响应式状态
- AppStorageV2全局播放状态
- 网络请求封装
- AVPlayer播放
- AVSession系统播控
- 后台音频长时任务
- 播放列表
- AI推荐入口
- 播放URL异步获取

## 三、P0问题

### P0-1：客户端硬编码AI密钥

表现：
真实API密钥直接存在ApiConfig，并随客户端请求发送。

风险：
密钥可以被源码、Git历史或安装包泄露。

处理：
- 撤销旧密钥
- 从客户端删除密钥
- 暂时关闭AI请求
- 后续通过服务端代理调用

状态：
已处理 / 未处理

### P0-2：播放意图守卫没有真正丢弃旧请求

表现：
检测到pendingSongId不匹配后只打印日志，没有return。

影响：
旧歌曲URL后返回时仍可能覆盖新歌曲。

处理：
使用单调递增的playIntentSequence；
过期请求立即return。

状态：
已处理 / 未处理

## 四、P1问题

### P1-1：Tabs内容使用currentIndex而非循环index

可能导致：
- 页面重复构建
- 网络重复请求
- ViewModel重复实例化
- Tab状态丢失

### P1-2：AvPlayerManager内部仍可能存在切歌竞态

原因：
- singPlay没有等待changeSong
- 多次reset可能交叠
- next/prev/列表点击均可触发切歌
- 目前只有网络URL层的意图守卫

后续计划：
在播放器管理器内部增加播放操作序列或串行操作队列。

### P1-3：播放器与AVSession初始化未等待

EntryAbility中：
- playerManager.init()
- sessionManager.init()

均未等待完成。

风险：
用户过快进入播放操作时，player或session可能尚未准备好。

### P1-4：空播放列表缺少统一保护

风险位置：
- prevPlay()
- nextPlay()
- 播放按钮
- durationUpdate设置元数据

应在使用playList[playIndex]前确认存在有效歌曲。

### P1-5：后台任务状态可能与真实状态不一致

startBackgroundTask调用失败时，
isTaskRunning仍然可能被设置为true，
后续请求会被错误拦截。

## 五、P2问题

- console日志与hilog混用
- 日志Tag仍使用testTag
- 多处未使用import
- HTTP错误统一返回null，丢失具体错误类型
- 多个资源地址仍使用HTTP
- Start页面定时器在点击跳过后没有取消
- currtentIndex拼写错误
- 部分命名和格式不统一

## 六、关于FSM的当前结论

当前项目使用AVPlayer stateChange进行状态驱动处理，
但尚未定义完整的业务状态枚举、转移表和非法转移保护。

当前更准确的描述：
“基于AVPlayer状态回调管理播放状态，并使用意图序列守卫处理异步结果乱序。”

## 七、今天修改的文件

- config/ApiConfig.ets
- utils/AIAssistant.ets
- viewmodels/FindViewModel.ets
- pages/Layout.ets
- docs/day01-code-audit.md