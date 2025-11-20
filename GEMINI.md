# CS4400 Course Tracker - Context for Claude Code

This is a university course tracking system built for CS:4400 Database Systems at the University of Iowa. The system manages students, courses, sections, employees (professors, TAs, advisors), academic requirements, and majors. Students can enroll in course sections, declare majors, and work with advisors. The system tracks prerequisites, requirements, and cross-listed courses across departments.

**Course**: CS:4400 Database Systems  
**Project**: Deliverable 5 - Database Implementation with Web Interface  
**Team**: Colin Miller, Manthan Shah, Jack Janik

## Documentation Index

When you need information about:

- **System architecture and component structure** → `docs/ARCHITECTURE.md`
- **Technology choices and stack details** → `docs/TECH_STACK.md`
- **Database schema, tables, and relationships** → `docs/DATABASE_DESIGN.md`
- **Authentication setup and testing** → `docs/AUTH_SETUP.md`
- **API routes and endpoints** → `docs/API_ROUTES.md` (not yet created)
- **SQL query documentation** → `docs/QUERY_DOCUMENTATION.md` (not yet created)
- **Development setup and workflow** → `docs/DEVELOPMENT.md` (not yet created)

## Directory Structure

```text
cs4400-course-tracker/
├── CLAUDE.md                    # This file - navigation for AI assistants
├── README.md                     # Project overview and setup instructions
├── requirements.txt              # Python dependencies
├── .gitignore                    # Git ignore rules
├── config.py                     # Configuration (DB credentials, Flask config)
├── app.py                        # Main Flask application entry point
├── docs/                         # Documentation
│   ├── AUTH_SETUP.md            # Authentication setup and testing guide
│   ├── ARCHITECTURE.md           # System design and component interaction
│   ├── TECH_STACK.md            # Technology stack documentation
│   └── DATABASE_DESIGN.md       # Database schema and design decisions
├── database/                     # SQL files
│   ├── schema.sql               # DDL (CREATE TABLE statements)
│   ├── data.sql                 # DML (INSERT statements with sample data)
│   ├── auth_table.sql           # Authentication table and test accounts
│   ├── triggers.sql             # Trigger definitions (completed)
│   ├── views.sql                # View definitions (completed)
│   ├── procedures_functions.sql # Stored procedures and functions (to be created)
│   └── queries.sql              # Main application queries (to be created)
├── routes/                       # Flask route handlers
│   ├── __init__.py
│   ├── auth_routes.py           # Authentication (login/logout)
│   ├── student_routes.py        # Student-facing routes (protected)
│   └── admin_routes.py          # Admin-facing routes (protected)
├── utils/                        # Utility modules
│   ├── __init__.py
│   ├── auth.py                  # Authentication utilities and decorators
│   └── db_connection.py         # Database connection management
├── templates/                    # Jinja2 HTML templates
│   ├── base.html                # Base template with common layout
│   ├── index.html               # Homepage
│   ├── login.html               # Login form
│   ├── student/                 # Student view templates
│   └── admin/                   # Admin view templates
└── static/                       # Static assets
    ├── css/                     # Stylesheets
    └── js/                      # JavaScript files
```

## Key Conventions

### Naming

- **Database tables**: PascalCase (e.g., `Student`, `Course`, `enrolls_in`)
- **Routes**: `/student/...` for student views, `/admin/...` for admin views
- **Templates**: Match route structure (e.g., `student/courses.html`)
- **SQL files**: Lowercase with underscores (e.g., `procedures_functions.sql`)

### File Organization

- **One SQL file per concern**: schema, data, triggers, views, procedures
- **Routes organized by user role**: student_routes.py, admin_routes.py
- **Templates mirror route structure**: student/ and admin/ subdirectories

### Code Style

- **SQL**: Use explicit JOINs, parameterized queries for security
- **Python**: Follow PEP 8, use descriptive variable names
- **Templates**: Use template inheritance from base.html

## Important Notes

### Course Requirements

- Must implement at least **3 triggers**
- Must create at least **2 views**
- Must implement **1 stored procedure** and **1 function** (at least one with input parameters)
- Must demonstrate **5 SQL queries**:
  - At least 3 with JOINs
  - At least 2 with aggregations
  - At least 1 with a subquery
  - At least 1 using a view

### Database Constraints

- Use **mysql-connector-python** (not SQLAlchemy or other ORMs) to demonstrate raw SQL
- All queries must be written explicitly (no ORM-generated SQL)
- Database enforces foreign keys, check constraints, and ENUM types
- Student has total participation in advises relationship
- Course has total participation in teaches relationship
- Section is a weak entity dependent on Course

### Project Constraints

- Demo presentation scheduled for first week of December
- Must provide .zip file with website and setup instructions
- Graders must be able to run on local server
- Must showcase at least one trigger in action during demo

## Authentication System

The system implements a simple session-based authentication with two user roles:

### Test Accounts

- **Student**: username `teststudent`, password `student123` (linked to Student ID 4001)
- **Admin**: username `testadmin`, password `admin123`

### Setup

1. Run `database/auth_table.sql` to create the `app_users` table
2. Ensure Student ID 4001 exists in the Student table
3. Access login at `/auth/login`

### Key Files

- **database/auth_table.sql**: Creates app_users table with test accounts
- **utils/auth.py**: Password hashing, authentication, and @login_required decorator
- **routes/auth_routes.py**: Login/logout routes
- **templates/login.html**: Login form

### Security Features

- Passwords hashed using werkzeug.security (scrypt)
- Session-based authentication with Flask sessions
- Role-based access control (@login_required decorator)
- Protected routes redirect to login if not authenticated
- Foreign key CASCADE delete for data integrity

See **docs/AUTH_SETUP.md** for detailed setup instructions and testing guide.
