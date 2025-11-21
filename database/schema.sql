-- ================================================================================
-- CS:4400 Database Systems - Deliverable 5
-- CourseTracker Database Implementation
-- Team: Colin Miller, Manthan Shah, Jack Janik
-- ================================================================================
-- SECTION 1: DDL (Data Definition Language)
--
-- This section creates all database tables with:
--   - Appropriate data types for each attribute
--   - Constraints: NOT NULL, UNIQUE, CHECK, DEFAULT
--   - Primary keys and foreign keys with referential actions
-- ================================================================================

DROP DATABASE IF EXISTS CourseTracker;
CREATE DATABASE CourseTracker;
USE CourseTracker;

-- ==================================================
-- 1.1 Base Entity Tables
-- ==================================================

-- College: Academic colleges within the university
CREATE TABLE College (
    collegeId INTEGER      PRIMARY KEY,
    name      VARCHAR(255) NOT NULL
);

-- Department: Academic departments belonging to colleges
CREATE TABLE Department (
    deptId    INTEGER      PRIMARY KEY,
    name      VARCHAR(255) NOT NULL,
    collegeId INTEGER      NOT NULL,
    FOREIGN KEY (collegeId) REFERENCES College(collegeId)
);

-- Employee: Base table for all university employees (Professor, TA, Advisor)
-- Uses disjoint specialization pattern
CREATE TABLE Employee (
    employeeId INTEGER        PRIMARY KEY,
    name       VARCHAR(255)   NOT NULL,
    gender     ENUM('M', 'F', 'X'),
    salary     DECIMAL(10, 2) CHECK (salary >= 0),
    role       ENUM('Professor', 'TA', 'Advisor') NOT NULL
);

-- Professor: Subtype of Employee (disjoint specialization)
CREATE TABLE Professor (
    employeeId INTEGER PRIMARY KEY,
    FOREIGN KEY (employeeId) REFERENCES Employee(employeeId)
);

-- TA (Teaching Assistant): Subtype of Employee (disjoint specialization)
CREATE TABLE TA (
    employeeId INTEGER PRIMARY KEY,
    FOREIGN KEY (employeeId) REFERENCES Employee(employeeId)
);

-- Advisor: Subtype of Employee (disjoint specialization)
CREATE TABLE Advisor (
    employeeId INTEGER PRIMARY KEY,
    FOREIGN KEY (employeeId) REFERENCES Employee(employeeId)
);

-- Student: University students with year classification
CREATE TABLE Student (
    studentId INTEGER          PRIMARY KEY,
    name      VARCHAR(255)     NOT NULL,
    gender    ENUM('M', 'F', 'X'),
    year      TINYINT UNSIGNED CHECK (year > 0)
);

-- Course: Catalog courses offered by the university
CREATE TABLE Course (
    courseId INTEGER          PRIMARY KEY,
    title    VARCHAR(255)     NOT NULL,
    credits  TINYINT UNSIGNED CHECK (credits BETWEEN 0 AND 5),
    building VARCHAR(255)
);

-- Requirement: Academic requirements (genEd, core, other)
CREATE TABLE Requirement (
    reqId   INTEGER      PRIMARY KEY,
    name    VARCHAR(255) NOT NULL,
    reqType ENUM('genEd', 'core', 'other') NOT NULL
);

-- Major: Degree programs with composite primary key (majorId, degreeType)
CREATE TABLE Major (
    majorId    INTEGER      NOT NULL,
    degreeType ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE') NOT NULL,
    name       VARCHAR(255) NOT NULL,
    deptId     INTEGER      NOT NULL,
    PRIMARY KEY (majorId, degreeType),
    FOREIGN KEY (deptId) REFERENCES Department(deptId)
);

-- ==================================================
-- 1.2 Weak Entity Tables
-- ==================================================

-- Section: Weak entity dependent on Course (composite key includes courseId)
CREATE TABLE Section (
    courseId  INTEGER           NOT NULL,
    sectionNo CHAR(4)           NOT NULL,
    capacity  SMALLINT UNSIGNED CHECK (capacity > 0),
    PRIMARY KEY (courseId, sectionNo),
    FOREIGN KEY (courseId) REFERENCES Course(courseId)
);

-- ==================================================
-- 1.3 Relationship Tables
-- ==================================================

