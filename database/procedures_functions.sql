-- ================================================================================
-- SECTION 5: Stored Procedures and Functions
--
-- This section creates 1 stored procedure and 1 function as required by
-- Deliverable 5. At least one includes input parameters.
-- ================================================================================

USE CourseTracker;

-- ==================================================
-- PROCEDURE: update_open_seats
-- ==================================================
-- Purpose: Validates section capacity before enrollment
-- Parameters: courseParam (INT), sectionParam (CHAR(4))
-- Called by: Enrollment page before inserting into enrolls_in
-- Demonstrates: Input parameters, JOIN, aggregation, conditional logic

DELIMITER //
CREATE PROCEDURE update_open_seats (IN courseParam INT, IN sectionParam CHAR(4))
BEGIN
    DECLARE open_seats INT;

    SELECT s.capacity - COUNT(e.studentId)
    INTO open_seats
    FROM Section s
    LEFT JOIN enrolls_in e
        ON s.courseId = e.courseId
        AND s.sectionNo = e.sectionNo
        AND e.status = 'enrolled'
    WHERE s.courseId = courseParam AND s.sectionNo = sectionParam
    GROUP BY s.capacity;

    IF open_seats <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Section at full capacity. Enrollment unavailable.';
    END IF;
END //
DELIMITER ;

-- ==================================================
-- FUNCTION: average_department_salary
-- ==================================================
-- Purpose: Calculates average salary of professors in a department
-- Parameters: dept_id (INT)
-- Returns: DECIMAL(10,2) - the average salary
-- Demonstrates: Input parameter, JOINs, aggregation (AVG)

DELIMITER //
CREATE FUNCTION average_department_salary (dept_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE avg_salary DECIMAL(10,2);

    SELECT AVG(e.salary)
    INTO avg_salary
    FROM Employee e
    JOIN teaches t ON e.employeeId = t.employeeId
    JOIN cross_lists c ON t.courseId = c.courseId
    WHERE c.deptId = dept_id;

    RETURN avg_salary;
END //
DELIMITER ;
