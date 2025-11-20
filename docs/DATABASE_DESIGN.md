# Database Design

## Schema Overview

The CourseTracker database models a university course management system with students, employees (professors, TAs, advisors), courses, sections, departments, colleges, majors, and academic requirements. The schema supports course enrollment, prerequisite tracking, cross-listing across departments, major declarations, and requirement fulfillment.

**Database Name**: `CourseTracker`

**ER Diagram**: See `Project_Deliverable_4.pdf` page 9 for full ER diagram with entity relationships, cardinalities, and participation constraints.

**Key Design Features**:

- Disjoint, total specialization of Employee into Professor, TA, and Advisor
- Weak entity Section dependent on Course
- Many-to-many relationships for course enrollment, teaching assignments, and advising
- Composite primary key for Major (majorId, degreeType)
- Prerequisites modeled as unary relationship on Course

---

## Tables

### Base Entities

#### College

Represents top-level academic units (e.g., College of Liberal Arts & Sciences).

**Columns**:

- `collegeId` (INTEGER, PRIMARY KEY): Unique identifier
- `name` (VARCHAR(255), NOT NULL): College name

**Relationships**: One-to-many with Department

---

#### Department

Represents academic departments within colleges.

**Columns**:

- `deptId` (INTEGER, PRIMARY KEY): Unique identifier
- `name` (VARCHAR(255), NOT NULL): Department name
- `collegeId` (INTEGER, NOT NULL, FOREIGN KEY): Parent college

**Relationships**:

- Many-to-one with College
- One-to-many with Major
- Many-to-many with Course (via cross_lists)

---

#### Employee

Supertype for all university employees in the system.

**Columns**:

- `employeeId` (INTEGER, PRIMARY KEY): Unique identifier
- `name` (VARCHAR(255), NOT NULL): Full name
- `gender` (ENUM('M', 'F', 'X')): Gender code
- `salary` (DECIMAL(10, 2), CHECK salary >= 0): Annual salary in USD
- `role` (ENUM('Professor', 'TA', 'Advisor'), NOT NULL): Employee role

**Specializations**: Professor, TA, Advisor (disjoint, total)

**Design Note**: Role is stored in Employee table for querying, but subtypes enforce referential integrity.

---

#### Professor

Subtype of Employee who teaches courses.

**Columns**:

- `employeeId` (INTEGER, PRIMARY KEY, FOREIGN KEY): References Employee

**Relationships**: Many-to-many with Course (via teaches)

---

#### TA

Subtype of Employee who assists with course sections.

**Columns**:

- `employeeId` (INTEGER, PRIMARY KEY, FOREIGN KEY): References Employee

**Relationships**: Many-to-many with Section (via assists)

---

#### Advisor

Subtype of Employee who advises students.

**Columns**:

- `employeeId` (INTEGER, PRIMARY KEY, FOREIGN KEY): References Employee

**Relationships**: Many-to-many with Student (via advises)

---

#### Student

Represents enrolled students.

**Columns**:

- `studentId` (INTEGER, PRIMARY KEY): Unique identifier
- `name` (VARCHAR(255), NOT NULL): Full name
- `gender` (ENUM('M', 'F', 'X')): Gender code
- `year` (TINYINT UNSIGNED, CHECK year > 0): Current year (1=freshman, 2=sophomore, etc.)

**Relationships**:

- Many-to-many with Section (via enrolls_in)
- Many-to-many with Advisor (via advises) - total participation
- Many-to-many with Major (via declares)

**Design Note**: GPA mentioned in data dictionary is a derived attribute, calculated from grades in enrolls_in.

---

#### Course

Represents catalog courses (e.g., "Database Systems").

**Columns**:

- `courseId` (INTEGER, PRIMARY KEY): Unique identifier
- `title` (VARCHAR(255), NOT NULL): Course title
- `credits` (TINYINT UNSIGNED, CHECK credits BETWEEN 0 AND 5): Credit hours
- `building` (VARCHAR(255)): Typical building location

**Relationships**:

- One-to-many with Section
- Many-to-many with Professor (via teaches) - total participation
- Many-to-many with Department (via cross_lists)
- Many-to-many with Requirement (via fulfills)
- Unary many-to-many with itself (via prerequisite_of)

---

#### Section (Weak Entity)

Represents specific offerings of courses.

**Columns**:

