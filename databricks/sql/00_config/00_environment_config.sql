-- Module: Environment/config/naming helpers
-- Scope: authoring-time configuration constants for phase-1 table/report generation only.
-- This file intentionally does not execute any Databricks DDL/DML.

-- Required target location for phase 1:
--   target_catalog = main
--   target_schema  = regtech_ops_stg
--   object_prefix  = bi_output_regtechops_
--
-- Guardrails:
-- 1) Do not create or alter objects in main.regtech in this phase.
-- 2) Every persistent object in main.regtech_ops_stg must start with bi_output_regtechops_.
-- 3) File-delivery/upload/response flow remains out of scope in this module.

