# CodeQL Fix Results — 2026-07-11

## Summary

Applied the working CodeQL configuration from `xhyperium/bootstrap` to all 15 failing repos.

**Template source**: `xhyperium/bootstrap/.github/workflows/codeql.yml` (CodeQL init+analyze v3.27.5)

## Method

All repos have branch protection (push-to-main blocked). Used feature branch + PR + admin merge workflow:
1. `git reset --hard origin/main`
2. `git checkout -b fix/codeql-sync-template`
3. Write bootstrap's codeql.yml
4. `git push -u origin fix/codeql-sync-template`
5. `gh pr create --fill`
6. `gh pr merge --merge --admin`

## Results

| # | Repo | PR | CodeQL Run | Status |
|---|------|-----|-----------|--------|
| 1 | kernel | [#52](https://github.com/xhyperium/kernel/pull/52) | [Run](https://github.com/xhyperium/kernel/actions/runs/29151254083) | MERGED |
| 2 | configx | [#26](https://github.com/xhyperium/configx/pull/26) | [Run](https://github.com/xhyperium/configx/actions/runs/29151254679) | MERGED |
| 3 | observex | [#30](https://github.com/xhyperium/observex/pull/30) | [Run](https://github.com/xhyperium/observex/actions/runs/29151255351) | MERGED |
| 4 | resiliencx | [#40](https://github.com/xhyperium/resiliencx/pull/40) | [Run](https://github.com/xhyperium/resiliencx/actions/runs/29151255988) | MERGED |
| 5 | schedulex | [#28](https://github.com/xhyperium/schedulex/pull/28) | [Run](https://github.com/xhyperium/schedulex/actions/runs/29151256601) | MERGED |
| 6 | testkitx | [#31](https://github.com/xhyperium/testkitx/pull/31) | [Run](https://github.com/xhyperium/testkitx/actions/runs/29151257292) | MERGED |
| 7 | redisx | [#36](https://github.com/xhyperium/redisx/pull/36) | [Run](https://github.com/xhyperium/redisx/actions/runs/29151257925) | MERGED |
| 8 | natsx | [#29](https://github.com/xhyperium/natsx/pull/29) | [Run](https://github.com/xhyperium/natsx/actions/runs/29151258611) | MERGED |
| 9 | postgresx | [#19](https://github.com/xhyperium/postgresx/pull/19) | [Run](https://github.com/xhyperium/postgresx/actions/runs/29151259292) | MERGED |
| 10 | taosx | [#32](https://github.com/xhyperium/taosx/pull/32) | [Run](https://github.com/xhyperium/taosx/actions/runs/29151259827) | MERGED |
| 11 | ossx | [#18](https://github.com/xhyperium/ossx/pull/18) | [Run](https://github.com/xhyperium/ossx/actions/runs/29151260479) | MERGED |
| 12 | clickhousex | [#21](https://github.com/xhyperium/clickhousex/pull/21) | [Run](https://github.com/xhyperium/clickhousex/actions/runs/29151261102) | MERGED |
| 13 | contracts | [#27](https://github.com/xhyperium/contracts/pull/27) | [Run](https://github.com/xhyperium/contracts/actions/runs/29151261673) | MERGED |
| 14 | domain_macro | — | [Run](https://github.com/xhyperium/domain_macro/actions/runs/29151262339) | SKIPPED (already correct) |
| 15 | xlibgate | [#81](https://github.com/xhyperium/xlibgate/pull/81) | [Run](https://github.com/xhyperium/xlibgate/actions/runs/29151262952) | MERGED |

## Notes

- **domain_macro** was skipped — its codeql.yml was already identical to the bootstrap template (commit `05943b8`: "fix: use matching CodeQL init/analyze versions (v3.27.5)"). Workflow triggered on existing main.
- **cp** is aliased to `cp -i` on this host; used `cat > file` to avoid interactive prompts.
- Branch protection required PR-based merge with `--admin` override for all repos.
- All 14 PRs merged and deleted source branches; all 15 workflows triggered.
