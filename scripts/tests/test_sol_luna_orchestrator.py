"""TDD contract tests for ``scripts/sol_luna_orchestrator.py``.

The implementation is intentionally not imported through a fallback or a
skip: while the implementation is absent, collection must fail with the
missing module path rather than silently turning this contract green.
"""

from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
from types import SimpleNamespace
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts" / "sol_luna_orchestrator.py"


def _load_orchestrator():
    spec = importlib.util.spec_from_file_location("sol_luna_orchestrator", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise AssertionError(f"cannot load orchestrator module from {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


orchestrator = _load_orchestrator()


def _error_types():
    custom_error = getattr(orchestrator, "OrchestrationError", None)
    if isinstance(custom_error, type) and issubclass(custom_error, BaseException):
        return (ValueError, custom_error)
    return (ValueError,)


def _catalog():
    return {
        "models": [
            {
                "slug": orchestrator.SOL_MODEL,
                "supported_reasoning_efforts": ["high", "xhigh"],
            },
            {
                "slug": orchestrator.LUNA_MODEL,
                "supported_reasoning_efforts": ["high", "xhigh"],
            },
        ]
    }


def _plan(task_count: int, workers: int | None = None) -> dict:
    return {
        "tasks": [
            {
                "id": f"task-{index}",
                "scope": f"src/task-{index}.py",
            }
            for index in range(task_count)
        ],
        "workers": workers if workers is not None else task_count,
        "max_retries": 1,
    }


def _batch_results(plan: dict) -> list[dict]:
    return [
        {
            "task_id": task["id"],
            "status": "passed",
            "mechanical_check": "passed",
            "evidence": [f"evidence for {task['id']}"],
            "uncertainties": [],
            "conflicts": [],
            "scope_violation": False,
            "changed_files": [task["scope"]],
            "retry_count": 0,
        }
        for task in plan["tasks"]
    ]


def _decision(evaluation):
    """Read both permitted result shapes without weakening the decision check."""
    if hasattr(evaluation, "decision"):
        return evaluation.decision
    return evaluation["decision"]


def test_public_constants_define_the_sol_luna_contract():
    assert orchestrator.SOL_MODEL == "gpt-5.6-sol"
    assert orchestrator.LUNA_MODEL == "gpt-5.6-luna"
    assert orchestrator.REASONING_EFFORT == "xhigh"
    assert orchestrator.MIN_EXECUTORS == 3
    assert orchestrator.MAX_EXECUTORS == 5


def test_model_supports_sol_and_luna_at_xhigh_but_not_luna_at_ultra():
    catalog = _catalog()

    assert orchestrator.model_supports(catalog, orchestrator.SOL_MODEL, "xhigh") is True
    assert orchestrator.model_supports(catalog, orchestrator.LUNA_MODEL, "xhigh") is True
    assert orchestrator.model_supports(catalog, orchestrator.LUNA_MODEL, "ultra") is False


@pytest.mark.parametrize("model", [orchestrator.SOL_MODEL, orchestrator.LUNA_MODEL])
def test_build_codex_command_uses_model_and_xhigh_as_argv_tokens(model):
    prompt = "/tmp/prompt with spaces.md"

    command = orchestrator.build_codex_command(
        model=model,
        effort=orchestrator.REASONING_EFFORT,
        workspace="/workspace/project",
        prompt_file_or_dash=prompt,
        sandbox="read-only",
    )

    assert isinstance(command, list)
    assert all(isinstance(token, str) for token in command)
    assert command.count("-m") == 1
    assert command[command.index("-m") + 1] == model
    assert command[:4] == ["codex", "-a", "never", "exec"]
    assert "--ephemeral" in command
    assert command.count("-c") == 1
    assert command[command.index("-c") + 1] == 'model_reasoning_effort="xhigh"'
    assert command[command.index("--sandbox") + 1] == "read-only"
    assert command[-1] == prompt
    assert not any(token.startswith("'") or token.startswith('"') for token in command)


@pytest.mark.parametrize("invalid_path", ["", "/tmp/project/file.py", "../outside.py", "src/../outside.py"])
def test_normalize_scope_rejects_empty_absolute_and_parent_paths(invalid_path):
    with pytest.raises(_error_types()):
        orchestrator.normalize_scope(invalid_path)


def test_normalize_scope_preserves_directory_prefix_and_normalizes_file_scope():
    assert orchestrator.normalize_scope("src/task.py") == "src/task.py"
    assert orchestrator.normalize_scope("src/") == "src/"


@pytest.mark.parametrize(
    ("path", "scopes", "expected"),
    [
        ("src/task.py", ["src/task.py"], True),
        ("src/task.py.bak", ["src/task.py"], False),
        ("src/lib/task.py", ["src/"], True),
        ("src-extra/task.py", ["src/"], False),
        ("docs/README.md", ["src/", "docs/README.md"], True),
    ],
)
def test_path_in_scope_distinguishes_exact_files_directory_prefixes_and_similar_prefixes(
    path, scopes, expected
):
    assert orchestrator.path_in_scope(path, scopes) is expected


@pytest.mark.parametrize(
    ("left", "right", "expected"),
    [
        ("src/task.py", "src/task.py", True),
        ("src/task.py", "src/", True),
        ("src/", "src/lib/", True),
        ("src/", "src-extra/", False),
        ("src/task.py", "src/task.py.bak", False),
    ],
)
def test_scopes_overlap_uses_path_boundaries(left, right, expected):
    assert orchestrator.scopes_overlap(left, right) is expected


@pytest.mark.parametrize(
    "argv",
    [
        ["git", "diff", "--check"],
        ["git", "diff", "--check", "--", "src/task.py"],
        ["git", "diff", "--name-only", "--", "src/task.py"],
        ["git", "diff", "--stat", "--"],
        ["git", "diff", "--exit-code"],
        ["git", "diff", "--quiet", "--cached"],
        ["git", "diff", "--no-ext-diff"],
        ["git", "status", "--short"],
        ["git", "status", "-s"],
        ["git", "status", "--porcelain"],
        ["git", "status", "--porcelain=v1"],
        ["git", "status", "--porcelain=v2"],
        ["git", "status", "--branch"],
        ["git", "status", "-b"],
        ["git", "status", "--untracked-files=all"],
        ["git", "status", "--untracked-files=normal"],
        ["git", "status", "--untracked-files=no"],
        ["git", "status", "--porcelain=v1", "--untracked-files=all", "--", "src/"],
        ["python", "-m", "pytest", "-q"],
    ],
)
def test_is_safe_check_allows_only_explicit_read_only_checks(argv):
    assert orchestrator.is_safe_check(argv) is True


@pytest.mark.parametrize(
    "argv",
    [
        ["git", "diff", "--check; touch /tmp/pwned"],
        ["git", "diff", "--check|cat"],
        ["git", "diff", "--check&&cat"],
        ["git", "diff", "$(id)"],
        ["git", "diff", "`id`"],
        ["git", "reset", "--hard"],
        ["git", "clean", "-fd"],
        ["git", "push"],
        ["git", "diff", "--output", "owned.txt"],
        ["git", "diff", "--output=owned.txt"],
        ["git", "diff", "--ext-diff"],
        ["git", "diff", "--textconv"],
        ["git", "diff", "--unknown-flag"],
        ["git", "status", "--unknown-flag"],
        ["git", "status", "--porcelain=v3"],
        ["git", "status", "--untracked-files=maybe"],
        ["echo", "not-an-allowlisted-check"],
        ["python", "arbitrary_script.py"],
        ["python3", "arbitrary_script.py"],
        ["python", "-c", "print('arbitrary code')"],
    ],
)
def test_is_safe_check_rejects_shell_injection_mutation_git_writes_and_scripts(argv):
    assert orchestrator.is_safe_check(argv) is False


def test_snapshot_runs_checks_before_final_status_and_patch_and_tracks_scope_violation(
    tmp_path, monkeypatch
):
    events = []
    out_of_scope = "generated/check-output.txt"

    def fake_run(argv, **kwargs):
        events.append("check")
        assert kwargs["timeout"] == orchestrator.DEFAULT_CHEAP_CHECK_TIMEOUT
        output = tmp_path / out_of_scope
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text("created by check\n", encoding="utf-8")
        return subprocess.CompletedProcess(argv, 0, stdout="ok", stderr="")

    def fake_status(_worktree):
        events.append("status")
        return [out_of_scope], f" M {out_of_scope}\0", out_of_scope

    def fake_capture(_worktree, patch_path):
        events.append("capture")
        patch_path.write_text(f"diff --git a/{out_of_scope} b/{out_of_scope}\n", encoding="utf-8")
        return [out_of_scope], f" M {out_of_scope}\0", ""

    monkeypatch.setattr(orchestrator, "_run", fake_run)
    monkeypatch.setattr(orchestrator, "_status_paths", fake_status)
    monkeypatch.setattr(orchestrator, "_capture_patch", fake_capture)

    snapshot = orchestrator._snapshot_and_checks(
        tmp_path,
        [["python3", "-m", "pytest"]],
        tmp_path / "attempt.patch",
        tmp_path / "checks.json",
    )

    assert events == ["check", "status", "capture"]
    assert snapshot["changed_files"] == [out_of_scope]
    assert out_of_scope in (tmp_path / "attempt.patch").read_text(encoding="utf-8")
    assert orchestrator.path_in_scope(out_of_scope, ["src/"]) is False
    assert snapshot["check_results"][0]["returncode"] == 0


@pytest.mark.parametrize(
    ("task_count", "requested_workers"),
    [(3, 3), (5, 5)],
)
def test_validate_plan_accepts_executor_boundaries(task_count, requested_workers):
    orchestrator.validate_plan(_plan(task_count, requested_workers), requested_workers)


@pytest.mark.parametrize("requested_workers", [2, 6])
def test_validate_plan_rejects_workers_outside_executor_bounds(requested_workers):
    with pytest.raises(_error_types()):
        orchestrator.validate_plan(_plan(3, requested_workers), requested_workers)


def test_validate_plan_rejects_duplicate_task_ids():
    plan = _plan(3, 3)
    plan["tasks"][1]["id"] = plan["tasks"][0]["id"]

    with pytest.raises(_error_types()):
        orchestrator.validate_plan(plan, 3)


def test_validate_plan_rejects_overlapping_task_scopes():
    plan = _plan(3, 3)
    plan["tasks"][0]["scope"] = "src/"
    plan["tasks"][1]["scope"] = "src/task-1.py"

    with pytest.raises(_error_types()):
        orchestrator.validate_plan(plan, 3)


@pytest.mark.parametrize("scope", ["/etc/passwd", "src/../outside.py"])
def test_validate_plan_rejects_unsafe_task_scopes(scope):
    plan = _plan(3, 3)
    plan["tasks"][0]["scope"] = scope

    with pytest.raises(_error_types()):
        orchestrator.validate_plan(plan, 3)


def test_evaluate_batch_accepts_when_every_task_passes_with_evidence():
    plan = _plan(3, 3)
    results = _batch_results(plan)

    assert _decision(orchestrator.evaluate_batch(plan, results)) == "accept"


def test_evaluate_batch_retries_luna_for_a_mechanical_check_failure():
    plan = _plan(3, 3)
    results = _batch_results(plan)
    results[0]["mechanical_check"] = "failed"

    assert _decision(orchestrator.evaluate_batch(plan, results)) == "retry_luna"


@pytest.mark.parametrize(
    "mutation",
    [
        pytest.param(lambda result: result.update(evidence=[]), id="missing-evidence"),
        pytest.param(lambda result: result.update(evidence="not_run"), id="evidence-not-run"),
        pytest.param(lambda result: result.update(uncertainties=["unresolved assumption"]), id="uncertainty"),
        pytest.param(lambda result: result.update(conflicts=["task result conflict"]), id="conflict"),
        pytest.param(lambda result: result.update(scope_violation=True), id="scope-violation"),
        pytest.param(
            lambda result: result.update(changed_files=["src/shared.py"]),
            id="overlapping-actual-changed-files",
        ),
    ],
)
def test_evaluate_batch_escalates_for_incomplete_or_conflicting_evidence(mutation):
    plan = _plan(3, 3)
    results = _batch_results(plan)
    mutation(results[0])
    if results[0]["changed_files"] == ["src/shared.py"]:
        results[1]["changed_files"] = ["src/shared.py"]

    assert _decision(orchestrator.evaluate_batch(plan, results)) == "escalate_sol"


def test_evaluate_batch_escalates_when_luna_retry_budget_is_exhausted():
    plan = _plan(3, 3)
    results = _batch_results(plan)
    results[0]["mechanical_check"] = "failed"
    results[0]["retry_count"] = plan["max_retries"]

    assert _decision(orchestrator.evaluate_batch(plan, results)) == "escalate_sol"


def test_probe_cli_fails_closed_before_subprocess_when_fake_catalog_lacks_xhigh(tmp_path, monkeypatch):
    """A catalog probe must reject unsupported required models before any model call."""
    catalog_path = tmp_path / "catalog.json"
    catalog_path.write_text(
        json.dumps(
            {
                "models": [
                    {"slug": orchestrator.SOL_MODEL, "supported_reasoning_efforts": ["high"]},
                    {"slug": orchestrator.LUNA_MODEL, "supported_reasoning_efforts": ["ultra"]},
                ]
            }
        ),
        encoding="utf-8",
    )

    calls = []

    def forbidden_subprocess(*args, **kwargs):
        calls.append((args, kwargs))
        raise AssertionError("model subprocess must not run after a failed catalog probe")

    monkeypatch.setattr(subprocess, "run", forbidden_subprocess)
    monkeypatch.setattr(
        sys,
        "argv",
        ["sol_luna_orchestrator.py", "probe", "--catalog", str(catalog_path)],
    )

    try:
        return_code = orchestrator.main()
    except SystemExit as exc:
        return_code = exc.code

    assert return_code not in (None, 0)
    assert calls == []


def test_primary_worktree_root_is_the_first_registered_worktree(tmp_path, monkeypatch):
    primary = tmp_path / "primary"
    nested = primary / ".worktree" / "workspaces" / "feat" / "current"
    primary.mkdir(parents=True)
    nested.mkdir(parents=True)

    def fake_run(argv, **kwargs):
        assert argv == ["git", "worktree", "list", "--porcelain"]
        return subprocess.CompletedProcess(
            argv,
            0,
            stdout=(
                f"worktree {primary}\nHEAD abc\nbranch refs/heads/main\n\n"
                f"worktree {nested}\nHEAD def\nbranch refs/heads/feat/current\n"
            ),
            stderr="",
        )

    monkeypatch.setattr(orchestrator, "_run", fake_run)

    assert orchestrator._primary_worktree_root(nested) == primary.resolve()
    assert orchestrator._runtime_worktree_path(primary, "run-1", "task-1") == (
        primary / ".worktree" / "workspaces" / "runtime" / "sol_luna" / "run-1" / "task-1"
    )


def test_run_converts_timeout_to_returncode_124_and_keeps_stderr(monkeypatch, tmp_path):
    def timed_out(*args, **kwargs):
        assert kwargs["timeout"] == orchestrator.DEFAULT_GIT_TIMEOUT
        raise subprocess.TimeoutExpired(
            kwargs.get("args", args[0] if args else ["git"]),
            kwargs["timeout"],
            output="partial stdout",
            stderr="partial stderr",
        )

    monkeypatch.setattr(subprocess, "run", timed_out)

    result = orchestrator._run(["git", "status"], cwd=tmp_path)

    assert result.returncode == 124
    assert "partial stdout" in result.stdout
    assert "partial stderr" in result.stderr
    assert "timed out" in result.stderr.lower()


def test_run_task_passes_a_structured_output_schema_to_luna(tmp_path, monkeypatch):
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }
    seen_schema = {}

    def fake_call(*args, **kwargs):
        schema_path = kwargs["output_schema"]
        assert schema_path is not None
        seen_schema.update(json.loads(Path(schema_path).read_text(encoding="utf-8")))
        output_path = kwargs["output_last_message"]
        output_path.write_text(
            json.dumps(
                {
                    "status": "pass",
                    "summary": "完成",
                    "changed_files": [],
                }
            ),
            encoding="utf-8",
        )
        raw = json.dumps(
            {"status": "pass", "summary": "完成", "changed_files": []}
        )
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: {
            "changed_files": [],
            "status_raw": "",
            "diff_names": "",
            "patch_error": "",
            "check_results": [],
            "checks_ok": True,
        },
    )

    result = orchestrator._run_task(
        "请求",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        1,
    )

    assert result["status"] == "pass"
    assert seen_schema["required"] == ["status", "summary", "changed_files"]
    assert seen_schema["additionalProperties"] is False
    assert set(seen_schema["properties"]) == {"status", "summary", "changed_files"}