- `courseId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Parent course
- `sectionNo` (CHAR(4), PRIMARY KEY): Section identifier (e.g., '0001')
- `capacity` (SMALLINT UNSIGNED, CHECK capacity > 0): Maximum enrollment

**Relationships**:

- Many-to-one with Course (identifying relationship)
- Many-to-many with Student (via enrolls_in)
- Many-to-many with TA (via assists)

**Design Note**: Section cannot exist without Course. Primary key is (courseId, sectionNo).

---

#### Requirement

Represents academic requirement categories.

**Columns**:

- `reqId` (INTEGER, PRIMARY KEY): Unique identifier
- `name` (VARCHAR(255), NOT NULL): Requirement name
- `reqType` (ENUM('genEd', 'core', 'other'), NOT NULL): Category type

**Relationships**:

- Many-to-many with Course (via fulfills)
- Many-to-many with Major (via requires)

---

#### Major

Represents degree programs offered by departments.

**Columns**:

- `majorId` (INTEGER, PRIMARY KEY): Major identifier
- `degreeType` (ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE'), PRIMARY KEY): Degree type
- `name` (VARCHAR(255), NOT NULL): Major name
- `deptId` (INTEGER, NOT NULL, FOREIGN KEY): Offering department

**Primary Key**: Composite (majorId, degreeType)

**Relationships**:

- Many-to-one with Department
- Many-to-many with Student (via declares)
- Many-to-many with Requirement (via requires)

**Design Note**: Same major can offer different degree types (e.g., Computer Science BA vs BS).

---

### Relationship Tables

#### cross_lists

Many-to-many relationship between Department and Course with course code attribute.

**Columns**:

- `deptId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Department
- `courseId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Course
- `code` (VARCHAR(16), NOT NULL): Department-specific course code (e.g., 'CS:4400')

**Constraints**:

- Unique (deptId, code): Each department assigns unique codes
- Models cross-listing: same course offered by multiple departments

---

#### teaches

Many-to-many relationship between Professor and Course.

**Columns**:

- `employeeId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Professor
- `courseId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Course

**Participation**: Course has total participation (every course must have a professor).

---

#### assists

Many-to-many relationship between TA and Section.

**Columns**:

- `employeeId` (INTEGER, PRIMARY KEY, FOREIGN KEY): TA
- `courseId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Course (part of Section key)
- `sectionNo` (CHAR(4), PRIMARY KEY, FOREIGN KEY): Section identifier

**Note**: Foreign key references composite key (courseId, sectionNo) in Section.

---

#### advises

Many-to-many relationship between Advisor and Student.

**Columns**:

- `employeeId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Advisor
- `studentId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Student

**Participation**: Student has total participation (every student must have an advisor).

---

#### declares

Many-to-many relationship between Student and Major.

**Columns**:

