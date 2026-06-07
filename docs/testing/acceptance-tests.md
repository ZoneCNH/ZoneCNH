# Acceptance Tests: Foundation v1

> Foundation v1 跨模块端到端验收场景。验证模块协作的正确性，不是单模块测试。

最后更新：2026-06-07
Status: Approved

---

## 1. 目的

本文档定义 Foundation v1 的整体验收场景，聚焦于**跨模块协作**。单模块的单元测试见各模块 `specs/*/SPEC.md` Section 16。

验收场景回答的问题：**Foundation v1 作为一个整体是否可以正常工作？**

---

## 2. 场景总览

| 编号 | 场景 | 涉及模块 | 优先级 |
|------|------|----------|--------|
| AT-001 | 正常启动（完整链路） | x.go, kernel, configx, observex | P0 |
| AT-002 | 配置加载 → 模块初始化 | configx, kernel, 所有 L1 模块 | P0 |
| AT-003 | 模块启动失败回滚 | kernel, configx, observex | P0 |
| AT-004 | 优雅停机 | kernel, 所有已注册模块 | P0 |
| AT-005 | 健康检查全链路 | kernel, observex, 所有模块 | P1 |
| AT-006 | 弹性策略生效 | resiliencx, kernel | P1 |
| AT-007 | 横切模块贯穿 | alertx, observex, 业务域模块 | P1 |
| AT-008 | 配置热更新 | configx, 业务域模块 | P2 |

---

## 3. 验收场景

### AT-001: 正常启动（完整链路）

**Given** x.go 配置文件就绪，包含 kernel、configx、observex 及若干业务域模块的配置
**When** 执行 `x.go` 启动应用
**Then**
- configx 读取并校验配置成功
- observex 初始化 logger、meter、tracer
- kernel 按拓扑序依次 Init → Start 所有模块
- 所有模块 Health() 返回 Ready=true, Live=true
- 应用进入 Running 状态

**验证方法：** 集成测试，检查所有模块最终状态为 `StateRunning`

---

### AT-002: 配置加载 → 模块初始化

**Given** 配置文件包含各模块的配置项
**When** configx 加载配置，kernel 初始化模块
**Then**
- 每个模块通过 `Deps.Config` 读取到正确的配置值
- 配置校验失败的模块不启动，返回明确错误
- 缺失必填配置的模块返回 `ValidationError`
- 可选配置使用默认值

**验证方法：** 集成测试，mock 配置文件，验证模块收到的配置值

---

### AT-003: 模块启动失败回滚

**Given** 注册模块 A（无依赖）、B（依赖 A）、C（依赖 A）
**When** A.Start 成功，B.Start 失败
**Then**
- kernel 立即中断启动流程
- A.Stop 被调用（反序清理）
- C 不启动（fail-fast）
- 应用返回 `ErrStartupFailed`，包含 B 的错误信息
- observex 记录启动失败日志

**验证方法：** 集成测试，注入一个 Start 返回错误的 mock 模块

---

### AT-004: 优雅停机

**Given** 应用处于 Running 状态，所有模块正常运行
**When** 收到 SIGTERM 信号
**Then**
- kernel 按启动反序调用每个模块的 Stop
- 每个模块在 shutdown_timeout 内完成 Stop
- 超时模块被强制跳过，记录 `ErrShutdownTimeout`
- 所有模块最终状态为 `StateStopped`
- 应用进程退出码为 0

**验证方法：** 集成测试，发送 SIGTERM，检查模块停止顺序和最终状态

---

### AT-005: 健康检查全链路

**Given** 应用处于 Running 状态
**When** 调用 `ModuleHealth(name)` 查询每个模块
**Then**
- 每个模块返回 `HealthStatus{Ready: true, Live: true}`
- `Health()` 调用无副作用（幂等）
- 模块内部状态变化时，Health() 反映最新状态

**验证方法：** 集成测试，周期性调用 Health()，验证状态一致性

---

### AT-006: 弹性策略生效

**Given** resiliencx 配置了重试策略（max_retries=3）和超时策略（timeout=5s）
**When** 业务模块调用外部服务，首次失败后重试
**Then**
- 重试 3 次后成功 → 返回成功结果
- 重试 3 次后仍失败 → 返回错误，observex 记录重试日志
- 超时策略触发 → 操作在 5s 后中断，返回超时错误

**验证方法：** 集成测试，mock 外部服务，注入可控的失败模式

---

### AT-007: 横切模块贯穿

**Given** alertx 和 observex 已注册，业务域模块产生告警事件
**When** 业务模块触发告警条件
**Then**
- alertx 收到告警事件，发送通知
- observex 记录告警日志，包含 trace ID
- 告警不影响业务模块的正常运行
- 多个模块同时触发告警时不丢失事件

**验证方法：** 集成测试，注入告警触发条件，检查 alertx 和 observex 的输出

---

### AT-008: 配置热更新

**Given** 应用运行中，configx 支持配置热更新
**When** 配置文件变更
**Then**
- configx 检测到变更并重新加载
- 受影响的模块收到配置更新通知
- 不受影响的模块不重启
- 配置校验失败时保留旧配置，记录告警

**验证方法：** 集成测试，修改配置文件，验证模块行为变化

---

## 4. 测试环境要求

| 要求 | 说明 |
|------|------|
| 隔离性 | 测试不依赖真实外部服务（交易所、消息队列） |
| 可重复 | 每次运行结果一致，无随机失败 |
| 快速 | 完整验收套件 < 60s |
| 标记 | 使用 `//go:build acceptance` 构建标签 |

---

## 5. 验收标准

Foundation v1 整体验收通过的条件：

- [ ] AT-001 至 AT-004 全部通过（P0 场景）
- [ ] AT-005 至 AT-007 全部通过（P1 场景）
- [ ] AT-008 通过（P2 场景，可推迟）
- [ ] 所有场景无 data race（`-race` 通过）
- [ ] 验收测试覆盖率 ≥ 80%
