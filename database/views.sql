USE CourseTracker;

-- ==================================================
-- View Creation
-- ==================================================
-- There are 2 views created in this file:
-- current_student_enrollments: Shows the current enrollments of all students.
-- completed_student_courses: Shows the completed courses of all students.
-- Both views are created from the admin's perspective.

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

SELECT * FROM current_student_enrollments;

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

SELECT * FROM completed_student_courses;