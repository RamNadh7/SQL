Create DATABASE Real_Time;

-- Customers Table
CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(50)
);

INSERT INTO Customers VALUES 
(1, 'Aisha'), 
(2, 'Ben'), 
(3, 'Carlos'), 
(4, 'Divya');

-- Orders Table
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

INSERT INTO Orders VALUES 
(101, 1, CURRENT_DATE - INTERVAL '5 days'), 
(102, 2, CURRENT_DATE - INTERVAL '15 days'), 
(103, 3, CURRENT_DATE - INTERVAL '40 days'),
(104, 4, CURRENT_DATE - INTERVAL '10 days');

-- Payments Table
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    payment_date DATE,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

INSERT INTO Payments VALUES 
(1001, 101, CURRENT_DATE - INTERVAL '2 days'),  -- paid recently
(1002, 103, CURRENT_DATE - INTERVAL '35 days'); -- old payment


select * from payments;
SELECT * from customers;
select * from orders;

/*
Complex Join Optimization 
Question: You have three tables: Customers, Orders, and Payments. Write a query to find all customers who have made an order but have not completed a payment in the last 30 days. 
*/

SELECT *
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
LEFT JOIN Payments p ON o.order_id = p.order_id 
    AND p.payment_date > CURRENT_DATE - INTERVAL '30 days'
WHERE p.order_id IS NULL;

-- In MySQL, you use: NOW() - INTERVAL 30 DAY
-- In PostgreSQL, you use: CURRENT_DATE - INTERVAL '30 days'
-- In SQL Server, you use: DATEADD(DAY, -30, GETDATE())
-- In Oracle, you use: SYSDATE - 30

--- the below one follows from current time
SELECT *
FROM Customers c 
JOIN Orders o ON c.customer_id = o.customer_id 
LEFT JOIN Payments p ON o.order_id = p.order_id  
AND p.payment_date > NOW() - INTERVAL '30 DAY'
WHERE p.order_id IS NULL;

------------------------------------------------------------------------------------------------------------------------
-- Sales Table
CREATE TABLE Sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    sale_date DATE,
    sales INT
);

INSERT INTO Sales (sale_id, product_id, sale_date, sales) VALUES
(1, 101, '2024-12-03', 2),
(2, 103, '2024-12-01', 5),
(3, 101, '2024-12-07', 4),
(4, 104, '2024-12-02', 1),
(5, 102, '2024-12-05', 3),
(6, 101, '2024-12-10', 6),
(7, 103, '2024-12-06', 2),
(8, 102, '2024-12-12', 4),
(9, 104, '2024-12-08', 3),
(10, 103, '2024-12-11', 5);


/*
Window Functions in Analytical Queries 
Question: For each product sold, calculate the running total of 
the number of sales made over time, ordered by sale date.
*/
SELECT product_id, sale_date, sales, 
       SUM(sales) OVER (PARTITION BY product_id ORDER BY 
sale_date) AS running_total 
FROM Sales;


----------------------------------------------------------------------
CREATE TABLE Service_Requests (
    request_id INT PRIMARY KEY,
    created_at TIMESTAMP,
    resolved_at TIMESTAMP
);

INSERT INTO Service_Requests (request_id, created_at, resolved_at) VALUES
(1, '2024-12-02 09:00:00', '2024-12-03 10:30:00'), -- weekday to weekday
(2, '2024-12-06 16:00:00', '2024-12-09 10:00:00'), -- spans weekend
(3, '2024-12-03 08:00:00', '2024-12-03 18:00:00'), -- same day
(4, '2024-12-07 10:00:00', '2024-12-09 09:00:00'), -- starts on Saturday
(5, '2024-12-05 13:00:00', '2024-12-06 16:00:00'); -- weekday

/*
 You are given a table Service_Requests with columns 
request_id, created_at, and resolved_at. Write a query to 
calculate the average time taken to resolve a request (in 
hours), excluding weekends. 
*/

