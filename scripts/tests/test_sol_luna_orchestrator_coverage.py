from __future__ import annotations

import importlib.util
import json
import subprocess
import sys
from pathlib import Path
from types import SimpleNamespace

import pytest


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "scripts" / "sol_luna_orchestrator.py"
SPEC = importlib.util.spec_from_file_location("sol_luna_orchestrator_coverage_target", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
orchestrator = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = orchestrator
SPEC.loader.exec_module(orchestrator)

SPEC_REF = "docs/governance/improvements/20260710-sol_luna_orchestration/SPEC.md"
MATRIX_REF = "docs/governance/improvements/20260710-sol_luna_orchestration/matrix/TRACEABILITY.md"
MATRIX_EDGES = [f"M-{index:03d}" for index in range(1, 9)]


def _errors():
    return (ValueError, orchestrator.BlockedError)


def _task_plan(count: int = 3) -> dict:
    return {
        "tasks": [
            {
                "id": f"task-{index}",
                "instructions": "实现隔离任务",
                "write_scope": [f"src/task-{index}.py"],
                "acceptance": "通过检查",
                "checks": [["git", "status", "--short"]],
            }
            for index in range(count)
        ],
        "workers": count,
        "max_retries": 1,
    }


def _passing_results(plan: dict) -> list[dict]:
    return [
        {
            "task_id": task["id"],
            "status": "pass",
            "evidence": ["check log"],
            "changed_files": [],
            "checks_ok": True,
        }
        for task in plan["tasks"]
    ]


def _integration_inputs(tmp_path: Path) -> tuple[dict, list[dict], list[list[str]]]:
    plan = _task_plan()
    task_results = []
    for task in plan["tasks"]:
        patch = tmp_path / f"{task['id']}.patch"
        patch.write_text("", encoding="utf-8")
        task_results.append({"task_id": task["id"], "patch_file": str(patch)})
    return plan, task_results, [["git", "status", "--short"]]


def test_small_helpers_cover_serialization_and_value_conversion(tmp_path):
    assert orchestrator._compact("abcdef", 3) == "abc\n...[输出已截断]"
    assert orchestrator._compact("short", 20) == "short"
    assert orchestrator._text_output(None) == ""
    assert orchestrator._text_output(b"bytes") == "bytes"
    assert orchestrator._text_output(42) == "42"

    json_path = tmp_path / "nested" / "value.json"
    orchestrator._write_json(json_path, {"answer": 42})
    assert json.loads(json_path.read_text(encoding="utf-8")) == {"answer": 42}
    log_path = tmp_path / "calls.jsonl"
    orchestrator._append_jsonl(log_path, {"kind": "test"})
    orchestrator._append_jsonl(log_path, {"kind": "second"})
    assert [json.loads(line)["kind"] for line in log_path.read_text().splitlines()] == [
        "test",
        "second",
    ]


def test_gate_decision_supports_mapping_compatibility():
    decision = orchestrator.GateDecision("accept")
    assert decision.decision == "accept"
    assert decision["decision"] == "accept"
    assert decision[1] == "c"


def test_scope_and_token_helpers_reject_non_strings_and_embedded_paths():
    with pytest.raises(_errors()):
        orchestrator.normalize_scope(123)
    assert orchestrator._token_has_unsafe_path("/tmp/result") is True
    assert orchestrator._token_has_unsafe_path("OUTPUT=../result") is True
    assert orchestrator._token_has_unsafe_path("CACHE=build/cache") is False
    assert orchestrator._token_has_unsafe_path("src/../outside.py") is True
    assert orchestrator._token_has_unsafe_path("C:/workspace/file.py") is True


@pytest.mark.parametrize(
    "argv",
    [
        ["pytest"],
        ["go", "test", "./..."],
        ["go", "vet", "./..."],
        ["node", "--test"],
        ["npm", "test"],
        ["npm", "run", "lint"],
        ["npm", "run", "typecheck"],
        ["cargo", "test"],
        ["cargo", "check"],
        ["cargo", "clippy"],
        ["make", "test"],
        ["make", "check"],
        ["make", "lint"],
    ],
)
def test_is_safe_check_covers_allowlisted_runners(argv):
    assert orchestrator.is_safe_check(argv) is True


@pytest.mark.parametrize(
    "argv",
    [
        None,
        [],
        ["git"],
        ["git", "diff", "--", "src/a", "--", "src/b"],
        ["git", "diff", "--", "/tmp/out"],
        ["python", "-m"],
        ["go"],
        ["node"],
        ["npm", "run", "deploy"],
        ["cargo"],
        ["make"],
    ],
)
def test_is_safe_check_rejects_malformed_or_unknown_runner(argv):
    assert orchestrator.is_safe_check(argv) is False


def test_model_supports_text_fallback_and_nested_catalog_shapes():
    text_catalog = "not json\nmodel-x supports xhigh\nmodel-y supports high"
    assert orchestrator.model_supports(text_catalog, "model-x", "xhigh") is True
    assert orchestrator.model_supports(text_catalog, "model-y", "xhigh") is False
    assert orchestrator.model_supports(17, "model-x", "xhigh") is False

    nested_catalog = {
        "items": [
            {
                "id": "model-list",
                "reasoning_efforts": [{"label": "xhigh"}],
            },
            {"name": "model-map", "supported_reasoning_efforts": {"xhigh": True}},
            {"model": "model-flag", "supports_xhigh": True},
            {"slug": "model-reason-flag", "supports_reasoning_xhigh": True},
        ]
    }
    assert orchestrator.model_supports(nested_catalog, "model-list", "xhigh") is True
    assert orchestrator.model_supports(nested_catalog, "model-map", "xhigh") is True
    assert orchestrator.model_supports(nested_catalog, "model-flag", "xhigh") is True
    assert orchestrator.model_supports(nested_catalog, "model-reason-flag", "xhigh") is True


def test_build_codex_command_validates_inputs_and_adds_optional_outputs(tmp_path):
    with pytest.raises(ValueError):
        orchestrator.build_codex_command("", "xhigh", tmp_path, "-")
    with pytest.raises(ValueError):
        orchestrator.build_codex_command("model", "xhigh", tmp_path, "-", sandbox="bad")
    with pytest.raises(ValueError):
        orchestrator.build_codex_command("model", "xhigh", tmp_path, "")

    command = orchestrator.build_codex_command(
        "model",
        "high",
        tmp_path,
        "-",
        output_schema=tmp_path / "schema.json",
        output_last_message=tmp_path / "message.json",
        sandbox="workspace-write",
    )
    assert command[-1] == "-"
    assert "--output-schema" in command
    assert "--output-last-message" in command
    assert command[command.index("--sandbox") + 1] == "workspace-write"


@pytest.mark.parametrize(
    "plan",
    [
        None,
        {},
        {"tasks": "not-list"},
    ],
)
def test_validate_plan_rejects_missing_plan_shapes(plan):
    with pytest.raises(_errors()):
        orchestrator.validate_plan(plan, 3)


@pytest.mark.parametrize(
    "mutation",
    [
        lambda plan: plan["tasks"].__setitem__(0, "not-an-object"),
        lambda plan: plan["tasks"][0].pop("instructions"),
        lambda plan: plan["tasks"][0].update(id="bad id"),
        lambda plan: plan["tasks"][0].update(instructions=""),
        lambda plan: plan["tasks"][0].update(acceptance=[]),
        lambda plan: plan["tasks"][0].update(write_scope=[]),
        lambda plan: plan["tasks"][0].update(checks=[]),
        lambda plan: plan["tasks"][0].update(checks=[["git", "push"]]),
    ],
)
def test_validate_plan_rejects_each_invalid_task_field(mutation):
    plan = _task_plan()
    mutation(plan)
    with pytest.raises(_errors()):
        orchestrator.validate_plan(plan, 3)


def test_validate_plan_supports_legacy_scope_and_deduplicates_it():
    plan = _task_plan()
    for index, task in enumerate(plan["tasks"]):
        task.pop("write_scope")
        task["scope"] = [f"src/task-{index}.py", f"src/task-{index}.py"]
    normalized = orchestrator.validate_plan(plan, 3)
    assert normalized["tasks"][0]["write_scope"] == ["src/task-0.py"]
    assert normalized["tasks"][0]["instructions"] == "实现隔离任务"


def test_validate_plan_rejects_bad_task_count_and_non_list_scope():
    with pytest.raises(_errors()):
        orchestrator.validate_plan(_task_plan(2), 3)
    plan = _task_plan()
    plan["tasks"][0]["write_scope"] = "src/task-0.py"
    assert orchestrator.validate_plan(plan, 3)["tasks"][0]["write_scope"] == [
        "src/task-0.py"
    ]
    plan["tasks"][0]["write_scope"] = 123
    with pytest.raises(_errors()):
        orchestrator.validate_plan(plan, 3)


def test_batch_details_handles_mapping_results_invalid_files_and_status_conflicts():
    plan = _task_plan()
    passing = _passing_results(plan)
    mapped = {item["task_id"]: {**item, "task_id": None} for item in passing}
    decision, reasons, retries = orchestrator._batch_details(plan, mapped)
    assert decision == "accept"
    assert reasons == []
    assert retries == []

    decision, reasons, _ = orchestrator._batch_details(plan, {"results": passing})
    assert decision == "accept"
    assert reasons == []
    assert orchestrator._result_items("bad results") == []

    invalid = _passing_results(plan)
    invalid[0]["changed_files"] = [123, "../outside"]
    decision, reasons, _ = orchestrator._batch_details(plan, invalid)
    assert decision == "escalate_sol"
    assert any("changed_files 无效" in reason for reason in reasons)
    assert any("changed_files 越界" in reason for reason in reasons)

    conflicting = _passing_results(plan)
    conflicting[0]["status"] = "unknown"
    decision, reasons, _ = orchestrator._batch_details(plan, conflicting)
    assert decision == "escalate_sol"
    assert reasons == ["task 输出状态冲突"]

    decision, reasons, _ = orchestrator._batch_details({}, passing)
    assert decision == "escalate_sol"
    assert reasons == ["计划证据缺失"]
    assert orchestrator.GateDecision("accept")["decision"] == "accept"


def test_batch_details_supports_attempts_remaining_and_checks_ok_failure():
    plan = _task_plan()
    results = _passing_results(plan)
    results[0].update(checks_ok=False, attempts_remaining=True)
    decision, reasons, retry_tasks = orchestrator._batch_details(plan, results)
    assert decision == "retry_luna"
    assert retry_tasks == ["task-0"]
    assert "等待 Luna 修复" in reasons[0]

    results[0].update(attempts_remaining=False, retry_count=1, max_retries=1)
    decision, reasons, retry_tasks = orchestrator._batch_details(plan, results)
    assert decision == "escalate_sol"
    assert retry_tasks == []
    assert "测试失败且重试耗尽" in reasons[0]


@pytest.mark.parametrize(
    "raw, expected",
    [
        ('```json\n{"value": 1}\n```', {"value": 1}),
        ('prefix\n{"value": 2}\ntrailer', {"value": 2}),
        ('noise\n[1, 2]', [1, 2]),
    ],
)
def test_parse_json_accepts_fenced_line_and_embedded_json(raw, expected):
    assert orchestrator._parse_json(raw) == expected


def test_parse_json_and_token_count_report_invalid_or_nested_data():
    with pytest.raises(ValueError, match="没有输出"):
        orchestrator._parse_json("  ")
    with pytest.raises(ValueError, match="有效 JSON"):
        orchestrator._parse_json("not json")
    assert orchestrator._token_count({"nested": [{"tokens": 7}]}) == 7
    assert orchestrator._token_count({"tokens": "7"}) is None
    assert orchestrator._token_count([{"totalTokens": 9}]) == 9
    assert orchestrator._token_count("not structured") is None


def test_call_codex_uses_response_file_and_records_token_count(tmp_path, monkeypatch):
    run_dir = tmp_path / "run"
    call_log = run_dir / "calls.jsonl"

    def fake_run(argv, **kwargs):
        output_path = Path(argv[argv.index("--output-last-message") + 1])
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps({"tokens": 11, "ok": True}), encoding="utf-8")
        return subprocess.CompletedProcess(argv, 0, stdout="ignored", stderr="")

    monkeypatch.setattr(orchestrator, "_run", fake_run)
    process, raw = orchestrator._call_codex(
        "model",
        "prompt",
        tmp_path,
        run_dir,
        call_log,
        "coverage-call",
    )
    assert process.returncode == 0
    assert json.loads(raw)["tokens"] == 11
    record = json.loads(call_log.read_text().strip())
    assert record["kind"] == "coverage-call"
    assert record["tokens"] == 11


