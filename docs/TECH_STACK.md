# Technology Stack

## Overview

This project uses Python with Flask for the web framework, MySQL for the database, and Jinja2 for templating. The stack is deliberately minimal to meet course requirements that emphasize raw SQL queries and database features like triggers, views, and stored procedures.

---

## Python 3.11

**Why**: Course requirement and team familiarity. Python provides good libraries for web development and database connectivity.

**What we use**:

- Core language features for route logic and data processing
- Flask framework for web server
- mysql-connector-python for database connectivity

**Configuration**:

- Virtual environment (venv) for dependency isolation
- Python 3.11+ required for modern type hints and performance

---

## Flask 3.0

**Why**: Lightweight web framework that meets course requirements without unnecessary complexity. Flask provides just enough structure for routing and templating while allowing direct SQL query execution.

**What we use**:

- Routing decorators (`@app.route()`, `@blueprint.route()`)
- Request handling (`request.args`, `request.form`)
- Template rendering (`render_template()`)
- Blueprints for organizing routes by user role
- Session management for user state
- Jinja2 templating (built-in)

**Configuration**:

- Debug mode enabled for development
- Secret key for session management
- Blueprint structure for modularity (student_routes, admin_routes)

---

## MySQL 8.0

**Why**: Course requirement. MySQL is a robust relational database system that supports the advanced features required by the project: triggers, views, stored procedures, and functions.

**What we use**:

- Relational schema with foreign keys
- ENUM types for constrained values (gender, role, status, grades, degree types, requirement types)
- CHECK constraints for data validation (salary >= 0, credits between 0-5, capacity > 0)
- Triggers for business logic enforcement (to be implemented)
- Views for data access abstraction (to be implemented)
- Stored procedures for reusable database operations (to be implemented)
- Functions for calculated values (to be implemented)
- Weak entity relationships (Section depends on Course)

**Configuration**:

- InnoDB storage engine for transaction support and foreign keys
- Foreign key constraints with appropriate ON DELETE/UPDATE actions
- UTF-8 character encoding for text fields

**Key Features**:

- **Foreign Keys**: Enforce referential integrity across tables
- **Composite Keys**: Used in Major (majorId, degreeType) and relationships
- **ON DELETE/UPDATE**: Cascade and restrict actions for data consistency
- **Transaction Support**: ACID properties for data integrity

---

## mysql-connector-python

**Why**: Official MySQL driver for Python. Allows raw SQL execution without an ORM, which is essential for demonstrating specific SQL patterns required by the course (explicit joins, aggregations, subqueries).

**What we use**:

- Connection management (`mysql.connector.connect()`)
- Cursor execution for queries (`cursor.execute()`)
- Parameterized queries for SQL injection prevention
- Result fetching (`fetchall()`, `fetchone()`)
- Transaction control (`commit()`, `rollback()`)

**Configuration**:

- Connection parameters: host, user, password, database
- Autocommit disabled for explicit transaction control
- Dictionary cursor for accessing results by column name

**Security**:

- Always use parameterized queries with `%s` placeholders
- Never use string formatting or concatenation for SQL
- Store credentials in config file (not in code)

---

## Jinja2 (via Flask)

**Why**: Built into Flask and sufficient for our templating needs. Provides template inheritance, variable rendering, and control structures for building HTML views.

**What we use**:

- Template inheritance (`{% extends %}`, `{% block %}`)
- Variable rendering (`{{ variable }}`)
- Control structures (`{% for %}`, `{% if %}`)
- Filters for data formatting (`{{ value|round(2) }}`)
- URL generation (`{{ url_for() }}`)
- Form handling integration

**Configuration**:

- Template directory: `templates/`
- Auto-escaping enabled for XSS prevention
- Template caching in production

**Patterns**:

- Base template (`base.html`) with common layout
- Child templates inherit and override blocks
- Separate template directories for student and admin views

---

## HTML5 / CSS3 / JavaScript

**Why**: Standard web technologies for user interface. No additional frontend framework needed for this project scope.

**What we use**:

- HTML5 for semantic markup
- CSS3 for styling and layout
- Minimal JavaScript for form validation and interactivity

**Configuration**:

- Static files served from `static/` directory
- CSS organized in `static/css/`
- JavaScript in `static/js/` (if needed)

**Approach**:

- Server-side rendering (no single-page application)
- Progressive enhancement
- Responsive design for different screen sizes

---

## Development Tools

### Version Control

- **Git**: Source code version control
- **GitHub**: Repository hosting at `cs4400-course-tracker`

### Database Tools

- **MySQL Workbench** or **command-line client**: For database development and testing
- Manual SQL file execution for schema setup

### Python Tools

- **pip**: Package management
- **venv**: Virtual environment for dependency isolation
- **requirements.txt**: Dependency specification

---

## Technology Decisions Summary

| Technology | Version | Primary Reason |
|-----------|---------|----------------|
| Python | 3.11+ | Course requirement, team experience |
| Flask | 3.0 | Lightweight, allows raw SQL |
| MySQL | 8.0 | Course requirement, supports triggers/views |
| mysql-connector-python | Latest | Official driver, no ORM |
| Jinja2 | Built-in | Adequate templating, comes with Flask |

---

## Dependencies

### Core Dependencies (requirements.txt)

```text
Flask==3.0.0
mysql-connector-python==8.2.0
```

### Development Dependencies (optional)

```text
python-dotenv==1.0.0  # For .env file support
```

---

## Not Using

**SQLAlchemy or other ORMs**: Course requires explicit SQL queries to demonstrate joins, aggregations, and subqueries. An ORM would abstract away the SQL, making it harder to meet requirements.

**Frontend frameworks (React, Vue)**: Project scope doesn't require complex client-side interactions. Server-side rendering with Jinja2 is sufficient.

**API layer (REST/GraphQL)**: Direct template rendering is simpler and meets requirements. No need for separate API endpoints.

**PostgreSQL or other RDBMS**: MySQL is the course standard and supports all required features.
