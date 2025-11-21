from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from utils.db_connection import execute_query, execute_update, call_procedure
from utils.auth import login_required

student_bp = Blueprint('student', __name__)

@student_bp.route('/')
@login_required(role='student')
def index():
    """Student dashboard/home page"""
    return render_template('student/index.html')

# ============================================================================
# QUERY 1: Course Listing with Capacity (JOIN)
# Requirement: JOIN between Section and Course tables
# ============================================================================
@student_bp.route('/courses')
@login_required(role='student')
def courses():
    """
    Display all available course sections with title, course ID, section number,
    capacity, and credit hours using JOIN between Section and Course tables.

    SQL Requirements Met:
    - JOIN ✓
    """
    try:
        sql = """
            SELECT
                c.title,
                s.courseId,
                s.sectionNo,
                s.capacity,
                c.credits
            FROM Section s
            JOIN Course c ON c.courseId = s.courseId
            ORDER BY c.title ASC
        """

        courses = execute_query(sql)

        if courses is None:
            flash('Error loading courses. Please try again.', 'error')
            courses = []

        return render_template('student/courses.html', courses=courses)

    except Exception as e:
        flash('An unexpected error occurred while loading courses.', 'error')
        print(f"Error in courses route: {e}")
        return render_template('student/courses.html', courses=[])

# ============================================================================
# QUERY 2: Student Enrollment (INSERT + Trigger Demo + Procedure)
# Requirements: INSERT, Demonstrates 3 triggers, Calls stored procedure
# ============================================================================
@student_bp.route('/enroll', methods=['GET', 'POST'])
@login_required(role='student')
def enroll():
    """
    Enroll a student in a course section after validating prerequisites and capacity
    using triggers and the update_open_seats stored procedure.

    SQL Requirements Met:
    - INSERT ✓
    - Demonstrates 3 triggers ✓ (prereq_check, section_capacity_check, student_already_completed_check)
    - Calls stored procedure ✓ (update_open_seats)

    Triggers:
    1. prereq_check: Validates prerequisites are met
    2. section_capacity_check: Ensures section has available seats
    3. student_already_completed_check: Prevents re-enrollment in completed courses
    """
    # Get the logged-in student's ID from session
    student_id = session.get('student_id')

    if not student_id:
        flash('Student ID not found in session. Please log in again.', 'error')
        return redirect(url_for('auth.login'))

    if request.method == 'POST':
        try:
            course_id = request.form.get('course_id')
            section_no = request.form.get('section_no')

            # Validate inputs
            if not all([course_id, section_no]):
                flash('Please select both course and section.', 'error')
                return redirect(url_for('student.enroll'))

            # Step 1: Call stored procedure to update open seats
            # This demonstrates the use of stored procedures
            proc_result = call_procedure('update_open_seats', (course_id, section_no))

            # Step 2: Insert enrollment record for the logged-in student
            # This will trigger all three validation triggers
            sql = """
                INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
                VALUES (%s, %s, %s, 'enrolled', NULL, CURDATE())
            """

            result = execute_update(sql, (student_id, course_id, section_no))

            if result > 0:
                flash('✓ Successfully enrolled in course! All prerequisites met and seat reserved.', 'success')
            else:
                flash('✗ Enrollment failed. This may be due to: unmet prerequisites, section at capacity, or course already completed.', 'error')

            return redirect(url_for('student.enroll'))

        except Exception as e:
            error_msg = str(e)

            # Parse trigger error messages for user-friendly display
            if 'prereq' in error_msg.lower():
                flash('✗ Enrollment failed: Prerequisites not met for this course.', 'error')
            elif 'capacity' in error_msg.lower() or 'full' in error_msg.lower():
                flash('✗ Enrollment failed: Section is at full capacity.', 'error')
            elif 'completed' in error_msg.lower():
                flash('✗ Enrollment failed: You have already completed this course.', 'error')
            else:
                flash('✗ Enrollment failed. Please check the course requirements and try again.', 'error')

            print(f"Error in enroll route: {e}")
            return redirect(url_for('student.enroll'))

    # GET request - Load form data
    try:
        # Get the logged-in student's info
        student_sql = "SELECT studentId, name, year FROM Student WHERE studentId = %s"
        student = execute_query(student_sql, (student_id,), fetch_one=True)

        # Load all courses
        courses_sql = "SELECT courseId, title, credits FROM Course ORDER BY title"
        courses = execute_query(courses_sql)

        # Load all sections with current capacity info
        sections_sql = """
            SELECT s.courseId, s.sectionNo, s.capacity, c.title
            FROM Section s
            JOIN Course c ON s.courseId = c.courseId
            ORDER BY c.title, s.sectionNo
        """
        sections = execute_query(sections_sql)

        # Handle None results
        if courses is None:
            courses = []
        if sections is None:
            sections = []

        return render_template('student/enroll.html',
                             student=student,
                             courses=courses,
                             sections=sections)

    except Exception as e:
        flash('Error loading enrollment form. Please try again.', 'error')
        print(f"Error loading enroll form: {e}")
        return render_template('student/enroll.html',
                             student=None,
                             courses=[],
                             sections=[])

