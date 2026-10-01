/*
===============================================================================
Script: create_databases.sql

Purpose:
    Initialize the empty MySQL data warehouse foundation for the
    Data Warehouse ETL Pipeline project.

Description:
    This script creates three separate MySQL databases representing the
    major layers of the data warehouse:

        1. dw_bronze
           Raw/source-preserving data.

        2. dw_silver
           Cleaned and standardized data.

        3. dw_gold
           Business-ready analytical data.

    At this stage, the databases are intentionally empty.
    No tables, source data, transformations, dimensions, or facts
    are created by this script.

Execution:
    This script is executed automatically by the Python database
    initialization script:

        scripts/setup_database.py

    It can also be executed directly using a MySQL client when required.

Safety:
    This script does NOT drop existing databases.

    CREATE DATABASE IF NOT EXISTS is used so that re-running the
    script does not destroy existing databases or their data.

Dependencies:
    - MySQL Server must be running.
    - The executing MySQL user must have sufficient privileges
      to create databases.

===============================================================================
*/


-- ============================================================================
-- BRONZE DATABASE
-- ============================================================================
-- Stores raw/source-preserving data during the Bronze ETL stage.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS dw_bronze
    CHARACTER SET utf8mb4;


-- ============================================================================
-- SILVER DATABASE
-- ============================================================================
-- Stores cleaned and standardized data during the Silver ETL stage.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS dw_silver
    CHARACTER SET utf8mb4;


-- ============================================================================
-- GOLD DATABASE
-- ============================================================================
-- Stores business-ready analytical data during the Gold ETL stage.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS dw_gold
    CHARACTER SET utf8mb4;