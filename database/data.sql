-- ================================================================================
-- SECTION 2: DML (Data Manipulation Language) - Sample Data
--
-- This section populates the database with sample data. Each table has at least
-- 5 tuples to demonstrate joins, aggregations, and other SQL operations.
-- ================================================================================

USE CourseTracker;

-- ==================================================
-- 2.1 Base Entity Data
-- ==================================================

-- ---------- College ----------

INSERT INTO College (collegeId, name) VALUES
(1, 'College of Liberal Arts & Sciences'),
(2, 'College of Engineering'),
(3, 'College of Business'),
(4, 'College of Education'),
(5, 'College of Public Health');

-- ---------- Department ----------

INSERT INTO Department (deptId, name, collegeId) VALUES
(10, 'Computer Science',        1),
(11, 'Electrical Engineering',  2),
(12, 'Mathematics',             1),
(13, 'Management Sciences',     3),
(14, 'Biostatistics',           5);

-- ---------- Employee ----------
-- Includes Professors, TAs, and Advisors with varied salaries for reporting

INSERT INTO Employee (employeeId, name, gender, salary, role) VALUES
-- Professors (salary range: 85k-105k)
(1001, 'Dr. Sarah Chen',      'F', 98000.00, 'Professor'),
(1002, 'Dr. Michael Roberts', 'M', 92000.00, 'Professor'),
(1003, 'Dr. Emily Watson',    'F', 105000.00, 'Professor'),
(1004, 'Dr. James Miller',    'M', 88000.00, 'Professor'),
(1005, 'Dr. Linda Garcia',    'F', 95000.00, 'Professor'),
-- Teaching Assistants (salary range: 18k-24k)
(2001, 'Alex Thompson',  'M', 20000.00, 'TA'),
(2002, 'Maria Santos',   'F', 21500.00, 'TA'),
(2003, 'Jordan Lee',     'X', 19500.00, 'TA'),
(2004, 'Priya Patel',    'F', 22000.00, 'TA'),
(2005, 'Kevin O''Brien', 'M', 23000.00, 'TA'),
-- Academic Advisors (salary range: 55k-68k)
(3001, 'Nancy Adams',    'F', 62000.00, 'Advisor'),
(3002, 'Robert Kim',     'M', 58000.00, 'Advisor'),
(3003, 'Taylor Morgan',  'X', 65000.00, 'Advisor'),
(3004, 'Jennifer Liu',   'F', 60000.00, 'Advisor'),
(3005, 'David Brown',    'M', 67000.00, 'Advisor');

-- ---------- Professor / TA / Advisor subtypes ----------
-- Disjoint specialization of Employee

INSERT INTO Professor (employeeId) VALUES
(1001), (1002), (1003), (1004), (1005);

INSERT INTO TA (employeeId) VALUES
(2001), (2002), (2003), (2004), (2005);

INSERT INTO Advisor (employeeId) VALUES
(3001), (3002), (3003), (3004), (3005);

-- ---------- Student ----------
-- 12 students across different years for meaningful enrollment data

INSERT INTO Student (studentId, name, gender, year) VALUES
(4001, 'Emma Johnson',     'F', 2),  -- Sophomore, test account student
(4002, 'Liam Williams',    'M', 3),  -- Junior
(4003, 'Olivia Brown',     'F', 4),  -- Senior
(4004, 'Noah Davis',       'M', 1),  -- Freshman
(4005, 'Ava Martinez',     'F', 3),  -- Junior
(4006, 'Ethan Anderson',   'M', 2),  -- Sophomore
(4007, 'Sophia Taylor',    'F', 4),  -- Senior
(4008, 'Mason Thomas',     'M', 2),  -- Sophomore
(4009, 'Isabella Jackson', 'F', 3),  -- Junior
(4010, 'Lucas White',      'M', 1),  -- Freshman
(4011, 'Mia Harris',       'F', 4),  -- Senior
(4012, 'Oliver Clark',     'M', 2);  -- Sophomore

