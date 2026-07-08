# ROADMAP.md 规范规则

> 本文件定义 ROADMAP.md 的编写规范、状态流转、版本规划和维护原则。
>
> 适用于所有 FoundationX 项目的路线图文档。

---

## 1. 文档目的

`ROADMAP.md` 用于记录项目的发展路线、阶段目标、核心任务、优先级和交付计划。

它不是临时待办清单，而是项目中长期规划的统一入口。

---

## 2. 基本原则

### 2.1 保持高层次

Roadmap 应关注：

- 项目阶段
- 重要功能
- 架构演进
- 版本目标
- 关键风险
- 里程碑

不应记录过细的实现细节，例如单个函数、变量名或临时调试任务。

---

### 2.2 可追踪

每个路线项都应具备明确状态，避免出现模糊描述。

推荐状态：

| 状态          | 含义                   |
| ------------- | ---------------------- |
| `Planned`     | 已计划，尚未开始       |
| `In Progress` | 正在进行               |
| `Blocked`     | 被依赖、问题或资源阻塞 |
| `Done`        | 已完成                 |
| `Deferred`    | 延后处理               |
| `Cancelled`   | 已取消                 |

---

### 2.3 可验证

每个重要任务应说明完成标准。

示例：

```md
### 用户认证模块

Status: In Progress
Priority: High
Target: v0.3.0

Done when:

- 支持邮箱登录
- 支持密码重置
- 登录接口有基础测试
- 文档已更新
```

---

## 3. 优先级规则

推荐使用以下优先级：

| 优先级     | 含义               |
| ---------- | ------------------ |
| `Critical` | 阻塞发布或核心能力 |
| `High`     | 当前阶段重点       |
| `Medium`   | 重要但不紧急       |
| `Low`      | 可选优化           |
| `Later`    | 暂不排期           |

优先级不应频繁变动。变更时应在更新记录中说明原因。

---

## 4. 推荐结构

`ROADMAP.md` 推荐使用以下结构：

```md
# Roadmap

## Vision

简要说明项目长期目标。

## Current Focus

当前阶段最重要的 1-3 个方向。

## Milestones

### v0.1.0 - 基础版本

Status: Done
Target Date: 2026-06

Goals:

- 初始化项目结构
- 完成核心模块雏形
- 建立基础测试流程

### v0.2.0 - 功能扩展

Status: In Progress
Target Date: 2026-07

Goals:

- 增加用户管理
- 增加配置系统
- 完善错误处理

## Backlog

### 功能类

- [ ] 支持插件系统
- [ ] 增加导入导出能力

### 架构类

- [ ] 拆分核心模块
- [ ] 优化缓存策略

### 文档类

- [ ] 补充快速开始文档
- [ ] 增加 API 示例

## Risks & Dependencies

- 第三方 API 稳定性
- 数据迁移成本
- 性能瓶颈

## Changelog

### 2026-06-09

- 新增 v0.2.0 规划
- 调整用户管理模块优先级为 High
```

---

## 5. Roadmap 条目格式

每个较大的任务建议使用统一格式：

```md
### 任务名称

Status: Planned
Priority: High
Target: v0.4.0
Owner: Optional

Description:

简要说明该任务要解决的问题。

Scope:

- 包含内容 A
- 包含内容 B

Out of Scope:

- 不包含内容 C
- 不包含内容 D

Done when:

- 完成标准 1
- 完成标准 2
- 完成标准 3
```

---

## 6. 更新规则

### 6.1 更新时间

建议在以下情况更新 `ROADMAP.md`：

* 新版本开始前
* 里程碑完成后
* 需求范围发生变化时
* 优先级发生变化时
* 有重大阻塞或风险时

---

### 6.2 更新要求

每次更新应保证：

* 状态准确
* 优先级清晰
* 已完成事项及时标记为 `Done`
* 被取消或延后的事项说明原因
* 不保留过期、误导性的计划

---

## 7. 不建议写入的内容

`ROADMAP.md` 不应包含：

* 临时 bug 列表
* 过细的开发任务
* 私密凭证或密钥
* 未确认的承诺
* 与项目路线无关的讨论记录
* 已废弃但未标注的计划

---