WITH request_hours AS (
  SELECT 
    request_id,
    created_at,
    resolved_at,
    EXTRACT(EPOCH FROM (resolved_at - created_at))/3600 AS total_hours,
    EXTRACT(DOW FROM created_at) AS start_dow
  FROM Service_Requests
  WHERE EXTRACT(DOW FROM created_at) BETWEEN 1 AND 5 -- exclude Sat (6) & Sun (0)
)
SELECT ROUND(AVG(total_hours), 2) AS avg_resolution_time_hours
FROM request_hours;



-------------------------------correct_solution


WITH WeekdayHours AS (
    SELECT 
        request_id,
        created_at,
        resolved_at,
        (
            -- Total hours
            EXTRACT(EPOCH FROM (resolved_at - created_at)) / 3600.0
            -
            -- Subtract weekend hours
            (
                SELECT 
                    COALESCE(
                        SUM(
                            CASE 
                                WHEN EXTRACT(DOW FROM d) IN (0, 6) THEN -- Sunday (0), Saturday (6)
                                    LEAST(
                                        EXTRACT(EPOCH FROM LEAST(d + INTERVAL '1 day', resolved_at) - GREATEST(d, created_at)) / 3600.0,
                                        24.0
                                    )
                                ELSE 0
                            END
                        ),
                        0
                    )
                FROM generate_series(
                    DATE_TRUNC('day', created_at),
                    DATE_TRUNC('day', resolved_at),
                    INTERVAL '1 day'
                ) d
            )
        ) AS resolution_hours
    FROM Service_Requests
    WHERE resolved_at IS NOT NULL
)
SELECT 
    ROUND(AVG(resolution_hours), 2) AS avg_resolution_time_hours
FROM WeekdayHours;


--------------------------------------------------------------------------------------------------
CREATE TABLE Purchases (
    purchase_id INT PRIMARY KEY,
    customer_id INT,
    purchase_date DATE,
    amount DECIMAL(10,2)
);


INSERT INTO Purchases (purchase_id, customer_id, purchase_date, amount) VALUES
(1, 1, CURRENT_DATE - INTERVAL '20 days', 45.00),
(2, 1, CURRENT_DATE - INTERVAL '30 days', 50.00),
(3, 1, CURRENT_DATE - INTERVAL '60 days', 35.00),
(4, 1, CURRENT_DATE - INTERVAL '90 days', 42.00),
(5, 1, CURRENT_DATE - INTERVAL '100 days', 29.00),
(6, 1, CURRENT_DATE - INTERVAL '120 days', 55.00),
(7, 2, CURRENT_DATE - INTERVAL '15 days', 20.00),
(8, 2, CURRENT_DATE - INTERVAL '40 days', 18.00),
(9, 2, CURRENT_DATE - INTERVAL '70 days', 22.00),
(10, 3, CURRENT_DATE - INTERVAL '10 days', 100.00),
(11, 3, CURRENT_DATE - INTERVAL '25 days', 90.00),
(12, 3, CURRENT_DATE - INTERVAL '50 days', 120.00);

/*
 Given a Purchases table, find customers who have 
made more than 5 purchases in the last 6 months, along with 
their total spend.
*/
SELECT customer_id, COUNT(*) AS purchase_count, 
SUM(amount) AS total_spent FROM Purchases 
WHERE purchase_date > NOW() - INTERVAL '6' MONTH 
GROUP BY customer_id 
HAVING COUNT(*) > 5; 

------------------------------------------------------------------------------------------------
CREATE TABLE Subjects (
    subject_id INT PRIMARY KEY,
    subject_name VARCHAR(50)
);

CREATE TABLE Student_Grades (
    student_id INT,
    subject_id INT,
    grade CHAR(1)
);

-- Subjects
INSERT INTO Subjects VALUES
(101, 'Math'),
(102, 'Science'),
(103, 'English');

-- Student Grades
INSERT INTO Student_Grades VALUES
(1, 101, 'A'),
(1, 102, 'B'),
(1, 103, 'A'), -- Student 1: complete
(2, 101, 'B'),
(2, 102, 'C'), -- Student 2: missing English
(3, 101, 'A'),
(3, 103, 'B'), -- Student 3: missing Science
(4, 102, 'C'),
(4, 103, 'B'); -- Student 4: missing Math

/*
You have a table of student grades. Write a query to 
find students who do not have grades for all subjects.
*/