def test_call_codex_falls_back_to_stdout_when_response_is_invalid(tmp_path, monkeypatch):
    call_log = tmp_path / "calls.jsonl"
    monkeypatch.setattr(
        orchestrator,
        "_run",
        lambda argv, **kwargs: subprocess.CompletedProcess(argv, 3, stdout="bad", stderr="oops"),
    )
    process, raw = orchestrator._call_codex(
        "model", "prompt", tmp_path, tmp_path / "run", call_log, "bad-call"
    )
    assert process.returncode == 3
    assert raw == "bad"
    assert json.loads(call_log.read_text().strip())["tokens"] is None


def test_status_paths_and_capture_patch_handle_untracked_and_diff_entries(tmp_path, monkeypatch):
    def fake_run(argv, **kwargs):
        if argv[:3] == ["git", "status", "--porcelain=v1"]:
            return subprocess.CompletedProcess(
                argv,
                0,
                stdout=" M changed.py\0?? new.py\0R  renamed.py\0old.py\0",
                stderr="",
            )
        if argv[:4] == ["git", "diff", "--name-only", "-z"]:
            return subprocess.CompletedProcess(argv, 0, stdout="diff-only.py\0", stderr="")
        if argv[1:3] == ["add", "-N"] or argv[1:2] == ["reset"]:
            return subprocess.CompletedProcess(argv, 0, stdout="", stderr="")
        if argv[1:3] == ["diff", "--binary"]:
            return subprocess.CompletedProcess(argv, 0, stdout="patch text\n", stderr="")
        raise AssertionError(argv)

    monkeypatch.setattr(orchestrator, "_run", fake_run)
    changed, status_raw, diff_names = orchestrator._status_paths(tmp_path)
    assert changed == ["changed.py", "diff-only.py", "new.py", "old.py", "renamed.py"]
    assert "new.py" in status_raw and "diff-only.py" in diff_names

    patch_path = tmp_path / "captured.patch"
    changed, _, error = orchestrator._capture_patch(tmp_path, patch_path)
    assert changed[0] == "changed.py"
    assert error == ""
    assert patch_path.read_text() == "patch text\n"


