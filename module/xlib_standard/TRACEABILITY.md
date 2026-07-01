# xlib_standard 追溯矩阵

- Matrix-Version: v0.1.0
- Last-Updated: 2026-06-30
- Source-SPEC: `module/xlib_standard/spec/SPEC.md` v1.1.0
- Source-Analysis: `module/xlib_standard/ANALYSIS.md` v3.2.0
- Source-FR-DETAIL: `module/xlib_standard/FR-DETAIL.md`
- State-Model: archived-snapshot only（xlib_standard 是标准参考/模板模块，非可执行模块）
- FR total: 52（49 line + 1 directory + 2 validator-output；行级覆盖 49/52）
- Current-State: 0 Done / 0 Partial / 0 Drifted / 52 archived-snapshot

> 本矩阵是 `ANALYSIS.md` 条款到来源文件的追溯表（章节级 + 来源级，非 rule 级）。FR 来源锚定 52/52；其中行级 49、directory 1、validator-output 2，不等于语义验证完整。xlib_standard 为标准参考/模板模块，所有 FR 标记为 archived-snapshot。

> 需要内容级复现时必须提供 source pack、digest/tree sha 或重新生成覆盖清单。matrix/ 子目录保留旧的快照索引作为归档工件，不随当前分析更新。

## 1. FR Matrix

| FR | 主题 | 证据锚点 | 证据类型 | AC | TC | 状态 |
|----|------|----------|----------|----|----|------|
| `FR-001` | Config 标准快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-001 | xlib-TC-001 | archived-snapshot |
| `FR-002` | Error 标准快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-002 | xlib-TC-002 | archived-snapshot |
| `FR-003` | Health 标准快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-003 | xlib-TC-003 | archived-snapshot |
| `FR-004` | Metrics 标准快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-004 | xlib-TC-004 | archived-snapshot |
| `FR-005` | Client 标准快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-005 | xlib-TC-005 | archived-snapshot |
| `FR-006` | Version 标准快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-006 | xlib-TC-006 | archived-snapshot |
| `FR-007` | 公共 API 模板快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-007 | xlib-TC-007 | archived-snapshot |
| `FR-008` | 模板可编译快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-008 | xlib-TC-008 | archived-snapshot |
| `FR-009` | render_template.sh 渲染快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-009 | xlib-TC-009 | archived-snapshot |
| `FR-010` | 生成库无模板残留快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-010 | xlib-TC-010 | archived-snapshot |
| `FR-011` | CI gate快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-011 | xlib-TC-011 | archived-snapshot |
| `FR-012` | boundary gate快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-012 | xlib-TC-012 | archived-snapshot |
| `FR-013` | release manifest快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-013 | xlib-TC-013 | archived-snapshot |
| `FR-014` | release final check快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-014 | xlib-TC-014 | archived-snapshot |
| `FR-015` | Evidence Runtime CLI快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-015 | xlib-TC-015 | archived-snapshot |
| `FR-016` | L2 下游仓库模板快照锚点 | `module/xlib_standard/spec/SPEC.md` | line | AC-016 | xlib-TC-016 | archived-snapshot |
| `FR-017` | 上游标准快照契约 17快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-017 | xlib-TC-017 | archived-snapshot |
| `FR-018` | 上游标准快照契约 18快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-018 | xlib-TC-018 | archived-snapshot |
| `FR-019` | 上游标准快照契约 19快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-019 | xlib-TC-019 | archived-snapshot |
| `FR-020` | 上游标准快照契约 20快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-020 | xlib-TC-020 | archived-snapshot |
| `FR-021` | 上游标准快照契约 21快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-021 | xlib-TC-021 | archived-snapshot |
| `FR-022` | 上游标准快照契约 22快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-022 | xlib-TC-022 | archived-snapshot |
| `FR-023` | 上游标准快照契约 23快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-023 | xlib-TC-023 | archived-snapshot |
| `FR-024` | 上游标准快照契约 24快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-024 | xlib-TC-024 | archived-snapshot |
| `FR-025` | 上游标准快照契约 25快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-025 | xlib-TC-025 | archived-snapshot |
| `FR-026` | 上游标准快照契约 26快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-026 | xlib-TC-026 | archived-snapshot |
| `FR-027` | 上游标准快照契约 27快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-027 | xlib-TC-027 | archived-snapshot |
| `FR-028` | 上游标准快照契约 28快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-028 | xlib-TC-028 | archived-snapshot |
| `FR-029` | 上游标准快照契约 29快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-029 | xlib-TC-029 | archived-snapshot |
| `FR-030` | 上游标准快照契约 30快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-030 | xlib-TC-030 | archived-snapshot |
| `FR-031` | 上游标准快照契约 31快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-031 | xlib-TC-031 | archived-snapshot |
| `FR-032` | 上游标准快照契约 32快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-032 | xlib-TC-032 | archived-snapshot |
| `FR-033` | 上游标准快照契约 33快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-033 | xlib-TC-033 | archived-snapshot |
| `FR-034` | 上游标准快照契约 34快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-034 | xlib-TC-034 | archived-snapshot |
| `FR-035` | 上游标准快照契约 35快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-035 | xlib-TC-035 | archived-snapshot |
| `FR-036` | 上游标准快照契约 36快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-036 | xlib-TC-036 | archived-snapshot |
| `FR-037` | 上游标准快照契约 37快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-037 | xlib-TC-037 | archived-snapshot |
| `FR-038` | 上游标准快照契约 38快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-038 | xlib-TC-038 | archived-snapshot |
| `FR-039` | 上游标准快照契约 39快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-039 | xlib-TC-039 | archived-snapshot |
| `FR-040` | 上游标准快照契约 40快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-040 | xlib-TC-040 | archived-snapshot |
| `FR-041` | 上游标准快照契约 41快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-041 | xlib-TC-041 | archived-snapshot |
| `FR-042` | 上游标准快照契约 42快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-042 | xlib-TC-042 | archived-snapshot |
| `FR-043` | 上游标准快照契约 43快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-043 | xlib-TC-043 | archived-snapshot |
| `FR-044` | 上游标准快照契约 44快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-044 | xlib-TC-044 | archived-snapshot |
| `FR-045` | 上游标准快照契约 45快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-045 | xlib-TC-045 | archived-snapshot |
| `FR-046` | 上游标准快照契约 46快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-046 | xlib-TC-046 | archived-snapshot |
| `FR-047` | 上游标准快照契约 47快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-047 | xlib-TC-047 | archived-snapshot |
| `FR-048` | 上游标准快照契约 48快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-048 | xlib-TC-048 | archived-snapshot |
| `FR-049` | 上游标准快照契约 49快照锚点 | `module/xlib_standard/ANALYSIS.md` | line | AC-049 | xlib-TC-049 | archived-snapshot |
| `FR-050` | 上游标准快照契约 50快照锚点 | `docs/standard/` | directory | AC-050 | xlib-TC-050 | archived-snapshot |
| `FR-051` | 上游标准快照契约 51快照锚点 | goalcli evidence CLI | validator-output | AC-051 | xlib-TC-051 | archived-snapshot |
| `FR-052` | 上游标准快照契约 52快照锚点 | release manifest checksum | validator-output | AC-052 | xlib-TC-052 | archived-snapshot |

