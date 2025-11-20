"""
Authentication routes for CourseTracker application.

Handles user login and logout functionality.
"""

from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from utils.auth import authenticate_user, is_logged_in

# Create auth blueprint
auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/login', methods=['GET', 'POST'])
def login():
    """
    Handle user login.

    GET: Display login form
    POST: Process login credentials and create session

    Form fields:
        - username: User's username
        - password: User's plaintext password

    On successful login:
        - Creates session with user information
        - Redirects to appropriate dashboard based on role

    On failed login:
        - Displays error message
        - Re-renders login form
    """
    # If already logged in, redirect to appropriate dashboard
    if is_logged_in():
        role = session.get('role')
        if role == 'student':
            return redirect(url_for('student.index'))
        elif role == 'admin':
            return redirect(url_for('admin.index'))

    # Handle POST request (form submission)
    if request.method == 'POST':
        username = request.form.get('username', '').strip()
        password = request.form.get('password', '')

        # Validate input
        if not username or not password:
            flash('Please enter both username and password.', 'error')
            return render_template('login.html')

        # Authenticate user
        user = authenticate_user(username, password)

        if user is None:
            # Authentication failed
            flash('Invalid username or password. Please try again.', 'error')
            return render_template('login.html')

        # Authentication successful - create session
        session['user_id'] = user['user_id']
        session['username'] = user['username']
        session['role'] = user['role']
        session['student_id'] = user['student_id']
        session['student_name'] = user['student_name']

        # Flash success message
        if user['role'] == 'student':
            flash(f"Welcome back, {user['student_name']}!", 'success')
        else:
            flash(f"Welcome back, {user['username']}!", 'success')

        # Redirect to appropriate dashboard
        if user['role'] == 'student':
            return redirect(url_for('student.index'))
        elif user['role'] == 'admin':
            return redirect(url_for('admin.index'))

    # Handle GET request (display login form)
    return render_template('login.html')


@auth_bp.route('/logout')
def logout():
    """
    Handle user logout.

    Clears session data and redirects to homepage.
    """
    # Get username before clearing session for goodbye message
    username = session.get('username', 'User')

    # Clear all session data
    session.clear()

    # Flash goodbye message
    flash(f'You have been logged out. Goodbye, {username}!', 'info')

    # Redirect to homepage
    return redirect(url_for('index'))
