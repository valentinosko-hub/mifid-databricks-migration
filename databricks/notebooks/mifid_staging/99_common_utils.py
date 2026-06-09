# Databricks notebook source
"""Common helpers for MiFID staging notebook wrappers.

These wrappers are staging-only control surfaces around repository SQL templates.
They are intentionally conservative and do not execute SQL by default.
"""

from __future__ import annotations

from pathlib import Path
from typing import Dict, List


def _get_dbutils():
    try:
        return dbutils  # type: ignore[name-defined]
    except Exception:
        return None


def get_widget_or_default(name: str, default: str) -> str:
    utils = _get_dbutils()
    if not utils:
        return default
    try:
        return utils.widgets.get(name) or default
    except Exception:
        return default


def get_job_params() -> Dict[str, str]:
    return {
        "source_catalog": get_widget_or_default("source_catalog", "main"),
        "source_schema": get_widget_or_default("source_schema", "regtech"),
        "target_catalog": get_widget_or_default("target_catalog", "main"),
        "target_schema": get_widget_or_default("target_schema", "regtech_ops_stg"),
        "object_prefix": get_widget_or_default("object_prefix", "bi_output_regtechops_"),
        "report_date": get_widget_or_default("report_date", "YYYY-MM-DD"),
        "run_mode": get_widget_or_default("run_mode", "development_structural_test"),
        "dry_run": get_widget_or_default("dry_run", "true").lower(),
        "skip_delivery_steps": get_widget_or_default("skip_delivery_steps", "true").lower(),
        "allow_masked_customer_sources": get_widget_or_default(
            "allow_masked_customer_sources", "false"
        ).lower(),
        "require_unmasked_pii_for_parity": get_widget_or_default(
            "require_unmasked_pii_for_parity", "true"
        ).lower(),
        "enable_manual_seed_testing_checks": get_widget_or_default(
            "enable_manual_seed_testing_checks", "false"
        ).lower(),
        "enable_masked_customer_structural_tests": get_widget_or_default(
            "enable_masked_customer_structural_tests", "false"
        ).lower(),
        "staging_execution_approved": get_widget_or_default(
            "staging_execution_approved", "false"
        ).lower(),
    }


def validate_staging_params(params: Dict[str, str]) -> None:
    if params["target_catalog"] != "main":
        raise ValueError("Blocked: target_catalog must be 'main' for staging wrappers.")
    if params["target_schema"] != "regtech_ops_stg":
        raise ValueError("Blocked: target_schema must be 'regtech_ops_stg' for staging wrappers.")
    if params["target_schema"] == "regtech":
        raise ValueError("Blocked: target_schema='regtech' is production-targeting and forbidden.")
    if not params["object_prefix"].startswith("bi_output_regtechops_"):
        raise ValueError("Blocked: object_prefix must start with 'bi_output_regtechops_'.")
    if params["skip_delivery_steps"] != "true":
        raise ValueError("Blocked: skip_delivery_steps must remain true in this phase.")
    if params["run_mode"] != "development_structural_test":
        raise ValueError("Blocked: run_mode must be development_structural_test.")
    if params["dry_run"] not in ("true", "false"):
        raise ValueError("Blocked: dry_run must be true/false.")
    if params["dry_run"] == "false" and params["staging_execution_approved"] != "true":
        raise ValueError(
            "Blocked: dry_run=false requires staging_execution_approved=true for staging only."
        )
    print("Staging parameter guard PASS.")


def render_sql_template(sql_text: str, params: Dict[str, str]) -> str:
    rendered = sql_text
    for key, value in params.items():
        rendered = rendered.replace(f"{{{{{key}}}}}", value)
        rendered = rendered.replace(f"{{{{job.parameters.{key}}}}}", value)
    return rendered


def read_repo_sql_file(path: str) -> str:
    root = Path.cwd()
    repo_guess = root
    for _ in range(8):
        if (repo_guess / "databricks" / "sql").exists():
            break
        repo_guess = repo_guess.parent
    file_path = repo_guess / path
    if not file_path.exists():
        return f"-- TODO: SQL file not found in current context: {path}"
    return file_path.read_text(encoding="utf-8")


def print_planned_sql_files(label: str, files: List[str]) -> None:
    print(f"{label} planned SQL files ({len(files)}):")
    for idx, file in enumerate(files, 1):
        print(f"  {idx}. {file}")


def exit_status(status: str, message: str) -> None:
    payload = f"{status}: {message}"
    print(payload)
    utils = _get_dbutils()
    if utils:
        utils.notebook.exit(payload)


def maybe_run_sql_files(files: List[str], params: Dict[str, str], allow_execution: bool = False) -> None:
    print_planned_sql_files("Notebook wrapper", files)
    if not allow_execution:
        exit_status(
            "DRY_RUN",
            "Wrapper mode only. SQL execution is disabled by default; planned files listed above.",
        )
        return

    # Future guarded path: explicit opt-in only, still staging-only.
    validate_staging_params(params)
    if params["dry_run"] != "false":
        raise ValueError("Execution blocked: allow_execution requires dry_run=false.")
    if params["staging_execution_approved"] != "true":
        raise ValueError("Execution blocked: staging_execution_approved must be true.")
    if params["skip_delivery_steps"] != "true":
        raise ValueError("Execution blocked: skip_delivery_steps must remain true.")

    for path in files:
        sql_text = read_repo_sql_file(path)
        rendered = render_sql_template(sql_text, params)
        if "main.regtech." in rendered:
            raise ValueError(f"Execution blocked: potential production write/read coupling in {path}")
        if any(token in rendered.lower() for token in ("sftp", "trax", "cappitech", "upload", "response")):
            raise ValueError(f"Execution blocked: delivery/response token found in {path}")
        spark.sql(rendered)  # type: ignore[name-defined]  # guarded by explicit opt-in

    exit_status("PASS", "SQL files executed under explicit guarded staging mode.")
