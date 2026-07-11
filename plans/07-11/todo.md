# plans/07-11/ 未完成任务清单

> 审计日期: 2026-07-11 | 版本: v2
> 审计源: README.md §2.0.4 Remaining Work Summary + §四 P0 tracker + §P1 roadmap + audit/identity/codeql reports
> 对齐状态: README.md execution tracker §2.0.4 已同步

---

## 一、P0 未完成 (3/10 → DOCUMENTED only)

| #    | Item                             | Current    | Needs                                                                    | Phase         |
| ---- | -------------------------------- | ---------- | ------------------------------------------------------------------------ | ------------- |
| P0-4 | bare-metal fault/soak controller | DOCUMENTED | Go 代码实现 (ebpf/netns/systemd package in xlib_standard/fixture/fault/) | Phase 2       |
| P0-6 | xlib_standard MVC freeze         | DOCUMENTED | 实际 CLI/API 冻结 tooling (check-mvc-freeze.sh 执行, lockfile 生成)      | Phase 1 Day 5 |
| P0-9 | W4 light/heavy pool              | DOCUMENTED | storage-pools.yaml 已在 CI runner 端部署 + xlibgate schema 验证集成      | Phase 2 前    |

**Root cause**: 3 items have implementation plans written but no running code.

---

## 二、P0 内部不一致 — FIXED ✓

| Location                      | Issue                             | Status  |
| ----------------------------- | --------------------------------- | ------- |
| README.md §4 §P0-6 detail     | 状态字段显示 PENDING → DOCUMENTED | ✓ FIXED |
| README.md §2.0.4 Phase 0 exit | `[-]` checkbox → `[x]`            | ✓ FIXED |
| README.md §2.0.4 Phase 0 exit | checkbox format 统一              | ✓ FIXED |

---

## 三、Phase 0 退出条件 — FIXED ✓

7 条退出条件全部 `[x]`, 新增第 8 条 GO/JV 补充工作包 (`[-] 4/6 remaining`). xref remaining 指标已汇总到 `Remaining Work Summary` 表 (§2.0.4) 和执行追踪区块.

---

## 四、GO/JV 工作包缺口 (2/6 resolved, 4 remaining)

READEME.md §3.3:

| ID                     | Description                  | Status                                 |
| ---------------------- | ---------------------------- | -------------------------------------- |
| GO-ROLLBACK-001        | 全局回滚策略定义             | ✓ FIXED (RESOLVED by P0-10 §10.1-10.3) |
| GO-BASE-002            | BASE 推广 Runbook            | ✓ FIXED (RESOLVED by P0-10 §10.1-10.3) |
| GO-PEOPLE-003          | 人员分工与并行窗口定义       | PENDING                                |
| GO-DASH-004            | Fleet Status Dashboard       | PENDING                                |
| JV-CONFIGX-INTEGRATION | configx + bootstrap 联合验证 | PENDING                                |
| JV-RESILIENCX-KERNEL   | resiliencx + kernel 边界验证 | PENDING                                |

---

## 五、observex BASE-003 push — FIXED ✓

observex 仓库: PR #32 created and merged. SECURITY.md, CONTRIBUTING.md, CODEOWNERS now on main.

---

## 六、CodeQL 状态 (1/25 remaining)

| Module          | Status  | Fix                                                 |
| --------------- | ------- | --------------------------------------------------- |
| domain_exchange | ✓ FIXED | PR #2 merged: manual build with GONOSUMCHECK bypass |
| domain_macro    | running | CodeQL triggered (run #29152670846)                 |
| xlib_standard   | ✓ FIXED | PR #162 merged: fix/xls003-standard-bundle → main   |

---

## 七、P1-2/3/4 未开始 (~50 items)

| Phase     | Module                                                   | Count                                 | Status      |
| --------- | -------------------------------------------------------- | ------------------------------------- | ----------- |
| P1-2      | kernel                                                   | 3 items (Go/CI/100%)                  | NOT_STARTED |
| P1-3      | configx, observex, schedulex, testkitx                   | 6 items                               | NOT_STARTED |
| P1-4      | 11 exchange adapter consumers                            | 2 items (import fix, consumer canary) | NOT_STARTED |
| 未覆盖 P1 | ~38 items (resiliencx 6策略, bootstrap, storage, domain) | ~38                                   | NOT_STARTED |

---

## 八、Migration 分支未清理

| Branch                        | Modules           | Status                           |
| ----------------------------- | ----------------- | -------------------------------- |
| fix/snake-case-migration      | 6                 | merged, branch deleted           |
| fix/xhyperium-org-migration   | 25                | merged, some branches deleted    |
| fix/enable-codeql             | 24                | merged                           |
| fix/enable-codeql-2           | 14                | merged                           |
| fix/codeql-v4                 | 24                | merged                           |
| fix/base-003-governance-files | 11                | ✓ FIXED (所有模块 PR merged)     |
| fix/xls003-standard-bundle    | 1 (xlib_standard) | ✓ FIXED (PR #162 merged to main) |

---

## 九、README.md 一致性差距

| Location                | Issue                                          | Status                      |
| ----------------------- | ---------------------------------------------- | --------------------------- |
| §2.0.4 退出条件         | checkbox unchecked + 格式不一致                | ✓ FIXED                     |
| §4 §P0-6 detail         | Status PENDING vs 总表 DOCUMENTED              | ✓ FIXED                     |
| §3.3 GO/JV 工作包       | GO-ROLLBACK-001/GO-BASE-002 should be RESOLVED | ✓ FIXED (README.md updated) |
| §0.3 关键数字           | P0 工作包 48 → 实际有更新                      | ⬜ minor                    |
| §9.1 Release Tuple 矩阵 | 空表 — 需填写 25 模块完成度                    | ⬜ deferred                 |
| §9.2 BASE 工作包矩阵    | 空表 — 需填 BASE-001~009 × 25 模块             | ⬜ deferred                 |

---

## 十、优先级排序 (updated)

| Priority | Item                                               | Effort | Impact                    |
| -------- | -------------------------------------------------- | ------ | ------------------------- |
| **P0**   | P0-6 MVC freeze implementation                     | Medium | Unblock Phase 1 canary    |
| **Done** | Merge xls003-standard-bundle to main               | Low    | ✓ FIXED (PR #162)         |
| **Done** | Fix observex BASE-003 push                         | Low    | ✓ FIXED (PR #32)          |
| **Done** | Update §3.3 GO-ROLLBACK-001/GO-BASE-002 → RESOLVED | Low    | ✓ FIXED                   |
| **Done** | domain_exchange GONOSUMCHECK bypass                | Low    | ✓ FIXED (PR #2)           |
| **P1**   | P1-2 kernel CI/验证 (3 items)                      | Medium | L0 canary qualification   |
| **P2**   | GO/JV 4 remaining work packages                    | Medium | Joint verification matrix |
| **P2**   | ~38 P1 items (resiliencx ~ domains)                | Large  | Phase 2-4 execution       |
