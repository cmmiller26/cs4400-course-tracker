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

### Database Features

- ✅ **3 Triggers**: Prerequisite validation, capacity enforcement, duplicate prevention
- ✅ **2 Views**: Current enrollments, completed courses
- 🔄 **Stored Procedure & Function**: In progress
- 🔄 **5 SQL Queries**: In progress (JOINs, aggregations, subqueries)

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

2. **Create virtual environment**:

   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**:

   ```bash
   pip install -r requirements.txt
   ```

4. **Configure database** (edit `config.py`):

   ```python
   DB_CONFIG = {
       'host': 'localhost',
       'user': 'your_username',
       'password': 'your_password',
       'database': 'CourseTracker'
   }
   ```

5. **Create database and load schema**:

   ```bash
   mysql -u your_username -p < database/schema.sql
   mysql -u your_username -p CourseTracker < database/data.sql
   mysql -u your_username -p CourseTracker < database/auth_table.sql
   mysql -u your_username -p CourseTracker < database/triggers.sql
   mysql -u your_username -p CourseTracker < database/views.sql
   ```

6. **Run the application**:

   ```bash
   python app.py
   ```

7. **Access the application**:
   - Homepage: `http://localhost:5001`
   - Login: `http://localhost:5001/auth/login`

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
├── app.py                   # Main Flask application
├── config.py                # Configuration settings
├── requirements.txt         # Python dependencies
├── database/               # SQL files
│   ├── schema.sql         # Table definitions
│   ├── data.sql           # Sample data
│   ├── auth_table.sql     # Authentication table
│   ├── triggers.sql       # Trigger definitions
│   └── views.sql          # View definitions
├── routes/                # Flask blueprints
│   ├── auth_routes.py     # Login/logout
│   ├── student_routes.py  # Student functionality
│   └── admin_routes.py    # Admin functionality
├── utils/                 # Utility modules
│   ├── auth.py            # Authentication utilities
│   └── db_connection.py   # Database connection
├── templates/             # Jinja2 templates
│   ├── base.html
│   ├── login.html
│   ├── student/
│   └── admin/
├── static/                # CSS, JavaScript
└── docs/                  # Documentation
    ├── AUTH_SETUP.md      # Authentication setup guide
    ├── ARCHITECTURE.md
    ├── TECH_STACK.md
    └── DATABASE_DESIGN.md
```

---

## Documentation

- **[CLAUDE.md](CLAUDE.md)**: Project overview and navigation for AI assistants
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

## Key Design Decisions

### No ORM

The project intentionally avoids SQLAlchemy or other ORMs to demonstrate explicit SQL queries (joins, aggregations, subqueries) as required by the course.

### Raw SQL Queries

All database interactions use parameterized SQL queries via mysql-connector-python with `%s` placeholders for security.

### Role-Based Access Control

- Student routes: `/student/*` - requires student login
- Admin routes: `/admin/*` - requires admin login
- Protected using `@login_required(role='student')` or `@login_required(role='admin')` decorators

### Session Management

- Server-side Flask sessions
- User data stored: user_id, username, role, student_id, student_name
- SECRET_KEY in config.py protects session cookies

---

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

---

## Team

- Colin Miller
- Manthan Shah
- Jack Janik

**Institution**: University of Iowa
**Course**: CS:4400 Database Systems
**Semester**: Fall 2025