def test_capture_patch_fails_closed_when_intent_to_add_fails(tmp_path, monkeypatch):
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: (["new.py"], "?? new.py\0", ""))

    def fail_add(argv, **kwargs):
        assert argv[1:3] == ["add", "-N"]
        return subprocess.CompletedProcess(argv, 7, stdout="", stderr="cannot add")

    monkeypatch.setattr(orchestrator, "_run", fail_add)
    patch_path = tmp_path / "failed.patch"
    changed, _, error = orchestrator._capture_patch(tmp_path, patch_path)
    assert changed == ["new.py"]
    assert error == "cannot add"
    assert patch_path.read_text() == ""


def test_snapshot_and_checks_with_no_checks_is_not_successful(tmp_path, monkeypatch):
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: (["src/a.py"], "status", "diff"))

    def capture(_, path):
        path.write_text("patch", encoding="utf-8")
        return ["src/a.py"], "", ""

    monkeypatch.setattr(
        orchestrator,
        "_capture_patch",
        capture,
    )
    with pytest.raises(ValueError, match="cheap check 列表不能为空"):
        orchestrator._snapshot_and_checks(
            tmp_path, [], tmp_path / "patch", tmp_path / "checks.json"
        )


@pytest.mark.parametrize(
    "value, reason",
    [
        (None, "不是对象"),
        ({}, "有效 status"),
        ({"status": "pass"}, "summary"),
        ({"status": "pass", "summary": "ok"}, "changed_files"),
    ],
)
def test_validate_luna_output_rejects_each_missing_field(value, reason):
    valid, message = orchestrator._validate_luna_output(value)
    assert valid is False
    assert reason in message


def test_run_task_records_invalid_json_and_process_failure(tmp_path, monkeypatch):
    task = _task_plan()["tasks"][0]
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess(["codex"], 1, stdout="", stderr="failed"),
            "not json",
            [],
        ),
    )
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: {
            "changed_files": [],
            "status_raw": "",
            "diff_names": "",
            "patch_error": "",
            "check_results": [],
            "checks_ok": False,
        },
    )
    result = orchestrator._run_task(
        "request",
        task,
        tmp_path,
        tmp_path / "task-worktree",
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        1,
        SPEC_REF,
        MATRIX_EDGES,
    )
    assert result["status"] == "evidence_missing"
    assert result["attempts"][0]["output_valid"] is False
    assert "JSON" in result["reason"]


