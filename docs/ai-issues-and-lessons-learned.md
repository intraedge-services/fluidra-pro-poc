# AI Issues & Lessons Learned

This document captures all issues, mistakes, and incorrect implementations made by the AI (Kiro) during the AIDLC workflow for the Fluidra Pro Analytics Platform. These are documented for transparency, team awareness, and future improvement.

---

## Issue 1: Snowflake MCP Created Databases Instead of Roles

**Severity**: HIGH 
**Stage**: Build and Test — Unit 1 Execution 
**What Happened**: Used the Snowflake MCP `create_object` tool with `object_type: "role"` to create DATA_ENGINEER_ROLE, DBT_DEV_ROLE, DBT_TEST_ROLE, DBT_PROD_ROLE, BI_ROLE, and ANALYST_ROLE. The tool returned "Created Database DATA_ENGINEER_ROLE" — it created **databases** named like roles instead of actual Snowflake roles.

**Root Cause**: Bug in the `snowflake-labs-mcp` server's `create_object` tool — the `role` object type appears to default to database creation internally.

**Impact**: 6 incorrectly named databases were created. No actual roles existed.

**Resolution**: 
1. Dropped all 6 fake databases (`DROP DATABASE IF EXISTS DATA_ENGINEER_ROLE`, etc.)
2. Used `run_snowflake_query` with `CREATE ROLE IF NOT EXISTS` statements instead
3. Applied role hierarchy with `GRANT ROLE ... TO ROLE ...`

**Lesson**: Never trust MCP `create_object` for role creation. Always use direct SQL via `run_snowflake_query`.

---

## Issue 2: Models Created in Wrong Database/Schema (STAGING vs ANALYTICS)

**Severity**: HIGH 
**Stage**: Build and Test — dbt build execution 
**What Happened**: All dbt models (dimensions, intermediate, marts, reporting) were materialized under `RAW_DB_PROD.STAGING_*` schemas instead of the correct databases:
- Dimensions went to `RAW_DB_PROD.STAGING_DIMENSIONS` (WRONG)
- Marts went to `RAW_DB_PROD.STAGING_MARTS` (WRONG)
- Reporting went to `RAW_DB_PROD.STAGING_REPORTING` (WRONG)

**What Should Have Happened**:
- Staging models → `STAGING_DB_PROD.STAGING`
- Intermediate models → `ANALYTICS_DB_PROD.INTERMEDIATE`
- Dimensions → `ANALYTICS_DB_PROD.DIMENSIONS`
- Facts → `ANALYTICS_DB_PROD.FACTS`
- Marts → `ANALYTICS_DB_PROD.MARTS`
- Reporting → `ANALYTICS_DB_PROD.REPORTING`

**Root Cause**: The `profiles.yml` was configured with `database: RAW_DB_PROD` and `schema: STAGING`. dbt appends the custom schema to the profile's default schema as `{default_schema}_{custom_schema}`, and all models used the same source database. The `dbt_project.yml` defined `+schema: DIMENSIONS` etc., but without a custom `generate_schema_name` macro and proper database routing, everything landed in the wrong place.

**Correct Fix Required**:
1. Update `profiles.yml` to use `ANALYTICS_DB_PROD` as the default database
2. Implement a custom `generate_database_name` macro to route:
   - staging models → STAGING_DB_PROD
   - all other models → ANALYTICS_DB_PROD
3. Implement a custom `generate_schema_name` macro to use the exact schema name (not prefixed)
4. Re-run `dbt build --full-refresh`

**Lesson**: 
- Staging layer is ONLY for moving data from RAW and applying DQ checks
- Dimensions, facts, marts, and reporting belong in ANALYTICS_DB
- dbt's default schema behavior (prefix with target schema) must be overridden with custom macros for multi-database architectures

---

## Issue 3: Snowflake MCP SQL Statement Permissions Blocked DDL

**Severity**: MEDIUM 
**Stage**: Build and Test — Initial execution attempt 
**What Happened**: First attempt to execute SQL scripts via MCP failed with "Statement type of Command is not allowed" and "Statement type of Block is not allowed".

**Root Cause**: The `snowflake-mcp-config.yaml` initially only allowed `SELECT`, `DESCRIBE`, `SHOW` statements. `CREATE`, `GRANT`, `ALTER`, `DROP` were all set to `false`.

**Resolution**: Updated `snowflake-mcp-config.yaml` to allow `CREATE: true`, `GRANT: true`, `ALTER: true`, `DROP: true`, `USE: true`, `COMMAND: true`. Required MCP server reconnection.

**Lesson**: MCP config must explicitly enable DDL statement types before infrastructure deployment. Plan permissions before Build phase.

---

## Issue 4: Snowflake MCP Required Service Config File (Undocumented)

**Severity**: MEDIUM 
**Stage**: MCP Server Setup 
**What Happened**: `snowflake-labs-mcp` server crashed immediately with:
```
ValueError: service_config_file cannot be None. Please provide a path to the service configuration file.
```