## 8. 与其他文档的关系

| 文件              | 用途                         |
| ----------------- | ---------------------------- |
| `README.md`       | 项目介绍、安装、使用方式     |
| `ROADMAP.md`      | 项目规划、阶段目标、未来方向 |
| `CHANGELOG.md`    | 已发布版本的变更记录         |
| `CONTRIBUTING.md` | 贡献规则                     |
| `TODO.md`         | 短期、细粒度任务             |

---

## 9. 推荐约定

* 使用 Markdown 标准语法
* 一个路线项只表达一个清晰目标
* 状态字段统一英文或统一中文，不混用
* 版本号建议遵循语义化版本，例如 `v1.2.0`
* 日期建议使用 `YYYY-MM-DD`
* Roadmap 应体现方向，而不是替代 issue tracker

---

## 10. 状态流转规则

Roadmap 条目的状态应按照明确流程流转，避免随意变更。

推荐流转：

```text
Planned -> In Progress -> Done
Planned -> Deferred
Planned -> Cancelled
In Progress -> Blocked
Blocked -> In Progress
Blocked -> Deferred
```

### 10.1 Planned

表示该事项已经被认可，但尚未开始执行。

适用情况：

* 已确定要做
* 已进入路线规划
* 尚未分配具体实现时间
* 尚未开始开发

---

### 10.2 In Progress

表示该事项已经开始推进。

适用情况：

* 已有明确负责人
* 已经开始设计、开发、测试或文档工作
* 当前版本或当前阶段正在处理

---

### 10.3 Blocked

表示该事项暂时无法继续。

必须说明阻塞原因。

示例：

```md
Status: Blocked

Blocked by:

- 等待第三方 API 文档更新
- 依赖数据库迁移完成
- 需要确认权限模型设计
```

---

### 10.4 Done

表示该事项已经完成，并符合完成标准。

不建议仅因为代码合并就标记为 `Done`。

应同时满足：

* 功能完成
* 基础测试完成
* 文档更新完成
* 没有已知阻塞问题
* 与原始目标一致

---

### 10.5 Deferred

表示该事项仍然有价值，但暂时延后。

必须说明延后原因。

示例：

```md
Status: Deferred

Reason:

- 当前版本优先处理核心流程
- 该功能依赖后续架构调整
```

---

### 10.6 Cancelled

表示该事项已经取消，不再计划执行。

必须说明取消原因。

示例：

```md
Status: Cancelled

Reason:

- 需求已被新的方案替代
- 当前项目方向已调整
```

---

## 11. 版本规划规则

版本规划应保持清晰、可交付、可验证。

### 11.1 一个版本应有明确主题

不建议一个版本同时包含过多方向。

推荐：

```md
### v0.3.0 - 用户系统完善
```

不推荐：

```md
### v0.3.0 - 用户系统、性能优化、插件市场、UI 重构、部署平台
```

---

### 11.2 每个版本应包含目标范围

推荐格式：

```md
### v0.3.0 - 用户系统完善

Status: Planned
Target Date: 2026-07-15

Goals:

- [ ] 支持用户注册
- [ ] 支持用户登录
- [ ] 支持密码重置
- [ ] 增加用户权限字段

Non-goals:

- 不实现第三方 OAuth 登录
- 不实现组织 / 团队管理
```

---

### 11.3 版本目标不宜过多

建议每个版本包含：

* 1 个主目标
* 2-5 个核心任务
* 少量必要的修复或文档工作

Roadmap 不是无限愿望清单。

---

## 12. 任务拆分规则

### 12.1 任务应按价值拆分

优先按用户价值、系统能力或交付结果拆分，而不是单纯按技术步骤拆分。

推荐：

```md
- 支持用户修改个人资料
- 支持导出报表
- 支持管理员查看审计日志
```

不推荐：

```md
- 新增字段
- 修改函数
- 调整样式
- 改一下接口
```

---

### 12.2 大任务必须拆分

过大的任务应拆成多个可追踪条目。

不推荐：

```md
- [ ] 完成后台管理系统
```

推荐：

```md
- [ ] 完成管理员登录
- [ ] 完成用户列表管理
- [ ] 完成角色权限配置
- [ ] 完成操作日志查看
```

