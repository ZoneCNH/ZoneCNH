import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LINT = ROOT / ".github" / "ci" / "kernel-governance-lint.sh"
WORKFLOW = ROOT / ".github" / "workflows" / "docs-ci.yml"
ACCEPTANCE = ROOT / "module" / "kernel" / "ACCEPTANCE.md"


def test_kernel_governance_lint_passes_current_tree():
    result = subprocess.run(
        ["bash", str(LINT)],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    )
    assert "kernel-governance-lint: PASS" in result.stdout


def test_docs_ci_runs_kernel_governance_lint():
    workflow = WORKFLOW.read_text()
    assert "Kernel Governance Lint" in workflow
    assert "bash .github/ci/kernel-governance-lint.sh" in workflow


def test_acceptance_uses_portable_governance_worktree_and_keeps_gate_caveat():
    text = ACCEPTANCE.read_text()
    stale = "/home/ZoneCNH-kernel" + "-governance-evidence"
    assert stale not in text
    assert "cd <kernel-governance-evidence-worktree>" in text
    assert "不是当前 Factory、GK-9 或 GK-10 通过证明" in text
    assert "当前仍不得关闭 Factory / GK-9 / GK-10" in text
    assert "不得仅凭 task 文档、历史状态文件或人工描述" in text