def test_run_task_rejects_actual_and_declared_out_of_scope_paths(tmp_path, monkeypatch):
    task = _task_plan()["tasks"][0]
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            json.dumps({"status": "pass", "summary": "ok", "changed_files": ["/tmp/out"]}),
            [],
        ),
    )
    monkeypatch.setattr(
        orchestrator,
        "_snapshot_and_checks",
        lambda *args, **kwargs: {
            "changed_files": ["other.py"],
            "status_raw": "status",
            "diff_names": "",
            "patch_error": "",
            "check_results": [],
            "checks_ok": True,
        },
    )
    result = orchestrator._run_task(
        "request",
        task,
        tmp_path,
        tmp_path / "task",
        tmp_path / "run",
        tmp_path / "calls",
        1,
        SPEC_REF,
        MATRIX_EDGES,
    )
    assert result["scope_ok"] is False
    assert result["attempts"][0]["outside_files"] == ["other.py"]
    assert result["attempts"][0]["declared_outside_files"] == ["/tmp/out"]
    assert result["reason"] == "越界或重叠编辑"


def test_run_task_exhausts_model_failure_and_check_failure(tmp_path, monkeypatch):
    task = _task_plan()["tasks"][0]
    responses = iter(
        [
            ("fail", True),
            ("pass", False),
        ]
    )

    def fake_call(*args, **kwargs):
        status, _ = next(responses)
        return (
            subprocess.CompletedProcess(["codex"], 0, stdout="", stderr=""),
            json.dumps({"status": status, "summary": status, "changed_files": []}),
            [],
        )

    def fake_snapshot(*args, **kwargs):
        _, checks_ok = fake_snapshot.states.pop(0)
        return {
            "changed_files": [],
            "status_raw": "status",
            "diff_names": "",
            "patch_error": "",
            "check_results": [],
            "checks_ok": checks_ok,
        }

    fake_snapshot.states = [("first", True), ("second", False)]
    monkeypatch.setattr(orchestrator, "_guarded_model_call", fake_call)
    monkeypatch.setattr(orchestrator, "_snapshot_and_checks", fake_snapshot)
    result = orchestrator._run_task(
        "request",
        task,
        tmp_path,
        tmp_path / "task",
        tmp_path / "run",
        tmp_path / "calls",
        1,
        SPEC_REF,
        MATRIX_EDGES,
    )
    assert result["status"] == "test_failure"
    assert result["attempts_exhausted"] is True
    assert "明确报告失败" in result["reason"]


def test_workspace_info_accepts_clean_feature_root_and_rejects_state_errors(tmp_path, monkeypatch):
    calls = []

    def clean_run(argv, **kwargs):
        calls.append(argv)
        if argv[:2] == ["git", "rev-parse"] and argv[2] == "--show-toplevel":
            return subprocess.CompletedProcess(argv, 0, stdout=f"{tmp_path}\n", stderr="")
        if argv[:2] == ["git", "symbolic-ref"]:
            return subprocess.CompletedProcess(argv, 0, stdout="feat/coverage\n", stderr="")
        if argv[:2] == ["git", "status"]:
            return subprocess.CompletedProcess(argv, 0, stdout="", stderr="")
        return subprocess.CompletedProcess(argv, 0, stdout="head\n", stderr="")

    monkeypatch.setattr(orchestrator, "_run", clean_run)
    workspace, branch, head = orchestrator._workspace_info(str(tmp_path))
    assert workspace == tmp_path.resolve()
    assert branch == "feat/coverage"
    assert head == "head"
    assert len(calls) == 4


@pytest.mark.parametrize("case", ["not-dir", "root-fail", "root-mismatch", "detached", "main", "status-fail", "dirty", "head-fail"])
def test_workspace_info_fails_closed_for_each_invalid_state(tmp_path, monkeypatch, case):
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    other = tmp_path / "other"
    other.mkdir()

    def fake_run(argv, **kwargs):
        if case == "root-fail" and argv[:2] == ["git", "rev-parse"]:
            return subprocess.CompletedProcess(argv, 1, stdout="", stderr="bad root")
        if case == "root-mismatch" and argv[:2] == ["git", "rev-parse"]:
            return subprocess.CompletedProcess(argv, 0, stdout=f"{other}\n", stderr="")
        if argv[:2] == ["git", "rev-parse"] and argv[2] == "--show-toplevel":
            return subprocess.CompletedProcess(argv, 0, stdout=f"{workspace}\n", stderr="")
        if argv[:2] == ["git", "symbolic-ref"]:
            if case == "detached":
                return subprocess.CompletedProcess(argv, 1, stdout="", stderr="")
            branch = "main\n" if case == "main" else "feat/x\n"
            return subprocess.CompletedProcess(argv, 0, stdout=branch, stderr="")
        if argv[:2] == ["git", "status"]:
            if case == "status-fail":
                return subprocess.CompletedProcess(argv, 1, stdout="", stderr="")
            return subprocess.CompletedProcess(argv, 0, stdout=" M file\n" if case == "dirty" else "", stderr="")
        if case == "head-fail":
            return subprocess.CompletedProcess(argv, 1, stdout="", stderr="")
        return subprocess.CompletedProcess(argv, 0, stdout="head\n", stderr="")

    monkeypatch.setattr(orchestrator, "_run", fake_run)
    target = tmp_path / "missing" if case == "not-dir" else workspace
    with pytest.raises(orchestrator.BlockedError):
        orchestrator._workspace_info(str(target))


def test_primary_root_and_parent_guard_report_git_failures(tmp_path, monkeypatch):
    monkeypatch.setattr(
        orchestrator,
        "_run",
        lambda argv, **kwargs: subprocess.CompletedProcess(argv, 1, stdout="", stderr="bad"),
    )
    with pytest.raises(orchestrator.BlockedError, match="primary"):
        orchestrator._primary_worktree_root(tmp_path)
    with pytest.raises(orchestrator.BlockedError, match="状态"):
        orchestrator._assert_parent_unchanged(tmp_path, "head")


