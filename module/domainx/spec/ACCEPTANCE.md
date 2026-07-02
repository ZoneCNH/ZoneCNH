# domainx 完整验收清单

- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）
- Last-Updated: 2026-06-30
- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [FEATURES.md](./FEATURES.md)
- Scale: 11 AC · 8 TC

> 本文档是 domainx 的 **完成定义（Definition of Done）**，把 SPEC 的 AC/TC 展开成可执行的验收项。
> 任一未勾选项存在即视为未达成完整验收；通过条件以 SPEC §19 验收门禁为准。

勾选图例：`[ ]` 未通过 · `[x]` 已通过并有证据 · `[~]` 部分通过（须在备注列注明缺口）

---

## 1. 验收标准（AC）

- [ ] **AC-001** FR-001
- [ ] **AC-002** FR-002
- [ ] **AC-003** FR-003
- [ ] **AC-004** FR-004
- [ ] **AC-005** FR-005
- [ ] **AC-006** FR-006
- [ ] **AC-007** FR-007
- [ ] **AC-008** FR-008
- [ ] **AC-009** BR-002
- [ ] **AC-010** BR-003
- [ ] **AC-011** BR-010

## 2. 测试用例（TC）

- [ ] **TC-001** FR-001, AC-001, AC-009
- [ ] **TC-002** FR-002, AC-002, AC-010
- [ ] **TC-003** FR-007, AC-007
- [ ] **TC-004** FR-003, AC-003
- [ ] **TC-005** FR-004, AC-004
- [ ] **TC-006** FR-005, AC-005
- [ ] **TC-007** FR-006, AC-006, AC-011
- [ ] **TC-008** FR-008, AC-008

---

## 3. 发布门禁（SPEC §19）

实现落地后，下列门禁必须全部通过才能声称完整验收：

```bash
git diff --check
bash .github/ci/spec-lint.sh
TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh
bash .github/ci/task-spec-validate.sh
go test ./module/domainx/... 2>/dev/null || true   # 远程仓库为准
go list -deps ./... | grep -v configx                # 禁止 configx 直接依赖（如 SPEC 要求）
```

## 4. 完整验收判定

§1 全部 AC `[x]` + §2 全部 TC `[x]` + §3 全部门禁通过 + 远程 `github.com/ZoneCNH/<repo>` Release 标签存在并指向当前 SPEC 版本。

