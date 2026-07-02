# Context Packet — xlib_evidence 全量任务

> 模块: xlib_evidence
> 版本: v0.2.4
> 工作目录: /home/workspace/xlib_evidence
> Spec: module/xlib_evidence/spec/SPEC.md v1.2.1

## 模块定位

xlib_evidence 是 Foundation 的证据收集与发布运行时——收集各模块的覆盖率、门禁结果、发布 manifest，生成统一证据报告，支持远程证据验证。

## 功能需求摘要

| FR | 描述 | 状态 |
|----|------|------|
| FR-001 | collect-coverage: 收集模块覆盖率与门禁结果 | ✅ PASS |
| FR-002 | generate-manifest: 生成 Release Manifest | ✅ PASS |
| FR-003 | validate-manifest: 验证 manifest 完整性/签名/内容 | ✅ PASS |
| FR-004 | remote-evidence: 远程证据查询 | ✅ PASS |
| FR-005 | report: 跨模块统一证据报告 | ✅ PASS |

## 边界规则

| BR | 规则 | 状态 |
|----|------|------|
| BR-001 | manifest 必须包含门禁全绿证据 | ✅ |
| BR-002 | 覆盖率低于 100.0% 不得发布 | ✅ |
| BR-003 | manifest 不可事后篡改（hash 链校验） | ✅ |
| BR-004 | evidence 存储必须不可变追加 | ✅ |

## 验收证据

- go test ./...: PASS
- go test -race -count=1: PASS
- go vet: PASS
- Coverage: 100.0%
- manifest 生成→验证 golden 测试: PASS
- manifest 篡改检测: PASS

## 架构约束

- 禁止依赖存储/网络后端（NFR-005）
- manifest hash 完整性校验（NFR-003）
- 不读取密钥/不连接远程服务（NFR-004）
