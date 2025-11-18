DROP DATABASE IF EXISTS CourseTracker;
CREATE DATABASE CourseTracker;
USE CourseTracker;

-- ==================================================
-- DDL: Table Defintions
-- ==================================================

-- ---------- Base Entities ----------

CREATE TABLE College (
    collegeId INTEGER      PRIMARY KEY,
    name      VARCHAR(255) NOT NULL
);

CREATE TABLE Department (
	deptId    INTEGER      PRIMARY KEY,
    name      VARCHAR(255) NOT NULL,
    collegeId INTEGER      NOT NULL,
    FOREIGN KEY (collegeId) REFERENCES College(collegeId)
);

CREATE TABLE Employee (
	employeeId INTEGER        PRIMARY KEY,
    name       VARCHAR(255)   NOT NULL,
    gender     ENUM('M', 'F', 'X'),
    salary     DECIMAL(10, 2) CHECK (salary >= 0),
    role       ENUM('Professor', 'TA', 'Advisor') NOT NULL
);

CREATE TABLE Professor (
	employeeId INTEGER PRIMARY KEY,
    FOREIGN KEY (employeeId) REFERENCES Employee(employeeId)
);

CREATE TABLE TA (
	employeeId INTEGER PRIMARY KEY,
    FOREIGN KEY (employeeId) REFERENCES Employee(employeeId)
);

CREATE TABLE Advisor (
	employeeId INTEGER PRIMARY KEY,
    FOREIGN KEY (employeeId) REFERENCES Employee(employeeId)
);

CREATE TABLE Student (
	studentId INTEGER          PRIMARY KEY,
    name      VARCHAR(255)     NOT NULL,
    gender    ENUM('M', 'F', 'X'),
    year      TINYINT UNSIGNED CHECK (year > 0)
);

CREATE TABLE Course (
	courseId INTEGER          PRIMARY KEY,
    title    VARCHAR(255)     NOT NULL,
    credits  TINYINT UNSIGNED CHECK (credits BETWEEN 0 AND 5),
    building VARCHAR(255)
);

CREATE TABLE Requirement (
	reqId   INTEGER      PRIMARY KEY,
    name    VARCHAR(255) NOT NULL,
    reqType ENUM('genEd', 'core', 'other') NOT NULL
);

CREATE TABLE Major (
	majorId    INTEGER      NOT NULL,
    degreeType ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE') NOT NULL,
    name       VARCHAR(255) NOT NULL,
    deptId     INTEGER      NOT NULL,
    PRIMARY KEY (majorId, degreeType),
    FOREIGN KEY (deptId) REFERENCES Department(deptId)
);

-- ---------- Weak Entities ----------

CREATE TABLE Section (
	courseId  INTEGER           NOT NULL,
	sectionNo CHAR(4)           NOT NULL,
    capacity  SMALLINT UNSIGNED CHECK (capacity > 0),
    PRIMARY KEY (courseId, sectionNo),
    FOREIGN KEY (courseId) REFERENCES Course(courseId)
);

-- ---------- Relationships ----------

CREATE TABLE cross_lists (
	deptId   INTEGER NOT NULL,
    courseId INTEGER NOT NULL,
    code     VARCHAR(16) NOT NULL,
    PRIMARY KEY (deptId, courseId),
    UNIQUE (deptId, code),
    FOREIGN KEY (deptId)   REFERENCES Department(deptId),
    FOREIGN KEY (courseId) REFERENCES Course(courseId)
);

CREATE TABLE teaches (
	employeeId INTEGER NOT NULL,
    courseId   INTEGER NOT NULL,
    PRIMARY KEY (employeeId, courseId),
    FOREIGN KEY (employeeId) REFERENCES Professor(employeeId),
    FOREIGN KEY (courseId)   REFERENCES Course(courseId)
);

CREATE TABLE assists (
	employeeId INTEGER NOT NULL,
    courseId   INTEGER NOT NULL,
    sectionNo  CHAR(4) NOT NULL,
    PRIMARY KEY (employeeId, courseId, sectionNo),
    FOREIGN KEY (employeeId)          REFERENCES TA(employeeId),
    FOREIGN KEY (courseId, sectionNo) REFERENCES Section(courseId, sectionNo)
);

CREATE TABLE advises (
	employeeId INTEGER NOT NULL,
    studentId  INTEGER NOT NULL,
    PRIMARY KEY (employeeId, studentId),
    FOREIGN KEY (employeeId) REFERENCES Advisor(employeeId),
    FOREIGN KEY (studentId)  REFERENCES Student(studentId)
);

CREATE TABLE declares (
	studentId  INTEGER NOT NULL,
    majorId    INTEGER NOT NULL,
    degreeType ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE') NOT NULL,
    PRIMARY KEY (studentId, majorId, degreeType),
    FOREIGN KEY (studentId)           REFERENCES Student(studentId),
    FOREIGN KEY (majorId, degreeType) REFERENCES Major(majorId, degreeType)
);

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

CREATE TABLE fulfills (
	courseId INTEGER NOT NULL,
    reqId    INTEGER NOT NULL,
    PRIMARY KEY (courseId, reqId),
    FOREIGN KEY (courseId) REFERENCES Course(courseId),
    FOREIGN KEY (reqId)    REFERENCES Requirement(reqId)
);

CREATE TABLE requires (
	majorId    INTEGER NOT NULL,
    degreeType ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE') NOT NULL,
    reqId      INTEGER NOT NULL,
    PRIMARY KEY (majorId, degreeType, reqId),
    FOREIGN KEY (majorId, degreeType) REFERENCES Major(majorId, degreeType),
    FOREIGN KEY (reqId)               REFERENCES Requirement(reqId)
);

CREATE TABLE prerequisite_of (
    prereqCourseId INTEGER NOT NULL,
    targetCourseId INTEGER NOT NULL,
    PRIMARY KEY (prereqCourseId, targetCourseId),
    FOREIGN KEY (prereqCourseId) REFERENCES Course(courseId),
    FOREIGN KEY (targetCourseId) REFERENCES Course(courseId)
);