---

### 12.3 每个任务只表达一个目标

不推荐：

```md
- [ ] 优化登录、注册、权限、数据库和部署
```

推荐：

```md
- [ ] 优化登录流程
- [ ] 完善注册校验
- [ ] 调整权限模型
- [ ] 优化数据库索引
- [ ] 更新部署脚本
```

---

## 13. Backlog 管理规则

Backlog 用于收集未来可能处理的事项，但不代表承诺。

### 13.1 Backlog 应分类管理

推荐分类：

```md
## Backlog

### Features

- [ ] 插件系统
- [ ] 多语言支持
- [ ] 批量导入

### Improvements

- [ ] 优化启动速度
- [ ] 减少重复配置
- [ ] 改进错误提示

### Architecture

- [ ] 拆分核心模块
- [ ] 引入任务队列
- [ ] 优化缓存层

### Documentation

- [ ] 增加部署说明
- [ ] 增加 API 示例
- [ ] 增加故障排查文档
```

---

### 13.2 Backlog 应定期清理

建议每个主要版本结束后清理一次 Backlog。

需要处理：

* 删除已经无意义的事项
* 合并重复事项
* 拆分过大的事项
* 提升已明确排期的事项到 Milestones
* 标记不再计划执行的事项为 `Cancelled`

---

## 14. 风险记录规则

Roadmap 中应记录会影响交付的关键风险。

推荐格式：

```md
## Risks & Dependencies

### Third-party API Stability

Impact: High
Status: Monitoring

Description:

项目依赖第三方 API。如果该 API 发生变更，可能影响核心功能。

Mitigation:

- 增加适配层
- 增加错误降级逻辑
- 保留备用服务方案
```

---

### 14.1 风险应包含影响级别

推荐使用：

| 级别     | 含义             |
| -------- | ---------------- |
| `High`   | 可能阻塞版本发布 |
| `Medium` | 可能影响部分功能 |
| `Low`    | 影响较小，可接受 |

---

### 14.2 风险应包含应对措施

不建议只写风险，不写处理方案。

不推荐：

```md
- 数据量变大后可能变慢
```

推荐：

```md
### 数据增长导致性能下降

Impact: Medium
Status: Monitoring

Mitigation:

- 增加分页
- 增加索引
- 引入缓存
- 增加性能测试
```

---

## 15. Roadmap 与 Issue 的边界

Roadmap 负责方向，Issue 负责执行。

### 15.1 应写入 Roadmap 的内容

* 版本目标
* 重要功能
* 架构方向
* 长期优化
* 关键风险
* 发布计划

### 15.2 应写入 Issue 的内容

* 具体 bug
* 具体开发任务
* 代码修改细节
* 复现步骤
* 单个接口调整
* 单个页面问题

---

## 16. Roadmap 更新检查清单

每次修改 `ROADMAP.md` 前，应检查：

```md
- [ ] 是否明确说明了目标？
- [ ] 是否设置了状态？
- [ ] 是否设置了优先级？
- [ ] 是否有完成标准？
- [ ] 是否属于 Roadmap 范围，而不是普通 TODO？
- [ ] 是否和已有条目重复？
- [ ] 是否影响当前版本目标？
- [ ] 是否需要同步 README、CHANGELOG 或 Issue？
```

---

## 17. Pull Request 修改规则

如果通过 PR 修改 `ROADMAP.md`，建议遵循以下规则：

### 17.1 PR 应说明修改原因

示例：

```md
This PR updates ROADMAP.md to:

- Add v0.4.0 planning
- Move plugin system to Deferred
- Mark user authentication as Done
```

---

### 17.2 不允许无原因删除路线项

删除路线项时，应说明原因。

推荐：

```md
- Removed legacy import plan because it has been replaced by the new plugin-based import system.
```

---

### 17.3 重大路线变更需要评审

以下变更应经过评审：

* 新增大版本目标
* 删除核心功能计划
* 修改当前阶段重点
* 改变架构方向
* 调整发布日期
* 将 `Planned` 改为 `Cancelled`
* 将 `High` 改为 `Low`

---

## 18. 命名规范

### 18.1 版本名称

推荐格式：