# ============================================================================
# QUERY 3: Student GPA Dashboard (AGGREGATION + JOIN + GROUP BY)
# Requirements: JOIN, Aggregation, GROUP BY
# ============================================================================
@student_bp.route('/gpa')
@login_required(role='student')
def gpa():
    """
    Calculate weighted GPA for the logged-in student based on completed courses using
    aggregation functions with JOIN and GROUP BY.

    SQL Requirements Met:
    - JOIN ✓ (Student, enrolls_in, Course)
    - Aggregation ✓ (SUM, GROUP BY)
    - GROUP BY ✓
    """
    # Get the logged-in student's ID from session
    student_id = session.get('student_id')

    if not student_id:
        flash('Student ID not found in session. Please log in again.', 'error')
        return redirect(url_for('auth.login'))

    try:
        # Calculate GPA for the logged-in student only
        sql = """
            SELECT
                s.studentId,
                s.name,
                SUM(CASE e.grade
                    WHEN 'A+' THEN 4.33 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.67
                    WHEN 'B+' THEN 3.33 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.67
                    WHEN 'C+' THEN 2.33 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.67
                    WHEN 'D+' THEN 1.33 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.67
                    WHEN 'F' THEN 0.0
                    ELSE 0.0
                END * c.credits) / NULLIF(SUM(c.credits), 0) AS gpa,
                COUNT(e.courseId) AS courses_completed,
                SUM(c.credits) AS total_credits
            FROM Student s
            JOIN enrolls_in e ON s.studentId = e.studentId
            JOIN Course c ON e.courseId = c.courseId
            WHERE s.studentId = %s AND e.status = 'completed' AND e.grade IS NOT NULL
            GROUP BY s.studentId, s.name
        """

        student_data = execute_query(sql, (student_id,), fetch_one=True)

        # Also get the student's completed courses for detailed view
        courses_sql = """
            SELECT
                c.courseId,
                c.title,
                c.credits,
                e.grade,
                e.enrolledDate,
                CASE e.grade
                    WHEN 'A+' THEN 4.33 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.67
                    WHEN 'B+' THEN 3.33 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.67
                    WHEN 'C+' THEN 2.33 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.67
                    WHEN 'D+' THEN 1.33 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.67
                    WHEN 'F' THEN 0.0
                    ELSE 0.0
                END AS grade_points
            FROM enrolls_in e
            JOIN Course c ON e.courseId = c.courseId
            WHERE e.studentId = %s AND e.status = 'completed' AND e.grade IS NOT NULL
            ORDER BY e.enrolledDate DESC
        """

        completed_courses = execute_query(courses_sql, (student_id,))

        if completed_courses is None:
            completed_courses = []

        return render_template('student/gpa.html',
                             student_data=student_data,
                             completed_courses=completed_courses)

    except Exception as e:
        flash('An unexpected error occurred while calculating your GPA.', 'error')
        print(f"Error in gpa route: {e}")
        return render_template('student/gpa.html',
                             student_data=None,
                             completed_courses=[])