SELECT student_id 
FROM Student_Grades 
GROUP BY student_id 
HAVING COUNT(DISTINCT subject_id) < (
    SELECT COUNT(*) FROM Subjects
);


------------------------------------------------------------------------------------------
CREATE TABLE Sales1 (
    sale_id INT PRIMARY KEY,
    employee_id INT,
    sale_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO Sales1 (sale_id, employee_id, sale_date, amount) VALUES
(1, 101, '2024-08-15', 500.00),
(2, 102, '2024-09-10', 750.00),
(3, 103, '2024-11-20', 600.00),
(4, 101, '2024-12-05', 800.00),
(5, 102, '2025-01-18', 300.00),
(6, 103, '2025-02-10', 400.00),
(7, 101, '2025-03-25', 900.00),
(8, 102, '2025-04-22', 1200.00),
(9, 104, '2025-05-30', 1500.00),
(10, 103, '2025-06-10', 700.00);

/*
Write a query to find the top 3 employees with the highest sales in the last year. 
(PostgreSQL version)
*/
SELECT employee_id, SUM(amount) AS total_sales
FROM Sales1
WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY employee_id
ORDER BY total_sales DESC
LIMIT 3;


--------------------------------------------------------------------------
CREATE TABLE Sales2 (
    sale_id INT PRIMARY KEY,
    employee_id INT,
    sale_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO Sales2 (sale_id, employee_id, sale_date, amount) VALUES
(1, 101, '2025-01-02', 500.00),
(2, 102, '2025-01-08', 750.00),
(3, 103, '2025-01-15', 600.00),
(4, 104, '2025-02-01', 400.00),
(5, 105, '2025-02-12', 300.00),
(6, 106, '2025-03-01', 900.00),
(7, 107, '2025-03-15', 1200.00),
(8, 108, '2025-03-22', 1000.00),
(9, 109, '2025-04-01', 450.00),
(10, 110, '2025-04-12', 800.00);

/*
How would you write a query to find the 90th percentile of sales from a Sales table?
*/
SELECT PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY 
amount) AS p90_sales 
FROM Sales2; 

-----------------------------------------------------------------------------------------------------
CREATE TABLE Sales3 (
    sale_id INT PRIMARY KEY,
    customer_id INT,
    amount DECIMAL(10,2)
);


INSERT INTO Sales3 (sale_id, customer_id, amount) VALUES
(1, 101, 100.00),
(2, 102, NULL),
(3, 103, 250.00),
(4, 104, NULL),
(5, 105, 300.00);

/*
How can you write a query that sums the total sales but treats null values as zero? 
*/

SELECT SUM(COALESCE(amount, 0)) AS total_sales 
FROM Sales3; 

-------------------------------------------------------------------------------------
CREATE TABLE Orders1 (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date TIMESTAMP,
    delivery_date TIMESTAMP
);

INSERT INTO Orders1 (order_id, customer_id, order_date, delivery_date) VALUES
(1, 101, '2025-05-01 10:00:00', '2025-05-03 16:30:00'),
(2, 102, '2025-05-02 09:15:00', '2025-05-04 11:45:00'),
(3, 103, '2025-05-03 14:00:00', '2025-05-05 17:20:00'),
(4, 104, '2025-05-04 08:30:00', '2025-05-04 18:00:00'),
(5, 105, '2025-05-05 12:00:00', '2025-05-08 10:15:00');

/*
Write a query to find the average time taken between order creation and delivery. 
*/
SELECT 
    ROUND(AVG(EXTRACT(EPOCH FROM delivery_date - order_date) / 3600), 2) AS avg_delivery_time_hours
FROM Orders1;


-----------------------------------------------------------------------------------------------------
CREATE TABLE Sales4 (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    amount DECIMAL(10,2)
);


INSERT INTO Sales4 (sale_id, sale_date, amount) VALUES
(1, '2025-01-15', 200.00),
(2, '2025-01-28', 350.00),
(3, '2025-02-10', 150.00),
(4, '2025-03-05', 500.00),
(5, '2025-03-15', 250.00),
(6, '2025-04-01', 300.00),
(7, '2025-06-20', 400.00),
(8, '2025-08-14', 100.00),
(9, '2025-08-28', 200.00),
(10, '2025-11-11', 700.00);

/*
Write a dynamic SQL query to generate a report of sales per month for a given year
*/


DO $$
DECLARE
    target_year INT := 2025;
    dyn_query TEXT;
BEGIN
    dyn_query := 'SELECT TO_CHAR(sale_date, ''Month'') AS month, 
                         SUM(amount) AS total_sales 
                  FROM Sales4 
                  WHERE EXTRACT(YEAR FROM sale_date) = ' || target_year || '
                  GROUP BY 1 
                  ORDER BY TO_DATE(month, ''Month'');';

    EXECUTE dyn_query;
END $$;

DO $$
DECLARE
    target_year INT := 2025;
    dyn_query TEXT;
BEGIN
    dyn_query := 'SELECT TO_CHAR(sale_date, ''Month'') AS month, 
                         SUM(amount) AS total_sales 
                  FROM Sales4 
                  WHERE EXTRACT(YEAR FROM sale_date) = ' || target_year || '
                  GROUP BY TO_CHAR(sale_date, ''Month'') 
                  ORDER BY TO_DATE(TO_CHAR(sale_date, ''Month''), ''Month'');';

    EXECUTE dyn_query;
END $$;



SELECT TO_CHAR(sale_date, 'Month') AS month, 
       SUM(amount) AS total_sales
FROM Sales4 
WHERE EXTRACT(YEAR FROM sale_date) = 2025
GROUP BY 1
ORDER BY TO_DATE(TO_CHAR(sale_date, 'Month'), 'Month');

-----------------------------------------------------------------
-- How can you identify and optimize slow-running queries in SQL?

-- Use the EXPLAIN command to analyze query execution plans. 
EXPLAIN SELECT * FROM Orders WHERE customer_id = 123; 
 -- Add appropriate indexes to improve query speed 
CREATE INDEX idx_customer_id ON Orders (customer_id); 
 -- Optimize joins and reduce the number of rows processed. 
SELECT o.order_id, c.customer_name  
FROM Orders o  
JOIN Customers c ON o.customer_id = c.customer_id 
WHERE c.region = 'North'; 


-------------------------------------------------------
--  What are the differences between temporary and permanent tables, and when would you use each?

-- Temporary Table (Exists for the session) 
CREATE TEMPORARY TABLE temp_orders AS  
SELECT * FROM Orders;

-- Permanent Table (Exists indefinitely until dropped) 
CREATE TABLE permanent_orders AS  
SELECT * FROM Orders; 


------------------------------------------------------------
---How do you implement full-text search on a column in SQL?
-- Create a full-text index on a column (SQL/MYSQL SERVER)
CREATE FULLTEXT INDEX ON Products(product_description); 
 -- Use the CONTAINS function to search for a keyword 
SELECT * FROM Products WHERE 
CONTAINS(product_description, 'laptop'); 


--------------------------------------------------------------------
CREATE TABLE Employees (
    employee_id INT PRIMARY KEY,
    manager_id INT,
    name VARCHAR(50)
);


INSERT INTO Employees (employee_id, manager_id, name) VALUES
(1, NULL, 'Alice'),       -- CEO
(2, 1, 'Bob'),            -- Reports to Alice
(3, 1, 'Carol'),          -- Reports to Alice
(4, 2, 'David'),          -- Reports to Bob
(5, 2, 'Eve'),            -- Reports to Bob
(6, 3, 'Frank'),          -- Reports to Carol
(7, 4, 'Grace'),          -- Reports to David
(8, 6, 'Heidi');          -- Reports to Frank

/*
How do you query hierarchical data stored in a self referencing table? 
*/
WITH RECURSIVE Hierarchy AS ( 
    SELECT employee_id, manager_id, name, 0 AS level 
    FROM Employees 
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.employee_id, e.manager_id, e.name, h.level + 1 
    FROM Employees e 
    INNER JOIN Hierarchy h ON e.manager_id = h.employee_id 
) 
SELECT * FROM Hierarchy;


---------------------------------------------------------------
/*
Explain how partitioning works in SQL and provide 
an example of partitioning a table by date. 
*/
CREATE TABLE Sales4 (
    sale_id INT,
    sale_date DATE,
    amount DECIMAL(10, 2),
    sale_year INT GENERATED ALWAYS AS (EXTRACT(YEAR FROM sale_date)) STORED
) PARTITION BY RANGE (sale_year);


CREATE TABLE Sales4_p2022 PARTITION OF Sales4
FOR VALUES FROM (2022) TO (2023);

CREATE TABLE Sales4_p2023 PARTITION OF Sales4
FOR VALUES FROM (2023) TO (2024);


--------------------------------------------------------------
/*
How would you manage concurrency issues in SQL, 
such as the lost update problem?
*/

-- Set transaction isolation level to SERIALIZABLE 
--Ensures transactions run as if executed one at a time
---Highest safety, but can reduce concurrency
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; 
 
BEGIN TRANSACTION; 
-- Perform the update or insert operation 
COMMIT; 


------------------------------------------------------
/*
Write a dynamic SQL query that generates a report of sales by region for a given year.
*/

DO $$
DECLARE
    target_year INT := 2025;  -- change this to your desired year
    dyn_query TEXT;
BEGIN
    dyn_query := 'SELECT region, SUM(amount) AS total_sales
        FROM Sales
        WHERE EXTRACT(YEAR FROM sale_date) = ' || target_year || '
        GROUP BY region
        ORDER BY region;
    ';
    EXECUTE dyn_query;
END $$;

--------------------------------------------------------------------------

CREATE TABLE Sales5 (
    sale_id INT PRIMARY KEY,
    product_id INT,
    sale_date DATE,
    amount DECIMAL(10, 2)
);


INSERT INTO Sales5 (sale_id, product_id, sale_date, amount) VALUES
(1, 101, '2025-01-05', 120.00),
(2, 101, '2025-01-10', 150.00),
(3, 101, '2025-01-15', 100.00),
(4, 102, '2025-01-06', 90.00),
(5, 102, '2025-01-12', 130.00),
(6, 101, '2025-01-20', 110.00),
(7, 102, '2025-01-22', 80.00),
(8, 103, '2025-01-09', 200.00),
(9, 103, '2025-01-12', 300.00);

/* Write a query to calculate a running total of sales for each product.*/

SELECT
    product_id,
    sale_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY product_id
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM Sales5
ORDER BY product_id, sale_date;



---------------------------------------------------------------------
CREATE TABLE Orders2 (
    order_id INT,
    customer_name VARCHAR(50),
    order_date DATE,
    amount DECIMAL(10,2)
);


INSERT INTO Orders2 (order_id, customer_name, order_date, amount) VALUES
(1, 'Alice', '2025-06-01', 100.00),
(2, 'Bob',   '2025-06-02', 150.00),
(3, 'Alice', '2025-06-01', 100.00),  -- duplicate of order 1 (not same ID)
(4, 'Carol', '2025-06-03', 200.00),
(5, 'Bob',   '2025-06-02', 150.00),  -- duplicate of order 2
(6, 'Dave',  '2025-06-04', 180.00);


/*
Write a query to identify duplicate rows in a table based on a combination of columns.
*/

SELECT 
    customer_name,
    order_date,
    amount,
    COUNT(*) AS duplicate_count
FROM Orders2
GROUP BY customer_name, order_date, amount
HAVING COUNT(*) > 1;

-----------------------------------------------------
CREATE TABLE Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100),
    parent_dept_id INT
);

