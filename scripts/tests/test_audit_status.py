"""audit-status.py regression tests."""

from __future__ import annotations

import ast
import json
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "audit-status.py"


def load_audit_helpers():
    """Load helper functions from audit-status.py without running its main body."""
    source = SCRIPT.read_text()
    marker = "# ── Load ────────────────────────────────────────────────────"
    prefix = source.split(marker, 1)[0]
    namespace: dict[str, object] = {"__file__": str(SCRIPT)}
    exec(compile(prefix, str(SCRIPT), "exec"), namespace)
    return namespace


def load_json_file(relative_path: str):
    return json.loads((ROOT / relative_path).read_text())


def test_multidimensional_status_rows_cover_foundationx_modules():
    helpers = load_audit_helpers()
    parse_multidimensional_status_rows = helpers["parse_multidimensional_status_rows"]
    load_json = helpers["load_json"]

    status_text = (ROOT / "STATUS.md").read_text()
    rows = parse_multidimensional_status_rows(status_text)
    status_doc = load_json(".foundationx/status/index.json")
    modules = status_doc["modules"]
    status_module_total = status_doc["total_modules"]

    assert set(rows) == set(modules)
    assert len(rows) == len(modules) == status_module_total
    assert rows["domainx"]["release"] == "✅"
    assert rows["domainx"]["factory"] == "✅"


def test_status_release_projection_note_matches_fact_layer_summary():
    helpers = load_audit_helpers()
    parse_status_release_projection_count = helpers["parse_status_release_projection_count"]

    status_text = (ROOT / "STATUS.md").read_text()
    fact_release_published = load_json_file(".foundationx/status/index.json")["summary"]["release_published"]

    assert parse_status_release_projection_count(status_text) == fact_release_published
    assert parse_status_release_projection_count(
        "当前 20-module projection 中 14/20 已发布 GitHub Release"
    ) == 14
    assert parse_status_release_projection_count("release count missing") is None


def test_multidimensional_status_rows_skip_malformed_entries():
    helpers = load_audit_helpers()
    parse_multidimensional_status_rows = helpers["parse_multidimensional_status_rows"]

    text = """
📊 基座多维成熟度展开
| 组件 | spec | impl | release | live | ext ci | adopt | soak | factory | note |
| alpha | ✅ | ✅ | ❌ | N/A | N/A | N/A | N/A | ❌ | ok |
| broken | ✅ | ✅ | ❌ | N/A | N/A | N/A | N/A | ❌
| beta | ✅ | ✅ | ✅ | N/A | N/A | N/A | N/A | ✅ | ok |
</details>
""".strip()

    rows = parse_multidimensional_status_rows(text)

    assert set(rows) == {"alpha", "beta"}
    assert rows["alpha"]["note"] == "ok"
    assert rows["beta"]["factory"] == "✅"


def test_public_projection_guardrails_remain_explicit_in_docs():
    readme = (ROOT / "README.md").read_text()
    architecture = (ROOT / "ARCHITECTURE.md").read_text()

    for text in (readme, architecture):
        assert ".foundationx/status/index.json" in text
        assert ".foundationx/blockers.json" in text
        assert "release/factory" in text or "release / factory" in text
        assert "domainx" in text
        assert "公开投影" in text
        assert "factory-grade" in text or "factory grade" in text


def load_audit_status_namespace():
    source = (ROOT / "scripts" / "audit-status.py").read_text()
    tree = ast.parse(source, filename=str(ROOT / "scripts" / "audit-status.py"))
    allowed = (ast.Import, ast.ImportFrom, ast.FunctionDef)
    module = ast.Module(body=[node for node in tree.body if isinstance(node, allowed)], type_ignores=[])
    namespace: dict[str, object] = {}
    exec(compile(module, str(ROOT / "scripts" / "audit-status.py"), "exec"), namespace)
    return namespace


