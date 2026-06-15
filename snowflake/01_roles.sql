-- =============================================================================
-- 01_roles.sql - Snowflake Role Hierarchy for Fluidra Pro Analytics Platform
-- =============================================================================
-- Run as: SECURITYADMIN
-- Dependencies: None
-- =============================================================================

USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS DATA_ENGINEER_ROLE
  COMMENT = 'Data platform engineers - pipeline operations, RAW_DB write access';

CREATE ROLE IF NOT EXISTS DBT_DEV_ROLE
  COMMENT = 'dbt Cloud service account - DEV environment execution';

CREATE ROLE IF NOT EXISTS DBT_TEST_ROLE
  COMMENT = 'dbt Cloud service account - TEST environment execution';

CREATE ROLE IF NOT EXISTS DBT_PROD_ROLE
  COMMENT = 'dbt Cloud service account - PROD environment execution';

CREATE ROLE IF NOT EXISTS BI_ROLE
  COMMENT = 'Dashboard consumers (PM, Exec, Sales Ops) - read MARTS and REPORTING';

CREATE ROLE IF NOT EXISTS ANALYST_ROLE
  COMMENT = 'Data analysts - read all analytics layers for ad-hoc analysis';

-- Role Hierarchy
GRANT ROLE DATA_ENGINEER_ROLE TO ROLE SYSADMIN;
GRANT ROLE DBT_DEV_ROLE TO ROLE DATA_ENGINEER_ROLE;
GRANT ROLE DBT_TEST_ROLE TO ROLE DATA_ENGINEER_ROLE;
GRANT ROLE DBT_PROD_ROLE TO ROLE DATA_ENGINEER_ROLE;
GRANT ROLE BI_ROLE TO ROLE SYSADMIN;
GRANT ROLE ANALYST_ROLE TO ROLE BI_ROLE;
