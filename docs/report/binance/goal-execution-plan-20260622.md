# Goal：binance 从规格参考推进到可发布 C/S 参考路径

- [COMPUTED, HIGH] 日期：2026-06-22
- [COMPUTED, HIGH] 对账日期：2026-06-23
- [COMPUTED, HIGH] 来源：`docs/report/binance/iteration-plan-20260622.md`、`docs/report/binance/deep-analysis-20260622-v2.md`、`docs/report/binance/deep-analysis-20260622-v3.md`、`docs/report/binance/deep-analysis-20260622-v4.md`、`docs/report/binance/business-types-coverage-20260622.md`、issues #866~#873 / #893~#896。

---

## 目标

[INFERRED, HIGH] 到 2026-09-30，将 `module/binance` 从部分治理完备的规格参考推进为可发布的 Binance C/S 参考实现路径。

[INFERRED, HIGH] 目标评分：

```text
当前治理评分: 82/100
目标治理评分: 95+/100
```

[COMPUTED, HIGH] 评分目标不等同于发布声明；Release readiness 仍需要本地证据、远端 CI 证据、live smoke/deploy 证据，以及 release tag 或等价的 owner-approved snapshot。

---

## 验收标准

| AC | 目标 | 2026-06-23 状态 | 证据 |
|---|---|---|---|
| AC-1 | 关闭治理漂移 #866/#867/#868/#872/#873 | PASS(local) | `scripts/check-binance-docs.sh` 通过；root version、4x4 natsx/Kafka matrix、task 文件名和 runtime 分层口径已对齐。 |
| AC-2 | 增加可执行文档一致性脚本 #870 | PASS(local) | `scripts/check-binance-docs.sh`；CI draft 位于 `module/binance/ci-workflow.yaml`。 |
| AC-3 | 增加 FR-012~FR-024 生命周期讨论稿 | PASS(local) | `module/binance/DATA-LIFECYCLE.md`；`scripts/check-binance-data-lifecycle.sh` 覆盖 13 个 FR anchor。 |
| AC-4 | 定义 FR-012~FR-015 runtime control plane | NOT COMPLETE | discussion draft 已存在；实现与 spec fold 仍属后续工作。 |
| AC-5 | 定义 FR-016~FR-019 historical lifecycle | NOT COMPLETE | discussion draft 已存在；实现与 spec fold 仍属后续工作。 |
| AC-6 | 定义 funding_rate / mark_price / reconciliation / rehydration | PARTIAL LOCAL CLOSED | FR-020 funding_rate/mark_price 已折叠进 SPEC v3.0.0 4 × 6；reconciliation / rehydration 仍保留在 DATA-LIFECYCLE discussion draft。 |
| AC-7 | 定义 FR-023~FR-024 governance APIs | NOT COMPLETE | discussion draft 已存在；dynamic hot reload 未声明完成。 |
| AC-8 | 刷新 #869 本地 runtime 证据 | PASS(local command set) | 2026-06-23 从 `/home/binance` 重新取得 clean short status、boundary gates PASS 10/10、`go test ./...`、`go vet ./...`、race test、`golangci-lint run` 通过证据；release/live smoke 仍由 owner gate。 |
| AC-9 | 满足 Release DoD | NOT COMPLETE | remote CI、live smoke/deploy、authoritative PR/head lineage 和 release tag 证据不在本地审计闭包内。 |

---

## Issue 执行状态

| Issue | 执行状态 | 关闭边界 |
|---|---|---|
| #866 | CLOSED(local) | NATS 4x4 matrix 已进入文档与脚本检查。 |
| #867 | CLOSED(local) | root README version 与 SPEC 对齐。 |
| #868 | CLOSED(local) | Kafka topics 使用 `binance.{product_line}.{event_type}.v1`；checked docs 不再保留 aggregate legacy topics。 |
| #869 | LOCAL-EVIDENCE CLOSED | `/home/binance` clean short status、boundary gate、`go test ./...`、`go vet ./...`、race test、lint 已通过；release/live smoke 仍由 owner gate。 |
| #870 | CLOSED(local) | `scripts/check-binance-docs.sh` 可执行且通过。 |
| #871 | CLOSED(local) | `module/binance/STANDARD.md` 已存在，并通过 `RULES.md` R9 连接。 |
| #872 | CLOSED(local) | runtime status wording 保持 docs readiness 与 runtime evidence 分层。 |
| #873 | CLOSED(local) | RULES task filenames 可解析到现有 docs。 |
| #893 | CLOSED(local) | SPEC §4 链接 distributed constraints 与 analysis sources。 |
| #894 | CLOSED(local) | migration anchor 已存在于 `docs/migrations/binance-v2-upgrade.md` 与 migration index。 |
| #895 | CLOSED(local) | README、goal、SPEC overview prose 改为指向 BR-001 / Appendix B，不再重复 legacy module detail。 |
| #896 | PARTIAL(local audit) | local newest-50 coverage audit 已存在；仍需要 authoritative GitHub PR/head lineage。 |

---

## 阶段路线

| 阶段 | 范围 | 2026-06-23 状态 |
|---|---|---|
| 0 | governance drift #866/#867/#868/#872/#873 | PASS(local) |
| 1 | script and report index #870 | PASS(local) |
| 2 | DATA-LIFECYCLE discussion draft | PASS(local) |
| 3 | realtime control FR-012~FR-015 | FUTURE |
| 4 | historical lifecycle FR-016~FR-019 | FUTURE |
| 5 | periodic data and reconciliation FR-020~FR-022 | FUTURE |
| 6 | governance observability and doc cleanup #871/#893/#894/#895/#896 | PASS(local)，但 #896 external lineage 除外 |
| 7 | runtime evidence #869 | PASS(local runtime evidence)；release evidence 仍为外部门禁 |

---

## 验证命令

[COMPUTED, HIGH] 本仓库文档验证命令：

```bash
bash -n scripts/check-binance-docs.sh
bash scripts/check-binance-docs.sh
bash -n scripts/check-binance-data-lifecycle.sh
bash scripts/check-binance-data-lifecycle.sh
node scripts/check.mjs
git diff --check
```

[COMPUTED, HIGH] `/home/binance` runtime 验证命令：

```bash
./scripts/boundary-gates.sh
go test ./...
go vet ./...
go test ./... -race -count=1
golangci-lint run
```

---

## 剩余门禁

1. [COMPUTED, HIGH] #869 local runtime evidence is closed by fresh `/home/binance` command output; release/live smoke evidence remains an external owner gate.
2. [COMPUTED, HIGH] #896 cannot be fully closed from local git evidence alone; it needs authoritative GitHub PR/head metadata or an equivalent owner-approved mapping.
3. [COMPUTED, HIGH] Release DoD is not complete without remote CI, live smoke/deploy evidence, and a release tag or owner-approved release snapshot.
4. [INFERRED, MED] FR-012~FR-024 should stay in discussion/spec-fold state until the owner approves the implementation sequence and version bump plan.

[RULES I BROKE]：无
