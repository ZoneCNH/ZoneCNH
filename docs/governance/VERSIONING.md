# 版本管理规范

> 本文件定义 FoundationX 文档体系的版本管理、发布流程和变更记录规范。

## 1. 版本号规则

遵循 [Semantic Versioning](https://semver.org/)：

```
v<MAJOR>.<MINOR>.<PATCH>
```

| 类型   | 触发条件                                     | 示例                         |
| ------ | -------------------------------------------- | ---------------------------- |
| MAJOR  | 宪法条款新增/删除/重写、架构重组、破坏性变更 | §0 全面重写 → v2.0.0         |
| MINOR  | 新增模块规格、Agent、治理文档、重要补充      | 新增 goal-architect → v1.1.0 |
| PATCH  | 措辞修正、格式调整、typo、非实质变更         | §0.2 措辞简化 → v1.0.1       |

### 1.1 版本号分配原则

- 一次发布只打一个版本号
- 版本号递增，不可回退
- 预发布版本使用 `-rc.N` 后缀（如 `v1.1.0-rc.1`）
- Goal 体系内部版本由 `.config/goal/registry/releases.yaml` 管理，与全局版本独立

### 1.2 版本号决策矩阵

| 变更涉及                    | 版本类型                 |
| --------------------------- | ------------------------ |
| CONSTITUTION.md 任何条款    | MINOR 起步，重写为 MAJOR |
| docs/governance/ 新增文件   | MINOR                    |
| docs/governance/ 内容修改   | PATCH                    |
| module/*/spec/SPEC.md 新增       | MINOR                    |
| module/*/spec/SPEC.md 修改       | PATCH                    |
| .claude/agents/ 新增        | MINOR                    |
| .claude/agents/ 修改        | PATCH                    |
| README.md / ARCHITECTURE.md | PATCH                    |
| CLAUDE.md / AGENTS.md       | PATCH                    |

## 2. 变更记录

### 2.1 CHANGELOG.md

全局变更日志位于仓库根目录 `CHANGELOG.md`，是版本变更的唯一权威来源。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)：

```markdown
## [Unreleased]
### Changed
### Added
### Removed

## [vX.Y.Z] - YYYY-MM-DD
### Changed
### Added
### Removed
### Fixed
```

### 2.2 变更分类

| 类别       | 含义                        |
| ---------- | --------------------------- |
| Added      | 新增功能、文档、Agent、规格 |
| Changed    | 修改现有内容                |
| Deprecated | 即将移除的内容              |
| Removed    | 已移除的内容                |
| Fixed      | 修复错误、typo、格式        |
| Security   | 安全相关变更                |

### 2.3 CONSTITUTION.md §12.3

宪法修正记录保留在 §12.3 表格中，与 CHANGELOG.md 互补：

- CHANGELOG.md 记录所有版本的全部变更
- §12.3 仅记录宪法条款本身的修正

两者不重复，§12.3 是宪法内部的审计追踪。

## 3. 发布流程

### 3.1 标准发布

```bash
# 1. 确保 main 分支干净
git checkout main && git pull

# 2. 更新 CHANGELOG.md [Unreleased] → [vX.Y.Z]
#    在 feature branch 中完成
git checkout -b docs/release-vX.Y.Z
# 编辑 CHANGELOG.md
git add CHANGELOG.md && git commit -m "docs: 更新 CHANGELOG.md — vX.Y.Z"
git checkout main && git merge --no-ff docs/release-vX.Y.Z

# 3. 打 tag
git tag -a vX.Y.Z -m "Release vX.Y.Z: <简要描述>"

# 4. 推送
git push origin main --tags

# 5. 清理
git branch -d docs/release-vX.Y.Z
```

### 3.2 紧急发布

```bash
# 1. 从 main 创建 hotfix branch
git checkout -b hotfix/vX.Y.Z

# 2. 修复 + 更新 CHANGELOG.md
git add . && git commit -m "fix: <描述>"

# 3. 合并 + tag + 推送
git checkout main && git merge --no-ff hotfix/vX.Y.Z
git tag -a vX.Y.Z -m "Hotfix vX.Y.Z: <描述>"
git push origin main --tags
git branch -d hotfix/vX.Y.Z
```

## 4. Tag 规范

### 4.1 Tag 命名

```
v<MAJOR>.<MINOR>.<PATCH>[-<prerelease>]
```

示例：`v1.0.0`, `v1.1.0-rc.1`, `v2.0.0`

### 4.2 Tag 消息

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z

变更摘要：
- <变更 1>
- <变更 2>
"
```

## 5. 与其他系统的关联

| 系统                                | 关联方式              |
| ----------------------------------- | --------------------- |
| Git tags                            | 全局版本锚点          |
| CHANGELOG.md                        | 全局变更日志          |
| .config/goal/registry/releases.yaml | Goal 体系内部发布记录 |
| CONSTITUTION.md §12.3               | 宪法修正审计追踪      |
| GitHub Releases                     | 基于 git tag 自动生成 |

### 5.1 Goal 体系版本

Goal 体系有独立版本管理：

- 发布记录在 `.config/goal/registry/releases.yaml`
- 使用 `release_version` 字段（如 `v1.0.0`）
- 与全局 CHANGELOG.md 交叉引用，但版本号独立递增

## 6. 回溯与对比

```bash
# 查看两个版本之间的差异
git diff v0.4.1..v1.0.0 --stat

# 查看某个版本的完整内容
git show v1.0.0

# 回溯到某个版本
git checkout v1.0.0 -- <file>

# 列出所有版本
git tag -l --sort=-v:refname
```
