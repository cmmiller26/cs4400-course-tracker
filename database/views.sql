-- ================================================================================
-- SECTION 3: Views (CREATE VIEW)
--
-- This section creates 2 relational views as required by Deliverable 5.
-- These views simplify common queries and demonstrate view creation skills.
-- ================================================================================

USE CourseTracker;

-- ==================================================
-- VIEW 1: current_student_enrollments
-- ==================================================
-- Purpose: Shows all currently enrolled students with course details
-- Used by: Student dashboard to display current schedule
-- Demonstrates: JOINs across 4 tables, correlated subqueries

CREATE VIEW current_student_enrollments AS
SELECT
    s.studentId,
    s.name AS studentName,
    s.gender,
    s.year,
    c.courseId,
    c.title,
    c.credits,
    se.sectionNo,
    se.capacity,
    e.status,
    e.grade,
    e.enrolledDate,
    (SELECT GROUP_CONCAT(cl.code SEPARATOR ', ')
     FROM cross_lists cl
     WHERE cl.courseId = c.courseId) AS code,
    (SELECT prof_emp.name
     FROM teaches t
     JOIN Professor p ON t.employeeId = p.employeeId
     JOIN Employee prof_emp ON p.employeeId = prof_emp.employeeId
     WHERE t.courseId = c.courseId
     LIMIT 1) AS professor,
    (SELECT GROUP_CONCAT(ta_emp.name SEPARATOR ', ')
     FROM assists a
     JOIN TA ta ON a.employeeId = ta.employeeId
     JOIN Employee ta_emp ON ta.employeeId = ta_emp.employeeId
     WHERE a.courseId = c.courseId AND a.sectionNo = se.sectionNo) AS tas
FROM Student s
JOIN enrolls_in e ON s.studentId = e.studentId
JOIN Section se ON e.courseId = se.courseId AND e.sectionNo = se.sectionNo
JOIN Course c ON se.courseId = c.courseId
WHERE e.status = 'enrolled';

-- ==================================================
-- VIEW 2: completed_student_courses
-- ==================================================
-- Purpose: Shows all completed courses with grades and grade points
-- Used by: GPA calculator and transcript generation
-- Demonstrates: JOINs, CASE expression for grade point conversion

CREATE VIEW completed_student_courses AS
SELECT
    s.studentId,
    s.name AS studentName,
    s.gender,
    s.year,
    c.courseId,
    c.title,
    c.credits,
    se.sectionNo,
    e.status,
    e.grade,
    e.enrolledDate,
    (SELECT GROUP_CONCAT(cl.code SEPARATOR ', ')
     FROM cross_lists cl
     WHERE cl.courseId = c.courseId) AS code,
    CASE e.grade
        WHEN 'A+' THEN 4.33 WHEN 'A' THEN 4.0 WHEN 'A-' THEN 3.67
        WHEN 'B+' THEN 3.33 WHEN 'B' THEN 3.0 WHEN 'B-' THEN 2.67
        WHEN 'C+' THEN 2.33 WHEN 'C' THEN 2.0 WHEN 'C-' THEN 1.67
        WHEN 'D+' THEN 1.33 WHEN 'D' THEN 1.0 WHEN 'D-' THEN 0.67
        WHEN 'F' THEN 0.0
        ELSE 0.0
    END AS grade_points
FROM Student s
JOIN enrolls_in e ON s.studentId = e.studentId
JOIN Section se ON e.courseId = se.courseId AND e.sectionNo = se.sectionNo
JOIN Course c ON se.courseId = c.courseId
WHERE e.status = 'completed';