@pytest.mark.parametrize(
    "stdout, expected",
    [
        ("", "没有 primary"),
        ("worktree /missing\n", "不存在"),
    ],
)
def test_primary_worktree_root_rejects_missing_registry_entries(tmp_path, monkeypatch, stdout, expected):
    monkeypatch.setattr(
        orchestrator,
        "_run",
        lambda argv, **kwargs: subprocess.CompletedProcess(argv, 0, stdout=stdout, stderr=""),
    )
    with pytest.raises(orchestrator.BlockedError, match=expected):
        orchestrator._primary_worktree_root(tmp_path)


def test_parent_guard_rejects_dirty_or_changed_head(tmp_path, monkeypatch):
    responses = iter(
        [
            subprocess.CompletedProcess([], 0, stdout=" M file", stderr=""),
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
            subprocess.CompletedProcess([], 0, stdout="other", stderr=""),
        ]
    )
    monkeypatch.setattr(orchestrator, "_run", lambda *args, **kwargs: next(responses))
    with pytest.raises(orchestrator.BlockedError, match="发生变化"):
        orchestrator._assert_parent_unchanged(tmp_path, "head")

    responses = iter(
        [
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
            subprocess.CompletedProcess([], 0, stdout="other", stderr=""),
        ]
    )
    monkeypatch.setattr(orchestrator, "_run", lambda *args, **kwargs: next(responses))
    with pytest.raises(orchestrator.BlockedError, match="HEAD"):
        orchestrator._assert_parent_unchanged(tmp_path, "head")


def test_worktree_creation_and_patch_application_cover_success_and_failures(tmp_path, monkeypatch):
    seen = []

    def create_run(argv, **kwargs):
        seen.append(argv)
        return subprocess.CompletedProcess(argv, 0, stdout="", stderr="")

    monkeypatch.setattr(orchestrator, "_run", create_run)
    path = tmp_path / "nested" / "worktree"
    assert orchestrator._create_worktree(tmp_path, path) is True
    assert path.parent.is_dir()
    assert seen[0][0:4] == ["git", "worktree", "add", "--detach"]

    empty = tmp_path / "empty.patch"
    assert orchestrator._apply_patch(tmp_path, empty) == (True, "")
    nonempty = tmp_path / "patch"
    nonempty.write_text("diff", encoding="utf-8")
    responses = iter(
        [
            subprocess.CompletedProcess([], 1, stdout="check out", stderr=""),
        ]
    )
    monkeypatch.setattr(orchestrator, "_run", lambda *args, **kwargs: next(responses))
    assert orchestrator._apply_patch(tmp_path, nonempty) == (False, "check out")

    responses = iter(
        [
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
            subprocess.CompletedProcess([], 1, stdout="", stderr="apply out"),
        ]
    )
    monkeypatch.setattr(orchestrator, "_run", lambda *args, **kwargs: next(responses))
    assert orchestrator._apply_patch(tmp_path, nonempty) == (False, "apply out")

    responses = iter(
        [
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
            subprocess.CompletedProcess([], 0, stdout="applied", stderr=""),
        ]
    )
    monkeypatch.setattr(orchestrator, "_run", lambda *args, **kwargs: next(responses))
    assert orchestrator._apply_patch(tmp_path, nonempty) == (True, "applied")


def test_create_worktree_reports_command_failure(tmp_path, monkeypatch):
    monkeypatch.setattr(
        orchestrator,
        "_run",
        lambda argv, **kwargs: subprocess.CompletedProcess(argv, 1, stdout="", stderr="failed"),
    )
    assert orchestrator._create_worktree(tmp_path, tmp_path / "worktree") is False


def test_run_checks_logs_empty_and_failed_checks(tmp_path, monkeypatch):
    with pytest.raises(ValueError, match="全局 check 列表不能为空"):
        orchestrator._run_checks(tmp_path, [], tmp_path / "empty.json")

    monkeypatch.setattr(
        orchestrator,
        "_run_cheap_check",
        lambda _workspace, argv, **kwargs: subprocess.CompletedProcess(
            argv, 4, stdout="", stderr="failed"
        ),
    )
    ok, records = orchestrator._run_checks(
        tmp_path, [["pytest", "-q"]], tmp_path / "failed.json"
    )
    assert ok is False
    assert records[0]["returncode"] == 4
    assert json.loads((tmp_path / "failed.json").read_text())[0]["stderr"] == "failed"


def test_integration_prompt_contains_scope_checks_and_previous_result():
    plan = _task_plan()
    prompt = orchestrator._integration_prompt(
        "request",
        plan["tasks"],
        [["pytest", "-q"]],
        SPEC_REF,
        MATRIX_EDGES,
        {"status": "fail"},
        2,
    )
    assert "第 2 次集成修复尝试" in prompt
    assert "src/task-0.py" in prompt
    assert "pytest" in prompt
    assert '"status": "fail"' in prompt


def test_integration_repair_fails_when_creation_or_patch_application_fails(tmp_path, monkeypatch):
    plan, task_results, checks = _integration_inputs(tmp_path)
    created = []
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: False)
    result = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls",
        checks,
        1,
        created,
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime",
    )
    assert result["status"] == "evidence_missing"
    assert "创建" in result["reason"]
    assert created == []

    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda *args: (False, "conflict"))
    result = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run2",
        tmp_path / "calls2",
        checks,
        1,
        created,
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime2",
    )
    assert result["conflict"] is True
    assert "conflict" in result["reason"]


def test_integration_repair_rejects_initial_out_of_scope_changes(tmp_path, monkeypatch):
    plan, task_results, checks = _integration_inputs(tmp_path)
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda *args: (True, ""))
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args: (True, [{"returncode": 0}]))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: (["outside.py"], "", ""))
    result = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls",
        checks,
        1,
        [],
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime",
    )
    assert result["status"] == "evidence_missing"
    assert result["conflict"] is True
    assert result["outside_files"] == ["outside.py"]