```md
v主版本.次版本.修订版本 - 版本主题
```

示例：

```md
### v1.0.0 - Stable Release
### v1.1.0 - Plugin System
### v1.2.0 - Performance Improvements
```

---

### 18.2 任务名称

任务名称应简洁、明确、可理解。

推荐：

```md
- 支持用户导出数据
- 增加管理员审计日志
- 优化首页加载速度
```

不推荐：

```md
- 做一下数据
- 改改管理端
- 优化东西
```

---

### 18.3 日期格式

统一使用：

```text
YYYY-MM-DD
```

示例：

```md
Target Date: 2026-07-15
Updated: 2026-06-09
```

---

## 19. 语言规范

项目 Roadmap 应保持语言一致。

可以选择：

* 全中文
* 全英文
* 中文标题 + 英文字段
* 英文标题 + 中文说明

不建议在同一类字段中混用。

推荐：

```md
Status: Planned
Priority: High
Target Date: 2026-07-15
```

或：

```md
状态：已计划
优先级：高
目标日期：2026-07-15
```

不推荐：

```md
Status: 已计划
优先级: High
Target Date：下个月
```

---

## 20. 完成标准规范

每个重要条目应包含 `Done when`。

### 20.1 完成标准应可验证

推荐：

```md
Done when:

- 用户可以成功注册账号
- 邮箱格式校验生效
- 注册接口有基础测试
- README 中包含注册流程说明
```

不推荐：

```md
Done when:

- 做完
- 差不多可以用
- 基本完善
```

---

### 20.2 完成标准不应过度技术化

Roadmap 的完成标准应更关注结果，而不是实现细节。

推荐：

```md
Done when:

- 用户可以导出 CSV 文件
- 导出失败时有明确错误提示
- 大文件导出不会阻塞主流程
```

不推荐：

```md
Done when:

- 修改 exportData 函数
- 增加变量 tempPath
- 调整第 120 行逻辑
```

---

## 21. 反例

以下内容不适合直接写入 `ROADMAP.md`：

```md
- [ ] 明天修一下那个 bug
- [ ] 改第 35 行
- [ ] 找小王问一下
- [ ] 看看能不能做 AI
- [ ] 优化一下所有东西
- [ ] 尽快上线
- [ ] 重构整个项目
```

这些内容问题在于：

* 时间不明确
* 范围不明确
* 结果不可验证
* 过于琐碎
* 缺少优先级
* 缺少完成标准

---

## 22. 最终维护原则

Roadmap 应始终回答三个问题：

1. 当前项目正在做什么？
2. 接下来项目准备做什么？
3. 哪些事情暂时不做或存在风险？

只要 `ROADMAP.md` 能清楚回答这三个问题，它就是有效的。

---

## 26. Roadmap 决策规则

Roadmap 中的每一项都应经过基本判断，不应因为"想做"就直接加入当前版本。

建议在加入前回答以下问题：

```md
- 这个事项解决什么问题？
- 对用户或项目有什么价值？
- 是否属于当前阶段目标？
- 是否存在更高优先级事项？
- 是否有明确完成标准？
- 是否依赖其他未完成事项？
- 是否应该放入 Backlog，而不是当前 Milestone？
```

---

### 26.1 加入当前版本的条件

一个事项适合加入当前版本，通常应满足：

* 与当前版本主题直接相关
* 对核心流程有明显价值
* 范围可控
* 能在当前周期内完成
* 依赖项基本明确
* 完成标准可验证

---

### 26.2 放入 Backlog 的条件

一个事项更适合放入 Backlog，通常是因为：

* 有价值但不紧急
* 方向还不够明确
* 依赖尚未完成
* 缺少设计方案
* 当前版本范围已经过大
* 只是一个想法或候选方案

---

### 26.3 延后的条件

一个事项应标记为 `Deferred`，通常是因为：

* 当前资源不足
* 当前版本目标变化
* 依赖未完成
* 技术方案需要重新评估
* 用户价值暂时不明确
* 有更重要事项需要优先处理

---

## 27. Roadmap 评审规则

Roadmap 应定期评审，避免变成过期文档。

### 27.1 评审频率

推荐频率：

