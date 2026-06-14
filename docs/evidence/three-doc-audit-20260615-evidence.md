# Evidence: 三文档一致性审计 2026-06-15

> 对应 ISA: `docs/solutions/three-doc-audit-20260615-ISA.md`

## ISC-1: domainx 三文件统一归基座

**命令**: `grep -n domainx STATUS.md | grep 'github.com'`

```
39:| [domainx](https://github.com/ZoneCNH/domainx) | v0.1.0 | █████ 100% | 100% | spec=100 mat=100 tsk=100 pln=100 prm=100 cod=100 | 执行域共享值对象：Order/Position/Trade/Portfolio/ExecutionReport 枚举与类型；v0.1.0 CI 已部署 |
```

domainx 位于 STATUS.md 基座组件表（第 39 行，transportx 之后），非 L2.5 表。README L88 在基座契约段。ARCH L24（领域共享: domainx）和 L130（各域说明表基座行末尾）。

**判定**: 通过。

## ISC-2: 仪表盘三恒等式自洽

**命令**: `python3 scripts/audit-status.py`

```
--- 2. Dashboard vs domain stats ---
  PASS Total: 80 == 80
  PASS Existing: 58 == 58
  PASS Created: 22 == 22
  PASS Progress: 62% == 62%
```

55+1+22+2=80, 37+43=80, 58+22=80。check 2 全部 PASS。

**判定**: 通过。

## ISC-3: ARCHITECTURE 状态表版本/进度对齐

**命令**: `git diff 7cef153..HEAD -- ARCHITECTURE.md | grep '^-\|^+'`

12 模块逐项已对齐：

| 模块 | ARCH 原值 | 修正值 |
|------|:--------:|:-----:|
| xlib-standard | `-` | v1.0.0 |
| xlib-harness | v1.0.0 | `-` |
| xlib-evidence | v1.0.0 | `-` |
| testkitx | v0.4.0, 90% | v1.0.0, 100% |
| resiliencx | v1.0.1 | v1.0.0 |
| xlibgate | 95% | 100% |
| redisx | v1.0.0 | v1.0.1 |
| postgresx | 90% | 100% |
| decimalx | v0.2.0 | v0.1.0 |
| regime-engine | `-`, 5% | v0.1.0, 25% |
| observex (横切) | v0.3.1, 80% | v1.0.0, 100% |
| contracts | 进度 -- | █████ 100% |

**判定**: 通过。

## ISC-4: 78 repos 全量存在

**命令**: `python3 scripts/audit-status.py --network`

```
--- 7. 404 check ---
  PASS No 404 links (78 repos)
```

**判定**: 通过。

## ISC-5: 同步表与组件表一致

**命令**: `python3 scripts/audit-status.py`

```
--- 3. Sync table vs unique repos ---
  PASS README: 77 == 77
  PASS ARCH: 77 == 77
  PASS STATUS: actual=78 sync-table=78 (diff=0, OK)
```

同步表 L2.5=4/4/4, 分析域=8/8/8, 决策域=6/6/6, 横切=2/2/2。

**判定**: 通过。

## ISC-6: strategies 全部引用已移除

**命令**: `grep -rn strategies STATUS.md README.md ARCHITECTURE.md | grep -v strategyx`

```
(空输出)
```

三文档 strategyx 除外无 strategies 引用。FOUNDATION-DEPS.yaml 和 ROADMAP.md 也已在 #419、#421 清除。

**判定**: 通过。

## ISC-7: GitHub Release/tag 验证

**命令**: `for r in xlib-standard ... domainx; do gh api repos/ZoneCNH/$r/releases | jq length; done`

| 指标 | 集群 | 验证结果 |
|------|:---:|------|
| 有 GitHub Release | kernel, configx, observex, testkitx, resiliencx, schedulex, xlibgate, xlib-standard, redisx, kafkax, natsx, postgresx, taosx, ossx (14 个) | `gh release view` 逐一确认 |
| 仅 git tag | clickhousex (v1.0.1), contracts (v1.0.1-spec), transportx (v1.1.1-spec), domainx (v0.1.0) (4 个) | `gh api repos/ZoneCNH/$r/git/refs/tags` 存在 |
| 全无 | xlib-harness, xlib-evidence (2 个) | 无 tag 无 release |

**判定**: 14/20 Release, 18/20 tag, 2/20 全无。与 STATUS.md 版本列一致。

## ISC-8: 三层预防部署

**命令**: `ls -la .claude/hooks/count-guard.mjs scripts/audit-status.py .github/workflows/audit-status.yml`

```
.claude/hooks/count-guard.mjs  → 6.6k, PreToolUse hook
scripts/audit-status.py        → 10k, 21 checks
.github/workflows/audit-status.yml → 410B, blocks merge on FAIL
```

`node .claude/hooks/count-guard.mjs < test_block.json` → exit 2（block 模式生效）。`python3 scripts/audit-status.py` → exit 0。

**判定**: 通过。

## ISC-9: audit-status.py 22/22 PASS

**命令**: `python3 scripts/audit-status.py --network`

```
==========================================
Results: 22 passed / 0 failed / 22 total
==========================================
```

**判定**: 通过。

## ISC-10: 域统计有版本号

**命令**: `awk -F'|'` 逐域计数

```
基座     18  (xlib-harness/xlib-evidence 无版本)
L2.5      4  (decimalx, domain-market, domain-exchange, domain-macro)
Provider  5  (全部 v0.1.0)
分析域    2  (regime-engine v0.1.0, flowx v0.1.0-draft)
决策域    3  (backtestx, strategyx, maestro v0.1.0-draft)
执行域    3  (riskx, orderx, positionx v0.1.0-draft)
x.go      1  (v0.0.1)
observex  1  (v1.0.0)
────────────────
合计     37
```

域统计表合计行 = 37。每分项通过组件表逐行提取非空非 `-` 版本列验证。

**判定**: 通过。
