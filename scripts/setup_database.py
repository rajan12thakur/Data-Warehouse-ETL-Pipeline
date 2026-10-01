"""
Automate MySQL data warehouse initialization.

This script:

1. Loads environment variables.
2. Reads MySQL connection settings.
3. Connects to the MySQL Server.
4. Locates the warehouse database initialization SQL file.
5. Executes the SQL statements.
6. Verifies the required databases.
7. Reports success or failure.

Design decision:
    SQL defines the database structure.
    Python automates the execution.
"""

from pathlib import Path
import os

import mysql.connector
from dotenv import load_dotenv


# ============================================================================
# CONFIGURATION
# ============================================================================

# Load environment variables from the project's .env file.
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")


# Databases that must exist after initialization.
EXPECTED_DATABASES = [
    "dw_bronze",
    "dw_silver",
    "dw_gold",
]


# ============================================================================
# PATHS
# ============================================================================

# Get the root directory of the project.
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Locate the SQL initialization script.
SQL_FILE = PROJECT_ROOT / "sql" / "setup" / "create_databases.sql"


# ============================================================================
# VALIDATION
# ============================================================================

def validate_configuration():
    """Validate required environment variables and SQL file."""

    required_variables = {
        "DB_HOST": DB_HOST,
        "DB_PORT": DB_PORT,
        "DB_USER": DB_USER,
        "DB_PASSWORD": DB_PASSWORD,
    }

    missing_variables = [
        name
        for name, value in required_variables.items()
        if not value
    ]

    if missing_variables:
        raise ValueError(
            "Missing required environment variables: "
            + ", ".join(missing_variables)
        )

    if not SQL_FILE.exists():
        raise FileNotFoundError(
            f"SQL initialization file was not found: {SQL_FILE}"
        )


# ============================================================================
# DATABASE INITIALIZATION
# ============================================================================

def initialize_databases():
    """Execute the SQL initialization script."""

    connection = None
    cursor = None

    try:
        print("Starting data warehouse initialization...")
        print()

        validate_configuration()

        print(f"SQL file: {SQL_FILE}")
        print(f"MySQL host: {DB_HOST}")
        print(f"MySQL port: {DB_PORT}")
        print(f"MySQL user: {DB_USER}")
        print()

        # Connect to the MySQL Server.
        # No database is specified because the databases themselves
        # are being created by this script.
        connection = mysql.connector.connect(
            host=DB_HOST,
            port=int(DB_PORT),
            user=DB_USER,
            password=DB_PASSWORD,
        )

        print("Connected to MySQL Server successfully.")
        print()

        cursor = connection.cursor()

        # Read the SQL initialization script.
        sql_script = SQL_FILE.read_text(encoding="utf-8")

        # Split the script into individual SQL statements.
        statements = [
            statement.strip()
            for statement in sql_script.split(";")
            if statement.strip()
        ]

        print("Executing database initialization SQL...")

        for statement in statements:
            cursor.execute(statement)

        print("Database initialization SQL executed successfully.")
        print()

        # Verify that all expected databases exist.
        print("Verifying databases...")

        for database in EXPECTED_DATABASES:
            cursor.execute(
                "SHOW DATABASES LIKE %s",
                (database,)
            )

            result = cursor.fetchone()

            if result is None:
                raise RuntimeError(
                    f"Database verification failed: {database}"
                )

            print(f"  ✓ {database}")

        print()
        print("Data warehouse initialization completed successfully.")

    except mysql.connector.Error as error:
        print()
        print(f"MySQL error: {error}")
        raise

    except (ValueError, FileNotFoundError, RuntimeError) as error:
        print()
        print(f"Initialization error: {error}")
        raise

    finally:
        if cursor is not None:
            cursor.close()

        if connection is not None and connection.is_connected():
            connection.close()
            print("MySQL connection closed.")


# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    initialize_databases()