<!--
  来源文档: docs/goal/26-rsi-full-standard.md
  文档编号: RSI-SG-001
  版本: v1.0
  日期: 2026-06-11
  语言: 中文
-->

# 26. 可执行模板与清单

## 26.1 Permission Request

```text
Permission Request ID:
Requesting system:
Current RSI level:
Requested permission:
Target resource:
Reason:
Expected duration:
Expected benefit:
Risk introduced:
Compensating controls:
Rollback plan:
Approver:
Expiry time:
```

## 26.2 Agent Manifest

```json
{
  "agent_id": "agent-rsi-dev-001",
  "owner": "AI R&D Platform Team",
  "rsi_level": "R2",
  "allowed_tools": [
    "read_repo",
    "write_sandbox",
    "run_unit_tests",
    "submit_pull_request"
  ],
  "forbidden_tools": [
    "merge_pull_request",
    "deploy_production",
    "read_model_weights",
    "read_hidden_tests",
    "modify_evaluator",
    "delete_logs",
    "create_cloud_resource",
    "send_external_email"
  ],
  "network_policy": {
    "default": "deny",
    "allowlist": [
      "internal-package-registry",
      "internal-eval-service"
    ]
  },
  "resource_limits": {
    "cpu_hours": 20,
    "gpu_hours": 0,
    "storage_gb": 50,
    "wall_clock_hours": 12
  },
  "logging": {
    "immutable": true,
    "retain_days": 365,
    "capture_tool_calls": true,
    "capture_code_diff": true,
    "capture_stdout_stderr": true
  },
  "approval_required_for": [
    "permission_change",
    "new_tool",
    "training_job",
    "evaluator_change",
    "network_egress",
    "production_access"
  ]
}
```

## 26.3 Safety Case

```text
1. 系统概述
2. RSI 等级判定
3. 改进闭环描述
4. 资产与权限清单
5. 风险假设
6. 不可接受风险阈值
7. 能力评估结果
8. 对齐与控制评估结果
9. 评测器完整性证明
10. 沙盒与隔离证明
11. 权重与数据安全证明
12. 红队测试摘要
13. 外部评估摘要
14. 残余风险说明
15. 缓解措施
16. 回滚与暂停机制
17. 未解决问题
18. 放行结论
19. 批准签名
```

## 26.4 Risk Register

```text
Risk ID:
Risk title:
RSI level:
Affected component:
Risk category:
Threat scenario:
Trigger condition:
Likelihood:
Impact:
Detectability:
Current controls:
Residual risk:
Risk owner:
Mitigation plan:
Deadline:
Status:
Acceptance authority:
Review date:
```

## 26.5 Compliance Decision

```text
RSI Compliance Decision

System name:
System ID:
Version:
Assessment date:
Assessor:
RSI level:
Risk score:
Release target:

Decision:
[ ] Approved
[ ] Approved with restrictions
[ ] Deferred
[ ] Rejected
[ ] Emergency stop

Required restrictions:
-

Key evidence reviewed:
- RSI Impact Assessment:
- Safety Case:
- Evaluation Report:
- Red Team Report:
- External Audit:
- Rollback Test:
- Incident History:

Unresolved risks:
1.
2.
3.

Residual risk judgment:
[ ] Acceptable
[ ] Acceptable with restrictions
[ ] Not acceptable
[ ] Unknown / insufficient evidence

Approval:
RSI Safety Officer:
Security Officer:
Release Authority:
Executive Risk Committee:
```

---

