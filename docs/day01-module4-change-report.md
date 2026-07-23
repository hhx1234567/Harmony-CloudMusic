# Day 1 模块四代码修改报告

## 1. 项目与任务背景

项目为 Mymusic / Harmony-CloudMusic，使用 ArkTS、ArkUI、MVVM、AppStorageV2、`@ObservedV2` / `@Trace`、AVPlayer、AVSession、后台音频长时任务和 HTTP 服务，目标 SDK 为 HarmonyOS 6.0.2（API 22）。

本次只处理 Day 1 模块四：客户端 AI 密钥风险、发现页网络播放意图、Play 导航去重、Tabs 页面身份、播放器异步操作序列、异步调用点、空列表边界、初始化与后台任务状态。未开始 Day 2，未增加业务功能，未改造完整播放器 FSM，也未引入第三方依赖。

修改前基线：

- 分支：`summer-v2`
- Commit：`322f55a1cf169ec79cba5b4026bd2110585a3f81`（短 ID：`322f55a`）
- Commit message：`fix: secure AI config and guard stale play intents`
- 初次直接构建：因 `DEVECO_SDK_HOME` 无效而在配置阶段失败，代码未开始编译。
- 将该环境变量仅对当前命令临时指向本机 SDK 根目录 `F:\DevEco Studio\sdk` 后，修改前构建成功。
- 修改前警告：20 条 ArkTS 警告，主要是 AVPlayer / AVSession 可能抛异常却未处理、后台任务设备能力兼容提示；另有未配置签名的构建警告。
- 修改前已有未提交文件，本轮未回退这些内容；其中 `MusicService.ets`、`HttpClient.ets`、`List.test.ets`、`PlayViewModel.test.ets` 及根目录 `how --stat` 保持为用户工作区改动。

## 2. 修改前的问题现象

### API 密钥泄露

`AIAssistant.ets` 即使把旧调用放进注释，仍保留第三方接口地址、认证 Header 和旧密钥符号引用。历史构建缓存和 HAP 还包含曾编译进去的真实密钥痕迹。注释不是安全边界，编译产物和 Git 历史也不会因当前源码修改而自动消失。

### 网络请求乱序

用户先点 A 再点 B 时，两个 `getSongRealUrl()` 可按 B、A 的顺序返回。歌曲 ID 只能标识资源，不能标识一次点击；同一首歌曲连续点击更无法用 ID 区分。旧结果若只记录“过期”而不立即 return，仍会进入播放器。

### 重复进入 Play

发现页原工作区代码同时存在一次直接 `pushPathByName('Play', ...)` 和一次去重辅助方法调用；播放器确认前就 push，最终可能形成：

```text
Layout
  -> Play
       -> Play
```

### 两个 Play 同时显示最新全局状态

Play 页面都连接同一个 AppStorageV2 `GlobalMusic`。当 B 更新全局状态时，两个 Play 实例会一起刷新，所以两个页面都显示 B，并不代表它们各自保存了独立歌曲。

### AVPlayer reset / setUrl 竞态

`changeSong()` 内有异步 `reset()`，但调用链原先没有一致等待；发现页之外的 Moment、播放列表、上一首、下一首和系统播控也能触发切歌。旧操作可能在新操作之后写 `playIndex`、歌曲信息或 `player.url`，形成页面、全局状态与真实音频不一致。

### Tabs 构建错误

错误模型是每个 `TabContent` 都读取同一个 `currentIndex` 来决定内容。当选中“发现”时，所有循环项都可能构建 Find，触发多个实例及重复 `aboutToAppear()`。当前基线中的 `Layout.ets` 已改为由循环 `index` 决定固定页面，并使用 `item.text` 作为稳定 key；本轮复核通过，无需再次修改。

## 3. 根因分析

问题必须拆成三个独立并发控制域：

1. 网络请求域：控制 URL 请求乱序，使用 `FindViewModel.playIntentSequence`。
2. 导航栈域：控制页面结构，使用 `NavPathStack.getAllPathName()` 查询真实栈状态。
3. 播放器状态域：控制所有播放入口对 AVPlayer 与 GlobalMusic 的写入，使用 `AvPlayerManager.playOperationSequence`。

单个 `playIntentSequence` 只能保护经过发现页 `playSong()` 的调用，无法覆盖 Moment、播放列表、上一首、下一首或 AVSession；它也不知道导航栈是否已有 Play。反过来，导航去重只阻止重复页面，不会阻止旧 URL 或旧 reset 写入播放器。三者职责不能互相替代。

## 4. 修改文件清单

