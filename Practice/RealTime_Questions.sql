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

/*Given a JSON column named `data` in a table, write a query to extract a specific value from the JSON object. */

SELECT 
    data ->> 'customer_name' AS customer_name
FROM orders;


{
  "customer": {
    "name": "Alice",
    "email": "alice@example.com"
  },
  "total": 100.0
}

SELECT 
    data -> 'customer' ->> 'name' AS customer_name
FROM orders;



-------------------------------------------------------------------------
/* Write a query to rank employees based on their sales performance within each department.
*/
CREATE TABLE Employees2 (
    employee_id INT PRIMARY KEY,
    name VARCHAR(50),
    department_id INT
);

CREATE TABLE Sales7 (
    sale_id INT PRIMARY KEY,
    employee_id INT,
    amount DECIMAL(10,2)
);


-- Employees table
INSERT INTO Employees2 (employee_id, name, department_id) VALUES
(1, 'Alice', 10),
(2, 'Bob', 10),
(3, 'Carol', 10),
(4, 'David', 20),
(5, 'Eve', 20),
(6, 'Frank', 30);

-- Sales table
INSERT INTO Sales7 (sale_id, employee_id, amount) VALUES
(101, 1, 300.00),
(102, 1, 200.00),
(103, 2, 500.00),
(104, 3, 150.00),
(105, 3, 150.00),
(106, 4, 700.00),
(107, 5, 400.00),
(108, 5, 200.00),
(109, 6, 100.00),
(110, 6, 50.00);


SELECT
    e.department_id,
    e.employee_id,
    e.name,
    SUM(s.amount) AS total_sales,
    RANK() OVER (
        PARTITION BY e.department_id
        ORDER BY SUM(s.amount) DESC
    ) AS sales_rank
FROM Employees2 e
JOIN Sales7 s ON e.employee_id = s.employee_id
GROUP BY e.department_id, e.employee_id, e.name
ORDER BY e.department_id, sales_rank;


------------------------------------------------------------------------
CREATE TABLE Sales8 (
    sale_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    sale_date DATE,
    amount DECIMAL(10,2)
);


INSERT INTO Sales8 (sale_id, product_name, sale_date, amount) VALUES
(1, 'Laptop', '2025-01-10', 1200.00),
(2, 'Laptop', '2025-02-15', 1350.00),
(3, 'Laptop', '2025-03-20', 1100.00),
(4, 'Phone',  '2025-01-05', 600.00),
(5, 'Phone',  '2025-01-25', 650.00),
(6, 'Phone',  '2025-03-10', 700.00),
(7, 'Tablet', '2025-02-10', 500.00),
(8, 'Tablet', '2025-02-18', 550.00),
(9, 'Tablet', '2025-03-22', 620.00),
(10, 'Tablet','2025-01-30', 400.00);

/*Write a query to pivot sales data to show the total sales for each product by month
*/


SELECT
    product_name,
    SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 1 THEN amount ELSE 0 END) AS Jan,
    SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 2 THEN amount ELSE 0 END) AS Feb,
    SUM(CASE WHEN EXTRACT(MONTH FROM sale_date) = 3 THEN amount ELSE 0 END) AS Mar
FROM Sales8
GROUP BY product_name
ORDER BY product_name;


-----------------------------------------------------------------------
CREATE TABLE Sales9 (
    sale_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    sale_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO Sales9 (sale_id, product_name, sale_date, amount) VALUES
(1, 'Laptop', '2025-06-01', 1200.00),
(2, 'Laptop', '2025-06-05', 1350.00),
(3, 'Phone',  '2025-06-03', 800.00),
(4, 'Phone',  '2025-06-07', 900.00),
(5, 'Tablet', '2025-06-02', 500.00),
(6, 'Tablet', '2025-06-06', 550.00),
(7, 'Tablet', '2025-06-08', 600.00);

/*Write a query to calculate total sales with subtotals for each product and grand total.*/

SELECT 
    COALESCE(product_name, 'Grand Total') AS category,
    SUM(amount) AS total_sales
FROM Sales9
GROUP BY ROLLUP(product_name);


----------------------------------------------------------------------
/*How would you write a SQL transaction that rolls back if an error occurs?*/

DO $$
BEGIN
    BEGIN
        -- Start transaction manually
        INSERT INTO Sales VALUES (11, 'Monitor', 300.00);

        -- Intentional or potential error
        UPDATE Inventory SET quantity = quantity - 1
        WHERE product_name = 'Monitor';

        COMMIT;
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        RAISE NOTICE 'Transaction failed and was rolled back';
    END;
END $$;


-------------------------------------------------------------------------
/*Write a trigger that automatically updates a timestamp column when a record is modified.*/

CREATE TABLE Products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    last_updated TIMESTAMP
);