-- ---------- Course ----------
-- 8 courses to provide variety for enrollments and prerequisites

INSERT INTO Course (courseId, title, credits, building) VALUES
(5001, 'Intro to Computer Science',  3, 'MLH'),
(5002, 'Data Structures',            4, 'MLH'),
(5003, 'Discrete Mathematics',       3, 'MLH'),
(5004, 'Intro to Electrical Eng',    3, 'SC'),
(5005, 'Database Systems',           3, 'MLH'),
(5006, 'Algorithms',                 3, 'MLH'),
(5007, 'Software Engineering',       3, 'MLH'),
(5008, 'Calculus I',                 4, 'MLH');

-- ---------- Requirement ----------

INSERT INTO Requirement (reqId, name, reqType) VALUES
(6001, 'CS Intro Core',        'core'),
(6002, 'CS Data Structures',   'core'),
(6003, 'Math Discrete',        'core'),
(6004, 'General Education 1',  'genEd'),
(6005, 'CS Elective',          'other'),
(6006, 'Math Foundation',      'core');

-- ---------- Major ----------

INSERT INTO Major (majorId, degreeType, name, deptId) VALUES
(1, 'BS',  'Computer Science BS',       10),
(1, 'BA',  'Computer Science BA',       10),
(2, 'BS',  'Electrical Engineering BS', 11),
(3, 'BS',  'Mathematics BS',            12),
(4, 'BBA', 'Business Analytics BBA',    13);

-- ---------- Section (weak entity) ----------
-- Multiple sections per course for enrollment variety
-- Intro CS has 3 sections, Data Structures has 2 sections
-- Algorithms section 0001 has capacity of 3 (will be at max capacity)

INSERT INTO Section (courseId, sectionNo, capacity) VALUES
(5001, '0001', 100),  -- Intro CS Section 1
(5001, '0002', 80),   -- Intro CS Section 2
(5001, '0003', 60),   -- Intro CS Section 3
(5002, '0001', 90),   -- Data Structures Section 1
(5002, '0002', 75),   -- Data Structures Section 2
(5003, '0001', 70),   -- Discrete Math
(5004, '0001', 60),   -- Intro EE
(5005, '0001', 50),   -- Database Systems
(5006, '0001', 3),    -- Algorithms (small capacity - will be FULL)
(5007, '0001', 40),   -- Software Engineering
(5008, '0001', 120);  -- Calculus I

-- ---------- cross_lists (Department-Course) ----------
-- Shows how courses are listed across departments with course codes

INSERT INTO cross_lists (deptId, courseId, code) VALUES
(10, 5001, 'CS:1210'),    -- Intro CS in CS dept
(11, 5001, 'ECE:1210'),   -- Intro CS cross-listed in ECE
(10, 5002, 'CS:2230'),    -- Data Structures
(12, 5003, 'MATH:2100'),  -- Discrete Math in Math dept
(10, 5003, 'CS:2100'),    -- Discrete Math cross-listed in CS
(11, 5004, 'ECE:1100'),   -- Intro EE
(10, 5005, 'CS:4400'),    -- Database Systems
(10, 5006, 'CS:3330'),    -- Algorithms
(10, 5007, 'CS:3910'),    -- Software Engineering
(12, 5008, 'MATH:1850');  -- Calculus I

-- ---------- teaches (Professor-Course) ----------
-- Total participation: every course must have a professor

INSERT INTO teaches (employeeId, courseId) VALUES
(1001, 5001),  -- Dr. Chen teaches Intro CS
(1002, 5002),  -- Dr. Roberts teaches Data Structures
(1003, 5003),  -- Dr. Watson teaches Discrete Math
(1004, 5004),  -- Dr. Miller teaches Intro EE
(1005, 5005),  -- Dr. Garcia teaches Database Systems
(1001, 5006),  -- Dr. Chen also teaches Algorithms
(1002, 5007),  -- Dr. Roberts also teaches Software Eng
(1003, 5008);  -- Dr. Watson also teaches Calculus