INSERT INTO Departments VALUES
(1, 'Corporate', NULL),
(2, 'Sales', 1),
(3, 'Domestic Sales', 2),
(4, 'International Sales', 2),
(5, 'Engineering', 1),
(6, 'Software', 5),
(7, 'Hardware', 5);

/* How do you write a recursive CTE to navigate a hierarchy of departments?*/

WITH RECURSIVE DeptHierarchy AS (
    -- Anchor member: top-level departments (no parent)
    SELECT 
        dept_id, 
        dept_name, 
        parent_dept_id,
        0 AS level
    FROM Departments
    WHERE parent_dept_id IS NULL

    UNION ALL

    -- Recursive member: find children of the current level
    SELECT 
        d.dept_id, 
        d.dept_name, 
        d.parent_dept_id,
        h.level + 1
    FROM Departments d
    INNER JOIN DeptHierarchy h ON d.parent_dept_id = h.dept_id
)
SELECT * 
FROM DeptHierarchy
ORDER BY level, dept_name;

-------------------------------------------------------
CREATE TABLE Employees1 (
    employee_id INT PRIMARY KEY,
    name VARCHAR(50),
    manager_id INT
);


INSERT INTO Employees1 (employee_id, name, manager_id) VALUES
(1, 'Alice', NULL),          -- CEO
(2, 'Bob', 1),               -- Reports to Alice
(3, 'Carol', 1),             -- Reports to Alice
(4, 'David', 2),             -- Reports to Bob
(5, 'Eve', 2),               -- Reports to Bob
(6, 'Frank', 3),             -- Reports to Carol
(7, 'Grace', 4),             -- Reports to David
(8, 'Heidi', 5),             -- Reports to Eve
(9, 'Ivan', 6),              -- Reports to Frank
(10, 'Judy', 7);             -- Reports to Grace