CREATE OR REPLACE FUNCTION update_last_modified()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER set_last_updated
BEFORE UPDATE ON Products
FOR EACH ROW
EXECUTE FUNCTION update_last_modified();


---------------------------------------------------------------------------
/*What is a cross join, and provide a query example that demonstrates its use?*/

SELECT a.name, b.product_name
FROM Customers a
CROSS JOIN Products b;

--- A cross join produces a Cartesian product, combining every row from one table with every row from another.

---------------------------------------------------------------------



/*Write a query to use the MERGE statement for updating existing records or inserting new ones.*/

CREATE TABLE Customers1 (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100)
);

delete from customers1;

INSERT INTO Customers1 (customer_id, customer_name, email) VALUES
(1, 'Alice', 'alice@example.com'),
(2, 'Bob', 'bob@example.com'),
(3, 'Carol', 'carol@example.com');



select * from customers1;

CREATE TABLE CustomerUpdates (
    customer_id INT,
    customer_name VARCHAR(100),
    email VARCHAR(100)
);


INSERT INTO CustomerUpdates (customer_id, customer_name, email) VALUES
(2, 'Bob B.', 'bob.b@example.com'),       -- should trigger UPDATE
(3, 'Carol C.', 'carol.c@example.com'),   -- should trigger UPDATE
(4, 'David', 'david@example.com');        -- should trigger INSERT

select * from customerupdates;
delete from customerupdates;



---- Write a query to use the MERGE statement for updating existing records or inserting new ones
MERGE INTO Customers1 AS target
USING CustomerUpdates AS source
ON target.customer_id = source.customer_id

WHEN MATCHED THEN
    UPDATE SET 
        customer_name = source.customer_name,
        email = source.email

WHEN NOT MATCHED THEN
    INSERT (customer_id, customer_name, email)
    VALUES (source.customer_id, source.customer_name, source.email);


-------------------------------------------------------------------------
CREATE TABLE Orders3 (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE
);

INSERT INTO Orders3 (order_id, customer_id, order_date) VALUES
(1, 101, '2025-06-01'),
(2, 102, '2025-06-02'),
(3, NULL, '2025-06-03'),
(4, 101, '2025-06-04'),
(5, NULL, '2025-06-05'),
(6, 103, '2025-06-06'),
(7, 102, '2025-06-07'),
(8, NULL, '2025-06-08');

/*Write a query that counts the number of orders placed by customers, treating NULL customer IDs as 'Unknown'.*/

SELECT 
    COALESCE(CAST(customer_id AS VARCHAR), 'Unknown') AS customer_label,
    COUNT(*) AS total_orders
FROM Orders3
GROUP BY COALESCE(CAST(customer_id AS VARCHAR), 'Unknown')
ORDER BY customer_label;


------------------------------------------------------------------------------
/* How can you combine data from two different tables that have similar structures, such as Orders2022 and Orders2023? */

SELECT * FROM Orders2022
UNION ALL
SELECT * FROM Orders2023;

-----------------------------------------------------------------------
/* Write a query to update the status of all orders that have been shipped but not delivered. */

UPDATE Orders
SET status = 'In Transit'
WHERE shipped_date IS NOT NULL
AND delivered_date IS NULL;


------------------------------------------------------------------

