"""audit-status.py regression tests."""

from __future__ import annotations

from pathlib import Path
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
    assert rows["domainx"]["release"] == "✅"
    assert rows["domainx"]["factory"] == "❌"


def test_multidimensional_status_rows_skip_malformed_entries():
    helpers = load_audit_helpers()
    parse_multidimensional_status_rows = helpers["parse_multidimensional_status_rows"]

    text = """
📊 基座多维成熟度展开
| module | spec | impl | release | live | ext ci | adopt | soak | factory | note |
| alpha | ✅ | ✅ | ❌ | N/A | N/A | N/A | N/A | ❌ | ok |
| broken | ✅ | ✅ | ❌ | N/A | N/A | N/A | N/A | ❌ |
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
