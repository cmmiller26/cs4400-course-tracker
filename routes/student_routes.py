from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from utils.db_connection import execute_query, execute_update, call_procedure
from utils.auth import login_required

student_bp = Blueprint('student', __name__)

@student_bp.route('/')
@login_required(role='student')
def index():
    """Student dashboard/home page with current enrollments"""
    # Get the logged-in student's ID from session
    student_id = session.get('student_id')

    if not student_id:
        flash('Student ID not found in session. Please log in again.', 'error')
        return redirect(url_for('auth.login'))

    try:
        # Get current enrollments using the current_student_enrollments view
        current_enrollments_sql = """
            SELECT title, courseId, credits, sectionNo, grade, code, professor, tas
            FROM current_student_enrollments
            WHERE studentId = %s
            ORDER BY title ASC
        """

        current_enrollments = execute_query(current_enrollments_sql, (student_id,))

        if current_enrollments is None:
            current_enrollments = []

        return render_template('student/index.html', current_enrollments=current_enrollments)

    except Exception as e:
        flash('Error loading current enrollments.', 'error')
        print(f"Error in student index route: {e}")
        return render_template('student/index.html', current_enrollments=[])

# ============================================================================
# QUERY 1: Course Listing with Capacity (JOIN)
# Requirement: JOIN between Section and Course tables
# ============================================================================
@student_bp.route('/courses')
@login_required(role='student')
def courses():
    """
    Display all available course sections with detailed information including
    course code, professor, TAs, and enrollment numbers.
    """
    try:
        sql = """
            SELECT
                c.title,
                s.courseId,
                s.sectionNo,
                s.capacity,
                c.credits,
                -- Cross-listed codes
                (SELECT GROUP_CONCAT(cl2.code SEPARATOR ', ') 
                FROM cross_lists cl2 
                WHERE cl2.courseId = c.courseId) AS code,
                -- Professor name
                (SELECT prof_emp2.name 
                FROM teaches t2 
                JOIN Professor p2 ON t2.employeeId = p2.employeeId
                JOIN Employee prof_emp2 ON p2.employeeId = prof_emp2.employeeId
                WHERE t2.courseId = s.courseId
                LIMIT 1) AS professor,
                -- TA names
                (SELECT GROUP_CONCAT(ta_emp2.name SEPARATOR ', ')
                FROM assists a2
                JOIN TA ta2 ON a2.employeeId = ta2.employeeId
                JOIN Employee ta_emp2 ON ta2.employeeId = ta_emp2.employeeId
                WHERE a2.courseId = s.courseId AND a2.sectionNo = s.sectionNo) AS tas,
                -- Enrolled students count (only currently enrolled, not completed/withdrawn)
                (SELECT COUNT(*)
                FROM enrolls_in e2
                WHERE e2.courseId = s.courseId AND e2.sectionNo = s.sectionNo
                AND e2.status = 'enrolled') AS num_enrolled
            FROM Section s
            JOIN Course c ON c.courseId = s.courseId
            ORDER BY c.title ASC, s.sectionNo ASC
        """

        courses = execute_query(sql)
        
        # Debug: Print what we got back
        print(f"DEBUG: courses = {courses}")
        print(f"DEBUG: type = {type(courses)}")
        
        if courses is None:
            flash('Error loading courses. Database query returned None.', 'error')
            courses = []
        elif isinstance(courses, list) and len(courses) == 0:
            flash('No courses found in the database.', 'info')
        elif isinstance(courses, list):
            flash(f'Successfully loaded {len(courses)} courses.', 'success')

        return render_template('student/courses.html', courses=courses or [])

    except Exception as e:
        flash(f'Database error: {str(e)}', 'error')
        print(f"Error in courses route: {e}")
        import traceback
        traceback.print_exc()
        return render_template('student/courses.html', courses=[])