CREATE TABLE Employees3 (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE Sales10 (
    sale_id INT PRIMARY KEY,
    employee_id INT,
    sale_amount DECIMAL(10,2)
);

-- Employees
INSERT INTO Employees3 (employee_id, name) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Carol'),
(4, 'David'),
(5, 'Eve');

-- Sales
INSERT INTO Sales10 (sale_id, employee_id, sale_amount) VALUES
(101, 1, 500.00),
(102, 1, 300.00),
(103, 2, 800.00),
(104, 3, 300.00),
(105, 3, 500.00),
(106, 4, 200.00),
(107, 5, 200.00),
(108, 5, 100.00);

/*Write a query to rank employees by their total sales, without skipping rank numbers for ties. */
SELECT 
    e.employee_id,
    e.name,
    SUM(s.sale_amount) AS total_sales,
    DENSE_RANK() OVER (
        ORDER BY SUM(s.sale_amount) DESC
    ) AS sales_rank
FROM Employees3 e
JOIN Sales10 s ON e.employee_id = s.employee_id
GROUP BY e.employee_id, e.name
ORDER BY sales_rank;


-------------------------------------------------------------------

CREATE TABLE Customers2 (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100)
);

CREATE TABLE Orders4 (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE
);

-- Customers
INSERT INTO Customers2 (customer_id, customer_name) VALUES
(101, 'Alice'),
(102, 'Bob'),
(103, 'Carol'),
(104, 'David');

-- Orders
INSERT INTO Orders4 (order_id, customer_id, order_date) VALUES
(1, 101, CURRENT_DATE - INTERVAL '10 day'),  -- recent order
(2, 102, CURRENT_DATE - INTERVAL '40 day'),  -- too old
(3, 103, CURRENT_DATE - INTERVAL '5 day'),   -- recent order
(4, 104, CURRENT_DATE - INTERVAL '60 day');  -- too old

/*Write a query to find customers who have placed at least one order in the last month.*/
SELECT 
    customer_id, 
    customer_name
FROM Customers2 c
WHERE EXISTS (
    SELECT 1 
    FROM Orders4 o
    WHERE o.customer_id = c.customer_id
    AND o.order_date >= CURRENT_DATE - INTERVAL '1 month'
);

SELECT DISTINCT customer_id
FROM Orders4
WHERE order_date >= CURRENT_DATE - INTERVAL '1 month';

--------------------------------------------------------------

CREATE TABLE Employees4 (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100),
    manager_id INT
);


INSERT INTO Employees4 (employee_id, name, manager_id) VALUES
(1, 'Alice', NULL),        -- CEO
(2, 'Bob', 1),
(3, 'Carol', 1),
(4, 'David', 2),
(5, 'Eve', 2),
(6, 'Frank', 3),
(7, 'Grace', 4),
(8, 'Heidi', 5),
(9, 'Ivan', 6);


/*How would you write a recursive query to retrieve all managers and their subordinates from an Employees table?*/

WITH RECURSIVE EmployeeHierarchy AS (
    SELECT 
        employee_id,
        name AS employee_name,
        manager_id,
        0 AS level,
        ARRAY[name]::VARCHAR[] AS path
    FROM Employees4
    WHERE manager_id IS NULL

    UNION ALL

    SELECT 
        e.employee_id,
        e.name,
        e.manager_id,
        eh.level + 1,
        eh.path || e.name
    FROM Employees4 e
    JOIN EmployeeHierarchy eh ON e.manager_id = eh.employee_id
)

SELECT 
    employee_id,
    employee_name,
    manager_id,
    level,
    ARRAY_TO_STRING(path, ' → ') AS reporting_path
FROM EmployeeHierarchy
ORDER BY level, employee_id;

--or

WITH recursive EmployeeHierarchy AS (
SELECT employee_id, manager_id, name, 0 AS Level
FROM Employees4
WHERE manager_id IS NULL
UNION ALL
SELECT e.employee_id, e.manager_id, e.name, eh.Level + 1
FROM Employees4 e
INNER JOIN EmployeeHierarchy eh ON e.manager_id =
eh.employee_id
)
SELECT * FROM EmployeeHierarchy;

------------------------------------------------------------------
/*How would you write a recursive query to retrieve all managers and their subordinates from an Employees table?*/

CREATE INDEX idx_customer_id
ON Orders(customer_id);

SELECT * FROM Orders WHERE customer_id = 123;

--------------------------------------------------------------------
CREATE TABLE Sales11 (
    employee_id INT,
    sale_month DATE,
    sale_amount DECIMAL(10,2)
);