| 文件 | 修改内容 | 修改原因 |
|---|---|---|
| `entry/src/main/ets/utils/AIAssistant.ets` | 删除第三方直连、认证 Header、旧接口模型与注释代码，只保留安全停用响应 | 客户端不得保存或发送厂商密钥 |
| `entry/src/main/ets/viewmodels/FindViewModel.ets` | 单调意图序列、歌曲快照、两次异步后检查、单次播放器调用、成功后导航 | 淘汰旧网络结果并防止过早导航 |
| `entry/src/main/ets/utils/AvPlayerManager.ets` | 独立操作序列、异步 boolean 调用链、reset 后提交状态、列表 upsert、空列表/索引保护 | 统一保护全部播放入口 |
| `entry/src/main/ets/utils/AvSessionManager.ets` | 后台任务真实状态、异步系统播控、初始化/销毁异常处理 | 防止状态假阳性和未处理 Promise |
| `entry/src/main/ets/entryability/EntryAbility.ets` | 小范围音频初始化和释放辅助方法，显式处理 Promise | 降低初始化竞态和未捕获异常风险 |
| `entry/src/main/ets/pages/Find.ets` | 页面异步任务统一 catch | 不遗留未处理 Promise |
| `entry/src/main/ets/pages/Moment.ets` | Moment 播放结果显式处理 | 适配 `singPlay(): Promise<boolean>` |
| `entry/src/main/ets/pages/Play.ets` | 上一首、下一首、当前播放、列表点击、删除均处理异步结果；增加索引保护 | 防止越界和静默 Promise 错误 |
| `entry/src/test/AvPlayerManager.test.ets` | 测试等待 `singPlay` 并验证无效 URL 被安全拒绝 | 适配新签名，避免无效异步断言 |
| `docs/day01-code-audit.md` | 保留根目录原审计内容的副本并追加第二轮分析 | 记录三控制域与剩余风险 |
| `docs/day01-module4-change-report.md` | 新增本报告 | 完整记录设计、验证和限制 |

以下文件已复核但本轮没有产生差异：

- `ApiConfig.ets`：`ENABLE_AI=false`，无第三方密钥，仅保留环境开关和业务服务端地址。
- `Layout.ets`：已使用 `currentIndex` 正确拼写、循环 `index` 固定页面身份和稳定 key。
- `globalMusic.ets`、路由配置、`router_map.json`：无需修改。

## 5. 每个文件的详细修改

### AIAssistant.ets

- 修改前：安全返回逻辑之外仍保留整段第三方直连注释，包括接口地址、认证 Header 和已删除配置字段引用。
- 修改后：`ask()` 先校验空输入；AI 关闭时返回“AI推荐功能正在进行安全后端改造”；即使未来误将开关打开，也只返回“暂不可用”，不发网络请求。
- 原则：客户端只能持有公开配置，服务端密钥必须位于受控后端环境变量。
- 副作用：AI 推荐暂时不可用，这是主动安全降级；普通音乐功能不受影响。

### FindViewModel.ets

- 修改前：工作区代码包含重复 `singPlay()`、播放器执行前直接 push 和之后再次去重导航。
- 修改后：每次点击生成新 `intentId`；复制 `targetSong`；URL 返回后和播放器返回后分别比较序列；任何失败或过期立即 return；只有 `applied=true` 且意图仍最新时调用导航辅助方法。
- 原则：每个异步边界后重新验证“这个操作仍是最新”；缓存对象与操作快照分离。
- 副作用：旧点击会被安静淘汰并留下可定位日志，不再触发页面和播放器写入。

### AvPlayerManager.ets

- 修改前：播放列表和全局状态可在 reset 完成前修改；prev/next/remove 不等待切歌；空列表和索引缺少统一保护。
- 修改后：`singPlay()` 返回 `Promise<boolean>`；每次操作递增 `playOperationSequence`；等待后台任务和 changeSong 后都检查序列；`changeSong()` 在 reset 成功且操作仍最新后才设置 `player.url`、更新列表及 GlobalMusic。
- 播放列表：按歌曲 ID 重新查找；存在则替换快照以更新真实 URL，不存在则加入队首。
- 同一 URL：直接恢复播放，不做无意义 reset。
- 副作用：调用方必须处理 boolean；旧操作返回 false。仍不是完整 FSM，底层设备行为需要压力测试。

### AvSessionManager.ets

- 修改前：后台任务 Promise 未等待，失败后仍无条件设置 `isTaskRunning=true`；系统上一首/下一首未处理 Promise。
- 修改后：成功后才置 true；错误码 9800005 代表任务已存在，可保持 true；其他失败明确置 false。系统播控通过辅助方法处理异步结果和错误。
- 初始化和资源释放改为显式 Promise 返回类型并捕获异常。
- 副作用：后台任务不可用时前台播放仍可继续，并记录日志；设备不支持该系统能力时仍有编译兼容提示。