def test_integration_repair_passes_initial_checks_or_reports_capture_error(tmp_path, monkeypatch):
    plan, task_results, checks = _integration_inputs(tmp_path)
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda *args: (True, ""))
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args: (True, [{"returncode": 0}]))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: ([], "", ""))
    monkeypatch.setattr(orchestrator, "_capture_patch", lambda *args: ([], "", "patch error"))
    result = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls",
        checks,
        1,
        [],
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime",
    )
    assert result["status"] == "evidence_missing"
    assert result["patch_error"] == "patch error"


@pytest.mark.parametrize("raw, returncode", [("bad", 0), ("{}", 1)])
def test_integration_repair_rejects_invalid_luna_evidence(tmp_path, monkeypatch, raw, returncode):
    plan, task_results, checks = _integration_inputs(tmp_path)
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda *args: (True, ""))
    monkeypatch.setattr(
        orchestrator,
        "_run_checks",
        lambda *args: (False, [{"returncode": 1}]),
    )
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: ([], "", ""))
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess([], returncode, stdout="", stderr=""),
            raw,
            [],
        ),
    )
    result = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls",
        checks,
        1,
        [],
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime",
    )
    assert result["status"] == "evidence_missing"
    assert result["evidence_complete"] is False


def test_integration_repair_rejects_scope_after_repair_and_patch_capture_error(tmp_path, monkeypatch):
    plan, task_results, checks = _integration_inputs(tmp_path)
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda *args: (True, ""))
    statuses = iter(
        [
            ([], "", ""),
            ([], "", ""),
            (["outside.py"], "", ""),
            (["outside.py"], "", ""),
        ]
    )
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: next(statuses))
    monkeypatch.setattr(
        orchestrator,
        "_path_diff_fingerprint",
        lambda _worktree, path: f"fingerprint:{path}",
    )
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args: (False, [{"returncode": 1}]))
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
            json.dumps({"status": "pass", "summary": "fixed", "changed_files": []}),
            [],
        ),
    )
    result = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls",
        checks,
        1,
        [],
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime",
    )
    assert result["reason"] == "集成修复越界"
    assert result["attempts"][0]["outside_files"] == ["outside.py"]

    statuses = iter([([], "", "")] * 5)
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: next(statuses))
    checks_results = iter(
        [(False, [{"returncode": 1}]), (True, [{"returncode": 0}])]
    )
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args: next(checks_results))
    monkeypatch.setattr(orchestrator, "_capture_patch", lambda *args: ([], "", "capture failed"))
    result = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run2",
        tmp_path / "calls2",
        checks,
        2,
        [],
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime2",
    )
    assert result["patch_error"] == "capture failed"


def test_integration_repair_exhausts_model_failure_after_successful_checks(tmp_path, monkeypatch):
    plan, task_results, checks = _integration_inputs(tmp_path)
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda *args: (True, ""))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: ([], "", ""))
    checks_results = iter(
        [(False, [{"returncode": 1}]), (True, [{"returncode": 0}])]
    )
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args: next(checks_results))
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
            json.dumps({"status": "fail", "summary": "still broken", "changed_files": []}),
            [],
        ),
    )
    result = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls",
        checks,
        1,
        [],
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime",
    )
    assert result["status"] == "test_failure"
    assert "明确报告失败" in result["reason"]


def test_sol_escalation_and_catalog_probe_cover_response_and_fallback_paths(tmp_path, monkeypatch):
    def fake_call(*args, **kwargs):
        kwargs["output_last_message"].parent.mkdir(parents=True, exist_ok=True)
        kwargs["output_last_message"].write_text("{}", encoding="utf-8")
        return subprocess.CompletedProcess([], 0, stdout="", stderr=""), "{}", []

    monkeypatch.setattr(orchestrator, "_guarded_model_call", fake_call)
    result = orchestrator._sol_escalation(
        "missing evidence",
        {"id": 1},
        tmp_path,
        tmp_path / "run",
        tmp_path / "calls.jsonl",
        SPEC_REF,
        MATRIX_EDGES,
    )
    assert result["returncode"] == 0
    assert result["reason"] == "missing evidence"
    assert Path(result["response_file"]).exists()

    monkeypatch.setattr(
        orchestrator,
        "_run",
        lambda argv, **kwargs: subprocess.CompletedProcess(argv, 0, stdout="", stderr="not json"),
    )
    process, catalog = orchestrator._probe_catalog()
    assert process.returncode == 0
    assert catalog == "not json"


def test_cli_probe_gate_request_and_checks_report_expected_codes(tmp_path, capsys):
    catalog = tmp_path / "catalog.json"
    catalog.write_text(
        json.dumps(
            {
                "models": [
                    {"slug": orchestrator.SOL_MODEL, "supported_reasoning_efforts": ["xhigh"]},
                    {"slug": orchestrator.LUNA_MODEL, "supported_reasoning_efforts": ["xhigh"]},
                ]
            }
        ),
        encoding="utf-8",
    )
    assert orchestrator.main(["probe", "--catalog", str(catalog)]) == 0
    assert '"accepted": true' in capsys.readouterr().out

    manifest = tmp_path / "manifest.json"
    plan = _task_plan()
    manifest.write_text(json.dumps({"plan": plan, "results": _passing_results(plan)}), encoding="utf-8")
    args = SimpleNamespace(manifest=None, manifest_option=str(manifest))
    assert orchestrator._cmd_gate(args) == 0
    assert capsys.readouterr().out.strip() == "accept"
    assert orchestrator._cmd_gate(SimpleNamespace(manifest=None, manifest_option=None)) == 2

    request_file = tmp_path / "request.md"
    request_file.write_text("  request text  ", encoding="utf-8")
    assert orchestrator._read_request(SimpleNamespace(request=None, request_file=str(request_file))) == "request text"
    with pytest.raises(ValueError):
        orchestrator._read_request(SimpleNamespace(request="a", request_file=str(request_file)))
    with pytest.raises(ValueError):
        orchestrator._read_request(SimpleNamespace(request=None, request_file=None))
    assert orchestrator._read_checks(['["pytest", "-q"]']) == [["pytest", "-q"]]
    with pytest.raises(ValueError):
        orchestrator._read_checks(["not-json"])
    with pytest.raises(ValueError):
        orchestrator._read_checks(['[""]'])