def test_run_task_retries_explicit_luna_failure_before_passing(tmp_path, monkeypatch):
    task = {
        "id": "task-1",
        "write_scope": ["src/task-1.py"],
        "instructions": "实现任务",
        "acceptance": "检查通过",
        "checks": [["git", "status", "--short"]],
    }
    responses = iter(
        [
            {"status": "fail", "summary": "首次失败", "changed_files": []},
            {"status": "pass", "summary": "重试通过", "changed_files": []},
        ]
    )
    calls = []

    def fake_call(*args, **kwargs):
        calls.append(kwargs["output_last_message"])
        raw = json.dumps(next(responses))
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: {
            "changed_files": [],
            "status_raw": "",
            "diff_names": "",
            "patch_error": "",
            "check_results": [],
            "checks_ok": True,
        },
    )

    result = orchestrator._run_task(
        "请求",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        2,
    )

    assert len(calls) == 2
    assert [attempt["model_status"] for attempt in result["attempts"]] == ["fail", "pass"]
    assert result["status"] == "pass"
    assert result.get("attempts_exhausted") is not True


def test_sol_plan_output_schema_closes_task_shape_and_requires_string_acceptance():
    schema = orchestrator._sol_plan_output_schema()
    task_schema = schema["properties"]["tasks"]["items"]

    assert schema["additionalProperties"] is False
    assert task_schema["additionalProperties"] is False
    assert task_schema["properties"]["acceptance"] == {"type": "string"}
    assert set(task_schema["properties"]) == {
        "id",
        "instructions",
        "write_scope",
        "acceptance",
        "checks",
    }