### EntryAbility.ets

- 修改前：播放器、会话初始化和销毁 Promise 被直接丢弃。
- 修改后：使用两个小型辅助方法依次等待初始化/释放，并在生命周期入口显式 catch；没有重写 UIAbility 生命周期。
- 副作用：页面加载仍不被音频初始化阻塞；极快点击会由 `singPlay` 的 player null 检查安全拒绝。

### Find.ets、Moment.ets、Play.ets

- 修改前：多个 UI 回调直接调用异步方法，不处理结果；Play 播放按钮直接访问 `playList[playIndex]`。
- 修改后：所有相关 Promise 均使用 `then/catch` 或统一辅助方法处理；播放按钮先检查列表和索引；删除当前歌曲会等待播放器管理器完成，列表清空后才退出 Play。
- 副作用：失败会记录日志而非静默；UI 样式未修改。

### AvPlayerManager.test.ets

- 修改前：调用异步 `singPlay` 后立即断言列表已变化，测试存在时序错误，也依赖未初始化播放器。
- 修改后：等待返回结果，使用空 URL 构造稳定的拒绝路径，验证返回 false 且列表不变。
- 副作用：该用例不替代真机 AVPlayer 竞态测试。

### 文档

- 根目录原 `day01-code-audit.md` 未删除；内容复制到 `docs/day01-code-audit.md` 后追加第二轮分析。
- 本报告新增所有要求章节。文档不改变运行时行为。

## 6. 播放意图守卫原理

单调递增序列是只增加、不回退的操作编号。每次点击执行：

```ts
const intentId = ++this.playIntentSequence
```

歌曲 ID 表示“哪首歌”，意图 ID 表示“用户第几次点击”。同一首歌连续点击五次仍有同一个歌曲 ID，但应产生五个不同 intentId。

`await` 会把控制权交还事件循环。等待期间，用户可以再次点击，成员字段已经变化，因此 await 前成立的“我是最新操作”在 await 后不一定成立。检测过期后必须立即 return；仅记录日志而继续执行等同于没有守卫。

歌曲快照避免把 URL 写回发现页缓存对象。缓存继续描述列表数据，`targetSong` 描述本次操作；旧请求被淘汰时不会污染缓存。

A/B 乱序示例：

```text
t0  点击 A，intent=1，发起 URL(A)
t1  点击 B，intent=2，发起 URL(B)
t2  URL(B) 返回，2 == latest，进入播放器
t3  URL(A) 返回，1 != latest，记录“网络结果过期”并 return
t4  播放器只应用 B，只有 B 有资格导航
```

同一首 A 连续点击也会得到 intent=3、intent=4，旧的 3 仍会被 4 淘汰。

## 7. 导航去重原理

`pushPathByName` 的语义是在当前栈顶继续压入页面，不会自动判断同名页面是否已存在。两个各自合法的调用可形成两个 Play。两个 Play 又都观察同一 GlobalMusic，所以最新歌曲 B 会让两个页面同时显示 B。

网络守卫负责“哪个异步结果有效”，导航去重负责“页面是否已经在栈中”。修复使用 API 22 SDK 实际存在的：

```ts
const pathNames = pathStack.getAllPathName()
```

本机 SDK `navigation.d.ts` 显示该方法自 API 10 提供，API 22 可用。若数组包含 `Play`，记录 `[Navigation]` 并停止；否则只执行一次 push。

```text
修复前：Layout -> Play -> Play
修复后：Layout -> Play
```

因此返回一次即可回到 Layout，无需维护会与真实栈失配的永久布尔变量。

## 8. Tabs 修复原理

`index` 是 ForEach 中当前循环项的固定身份：0 永远是推荐，1 永远是发现，2 永远是动态，3 永远是我的。`currentIndex` 是用户此刻选中的位置，只应该控制 Tabs 的选中状态、图标和文字颜色。

若所有 TabContent 用同一个 currentIndex 决定内容，那么切到 1 时每个 TabContent 都可能创建 Find，多个 Find 会各自执行 `aboutToAppear()`，造成重复请求、ViewModel 重建和状态重置。当前代码由 index 构建固定页面，`this.currentIndex === index` 只用于样式；`item.text` 作为稳定唯一 key，让框架在刷新时保持循环项身份。

## 9. 播放器操作序列原理

`FindViewModel` 的守卫保护不了 Moment、播放列表、上一首、下一首、自动下一首和系统播控，所以 AvPlayerManager 必须有独立序列。