| 项目阶段     | 建议频率       |
| ------------ | -------------- |
| 早期探索阶段 | 每 1-2 周      |
| 快速开发阶段 | 每 2-4 周      |
| 稳定维护阶段 | 每个版本结束后 |
| 长期维护项目 | 每 1-2 个月    |

---

### 27.2 评审内容

每次评审应检查：

```md
- 当前重点是否仍然准确？
- 当前 Milestone 是否过大？
- 是否有任务已经完成但未标记？
- 是否有任务长期停留在 In Progress？
- 是否有任务长期 Blocked？
- Backlog 是否过期或重复？
- 风险是否仍然存在？
- 目标日期是否需要调整？
- 是否需要同步 CHANGELOG.md？
```

---

### 27.3 长期未更新处理

如果某个 Roadmap 条目长期没有变化，应重新评估。

建议规则：

```md
- 30 天无变化：检查状态是否准确
- 60 天无变化：评估是否仍属于当前版本
- 90 天无变化：考虑移入 Deferred 或 Backlog
```

---

## 28. 标签规范

为了方便分类，可以为 Roadmap 条目增加标签。

推荐标签：

| 标签              | 含义       |
| ----------------- | ---------- |
| `feature`         | 新功能     |
| `improvement`     | 功能改进   |
| `architecture`    | 架构调整   |
| `performance`     | 性能优化   |
| `security`        | 安全相关   |
| `documentation`   | 文档相关   |
| `testing`         | 测试相关   |
| `maintenance`     | 维护清理   |
| `breaking-change` | 破坏性变更 |
| `research`        | 调研事项   |

示例：

```md
### Plugin System

Status: Planned
Priority: High
Target: v0.5.0
Tags: feature, architecture
```

---

## 29. 依赖关系规则

如果某个事项依赖其他事项，应显式写出。

推荐格式：

```md
### Audit Log

Status: Planned
Priority: Medium
Target: v0.4.0

Depends on:

- User Permission Model
- Database Migration v2
```

---

### 29.1 避免隐藏依赖

不推荐只写：

```md
- [ ] 增加审计日志
```

如果它实际上依赖权限系统、数据库结构和后台页面，应写清楚。

推荐：

```md
### Audit Log

Depends on:

- 权限模型稳定
- 操作记录表设计完成
- 管理后台基础页面完成
```

---

### 29.2 阻塞项必须可追踪

如果状态为 `Blocked`，必须说明被什么阻塞。

```md
Status: Blocked

Blocked by:

- Waiting for permission model design
```

---

## 30. 指标规则

对于性能、稳定性、增长类目标，应尽量写出可衡量指标。

### 30.1 性能类

推荐：

```md
Done when:

- 首页首屏加载时间低于 2 秒
- 常用查询在 500ms 内返回
- 批量导入 10,000 条数据不会超时
```

不推荐：

```md
Done when:

- 性能变好
- 查询更快
```

---

### 30.2 稳定性类

推荐：

```md
Done when:

- 核心流程有自动化测试覆盖
- 常见异常有明确错误提示
- 服务异常时不会导致数据丢失
```

---

### 30.3 文档类

推荐：

```md
Done when:

- README 包含安装步骤
- 文档包含至少一个完整使用示例
- 新用户可以根据文档完成本地启动
```

---

## 31. 破坏性变更规则

如果 Roadmap 中包含破坏性变更，必须明确标注。

示例：

```md
### Configuration Format v2

Status: Planned
Priority: High
Target: v1.0.0
Tags: breaking-change, architecture

Breaking Changes:

- 旧版配置字段 `server.port` 将改为 `app.server.port`
- 旧版插件配置格式不再兼容

Migration Plan:

- 提供迁移脚本
- 在文档中说明新旧配置差异
- 在 v0.9.x 中提前提示废弃信息
```

---

### 31.1 破坏性变更必须包含迁移方案

不允许只写破坏性变更，不写迁移路径。

必须说明：

* 影响范围
* 旧行为
* 新行为
* 迁移方式
* 预计生效版本

---

## 32. 废弃计划规则

如果某项能力未来会移除，应在 Roadmap 中提前记录。

推荐格式：