def test_compare_multidimensional_projection_detects_drift_and_overclaims():
    ns = load_audit_status_namespace()
    compare = ns["compare_multidimensional_projection"]

    status_rows = {
        "alpha": {
            "spec": "✅",
            "impl": "✅",
            "release": "❌",
            "live": "N/A",
            "ext_ci": "N/A",
            "adopt": "N/A",
            "soak": "N/A",
            "factory": "✅",
            "note": "drift",
        },
        "beta": {
            "spec": "✅",
            "impl": "✅",
            "release": "✅",
            "live": "N/A",
            "ext_ci": "N/A",
            "adopt": "N/A",
            "soak": "N/A",
            "factory": "N/A",
            "note": "boundary",
        },
    }
    modules = {
        "alpha": {"release": True, "factory": False},
        "gamma": {"release": False, "factory": True},
    }
    blockers_doc = {
        "factory_blocking_modules": ["alpha"],
        "blockers": [{"module": "alpha", "status": "open"}],
    }

    projection = compare(status_rows, modules, blockers_doc)

    assert projection["missing_status_rows"] == ["gamma"]
    assert projection["extra_status_rows"] == ["beta"]
    assert projection["release_yes"] == 1
    assert projection["release_mismatches"] == ["alpha (STATUS ❌ != fact-layer ✅)"]
    assert projection["factory_mismatches"] == ["alpha (STATUS ✅ != fact-layer ❌)"]
    assert projection["factory_na"] == 1
    assert projection["factory_overclaims"] == ["alpha"]


def test_repo_contract_yaml_matches_machine_contract():
    json_contract = load_json_file(".foundationx/repo-contract.json")
    yaml_contract = yaml.safe_load((ROOT / ".repo-contract.yaml").read_text())

    assert yaml_contract == json_contract


def test_foundation_bom_module_set_and_factory_policy_matches_status():
    status = load_json_file(".foundationx/status/index.json")
    bom = yaml.safe_load((ROOT / "foundation-bom.yaml").read_text())

    assert bom["source"] == ".foundationx/status/index.json"
    assert set(bom["modules"]) == set(status["modules"])
    assert len(bom["modules"]) == status["total_modules"]

    for name, module in status["modules"].items():
        bom_module = bom["modules"][name]
        assert bom_module["status_renderable"] is True
        assert bom_module["factory_grade_allowed"] is (
            bom_module["kind"] not in {"core", "skeleton", "test"}
        )
        if bom_module["kind"] in {"core", "skeleton", "test"}:
            assert bom_module["factory_grade_allowed"] is False


def test_release_and_factory_closure_invariants_remain_evidence_backed():
    status = load_json_file(".foundationx/status/index.json")
    blockers = load_json_file(".foundationx/blockers.json")

    release_false_modules = sorted(
        name for name, module in status["modules"].items() if module["release"] is False
    )
    factory_false_modules = sorted(
        name for name, module in status["modules"].items() if module["factory"] is False
    )
    open_blocker_modules = sorted(
        {blocker["module"] for blocker in blockers["blockers"] if blocker["status"] == "open"}
    )

    # 当前事实（2026-06-18 联网复核：21/21 模块 GitHub Release 实测存在 → release 全 true）：
    # bootstrap / kernel / ossx factory=false（分别由 BLK-009 / BLK-011 / BLK-010 open 阻塞）。
    # release_false_modules 与 factory_false_modules 直接对齐 status 权威源，不再硬编码快照。
    assert release_false_modules == []
    assert factory_false_modules == sorted(blockers["factory_blocking_modules"])
    assert blockers["factory_blocking_modules"] == factory_false_modules
    assert set(open_blocker_modules).issubset(blockers["factory_blocking_modules"])
    assert blockers["release_blocking_modules"] == []

    for name in release_false_modules:
        assert status["modules"][name]["factory"] is False

    for name in blockers["factory_blocking_modules"]:
        assert status["modules"][name]["factory"] is False

    for name in blockers["release_blocking_modules"]:
        assert status["modules"][name]["release"] is False