reset 是异步边界：调用后播放器状态尚未立即回到可设置新 URL 的状态。旧操作在 reset 后继续写 GlobalMusic 或 `player.url`，会把最新 UI 与底层音频重新分离。现在只有序列仍最新的操作能提交这些字段。

播放器返回 boolean，使调用方能区分“操作已应用”和“被淘汰/无效/未初始化”。整个调用链因此需要 async/await 或明确 then/catch。

交错示例一：

```text
op1(A) -> await reset(A)
op2(B) -> await reset(B)
reset(A) 返回 -> op1 != latest -> false，不写 GlobalMusic/player.url
reset(B) 返回 -> op2 == latest -> 写 B -> true
```

交错示例二：

```text
op3(下一首) -> await 后台任务
op4(播放列表点击 C) -> await 后台任务
op3 返回 -> 已过期 -> false
op4 reset 完成 -> 重新按 C.id 查找列表位置 -> 应用 C
```

同一资源 URL 已是当前播放 URL 时直接调用 play 恢复，并更新列表中该歌曲的真实 URL 快照，不执行 reset。

## 10. 安全设计说明

移动客户端无法保密第三方服务端密钥：安装包在用户设备上，代码、常量、内存、网络调用都能被静态分析、动态调试或代理观察。资源文件、客户端环境变量、Base64 和字符串拆分只是混淆，不是秘密存储。

旧密钥即使已经撤销，也应从当前源码和构建产物删除，避免误用、复制和持续触发安全扫描；撤销只能让它失效，不能让泄漏材料消失。Git 采用内容寻址并保留旧提交，当前文件删除后，旧对象和其他分支仍可能包含密钥。

当前暂时关闭 AI，是因为业务后端代理尚未实现。正确架构为：

```text
HarmonyOS 客户端
  -> 自有业务后端
  -> 后端从环境变量读取第三方 API Key
  -> 第三方 AI API
```

本次不直接重写 Git 历史，因为历史清理会改变 commit ID，需要协调所有分支、标签、协作者和远端，并通常伴随强制推送。应先撤销密钥，再在单独维护窗口执行并通知协作者重新同步。

## 11. 测试方案

1. 正常播放：点击一首歌，确认仅一个 Play，页面/歌曲/音频一致。
2. 人为延迟竞态：仅在测试分支或可注入网络 fake 中让奇数 intent 延迟 1500ms、偶数延迟 100ms；生产代码不得保留延迟。
3. 不同歌曲快速点击 10 轮：最终只应用最后一首。
4. 同一歌曲快速点击 5 轮：每次 intent 不同，旧操作被淘汰。
5. URL 失败：空 URL 不进入播放器、不导航。
6. Tabs：推荐 -> 发现 -> 动态 -> 我的 -> 发现 -> 推荐。
7. 播放器操作：下一首 -> 上一首 -> 下一首 -> 播放列表点击其他歌曲。
8. 导航栈：日志中的路径最多包含一个 Play，返回一次回到 Layout。
9. 密钥搜索：源码、清理后的缓存和新 HAP 不包含真实密钥或第三方直连认证。

本轮没有把人为延迟加入生产路径。确定性竞态的预期日志顺序是 `[PlayIntent][1] 开始`、`[PlayIntent][2] 开始`、2 URL 返回并进入播放器、1 URL 返回后过期、2 最终有效；该设备测试尚未实际执行，因此没有伪造实际日志。

## 12. 测试结果