/*Write a recursive CTE to find all employees in an organization and their respective managers, given an Employees table.*/

WITH RECURSIVE EmployeeHierarchy AS (
    -- Base case: select each employee and their immediate manager
    SELECT 
        e.employee_id,
        e.name AS employee_name,
        m.employee_id AS manager_id,
        m.name AS manager_name,
        0 AS level
    FROM Employees1 e
    LEFT JOIN Employees1 m ON e.manager_id = m.employee_id
    UNION ALL
    -- Recursive case: climb up the management tree
    SELECT 
        eh.employee_id,
        eh.employee_name,
        m.employee_id,
        m.name,
        eh.level + 1
    FROM EmployeeHierarchy eh
    JOIN Employees1 m ON eh.manager_id = m.employee_id
)
SELECT * 
FROM EmployeeHierarchy
ORDER BY employee_id, level;


WITH RECURSIVE EmployeeHierarchy AS (
    SELECT 
        e.employee_id,
        e.name AS employee_name,
        m.employee_id AS manager_id,
        m.name AS manager_name,
        0 AS level,
        ARRAY[e.employee_id] AS path
    FROM Employees1 e
    LEFT JOIN Employees1 m ON e.manager_id = m.employee_id

    UNION ALL

    SELECT 
        eh.employee_id,
        eh.employee_name,
        m.employee_id,
        m.name,
        eh.level + 1,
        path || m.employee_id
    FROM EmployeeHierarchy eh
    JOIN Employees1 m ON eh.manager_id = m.employee_id
    WHERE NOT m.employee_id = ANY(eh.path)
)
SELECT employee_id, employee_name, manager_id, manager_name, level
FROM EmployeeHierarchy
ORDER BY employee_id, level;


