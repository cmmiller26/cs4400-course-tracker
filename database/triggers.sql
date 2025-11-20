USE CourseTracker;

-- ==================================================
-- Trigger Creation
-- ==================================================
-- There are 3 triggers created in this file:
-- prereq_check: Checks if the prerequisite for a course has been met.
-- section_capacity_check: Checks if the section is full.
-- student_already_completed_check: Checks if the student has already completed the course.

DELIMITER //
CREATE TRIGGER prereq_check
BEFORE INSERT ON enrolls_in
FOR EACH ROW
BEGIN
    DECLARE prereq_met BOOLEAN;
    DECLARE prereq_course_id INTEGER;
    DECLARE prereq_section_no CHAR(4);
    DECLARE prereq_course_title VARCHAR(255);
    DECLARE prereq_course_credits TINYINT UNSIGNED;
    DECLARE prereq_course_building VARCHAR(255);

    SELECT prerequisite_of.prereqCourseId
    INTO prereq_course_id
    FROM prerequisite_of
    WHERE prerequisite_of.targetCourseId = NEW.courseId;

    IF prereq_course_id IS NOT NULL THEN
        SELECT section.sectionNo INTO prereq_section_no
        FROM Section
        WHERE Section.courseId = prereq_course_id;

        SELECT Course.title INTO prereq_course_title
        FROM Course
        WHERE Course.courseId = prereq_course_id;

        SELECT Course.credits INTO prereq_course_credits
        FROM Course
        WHERE Course.courseId = prereq_course_id;

        SELECT Course.building INTO prereq_course_building
        FROM Course
        WHERE Course.courseId = prereq_course_id;

        IF prereq_section_no IS NOT NULL THEN
            SELECT COUNT(*) INTO prereq_met
            FROM enrolls_in
            WHERE enrolls_in.courseId = prereq_course_id
            AND enrolls_in.sectionNo = prereq_section_no
            AND enrolls_in.status = 'completed';

            IF prereq_met = 0 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Prerequisite(s) not met';
            END IF;
        END IF;
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
CREATE TRIGGER student_already_completed_check
BEFORE INSERT ON enrolls_in
FOR EACH ROW
BEGIN
    DECLARE student_already_completed BOOLEAN;
    SELECT COUNT(*) INTO student_already_completed
    FROM enrolls_in
    WHERE enrolls_in.studentId = NEW.studentId
    AND enrolls_in.courseId = NEW.courseId
    AND enrolls_in.sectionNo = NEW.sectionNo
    AND enrolls_in.status = 'completed';

    IF student_already_completed > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Student already completed this course!';
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