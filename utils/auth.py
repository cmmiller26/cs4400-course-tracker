"""
Authentication utilities for CourseTracker application.

Provides password hashing, user authentication, and route protection decorators.
Uses werkzeug.security for password hashing with Flask's default method (pbkdf2:sha256).
"""

from functools import wraps
from flask import session, redirect, url_for, flash
from werkzeug.security import generate_password_hash, check_password_hash
from utils.db_connection import execute_query


def hash_password(password):
    """
    Hash a plaintext password using werkzeug's secure hashing.

    Uses Flask's default method: pbkdf2:sha256 with salt.

    Args:
        password (str): Plaintext password to hash

    Returns:
        str: Hashed password string

    Example:
        >>> hashed = hash_password('student123')
        >>> print(hashed)
        'scrypt:32768:8:1$...'
    """
    return generate_password_hash(password)


def verify_password(password_hash, password):
    """
    Verify a plaintext password against a stored hash.

    Args:
        password_hash (str): Stored password hash
        password (str): Plaintext password to verify

    Returns:
        bool: True if password matches, False otherwise

    Example:
        >>> hashed = hash_password('student123')
        >>> verify_password(hashed, 'student123')
        True
        >>> verify_password(hashed, 'wrong')
        False
    """
    return check_password_hash(password_hash, password)


def authenticate_user(username, password):
    """
    Authenticate a user by username and password.

    Queries the app_users table, retrieves user record, and verifies password.
    If student role, also retrieves student name from Student table.

    Args:
        username (str): Username to authenticate
        password (str): Plaintext password to verify

    Returns:
        dict: User information dict with keys:
            - user_id (int): User's ID
            - username (str): Username
            - role (str): 'student' or 'admin'
            - student_id (int or None): Linked student ID if role is 'student'
            - student_name (str or None): Student name if role is 'student'
        None: If authentication fails

    Example:
        >>> user = authenticate_user('teststudent', 'student123')
        >>> print(user['role'])
        'student'
        >>> print(user['student_id'])
        4001
    """
    # Query app_users table with LEFT JOIN to Student for name
    sql = """
        SELECT
            au.userId,
            au.username,
            au.password_hash,
            au.role,
            au.linked_id,
            s.name AS student_name
        FROM app_users au
        LEFT JOIN Student s ON au.linked_id = s.studentId
        WHERE au.username = %s
    """

    result = execute_query(sql, (username,), fetch_one=True)

    # Check if user exists
    if not result:
        return None

    # Verify password
    if not verify_password(result['password_hash'], password):
        return None

    # Return user information (excluding password hash)
    return {
        'user_id': result['userId'],
        'username': result['username'],
        'role': result['role'],
        'student_id': result['linked_id'],
        'student_name': result['student_name']
    }


def get_current_user():
    """
    Get currently logged-in user information from session.

    Returns:
        dict: User information from session with keys:
            - user_id (int)
            - username (str)
            - role (str)
            - student_id (int or None)
            - student_name (str or None)
        None: If no user is logged in

    Example:
        >>> user = get_current_user()
        >>> if user:
        >>>     print(f"Logged in as {user['username']}")
    """
    if 'user_id' not in session:
        return None

    return {
        'user_id': session.get('user_id'),
        'username': session.get('username'),
        'role': session.get('role'),
        'student_id': session.get('student_id'),
        'student_name': session.get('student_name')
    }


def login_required(role=None):
    """
    Decorator to protect routes that require authentication.

    Can optionally restrict to specific role (student or admin).
    If user is not logged in, redirects to login page.
    If user has wrong role, redirects to appropriate dashboard with error message.

    Args:
        role (str, optional): Required role ('student' or 'admin').
            If None, any logged-in user can access.

    Returns:
        function: Decorated function that checks authentication

    Usage:
        @app.route('/student/courses')
        @login_required(role='student')
        def view_courses():
            # Only accessible to logged-in students
            pass

        @app.route('/admin/dashboard')
        @login_required(role='admin')
        def admin_dashboard():
            # Only accessible to logged-in admins
            pass

        @app.route('/profile')
        @login_required()
        def profile():
            # Accessible to any logged-in user
            pass
    """
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if user is logged in
            if 'user_id' not in session:
                flash('Please log in to access this page.', 'error')
                return redirect(url_for('auth.login'))

            # Check role if specified
            if role is not None:
                user_role = session.get('role')

                if user_role != role:
                    # User has wrong role - redirect to their appropriate dashboard
                    if user_role == 'student':
                        flash('Access denied. This page is for administrators only.', 'error')
                        return redirect(url_for('student.index'))
                    elif user_role == 'admin':
                        flash('Access denied. This page is for students only.', 'error')
                        return redirect(url_for('admin.index'))
                    else:
                        # Unknown role - log out for safety
                        session.clear()
                        flash('Invalid user role. Please log in again.', 'error')
                        return redirect(url_for('auth.login'))

            # User is authenticated and has correct role (if specified)
            return f(*args, **kwargs)

        return decorated_function
    return decorator


def is_logged_in():
    """
    Check if a user is currently logged in.

    Returns:
        bool: True if user is logged in, False otherwise

    Example:
        >>> if is_logged_in():
        >>>     print("User is logged in")
    """
    return 'user_id' in session


def get_user_role():
    """
    Get the role of the currently logged-in user.

    Returns:
        str: 'student' or 'admin'
        None: If no user is logged in

    Example:
        >>> role = get_user_role()
        >>> if role == 'student':
        >>>     print("Student user")
    """
    return session.get('role')