-- ---------- assists (TA-Section) ----------

INSERT INTO assists (employeeId, courseId, sectionNo) VALUES
(2001, 5001, '0001'),  -- Alex assists Intro CS Sec 1
(2002, 5001, '0002'),  -- Maria assists Intro CS Sec 2
(2004, 5001, '0003'),  -- Priya assists Intro CS Sec 3
(2003, 5002, '0001'),  -- Jordan assists Data Structures Sec 1
(2005, 5002, '0002'),  -- Kevin assists Data Structures Sec 2
(2004, 5003, '0001'),  -- Priya also assists Discrete Math
(2005, 5005, '0001'),  -- Kevin also assists Database Systems
(2001, 5006, '0001'),  -- Alex also assists Algorithms
(2003, 5008, '0001');  -- Jordan also assists Calculus

-- ---------- advises (Advisor-Student) ----------
-- Total participation: every student must have an advisor

INSERT INTO advises (employeeId, studentId) VALUES
(3001, 4001),  -- Nancy advises Emma
(3001, 4002),  -- Nancy advises Liam
(3001, 4003),  -- Nancy advises Olivia
(3002, 4004),  -- Robert advises Noah
(3002, 4005),  -- Robert advises Ava
(3003, 4006),  -- Taylor advises Ethan
(3003, 4007),  -- Taylor advises Sophia
(3004, 4008),  -- Jennifer advises Mason
(3004, 4009),  -- Jennifer advises Isabella
(3005, 4010),  -- David advises Lucas
(3005, 4011),  -- David advises Mia
(3005, 4012);  -- David advises Oliver

-- ---------- declares (Student-Major) ----------

INSERT INTO declares (studentId, majorId, degreeType) VALUES
(4001, 1, 'BS'),   -- Emma: CS BS
(4002, 1, 'BS'),   -- Liam: CS BS
(4003, 1, 'BA'),   -- Olivia: CS BA
(4004, 2, 'BS'),   -- Noah: EE BS
(4005, 1, 'BS'),   -- Ava: CS BS
(4006, 3, 'BS'),   -- Ethan: Math BS
(4007, 1, 'BS'),   -- Sophia: CS BS
(4008, 4, 'BBA'), -- Mason: Business Analytics
(4009, 1, 'BA'),   -- Isabella: CS BA
(4010, 2, 'BS'),   -- Lucas: EE BS
(4011, 1, 'BS'),   -- Mia: CS BS
(4012, 3, 'BS');   -- Oliver: Math BS

-- ---------- enrolls_in (Student-Section) ----------
-- Comprehensive enrollment data with completed courses and current enrollments
-- This data supports GPA calculations, grade analytics, and enrollment reports

INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate) VALUES
-- ========== COMPLETED ENROLLMENTS (for grade analytics) ==========

-- Emma Johnson (4001) - Sophomore, 3 completed courses
(4001, 5001, '0001', 'completed', 'A',  '2023-08-21'),  -- Intro CS: A
(4001, 5003, '0001', 'completed', 'A-', '2024-01-15'),  -- Discrete Math: A-
(4001, 5002, '0001', 'completed', 'A',  '2024-08-19'),  -- Data Structures: A

-- Liam Williams (4002) - Junior, 4 completed courses
(4002, 5001, '0002', 'completed', 'B+', '2022-08-22'),  -- Intro CS: B+
(4002, 5008, '0001', 'completed', 'B',  '2022-08-22'),  -- Calculus: B
(4002, 5003, '0001', 'completed', 'B-', '2023-01-17'),  -- Discrete Math: B-
(4002, 5002, '0001', 'completed', 'B',  '2023-08-21'),  -- Data Structures: B

