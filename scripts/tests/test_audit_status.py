"""audit-status.py regression tests."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


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