- `studentId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Student
- `majorId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Major identifier
- `degreeType` (ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE'), PRIMARY KEY, FOREIGN KEY): Degree type

**Note**: Foreign key references composite key (majorId, degreeType) in Major.

---

#### enrolls_in

Many-to-many relationship between Student and Section with enrollment attributes.

**Columns**:

- `studentId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Student
- `courseId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Course (part of Section key)
- `sectionNo` (CHAR(4), PRIMARY KEY, FOREIGN KEY): Section identifier
- `status` (ENUM('enrolled', 'completed', 'withdrawn'), NOT NULL): Enrollment status
- `grade` (ENUM('A+','A','A-','B+','B','B-','C+','C','C-','D+','D','D-','F')): Final grade (NULL if not completed)
- `enrolledDate` (DATE, NOT NULL): Date of enrollment

**Design Note**: Grade is nullable to allow for currently enrolled or withdrawn courses.

---

#### fulfills

Many-to-many relationship between Course and Requirement.

**Columns**:

- `courseId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Course
- `reqId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Requirement

**Models**: Which courses satisfy which requirements.

---

#### requires

Many-to-many relationship between Major and Requirement.

**Columns**:

- `majorId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Major identifier
- `degreeType` (ENUM('BA', 'BS', 'BFA', 'BBA', 'BSE'), PRIMARY KEY, FOREIGN KEY): Degree type
- `reqId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Requirement

**Models**: Which requirements are needed for which majors.

---

#### prerequisite_of

Unary many-to-many relationship on Course for prerequisites.

**Columns**:

- `prereqCourseId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Prerequisite course
- `targetCourseId` (INTEGER, PRIMARY KEY, FOREIGN KEY): Course requiring the prerequisite

**Design Note**: Models "Course A is a prerequisite of Course B" relationship.

**Example**:

- (5001, 5002): Intro to CS is prerequisite for Data Structures
- (5002, 5005): Data Structures is prerequisite for Databases
- (5003, 5005): Discrete Math is prerequisite for Databases

---

### Authentication Table

#### app_users

Application user accounts for authentication (not part of original ER diagram).

**Columns**:

- `userId` (INTEGER, PRIMARY KEY AUTO_INCREMENT): Unique identifier
- `username` (VARCHAR(50), UNIQUE NOT NULL): Login username
- `password_hash` (VARCHAR(255), NOT NULL): Hashed password (scrypt)
- `role` (ENUM('student', 'admin'), NOT NULL): User role
- `linked_id` (INTEGER, FOREIGN KEY): Links to Student.studentId for students, NULL for admins

**Relationships**:

- Many-to-one with Student (optional, only for student role)
- Foreign key with CASCADE DELETE: If student deleted, app_users record also deleted

**Design Note**: This table enables simple authentication for demo purposes. Students have linked_id to Student table, admins have NULL linked_id. Application layer enforces this constraint.

**Test Data**:

- teststudent/student123 (role: student, linked to Student ID 4001)
- testadmin/admin123 (role: admin, no student link)

---

## Key Constraints

### Foreign Key Constraints

**Referential Integrity**: All foreign keys enforce referential integrity. MySQL default behavior (RESTRICT) prevents deletion of referenced rows.

**Important Foreign Key Relationships**:

- `Department.collegeId → College.collegeId`
- `Major.deptId → Department.deptId`
- `Section.courseId → Course.courseId` (identifying relationship for weak entity)
- `Professor.employeeId → Employee.employeeId` (subtype)
- `TA.employeeId → Employee.employeeId` (subtype)
- `Advisor.employeeId → Employee.employeeId` (subtype)
- `enrolls_in.(courseId, sectionNo) → Section.(courseId, sectionNo)` (composite foreign key)
- `assists.(courseId, sectionNo) → Section.(courseId, sectionNo)` (composite foreign key)

### Check Constraints

**Data Validation**: MySQL enforces CHECK constraints for data integrity.

- `Employee.salary >= 0`: Salary cannot be negative
- `Course.credits BETWEEN 0 AND 5`: Credits must be 0-5
- `Section.capacity > 0`: Capacity must be positive
- `Student.year > 0`: Year must be positive

### Unique Constraints

- `cross_lists (deptId, code)`: Department-specific course codes must be unique
- All primary keys implicitly have unique constraints

### ENUM Constraints

**Controlled Vocabularies**: ENUMs restrict values to predefined sets.

- `Employee.gender`: 'M', 'F', 'X'
- `Employee.role`: 'Professor', 'TA', 'Advisor'
- `Student.gender`: 'M', 'F', 'X'
- `Requirement.reqType`: 'genEd', 'core', 'other'
- `Major.degreeType`: 'BA', 'BS', 'BFA', 'BBA', 'BSE'
- `enrolls_in.status`: 'enrolled', 'completed', 'withdrawn'
- `enrolls_in.grade`: 'A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'D-', 'F'

### NOT NULL Constraints

**Required Fields**: Key attributes that cannot be NULL.

- All primary keys
- Entity names (College.name, Department.name, Employee.name, Student.name, Course.title, Requirement.name, Major.name)
- Employee.role and Employee.salary
- Department.collegeId and Major.deptId (foreign keys to required relationships)
- enrolls_in.status and enrolls_in.enrolledDate
- Requirement.reqType

### Composite Primary Keys

**Multi-column Keys**: Used where single column is insufficient.

- `Section (courseId, sectionNo)`: Section identifier requires parent course
- `Major (majorId, degreeType)`: Same major can have multiple degree types
- All relationship tables use composite keys from participating entities

---

## Sample Data

The database includes sample data (5+ rows per table) to support testing and demonstration:

- **5 Colleges**: Liberal Arts, Engineering, Business, Education, Public Health
- **5 Departments**: Computer Science, Electrical Engineering, Mathematics, Management Sciences, Biostatistics
- **15 Employees**: 5 Professors, 5 TAs, 5 Advisors
- **5 Students**: Various years and declared majors
- **5 Courses**: Intro CS, Data Structures, Discrete Math, Intro EE, Database Systems
- **5 Sections**: Various capacities for courses
- **5 Requirements**: Core CS requirements and general education
- **5 Majors**: CS BS, CS BA, EE BS, Math BS, Business Analytics BBA

**Relationships**: All relationship tables include 5+ sample records demonstrating joins, enrollments, teaching assignments, advising relationships, and prerequisite chains.

See `database/data.sql` for complete sample data.