def test_release_trust_snapshots_match_foundationx_fact_sources():
    status = load_json_file(".foundationx/status/index.json")
    contract = load_json_file(".foundationx/repo-contract.json")
    trust_index = load_json_file("release/trust/index.json")
    trust_summary = load_json_file("release/trust/summary.json")
    trust_open = load_json_file("release/trust/open-blockers.json")
    trust_guard = load_json_file("release/trust/projection-guard.json")

    expected_open = {
        "source": ".foundationx/blockers.json",
        "total": 3,
        "by_severity": {"high": 2, "medium": 1},
        "by_module": {
            "bootstrap": ["BLK-009"],
            "kernel": ["BLK-011"],
            "ossx": ["BLK-010"],
        },
        "by_category": {"evidence": 1, "implementation": 2},
        "ids": ["BLK-009", "BLK-010", "BLK-011"],
    }
    expected_guard = {
        "source": ".foundationx/repo-contract.json",
        "contract_version": contract["contract_version"],
        "public_docs": contract["projection_guards"]["public_docs"],
        "release_manifest": contract["projection_guards"]["release_manifest"],
        "reason_code": "policy_contract_projection_drift",
        "reason_present": True,
    }
    expected_trust_summary = {
        "spec_complete": 21,
        "impl_complete": 21,
        "release_published": 21,
        "live_integration": 7,
        "factory_grade": 17,
    }

    assert trust_summary == {
        "source": ".foundationx/status/index.json",
        "summary": expected_trust_summary,
    }
    assert trust_index["summary"] == expected_trust_summary
    assert status["summary"]["factory_grade"] == 20
    assert trust_open == expected_open
    assert trust_index["open_blockers"] == trust_open
    assert trust_guard == expected_guard
    assert trust_index["projection_guard"] == trust_guard
    assert trust_index["claim_policy"]["audit_status_factory_grade_proof"] is False
    assert trust_index["missing_sources"] == []


def test_audit_status_ci_gate_stays_local_projection_guard():
    ci_gate = (ROOT / ".github" / "ci" / "status-consistency-check.sh").read_text()
    audit_source = SCRIPT.read_text()

    assert "audit-status.py\" --foundationx-only" in ci_gate
    assert "--network" not in ci_gate
    assert "python3 scripts/audit-status.py --network" in audit_source
    assert "SKIPPED (use --network)" in audit_source


def test_release_trust_policy_does_not_treat_local_audit_as_factory_proof():
    trust_index = load_json_file("release/trust/index.json")
    claim_policy = trust_index["claim_policy"]

    assert claim_policy["audit_status_factory_grade_proof"] is False
    assert "projection consistency guard only" in claim_policy["audit_status_role"]
    assert "xlibgate trust evidence" in claim_policy["factory_grade_requires"]
    assert "open blocker review" in claim_policy["factory_grade_requires"]


def test_audit_status_full_mode_runs_clean_for_current_projection():
    result = subprocess.run(
        [sys.executable, "scripts/audit-status.py"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        timeout=30,
    )

    output = result.stdout + result.stderr
    assert result.returncode == 0, output
    assert "Traceback" not in output
    assert "SKIPPED (use --network)" in result.stdout
    assert "ARCH" in result.stdout
    assert "FAIL" not in result.stdout
    assert "Summary: 51 passed, 0 failed" in result.stdout


def test_audit_status_foundationx_only_mode_runs_clean():
    result = subprocess.run(
        [sys.executable, "scripts/audit-status.py", "--foundationx-only"],
        cwd=ROOT,
        text=True,
        capture_output=True,
        timeout=30,
    )

    output = result.stdout + result.stderr
    assert result.returncode == 0, output
    assert "Traceback" not in output
    assert "=== audit-status.py --foundationx-only ===" in result.stdout
    assert "release=false implies factory=false" in result.stdout
    assert "open blockers force factory=false" in result.stdout
    assert "open release blockers force release=false" in result.stdout