```md
### Deprecate Legacy Import API

Status: Planned
Priority: Medium
Target: v1.0.0
Tags: breaking-change, maintenance

Reason:

旧导入接口难以维护，且已被新的通用导入系统替代。

Deprecation Plan:

- v0.8.0 标记为 deprecated
- v0.9.0 输出迁移提示
- v1.0.0 正式移除

Migration:

- 使用 `/api/import/v2`
- 参考新版导入文档
```

---

## 33. 发布门禁规则

Roadmap 中的版本不应只看功能完成，还应满足发布条件。

推荐发布门禁：

```md
Release checklist:

- [ ] 当前版本目标全部完成或明确移出
- [ ] 关键测试通过
- [ ] README 已更新
- [ ] CHANGELOG 已更新
- [ ] 已知风险已记录
- [ ] 破坏性变更已说明
- [ ] 迁移说明已补充
- [ ] 没有未处理的 Critical 问题
```

---

## 34. Roadmap 与 CHANGELOG 的衔接

Roadmap 记录计划，CHANGELOG 记录事实。

### 34.1 Roadmap 中的 Done 不等于发布

Roadmap 条目标记为 `Done`，表示该目标完成。

但只有正式发布后，相关内容才应写入 `CHANGELOG.md`。

---

### 34.2 发布后同步

版本发布后，应进行同步：

```md
- ROADMAP.md：将版本状态改为 Done
- CHANGELOG.md：记录实际发布内容
- README.md：更新使用方式
- TODO.md / Issues：关闭或调整相关任务
```

---

## 35. Roadmap 与架构决策的关系

Roadmap 不应替代架构决策记录。

如果某个路线项涉及重要架构选择，应链接到 ADR 或设计文档。

推荐：

```md
### Plugin System

Status: Planned
Priority: High
Target: v0.5.0

Related Docs:

- ADR-003: Plugin Loading Strategy
- docs/design/plugin-system.md
```

---

### 35.1 需要单独设计文档的情况

以下事项不建议只写在 Roadmap 中：

* 权限模型重构
* 插件系统
* 数据库迁移
* API 版本升级
* 多租户架构
* 大规模性能优化
* 安全模型调整

这些事项应在 Roadmap 中保留摘要，并链接到详细设计文档。

---

## 36. 负责人规则

团队项目中，较大的 Roadmap 条目建议设置负责人。

推荐格式：

```md
Owner: @username
```

或：

```md
Owner: Backend Team
```

---

### 36.1 Owner 的职责

Owner 不一定是唯一实现者，但应负责：

* 推进该事项
* 更新状态
* 记录阻塞
* 协调依赖
* 确认完成标准
* 在版本结束时同步结果

---

### 36.2 无负责人事项

如果事项没有负责人，应谨慎加入当前 Milestone。

可以放在 Backlog：

```md
Status: Backlog
Owner: Unassigned
```

---

## 37. 范围控制规则

Roadmap 最常见的问题是范围膨胀。

### 37.1 每个 Milestone 应限制范围

建议：

```md
- 当前版本只保留最关键目标
- 不把所有 Backlog 都塞进下个版本
- 不在开发中途随意加入大功能
- 新增范围必须说明原因
```

---

### 37.2 范围变更必须记录

示例：

```md
Scope changes:

### 2026-06-09

- Added audit log because permission changes need traceability.
- Moved plugin marketplace to Deferred because plugin core is not stable yet.
```

---

## 38. 当前重点规则

`Current Focus` 应保持非常简短。

推荐只写 1-3 项：

```md
## Current Focus

- 完成用户认证闭环
- 稳定配置系统
- 补齐核心文档
```

不推荐：

```md
## Current Focus

- 用户认证
- 配置系统
- 插件系统
- 性能优化
- 管理后台
- 部署平台
- 多语言
- 数据导入
- 数据导出
```

如果当前重点超过 3 项，通常说明没有重点。

---

## 39. Roadmap 精简规则

Roadmap 应清晰，不应无限增长。

### 39.1 可归档内容

以下内容可以移出主 Roadmap：

* 已完成很久的版本
* 已取消很久的计划
* 过期讨论记录
* 太细的任务列表
* 已迁移到 Issue 的执行细节

---

### 39.2 归档方式

可以创建：