INSERT INTO Sales11 (employee_id, sale_month, sale_amount) VALUES
(1, '2024-12-01', 1000),
(1, '2025-01-01', 1200),
(1, '2025-02-01', 1100),
(2, '2025-01-01', 800),
(2, '2025-02-01', 950),
(3, '2025-02-01', 500);

/*Write a query to compare each employee's sales with their previous month's sales.*/
SELECT 
    employee_id,
    TO_CHAR(sale_month, 'YYYY-MM') AS month,
    sale_amount AS current_month_sales,
    LAG(sale_amount) OVER (
        PARTITION BY employee_id 
        ORDER BY sale_month
    ) AS previous_month_sales,
    ROUND(
        100.0 * (sale_amount - LAG(sale_amount) OVER (
            PARTITION BY employee_id 
            ORDER BY sale_month
        )) / NULLIF(LAG(sale_amount) OVER (
            PARTITION BY employee_id 
            ORDER BY sale_month
        ), 0), 2
    ) AS percent_change
FROM Sales11
ORDER BY employee_id, sale_month;

--or 
SELECT employee_id, sale_month, sale_amount,
LAG(sale_amount) OVER (PARTITION BY employee_id
ORDER BY sale_month) AS previous_month_sales,
LEAD(sale_amount) OVER (PARTITION BY employee_id
ORDER BY sale_month) AS next_month_sales
FROM sales11;


------------------------------------------------------------------------
/*Write a query to count the number of unique customers who placed orders in the last year.*/

 SELECT COUNT(DISTINCT customer_id) AS unique_customers_last_year
FROM Orders
WHERE order_date >= CURRENT_DATE - INTERVAL '1 year';


--------------------------------------------------------------------
/*Write a query to calculate the total sales for each product category, with a separate total for 'Electronics'.*/

-- Products table
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50)
);

-- Sales table
CREATE TABLE Sales12(
    sale_id INT PRIMARY KEY,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2)
);

-- Products
INSERT INTO Products VALUES
(1, 'Laptop', 'Electronics'),
(2, 'Smartphone', 'Electronics'),
(3, 'Desk Chair', 'Furniture'),
(4, 'Notebook', 'Stationery');

-- Sales
INSERT INTO Sales12 VALUES
(101, 1, 2, 1000.00),   -- Laptop
(102, 2, 3, 500.00),    -- Smartphone
(103, 3, 5, 150.00),    -- Desk Chair
(104, 4, 10, 5.00);     -- Notebook



-- Total sales per category
SELECT 
    p.category,
    SUM(s.quantity * s.unit_price) AS total_sales
FROM Sales12 s
JOIN Products p ON s.product_id = p.product_id
GROUP BY p.category

UNION ALL

-- Separate total for Electronics
SELECT 
    'Electronics (Total)' AS category,
    SUM(s.quantity * s.unit_price)
FROM Sales12 s
JOIN Products p ON s.product_id = p.product_id
WHERE p.category = 'Electronics';

-----------------------------------------------------------------------
/*Write a query to calculate the average, minimum,and maximum sales amount for each region.*/
SELECT region,
AVG(sales_amount) AS average_sales,
MIN(sales_amount) AS min_sales,
MAX(sales_amount) AS max_sales
FROM Sales
GROUP BY region


-----------------------------------------------------------------
/*Write a query to return the second page of results from an Orders table, assuming each page shows 10 results.*/
SELECT * FROM Orders
ORDER BY order_date
OFFSET 1 ROWS
FETCH NEXT 10 ROWS ONLY;

-------------------------------------------------------------
/*Write a query to find all employees who share the same manager in an Employees table.*/
SELECT e1.employee_id, e1.name AS employee_name, e2.name
AS manager_name
FROM Employees e1
JOIN Employees e2 ON e1.manager_id = e2.employee_id;

---------------------------------------------------------------------
CREATE TABLE Orders5 (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    delivery_date DATE
);

INSERT INTO Orders5 (order_id, customer_id, order_date, delivery_date) VALUES
(1, 101, DATE '2025-06-01', DATE '2025-06-05'),
(2, 102, DATE '2025-06-03', DATE '2025-06-10'),
(3, 103, DATE '2025-06-07', DATE '2025-06-07'),
(4, 104, DATE '2025-06-10', DATE '2025-06-15'),
(5, 105, DATE '2025-06-12', NULL);  -- still pending delivery