-- Olivia Brown (4003) - Senior, 5 completed courses
(4003, 5001, '0001', 'completed', 'A',  '2021-08-23'),  -- Intro CS: A
(4003, 5008, '0001', 'completed', 'A-', '2021-08-23'),  -- Calculus: A-
(4003, 5003, '0001', 'completed', 'A',  '2022-01-18'),  -- Discrete Math: A
(4003, 5002, '0001', 'completed', 'A-', '2022-08-22'),  -- Data Structures: A-
(4003, 5006, '0001', 'completed', 'B+', '2023-01-17'),  -- Algorithms: B+

-- Noah Davis (4004) - Freshman, 1 completed course
(4004, 5004, '0001', 'completed', 'B',  '2023-08-21'),  -- Intro EE: B

-- Ava Martinez (4005) - Junior, 4 completed courses
(4005, 5001, '0001', 'completed', 'A-', '2022-08-22'),  -- Intro CS: A-
(4005, 5008, '0001', 'completed', 'B+', '2022-08-22'),  -- Calculus: B+
(4005, 5003, '0001', 'completed', 'B+', '2023-01-17'),  -- Discrete Math: B+
(4005, 5002, '0001', 'completed', 'A-', '2023-08-21'),  -- Data Structures: A-

-- Ethan Anderson (4006) - Sophomore, 2 completed courses
(4006, 5008, '0001', 'completed', 'A',  '2023-08-21'),  -- Calculus: A
(4006, 5003, '0001', 'completed', 'A',  '2024-01-15'),  -- Discrete Math: A

-- Sophia Taylor (4007) - Senior, 6 completed courses (most advanced)
(4007, 5001, '0002', 'completed', 'A+', '2021-08-23'),  -- Intro CS: A+
(4007, 5008, '0001', 'completed', 'A',  '2021-08-23'),  -- Calculus: A
(4007, 5003, '0001', 'completed', 'A',  '2022-01-18'),  -- Discrete Math: A
(4007, 5002, '0001', 'completed', 'A',  '2022-08-22'),  -- Data Structures: A
(4007, 5006, '0001', 'completed', 'A-', '2023-01-17'),  -- Algorithms: A-
(4007, 5007, '0001', 'completed', 'A',  '2023-08-21'),  -- Software Eng: A

-- Mason Thomas (4008) - Sophomore, 2 completed courses
(4008, 5001, '0001', 'completed', 'C+', '2023-08-21'),  -- Intro CS: C+
(4008, 5008, '0001', 'completed', 'C',  '2023-08-21'),  -- Calculus: C

-- Isabella Jackson (4009) - Junior, 3 completed courses
(4009, 5001, '0002', 'completed', 'B',  '2022-08-22'),  -- Intro CS: B
(4009, 5008, '0001', 'completed', 'B-', '2022-08-22'),  -- Calculus: B-
(4009, 5003, '0001', 'completed', 'C+', '2023-01-17'),  -- Discrete Math: C+

-- Lucas White (4010) - Freshman, 1 completed course
(4010, 5004, '0001', 'completed', 'A-', '2023-08-21'),  -- Intro EE: A-

-- Mia Harris (4011) - Senior, 4 completed courses (currently in Algorithms)
(4011, 5001, '0001', 'completed', 'B+', '2021-08-23'),  -- Intro CS: B+
(4011, 5008, '0001', 'completed', 'B',  '2021-08-23'),  -- Calculus: B
(4011, 5003, '0001', 'completed', 'B+', '2022-01-18'),  -- Discrete Math: B+
(4011, 5002, '0001', 'completed', 'B',  '2022-08-22'),  -- Data Structures: B

-- Oliver Clark (4012) - Sophomore, 2 completed courses
(4012, 5008, '0001', 'completed', 'B+', '2023-08-21'),  -- Calculus: B+
(4012, 5003, '0001', 'completed', 'B',  '2024-01-15'),  -- Discrete Math: B

