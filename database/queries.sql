-- Select query to look for classes
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
	-- Enrolled students count
	(SELECT COUNT(*) 
	FROM enrolls_in e2 
	WHERE e2.courseId = s.courseId AND e2.sectionNo = s.sectionNo) AS num_enrolled
FROM Section s
JOIN Course c ON c.courseId = s.courseId
ORDER BY c.title ASC, s.sectionNo ASC;

-- Insert query for enrollment
INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
VALUES (%s, %s, %s, 'enrolled', NULL, CURDATE());

-- Delete query for dropping a course
DELETE FROM enrolls_in
WHERE studentId = %s AND courseId = %s AND sectionNo = %s AND status = 'enrolled';

-- Aggregate to calculate GPA
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
GROUP BY s.studentId, s.name;

-- Aggregate to show individual and average salary
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