WITH RECURSIVE EmployeeCTE AS (
SELECT employee_id, manager_id, name
FROM Employees1
WHERE manager_id IS NULL
UNION ALL
SELECT e.employee_id, e.manager_id, e.name
FROM Employees1 e
INNER JOIN EmployeeCTE cte ON e.manager_id =
cte.employee_id
)
SELECT * FROM EmployeeCTE;


-------------------------------------------------------------------


/*
Write a query that categorizes sales amounts into different ranges using the CASE statement.
*/

CREATE TABLE Sales6 (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO Sales6 (sale_id, sale_date, amount) VALUES
(1, '2025-06-01', 45.00),
(2, '2025-06-02', 120.00),
(3, '2025-06-03', 300.00),
(4, '2025-06-04', 90.00),
(5, '2025-06-05', 510.00),
(6, '2025-06-06', 499.99),
(7, '2025-06-07', 1000.00),
(8, '2025-06-08', 15.00);


SELECT
    sale_id,
    amount,
    CASE 
        WHEN amount < 100 THEN 'Low'
        WHEN amount BETWEEN 100 AND 499.99 THEN 'Medium'
        WHEN amount >= 500 THEN 'High'
        ELSE 'Unknown'
    END AS amount_category
FROM Sales6;

----------------------------------------------------------------------
