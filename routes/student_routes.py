from flask import Blueprint, render_template, request, redirect, url_for, flash
from utils.db_connection import execute_query, execute_update

student_bp = Blueprint('student', __name__)

@student_bp.route('/')
def index():
    """Student dashboard/home page"""
    return render_template('student/index.html')

@student_bp.route('/courses')
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
def enroll():
    """
    Handle student enrollment in a course section.
    For demo purposes, we'll use a fixed studentId (4001).
    In production, this would come from session/authentication.
    """
    if request.method == 'POST':
        student_id = request.form.get('studentId', 4001)  # Default for demo
        course_id = request.form.get('courseId')
        section_no = request.form.get('sectionNo')
        
        # Insert enrollment
        sql = """
            INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
            VALUES (%s, %s, %s, 'enrolled', NULL, CURDATE())
        """
        
        result = execute_update(sql, (student_id, course_id, section_no))
        
        if result > 0:
            flash('Successfully enrolled in course!', 'success')
        else:
            flash('Error enrolling in course. You may already be enrolled or section is full.', 'error')
        
        return redirect(url_for('student.view_courses'))
    
    # GET request - show enrollment form
    course_id = request.args.get('courseId')
    section_no = request.args.get('sectionNo')
    
    if not course_id or not section_no:
        flash('Invalid course or section', 'error')
        return redirect(url_for('student.view_courses'))
    
    # Get course details
    sql = """
        SELECT c.title, c.credits, s.sectionNo, s.capacity, cl.code
        FROM Course c
        JOIN Section s ON c.courseId = s.courseId
        JOIN cross_lists cl ON c.courseId = cl.courseId
        WHERE c.courseId = %s AND s.sectionNo = %s
        LIMIT 1
    """
    
    course = execute_query(sql, (course_id, section_no), fetch_one=True)
    
    if not course:
        flash('Course not found', 'error')
        return redirect(url_for('student.view_courses'))
    
    return render_template('student/enroll.html', 
                         course=course, 
                         courseId=course_id, 
                         sectionNo=section_no)

@student_bp.route('/my-courses')
def my_courses():
    """
    Display courses the student is enrolled in.
    For demo purposes, we'll use studentId = 4001.
    """
    student_id = 4001  # Fixed for demo
    
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