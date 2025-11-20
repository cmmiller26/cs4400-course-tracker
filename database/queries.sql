-- Select query to look for classes
SELECT c.title, s.courseId, s.sectionNo, s.capacity, c.credits
FROM Section s
JOIN Course c
ON c.courseId = s.courseId
ORDER BY c.title ASC;
-- Insert query for enrollment
INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate) VALUES
(4005, 5003, '0001', 'enrolled', NULL, CURRENT_DATE);
-- Delete a student when they drop a class
DELETE FROM enrolls_in
WHERE (studentId = '4005' AND courseId = '5003' AND sectionNo = '0001' AND 
status = 'enrolled' AND status = NULL AND enrollmentDate IS NOT NULL);
-- Update query to change student grade
UPDATE enrolls_in
SET grade = ''
WHERE (studentId = '' AND courseId = '' AND sectionNo = '' AND 
status = '' AND status = '' AND enrollmentDate IS NOT NULL);
-- Aggregate to calculate GPA
SELECT studentId, SUM(
	CASE e.grade
		WHEN 'A+' THEN 4.3
        WHEN 'A' THEN 4.0
        WHEN 'A-' THEN 3.7
        WHEN 'B+' THEN 3.3
        WHEN 'B' THEN 3.0
        WHEN 'B-' THEN 2.7
        WHEN 'C+' THEN 2.3
        WHEN 'C' THEN 2.0
        WHEN 'C-' THEN 1.7
        WHEN 'D+' THEN 1.3
        WHEN 'D' THEN 1.0
        WHEN 'D-' THEN 0.3
        WHEN 'F' THEN 0.0
	END * credits) / SUM(credits) AS GPA
FROM enrolls_in e
JOIN course c
ON e.courseId = c.courseId
GROUP BY studentId;
-- Aggregate to show individual and average salary
SELECT e.name, e.role, e.salary, S.average_salary
FROM (
	SELECT role, AVG(salary) AS average_salary
    FROM employee
    GROUP BY role
    ) AS S
JOIN Employee e
ON S.role = e.role;
-- Aggregate to show average grade per class
SELECT  DISTINCT c.title, S.average_grade
FROM (
	SELECT courseId, AVG(CASE 
		WHEN grade = 'A+' THEN 4.3
		WHEN grade = 'A' THEN 4
		WHEN grade = 'A-' THEN 3.7
		WHEN grade = 'B+' THEN 3.3
		WHEN grade = 'B' THEN 3.0
		WHEN grade = 'B-' THEN 2.7
		WHEN grade = 'C+' THEN 2.3
		WHEN grade = 'C' THEN 2.0
		WHEN grade = 'C-' THEN 1.7
		WHEN grade = 'D+' THEN 1.3
		WHEN grade = 'D' THEN 1.0
		WHEN grade = 'D-' THEN 0.3
		WHEN grade = 'F' THEN 0.0
	END) AS average_grade
FROM enrolls_in
GROUP BY courseId) AS S
JOIN enrolls_in e
ON S.courseId = e.courseId
JOIN Course c
ON e.courseId = c.courseId;
-- Aggregate to show average grade each professor gives
SELECT  DISTINCT p.employeeId, e1.name, S.average_grade
FROM (SELECT courseId, AVG(CASE 
		WHEN grade = 'A+' THEN 4.3
		WHEN grade = 'A' THEN 4
		WHEN grade = 'A-' THEN 3.7
		WHEN grade = 'B+' THEN 3.3
		WHEN grade = 'B' THEN 3.0
		WHEN grade = 'B-' THEN 2.7
		WHEN grade = 'C+' THEN 2.3
		WHEN grade = 'C' THEN 2.0
		WHEN grade = 'C-' THEN 1.7
		WHEN grade = 'D+' THEN 1.3
		WHEN grade = 'D' THEN 1.0
		WHEN grade = 'D-' THEN 0.3
		WHEN grade = 'F' THEN 0.0
	END) AS average_grade
FROM enrolls_in
GROUP BY courseId) AS S
JOIN enrolls_in e
ON S.courseId = e.courseId
JOIN Teaches t
ON e.courseId = t.courseId
JOIN Professor p
ON t.employeeId = p.employeeId
JOIN Employee e1
ON e1.employeeId = p.employeeId;