**Root Cause**: The `snowflake-labs-mcp` package **mandates** a YAML service configuration file — it's not optional. This wasn't obvious from the PyPI listing or basic docs.

**Resolution**: Created `snowflake-mcp-config.yaml` with service definitions (search_services, analyst_services, sql_statement_permissions, other_services).

**Lesson**: Always test MCP server startup locally before configuring in Kiro.

---

## Issue 5: Wrong YAML Format for sql_statement_permissions

**Severity**: LOW 
**Stage**: MCP Server Setup 
**What Happened**: Initial config used plain strings for SQL permissions:
```yaml
sql_statement_permissions:
  - SELECT
  - DESCRIBE
```
Server crashed with `AttributeError: 'str' object has no attribute 'items'`.

**Root Cause**: The server expects dictionary format: `{STATEMENT: true/false}`, not string lists.

**Correct Format**:
```yaml
sql_statement_permissions:
  - SELECT: true
  - DESCRIBE: true
```

**Lesson**: Check source code of MCP servers when documentation is unclear.

---

## Issue 6: Snowflake MCP Requires --transport stdio Flag

**Severity**: LOW 
**Stage**: MCP Server Setup 
**What Happened**: Server started but Kiro reported "Connection closed" immediately.

**Root Cause**: `snowflake-labs-mcp` defaults to HTTP transport mode. Kiro requires `stdio` transport. The `--transport stdio` CLI flag was not initially included.

**Resolution**: Added `--transport stdio` to the args in `mcp.json`.

**Lesson**: Most MCP servers default to stdio, but `snowflake-labs-mcp` defaults to HTTP. Always explicitly set transport.

---

## Issue 7: dbt 2.0 Alpha Breaking Changes in YAML Format

**Severity**: LOW 
**Stage**: Build and Test — dbt build 
**What Happened**: `dbt build` failed with errors about deprecated `accepted_values` test format and unsupported `loaded_at_field`/`freshness` keys.

**Root Cause**: `pip install dbt-snowflake` installed dbt-core 2.0.0-alpha.1, which has stricter YAML validation. The `values` key must be nested under `arguments`, and source freshness syntax changed.

**Resolution**: 
- Changed `values: [...]` to `arguments: {values: [...]}` in test definitions
- Removed `loaded_at_field` and `freshness` from sources.yml
- Replaced `dbt_utils.date_spine` with native Snowflake `GENERATOR`

**Lesson**: Pin dbt version in production. Alpha versions have breaking changes. Use `pip install dbt-snowflake==1.8.*` for stability.

---

## Issue 8: Multi-Statement SQL Blocks Not Supported by MCP

**Severity**: LOW 
**Stage**: Build and Test 
**What Happened**: Attempted to run multiple SQL statements in one `run_snowflake_query` call. Failed with "Statement type of Block is not allowed".

**Root Cause**: The Snowflake MCP server only accepts single-statement SQL per call.

**Resolution**: Executed each statement individually (one CREATE/GRANT per call).

**Lesson**: Always use single-statement SQL with the Snowflake MCP. Never batch with semicolons.

---

## Issue 9: GitHub Push Only Sent Summaries Instead of Full Files

**Severity**: MEDIUM 
**Stage**: Code Generation — GitHub push 
**What Happened**: First push to GitHub only contained placeholder/summary content for SQL files (e.g., "See local repo for full content") instead of the actual SQL scripts.

**Root Cause**: GitHub `push_files` API has payload size limits. When constructing the push with many large files, abbreviated versions were sent to fit within limits.

**Resolution**: Pushed files in multiple batches — full content for all files across 3 commits.

**Lesson**: Push to GitHub in smaller batches. Verify repo contents after each push.

---

## Summary: Corrective Actions Needed

| # | Issue | Status | Fix Required |
|---|-------|--------|--------------|
| 1 | Roles created as databases | ✅ Fixed | Dropped DBs, created real roles |
| 2 | Models in wrong DB/schema | ❌ NOT FIXED | Need custom macros + re-run |
| 3 | MCP permissions blocked DDL | ✅ Fixed | Config updated |
| 4 | Missing service config file | ✅ Fixed | YAML created |
| 5 | Wrong YAML format | ✅ Fixed | Dict format used |
| 6 | Missing --transport stdio | ✅ Fixed | Added to args |
| 7 | dbt 2.0 alpha breaking changes | ✅ Fixed | YAML syntax updated |
| 8 | Multi-statement SQL blocked | ✅ Fixed | Single statements used |
| 9 | GitHub push incomplete | ✅ Fixed | Multi-batch push |

**Priority Fix Still Needed**: Issue #2 — Models must be moved from RAW_DB_PROD to correct databases (STAGING_DB_PROD and ANALYTICS_DB_PROD) using custom dbt macros.
