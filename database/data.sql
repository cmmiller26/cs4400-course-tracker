-- ==================================================
-- DML: Sample Data (>= 5 rows per table)
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

INSERT INTO Employee (employeeId, name, gender, salary, role) VALUES
(1001, 'Alice Prof',   'F', 95000.00, 'Professor'),
(1002, 'Bob Prof',     'M', 90000.00, 'Professor'),
(1003, 'Carol Prof',   'F', 98000.00, 'Professor'),
(1004, 'Dan Prof',     'M', 91000.00, 'Professor'),
(1005, 'Eve Prof',     'F', 93000.00, 'Professor'),
(2001, 'Tom TA',       'M', 20000.00, 'TA'),
(2002, 'Rita TA',      'F', 21000.00, 'TA'),
(2003, 'Sam TA',       'X', 20500.00, 'TA'),
(2004, 'Uma TA',       'F', 21500.00, 'TA'),
(2005, 'Vic TA',       'M', 22000.00, 'TA'),
(3001, 'Ann Advisor',  'F', 60000.00, 'Advisor'),
(3002, 'Bill Advisor', 'M', 62000.00, 'Advisor'),
(3003, 'Cory Advisor', 'X', 61000.00, 'Advisor'),
(3004, 'Dana Advisor', 'F', 63000.00, 'Advisor'),
(3005, 'Eli Advisor',  'M', 64000.00, 'Advisor');

-- ---------- Professor / TA / Advisor subtypes ----------

INSERT INTO Professor (employeeId) VALUES
(1001), (1002), (1003), (1004), (1005);

INSERT INTO TA (employeeId) VALUES
(2001), (2002), (2003), (2004), (2005);

INSERT INTO Advisor (employeeId) VALUES
(3001), (3002), (3003), (3004), (3005);

-- ---------- Student ----------

INSERT INTO Student (studentId, name, gender, year) VALUES
(4001, 'Student One',   'F', 1),
(4002, 'Student Two',   'M', 2),
(4003, 'Student Three', 'X', 3),
(4004, 'Student Four',  'F', 4),
(4005, 'Student Five',  'M', 3);

-- ---------- Course ----------

INSERT INTO Course (courseId, title, credits, building) VALUES
(5001, 'Intro to Computer Science', 3, 'MLH'),
(5002, 'Data Structures',           4, 'MLH'),
(5003, 'Discrete Mathematics',      3, 'PBB'),
(5004, 'Intro to Electrical Eng',   3, 'SC'),
(5005, 'Database Systems',          3, 'MLH');

-- ---------- Requirement ----------

INSERT INTO Requirement (reqId, name, reqType) VALUES
(6001, 'CS Intro Core',       'core'),
(6002, 'CS Data Structures',  'core'),
(6003, 'Math Discrete',       'core'),
(6004, 'General Education 1', 'genEd'),
(6005, 'Capstone/Other',      'other');

-- ---------- Major ----------

INSERT INTO Major (majorId, degreeType, name, deptId) VALUES
(1, 'BS',  'Computer Science BS',      10),
(1, 'BA',  'Computer Science BA',      10),
(2, 'BS',  'Electrical Engineering BS',11),
(3, 'BS',  'Mathematics BS',           12),
(4, 'BBA', 'Business Analytics BBA',   13);

-- ---------- Section (weak) ----------

INSERT INTO Section (courseId, sectionNo, capacity) VALUES
(5001, '0001', 100),
(5001, '0002',  80),
(5002, '0001',  90),
(5003, '0001',  70),
(5005, '0001',  60);

-- ---------- cross_lists (Department–Course) ----------

INSERT INTO cross_lists (deptId, courseId, code) VALUES
(10, 5001, 'CS:1210'),
(11, 5001, 'ECE:1210'),
(10, 5002, 'CS:2230'),
(12, 5003, 'MATH:1860'),
(10, 5005, 'CS:3820');

-- ---------- teaches (Professor–Course) ----------

INSERT INTO teaches (employeeId, courseId) VALUES
(1001, 5001),
(1002, 5002),
(1003, 5003),
(1004, 5004),
(1005, 5005);

-- ---------- assists (TA–Section) ----------

INSERT INTO assists (employeeId, courseId, sectionNo) VALUES
(2001, 5001, '0001'),
(2002, 5001, '0002'),
(2003, 5002, '0001'),
(2004, 5003, '0001'),
(2005, 5005, '0001');

-- ---------- advises (Advisor–Student) ----------
-- (Student has total participation here at the ER level;
--  we are ensuring every student appears in advises.)

INSERT INTO advises (employeeId, studentId) VALUES
(3001, 4001),
(3001, 4002),
(3002, 4003),
(3003, 4004),
(3004, 4005);

-- ---------- declares (Student–Major) ----------

INSERT INTO declares (studentId, majorId, degreeType) VALUES
(4001, 1, 'BS'),
(4002, 1, 'BA'),
(4003, 2, 'BS'),
(4004, 3, 'BS'),
(4005, 4, 'BBA');

-- ---------- enrolls_in (Student–Section) ----------

INSERT INTO enrolls_in (studentId, courseId, sectionNo, status, grade, enrolledDate) VALUES
(4001, 5001, '0001', 'completed', 'A',  '2024-09-01'),
(4002, 5001, '0002', 'completed', 'B+', '2024-09-01'),
(4003, 5002, '0001', 'enrolled',  NULL, '2025-01-15'),
(4004, 5003, '0001', 'completed', 'A-', '2024-09-01'),
(4005, 5005, '0001', 'enrolled',  NULL, '2025-01-20');

-- ---------- fulfills (Course–Requirement) ----------

INSERT INTO fulfills (courseId, reqId) VALUES
(5001, 6001),
(5002, 6002),
(5003, 6003),
(5004, 6004),
(5005, 6005);

-- ---------- requires (Major–Requirement) ----------

INSERT INTO requires (majorId, degreeType, reqId) VALUES
(1, 'BS',  6001),  -- CS BS requires Intro Core
(1, 'BS',  6002),  -- CS BS requires Data Structures
(1, 'BA',  6001),  -- CS BA requires Intro Core
(2, 'BS',  6004),  -- EE BS requires GenEd 1
(3, 'BS',  6003),  -- Math BS requires Discrete
(4, 'BBA', 6005);  -- Business Analytics requires Capstone/Other

-- ---------- prerequisite_of (Course–Course) ----------

INSERT INTO prerequisite_of (prereqCourseId, targetCourseId) VALUES
(5001, 5002),  -- Intro CS → Data Structures
(5002, 5005),  -- Data Structures → Databases
(5003, 5005),  -- Discrete → Databases
(5001, 5003),  -- Intro CS → Discrete
(5004, 5005);  -- Intro EE → Databases