def test_sol_escalation_passes_decision_schema_to_codex(tmp_path, monkeypatch):
    seen = {}

    def fake_call(*args, **kwargs):
        schema_path = kwargs["output_schema"]
        seen.update(json.loads(Path(schema_path).read_text(encoding="utf-8")))
        kwargs["output_last_message"].parent.mkdir(parents=True, exist_ok=True)
        kwargs["output_last_message"].write_text(
            json.dumps(
                {
                    "decision": "blocked",
                    "reason": "证据不足",
                    "missing_evidence": ["检查日志"],
                }
            ),
            encoding="utf-8",
        )
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), ""

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)

    result = orchestrator._sol_escalation(
        "证据缺失", {"missing": True}, tmp_path, tmp_path / "run", tmp_path / "calls.jsonl"
    )

    assert result["returncode"] == 0
    assert set(seen["required"]) >= {"decision", "reason", "missing_evidence"}


def test_integration_repair_uses_schema_only_after_initial_checks_fail(tmp_path, monkeypatch):
    plan = {
        "tasks": [
            {"id": f"task-{index}", "write_scope": [f"src/{index}.py"]}
            for index in range(3)
        ]
    }
    task_results = [
        {"task_id": f"task-{index}", "patch_file": str(tmp_path / f"{index}.patch")}
        for index in range(3)
    ]
    checks = iter([(False, [{"returncode": 1}]), (True, [{"returncode": 0}])])
    seen = {}

    monkeypatch.setattr(orchestrator, "_create_worktree", lambda _workspace, _path: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda _workspace, _patch: (True, ""))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _path: ([], "", ""))
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args, **kwargs: next(checks))
    monkeypatch.setattr(
        orchestrator,
        "_capture_patch",
        lambda _worktree, patch_path: ([], "", "")
        if patch_path.name == "combined.patch"
        else ([], "", ""),
    )

    def fake_call(*args, **kwargs):
        schema = kwargs["output_schema"]
        seen.update(json.loads(Path(schema).read_text(encoding="utf-8")))
        output_path = kwargs["output_last_message"]
        output_path.parent.mkdir(parents=True, exist_ok=True)
        raw = json.dumps(
            {"status": "pass", "summary": "修复完成", "changed_files": []}
        )
        output_path.write_text(raw, encoding="utf-8")
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)

    result = orchestrator._integration_repair(
        "请求",
        plan,
        task_results,
        tmp_path / "workspace",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        [["git", "status", "--short"]],
        1,
        [],
        runtime_base=tmp_path / "runtime" / "run",
    )

    assert result["status"] == "pass"
    assert seen["required"] == ["status", "summary", "changed_files"]
    assert seen["additionalProperties"] is False
    assert set(seen["properties"]) == {"status", "summary", "changed_files"}