-- ========== CURRENT ENROLLMENTS (Spring 2025) ==========

-- Emma (4001) - no current enrollments

-- Liam (4002) - currently in Algorithms (has prereqs: Data Structures)
(4002, 5006, '0001', 'enrolled', NULL, '2025-01-13'),

-- Olivia (4003) - currently in Database Systems (has all prereqs)
(4003, 5005, '0001', 'enrolled', NULL, '2025-01-13'),

-- Noah (4004) - currently in Intro CS
(4004, 5001, '0001', 'enrolled', NULL, '2025-01-13'),

-- Ava (4005) - currently in Algorithms
(4005, 5006, '0001', 'enrolled', NULL, '2025-01-13'),

-- Mia (4011) - currently in Algorithms (THIS FILLS THE SECTION TO CAPACITY: 3/3)
(4011, 5006, '0001', 'enrolled', NULL, '2025-01-13'),

-- Sophia (4007) - currently in Database Systems
(4007, 5005, '0001', 'enrolled', NULL, '2025-01-13'),

-- Mason (4008) - currently in Discrete Math
(4008, 5003, '0001', 'enrolled', NULL, '2025-01-13'),

-- Isabella (4009) - currently in Data Structures
(4009, 5002, '0001', 'enrolled', NULL, '2025-01-13'),

-- Lucas (4010) - currently in Intro CS
(4010, 5001, '0002', 'enrolled', NULL, '2025-01-13'),

-- Oliver (4012) - currently in Intro CS (wants to learn programming)
(4012, 5001, '0001', 'enrolled', NULL, '2025-01-13');

-- ========== WITHDRAWN ENROLLMENT (to show all statuses) ==========
-- Ethan withdrew from Intro CS
INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate) VALUES
(4006, 5001, '0001', 'withdrawn', NULL, '2024-08-19');

-- ---------- fulfills (Course-Requirement) ----------

INSERT INTO fulfills (courseId, reqId) VALUES
(5001, 6001),  -- Intro CS fulfills CS Intro Core
(5002, 6002),  -- Data Structures fulfills CS Data Structures
(5003, 6003),  -- Discrete Math fulfills Math Discrete
(5004, 6004),  -- Intro EE fulfills GenEd
(5005, 6005),  -- Database Systems fulfills CS Elective
(5006, 6005),  -- Algorithms fulfills CS Elective
(5007, 6005),  -- Software Eng fulfills CS Elective
(5008, 6006);  -- Calculus fulfills Math Foundation

-- ---------- requires (Major-Requirement) ----------

INSERT INTO requires (majorId, degreeType, reqId) VALUES
(1, 'BS',  6001),  -- CS BS requires Intro Core
(1, 'BS',  6002),  -- CS BS requires Data Structures
(1, 'BS',  6003),  -- CS BS requires Discrete Math
(1, 'BS',  6006),  -- CS BS requires Math Foundation
(1, 'BA',  6001),  -- CS BA requires Intro Core
(1, 'BA',  6002),  -- CS BA requires Data Structures
(2, 'BS',  6004),  -- EE BS requires GenEd
(3, 'BS',  6003),  -- Math BS requires Discrete
(3, 'BS',  6006),  -- Math BS requires Math Foundation
(4, 'BBA', 6005);  -- Business Analytics requires Elective

-- ---------- prerequisite_of (Course-Course) ----------
-- Defines prerequisite chains for course enrollment validation

INSERT INTO prerequisite_of (prereqCourseId, targetCourseId) VALUES
(5001, 5002),  -- Intro CS -> Data Structures
(5001, 5003),  -- Intro CS -> Discrete Math
(5002, 5005),  -- Data Structures -> Database Systems
(5003, 5005),  -- Discrete Math -> Database Systems
(5002, 5006),  -- Data Structures -> Algorithms
(5002, 5007),  -- Data Structures -> Software Engineering
(5008, 5003);  -- Calculus -> Discrete Math
