# Day 1 核心代码审计

> 本文件复制自仓库根目录的 `day01-code-audit.md`；根目录原文件保留，避免覆盖用户原始文档。本轮在末尾追加“第二轮问题分析”。

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
当前源码已处理；Git 历史仍需后续专项清理。

### P0-2：播放意图守卫没有真正丢弃旧请求

表现：
检测到pendingSongId不匹配后只打印日志，没有return。

影响：
旧歌曲URL后返回时仍可能覆盖新歌曲。

处理：
使用单调递增的playIntentSequence；
过期请求立即return。

状态：
已处理。

## 四、P1问题

### P1-1：Tabs内容使用currentIndex而非循环index

可能导致：
- 页面重复构建
- 网络重复请求
- ViewModel重复实例化
- Tab状态丢失

当前状态：已改为由循环 `index` 决定固定页面身份，并提供稳定 key；`currentIndex` 仅表示选中位置。

### P1-2：AvPlayerManager内部仍可能存在切歌竞态

原因：
- singPlay没有等待changeSong
- 多次reset可能交叠
- next/prev/列表点击均可触发切歌
- 目前只有网络URL层的意图守卫

当前状态：已增加独立 `playOperationSequence`，异步调用链返回并处理 `Promise<boolean>`。

### P1-3：播放器与AVSession初始化未等待

EntryAbility中原先：
- playerManager.init()
- sessionManager.init()

均未处理完成状态。

当前状态：已通过小范围异步初始化辅助方法依次等待并记录失败；播放入口仍保留未初始化保护。

### P1-4：空播放列表缺少统一保护

风险位置：
- prevPlay()
- nextPlay()
- 播放按钮
- durationUpdate设置元数据

当前状态：上述入口及 removeSong、当前索引访问均已增加边界检查。

### P1-5：后台任务状态可能与真实状态不一致

原问题：startBackgroundTask调用失败时，isTaskRunning仍然可能被设置为true，后续请求会被错误拦截。

当前状态：仅成功或系统明确返回“任务已存在”时设为 true，其他错误保持 false。

## 五、P2问题

- console日志与hilog混用
- 日志Tag仍有testTag
- 多处未使用import
- HTTP错误统一返回null，丢失具体错误类型
- 多个资源地址仍使用HTTP
- Start页面定时器在点击跳过后没有取消
- 部分命名和格式不统一

这些问题不属于本次 Day 1 模块四的核心修复范围，保留为后续任务。

## 六、关于FSM的当前结论

当前项目使用AVPlayer stateChange进行状态驱动处理，
但尚未定义完整的业务状态枚举、转移表和非法转移保护。

当前更准确的描述：
“基于AVPlayer状态回调管理播放状态，并使用意图序列守卫处理异步结果乱序。”

## 七、第一轮修改涉及的文件

- config/ApiConfig.ets
- utils/AIAssistant.ets
- viewmodels/FindViewModel.ets
- pages/Layout.ets
- docs/day01-code-audit.md

## 八、第二轮问题分析

### 8.1 为什么意图检查触发次数少

第一轮守卫以歌曲 ID 或只在网络请求返回处检查。歌曲 ID 是业务实体身份，不是一次点击操作的身份；同一首歌连续点击时 ID 完全相同，因此无法识别新旧点击。另一方面，若只在 `getSongRealUrl()` 后检查一次，`singPlay()` 内部的 `reset()` 等异步边界仍可能让状态在等待期间变化。第二轮改为每次点击递增 `playIntentSequence`，并在 URL 请求和播放器等待之后各检查一次。

### 8.2 为什么仍然出现两个 Play

意图守卫只回答“这个异步结果是否仍是最新”，不回答“导航栈里是否已有 Play”。原代码还在播放器确认前直接调用了一次 `pushPathByName('Play', ...)`，随后又通过辅助方法再次导航，明确具备形成 `Layout -> Play -> Play` 的路径。第二轮删除过早 push，并由 `openPlayPageOnce()` 读取 `getAllPathName()`；栈中存在 Play 时不再 push。

### 8.3 为什么两个 Play 都显示第二首歌曲

两个 Play 页面都通过 `AppStorageV2` 连接同一个 `GlobalMusic`。它们不是各自持有歌曲快照，而是观察同一个全局播放状态。因此第二首歌曲写入 `GlobalMusic` 后，栈中的两个 Play 实例都会刷新并显示第二首歌，看起来像“两个页面都跳成了 B”。

### 8.4 为什么第二首有时没有真正播放

原 `singPlay()` 没有等待 `changeSong()`，而 `changeSong()` 内部又等待异步 `player.reset()`。A/B 两次切歌可交错执行：页面先被新的 `GlobalMusic` 刷新，但底层 `player.url` 可能仍由旧 reset 的后续步骤覆盖，或播放器尚未完成初始化。第二轮将播放调用链改成 `Promise<boolean>`，只在最新操作 reset 完成、URL 已写入播放器且状态已提交后返回 true。

### 8.5 三个并发控制域

1. 网络请求域：`playIntentSequence` 淘汰乱序返回的旧 URL 请求。
2. 导航栈域：`getAllPathName()` 检查 Play 是否已经存在，避免重复 push。
3. 播放器状态域：`playOperationSequence` 覆盖发现页、动态页、播放列表、上一首、下一首和 AVSession 系统播控等全部播放入口。

单个序列无法替代另外两个域：网络序列看不到导航栈，也覆盖不了不经过发现页的播放器入口；播放器序列同样不负责页面栈结构。

### 8.6 第二轮修复方案

- 删除发现页的重复 `singPlay()` 与过早导航。
- 每次播放点击创建歌曲快照，不修改发现页缓存对象。
- 在每个关键 await 后检查意图/操作序列，过期立即 return。
- `AvPlayerManager` 在 reset 成功且操作仍最新后才更新列表、`GlobalMusic` 和 `player.url`。
- `prevPlay`、`nextPlay`、`removeSong` 全部异步化并增加空列表、索引保护。
- 所有 UI/AVSession 调用点显式处理 Promise。
- 后台任务状态只在成功或“已存在”时标为运行。

### 8.7 当前剩余风险

- `playOperationSequence` 是“最后操作获胜”守卫，不是完整播放器有限状态机；底层设备对交叠 reset 的具体容忍度仍需真机压力测试。
- 后台长时任务 API 不是所有设备都支持，编译器仍给出系统能力兼容提示。
- 缺少可注入的网络层和 AVPlayer fake，确定性竞态目前主要依赖真机/模拟器日志验证。
- Git 历史中的旧密钥仍可能被检出，必须先撤销密钥，再单独规划历史清理与协作分支同步。
- 当前日志仍混用 console 与 hilog，后续应统一。
