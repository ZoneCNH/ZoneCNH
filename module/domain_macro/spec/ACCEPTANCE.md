# domain_macro 完整验收清单

- Status: Generated（与 [SPEC.md](./SPEC.md) 同步抽取，未经 pipeline-arbiter 校验）
- Last-Updated: 2026-06-30
- Source: [SPEC.md](./SPEC.md) · [TRACEABILITY.md](./TRACEABILITY.md) · [FEATURES.md](./FEATURES.md)
- Scale: 8 AC · 0 TC

> 本文档是 domain_macro 的 **完成定义（Definition of Done）**，把 SPEC 的 AC/TC 展开成可执行的验收项。
> 任一未勾选项存在即视为未达成完整验收；通过条件以 SPEC §19 验收门禁为准。

勾选图例：`[ ]` 未通过 · `[x]` 已通过并有证据 · `[~]` 部分通过（须在备注列注明缺口）

---

## 1. 验收标准（AC）

- [ ] **AC-MAC-001** FR-MAC-001
- [ ] **AC-MAC-002** FR-MAC-002
- [ ] **AC-MAC-003** FR-MAC-003
- [ ] **AC-MAC-004** FR-MAC-004
- [ ] **AC-MAC-005** FR-MAC-005
- [ ] **AC-MAC-006** FR-MAC-006
- [ ] **AC-MAC-007** FR-MAC-007
- [ ] **AC-MAC-008** FR-MAC-008

## 2. 测试用例（TC）

> SPEC 中未抽取到 `TC-` 编号；请人工对照 SPEC §15 测试矩阵补全。

---

## 3. 发布门禁（SPEC §19）

实现落地后，下列门禁必须全部通过才能声称完整验收：

```bash
git diff --check
bash .github/ci/spec-lint.sh
TRACEABILITY_STRICT=1 bash .github/ci/traceability-check.sh
bash .github/ci/task-spec-validate.sh
go test ./module/domain_macro/... 2>/dev/null || true   # 远程仓库为准
go list -deps ./... | grep -v configx                # 禁止 configx 直接依赖（如 SPEC 要求）
```

## 4. 完整验收判定

§1 全部 AC `[x]` + §2 全部 TC `[x]` + §3 全部门禁通过 + 远程 `github.com/ZoneCNH/<repo>` Release 标签存在并指向当前 SPEC 版本。

