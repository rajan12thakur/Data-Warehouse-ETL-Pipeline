/*
===============================================================================
Script: create_databases.sql

Purpose:
    Initialize the empty MySQL data warehouse foundation for the
    Data Warehouse ETL Pipeline project.

Description:
    This script creates three separate MySQL databases representing the
    major layers of the warehouse:

        1. retail_bronze
           Raw/source-preserving data.

        2. retail_silver
           Cleaned and standardized data.

        3. retail_gold
           Business-ready analytical data.

    At this stage, the databases are intentionally empty.
    No tables, source data, transformations, dimensions, or facts
    are created by this script.

Execution:
    Run this script when setting up a new development environment
    or when provisioning the warehouse databases.

Safety:
    This script does NOT drop existing databases.
    CREATE DATABASE IF NOT EXISTS is used so that re-running the
    script does not destroy existing data.

Dependencies:
    MySQL server must be running and the executing user must have
    sufficient privileges to create databases.

===============================================================================
*/


-- ============================================================================
-- BRONZE DATABASE
-- ============================================================================
-- Stores raw/source-preserving data in later ETL stages.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS retail_bronze
    CHARACTER SET utf8mb4;


-- ============================================================================
-- SILVER DATABASE
-- ============================================================================
-- Stores cleaned, standardized, and transformed data.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS retail_silver
    CHARACTER SET utf8mb4;


-- ============================================================================
-- GOLD DATABASE
-- ============================================================================
-- Stores business-ready analytical data.
-- The database is currently created empty.

CREATE DATABASE IF NOT EXISTS retail_gold
    CHARACTER SET utf8mb4;