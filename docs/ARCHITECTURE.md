# System Architecture

## Overview

The CourseTracker is a Flask-based web application that provides direct access to a MySQL database for managing university course information. The architecture follows a traditional Model-View-Controller (MVC) pattern where Flask routes act as controllers, MySQL serves as the model layer, and Jinja2 templates provide the view layer. No ORM is used; all database interactions occur through raw SQL queries executed via mysql-connector-python.

## Component Diagram

```text
┌─────────────┐
│   Browser   │
│   (User)    │
└──────┬──────┘
       │ HTTP Request
       ↓
┌───────────────────────────────────────┐
│         Flask Application             │
│  ┌─────────────────────────────────┐  │
│  │         app.py                  │  │
│  │  - Application initialization   │  │
│  │  - Blueprint registration       │  │
│  │  - Configuration                │  │
│  └────────────┬────────────────────┘  │
│               │                       │
│  ┌────────────▼────────────────────┐  │
│  │       routes/                   │  │
│  │  - student_routes.py            │  │
│  │  - admin_routes.py              │  │
│  │  (Request handlers)             │  │
│  └────────────┬────────────────────┘  │
│               │                       │
│               ↓                       │
│  ┌─────────────────────────────────┐  │
│  │      utils/db_connection.py     │  │
│  │  - Connection management        │  │
│  │  - Query execution              │  │
│  └────────────┬────────────────────┘  │
└───────────────┼───────────────────────┘
                │
                ↓
         ┌─────────────────┐
         │    MySQL        │
         │  CourseTracker  │
         │   Database      │
         └──────┬──────────┘
                │
                ↓
         ┌──────────────┐
         │  Templates   │
         │  (Jinja2)    │
         │  - base.html │
         │  - student/  │
         │  - admin/    │
         └──────────────┘
```

## Request Flow

### Standard GET Request Flow

1. **User Action**: Browser sends GET request to Flask (e.g., `/student/courses`)
2. **Route Matching**: Flask routes the request to appropriate handler in `routes/student_routes.py`
3. **Query Execution**: Route function calls database query via `utils/db_connection.py`
4. **Database Access**: Connection utility executes SQL query against MySQL using mysql-connector-python
5. **Data Retrieval**: MySQL returns result set (list of dictionaries or tuples)
6. **Template Rendering**: Route passes results to Jinja2 template (e.g., `templates/student/courses.html`)
7. **HTML Generation**: Jinja2 renders HTML with data interpolated
8. **Response**: Flask sends rendered HTML back to browser

### Standard POST Request Flow (e.g., Enrollment)

1. **User Action**: Browser submits form via POST (e.g., `/student/enroll`)
2. **Route Matching**: Flask routes to POST handler in `routes/student_routes.py`
3. **Data Validation**: Route extracts and validates form data
4. **Transaction Start**: Connection utility opens database transaction
5. **Query Execution**: Route executes INSERT/UPDATE/DELETE via `utils/db_connection.py`
6. **Trigger Activation**: Database triggers fire automatically (e.g., capacity check)
7. **Commit/Rollback**: Transaction commits on success or rolls back on error
8. **Redirect/Render**: Route redirects to success page or re-renders form with error message

## Component Responsibilities

### app.py

- Initialize Flask application
- Load configuration from `config.py`
- Register blueprints from `routes/`
- Configure Jinja2 template environment
- Set up error handlers
- Define application entry point

### routes/ (Blueprint Modules)

- **student_routes.py**: Handle student-facing functionality
  - View available courses and sections
  - Enroll in sections
  - View enrolled courses and grades
  - Declare majors
  - View requirements and progress
  
- **admin_routes.py**: Handle administrative functionality
  - Manage courses, sections, and employees
  - Update student grades
  - View enrollment statistics
  - Generate reports with aggregations

**Responsibilities of route handlers**:

- Parse request parameters (query strings, form data)
- Call database queries via `utils/db_connection.py`
- Handle query results (transform, filter, aggregate)
- Pass data to templates for rendering
- Handle errors and validation

### utils/db_connection.py

- Establish and manage MySQL connections
- Provide connection pooling if needed
- Execute parameterized SQL queries
- Handle database exceptions
- Return results in consistent format (list of dictionaries)
- Ensure proper connection cleanup

**Key functions** (planned):

- `get_connection()`: Return database connection object
- `execute_query(sql, params)`: Execute SELECT query, return results
- `execute_update(sql, params)`: Execute INSERT/UPDATE/DELETE, return affected rows
- `close_connection(connection)`: Properly close connection

### templates/ (Jinja2 Templates)

- **base.html**: Master template with common layout
  - Header with navigation
  - Footer
  - Common CSS/JS includes
  - Block definitions for content injection
  
- **student/**: Student-specific views
  - Course catalog and search
  - Enrollment forms
  - Grade displays
  - Requirement tracking
  
- **admin/**: Admin-specific views
  - Data management forms
  - Statistics and reports
  - Employee management

**Responsibilities**:

- Render data from route handlers
- Provide forms for user input
- Display validation errors
- Implement responsive layouts
- Use template inheritance to avoid duplication

### database/ (SQL Files)

These are **not** loaded by the Python application. They are executed manually in MySQL to set up the database.

- **schema.sql**: Table definitions (CREATE TABLE statements)
- **data.sql**: Sample data (INSERT statements)
- **triggers.sql**: Trigger definitions (to be created)
- **views.sql**: View definitions (to be created)
- **procedures_functions.sql**: Stored procedures and functions (to be created)
- **queries.sql**: Documentation of main application queries (to be created)

### static/

- **css/**: Stylesheets for visual presentation
- **js/**: Client-side JavaScript for interactivity

## Database Interaction Pattern

All routes follow this pattern for database access:

```text
Route Handler:
1. Import db_connection utility
2. Prepare SQL query string with placeholders
3. Prepare parameters tuple/list
4. Call execute_query() or execute_update()
5. Receive results
6. Process results if needed
7. Pass to template or handle errors
```

### Example Pattern (Conceptual)

```python
# In student_routes.py
from utils.db_connection import execute_query

@student_bp.route('/courses')
def view_courses():
    sql = """
        SELECT c.courseId, c.title, c.credits, cl.code
        FROM Course c
        JOIN cross_lists cl ON c.courseId = cl.courseId
        WHERE cl.deptId = %s
    """
    params = (dept_id,)
    courses = execute_query(sql, params)
    return render_template('student/courses.html', courses=courses)
```

### Query Execution Approach

- **Parameterized queries**: Always use `%s` placeholders, never string interpolation
- **Connection management**: Open connection, execute, close in utility function
- **Error handling**: Catch MySQL exceptions, log errors, return user-friendly messages
- **Results format**: Return list of dictionaries for easy template access

## Data Flow Example: Student Enrollment

1. **Student views course catalog**: GET `/student/courses`
   - Route queries Course, Section, cross_lists tables
   - Joins to show course codes and availability
   - Template renders course list with "Enroll" buttons

2. **Student clicks "Enroll"**: GET `/student/enroll?courseId=5001&sectionNo=0001`
   - Route displays enrollment confirmation form
   - Form includes hidden fields for courseId and sectionNo
   - Template shows course details and confirmation button

3. **Student confirms enrollment**: POST `/student/enroll`
   - Route extracts studentId (from session), courseId, sectionNo from form
   - Route calls INSERT query on enrolls_in table
   - Database trigger fires to check capacity
   - If trigger allows, enrollment succeeds
   - Route redirects to "My Courses" page with success message

4. **Student views enrolled courses**: GET `/student/my-courses`
   - Route queries enrolls_in JOIN Section JOIN Course
   - Template displays enrolled courses with status and grades