| 测试项 | 预期结果 | 实际结果 | 是否通过 | 证据 |
|---|---|---|---|---|
| 修改前基线构建 | 记录原状态 | 临时指定正确 SDK 根目录后成功 | 通过 | Hvigor `BUILD SUCCESSFUL`，20 条 ArkTS 警告 |
| 修改后干净构建 | 编译成功且不新增警告 | clean 后全量构建成功，降为 3 条后台任务设备能力提示 | 通过 | Hvigor `BUILD SUCCESSFUL in 28 s 247 ms` |
| NavPathStack API | API 22 支持栈查询 | SDK 定义存在，`@since 10` | 通过 | `openharmony/ets/component/navigation.d.ts` |
| 异步调用点静态检查 | 不遗留未处理 singPlay Promise | 所有调用点均 await 或 then/catch | 通过 | 仓库调用点搜索 |
| 本地单元测试 | 空 URL 被拒绝，既有用例不回归 | 3 个测试全部成功，Failure 0、Error 0 | 通过 | `entry/.test/.../test_result.txt` |
| URL 失败代码路径 | 不修改播放列表，返回 false | `singPlay_should_reject_empty_url` 成功 | 通过 | Hvigor `test` 结果 |
| 正常播放 | 一个 Play，页面/歌曲/音频一致 | 未实际执行，需要用户在真机或模拟器验证 | 未验证 | 无设备会话 |
| 人为延迟确定性竞态 | A 过期、只应用 B | 未实际执行；未向生产代码加入延迟 | 未验证 | 无设备会话/网络 fake |
| 不同歌曲快速点击 10 轮 | 不重复 Play，最后一首生效 | 未实际执行，需要用户在真机或模拟器验证 | 未验证 | 无设备会话 |
| 同一歌曲快速点击 5 轮 | 点击可按 intent 区分 | 未实际执行，需要用户在真机或模拟器验证 | 未验证 | 无设备会话 |
| 快速上一首/下一首 | 旧操作被淘汰，无越界崩溃 | 未实际执行，需要用户在真机或模拟器验证 | 未验证 | 无设备会话 |
| Tabs 切换 | 四页固定身份，无重复 Find | 代码结构静态符合；UI 未实际执行 | 部分验证 | `Layout.ets` index 分支与稳定 key |
| 导航最大深度 | 最多一个 Play | 静态仅保留去重辅助方法中的一次 push；运行时未执行 | 部分验证 | `FindViewModel.ets` 调用点搜索 |
| 密钥与直连扫描 | 当前源码和新产物无真实密钥 | 源码 0、非 Git 工作区真实 key 0、新构建产物敏感匹配 0 | 通过 | 干净构建后的安全搜索 |

## 13. 修改后的日志格式

```text
[PlayIntent][1] 开始解析歌曲URL
[PlayIntent][1] 网络结果过期
[PlayerOperation][2] 开始reset
[PlayerOperation][2] 已应用最新URL
[Navigation] 当前导航栈
```

- `[PlayIntent]`：网络请求域，编号对应一次发现页点击。
- `[PlayerOperation]`：播放器状态域，编号覆盖所有播放入口。
- `[Navigation]`：导航栈域，说明是否 push 或拦截。

## 14. 已知限制与后续任务

- 撤销并专项清理 Git 历史中的旧密钥，协调远端和协作者后再执行历史重写。
- 建设 AI 服务端代理、鉴权、限流和审计，客户端只访问自有后端。
- 引入更完整的播放器 FSM 与非法状态转移保护。
- 加强初始化状态管理，让 UI 可感知“初始化中/失败”。
- 增加错误状态和用户提示，目前很多失败只写日志。
- 日志统一迁移到 hilog，并避免输出敏感数据。
- 完善后台任务生命周期及设备能力判断。
- 为网络、导航和播放器引入可注入 fake，建设自动化竞态测试。
- 当前 `playOperationSequence` 能阻止旧操作提交应用层状态，但底层多个 reset 的设备实现仍需真机压力验证。

## 15. 最终验收清单

- [x] 已确认真实文件路径、路由配置和 SDK 版本。
- [x] 已记录修改前分支、Commit、构建状态和警告。
- [x] 当前 AI 为安全关闭状态，AIAssistant 不直连第三方 AI。
- [x] 发现页使用普通私有 `playIntentSequence`，同歌点击也可区分。
- [x] URL 和播放器 await 后均检查过期并立即 return。
- [x] 不修改发现页缓存 item，使用 targetSong 快照。
- [x] 导航读取真实栈状态，最多只 push 一次 Play。
- [x] Tabs 由 index 决定页面，currentIndex 仅用于选中状态，存在稳定 key。
- [x] 播放器拥有独立 `playOperationSequence` 和 boolean 返回值。
- [x] 上一首、下一首、播放按钮、durationUpdate、removeSong 有空列表/索引保护。
- [x] 所有受影响异步调用点显式处理 Promise。
- [x] 后台任务失败不会无条件标记为运行。
- [x] 修改后 ArkTS 工程构建成功且警告数量下降。
- [ ] 真机正常播放、快速点击、导航返回和系统播控压力测试。
- [ ] Git 历史密钥专项清理和 AI 服务端代理。

## 16. Git 信息

- 修改前分支：`summer-v2`
- 修改前 Commit ID：`322f55a1cf169ec79cba5b4026bd2110585a3f81`
- 修改后 Commit ID：由本报告所在提交生成，无法在同一内容寻址提交内自引用；准确短 ID 记录在最终交付回复中。
- 计划 Commit message：`fix: guard playback races and prevent duplicate play routes`
- 修改前存在未提交文件：是。
- 修改后仍将保留未纳入本次提交的用户文件：是，详见最终 `git status`。