/*Write a query to calculate the number of days between an order date and a delivery date.*/
SELECT 

    order_id,
    delivery_date - order_date AS days_to_deliver
FROM Orders5;
 ---- If you want to show how many days have passed since the order for undelivered items
SELECT 
    order_id,
    delivery_date,
    order_date,
    COALESCE(delivery_date, CURRENT_DATE) - order_date AS days_elapsed
FROM Orders5;


--------------------------------------------------------------------------------

CREATE TABLE Invoices (
    invoice_number INT PRIMARY KEY
);

INSERT INTO Invoices (invoice_number) VALUES
(1001), (1002), (1003), (1005), (1006), (1009), (1010);

/*How can you write a query to detect missing invoice numbers in a sequence of invoices?*/
WITH RECURSIVE expected_numbers AS (
    SELECT MIN(invoice_number) AS num
    FROM Invoices
    UNION ALL
    SELECT num + 1
    FROM expected_numbers
    WHERE num + 1 <= (SELECT MAX(invoice_number) FROM Invoices)
)
SELECT num AS missing_invoice
FROM expected_numbers
WHERE num NOT IN (SELECT invoice_number FROM Invoices);

------------------------------------------------------------------------------
Explain the difference between INNER JOIN, LEFT JOIN, RIGHT JOIN, and FULL JOIN with examples.

• INNER JOIN returns records that have matching values in both tables.
• LEFT JOIN returns all records from the left table and matching records from the right.
• RIGHT JOIN returns all records from the right table and matching records from the left.
• FULL JOIN returns all records when there is a match in either table.

-------------------------------------------------------------------------

How would you find duplicate rows in a table?

SELECT column1, COUNT(*)
FROM table
GROUP BY column1 having count(*)>1;

------------------------------------------------------------------------------
What’s the difference between RANK() and DENSE_RANK() in SQL?
• RANK() gives gaps in ranking after ties.
• DENSE_RANK() assigns consecutive ranks without gaps

SELECT column, RANK() OVER (ORDER BY column DESC) AS rank
FROM table;


--------------------------------------------------------------------------------
How would you remove duplicate rows in SQL?
WITH cte AS (
SELECT column, ROW_NUMBER() OVER(PARTITION BY
column ORDER BY column) AS row_num
FROM table
)
Delete from cte where row_num>1;

-----------------------------------------------------------------------------
Explain window functions and how you would use them in SQL.

Window functions perform calculations across a set of rows related to the current row, like RANK(), SUM(), AVG(),and ROW_NUMBER(). They are useful for calculations without collapsing rows.

SELECT column, SUM(value) OVER(PARTITION BY category)
AS sum_value
FROM table;

------------------------------------------------------------------------------
How would you fetch only even-numbered rows from a table?

SELECT *
FROM (
SELECT *, ROW_NUMBER() OVER (ORDER BY column) AS
row_num
FROM table
) AS subquery
WHERE row_num % 2 = 0;


----------------------------------------------------------------------------
What is the purpose of the EXPLAIN statement in SQL?
EXPLAIN analyzes the query execution plan, showing how tables are accessed, indices used, and estimated costs, allowing you to optimize queries.

----------------------------------------------------------------------------
Explain a scenario where you’d use a SELF JOIN.
Use a SELF JOIN when you need to compare rows within the same table, such as finding employee-manager relationships within an employee table.

SELECT a.employee_id, b.employee_id AS manager_id
FROM employees a
JOIN employees b ON a.manager_id = b.employee_id;

-----------------------------------------------------------------------------
How can you optimize a query with multiple joins?

Index columns involved in joins, filter data early, and
order joins so smaller tables are joined first. Use EXPLAIN to
check performance.


----------------------------------------------------------------------------
Describe the difference between WHERE and HAVING.

WHERE filters rows before aggregation, while
HAVING filters after aggregation. Use WHERE for raw data and
HAVING for aggregate functions.

-----------------------------------------------------------------------------
/* How would you calculate the cumulative sum in SQL? */

CREATE TABLE Sales13 (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    amount DECIMAL(10,2)
);

