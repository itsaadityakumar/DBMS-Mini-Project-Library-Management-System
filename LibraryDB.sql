-- =====================================================================
-- DBMS Mini Project : Library Management System
-- Name  : Aditya Kumar
-- Roll  : 2419158
-- Branch: CSE - A
-- =====================================================================

-- 1. CREATE DATABASE ---------------------------------------------------
DROP DATABASE IF EXISTS LibraryDB;
CREATE DATABASE LibraryDB;
USE LibraryDB;

-- 2. CREATE TABLES -----------------------------------------------------
CREATE TABLE Students (
    student_id   INT PRIMARY KEY AUTO_INCREMENT,
    roll_no      VARCHAR(15)  NOT NULL UNIQUE,
    name         VARCHAR(50)  NOT NULL,
    department   VARCHAR(30)  NOT NULL,
    email        VARCHAR(60)  UNIQUE,
    phone        VARCHAR(15),
    campus       VARCHAR(30)  DEFAULT 'Main Campus'
);

CREATE TABLE Books (
    book_id           INT PRIMARY KEY AUTO_INCREMENT,
    title             VARCHAR(100) NOT NULL,
    author            VARCHAR(60)  NOT NULL,
    category          VARCHAR(30)  NOT NULL,
    price             DECIMAL(8,2) CHECK (price > 0),
    total_copies      INT NOT NULL CHECK (total_copies >= 0),
    available_copies  INT NOT NULL CHECK (available_copies >= 0),
    CHECK (available_copies <= total_copies)
);

-- Book_Issue stores both issue and return information.
-- return_date IS NULL  -> book not yet returned
CREATE TABLE Book_Issue (
    issue_id     INT PRIMARY KEY AUTO_INCREMENT,
    student_id   INT  NOT NULL,
    book_id      INT  NOT NULL,
    issue_date   DATE NOT NULL,
    due_date     DATE NOT NULL,
    return_date  DATE NULL,
    fine         DECIMAL(6,2) DEFAULT 0,
    FOREIGN KEY (student_id) REFERENCES Students(student_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id)    REFERENCES Books(book_id)       ON DELETE CASCADE,
    CHECK (due_date >= issue_date)
);

-- 3. INSERT SAMPLE DATA -------------------------------------------------
INSERT INTO Students (roll_no, name, department, email, phone, campus) VALUES
('2419158', 'Aditya Kumar', 'CSE', 'aditya.kumar@college.edu', '9876500001', 'Main Campus'),
('2419101', 'Rohan Sharma', 'CSE', 'rohan.sharma@college.edu', '9876500002', 'Main Campus'),
('2419202', 'Simran Kaur',  'ECE', 'simran.kaur@college.edu',   '9876500003', 'North Campus'),
('2419303', 'Priya Verma',  'ME',  'priya.verma@college.edu',   '9876500004', 'North Campus'),
('2419404', 'Karan Singh',  'IT',  'karan.singh@college.edu',   '9876500005', 'Main Campus'),
('2419505', 'Neha Gupta',   'CSE', 'neha.gupta@college.edu',    '9876500006', 'South Campus');

INSERT INTO Books (title, author, category, price, total_copies, available_copies) VALUES
('Database System Concepts',          'Silberschatz',      'DBMS',      850.00, 5, 5),
('Fundamentals of Database Systems',  'Elmasri & Navathe', 'DBMS',      790.00, 4, 4),
('Operating System Concepts',         'Galvin',            'OS',        820.00, 3, 3),
('Computer Networks',                 'Tanenbaum',         'Networks',  700.00, 4, 4),
('Introduction to Algorithms',        'Cormen',            'Algorithms',950.00, 3, 3),
('Let Us C',                          'Yashavant Kanetkar','Programming',350.00,6, 6),
('Java: The Complete Reference',      'Herbert Schildt',   'Programming',650.00,5, 5),
('Python Crash Course',               'Eric Matthes',      'Programming',500.00,4, 4),
('Artificial Intelligence',           'Russell & Norvig',  'AI',        900.00, 2, 2),
('Digital Logic Design',              'Morris Mano',       'Electronics',450.00,3, 3);

