USE CourseTracker;

-- ==================================================
-- Trigger Creation
-- ==================================================
-- There are 3 triggers created in this file:
-- prereq_check: Checks if the prerequisite for a course has been met.
-- section_capacity_check: Checks if the section is full.
-- student_enrollment_status_check: Checks if the student is already enrolled or has completed the course.

DELIMITER //
CREATE TRIGGER prereq_check
BEFORE INSERT ON enrolls_in
FOR EACH ROW
BEGIN
    DECLARE missing_prereqs INT;

    -- Check if student has completed all prerequisites for this course
    -- Count how many prerequisites exist that the student has NOT completed
    SELECT COUNT(*)
    INTO missing_prereqs
    FROM prerequisite_of p
    WHERE p.targetCourseId = NEW.courseId
    AND NOT EXISTS (
        SELECT 1
        FROM enrolls_in e
        WHERE e.studentId = NEW.studentId
        AND e.courseId = p.prereqCourseId
        AND e.status = 'completed'
    );

    -- If any prerequisites are missing, block the enrollment
    IF missing_prereqs > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Prerequisite(s) not met';
    END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER section_capacity_check
BEFORE INSERT ON enrolls_in
FOR EACH ROW
BEGIN
    DECLARE section_capacity INTEGER;
    DECLARE section_enrolled INTEGER;

    SELECT Section.capacity INTO section_capacity
    FROM Section
    WHERE Section.courseId = NEW.courseId
    AND Section.sectionNo = NEW.sectionNo;

    SELECT COUNT(*) INTO section_enrolled
    FROM enrolls_in
    WHERE enrolls_in.courseId = NEW.courseId
    AND enrolls_in.sectionNo = NEW.sectionNo;

    IF section_enrolled >= section_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Section is full!';
    END IF;
END //
DELIMITER ;

--
DELIMITER //
CREATE TRIGGER student_enrollment_status_check
BEFORE INSERT ON enrolls_in
FOR EACH ROW
BEGIN
    DECLARE existing_status VARCHAR(20);

    -- Check if student has any existing enrollment for this course
    SELECT enrolls_in.status INTO existing_status
    FROM enrolls_in
    WHERE enrolls_in.studentId = NEW.studentId
    AND enrolls_in.courseId = NEW.courseId
    LIMIT 1;

    -- If a record exists, throw appropriate error based on status
    IF existing_status IS NOT NULL THEN
        IF existing_status = 'enrolled' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student already enrolled in this course!';
        ELSEIF existing_status = 'completed' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student already completed this course!';
        END IF;
    END IF;
END //
DELIMITER ;

-- ==================================================
-- Trigger Regression Tests
-- ==================================================
-- Transaction is created with test data, and then it is
-- rolled back safely after verifying the expected behavior,
-- to avoid test data being permanently added.

-- ---------- example of failing prereq_check trigger ----------
START TRANSACTION;
INSERT INTO Course (courseId, title, credits, building)
VALUES (5006, 'Algorithms', 3, 'MLH'),
       (5007, 'Artificial Intelligence', 3, 'MLH');
INSERT INTO Section (courseId, sectionNo, capacity)
VALUES (5006, '0001', 30),
       (5007, '0001', 30);
INSERT INTO Student (studentId, name, gender, year)
VALUES (4006, 'Student 6', 'X', 3);
INSERT INTO prerequisite_of (prereqCourseId, targetCourseId)
VALUES (5006, 5007);
/* Student 6 hasn't taken Algorithms yet, but
is trying to enroll in Artificial Intelligence,
which requires Algorithms as a prerequisite.
Thus, 'Prerequisite(s) not met' error message is thrown */
INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
VALUES (4006, 5007, '0001', 'enrolled', NULL, '2024-01-20');
ROLLBACK;

-- ---------- example of failing section_capacity_check trigger ----------
START TRANSACTION;
INSERT INTO Course (courseId, title, credits, building)
VALUES (5008, 'Computer Organization', 3, 'EPB');
INSERT INTO Section (courseId, sectionNo, capacity)
VALUES (5008, '0001', 1); -- only 1 to avoid numerous inserts into enrolls_in
INSERT INTO Student (studentId, name, gender, year)
VALUES (4007, 'Student 7', 'F', 2),
       (4008, 'Student 8', 'M', 2);
INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
VALUES (4007, 5008, '0001', 'enrolled', NULL, '2024-01-20');
/* Since Student 7 already has enrolled in Computer Organization,
and the capacity for that class is 1, 'Section is full!' error
message will be thrown when Student 8 tries to enroll in that class. */
INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
VALUES (4008, 5008, '0001', 'enrolled', NULL, '2024-01-20');
ROLLBACK;

-- ---------- example of failing student_already_completed_check trigger ----------
START TRANSACTION;
INSERT INTO Course (courseId, title, credits, building)
VALUES (5009, 'Applied Linear Regression', 3, 'SH');
INSERT INTO Section (courseId, sectionNo, capacity)
VALUES (5009, '0001', 30);
INSERT INTO Student (studentId, name, gender, year)
VALUES (4009, 'Student 9', 'F', 4);
INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
VALUES (4009, 5009, '0001', 'completed', 'B', '2023-05-16');
/* Student 8 has already completed Applied Linear Regression,
but is trying to reenroll in it. Thus, 'Student already 
completed this course!' error message will be thrown. */
INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate)
VALUES (4009, 5009, '0001', 'enrolled', NULL, '2023-08-21');
ROLLBACK;