INSERT INTO Sales13 (sale_id, sale_date, amount) VALUES
(1, '2025-01-01', 100.00),
(2, '2025-01-03', 150.00),
(3, '2025-01-05', 200.00),
(4, '2025-01-07', 50.00),
(5, '2025-01-10', 300.00);


SELECT 
    sale_id,
    sale_date,
    amount,
    SUM(amount) OVER (ORDER BY sale_date) AS cumulative_sales
FROM Sales13
ORDER BY sale_date;

or 
SELECT column, SUM(value) OVER (ORDER BY column ROWS
BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS
cumulative_sum
FROM table;

---------------------------------------------------------------------------
What is the difference between UNION and UNION ALL?
Answer: UNION removes duplicates, while UNION ALL keeps
all results, including duplicates. UNION ALL is faster for larger
datasets.

--------------------------------------------------------------------------
/*How would you delete rows that are duplicates but keep
the first occurrence?*/

WITH cte AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY column
ORDER BY column) AS row_num
FROM table
)
DELETE FROM cte WHERE row_num > 1;

----------------------------------------------------------------------------
Explain a correlated subquery and give an example.

SELECT name
FROM employees e1
WHERE salary > (
SELECT AVG(salary)
FROM employees e2
WHERE e1.department_id = e2.department_id
);


--------------------------------------------------------------------------
What is an index, and how does it improve query
performance?

An index is a data structure that speeds up data retrieval by reducing the amount of data scanned. It acts as a pointer to data rows based on indexed columns.

-----------------------------------------------------------------------
What’s the difference between a PRIMARY KEY and a
UNIQUE constraint?

Both enforce uniqueness, but PRIMARY KEY also
doesn’t allow NULL values and uniquely identifies each row,
while UNIQUE allows one NULL.

-------------------------------------------------------------------------
How do you find the nth highest salary in SQL?
SELECT *
FROM (
    SELECT 
        emp_name,
        emp_salary,
        DENSE_RANK() OVER (ORDER BY emp_salary DESC) AS salary_rank
    FROM Employees
) ranked
WHERE salary_rank = N;


---------------------------------------------------------------------------
What is a TRIGGER and when would you use it?

A TRIGGER automatically executes predefined actions
in response to database events (like insert, update, delete). It’s
useful for logging changes or enforcing rules.

---------------------------------------------------------------------------
How would you update records in one table based on
values in another table?

UPDATE table1
SET column = table2.value
FROM table2
WHERE table1.id = table2.id;

------------------------------------------------------------------------------
Explain the COALESCE function and give an example.

COALESCE returns the first non-null value among its
arguments, useful for handling missing values.

SELECT COALESCE(column1, column2, 0) AS result FROM
table;

-----------------------------------------------------------------------------
How would you remove rows with NULL values in a specific column?

DELETE FROM table WHERE column IS NULL;

----------------------------------------------------------------------------
How would you list all unique pairs of columns from the same table?

SELECT DISTINCT a.column1, b.column1
FROM table a
Join table b on a.column1<b.column1;

----------------------------------------------------------------------------
Explain the GROUP BY clause and when you would use it.

GROUP BY groups rows sharing a common field, used with aggregate functions like SUM, COUNT, AVG.

----------------------------------------------------------------------------
/*
What is ACID in database transactions?

ACID stands for Atomicity, Consistency, Isolation,
Durability. It ensures reliable transactions, essential for
maintaining data integrity.

Atomicity

    A transaction is like a promise — it either completes fully or doesn't happen at all.

    Example: If you're transferring money between accounts, the debit and credit must both succeed — or both fail.

Consistency

    A transaction must leave the database in a valid state, following all constraints and rules.

    Example: If there's a rule that no account balance can be negative, a transaction must respect that — no matter what.

Isolation

    When multiple transactions happen at the same time, they must not interfere with each other.

    Example: Two people buying the last ticket shouldn't both succeed — only the first one who commits the change should win.

Durability

    Once a transaction is committed, it’s saved — even if the system crashes.

    Example: If the power goes out, your confirmed order should still be there when things restart.

*/

