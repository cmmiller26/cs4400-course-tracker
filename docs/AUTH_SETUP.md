# Authentication System Setup Instructions

## Overview

A simple authentication system has been implemented for the CourseTracker application with two test accounts:

- **Student Account**: Links to Student ID 4001
- **Admin Account**: Administrative access

## Database Setup

### Step 1: Run the Authentication Table SQL

Execute the SQL file to create the `app_users` table and insert test accounts:

```bash
mysql -u your_username -p CourseTracker < database/auth_table.sql
```

Or manually in MySQL:

```sql
SOURCE /path/to/cs4400-course-tracker/database/auth_table.sql;
```

This will:

1. Create the `app_users` table
2. Insert two test accounts with hashed passwords
3. Display confirmation of successful setup

### Step 2: Verify Database Setup

Check that the table was created and data was inserted:

```sql
USE CourseTracker;
SELECT * FROM app_users;
```

You should see:

- **teststudent** - role: student, linked_id: 4001
- **testadmin** - role: admin, linked_id: NULL

## Test Accounts

### Student Account

- **Username**: `teststudent`
- **Password**: `student123`
- **Role**: student
- **Linked to**: Student ID 4001 (should exist in your Student table)
- **Access**: Student portal only

### Admin Account

- **Username**: `testadmin`
- **Password**: `admin123`
- **Role**: admin
- **Linked to**: None (admins are not students/employees)
- **Access**: Admin portal only

## Testing the Authentication System

### 1. Start the Flask Application

```bash
python app.py
```

The application will run on `http://localhost:5001`

### 2. Test Login Flow

#### Test Student Login

1. Navigate to `http://localhost:5001/auth/login`
2. Enter username: `teststudent`
3. Enter password: `student123`
4. Click "Log In"
5. **Expected**: Redirected to Student Portal with welcome message showing student name
6. **Verify**: Can access all student routes (/student/\*)
7. **Verify**: Cannot access admin routes (redirected with error message)

#### Test Admin Login

1. Click "Logout" (if logged in as student)
2. Navigate to `http://localhost:5001/auth/login`
3. Enter username: `testadmin`
4. Enter password: `admin123`
5. Click "Log In"
6. **Expected**: Redirected to Admin Portal with welcome message
7. **Verify**: Can access all admin routes (/admin/\*)
8. **Verify**: Cannot access student routes (redirected with error message)

### 3. Test Protected Routes

Try accessing protected routes without logging in:

1. **Logout** (if logged in)
2. Try to access `http://localhost:5001/student/courses`
3. **Expected**: Redirected to login page with "Please log in" message

### 4. Test Session Management

1. **Login** as student
2. **Close browser** (not just tab)
3. **Reopen browser** and navigate to site
4. **Expected**: Session should persist (depending on browser settings)

### 5. Test Navigation

When logged in:

- **Student**: Navigation bar shows "Student Portal" dropdown and student name
- **Admin**: Navigation bar shows "Admin Portal" dropdown and admin username
- **Both**: Logout button visible in navigation
- **Not logged in**: Only "Login" button visible

## System Architecture

### Files Created/Modified

#### New Files

1. **database/auth_table.sql** - Authentication table schema and test data
2. **utils/auth.py** - Authentication utilities (hashing, verification, decorators)
3. **routes/auth_routes.py** - Login/logout routes
4. **templates/login.html** - Login form template

#### Modified Files

1. **app.py** - Registered auth blueprint
2. **routes/student_routes.py** - Added @login_required(role='student') decorators
3. **routes/admin_routes.py** - Added @login_required(role='admin') decorators
4. **templates/base.html** - Added login/logout links and user display

### How It Works

1. **Password Security**:
   - Passwords hashed using werkzeug.security (scrypt algorithm)
   - Never stored in plaintext
   - Hashes are salted automatically

2. **Session Management**:
   - Uses Flask sessions (server-side storage)
   - Session data: user_id, username, role, student_id, student_name
   - SECRET_KEY from config.py protects session cookies

3. **Route Protection**:
   - @login_required() decorator checks for valid session
   - @login_required(role='student') restricts to students only
   - @login_required(role='admin') restricts to admins only
   - Unauthorized access redirects to appropriate dashboard with error message

4. **Foreign Key Relationship**:
   - app_users.linked_id → Student.studentId (CASCADE DELETE)
   - If a student is deleted from Student table, their app_users record is also deleted
   - Admins have NULL linked_id (they are not students)

## Important Notes

### For Demo Purposes Only

This authentication system is intentionally simple for demonstration:

- Only 2 test accounts
- No registration/signup functionality
- No password reset/recovery
- No email verification
- No multi-factor authentication
- No account lockout after failed attempts

### For Production Use

If deploying to production, you should add:

1. User registration system
2. Password reset functionality
3. Email verification
4. Rate limiting on login attempts
5. Account lockout mechanisms
6. Session timeout configuration
7. HTTPS enforcement
8. CSRF protection
9. More secure SECRET_KEY management
10. Logging of authentication events

### Student ID Requirement

**Important**: The test student account (teststudent) is linked to Student ID 4001.
This student must exist in your Student table with the following data:

```sql
-- Verify Student 4001 exists
SELECT * FROM Student WHERE studentId = 4001;
```

If Student 4001 doesn't exist, either:

1. **Option A**: Insert Student 4001 into your Student table
2. **Option B**: Update auth_table.sql to use a different existing studentId

## Troubleshooting

### Issue: "Invalid username or password"

- **Cause**: Incorrect credentials or app_users table not created
- **Solution**: Verify test accounts exist: `SELECT * FROM app_users;`

### Issue: "Please log in to access this page"

- **Cause**: Session expired or not logged in
- **Solution**: Log in at `/auth/login`

### Issue: "Access denied" message

- **Cause**: Trying to access wrong portal (student trying to access admin or vice versa)
- **Solution**: Log out and log in with correct account type

### Issue: Foreign key constraint error when creating app_users table

- **Cause**: Student ID 4001 doesn't exist in Student table
- **Solution**: Either create Student 4001 or modify auth_table.sql to use different student ID

### Issue: "SECRET_KEY" not configured

- **Cause**: config.py missing or SECRET_KEY not set
- **Solution**: config.py already has SECRET_KEY = 'dev-secret-key-change-in-production'

### Issue: Session not persisting

- **Cause**: SECRET_KEY changed or browser blocking cookies
- **Solution**: Check browser cookie settings, verify SECRET_KEY is consistent

## Security Considerations

### Password Hashes

The password hashes in auth_table.sql are pre-generated for convenience. In production:

1. Never commit password hashes to version control
2. Generate hashes on first run or through admin interface
3. Use environment variables for default admin credentials

### SECRET_KEY

The SECRET_KEY in config.py is set to a default value. In production:

1. Set SECRET_KEY via environment variable
2. Use a strong random key: `python -c "import secrets; print(secrets.token_hex(32))"`
3. Never commit SECRET_KEY to version control

## Next Steps

After verifying authentication works:

1. **Update enrollment form** (if needed) to use session student_id
2. **Add user context** to templates (show personalized data)
3. **Create admin user management** (optional - add/remove users)
4. **Add password change functionality** (optional)
5. **Implement "Remember Me"** (optional - persistent login)

## Questions?

If you encounter issues:

1. Check that database/auth_table.sql was executed successfully
2. Verify Flask app is running without errors
3. Check browser console for JavaScript errors
4. Review Flask logs for error messages
5. Ensure Student 4001 exists in Student table

---

**Setup Complete!**

You now have a working authentication system for your CourseTracker application.
