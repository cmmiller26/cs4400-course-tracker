from flask import Blueprint, render_template, request, redirect, url_for, flash
from utils.db_connection import execute_query, execute_update

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/')
def index():
    """Admin dashboard/home page"""
    return render_template('admin/index.html')

@admin_bp.route('/statistics')
def statistics():
    """
    Display enrollment statistics.
    
    Query 2: Aggregation - Count enrollments by department
    """
    sql = """
        SELECT 
            d.name AS department,
            COUNT(DISTINCT e.studentId) AS student_count,
            COUNT(e.studentId) AS total_enrollments
        FROM Department d
        JOIN cross_lists cl ON d.deptId = cl.deptId
        JOIN Course c ON cl.courseId = c.courseId
        JOIN enrolls_in e ON c.courseId = e.courseId
        WHERE e.status = 'enrolled'
        GROUP BY d.deptId, d.name
        ORDER BY total_enrollments DESC
    """
    
    stats = execute_query(sql)
    
    if stats is None:
        flash('Error loading statistics', 'error')
        stats = []
    
    return render_template('admin/statistics.html', stats=stats)

@admin_bp.route('/students')
def view_students():
    """
    Display all students with their majors and advisors.
    
    Query 3: Join Student, Major, Advisor
    """
    sql = """
        SELECT 
            s.studentId,
            s.name AS studentName,
            s.year,
            m.name AS majorName,
            m.degreeType,
            e.name AS advisorName
        FROM Student s
        LEFT JOIN declares d ON s.studentId = d.studentId
        LEFT JOIN Major m ON d.majorId = m.majorId AND d.degreeType = m.degreeType
        LEFT JOIN advises a ON s.studentId = a.studentId
        LEFT JOIN Employee e ON a.employeeId = e.employeeId
        ORDER BY s.name
    """
    
    students = execute_query(sql)
    
    if students is None:
        flash('Error loading students', 'error')
        students = []
    
    return render_template('admin/students.html', students=students)

@admin_bp.route('/courses')
def manage_courses():
    """Display all courses for management"""
    sql = """
        SELECT 
            c.courseId,
            c.title,
            c.credits,
            c.building,
            e.name AS professorName
        FROM Course c
        LEFT JOIN teaches t ON c.courseId = t.courseId
        LEFT JOIN Employee e ON t.employeeId = e.employeeId
        ORDER BY c.title
    """
    
    courses = execute_query(sql)
    
    if courses is None:
        flash('Error loading courses', 'error')
        courses = []
    
    return render_template('admin/courses.html', courses=courses)