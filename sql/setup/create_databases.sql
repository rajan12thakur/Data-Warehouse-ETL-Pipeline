/*
=================================================================
Data Warehouse ETL Pipeline - MySQL Database Initialization
=================================================================

Purpose:
    Creates the MySQL databases used for the Bronze, Silver,
    and Gold layers of the data warehouse.

Architecture:
    Bronze -> Raw source data
    Silver -> Cleaned and standardized data
    Gold   -> Business-ready analytical data

Database naming:
    retail_bronze
    retail_silver
    retail_gold

WARNING:
    This script drops and recreates the warehouse databases.
    Running this script will permanently delete existing data
    inside these databases.

    Use this script only for local development or when a full
    database reset is intentionally required.

=================================================================
*/

-- ===============================================================
-- BRONZE LAYER
-- Raw source data
-- ===============================================================

DROP DATABASE IF EXISTS retail_bronze;

CREATE DATABASE retail_bronze;


-- ===============================================================
-- SILVER LAYER
-- Cleaned and standardized data
-- ===============================================================

DROP DATABASE IF EXISTS retail_silver;

CREATE DATABASE retail_silver;


-- ===============================================================
-- GOLD LAYER
-- Business-ready analytical data
-- ===============================================================

DROP DATABASE IF EXISTS retail_gold;

CREATE DATABASE retail_gold;
