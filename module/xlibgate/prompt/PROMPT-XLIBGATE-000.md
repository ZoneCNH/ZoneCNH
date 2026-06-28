# Context Packet — xlibgate 全量任务

> 模块: xlibgate
> 版本: v1.0.0
> 工作目录: /home/xlibgate
> Spec: module/xlibgate/spec/SPEC.md v1.2.0

## 模块定位

xlibgate 是 Foundation 的机器可执行门禁 CLI 工具，提供三组子命令：check（import/gomod/baseline/release/all）、l2（validate-manifest/plan/check-contracts/check-evidence/release-check）、trust（identity/template-residue/release-consistency/maturity/import-boundary/testkit-prod-import/secret-redaction/fleet-status/all）。

## 功能需求摘要

| FR | 描述 | 状态 |
|----|------|------|
| FR-001 | check imports: 扫描 import 边界违规 | ✅ |
| FR-002 | check gomod: go mod tidy 整洁度 | ✅ |
| FR-003 | check baseline: Go toolchain 版本一致性 | ✅ |
| FR-004 | check release: release evidence 校验 | ✅ |
| FR-005 | check all: 串联所有子检查 | ✅ |
| FR-006 | 输出格式: JSON + human-readable | ✅ |
| FR-007 | l2 validate-manifest | ✅ |
| FR-008 | l2 plan | ✅ |
| FR-009 | l2 check-contracts | ✅ |
| FR-010 | l2 check-evidence | ✅ |
| FR-011 | l2 release-check | ✅ |
| FR-012 | trust identity: 五源身份比对 | ✅ |
| FR-013 | trust template-residue: 模板残留扫描 | ✅ |
| FR-014 | trust release-consistency: 七源版本一致性 | ✅ |
| FR-015 | trust maturity --factory: 11 维工厂级成熟度 | ✅ |
| FR-016 | trust import-boundary: import 边界检查 | ✅ |
| FR-017 | trust testkit-prod-import: testkitx 生产隔离 | ✅ |
| FR-018 | trust secret-redaction: 密钥脱敏扫描 | ✅ |
| FR-019 | trust fleet-status: 20 模块舰队状态聚合 | ✅ |

## 架构约束

- 零运行时依赖：仅依赖 stdlib + yaml.v3 + Go AST + gitleaks
- exit code 标准化：0=pass, 1=fail, 2=error
- FOUNDATION-DEPS.yaml 消费：不硬编码依赖规则
- 不被任何模块 import（纯 CLI 工具）

## 验收证据

- git tag v1.0.0: 存在
- internal/trust/ 全部测试 PASS（2622 行代码，19 个测试文件）
- check all 自检: PASS
- go list -deps: 零 Foundation 运行时依赖
