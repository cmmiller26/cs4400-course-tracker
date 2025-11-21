-- ============================================================================
-- Authentication Table for CourseTracker
-- ============================================================================
-- This file creates the app_users table for simple authentication
-- Two test accounts are created: one student and one admin
-- Passwords are hashed using werkzeug.security.generate_password_hash()
--
-- Test Accounts:
-- - Username: 'teststudent', Password: 'student123', Role: student, Links to Student ID 4001
-- - Username: 'testadmin', Password: 'admin123', Role: admin, No student link
-- ============================================================================

USE CourseTracker;

-- Drop table if it exists (for clean re-runs)
DROP TABLE IF EXISTS app_users;

-- Create app_users table
CREATE TABLE app_users (
    userId INTEGER PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('student', 'admin') NOT NULL,
    linked_id INTEGER,
    
    -- Foreign key to Student table with CASCADE delete
    -- If student is deleted from Student table, their app_users record is also deleted
    CONSTRAINT fk_app_users_student
        FOREIGN KEY (linked_id)
        REFERENCES Student(studentId)
        ON DELETE CASCADE
        ON UPDATE CASCADE
        
    -- Note: Check constraint for role-based linked_id validation removed due to MySQL limitation
    -- Application layer will enforce: students must have linked_id, admins must not
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert test accounts with properly hashed passwords
-- Password hashes generated using werkzeug.security.generate_password_hash()
-- NOTE: For the convenience of project setup and grading, these are valid, pre-generated
-- hashes for the test accounts. In a production environment, hashes should not be
-- committed to version control.

-- Test Student Account
-- Username: teststudent
-- Password: student123
INSERT INTO app_users (username, password_hash, role, linked_id) VALUES (
    'teststudent',
    'scrypt:32768:8:1$ukzXW2fUf8KkGkWg$b29448b599fa5a11c17e1c0cd02072a06d313ed801e69a6d1a040304c5551219dd23e02c7f79c0883cf7ed9c22b95df0919da3721e5668de3fa752b5071305cd',
    'student',
    4001
);

-- Test Admin Account
-- Username: testadmin
-- Password: admin123
INSERT INTO app_users (username, password_hash, role, linked_id) VALUES (
    'testadmin',
    'scrypt:32768:8:1$7N27tlmGBpRWbHbX$6464eeb1c4811db4cbc6bc4cf53c70ce1a0761fe016b1c355d39aa18e9a195e9b5bc8c4c1292f456474ca57f00457b7aeb86a61f37884864dee465a51dcc454f',
    'admin',
    NULL
);

-- Verification queries removed for automated initialization
-- To verify manually, run:
-- SELECT userId, username, role, linked_id FROM app_users;