def test_cli_run_converts_blocked_and_value_errors_to_json(monkeypatch, capsys):
    monkeypatch.setattr(
        orchestrator,
        "_run_orchestration",
        lambda args: (_ for _ in ()).throw(orchestrator.BlockedError("blocked")),
    )
    code = orchestrator._cmd_run(SimpleNamespace())
    assert code == 20
    assert json.loads(capsys.readouterr().out)["verdict"] == "blocked"

    monkeypatch.setattr(
        orchestrator,
        "_run_orchestration",
        lambda args: (_ for _ in ()).throw(ValueError("invalid")),
    )
    code = orchestrator._cmd_run(SimpleNamespace())
    assert code == 2
    assert json.loads(capsys.readouterr().out)["reason"] == "invalid"

    monkeypatch.setattr(orchestrator, "_run_orchestration", lambda args: (0, {"ok": True}))
    assert orchestrator._cmd_run(SimpleNamespace()) == 0
    assert json.loads(capsys.readouterr().out) == {"ok": True}


def test_run_orchestration_rejects_argument_boundaries_before_workspace_access(tmp_path):
    base = SimpleNamespace(
        request="request",
        request_file=None,
        workspace=str(tmp_path),
        workers=3,
        max_luna_attempts=1,
        check=[],
    )
    for field, value in [("workers", 2), ("workers", 6), ("max_luna_attempts", 0)]:
        args = SimpleNamespace(**vars(base))
        setattr(args, field, value)
        with pytest.raises(ValueError):
            orchestrator._run_orchestration(args)

    args = SimpleNamespace(**vars(base))
    args.check = ["not-json"]
    with pytest.raises(ValueError):
        orchestrator._run_orchestration(args)
    args.check = ['["git", "push"]']
    with pytest.raises(ValueError):
        orchestrator._run_orchestration(args)


def test_run_orchestration_rejects_primary_workspace_and_probe_failure(tmp_path, monkeypatch):
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    spec = tmp_path / SPEC_REF
    spec.parent.mkdir(parents=True)
    spec.write_text(
        "# Spec\n\n" + "\n".join(f"{edge.replace('M-', 'FR-')}" for edge in MATRIX_EDGES),
        encoding="utf-8",
    )
    matrix = tmp_path / MATRIX_REF
    matrix.parent.mkdir(parents=True)
    matrix.write_text(
        "| Edge ID | FR |\n|---|---|\n"
        + "".join(f"| {edge} | FR-001 |\n" for edge in MATRIX_EDGES),
        encoding="utf-8",
    )
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    subprocess.run(
        [
            "git",
            "-c",
            "user.name=test",
            "-c",
            "user.email=test@example.invalid",
            "commit",
            "-qm",
            "fixture",
        ],
        cwd=tmp_path,
        check=True,
    )
    args = SimpleNamespace(
        request="request",
        request_file=None,
        workspace=str(tmp_path),
        workers=3,
        max_luna_attempts=1,
        check=['["pytest", "-q"]'],
        spec_ref=SPEC_REF,
        matrix_ref=MATRIX_REF,
        matrix_edge=MATRIX_EDGES,
    )
    monkeypatch.setattr(orchestrator, "_workspace_info", lambda _: (tmp_path, "feat/x", "head"))
    monkeypatch.setattr(orchestrator, "_primary_worktree_root", lambda _: tmp_path)
    with pytest.raises(orchestrator.BlockedError, match="primary"):
        orchestrator._run_orchestration(args)


def test_run_normalizes_dots_and_handles_subprocess_success_and_timeout(tmp_path, monkeypatch):
    assert orchestrator.normalize_scope("src//./") == "src/"
    assert orchestrator.normalize_scope(".") == "."
    assert orchestrator.path_in_scope("src/file.py", ".") is True
    assert orchestrator.scopes_overlap(".", "outside/") is True

    def successful_run(command, **kwargs):
        assert command == ["git", "status"]
        assert kwargs["shell"] is False
        return subprocess.CompletedProcess(command, 0, stdout="ok", stderr="")

    monkeypatch.setattr(subprocess, "run", successful_run)
    result = orchestrator._run(["git", "status"], cwd=tmp_path, input_text="input")
    assert result.stdout == "ok"
    assert result.returncode == 0

    def timeout_run(command, **kwargs):
        raise subprocess.TimeoutExpired(command, kwargs["timeout"], output=b"partial", stderr=b"late")

    monkeypatch.setattr(subprocess, "run", timeout_run)
    result = orchestrator._run(["git", "status"], cwd=tmp_path, timeout=2)
    assert result.returncode == 124
    assert result.stdout == "partial"
    assert "late" in result.stderr


def test_validate_plan_covers_worker_duplicate_and_overlap_guards():
    with pytest.raises(ValueError, match="3 到 5"):
        orchestrator.validate_plan(_task_plan(), 2)
    with pytest.raises(ValueError, match="3 到 5"):
        orchestrator.validate_plan(_task_plan(), 6)

    duplicate = _task_plan()
    duplicate["tasks"][1]["id"] = duplicate["tasks"][0]["id"]
    with pytest.raises(ValueError, match="重复"):
        orchestrator.validate_plan(duplicate, 3)

    overlap = _task_plan()
    overlap["tasks"][0]["write_scope"] = ["src/"]
    with pytest.raises(ValueError, match="重叠"):
        orchestrator.validate_plan(overlap, 3)