# ============================================================================
# Drop Course Route (DELETE)
# ============================================================================
@student_bp.route('/drop/<course_id>/<int:section_no>', methods=['POST'])
@login_required(role='student')
def drop_course(course_id, section_no):
    """
    Drop a course by deleting the enrollment record.
    """
    student_id = session.get('student_id')

    if not student_id:
        flash('Student ID not found in session. Please log in again.', 'error')
        return redirect(url_for('auth.login'))

    try:
        # Delete the enrollment record
        sql = """
            DELETE FROM enrolls_in
            WHERE studentId = %s AND courseId = %s AND sectionNo = %s AND status = 'enrolled'
        """

        execute_update(sql, (student_id, course_id, section_no))

        # Call stored procedure to update open seats
        call_procedure('update_open_seats', (course_id, section_no))

        flash('✓ Successfully dropped the course.', 'success')
        return redirect(url_for('student.index'))

    except Exception as e:
        flash(f'✗ Error dropping course: {str(e)}', 'error')
        print(f"Error in drop_course route: {e}")
        return redirect(url_for('student.index'))

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
            call_procedure('update_open_seats', (course_id, section_no))

            # Step 2: Insert enrollment record for the logged-in student
            # This will trigger all 3 validation triggers (prereq, capacity, enrollment status)
            sql = """
                INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
                VALUES (%s, %s, %s, 'enrolled', NULL, CURDATE())
            """

            # If this succeeds, the enrollment was successful (all triggers passed)
            # If any trigger fails, an exception will be raised and caught below
            execute_update(sql, (student_id, course_id, section_no))
            flash('✓ Successfully enrolled in course! All prerequisites met and seat reserved.', 'success')
            return redirect(url_for('student.enroll'))

        except Exception as e:
            error_msg = str(e)
            course_id = request.form.get('course_id')
            section_no = request.form.get('section_no')

            # Parse trigger error messages for user-friendly display with specific details
            if 'already enrolled' in error_msg.lower() or 'Student already enrolled' in error_msg or 'Duplicate entry' in error_msg:
                # Student is already enrolled in this section
                flash('✗ Enrollment failed: You are already enrolled in this course section.', 'error')

            elif 'prereq' in error_msg.lower() or 'Prerequisite(s) not met' in error_msg:
                # Student has not met prerequisites
                flash('✗ Enrollment failed: Prerequisites not met for this course.', 'error')

            elif 'full' in error_msg.lower() or 'Section is full!' in error_msg:
                # Section is at full capacity
                flash('✗ Enrollment failed: Section is at full capacity.', 'error')

            elif 'completed' in error_msg.lower() or 'Student already completed this course!' in error_msg:
                # Student has already completed the course
                flash('✗ Enrollment failed: You have already completed this course.', 'error')
            else:
                # Unknown error - show the raw message for debugging
                flash(f'✗ Enrollment failed: {error_msg}', 'error')

            print(f"Error in enroll route: {e}")
            return redirect(url_for('student.enroll'))

    # GET request - Load form data
    try:
        # Get the logged-in student's info
        student_sql = "SELECT studentId, name, year FROM Student WHERE studentId = %s"
        student = execute_query(student_sql, (student_id,), fetch_one=True)

        # Load all courses with cross-listed codes
        courses_sql = """
            SELECT c.courseId, c.title, c.credits,
                (SELECT GROUP_CONCAT(cl.code SEPARATOR ', ')
                FROM cross_lists cl
                WHERE cl.courseId = c.courseId) AS code
            FROM Course c
            ORDER BY c.title
        """
        courses = execute_query(courses_sql)

        # Load all sections with capacity, professor, and enrolled counts
        sections_sql = """
            SELECT s.courseId, s.sectionNo, s.capacity,
                -- Enrolled student count
                (SELECT COUNT(*)
                FROM enrolls_in ei
                WHERE ei.courseId = s.courseId
                    AND ei.sectionNo = s.sectionNo
                    AND ei.status = 'enrolled') AS num_enrolled
            FROM Section s
            JOIN Course c ON c.courseId = s.courseId
            ORDER BY s.courseId, s.sectionNo
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

        # Get completed courses using the completed_student_courses view
        completed_courses_sql = """
            SELECT courseId, title, credits, sectionNo, grade, enrolledDate, code, grade_points
            FROM completed_student_courses
            WHERE studentId = %s AND grade IS NOT NULL
            ORDER BY enrolledDate DESC
        """

        completed_courses = execute_query(completed_courses_sql, (student_id,))

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