## 2. Acceptance Criteria

| AC | Requirement | State |
|----|-------------|-------|
| AC-001 | Config 标准快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-002 | Error 标准快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-003 | Health 标准快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-004 | Metrics 标准快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-005 | Client 标准快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-006 | Version 标准快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-007 | 公共 API 模板快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-008 | 模板可编译快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-009 | render_template.sh 渲染快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-010 | 生成库无模板残留快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-011 | CI gate快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-012 | boundary gate快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-013 | release manifest快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-014 | release final check快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-015 | Evidence Runtime CLI快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-016 | L2 下游仓库模板快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-017 | 上游标准快照契约 17快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-018 | 上游标准快照契约 18快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-019 | 上游标准快照契约 19快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-020 | 上游标准快照契约 20快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-021 | 上游标准快照契约 21快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-022 | 上游标准快照契约 22快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-023 | 上游标准快照契约 23快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-024 | 上游标准快照契约 24快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-025 | 上游标准快照契约 25快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-026 | 上游标准快照契约 26快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-027 | 上游标准快照契约 27快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-028 | 上游标准快照契约 28快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-029 | 上游标准快照契约 29快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-030 | 上游标准快照契约 30快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-031 | 上游标准快照契约 31快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-032 | 上游标准快照契约 32快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-033 | 上游标准快照契约 33快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-034 | 上游标准快照契约 34快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-035 | 上游标准快照契约 35快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-036 | 上游标准快照契约 36快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-037 | 上游标准快照契约 37快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-038 | 上游标准快照契约 38快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-039 | 上游标准快照契约 39快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-040 | 上游标准快照契约 40快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-041 | 上游标准快照契约 41快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-042 | 上游标准快照契约 42快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-043 | 上游标准快照契约 43快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-044 | 上游标准快照契约 44快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-045 | 上游标准快照契约 45快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-046 | 上游标准快照契约 46快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-047 | 上游标准快照契约 47快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-048 | 上游标准快照契约 48快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-049 | 上游标准快照契约 49快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-050 | 上游标准快照契约 50快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-051 | 上游标准快照契约 51快照锚点 通过来源定位可复现 | archived-snapshot |
| AC-052 | 上游标准快照契约 52快照锚点 通过来源定位可复现 | archived-snapshot |

## 3. Summary

| Metric | Value |
|--------|-------|
| FR total | 52 |
| Done | 0 |
| Partial | 0 |
| Drifted | 0 |
| Archived-snapshot | 52 |
| release_closeable | N/A（标准参考/模板模块，非可执行） |
