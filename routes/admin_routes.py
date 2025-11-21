from flask import Blueprint, render_template, request, redirect, url_for, flash
from utils.db_connection import execute_query, call_function
from utils.auth import login_required

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/')
@login_required(role='admin')
def index():
    """Admin dashboard/home page"""
    return render_template('admin/index.html')

# ============================================================================
# QUERY 4: Salary Analysis with Department Comparison
# Requirements: SUBQUERY, AGGREGATION, FUNCTION
# ============================================================================
@admin_bp.route('/salary-report')
@login_required(role='admin')
def salary_report():
    """
    Display employee salaries compared to role averages using subqueries, aggregation,
    and the average_department_salary stored function.

    SQL Requirements Met:
    - SUBQUERY ✓ (role average salary subquery)
    - AGGREGATION ✓ (AVG in subquery)
    - FUNCTION ✓ (average_department_salary)
    - JOIN ✓ (Employee with subquery)

    Note: Database views are demonstrated in the analytics route.
    """
    try:
        # Part 1: Employee salary vs role average (demonstrates SUBQUERY and AGGREGATION)
        salary_comparison_sql = """
            SELECT
                e.employeeId,
                e.name,
                e.role,
                e.salary,
                role_avg.average_salary,
                (e.salary - role_avg.average_salary) AS difference
            FROM Employee e
            JOIN (
                SELECT role, AVG(salary) AS average_salary
                FROM Employee
                GROUP BY role
            ) AS role_avg ON e.role = role_avg.role
            ORDER BY e.role, e.salary DESC
        """
        employees = execute_query(salary_comparison_sql)

        if employees is None:
            employees = []

        # Part 2: Department average salaries (demonstrates FUNCTION)
        # Get all unique departments first
        dept_sql = "SELECT DISTINCT deptId, name FROM Department ORDER BY name"
        departments = execute_query(dept_sql)

        department_averages = []
        if departments:
            for dept in departments:
                avg_salary = call_function('average_department_salary', (dept['deptId'],))
                if avg_salary is not None:
                    department_averages.append({
                        'deptId': dept['deptId'],
                        'name': dept['name'],
                        'average_salary': avg_salary
                    })

        return render_template('admin/salary_report.html',
                             employees=employees,
                             department_averages=department_averages)

    except Exception as e:
        flash('An unexpected error occurred while loading the salary report.', 'error')
        print(f"Error in salary_report route: {e}")
        return render_template('admin/salary_report.html',
                             employees=[],
                             department_averages=[])

# ============================================================================
# QUERY 5: Course Grade Analytics
# Requirements: AGGREGATION, VIEW, JOIN
# ============================================================================
@admin_bp.route('/analytics')
@login_required(role='admin')
def analytics():
    """
    Display average grades per course and per professor using aggregation
    with both database views (current_student_enrollments and completed_student_courses).

    SQL Requirements Met:
    - AGGREGATION ✓ (AVG, GROUP BY)
    - JOIN ✓ (Multiple joins across tables)
    - VIEW ✓ (current_student_enrollments, completed_student_courses)
    """
    try:
        # Part 1: Average grade per course (demonstrates AGGREGATION)
        course_grades_sql = """
            SELECT
                c.courseId,
                c.title,
                AVG(CASE e.grade
                    WHEN 'A+' THEN 4.33 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.67
                    WHEN 'B+' THEN 3.33 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.67
                    WHEN 'C+' THEN 2.33 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.67
                    WHEN 'D+' THEN 1.33 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.67
                    WHEN 'F' THEN 0.0
                    ELSE 0.0
                END) AS avg_grade,
                COUNT(e.studentId) AS student_count
            FROM Course c
            JOIN enrolls_in e ON c.courseId = e.courseId
            WHERE e.status = 'completed' AND e.grade IS NOT NULL
            GROUP BY c.courseId, c.title
            ORDER BY avg_grade DESC
        """
        course_grades = execute_query(course_grades_sql)

        if course_grades is None:
            course_grades = []

        # Part 2: Average grade per professor (demonstrates JOIN and AGGREGATION)
        professor_grades_sql = """
            SELECT
                p.employeeId,
                emp.name,
                AVG(CASE e.grade
                    WHEN 'A+' THEN 4.33 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.67
                    WHEN 'B+' THEN 3.33 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.67
                    WHEN 'C+' THEN 2.33 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.67
                    WHEN 'D+' THEN 1.33 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.67
                    WHEN 'F' THEN 0.0
                    ELSE 0.0
                END) AS avg_grade,
                COUNT(DISTINCT e.studentId) AS student_count,
                COUNT(DISTINCT t.courseId) AS courses_taught
            FROM Professor p
            JOIN Employee emp ON p.employeeId = emp.employeeId
            JOIN teaches t ON p.employeeId = t.employeeId
            JOIN enrolls_in e ON t.courseId = e.courseId
            WHERE e.status = 'completed' AND e.grade IS NOT NULL
            GROUP BY p.employeeId, emp.name
            ORDER BY avg_grade DESC
        """
        professor_grades = execute_query(professor_grades_sql)

        if professor_grades is None:
            professor_grades = []

        # Part 3: Use completed courses view (demonstrates VIEW)
        completed_view_sql = "SELECT * FROM completed_student_courses ORDER BY studentId, title LIMIT 50"
        completed_courses = execute_query(completed_view_sql)

        if completed_courses is None:
            completed_courses = []

        # Part 4: Use current enrollments view (demonstrates second VIEW)
        current_view_sql = "SELECT * FROM current_student_enrollments ORDER BY studentId, title LIMIT 50"
        current_enrollments = execute_query(current_view_sql)

        if current_enrollments is None:
            current_enrollments = []

        return render_template('admin/analytics.html',
                             course_grades=course_grades,
                             professor_grades=professor_grades,
                             completed_courses=completed_courses,
                             current_enrollments=current_enrollments)

    except Exception as e:
        flash('An unexpected error occurred while loading analytics.', 'error')
        print(f"Error in analytics route: {e}")
        return render_template('admin/analytics.html',
                             course_grades=[],
                             professor_grades=[],
                             completed_courses=[],
                             current_enrollments=[])
