-- ================================================================================
-- SECTION 4: Triggers (CREATE TRIGGER)
--
-- This section creates 3 triggers as required by Deliverable 5.
-- All triggers fire BEFORE INSERT on enrolls_in to validate enrollment requests.
-- The website enrollment page demonstrates these triggers in action.
-- ================================================================================

USE CourseTracker;

-- ==================================================
-- TRIGGER 1: prereq_check
-- ==================================================
-- Purpose: Validates that student has completed all prerequisites
-- Fires: BEFORE INSERT on enrolls_in
-- Demo: Try enrolling in Database Systems without completing Data Structures

DELIMITER //
CREATE TRIGGER prereq_check
BEFORE INSERT ON enrolls_in
FOR EACH ROW
BEGIN
    DECLARE missing_prereqs INT;

    -- Count prerequisites that the student has NOT completed
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

    IF missing_prereqs > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Prerequisite(s) not met';
    END IF;
END //
DELIMITER ;

-- ==================================================
-- TRIGGER 2: section_capacity_check
-- ==================================================
-- Purpose: Prevents enrollment when section is at full capacity
-- Fires: BEFORE INSERT on enrolls_in
-- Demo: Try enrolling in Algorithms section 0001 (capacity 3, already full)

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

    -- Only count currently enrolled students (not completed or withdrawn)
    SELECT COUNT(*) INTO section_enrolled
    FROM enrolls_in
    WHERE enrolls_in.courseId = NEW.courseId
    AND enrolls_in.sectionNo = NEW.sectionNo
    AND enrolls_in.status = 'enrolled';

    IF section_enrolled >= section_capacity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Section is full!';
    END IF;
END //
DELIMITER ;

-- ==================================================
-- TRIGGER 3: student_enrollment_status_check
-- ==================================================
-- Purpose: Prevents duplicate enrollment or re-enrollment in completed courses
-- Fires: BEFORE INSERT on enrolls_in
-- Demo: Try enrolling in a course you've already completed

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
