-- Procedure to update class capacity after an enrollment
DELIMITER //

CREATE PROCEDURE update_open_seats (IN courseParam INT, IN sectionParam CHAR(4))
BEGIN
	DECLARE open_seats INT;
	SELECT s.capacity - COUNT(e.studentId)
    INTO open_seats
	FROM Section s
	JOIN enrolls_in e
	ON s.courseId = e.courseId AND s.sectionNo = e.sectionNo
	WHERE s.courseId = courseParam AND s.sectionNo = sectionParam AND status = 'enrolled';
	IF open_seats <= 0 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Section at full capacity. Enrollment unavailable.';
	END IF;
END//

DELIMITER ;

-- Function to find average salary of each department
DELIMITER //

CREATE FUNCTION average_department_salary (dept_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE avg_salary DECIMAL(10,2);
  SELECT AVG(e.salary) 
  INTO avg_salary
  FROM Employee e
  JOIN Teaches t 
  ON e.employeeId = t.employeeId
  JOIN cross_lists c 
  ON t.courseId = c.courseId
  WHERE c.deptId = dept_id;
  RETURN avg_salary;
END//

DELIMITER ;