```md
docs/archive/ROADMAP-2025.md
docs/archive/ROADMAP-v0.x.md
```

主 `ROADMAP.md` 中只保留：

```md
## Archive

- [ROADMAP-2025](../archive/ROADMAP-2025.md)
- [ROADMAP-v0.x](../archive/ROADMAP-v0.x.md)
```

---

## 40. 机器可读字段规范

如果项目需要自动化解析 Roadmap，建议统一字段格式。

推荐字段：

```md
Status: Planned
Priority: High
Target: v0.4.0
Target Date: 2026-07-15
Owner: @username
Tags: feature, backend
```

不推荐：

```md
状态大概是还没开始
优先级应该挺高
预计下个月吧
```

---

### 40.1 字段顺序

推荐固定顺序：

```md
Status:
Priority:
Target:
Target Date:
Owner:
Tags:
```

完整示例：

```md
### User Permission Model

Status: In Progress
Priority: High
Target: v0.4.0
Target Date: 2026-07-15
Owner: Backend Team
Tags: feature, security, architecture
```

---

## 41. Roadmap Lint 规则

可以用人工或脚本检查 Roadmap 质量。

建议检查项：

```md
- [ ] 是否存在没有 Status 的大条目？
- [ ] 是否存在没有 Priority 的当前版本任务？
- [ ] 是否存在没有 Done when 的重要任务？
- [ ] 是否存在模糊词，例如"尽快""优化一下""完善一下"？
- [ ] 是否存在 Target Date 格式不统一？
- [ ] 是否存在长期 Blocked 但没有原因的事项？
- [ ] 是否存在 Cancelled 但没有原因的事项？
- [ ] 是否存在 Deferred 但没有重新评估时间的事项？
```

---

## 42. 模糊词限制

Roadmap 中应避免模糊表达。

不推荐：

```md
- 尽快支持插件
- 后面优化性能
- 完善用户体验
- 做一下管理后台
- 重构一下代码
```

推荐：

```md
- 支持本地插件加载
- 将首页加载时间优化到 2 秒以内
- 改进登录失败时的错误提示
- 增加用户列表和角色管理页面
- 拆分认证模块和用户资料模块
```

---

## 43. 研究类任务规则

有些事项还不能直接开发，需要先调研。

推荐使用 `research` 标签。

示例：

```md
### Evaluate Search Engine Options

Status: Planned
Priority: Medium
Target: v0.6.0
Tags: research, architecture

Goal:

评估是否需要引入独立搜索服务。

Questions:

- 当前数据库搜索是否足够？
- 数据量增长后性能是否可接受？
- 是否需要全文搜索？
- 是否需要多语言分词？

Done when:

- 完成至少两个方案对比
- 明确推荐方案
- 记录取舍原因
- 决定是否进入实现阶段
```

---

## 44. 安全相关规则

涉及安全的路线项应更严格。

安全类任务应包含：

```md
- 风险说明
- 影响范围
- 完成标准
- 测试要求
- 回滚或缓解方案
```

示例：

```md
### Strengthen API Authentication

Status: Planned
Priority: Critical
Target: v0.4.0
Tags: security, backend

Description:

增强 API 认证机制，降低未授权访问风险。

Done when:

- 所有受保护接口都需要认证
- Token 过期逻辑生效
- 未授权请求返回明确错误
- 关键路径有测试覆盖
```

---

## 45. 数据迁移规则

如果路线项涉及数据迁移，必须写明迁移策略。

示例：

```md
### Database Schema v2

Status: Planned
Priority: High
Target: v0.5.0
Tags: architecture, migration

Migration Plan:

- 新增字段时保持向后兼容
- 先写入新旧字段
- 验证数据一致性
- 再移除旧字段

Rollback Plan:

- 保留旧字段一个版本
- 保留迁移前备份
- 迁移失败时恢复旧结构
```

---

## 46. 回滚规则

高风险路线项应包含回滚方案。

适用场景：

* 数据库迁移
* 权限模型调整
* 配置格式变化
* API 版本升级
* 依赖服务替换
* 核心流程重构

推荐格式：

```md
Rollback Plan:

- 保留旧逻辑到下一个小版本
- 增加开关控制新功能
- 出现严重问题时恢复旧实现
```