-- Issue records (some returned, some still pending)
INSERT INTO Book_Issue (student_id, book_id, issue_date, due_date, return_date, fine) VALUES
(1, 1, '2026-10-01', '2026-10-15', '2026-10-14', 0),
(1, 5, '2026-10-20', '2026-11-03', NULL,         0),
(2, 3, '2026-10-05', '2026-10-19', '2026-10-25', 12),
(3, 4, '2026-10-10', '2026-10-24', NULL,         0),
(4, 6, '2026-10-12', '2026-10-26', '2026-10-26', 0),
(5, 8, '2026-10-28', '2026-11-11', NULL,         0),
(2, 2, '2026-11-01', '2026-11-15', NULL,         0);

-- Keep available_copies in sync with currently issued (unreturned) books
UPDATE Books b
SET available_copies = total_copies -
    (SELECT COUNT(*) FROM Book_Issue i
     WHERE i.book_id = b.book_id AND i.return_date IS NULL);

-- 4. QUERIES ------------------------------------------------------------

-- Q1. Display all available books
SELECT book_id, title, author, category, available_copies
FROM Books
WHERE available_copies > 0;

-- Q2. Display all student details
SELECT * FROM Students;

-- Q3. Books issued to a particular student (Aditya Kumar, roll 2419158)
SELECT s.name, b.title, b.author, i.issue_date, i.due_date,
       IFNULL(i.return_date, 'Not Returned') AS return_status
FROM Book_Issue i
JOIN Students s ON s.student_id = i.student_id
JOIN Books    b ON b.book_id    = i.book_id
WHERE s.roll_no = '2419158';

-- Q4. All issue records with student and book names (JOIN)
SELECT i.issue_id, s.name AS student, b.title AS book, i.issue_date, i.return_date
FROM Book_Issue i
JOIN Students s ON s.student_id = i.student_id
JOIN Books    b ON b.book_id    = i.book_id
ORDER BY i.issue_date;

-- Q5. Books that are currently issued and not yet returned
SELECT s.name, b.title, i.due_date
FROM Book_Issue i
JOIN Students s ON s.student_id = i.student_id
JOIN Books    b ON b.book_id    = i.book_id
WHERE i.return_date IS NULL;

-- Q6. Aggregate: number of books issued per student (GROUP BY)
SELECT s.name, COUNT(i.issue_id) AS books_issued
FROM Students s
LEFT JOIN Book_Issue i ON i.student_id = s.student_id
GROUP BY s.student_id, s.name
ORDER BY books_issued DESC;

-- Q7. Aggregate: total books, total copies, average price
SELECT COUNT(*) AS total_titles, SUM(total_copies) AS total_copies,
       ROUND(AVG(price),2) AS avg_price, MAX(price) AS max_price
FROM Books;

-- Q8. Category-wise count with HAVING
SELECT category, COUNT(*) AS titles
FROM Books
GROUP BY category
HAVING COUNT(*) >= 2;

-- Q9. Total fine collected
SELECT SUM(fine) AS total_fine FROM Book_Issue;

-- 5. DATA MANIPULATION (INSERT / UPDATE / DELETE) ------------------------

-- Issue a new book to a student and reduce available copies
INSERT INTO Book_Issue (student_id, book_id, issue_date, due_date)
VALUES (3, 7, '2026-11-04', '2026-11-18');
UPDATE Books SET available_copies = available_copies - 1 WHERE book_id = 7;

-- Return a book: set return date and increase available copies
UPDATE Book_Issue SET return_date = '2026-11-04'
WHERE student_id = 1 AND book_id = 5 AND return_date IS NULL;
UPDATE Books SET available_copies = available_copies + 1 WHERE book_id = 5;

-- Update a student's phone number
UPDATE Students SET phone = '9999900000' WHERE roll_no = '2419158';

-- Delete a student (their issue records are removed via ON DELETE CASCADE)
DELETE FROM Students WHERE roll_no = '2419505';

-- Check results after manipulation
SELECT book_id, title, available_copies FROM Books;
SELECT * FROM Book_Issue;
