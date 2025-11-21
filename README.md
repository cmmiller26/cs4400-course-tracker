# CS4400 CourseTracker

A university course tracking system built for CS:4400 Database Systems at the University of Iowa. The system manages students, courses, sections, employees (professors, TAs, advisors), academic requirements, and majors.

**Course**: CS:4400 Database Systems
**Project**: Deliverable 5 - Database Implementation with Web Interface
**Team**: Colin Miller, Manthan Shah, Jack Janik

---

## Features

### Student Portal

- Browse course catalog with sections and departments
- Enroll in course sections with automatic validation
- View enrolled and completed courses with grades
- Declare majors and track requirements

### Admin Portal

- View and manage student records
- Manage courses and professor assignments
- View enrollment statistics by department
- Access database views for reporting
- SQL queries showcase

### Authentication Schema

- Session-based authentication with role-based access control
- Two test accounts: student and admin
- Protected routes with @login_required decorator
- Password hashing using werkzeug.security (scrypt)

---

## Quick Start

### Prerequisites

- Python 3.11+
- MySQL 8.0+
- pip (Python package manager)

### Installation

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd cs4400-course-tracker
   ```

2. **Create and activate virtual environment**:

   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On macOS/Linux
   # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:

   ```bash
   pip install -r requirements.txt
   ```

4. **Configure database**:

   Copy the example environment file and edit with your MySQL credentials:

   ```bash
   cp .env.example .env
   ```

   Edit `.env` file:

   ```bash
   SECRET_KEY=your-random-secret-key-here
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=YOUR_MYSQL_PASSWORD_HERE
   DB_NAME=CourseTracker
   ```

5. **Initialize the database**:

   The automated initialization script will create the database and execute all SQL files:

   ```bash
   python -m utils.init_db
   ```

   This script will:
   - Drop and recreate the `CourseTracker` database
   - Execute all SQL files in the correct order (schema, auth, data, views, triggers, procedures)
   - Create test accounts (teststudent/student123, testadmin/admin123)
   - Provide clear feedback on success or errors

6. **Run the application**:

   ```bash
   python run.py
   ```

7. **Access the application**:
   - Homepage: `http://localhost:5001`
   - Login: `http://localhost:5001/auth/login`

---

## Database Utilities

The project includes comprehensive database utility functions in [utils/db_connection.py](utils/db_connection.py):

### Connection Management

```python
from utils.db_connection import get_connection

# Get a connection (automatically uses config from .env)
connection = get_connection()
```

### Query Execution

```python
from utils.db_connection import execute_query, execute_update

# SELECT queries - returns list of dictionaries
students = execute_query("SELECT * FROM Student WHERE year = %s", (2024,))
student = execute_query("SELECT * FROM Student WHERE id = %s", (4001,), fetch_one=True)

# INSERT/UPDATE/DELETE - returns affected row count
rows_affected = execute_update(
    "UPDATE Student SET year = %s WHERE id = %s",
    (2025, 4001)
)
```

### Stored Procedures & Functions

```python
from utils.db_connection import call_procedure, call_function

# Call stored procedure (returns list of result sets)
results = call_procedure('GetStudentEnrollments', (4001,))

# Call stored function (returns scalar result)
gpa = call_function('CalculateGPA', (4001,))
```

### Transaction Management

```python
from utils.db_connection import execute_transaction

# Execute multiple queries in a transaction
queries = [
    ("INSERT INTO Student VALUES (%s, %s, %s, %s, %s)", (5001, 'John', 'Doe', 2024, 'M')),
    ("INSERT INTO enrolls_in VALUES (%s, %s, %s, %s, NULL)", (5001, 'CS', 4400, 1))
]
success = execute_transaction(queries)
```

### Security Features

- All queries use **parameterized statements** with `%s` placeholders
- Automatic **connection pooling** and cleanup
- Built-in **error handling** and logging
- **Transaction rollback** on errors

---

## Test Accounts

### Student Account

- **Username**: `teststudent`
- **Password**: `student123`
- **Access**: Student portal with data for Student ID 4001

### Admin Account

- **Username**: `testadmin`
- **Password**: `admin123`
- **Access**: Admin portal with full system access

---

