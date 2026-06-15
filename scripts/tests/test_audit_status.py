"""audit-status.py regression tests."""

from __future__ import annotations

import ast
import subprocess
import sys

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


def test_multidimensional_status_rows_cover_foundationx_modules():
    helpers = load_audit_helpers()
    parse_multidimensional_status_rows = helpers["parse_multidimensional_status_rows"]
    load_json = helpers["load_json"]

    status_text = (ROOT / "STATUS.md").read_text()
    rows = parse_multidimensional_status_rows(status_text)
    modules = load_json(".foundationx/status/index.json")["modules"]

    assert set(rows) == set(modules)
    assert len(rows) == 20
    assert rows["domainx"]["release"] == "❌"
    assert rows["domainx"]["factory"] == "❌"


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


def test_audit_status_full_mode_runs_clean():
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
    assert "STATUS FACTORY rows match fact-layer factory values" in result.stdout
