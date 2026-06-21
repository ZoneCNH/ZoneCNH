# Changelog

本目录遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 与语义化版本策略。

## [Unreleased]

### Added

- 补充 `module/contracts` 目录的 README 与 CHANGELOG，明确 consumer / producer / stable period 语义。

### Changed

- 与 `goal.md`、`FEATURES.md`、`ACCEPTANCE.md` 的发布基线同步。

## [v1.2.0] - 2026-06-21

### Added

- 当前 contracts 基线文档同步。
- 合约目录的发布说明、版本边界与稳定期约定。

### Breaking Changes

- 无。

## Breaking change policy

- 默认只接受向后兼容的增量变更。
- 删除字段、重命名接口、改变语义或修改默认行为都视为破坏性变更。
- 破坏性变更必须先完成版本升级、消费者迁移说明与验证回归，再进入发布。
