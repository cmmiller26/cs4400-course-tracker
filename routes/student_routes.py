from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from utils.db_connection import execute_query, execute_update
from utils.auth import login_required

student_bp = Blueprint('student', __name__)

@student_bp.route('/')
@login_required(role='student')
def index():
    """Student dashboard/home page"""
    return render_template('student/index.html')

@student_bp.route('/courses')
@login_required(role='student')
def view_courses():
    """
    Display all available courses with their sections.
    
    Query 1: Join Course, Section, and cross_lists to show course catalog
    """
    sql = """
        SELECT 
            c.courseId,
            c.title,
            c.credits,
            c.building,
            s.sectionNo,
            s.capacity,
            cl.code,
            d.name AS deptName
        FROM Course c
        JOIN Section s ON c.courseId = s.courseId
        JOIN cross_lists cl ON c.courseId = cl.courseId
        JOIN Department d ON cl.deptId = d.deptId
        ORDER BY c.title, s.sectionNo
    """
    
    courses = execute_query(sql)
    
    if courses is None:
        flash('Error loading courses', 'error')
        courses = []
    
    return render_template('student/courses.html', courses=courses)

@student_bp.route('/enroll', methods=['GET', 'POST'])
@login_required(role='student')
def enroll():
    """
    Handle student enrollment in a course section.
    Demonstrates 3 triggers: prerequisite validation, capacity enforcement, and duplicate prevention.
    """
    if request.method == 'POST':
        student_id = request.form.get('student_id')
        course_id = request.form.get('course_id')
        section_no = request.form.get('section_no')

        # Insert enrollment - triggers will automatically validate
        sql = """
            INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
            VALUES (%s, %s, %s, 'enrolled', NULL, CURDATE())
        """

        result = execute_update(sql, (student_id, course_id, section_no))

        if result > 0:
            flash('✓ Successfully enrolled in course!', 'success')
        else:
            flash('✗ Enrollment failed. Check prerequisites, section capacity, or if course is already completed.', 'error')

        return redirect(url_for('student.enroll'))

    # GET request - show enrollment form with all students, courses, and sections
    students_sql = "SELECT studentId, name, year FROM Student ORDER BY name"
    students = execute_query(students_sql)

    courses_sql = "SELECT courseId, title, credits FROM Course ORDER BY title"
    courses = execute_query(courses_sql)

    sections_sql = "SELECT courseId, sectionNo, capacity FROM Section ORDER BY courseId, sectionNo"
    sections = execute_query(sections_sql)

    if students is None:
        students = []
    if courses is None:
        courses = []
    if sections is None:
        sections = []

    return render_template('student/enroll.html',
                         students=students,
                         courses=courses,
                         sections=sections)

@student_bp.route('/my-courses')
@login_required(role='student')
def my_courses():
    """
    Display courses the student is enrolled in.
    Uses the logged-in student's ID from session.
    """
    student_id = session.get('student_id')
    
    sql = """
        SELECT 
            c.title,
            c.credits,
            s.sectionNo,
            cl.code,
            e.status,
            e.grade,
            e.enrolledDate
        FROM enrolls_in e
        JOIN Section s ON e.courseId = s.courseId AND e.sectionNo = s.sectionNo
        JOIN Course c ON s.courseId = c.courseId
        JOIN cross_lists cl ON c.courseId = cl.courseId
        WHERE e.studentId = %s
        ORDER BY e.enrolledDate DESC
    """
    
    enrollments = execute_query(sql, (student_id,))
    
    if enrollments is None:
        flash('Error loading your courses', 'error')
        enrollments = []
    
    return render_template('student/my_courses.html', enrollments=enrollments)