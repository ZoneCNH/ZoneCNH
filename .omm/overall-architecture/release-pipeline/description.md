release/ + scripts/ 构成的发布管线。release/manifest/ 下有 latest.json、release-manifest.json、sre-deploy-contract.json、goal-release-gate.json 及对应 .sha256 校验；release/trust/ 下有 summary/index/open-blockers/projection-guard。release/{date}/ 下是每次发布的 RELEASE-NOTES。

scripts/ 下约 30 个脚本：audit-status.py（数量审计）、version-bump.sh（版本递增）、pipeline.py/arbiter.py（四源评分仲裁）、rule-scorer.py、gc-scan.mjs（GC 扫描）等。受 VersionGuard Stop Hook 自动检查。
