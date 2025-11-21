-- ================================================================================
-- SECTION 6: SQL Queries
--
-- This section contains the 5+ SQL queries required by Deliverable 5.
-- Requirements met:
--   - At least 3 queries with JOINs
--   - At least 2 queries with aggregations
--   - At least 1 query with a subquery
--   - At least 1 query using a view
--
-- Each query is showcased on the website with a description.
-- ================================================================================

USE CourseTracker;

-- ==================================================
-- QUERY 1: Course Catalog with Enrollment Info
-- ==================================================
-- Description: Displays all course sections with professor, TAs, and enrollment
-- Requirements: JOIN (Section-Course), correlated subqueries
-- Website: Student Portal > Browse Courses

SELECT
    c.title,
    s.courseId,
    s.sectionNo,
    s.capacity,
    c.credits,
    (SELECT GROUP_CONCAT(cl2.code SEPARATOR ', ')
     FROM cross_lists cl2
     WHERE cl2.courseId = c.courseId) AS code,
    (SELECT prof_emp2.name
     FROM teaches t2
     JOIN Professor p2 ON t2.employeeId = p2.employeeId
     JOIN Employee prof_emp2 ON p2.employeeId = prof_emp2.employeeId
     WHERE t2.courseId = s.courseId
     LIMIT 1) AS professor,
    (SELECT GROUP_CONCAT(ta_emp2.name SEPARATOR ', ')
     FROM assists a2
     JOIN TA ta2 ON a2.employeeId = ta2.employeeId
     JOIN Employee ta_emp2 ON ta2.employeeId = ta_emp2.employeeId
     WHERE a2.courseId = s.courseId AND a2.sectionNo = s.sectionNo) AS tas,
    (SELECT COUNT(*)
     FROM enrolls_in e2
     WHERE e2.courseId = s.courseId AND e2.sectionNo = s.sectionNo
     AND e2.status = 'enrolled') AS num_enrolled
FROM Section s
JOIN Course c ON c.courseId = s.courseId
ORDER BY c.title ASC, s.sectionNo ASC;

-- ==================================================
-- QUERY 2: Student Schedule (Using View)
-- ==================================================
-- Description: Shows a student's current course schedule
-- Requirements: Uses the current_student_enrollments VIEW
-- Website: Student Portal > Dashboard

SELECT title, courseId, credits, sectionNo, grade, code, professor, tas
FROM current_student_enrollments
WHERE studentId = 4001
ORDER BY title ASC;

-- ==================================================
-- QUERY 3: GPA Calculator (Aggregation + JOIN)
-- ==================================================
-- Description: Calculates weighted GPA for a student based on completed courses
-- Requirements: JOINs (Student-enrolls_in-Course), aggregation (SUM, COUNT), GROUP BY
-- Website: Student Portal > GPA Calculator

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
WHERE s.studentId = 4001 AND e.status = 'completed' AND e.grade IS NOT NULL
GROUP BY s.studentId, s.name;

-- ==================================================
-- QUERY 4: Salary Report (Aggregation + Subquery)
-- ==================================================
-- Description: Shows employee salaries compared to role average
-- Requirements: JOIN with subquery, aggregation (AVG), GROUP BY
-- Website: Admin Portal > Salary Report

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
ORDER BY e.role, e.salary DESC;

-- ==================================================
-- QUERY 5: Grade Analytics by Course (Aggregation + JOIN)
-- ==================================================
-- Description: Shows average grade for each course
-- Requirements: JOIN (Course-enrolls_in), aggregation (AVG, COUNT), GROUP BY
-- Website: Admin Portal > Grade Analytics

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
ORDER BY avg_grade DESC;

-- ==================================================
-- QUERY 6: Grade Analytics by Professor (Aggregation + Multiple JOINs)
-- ==================================================
-- Description: Shows average grade given by each professor
-- Requirements: Multiple JOINs (Professor-Employee-teaches-enrolls_in), aggregation
-- Website: Admin Portal > Grade Analytics

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
ORDER BY avg_grade DESC;

-- ==================================================
-- Additional DML Queries Used by Website
-- ==================================================

-- INSERT: Enroll student in a course section
-- (Triggers prereq_check, section_capacity_check, student_enrollment_status_check)
-- INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
-- VALUES (?, ?, ?, 'enrolled', NULL, CURDATE());

-- DELETE: Drop a course
-- DELETE FROM enrolls_in
-- WHERE studentId = ? AND courseId = ? AND sectionNo = ? AND status = 'enrolled';

-- UPDATE: Assign a grade
-- UPDATE enrolls_in
-- SET grade = ?
-- WHERE studentId = ? AND courseId = ? AND sectionNo = ?;