---

## 47. 实验功能规则

实验性功能不应直接写成稳定承诺。

推荐格式：

```md
### Experimental AI Assistant

Status: Planned
Priority: Low
Target: v0.7.0
Tags: experimental, research

Experiment Goal:

验证 AI 助手是否能提升用户配置效率。

Success Criteria:

- 用户能通过自然语言完成基础配置
- 错误率在可接受范围内
- 不影响现有手动配置流程

Exit Criteria:

- 如果效果不稳定，则移入 Deferred
- 如果验证成功，则拆分为正式功能规划
```

---

## 48. 多版本规划规则

Roadmap 可以规划多个版本，但不应过度详细规划太远的未来。

推荐：

```md
## Milestones

### v0.2.0 - Core Features
详细规划

### v0.3.0 - Stability
中等详细

### v0.4.0 - Extensions
粗略规划
```

---

### 48.1 越远的版本越粗略

推荐原则：

```md
当前版本：明确任务、完成标准、目标日期
下一个版本：明确方向、核心目标
更远版本：只保留主题和候选事项
```

---

## 49. Roadmap 冲突处理规则

如果 Roadmap 与实际开发不一致，应及时修正。

### 49.1 实际已经改变

如果实际开发方向已经变化，不要保留旧 Roadmap 假装仍然有效。

应更新：

```md
- Current Focus
- Milestones
- Backlog
- Deferred
- Cancelled
- Changelog
```

---

### 49.2 计划无法完成

如果当前版本目标无法完成，应选择：

```md
- 缩小范围
- 移到下个版本
- 拆分任务
- 标记 Deferred
- 调整目标日期
```

不建议静默拖延。

---

## 50. Roadmap 最终质量标准

一个合格的 `ROADMAP.md` 应满足：

```md
- 新成员能看懂项目方向
- 维护者能知道当前重点
- 贡献者能判断什么适合贡献
- 用户能理解未来大致计划
- 已完成和未完成事项区分清楚
- 延后和取消事项有原因
- 风险和依赖有记录
- 文档不过度承诺
- 内容不会替代 Issue 或 TODO
```

---

## 51. 推荐最终文件结构

完整项目中，可以采用：

```text
.
├── README.md
├── ROADMAP.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── TODO.md
└── docs/
    ├── design/
    │   └── plugin-system.md
    ├── adr/
    │   └── ADR-001-project-structure.md
    └── archive/
        └── ROADMAP-2025.md
```

---

## 52. 简洁版规则

如果项目较小，可以使用简洁版 Roadmap。

```md
# Roadmap

## Current Focus

- 当前重点 1
- 当前重点 2
- 当前重点 3

## Now

- [ ] 正在做的事项 1
- [ ] 正在做的事项 2

## Next

- [ ] 下一阶段事项 1
- [ ] 下一阶段事项 2

## Later

- [ ] 未来可能做的事项 1
- [ ] 未来可能做的事项 2

## Done

- [x] 已完成事项 1
- [x] 已完成事项 2
```

适合：

* 个人项目
* 早期原型
* 小型工具
* 不需要复杂版本规划的项目

---

## 53. 严格版规则

如果项目较大，可以使用严格版 Roadmap。

```md
# Roadmap

## Vision

## Strategy

## Current Focus

## Milestones

## Release Plan

## Feature Roadmap

## Architecture Roadmap

## Security Roadmap

## Performance Roadmap

## Backlog

## Deferred

## Cancelled

## Risks & Dependencies

## Metrics

## Changelog

## Archive
```

适合：

* 团队项目
* 商业项目
* 长期维护项目
* 多模块系统
* 有正式发布节奏的项目

---

## 54. 最终建议

`ROADMAP.md` 的目标不是写得越多越好，而是让项目方向更清楚。

维护时优先保证：

```md
清晰 > 完整
准确 > 详细
可验证 > 好听
可维护 > 复杂
```

Roadmap 应该随着项目演进而变化，但不应该频繁失真。

一个好的 Roadmap 应该让读者快速知道：

```md
现在做什么
下一步做什么
以后可能做什么
为什么这样安排
什么事情暂时不做
什么风险需要注意
```
