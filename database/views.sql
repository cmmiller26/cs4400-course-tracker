USE CourseTracker;

-- ==================================================
-- View Creation
-- ==================================================
-- There are 2 views created in this file:
-- current_student_enrollments: Shows the current enrollments of all students.
-- completed_student_courses: Shows the completed courses of all students.
-- Both views are created from the admin's perspective.

CREATE VIEW current_student_enrollments AS
SELECT s.studentId, s.name, s.gender, s.year, c.title, c.credits, se.sectionNo, se.capacity, e.status, e.grade, e.enrolledDate
FROM Student s
JOIN enrolls_in e ON s.studentId = e.studentId
JOIN Section se ON e.sectionNo = se.sectionNo
JOIN Course c ON se.courseId = c.courseId
WHERE e.status = 'enrolled';

SELECT * FROM current_student_enrollments;

CREATE VIEW completed_student_courses AS
SELECT s.studentId, s.name, s.gender, s.year, c.title, c.credits, se.sectionNo, e.status, e.grade, e.enrolledDate
FROM Student s
JOIN enrolls_in e ON s.studentId = e.studentId
JOIN Section se ON e.sectionNo = se.sectionNo
JOIN Course c ON se.courseId = c.courseId
WHERE e.status = 'completed';

SELECT * FROM completed_student_courses;