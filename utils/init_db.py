#!/usr/bin/env python3
"""
Database Initialization Script for CourseTracker

This script initializes the CourseTracker database by executing SQL files in the correct order:
1. schema.sql - Creates all tables
2. auth_table.sql - Creates authentication table and test accounts
3. data.sql - Inserts sample data
4. views.sql - Creates database views
5. triggers.sql - Creates database triggers
6. procedures_functions.sql - Creates stored procedures and functions

Usage:
    python -m utils.init_db [--force]

Options:
    --force: Skip confirmation prompt and force re-initialization
"""

import os
import sys
import mysql.connector
from mysql.connector import Error
from config import Config

# SQL files to execute in order
# IMPORTANT: data.sql must come before auth_table.sql because auth references Student table
# Logic files (views, triggers) should run AFTER data is inserted to ensure data exists for them to act on.
SQL_FILES = [
    'schema.sql',
    'data.sql',
    'auth_table.sql',
    'views.sql',
    'triggers.sql',
    'procedures_functions.sql'
]

def get_database_dir():
    """Get the absolute path to the database directory."""
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)
    return os.path.join(project_root, 'database')

def read_sql_file(filepath):
    """
    Read SQL file and return its contents.

    Args:
        filepath (str): Path to SQL file

    Returns:
        str: Contents of SQL file
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f"ERROR: File not found: {filepath}")
        return None
    except Exception as e:
        print(f"ERROR: Failed to read {filepath}: {e}")
        return None

def execute_sql_statements(cursor, sql_content, filename):
    """
    Execute SQL statements from a file, handling DELIMITER statements.

    Args:
        cursor: MySQL cursor object
        sql_content (str): SQL content to execute
        filename (str): Name of the file (for error messages)

    Returns:
        bool: True if successful, False otherwise
    """
    try:
        # Replace any USE database statements with the correct database name from config
        import re
        db_name = Config.DB_CONFIG['database']

        # Remove DROP DATABASE, CREATE DATABASE, and DROP TABLE statements from SQL files
        # The init script handles database dropping/creation, and we're creating fresh tables
        sql_content = re.sub(
            r'DROP\s+DATABASE\s+IF\s+EXISTS\s+\w+\s*;',
            '',
            sql_content,
            flags=re.IGNORECASE
        )
        sql_content = re.sub(
            r'CREATE\s+DATABASE\s+\w+\s*;',
            '',
            sql_content,
            flags=re.IGNORECASE
        )
        # Remove DROP TABLE statements (single or multiple tables)
        sql_content = re.sub(
            r'DROP\s+TABLE\s+IF\s+EXISTS\s+[^;]+;',
            '',
            sql_content,
            flags=re.IGNORECASE
        )

        # Remove test/regression sections that are wrapped in START TRANSACTION...ROLLBACK
        # These are meant for manual testing, not automated initialization
        sql_content = re.sub(
            r'START\s+TRANSACTION;.*?ROLLBACK;',
            '',
            sql_content,
            flags=re.IGNORECASE | re.DOTALL
        )

        # Replace USE statements with the correct database name
        sql_content = re.sub(
            r'USE\s+\w+\s*;',
            f'USE {db_name};',
            sql_content,
            flags=re.IGNORECASE
        )

        # The `DELIMITER` command is a client-side directive and not valid SQL for the server.
        # We need to split the script by this directive and execute the chunks.
        # `multi=True` handles multiple statements separated by ';', but not custom delimiters.
        total_statements_executed = 0
        # Regex to split the script by "DELIMITER new_delimiter"
        delimiter_pattern = re.compile(r'DELIMITER\s+([^\s]+)', re.IGNORECASE)
        
        # Start with the default delimiter
        current_delimiter = ';'
        # Split the script into chunks based on where the delimiter is changed
        script_chunks = delimiter_pattern.split(sql_content)

        # The first chunk uses the default delimiter
        sql_chunk = script_chunks.pop(0)

        while sql_chunk is not None:
            # Execute statements in the current chunk
            statements = [s.strip() for s in sql_chunk.split(current_delimiter) if s.strip()]
            if statements:
                for stmt in statements:
                    results = cursor.execute(stmt, multi=True)
                    # Iterate through results to clear buffer and avoid "Commands out of sync"
                    for _ in results:
                        pass
                    total_statements_executed += 1

            # If there are more chunks, the next one is the new delimiter,
            # and the one after that is the next SQL chunk.
            if script_chunks:
                current_delimiter = script_chunks.pop(0)
                sql_chunk = script_chunks.pop(0)
            else:
                sql_chunk = None

        print(f"  ✓ Executed {total_statements_executed} statements.")

        return True

    except Exception as e:
        print(f"ERROR: Failed to execute {filename}: {e}")
        return False

def drop_database(cursor, db_name):
    """Drop the database if it exists."""
    try:
        # Check if database exists first
        cursor.execute("SHOW DATABASES LIKE %s", (db_name,))
        exists = cursor.fetchone()

        if exists:
            cursor.execute(f"DROP DATABASE {db_name}")
            print(f"✓ Dropped existing database: {db_name}")
        else:
            print(f"  Database '{db_name}' does not exist (this is normal for first-time setup)")

        return True
    except Error as e:
        print(f"ERROR: Failed to drop database: {e}")
        return False

def create_database(cursor, db_name):
    """Create the database."""
    try:
        cursor.execute(f"CREATE DATABASE IF NOT EXISTS {db_name}")
        print(f"✓ Created database: {db_name}")
        return True
    except Error as e:
        print(f"ERROR: Failed to create database: {e}")
        return False

def initialize_database(force=False):
    """
    Initialize the database by executing all SQL files.

    Args:
        force (bool): If True, skip confirmation prompt

    Returns:
        bool: True if successful, False otherwise
    """
    db_name = Config.DB_CONFIG['database']
    database_dir = get_database_dir()

    print("="*70)
    print("CourseTracker Database Initialization")
    print("="*70)
    print(f"Database: {db_name}")
    print(f"Host: {Config.DB_CONFIG['host']}")
    print(f"SQL Directory: {database_dir}")
    print("="*70)

    # Verify all SQL files exist
    missing_files = []
    for filename in SQL_FILES:
        filepath = os.path.join(database_dir, filename)
        if not os.path.exists(filepath):
            missing_files.append(filename)

    if missing_files:
        print("\nERROR: The following SQL files are missing:")
        for filename in missing_files:
            print(f"  - {filename}")
        return False

    # Confirmation prompt
    if not force:
        print("\n⚠️  WARNING: This will DROP and recreate the database!")
        print("   All existing data will be lost.")
        response = input("\nContinue? (yes/no): ").strip().lower()
        if response not in ['yes', 'y']:
            print("Aborted.")
            return False

    connection = None
    cursor = None

    try:
        # Connect without specifying database
        config = Config.DB_CONFIG.copy()
        config.pop('database', None)

        print("\nConnecting to MySQL server...")
        connection = mysql.connector.connect(**config)
        cursor = connection.cursor()
        print("✓ Connected to MySQL server")

        # Drop and create database
        print(f"\nPreparing database '{db_name}'...")
        if not drop_database(cursor, db_name):
            return False
        if not create_database(cursor, db_name):
            return False

        # Use the database
        cursor.execute(f"USE {db_name}")
        print(f"✓ Using database: {db_name}")

        # Execute SQL files in order
        print("\nExecuting SQL files...")
        for filename in SQL_FILES:
            filepath = os.path.join(database_dir, filename)
            print(f"\n[{filename}]")

            sql_content = read_sql_file(filepath)
            if sql_content is None:
                return False

            if not execute_sql_statements(cursor, sql_content, filename):
                return False

            connection.commit()
            print(f"✓ Successfully executed {filename}")

        print("\n" + "="*70)
        print("✓ Database initialization completed successfully!")
        print("="*70)
        print("\nTest accounts created:")
        print("  Student: username='teststudent', password='student123'")
        print("  Admin:   username='testadmin',   password='admin123'")
        print("="*70)

        return True

    except Error as e:
        print(f"\n✗ Database error: {e}")
        return False
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        return False
    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()
            print("\nDatabase connection closed.")

def main():
    """Main entry point."""
    force = '--force' in sys.argv or '-f' in sys.argv

    success = initialize_database(force=force)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
