-- ================================================================
-- Script to update the triggers with fixes
-- Run this to drop old triggers and create the fixed versions
-- ================================================================

USE CourseTracker;

-- Drop existing triggers (including old separated ones)
DROP TRIGGER IF EXISTS prereq_check;
DROP TRIGGER IF EXISTS section_capacity_check;
DROP TRIGGER IF EXISTS student_already_enrolled_check;
DROP TRIGGER IF EXISTS student_already_completed_check;
DROP TRIGGER IF EXISTS student_enrollment_status_check;

-- Recreate triggers with fixes (3 triggers total)
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
            SET MESSAGE_TEXT = 'Student already enrolled in this section!';
        ELSEIF existing_status = 'completed' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student already completed this course!';
        END IF;
    END IF;
END //
DELIMITER ;

SELECT 'Triggers updated successfully! 3 triggers now installed (combined enrollment status check).' AS status;