-------------------------------------------------------------------------------
---- How would you calculate the moving average in SQL?
SELECT column, AVG(value) OVER(ORDER BY date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS moving_avg FROM table;

------------------------------------------------------------------------------
Explain what a cross join is and when you might use it

A cross join returns the Cartesian product of two tables. It’s rarely used unless you need all possible combinations of two sets.

------------------------------------------------------------------------------
What is the difference between DELETE and TRUNCATE?
DELETE removes rows one by one, can have a WHERE clause, and can be rolled back. TRUNCATE removes all rows quickly, can’t be rolled back, and resets identity columns.

----------------------------------------------------------------------------
How do you handle NULL values when joining tables?
Answer: Use LEFT JOIN to retain rows with NULL in one table,
or use IS NULL or COALESCE to manage NULL values.

----------------------------------------------------------------------------
How would you select records in one table that don’t exist in another table?
SELECT a.*
FROM table_a a
LEFT JOIN table_b b ON a.id = b.id
WHERE b.id IS NULL;

---------------------------------------------------------------------------
How would you pivot data in SQL?
SELECT category, SUM(CASE WHEN month = 'January' THEN
value END) AS January
FROM sales
GROUP BY category;

----------------------------------------------------------------------------
How would you normalize a table, and why is it important?
Normalization removes redundancy by structuring data across tables, enforcing dependencies, and improving consistency.

---------------------------------------------------------------------------
How would you denormalize data for performance?
Combine tables to reduce joins, allowing faster reads, often used in reporting databases.

--------------------------------------------------------------------------
How would you create an index, and when should you avoid it?
Use CREATE INDEX for frequently searched columns but avoid over-indexing on tables with frequent writes, as it slows down insertions.

-----------------------------------------------------------------------------
Explain the use of IFNULL and NULLIF.
IFNULL replaces NULL with a default value, while NULLIF returns NULL if two expressions are equal.

----------------------------------------------------------------------------
How do you find the first and last records in a grouped dataset?
SELECT category, FIRST_VALUE(value) OVER (PARTITION BY
category ORDER BY date) AS first_value

----------------------------------------------------------------------------
How would you write a recursive query?
WITH RECURSIVE cte AS (
SELECT column FROM table
UNION ALL
SELECT column FROM table WHERE condition
)

---------------------------------------------------------------------------
Explain a CASE statement and give an example.

SELECT name,
CASE
WHEN score > 90 THEN 'A'
WHEN score > 80 THEN 'B'
ELSE 'C'
END AS grade
FROM students;

--------------------------------------------------------------------------
What are SQL constraints, and why are they important?
Constraints enforce rules on data, such as PRIMARY KEY, FOREIGN KEY, and CHECK, to maintain integrity.

--------------------------------------------------------------------------
What is a materialized view?
A materialized view stores the results of a query physically for fast access, unlike regular views which are computed on demand.

---------------------------------------------------------------------------
How would you schedule an SQL job to run periodically?
Use database schedulers, such as SQL Server Agent or cron jobs.

----------------------------------------------------------------------------
What is the purpose of the LIMIT and OFFSET clauses?
LIMIT restricts result rows, while OFFSET skips a number of rows, useful for pagination.

-----------------------------------------------------------------------------
Explain the difference between VARCHAR and CHAR.
Answer: CHAR has a fixed length, while VARCHAR is variable-length, saving space for shorter values.

-------------------------------------------------------------------------------
How would you handle transactional deadlocks in SQL?
Answer: Use retry logic, lower isolation levels, and index tables appropriately to reduce deadlocks.

------------------------------------------------------------------------------
What is a stored procedure, and why use one?
Answer: A stored procedure is a saved SQL script that can be reused, which helps with performance, code organization, and security.

------------------------------------------------------------------------------
How would you handle time zone conversions in SQL?
Answer: Use AT TIME ZONE or equivalent functions to convert between time zones.

-----------------------------------------------------------------------------
Explain the use of PARTITION BY and ORDER BY in window functions.
Answer: PARTITION BY groups rows, and ORDER BY sets the order within each partition, crucial for calculations like ranking and cumulative sums

----------------------------------------------------------------------------
How do you measure query performance in SQL?
Answer: Use execution plans, query runtime, index usage stats, and track CPU/memory usage.

---------------------------------------------------------------------------
What is a temp table, and when would you use it?
Answer: Temporary tables store intermediate results, ideal for complex queries and session-specific data.

--------------------------------------------------------------------------
How would you handle schema changes in a production database?
Answer: Test changes in a staging environment, backup data, use ALTER TABLE carefully, and communicate downtime if needed.

-----------------------------------------------------------------------------
What is a CTE, and how does it differ from a subquery?
Answer: A CTE is a temporary result set within a query for better readability and reusability, while a subquery is a nested query directly within another query.

----------------------------------------------------------------------------
How would you identify customers who made a purchase last year but not this year?



-- Adjust years as needed
SELECT customer_id
FROM Orders
WHERE EXTRACT(YEAR FROM order_date) = 2024

EXCEPT

SELECT customer_id
FROM Orders
WHERE EXTRACT(YEAR FROM order_date) = 2025;

or 

SELECT DISTINCT customer_id
FROM Orders
WHERE EXTRACT(YEAR FROM order_date) = 2024
  AND customer_id NOT IN (
    SELECT DISTINCT customer_id
    FROM Orders
    WHERE EXTRACT(YEAR FROM order_date) = 2025
);


------------------------------------------------------------------------------
Given a sales table, how do you find the top 3 sales representatives based on total sales?

CREATE TABLE Sales14 (
    sale_id INT,
    rep_name VARCHAR(100),
    sale_amount DECIMAL(10,2)
);


INSERT INTO Sales14 (sale_id, rep_name, sale_amount) VALUES
(1, 'Alice', 1000.00),
(2, 'Bob', 1500.00),
(3, 'Alice', 2000.00),
(4, 'Carol', 1800.00),
(5, 'David', 1200.00),
(6, 'Bob', 1700.00),
(7, 'Eve', 900.00);


WITH RankedSales AS (
  SELECT rep_name,
         SUM(sale_amount) AS total_sales,
         RANK() OVER (ORDER BY SUM(sale_amount) DESC) AS sales_rank
  FROM Sales14
  GROUP BY rep_name
)
SELECT *
FROM RankedSales
WHERE sales_rank <= 3;


-----------------------------------------------------------------------
/*How would you find customers who’ve bought all products in a given product list?*/
-- Customer purchases
CREATE TABLE CustomerPurchases (
    customer_id INT,
    product_id INT
);

-- Target product list
CREATE TABLE TargetProducts (
    product_id INT
);

-- Purchases
INSERT INTO CustomerPurchases VALUES
(1, 101), (1, 102), (1, 103),
(2, 101), (2, 102),
(3, 101), (3, 102), (3, 103);

-- Target product list
INSERT INTO TargetProducts VALUES
(101), (102), (103);

SELECT customer_id
FROM CustomerPurchases
WHERE product_id IN (SELECT product_id FROM TargetProducts)
GROUP BY customer_id
HAVING COUNT(DISTINCT product_id) = (SELECT COUNT(*) FROM TargetProducts);

------------------------------------------------------------------------------
CREATE TABLE Attendance (
    employee_id INT,
    attendance_date DATE,
    status VARCHAR(10)  -- 'Present' or 'Absent'
);

INSERT INTO Attendance VALUES
(1, '2025-07-01', 'Present'),
(1, '2025-07-02', 'Absent'),
(1, '2025-07-03', 'Absent'),
(1, '2025-07-04', 'Absent'),
(1, '2025-07-05', 'Present'),
(2, '2025-07-01', 'Absent'),
(2, '2025-07-02', 'Absent'),
(2, '2025-07-03', 'Present');


/* How do you identify consecutive absences in attendance data?*/
WITH AbsentDays AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY attendance_date) 
         - 
         ROW_NUMBER() OVER (PARTITION BY employee_id, status ORDER BY attendance_date) 
         AS grp
  FROM Attendance
  WHERE status = 'Absent'
)
SELECT 
    employee_id,
    MIN(attendance_date) AS absence_start,
    MAX(attendance_date) AS absence_end,
    COUNT(*) AS consecutive_days
FROM AbsentDays
GROUP BY employee_id, grp
HAVING COUNT(*) >= 2  -- change this to detect 3+ or N+ day streaks
ORDER BY employee_id, absence_start;