## Project Structure

```text
cs4400-course-tracker/
├── run.py                        # Application entry point
├── app.py                        # Main Flask application (app factory)
├── config.py                     # Configuration settings
├── requirements.txt              # Python dependencies
├── .env.example                  # Environment variables template
├── .env                          # Your local config (not in git)
├── database/                     # SQL files
│   ├── schema.sql                # Table definitions
│   ├── auth_table.sql            # Authentication table
│   ├── data.sql                  # Sample data
│   ├── views.sql                 # View definitions
│   ├── triggers.sql              # Trigger definitions
│   ├── procedures_functions.sql  # Stored procedures & functions
│   └── queries.sql               # Main application queries
├── routes/                       # Flask blueprints
│   ├── __init__.py
│   ├── auth_routes.py            # Login/logout
│   ├── student_routes.py         # Student functionality
│   └── admin_routes.py           # Admin functionality
├── utils/                        # Utility modules
│   ├── __init__.py
│   ├── auth.py                   # Authentication utilities
│   ├── db_connection.py          # Database connection & query functions
│   └── init_db.py                # Database initialization script
├── templates/                    # Jinja2 templates
│   ├── base.html                 # Base template with Iowa branding
│   ├── index.html                # Landing page
│   ├── login.html                # Login form
│   ├── student/                  # Student portal templates
│   │   ├── index.html            # Student dashboard
│   │   ├── courses.html          # Course catalog
│   │   ├── enroll.html           # Enrollment page
│   │   └── gpa.html              # GPA calculator
│   └── admin/                    # Admin portal templates
│       ├── index.html            # Admin dashboard
│       ├── analytics.html        # Grade analytics
│       └── salary_report.html    # Salary report
├── static/                       # Static assets
│   └── css/
│       ├── style.css             # Base styles
│       ├── components.css        # Reusable components
│       ├── theme-student.css     # Student portal theme
│       ├── theme-admin.css       # Admin portal theme
│       ├── admin_dashboard.css   # Admin dashboard styles
│       ├── analytics.css         # Analytics page styles
│       ├── salary_report.css     # Salary report styles
│       └── gpa.css               # GPA calculator styles
└── docs/                         # Documentation
    ├── AUTH_SETUP.md             # Authentication setup guide
    ├── ARCHITECTURE.md           # System architecture
    ├── TECH_STACK.md             # Technology stack details
    └── DATABASE_DESIGN.md        # Database schema & design
```

---

## Documentation

- **[docs/AUTH_SETUP.md](docs/AUTH_SETUP.md)**: Detailed authentication setup and testing
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)**: System architecture and request flow
- **[docs/TECH_STACK.md](docs/TECH_STACK.md)**: Technology choices and stack details
- **[docs/DATABASE_DESIGN.md](docs/DATABASE_DESIGN.md)**: Database schema and design decisions

---

## Technology Stack

- **Backend**: Python 3.11, Flask 3.0
- **Database**: MySQL 8.0
- **Database Driver**: mysql-connector-python (no ORM)
- **Templating**: Jinja2
- **Authentication**: Flask sessions with werkzeug.security
- **Frontend**: HTML5, CSS3, minimal JavaScript

---

## ER Diagram

![ER Diagram](static/images/er-diagram.svg)

## Database Schema Highlights

### Core Entities

- **Student**: University students with year and demographics
- **Employee**: Professors, TAs, and Advisors (disjoint specialization)
- **Course**: Catalog courses with prerequisites
- **Section**: Weak entity - specific course offerings
- **Major**: Degree programs (composite key: majorId, degreeType)
- **Department** & **College**: Academic organizational units

### Key Relationships

- **enrolls_in**: Student enrollment in sections (status, grade, date)
- **teaches**: Professors assigned to courses (total participation)
- **advises**: Advisors assigned to students (student total participation)
- **cross_lists**: Courses cross-listed in multiple departments
- **prerequisite_of**: Unary relationship for course prerequisites

### Authentication

- **app_users**: User accounts with hashed passwords
  - Foreign key to Student table (CASCADE DELETE)
  - Role-based access (student/admin)

---

## License

This project is for educational purposes as part of CS:4400 Database Systems at the University of Iowa.
