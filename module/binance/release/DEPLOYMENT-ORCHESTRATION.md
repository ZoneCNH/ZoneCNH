# Binance Release Execution Guide

> **职责**：发布执行层手册；入口和判定请分别查看 `README.md` / `gate/` / `spec/`。

**Status:** 🟢 EXECUTION MANUAL
**Version:** v4.0.0 (spec) / v0.14.0 (runtime)
**Prepared:** 2026-07-04T14:05Z
**Lead:** Copilot CLI / ZoneCNH

## Executive Summary

This document is the release execution runbook. It assumes the reader already passed `README.md` -> `gate/RELEASE-CHECKLIST.md` -> `gate/DEPLOY-PREFLIGHT.md` and only needs the operational steps for release path A/B, rollback, and post-release smoke.

## Pre-Deployment Validation Status

| Check | Result | Evidence |
|-------|--------|----------|
| Code Quality | ✅ PASS | 54/54 tests, CI 15/15 gates |
| Version Consistency | ✅ PASS | v4.0.0/v0.14.0 verified |
| Documentation Integrity | ✅ PASS | 70/70 refs valid |
| Staging Validation | ✅ PASS | Health checks OK, p99 <150ms |
| Production Readiness | ✅ SIGNED | Checklist approved |

## Deployment Plan

### Phase 1: Pre-Deployment (T-24h to T-0)

**Activities:**
1. Notify ops team and all stakeholders
2. Schedule deployment window (off-peak hours recommended)
3. Prepare rollback procedures (blue/canary standby)
4. Brief on-call engineer and incident commander
5. Verify staging environment ready
6. Final sanity check of all prerequisites

**Owner:** Engineering Lead / DevOps Lead  
**Duration:** 1-2 hours  
**Go/No-Go:** All items completed before T-0

---

### Phase 2: Deployment Execution (T-0 to T+30min)

#### 2.1 Green Environment Setup (T-0 to T+10min)
1. Deploy v0.12.0 container image to green environment
2. Apply configuration for green environment
3. Verify all services starting (logs check)
4. Wait for health probes to succeed

**Metrics:** All pods READY, all containers Running  
**Duration:** 10 minutes

#### 2.2 Health Check Suite (T+10 to T+15min)
1. Run comprehensive health check endpoints
   - `GET /health/ready` → 200 OK
   - `GET /health/live` → 200 OK
   - `GET /api/v1/exchange/status` → 200 OK
2. Validate all dependencies connected (DB, Redis, NATS)
3. Verify monitoring metrics flowing

**Success Criteria:** All 3 endpoints return 200  
**Duration:** 5 minutes

#### 2.3 Canary Traffic (T+15 to T+30min)
1. Enable traffic routing to green (5% of traffic)
2. Monitor metrics for 15 minutes
3. Verify:
   - Error rate remains <0.1%
   - Latency p99 stays <500ms
   - No increased 5xx errors
   - Database query patterns normal

**Success Criteria:** No anomalies detected  
**Duration:** 15 minutes

#### 2.4 Full Traffic Flip (T+30 to T+35min)
1. Route 100% of traffic to green environment
2. Monitor for 5 minutes
3. Verify blue environment receiving zero traffic
4. Confirm all metrics show healthy state

**Metrics:** 100% traffic on green, error rate <0.1%  
**Duration:** 5 minutes

---

### Phase 3: Post-Deployment Monitoring (T+35min to T+72h)

#### 3.1 Immediate Monitoring (T+35min to T+2h)
- Every 5 minutes: Check error rate, latency, DB pool
- Alert threshold: Any metric crosses critical
- Action threshold: Continue monitoring if OK

#### 3.2 First 4 Hours (T+2h to T+6h)
- Every 30 minutes: Full health check
- Monitor for unusual patterns
- Alert on any threshold breach
- Decision point at T+4h: Proceed or rollback?

#### 3.3 First 24 Hours (T+6h to T+24h)
- Every hour: Metrics review
- Check for performance degradation
- Monitor resource utilization
- Decision point at T+24h: Proceed or rollback?

#### 3.4 Full 72 Hours (T+24h to T+72h)
- Daily metrics review
- Weekly trend analysis
- Blue environment status: Keep standby or retire
- Decision point at T+72h: Mark as stable

---

### Phase 4: Post-Release Activities (T+72h)

**Activities:**
1. Conduct post-deployment retrospective
2. Collect all incident reports (if any)
3. Update runbooks based on lessons learned
4. Archive blue environment or retire
5. Plan next iteration (C4+ scaffolds)

**Owner:** Engineering Lead + Operations  
**Duration:** 2-3 hours

---

## Rollback Procedure

### Trigger Conditions (Automatic Rollback)

| Condition | Threshold | Trigger | Action |
|-----------|-----------|---------|--------|
| Error Rate | >1% | 5 min | Immediate rollback |
| Latency p99 | >1000ms | 5 min | Immediate rollback |
| DB Pool | >95% | 2 min | Immediate rollback |
| Security Issue | Critical | Detected | Immediate rollback |
| Dependency Failure | Any | Immediate | Immediate rollback |

### Rollback Steps (Duration: <5 min)

1. **Trigger:** Ops team initiates rollback or automated system triggers
   - Command: `kubectl set image deployment/binance-api binance-api=binance:v0.11.0`

2. **Verify Rollback:** (1 minute)
   - Check v0.11.0 pods becoming Ready
   - Monitor traffic returning to 100% on blue

3. **Health Check:** (1 minute)
   - Call `GET /health/ready` on blue
   - Verify all dependencies reconnected

4. **Monitor Metrics:** (3 minutes)
   - Error rate returns to normal (<0.1%)
   - Latency p99 returns to baseline
   - Database connections healthy

5. **Status Update:**
   - Incident commander sends update
   - Post-mortem scheduled for same day

---

## Health Check Thresholds

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| Error Rate | <0.1% | >0.5% | >1% |
| Latency p99 | <500ms | >400ms | >1000ms |
| NATS Lag | <1s | >5s | >30s |
| DB Pool | <70% | >80% | >95% |

---

## Contacts & Escalation

- **On-call Engineer:** [on-call-phone]
- **Ops Lead:** [ops-lead-email]
- **Incident Commander:** [ic-phone]
- **Engineering Lead:** [eng-lead-email]

---

**Document prepared:** 2026-07-04T14:05Z  
**Status:** 🟢 HANDOFF TO OPS TEAM  
**Next:** Execute Phase 2 deployment
