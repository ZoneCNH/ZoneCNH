# CodeQL Pass/Fail 诊断报告

**日期**: 2026-07-11  
**诊断者**: diagnoser (agent)  
**状态**: 根因已确定

## 问题摘要

xhyperium 组织下 23 个 Go 模块仓库配置了 CodeQL 扫描。其中 8 个通过，15 个失败。

## 通过/失败矩阵

### 通过的 8 个仓库

| 仓库 | codeql.yml SHA | init 版本 | analyze 版本 | 有 config 文件 |
|------|---------------|-----------|-------------|--------------|
| bootstrap | unique | v3.27.5 (f09c1c0a) | v3.27.5 (f09c1c0a) | 是 |
| decimalx | unique | v3.27.5 (f09c1c0a) | v3.27.5 (f09c1c0a) | 是 |
| domainx | unique | v3.27.5 (f09c1c0a) | v3.27.5 (f09c1c0a) | 是 |
| domain_market | unique | v3.27.5 (f09c1c0a) | v3.27.5 (f09c1c0a) | 是 |
| domain_exchange | unique | v3.27.5 (f09c1c0a) | v3.27.5 (f09c1c0a) | 是 |
| transportx | unique | v3.27.5 (f09c1c0a) | v3.27.5 (f09c1c0a) | 是 |
| xlib_harness | unique | v3.27.5 (f09c1c0a) | v3.27.5 (f09c1c0a) | 否 |
| xlib_evidence | unique | v3.27.5 (f09c1c0a) | v3.27.5 (f09c1c0a) | 否 |

### 失败的 15 个仓库

**组 A (14 仓库，共享相同 codeql.yml)** sha: `dc53803c62d99d5a43c77ad841870590d406abe9`:

kernel, configx, observex, resiliencx, schedulex, testkitx, redisx, natsx, postgresx, taosx, ossx, clickhousex, contracts

| 步骤 | Action | 版本/哈希 |
|------|--------|----------|
| init | codeql-action/init | v3.27.5 (f09c1c0a) |
| autobuild | codeql-action/autobuild | v3.27.5 (f09c1c0a) |
| **analyze** | **codeql-action/analyze** | **54f647b7 (releases/v4 ~v4.36.3)** |

配置: `queries: +security-and-quality`, 无 `build-mode`, 无 `.github/codeql/` 目录

**组 B (domain_macro) — 不同故障模式**:

| 步骤 | Action | 版本/哈希 |
|------|--------|----------|
| init | codeql-action/init | v3.27.5 (f09c1c0a) |
| analyze | codeql-action/analyze | v3.27.5 (f09c1c0a) |

配置: `build-mode: autobuild`, 有 `.github/codeql/codeql-config.yml`

**组 C (xlibgate) — 不同故障模式**:

| 步骤 | Action | 版本/哈希 |
|------|--------|----------|
| init | codeql-action/init | v3.27.5 (f09c1c0a) |
| analyze | codeql-action/analyze | v4.37.0 (99df26d) |

配置: `build-mode: autobuild`, `continue-on-error: true`, 无 config 文件

## 根因分析

### 组 A (14 仓库): init/analyze 版本不匹配

**错误**: `Loaded configuration file, but it does not contain the expected 'version' field.`

**根因**: CodeQL action 的 `init` 步骤使用 v3.27.5 (f09c1c0a)，但 `analyze` 步骤使用了 releases/v4 分支上的提交 (54f647b7，非标记版本，是主分支合并到 releases/v4 的内部提交)。

v3 init 在 runner 环境变量和临时文件中序列化配置状态。v4 analyze 尝试读取这些状态，但 v3 init 产生的状态格式缺少 v4 期望的 `version` 字段，导致分析步骤启动时解析失败。

**证据**:
- 错误发生在 `Perform CodeQL Analysis` 步骤（analyze action）
- `autobuild` 步骤成功完成: `CODEQL_ACTION_AUTOBUILD_DID_COMPLETE_SUCCESSFULLY: true`
- analyze 错误日志: `Loaded configuration file, but it does not contain the expected 'version' field.`
- `54f647b7` 提交日期为 2026-07-02，属于 `releases/v4` 分支，内容为 "Merge pull request #3984 — Merge main into releases/v4"，不是正式的 v3 标记版本

### 组 B (domain_macro): 权限错误

**错误**: `Resource not accessible by integration`

**根因**: domain_macro 的 codeql.yml 配置与通过仓库一致（init v3 + analyze v3），扫描本身成功完成（`CodeQL scanned 5 out of 6 Go files`）。失败发生在 SARIF 结果上传阶段，因为 GitHub App 集成缺乏写入 security-events 的权限。

### 组 C (xlibgate): 不同的版本不匹配 + continue-on-error

xlibgate 使用 init v3.27.5 + analyze v4.37.0，同样是跨大版本混用。但由于配置了 `continue-on-error: true`，工作流不会因错误终止（但仍标记为失败）。

## 为什么通过仓库没问题？

所有 8 个通过仓库的 `init` 和 `analyze` 步骤**使用相同版本的 action** (`f09c1c0a94de965c15400f5634aa42fac8fb8f88` = v3.27.5)，因此它们的配置序列化/反序列化格式完全一致。

`build-mode: autobuild` vs 独立 `autobuild` 步骤的区别、`queries` 配置、以及是否有 `.github/codeql/` 配置目录**均与控制因素无关** — 决定性因素仅为 `init` 和 `analyze` 的版本是否一致。

## 修复方案

### 组 A (14 仓库): 对齐 analyze 哈希

将 14 个仓库的 `analyze` 步骤哈希从 `54f647b7e1bb85c95cddabcd46b0c578ec92bc1a` 改为 `f09c1c0a94de965c15400f5634aa42fac8fb8f88`（与 init 相同的 v3.27.5）。

需要将 analyze 步骤从：
```yaml
uses: github/codeql-action/analyze@54f647b7e1bb85c95cddabcd46b0c578ec92bc1a
```
修改为：
```yaml
uses: github/codeql-action/analyze@f09c1c0a94de965c15400f5634aa42fac8fb8f88
```

**影响范围**: 14 个仓库共享相同的 codeql.yml (sha: dc53803c)，因此一个 PR 模板即可覆盖全部 14 个仓库。

### 组 B (domain_macro): 修复 token 权限

确保 domain_macro 的 `GITHUB_TOKEN` 或 GitHub App 拥有写入 security-events 的权限。

### 组 C (xlibgate): 对齐 analyze 哈希

将 xlibgate 的 analyze 步骤从 v4.37.0 改回 v3.27.5，或同时将 init 升级至 v4。

## 结论

**主要问题**: 14 个仓库共享的 codeql.yml 模板中，`analyze` action 版本错误地使用了 v4 分支上的内部合并提交 (54f647b7)，与 `init` action 的 v3.27.5 不兼容。修复只需将 analyze 的哈希对齐为与 init 相同的版本即可。

**次要问题**: domain_macro（权限不足）和 xlibgate（不同版本混用场景）需要单独处理。
