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
        int: Number of affected rows

    Raises:
        mysql.connector.Error: Re-raises database errors (including trigger errors) for handling by caller
    """
    connection = None
    cursor = None
    try:
        connection = get_connection()
        if not connection:
            raise Error("Failed to establish database connection")

        cursor = connection.cursor()

        # Execute the query - triggers will fire during execution
        # If a trigger raises an error, this will raise mysql.connector.Error
        cursor.execute(sql, params or ())

        # Only commit if execute succeeded (no trigger errors)
        connection.commit()

        affected_rows = cursor.rowcount
        return affected_rows

    except Error as e:
        # Rollback on any error (including trigger errors)
        if connection:
            connection.rollback()
        print(f"Error executing update: {e}")
        print(f"SQL: {sql}")
        print(f"Params: {params}")
        # Re-raise the exception so calling code can handle it with specific error messages
        raise

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

def call_procedure(proc_name, params=None):
    """
    Call a stored procedure and return results.

    Args:
        proc_name (str): Name of the stored procedure
        params (tuple/list): Parameters for the procedure

    Returns:
        list: List of result sets (each result set is a list of dictionaries)
        None: If procedure call fails
    """
    connection = None
    cursor = None
    try:
        connection = get_connection()
        if not connection:
            return None

        cursor = connection.cursor(dictionary=True)
        cursor.callproc(proc_name, params or ())

        # Stored procedures can return multiple result sets
        results = []
        for result in cursor.stored_results():
            results.append(result.fetchall())

        connection.commit()
        return results

    except Error as e:
        if connection:
            connection.rollback()
        print(f"Error calling procedure: {e}")
        print(f"Procedure: {proc_name}")
        print(f"Params: {params}")
        return None

    finally:
        if cursor:
            cursor.close()
        if connection and connection.is_connected():
            connection.close()

def call_function(func_name, params):
    """
    Call a stored function and return the result.

    Args:
        func_name (str): Name of the stored function
        params (tuple/list): Parameters for the function

    Returns:
        The result of the function, or None if call fails
    """
    connection = None
    cursor = None
    try:
        connection = get_connection()
        if not connection:
            return None

        cursor = connection.cursor()

        # Build the SQL to call the function
        placeholders = ', '.join(['%s'] * len(params))
        sql = f"SELECT {func_name}({placeholders}) AS result"

        cursor.execute(sql, params)
        result = cursor.fetchone()

        return result[0] if result else None

    except Error as e:
        print(f"Error calling function: {e}")
        print(f"Function: {func_name}")
        print(f"Params: {params}")
        return None

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