def test_integration_repair_retries_explicit_luna_failure_before_passing(tmp_path, monkeypatch):
    plan = {
        "tasks": [
            {"id": f"task-{index}", "write_scope": [f"src/{index}.py"]}
            for index in range(3)
        ]
    }
    task_results = [
        {"task_id": f"task-{index}", "patch_file": str(tmp_path / f"{index}.patch")}
        for index in range(3)
    ]
    checks = iter(
        [
            (False, [{"returncode": 1}]),
            (True, [{"returncode": 0}]),
            (True, [{"returncode": 0}]),
        ]
    )
    responses = iter(
        [
            {"status": "failed", "summary": "首次失败", "changed_files": []},
            {"status": "pass", "summary": "重试通过", "changed_files": []},
        ]
    )
    calls = []

    monkeypatch.setattr(orchestrator, "_create_worktree", lambda _workspace, _path: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda _workspace, _patch: (True, ""))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _path: ([], "", ""))
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args, **kwargs: next(checks))
    monkeypatch.setattr(orchestrator, "_capture_patch", lambda *args: ([], "", ""))

    def fake_call(*args, **kwargs):
        calls.append(kwargs["output_last_message"])
        raw = json.dumps(next(responses))
        return subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), raw

    monkeypatch.setattr(orchestrator, "_call_codex", fake_call)

    result = orchestrator._integration_repair(
        "请求",
        plan,
        task_results,
        tmp_path / "workspace",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        [["git", "status", "--short"]],
        2,
        [],
        runtime_base=tmp_path / "runtime" / "run",
    )

    assert len(calls) == 2
    assert [attempt["model_status"] for attempt in result["attempts"]] == ["failed", "pass"]
    assert result["status"] == "pass"
    assert result.get("attempts_exhausted") is not True