def test_batch_details_covers_explicit_evidence_and_overlap_reasons():
    plan = _task_plan()
    cases = [
        {"scope_ok": False},
        {"conflict": True},
        {"uncertainties": ["unknown"]},
        {"evidence_complete": False},
        {"test_failed": True, "retry_count": 1, "max_retries": 1},
    ]
    for mutation in cases:
        results = _passing_results(plan)
        results[0].update(mutation)
        decision, reasons, _ = orchestrator._batch_details(plan, results)
        assert decision == "escalate_sol"
        assert reasons

    results = _passing_results(plan)
    results[0]["changed_files"] = ["src/shared.py"]
    results[1]["changed_files"] = ["src/shared.py"]
    decision, reasons, _ = orchestrator._batch_details(plan, results)
    assert decision == "escalate_sol"
    assert any("实际编辑重叠" in reason for reason in reasons)


def test_schema_builders_describe_all_structured_outputs():
    plan_schema = orchestrator._sol_plan_output_schema()
    escalation_schema = orchestrator._sol_escalation_schema()
    assert plan_schema["properties"]["tasks"]["minItems"] == orchestrator.MIN_EXECUTORS
    assert plan_schema["properties"]["tasks"]["maxItems"] == orchestrator.MAX_EXECUTORS
    assert plan_schema["properties"]["tasks"]["items"]["properties"]["checks"]["minItems"] == 1
    assert escalation_schema["required"] == ["decision", "reason", "missing_evidence"]
    assert escalation_schema["properties"]["decision"]["enum"] == ["blocked", "escalate_sol"]


def test_run_task_passes_after_valid_output_and_retries_check_failure(tmp_path, monkeypatch):
    task = _task_plan()["tasks"][0]
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
            json.dumps({"status": "pass", "summary": "done", "changed_files": []}),
            [],
        ),
    )
    snapshots = iter([False, True])

    def fake_snapshot(*args, **kwargs):
        checks_ok = next(snapshots)
        return {
            "changed_files": [],
            "status_raw": "status",
            "diff_names": "",
            "patch_error": "",
            "check_results": [{"returncode": 0 if checks_ok else 1}],
            "checks_ok": checks_ok,
        }

    monkeypatch.setattr(orchestrator, "_snapshot_and_checks", fake_snapshot)
    result = orchestrator._run_task(
        "request",
        task,
        tmp_path,
        tmp_path / "task",
        tmp_path / "run",
        tmp_path / "calls",
        2,
        SPEC_REF,
        MATRIX_EDGES,
    )
    assert result["status"] == "pass"
    assert len(result["attempts"]) == 2
    assert result["attempts"][0]["checks_ok"] is False


def test_integration_repair_passes_initially_and_after_repair(tmp_path, monkeypatch):
    plan, task_results, checks = _integration_inputs(tmp_path)
    monkeypatch.setattr(orchestrator, "_create_worktree", lambda *args: True)
    monkeypatch.setattr(orchestrator, "_apply_patch", lambda *args: (True, ""))
    monkeypatch.setattr(orchestrator, "_status_paths", lambda _: ([], "", ""))
    monkeypatch.setattr(orchestrator, "_capture_patch", lambda _, path: ([], "", ""))
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args: (True, [{"returncode": 0}]))
    primary = tmp_path / "primary"
    primary.mkdir()
    monkeypatch.setattr(orchestrator, "_primary_worktree_root", lambda _: primary)
    initial = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "initial-run",
        tmp_path / "calls",
        checks,
        1,
        [],
        SPEC_REF,
        MATRIX_EDGES,
        None,
    )
    assert initial["status"] == "pass"
    assert initial["evidence_complete"] is True
    assert Path(initial["patch_file"]).name == "combined.patch"

    checks_results = iter(
        [(False, [{"returncode": 1}]), (True, [{"returncode": 0}])]
    )
    monkeypatch.setattr(orchestrator, "_run_checks", lambda *args: next(checks_results))
    monkeypatch.setattr(
        orchestrator,
        "_guarded_model_call",
        lambda *args, **kwargs: (
            subprocess.CompletedProcess([], 0, stdout="", stderr=""),
            json.dumps({"status": "accepted", "summary": "fixed", "changed_files": []}),
            [],
        ),
    )
    repaired = orchestrator._integration_repair(
        "request",
        plan,
        task_results,
        tmp_path,
        tmp_path / "repair-run",
        tmp_path / "calls2",
        checks,
        1,
        [],
        SPEC_REF,
        MATRIX_EDGES,
        tmp_path / "runtime2",
    )
    assert repaired["status"] == "pass"
    assert repaired["reason"] == "集成修复后全局检查通过"


def test_model_supports_string_entries_and_schema_file_is_idempotent(tmp_path):
    catalog = {"models": [{"slug": "model", "reasoning_efforts": ["xhigh", {"xhigh": True}]}]}
    assert orchestrator.model_supports(catalog, "model", "xhigh") is True
    schema = {"type": "object"}
    first = orchestrator._schema_file(tmp_path, "schema.json", schema)
    second = orchestrator._schema_file(tmp_path, "schema.json", {"type": "changed"})
    assert first == second
    assert json.loads(first.read_text()) == schema


def test_cli_gate_rejects_manifest_without_plan_and_request_rejects_empty_file(tmp_path):
    malformed = tmp_path / "malformed.json"
    malformed.write_text(json.dumps({"results": []}), encoding="utf-8")
    args = SimpleNamespace(manifest=str(malformed), manifest_option=None)
    assert orchestrator._cmd_gate(args) == 2

    empty_request = tmp_path / "empty.md"
    empty_request.write_text("  \n", encoding="utf-8")
    with pytest.raises(ValueError, match="不能为空"):
        orchestrator._read_request(SimpleNamespace(request=None, request_file=str(empty_request)))
