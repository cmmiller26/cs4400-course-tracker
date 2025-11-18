import mysql.connector
from mysql.connector import Error
from config import Config

def get_connection():
    """
    Create and return a MySQL database connection.
    
    Returns:
        connection: MySQL connection object or None if connection fails
    """
    try:
        connection = mysql.connector.connect(**Config.DB_CONFIG)
        if connection.is_connected():
            return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

def execute_query(sql, params=None, fetch_one=False):
    """
    Execute a SELECT query and return results.
    
    Args:
        sql (str): SQL query string with %s placeholders
        params (tuple/list): Parameters for the query
        fetch_one (bool): If True, return single row; if False, return all rows
    
    Returns:
        list/dict: Query results as list of dictionaries (or single dict if fetch_one=True)
        None: If query fails
    """
    connection = None
    cursor = None
    try:
        connection = get_connection()
        if not connection:
            return None
        
        # Use dictionary cursor to get results as dictionaries
        cursor = connection.cursor(dictionary=True)
        cursor.execute(sql, params or ())
        
        if fetch_one:
            result = cursor.fetchone()
        else:
            result = cursor.fetchall()
        
        return result
    
    except Error as e:
        print(f"Error executing query: {e}")
        print(f"SQL: {sql}")
        print(f"Params: {params}")
        return None
    
    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()

def execute_update(sql, params=None):
    """
    Execute an INSERT, UPDATE, or DELETE query.
    
    Args:
        sql (str): SQL query string with %s placeholders
        params (tuple/list): Parameters for the query
    
    Returns:
        int: Number of affected rows, or -1 if query fails
    """
    connection = None
    cursor = None
    try:
        connection = get_connection()
        if not connection:
            return -1
        
        cursor = connection.cursor()
        cursor.execute(sql, params or ())
        connection.commit()
        
        affected_rows = cursor.rowcount
        return affected_rows
    
    except Error as e:
        if connection:
            connection.rollback()
        print(f"Error executing update: {e}")
        print(f"SQL: {sql}")
        print(f"Params: {params}")
        return -1
    
    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()

def execute_transaction(queries):
    """
    Execute multiple queries in a single transaction.
    
    Args:
        queries (list): List of tuples (sql, params) to execute
    
    Returns:
        bool: True if all queries succeed, False otherwise
    """
    connection = None
    cursor = None
    try:
        connection = get_connection()
        if not connection:
            return False
        
        cursor = connection.cursor()
        
        # Execute all queries
        for sql, params in queries:
            cursor.execute(sql, params or ())
        
        # Commit transaction
        connection.commit()
        return True
    
    except Error as e:
        if connection:
            connection.rollback()
        print(f"Error executing transaction: {e}")
        return False
    
    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()

def test_connection():
    """
    Test database connection and print connection info.
    
    Returns:
        bool: True if connection successful, False otherwise
    """
    connection = get_connection()
    if connection and connection.is_connected():
        db_info = connection.get_server_info()
        print(f"Successfully connected to MySQL Server version {db_info}")
        cursor = connection.cursor()
        cursor.execute("SELECT DATABASE();")
        database = cursor.fetchone()
        print(f"Connected to database: {database[0]}")
        cursor.close()
        connection.close()
        return True
    else:
        print("Failed to connect to database")
        return False