-- cross_lists: M:N relationship between Department and Course
-- Stores department-specific course codes (e.g., CS:1210, ECE:1210)
CREATE TABLE cross_lists (
    deptId   INTEGER NOT NULL,
    courseId INTEGER NOT NULL,
    code     VARCHAR(16) NOT NULL,
    PRIMARY KEY (deptId, courseId),
    UNIQUE (deptId, code),
    FOREIGN KEY (deptId)   REFERENCES Department(deptId),
    FOREIGN KEY (courseId) REFERENCES Course(courseId)
);

-- teaches: M:N relationship between Professor and Course
-- Total participation: every Course must have a Professor
CREATE TABLE teaches (
    employeeId INTEGER NOT NULL,
    courseId   INTEGER NOT NULL,
    PRIMARY KEY (employeeId, courseId),
    FOREIGN KEY (employeeId) REFERENCES Professor(employeeId),
    FOREIGN KEY (courseId)   REFERENCES Course(courseId)
);

-- assists: M:N relationship between TA and Section
CREATE TABLE assists (
    employeeId INTEGER NOT NULL,
    courseId   INTEGER NOT NULL,
    sectionNo  CHAR(4) NOT NULL,
    PRIMARY KEY (employeeId, courseId, sectionNo),
    FOREIGN KEY (employeeId)          REFERENCES TA(employeeId),
    FOREIGN KEY (courseId, sectionNo) REFERENCES Section(courseId, sectionNo)
);

-- advises: M:N relationship between Advisor and Student
-- Total participation: every Student must have an Advisor
CREATE TABLE advises (
    employeeId INTEGER NOT NULL,
    studentId  INTEGER NOT NULL,
    PRIMARY KEY (employeeId, studentId),
    FOREIGN KEY (employeeId) REFERENCES Advisor(employeeId),
    FOREIGN KEY (studentId)  REFERENCES Student(studentId)
);

-- declares: M:N relationship between Student and Major
CREATE TABLE declares (
    studentId  INTEGER NOT NULL,
    majorId    INTEGER NOT NULL,
    degreeType ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE') NOT NULL,
    PRIMARY KEY (studentId, majorId, degreeType),
    FOREIGN KEY (studentId)           REFERENCES Student(studentId),
    FOREIGN KEY (majorId, degreeType) REFERENCES Major(majorId, degreeType)
);

-- enrolls_in: M:N relationship between Student and Section
-- Tracks enrollment status, grades, and enrollment date
CREATE TABLE enrolls_in (
    studentId    INTEGER NOT NULL,
    courseId     INTEGER NOT NULL,
    sectionNo    CHAR(4) NOT NULL,
    status       ENUM('enrolled', 'completed', 'withdrawn') NOT NULL,
    grade        ENUM('A+','A','A-','B+','B','B-',
                      'C+','C','C-','D+','D','D-','F') NULL,
    enrolledDate DATE    NOT NULL,
    PRIMARY KEY (studentId, courseId, sectionNo),
    FOREIGN KEY (studentId)           REFERENCES Student(studentId),
    FOREIGN KEY (courseId, sectionNo) REFERENCES Section(courseId, sectionNo)
);

-- fulfills: M:N relationship between Course and Requirement
CREATE TABLE fulfills (
    courseId INTEGER NOT NULL,
    reqId    INTEGER NOT NULL,
    PRIMARY KEY (courseId, reqId),
    FOREIGN KEY (courseId) REFERENCES Course(courseId),
    FOREIGN KEY (reqId)    REFERENCES Requirement(reqId)
);

-- requires: M:N relationship between Major and Requirement
CREATE TABLE requires (
    majorId    INTEGER NOT NULL,
    degreeType ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE') NOT NULL,
    reqId      INTEGER NOT NULL,
    PRIMARY KEY (majorId, degreeType, reqId),
    FOREIGN KEY (majorId, degreeType) REFERENCES Major(majorId, degreeType),
    FOREIGN KEY (reqId)               REFERENCES Requirement(reqId)
);

-- prerequisite_of: Unary M:N relationship on Course (self-referencing)
-- Defines which courses are prerequisites for other courses
CREATE TABLE prerequisite_of (
    prereqCourseId INTEGER NOT NULL,
    targetCourseId INTEGER NOT NULL,
    PRIMARY KEY (prereqCourseId, targetCourseId),
    FOREIGN KEY (prereqCourseId) REFERENCES Course(courseId),
    FOREIGN KEY (targetCourseId) REFERENCES Course(courseId)
);
