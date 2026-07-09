# CICD-001 Release Notes — v1.1.0

> Date: 2026-07-09  
> Release: https://github.com/ZoneCNH/ZoneCNH/releases/tag/v1.1.0  
> xlibgate: https://github.com/ZoneCNH/xlibgate/releases/tag/v1.2.0

## Summary

ZoneCNH CI/CD 从 GitHub-hosted runners 全部迁移至 self-hosted sre/* pool 架构。
16 runners, 11 pools, 3 hosts, Go 1.26.5, 0 ubuntu-latest.

## Deliverables

| Metric | Value |
|--------|-------|
| Self-hosted runners | 16 |
| sre/* pool types | 11 |
| SRE hosts | 3 |
| Go baseline | 1.26.5 |
| ubuntu-latest residue | 0 |
| Migrated workflow files | 70+ |
| Module ci-workflow coverage | 58 |

## Runner Fleet

```
sre/governance     ×2  94.72.124.39
sre/foundation-l0  ×2  10.2.2.9
sre/foundation-l1  ×2  10.2.2.9
sre/contracts      ×1  10.2.2.9
sre/security       ×1  10.2.2.9
sre/market         ×1  84.247.154.45
sre/macro          ×1  84.247.154.45
sre/storage-heavy  ×2  84.247.154.45
sre/storage-light  ×1  84.247.154.45
sre/engine         ×1  84.247.154.45
sre/deploy         ×2  84.247.154.45
```

## New Files

| File | Purpose |
|------|---------|
| BASELINE.yaml | Go + CI/CD policy SSOT |
| docs/sre/RUNNER-POOLS.yaml | 11 pool registry |
| docs/sre/MODULE-RUNNER-MAP.yaml | 68 module→pool map |
| .github/ci/runner-policy-guard.sh | Self-hosted enforcement |
| .github/ci/runner-evidence.sh | Evidence generation |
| .github/workflows/runner-gate.yml | Reusable gate (14 workflows) |
| .github/workflows/compliance.yml | Compliance dashboard |
| .github/workflows/runner-health.yml | 30min health check |
| .github/workflows/drift-scan.yml | Daily drift scan |

## xlibgate

4 new gates in ZoneCNH/xlibgate#76:
- `trust runner-policy` — runner compliance scan
- `trust runner-pools` — pool registration verification
- `trust runner-evidence` — evidence schema validation
- `trust deploy-isolation` — deploy isolation rules