def _orchestration_args(workspace: Path):
    return SimpleNamespace(
        request="请求",
        request_file=None,
        workspace=str(workspace),
        workers=3,
        max_luna_attempts=1,
        check=[],
    )


def _patch_orchestration_dependencies(monkeypatch, workspace, integration_result, apply_calls):
    plan = {
        "tasks": [
            {
                "id": f"task-{index}",
                "instructions": "实现任务",
                "write_scope": [f"src/task-{index}.py"],
                "acceptance": "检查通过",
                "checks": [["git", "status", "--short"]],
            }
            for index in range(3)
        ],
        "workers": 3,
        "max_retries": 1,
    }
    primary = workspace / "primary"
    primary.mkdir(parents=True)

    monkeypatch.setattr(orchestrator, "_workspace_info", lambda _: (workspace, "feat/test", "head"))
    monkeypatch.setattr(orchestrator, "_primary_worktree_root", lambda _: primary)
    monkeypatch.setattr(
        orchestrator,
        "_probe_catalog",
        lambda: (subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""), _catalog()),
    )
    monkeypatch.setattr(
        orchestrator,
        "_call_codex",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            json.dumps(plan),
        ),
    )
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda _workspace, path: True)
    monkeypatch.setattr(
        orchestrator,
        "_run_task",
        lambda _request, task, *_args: {
            "task_id": task["id"],
            "status": "pass",
            "scope_ok": True,
            "evidence_complete": True,
            "test_failed": False,
            "changed_files": [],
            "patch_file": str(workspace / f"{task['id']}.patch"),
        },
    )
    monkeypatch.setattr(orchestrator, "_integration_repair", lambda *args, **kwargs: integration_result)
    monkeypatch.setattr(
        orchestrator,
        "_apply_patch",
        lambda target, patch: (apply_calls.append((target, patch)) or (True, "")),
    )
    def fake_run(argv, **kwargs):
        stdout = "head\n" if argv == ["git", "rev-parse", "HEAD"] else ""
        return subprocess.CompletedProcess(argv, 0, stdout=stdout, stderr="")

    monkeypatch.setattr(orchestrator, "_run", fake_run)


def test_failed_integration_never_applies_a_patch_to_parent(tmp_path, monkeypatch):
    apply_calls = []
    _patch_orchestration_dependencies(
        monkeypatch,
        tmp_path / "workspace",
        {"status": "test_failure", "reason": "全局检查失败"},
        apply_calls,
    )
    workspace = tmp_path / "workspace"
    workspace.mkdir(exist_ok=True)

    code, summary = orchestrator._run_orchestration(_orchestration_args(workspace))

    assert code == 20
    assert summary["verdict"] == "escalate_sol"
    assert apply_calls == []


def test_parent_apply_happens_once_only_after_integration_checks_pass(tmp_path, monkeypatch):
    apply_calls = []
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    _patch_orchestration_dependencies(
        monkeypatch,
        workspace,
        {"status": "pass", "patch_file": str(workspace / "combined.patch")},
        apply_calls,
    )

    code, summary = orchestrator._run_orchestration(_orchestration_args(workspace))

    assert code == 0
    assert summary["verdict"] == "accept"
    assert len(apply_calls) == 1
    assert apply_calls[0][0] == workspace
