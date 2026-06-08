"""
pipeline.py 测试
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]


def _load():
    spec = importlib.util.spec_from_file_location("pipeline_mod", ROOT / "scripts/pipeline.py")
    mod = importlib.util.module_from_spec(spec)
    sys.modules["pipeline_mod"] = mod
    spec.loader.exec_module(mod)
    return mod


pl = _load()


@pytest.fixture
def env(tmp_path, monkeypatch):
    monkeypatch.setattr(pl, "ROOT", tmp_path)
    monkeypatch.setattr(pl, "STATE_ROOT", tmp_path / ".omc/state/pipeline")
    return tmp_path


def _write_verdict(env_path, module, stage, gate, composite=99, next_action="advance"):
    d = env_path / ".omc/state/pipeline" / module / stage
    d.mkdir(parents=True, exist_ok=True)
    (d / "verdict.json").write_text(json.dumps({
        "gate": gate, "composite_score": composite,
        "next_action": next_action, "attempt": 1,
    }), encoding="utf-8")


def test_next_empty(env, capsys):
    rc = pl.cmd_next("m1")
    assert rc == 0
    assert capsys.readouterr().out.strip() == "spec"


def test_next_first_failing_stage(env, capsys):
    _write_verdict(env, "m1", "spec", "pass")
    _write_verdict(env, "m1", "matrix", "fail")
    rc = pl.cmd_next("m1")
    assert rc == 0
    assert capsys.readouterr().out.strip() == "matrix"


def test_next_done(env, capsys):
    for stage in pl.STAGES:
        _write_verdict(env, "m1", stage, "pass")
    pl.cmd_next("m1")
    assert capsys.readouterr().out.strip() == "done"


def test_next_advances_past_pass(env, capsys):
    _write_verdict(env, "m1", "spec", "pass")
    _write_verdict(env, "m1", "matrix", "pass")
    pl.cmd_next("m1")
    assert capsys.readouterr().out.strip() == "tasks"


def test_status_runs(env, capsys):
    _write_verdict(env, "m1", "spec", "pass", composite=98)
    rc = pl.cmd_status("m1")
    assert rc == 0
    out = capsys.readouterr().out
    assert "Pipeline status: m1" in out
    assert "spec" in out and "pass" in out
