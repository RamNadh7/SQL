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
Question: For each product sold, calculate the running total of the number of sales made over time, ordered by sale date.
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
 You are given a table Service_Requests with columns request_id, created_at, and resolved_at. Write a query to calculate the average time taken to resolve a request (in hours), excluding weekends. 
*/


WITH all_hours AS (
  SELECT 
    request_id,
    generate_series(
      created_at,
      resolved_at,
      interval '1 hour'
    ) AS hourly_tick
  FROM Service_Requests
),
filtered_hours AS (
  SELECT 
    request_id,
    hourly_tick
  FROM all_hours
  WHERE EXTRACT(DOW FROM hourly_tick) BETWEEN 1 AND 5 -- Mon to Fri
)
  ROUND(COUNT(*)::numeric / COUNT(DISTINCT request_id), 2) AS avg_resolution_time_hours
FROM filtered_hours;

-------------------------------alternate solution -------------------------------------------


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
 Given a Purchases table, find customers who have made more than 5 purchases in the last 6 months, along with their total spend.
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
You have a table of student grades. Write a query to find students who do not have grades for all subjects.
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

----------------------------------------------------------
WITH yr_sale AS (
  SELECT employee_id, SUM(amount) AS total_sales
  FROM Sales1
  WHERE sale_date >= CURRENT_DATE - INTERVAL '1 year'
  GROUP BY employee_id
),
ranked_sales AS (
  SELECT 
    employee_id,
    total_sales,
    DENSE_RANK() OVER (ORDER BY total_sales DESC) AS rnk
  FROM yr_sale
)
SELECT employee_id, total_sales, rnk
FROM ranked_sales
WHERE rnk <= 3;

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
Explain how partitioning works in SQL and provide an example of partitioning a table by date. 
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


--------------------------------------------------------------------------
/*How would you calculate the percentage growth in sales month over month?*/

CREATE TABLE MonthlySales (
    month DATE,
    sales DECIMAL(10,2)
);

INSERT INTO MonthlySales (month, sales) VALUES
('2025-01-01', 100000.00),
('2025-02-01', 120000.00),
('2025-03-01', 110000.00),
('2025-04-01', 130000.00),
('2025-05-01', 125000.00),
('2025-06-01', 140000.00);


SELECT 
    month,
    sales,
    LAG(sales) OVER (ORDER BY month) AS prev_month_sales,
    ROUND(
        (sales - LAG(sales) OVER (ORDER BY month)) 
        / NULLIF(LAG(sales) OVER (ORDER BY month), 0) * 100, 2
    ) AS mom_growth_percent
FROM MonthlySales;


-------------------------------------------------------------------------------
-- Orders that have been shipped
CREATE TABLE Shipments (
    shipment_id INT,
    order_id INT,
    shipped_date DATE
);

-- Orders that have been billed
CREATE TABLE Invoices1 (
    invoice_id INT,
    order_id INT,
    billed_date DATE
);

INSERT INTO Shipments (shipment_id, order_id, shipped_date) VALUES
(1, 1001, '2025-06-01'),
(2, 1002, '2025-06-03'),
(3, 1003, '2025-06-05'),
(4, 1004, '2025-06-07'),
(5, 1005, '2025-06-09'),
(6, 1006, '2025-06-11');


INSERT INTO Invoices1 (invoice_id, order_id, billed_date) VALUES
(101, 1001, '2025-06-02'),
(102, 1003, '2025-06-06'),
(103, 1005, '2025-06-10');

/*How can you identify orders that have been shipped but not yet billed?*/
SELECT s.order_id, s.shipped_date
FROM Shipments s
LEFT JOIN Invoices1 i ON s.order_id = i.order_id
WHERE i.invoice_id IS NULL;

----------------------------------------------------------------------------
CREATE TABLE Transactions (
    transaction_id INT,
    transaction_date DATE,
    amount DECIMAL(10,2)
);


INSERT INTO Transactions VALUES
(1, '2025-07-01', 100.00),
(2, '2025-07-01', 150.00),
(3, '2025-07-02', 200.00),
(4, '2025-07-02', 50.00),
(5, '2025-07-02', 300.00),
(6, '2025-07-03', 120.00),
(7, '2025-07-03', 80.00);

/* Given transaction data, how would you find the day with the highest transactions?*/

SELECT transaction_date, COUNT(*) AS transaction_count
FROM Transactions
GROUP BY transaction_date
ORDER BY transaction_count DESC
LIMIT 1;

-----------------------------------------------------------------------------
CREATE TABLE Employees5 (
    emp_id INT,
    emp_name VARCHAR(100),
    department VARCHAR(50),
    performance_score INT
);

INSERT INTO Employees5 VALUES
(1, 'Alice', 'Sales', 85),
(2, 'Bob', 'Sales', 92),
(3, 'Carol', 'Sales', 85),
(4, 'David', 'HR', 78),
(5, 'Eve', 'HR', 88),
(6, 'Frank', 'HR', 88),
(7, 'Grace', 'IT', 95),
(8, 'Heidi', 'IT', 90);

/*How would you rank employees within departments based on their performance score?*/
SELECT 
    emp_id,
    emp_name,
    department,
    performance_score,
    Dense_RANK() OVER (
        PARTITION BY department 
        ORDER BY performance_score DESC
    ) AS dept_rank
FROM Employees5
ORDER BY department, dept_rank;


--------------------------------------------------------------------------
CREATE TABLE Orders6 (
    order_id INT,
    customer_id INT,
    order_date DATE
);

INSERT INTO Orders6 VALUES
(1, 101, '2025-06-01'),
(2, 102, '2025-06-02'),
(3, 101, '2025-06-03'),
(4, 103, '2025-06-04'),
(5, 104, '2025-06-05'),
(6, 104, '2025-06-06'),
(7, 104, '2025-06-07'),
(8, 105, '2025-06-08');

/*How would you retrieve customers who placed exactly two orders?*/

SELECT customer_id
FROM Orders6
GROUP BY customer_id
HAVING COUNT(*) = 2;
--------------------------------------------------------------------------
/*How do you find the first purchase made by each customer?*/
WITH RankedPurchases AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY customer_id 
           ORDER BY purchase_date
         ) AS rn
  FROM Purchases
)
SELECT *
FROM RankedPurchases
WHERE rn = 1;


----------------------------------------------------------------------------
/*How do you identify orders with a price change compared to the previous order?*/
CREATE TABLE Orders7 (
    order_id INT,
    customer_id INT,
    order_date DATE,
    price DECIMAL(10,2)
);


INSERT INTO Orders7 VALUES
(1, 101, '2025-06-01', 100.00),
(2, 101, '2025-06-05', 100.00),
(3, 101, '2025-06-10', 120.00),
(4, 102, '2025-06-02', 200.00),
(5, 102, '2025-06-08', 180.00);

SELECT *
FROM (
    SELECT 
        order_id,
        customer_id,
        order_date,
        price,
        LAG(price) OVER (
            PARTITION BY customer_id 
            ORDER BY order_date
        ) AS previous_price
    FROM Orders7
) AS sub
WHERE price <> previous_price;

-----------------------------------------------------------------------
/*How would you find the average sales by month and year?*/
SELECT 
    EXTRACT(YEAR FROM sale_date) AS sale_year,
    EXTRACT(MONTH FROM sale_date) AS sale_month,
    round(AVG(amount),2) AS average_sales
FROM Sales1
GROUP BY 
    EXTRACT(YEAR FROM sale_date),
    EXTRACT(MONTH FROM sale_date)
ORDER BY 
    sale_year,
    sale_month;


----------------------------------------------------------------------------
CREATE TABLE Orders8 (
    order_id INT,
    customer_id INT,
    order_date DATE
);

INSERT INTO Orders8 (order_id, customer_id, order_date) VALUES
-- Customer 101: Jan & Feb (consecutive)
(1, 101, '2025-01-10'),
(2, 101, '2025-02-15'),

-- Customer 102: Feb & Apr (not consecutive)
(3, 102, '2025-02-20'),
(4, 102, '2025-04-05'),

-- Customer 103: Mar only
(5, 103, '2025-03-12'),

-- Customer 104: Apr & May (consecutive)
(6, 104, '2025-04-18'),
(7, 104, '2025-05-02'),

-- Customer 105: May & Jun (consecutive)
(8, 105, '2025-05-25'),
(9, 105, '2025-06-01'),

-- Customer 106: Jan, Feb, Mar (multiple consecutive)
(10, 106, '2025-01-05'),
(11, 106, '2025-02-10'),
(12, 106, '2025-03-15');


/*How do you find customers who placed orders in two consecutive months?*/


WITH MonthlyOrders AS (
  SELECT DISTINCT 
         customer_id,
         DATE_TRUNC('month', order_date) AS order_month
  FROM Orders8
),
RankedOrders AS (
  SELECT customer_id,
         order_month,
         LAG(order_month) OVER (
             PARTITION BY customer_id 
             ORDER BY order_month
         ) AS prev_month
  FROM MonthlyOrders
)
SELECT DISTINCT customer_id
FROM RankedOrders
WHERE prev_month IS NOT NULL
  AND order_month = prev_month + INTERVAL '1 month';


------------------------------------------------------------------------------
How would you get the running total of sales over time?

SELECT 
    sale_date,
    amount,
    SUM(amount) OVER (
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM Sales1;

------------------------------------------------------------------------------
/*How would you handle a situation where you need to delete duplicate records, keeping only the latest entry?*/

WITH RankedUsers AS (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY email
           ORDER BY updated_at DESC
         ) AS rn
  FROM Users
)
DELETE FROM Users
WHERE id IN (
  SELECT id
  FROM RankedUsers
  WHERE rn > 1
);
or 

DELETE FROM Users
WHERE id NOT IN (
  SELECT MAX(id)
  FROM Users
  GROUP BY email
);
 ----------------------------------------------------------------------------

 CREATE TABLE Events (
    event_id INT,
    event_name VARCHAR(100),
    start_time TIMESTAMP,
    end_time TIMESTAMP
);

INSERT INTO Events (event_id, event_name, start_time, end_time) VALUES
(1, 'Login Session', '2025-07-05 08:00:00', '2025-07-05 10:15:00'),
(2, 'System Backup', '2025-07-05 01:30:00', '2025-07-05 03:00:00'),
(3, 'Data Sync', '2025-07-04 22:00:00', '2025-07-05 00:45:00'),
(4, 'Report Generation', '2025-07-05 09:00:00', '2025-07-05 09:45:00');

/* How do you calculate the time difference between two timestamps in SQL? */
SELECT 
    event_id,
    event_name,
    start_time,
    end_time,
    end_time - start_time AS duration,
    EXTRACT(EPOCH FROM end_time - start_time) / 60 AS duration_minutes
FROM Events;

select end_time - start_time from events;

select start_time - end_time from events;

------------------------------------------------------------------------------
/*How would you retrieve products with the same price across multiple orders?*/

SELECT product_id, price
FROM orders2
GROUP BY product_id, price
HAVING COUNT(DISTINCT order_id) > 1;

----------------------------------------------------------------------------
How do you find all orders placed in the last 7 days?

SELECT *
FROM Orders
WHERE order_date >= CURRENT_DATE - INTERVAL '7 days';

----------------------------------------------------------------------------
How would you retrieve the order with the maximum amount for each customer?

WITH RankedOrders AS (
  SELECT *,
         RANK() OVER (
           PARTITION BY customer_id 
           ORDER BY amount DESC
         ) AS rnk
  FROM Orders
)
SELECT order_id, customer_id, order_date, amount
FROM RankedOrders
WHERE rnk = 1;


-----------------------------------------------------------------------------
/* Copy Rights Reserved How do you calculate monthly retention rates for customers?*/

CREATE TABLE customer_activity (
    customer_id INT,
    activity_date DATE
);

INSERT INTO customer_activity VALUES
(1, '2025-01-10'), (1, '2025-02-15'), (1, '2025-03-01'),
(2, '2025-01-12'),
(3, '2025-02-05'), (3, '2025-03-10'),
(4, '2025-02-20'),
(5, '2025-03-05'), (5, '2025-04-01');


WITH cohort AS (
  SELECT 
    customer_id,
    DATE_TRUNC('month', MIN(activity_date)) AS cohort_month
  FROM customer_activity
  GROUP BY customer_id
),
activity_by_month AS (
  SELECT 
    customer_id,
    DATE_TRUNC('month', activity_date) AS activity_month
  FROM customer_activity
),
cohort_activity AS (
  SELECT 
    c.cohort_month,
    a.activity_month,
    a.customer_id
  FROM cohort c
  JOIN activity_by_month a ON c.customer_id = a.customer_id
)
SELECT 
  cohort_month,
  activity_month,
  COUNT(DISTINCT customer_id) AS retained_customers
FROM cohort_activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;

or

SELECT 
    a.month AS retained_in_month,
    COUNT(DISTINCT a.customer_id) AS retained_customers
FROM customers a
JOIN customers b
  ON a.customer_id = b.customer_id
 AND b.month = a.month + INTERVAL '1 month'
GROUP BY a.month
ORDER BY a.month;

---------------------------------------------------------------------------
/*How would you identify the best-selling product each month?*/

CREATE TABLE OrderDetails (
    order_id INT,
    product_id INT,
    order_date DATE,
    quantity INT
);

INSERT INTO OrderDetails VALUES
(1, 101, '2025-01-05', 5),
(2, 102, '2025-01-10', 3),
(3, 101, '2025-01-15', 2),
(4, 103, '2025-02-01', 7),
(5, 101, '2025-02-10', 4),
(6, 102, '2025-02-20', 6),
(7, 103, '2025-02-25', 3);

WITH MonthlySales AS (
  SELECT 
    DATE_TRUNC('month', order_date) AS sale_month,
    product_id,
    SUM(quantity) AS total_quantity
  FROM OrderDetails
  GROUP BY sale_month, product_id
),
RankedSales AS (
  SELECT *,
         RANK() OVER (
           PARTITION BY sale_month 
           ORDER BY total_quantity DESC
         ) AS rank
  FROM MonthlySales
)
SELECT sale_month, product_id, total_quantity
FROM RankedSales
WHERE rank = 1
ORDER BY sale_month;

----------------------------------------------------------------------------
/*How do you handle a case where you need to split data between weekends and weekdays?*/

SELECT 
  CASE 
    WHEN EXTRACT(DOW FROM sale_date) IN (0, 6) THEN 'Weekend'
    ELSE 'Weekday'
  END AS day_type,
  COUNT(*) AS total_sales,
  SUM(amount) AS total_amount
FROM Sales15
GROUP BY day_type;

---------------------------------------------------------------------------
/*How do you calculate the difference in sales between two periods?*/

WITH sales_by_month AS (
  SELECT 
    DATE_TRUNC('month', sale_date) AS month,
    SUM(amount) AS total_sales
  FROM Sales
  GROUP BY month
),
ranked_sales AS (
  SELECT *,
         LAG(total_sales) OVER (ORDER BY month) AS previous_sales
  FROM sales_by_month
)
SELECT 
  month,
  total_sales,
  previous_sales,
  total_sales - previous_sales AS sales_diff,
  ROUND((total_sales - previous_sales) * 100.0 / previous_sales, 2) AS percent_change
FROM ranked_sales;

-------------------------------------------------------------------------------
/*How would you calculate a cohort retention rate?*/

SELECT cohort, COUNT(DISTINCT
retained_customers.customer_id) / COUNT(DISTINCT
initial_customers.customer_id) AS retention_rate
FROM customers initial_customers
LEFT JOIN customers retained_customers ON
initial_customers.customer_id =
retained_customers.customer_id;

----------------------------------------------------------------------------
/*How would you identify customers who haven’t purchased in over 6 months?*/

CREATE TABLE Purchases1 (
    customer_id INT,
    purchase_date DATE
);

INSERT INTO Purchases1 VALUES
(1, '2025-01-10'),
(2, '2025-06-01'),
(3, '2024-12-15'),
(4, '2025-02-20'),
(5, '2025-07-01');  -- recent purchase


WITH LastPurchase AS (
  SELECT 
    customer_id,
    MAX(purchase_date) AS last_purchase
  FROM Purchases1
  GROUP BY customer_id
)
SELECT customer_id, last_purchase
FROM LastPurchase
WHERE last_purchase < CURRENT_DATE - INTERVAL '6 months';

------------------------------------------------------------------------------
/*How would you find employees who joined within the last quarter?*/

SELECT *
FROM employees
WHERE joining_date >= DATE_TRUNC('quarter', CURRENT_DATE);

SELECT 
  employee_id,
  employee_name,
  joining_date,
  DATE_TRUNC('quarter', joining_date) AS joined_quarter
FROM employees
WHERE joining_date >= DATE_TRUNC('quarter', CURRENT_DATE);


---------------------------------------------------------------------------
/*How do you retrieve the last three months’ average sales per day?*/
WITH recent_sales AS (
  SELECT *
  FROM Sales
  WHERE sale_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '3 months'
)
SELECT 
  ROUND(SUM(amount) / COUNT(DISTINCT sale_date), 2) AS avg_sales_per_day
FROM recent_sales;

----------------------------------------------------------------------
---How do you select all employees with higher salaries than their department average?
SELECT e.employee_id, e.name, e.department_id, e.salary
FROM employees e
JOIN (
  SELECT department_id, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY department_id
) d ON e.department_id = d.department_id
WHERE e.salary > d.avg_salary;


----------------------------------------------------------------------------
---- How would you identify users who placed their last order in December last year?
WITH LastOrders AS (
  SELECT 
    customer_id,
    MAX(order_date) AS last_order_date
  FROM Orders
  GROUP BY customer_id
)
SELECT customer_id, last_order_date
FROM LastOrders
WHERE EXTRACT(YEAR FROM last_order_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
  AND EXTRACT(MONTH FROM last_order_date) = 12;


-------------------------------------------------------------------------
---- How do you retrieve products with the second-highest sales for each category?

WITH ProductSales AS (
  SELECT 
    p.category,
    p.product_id,
    p.product_name,
    SUM(s.quantity) AS total_quantity
  FROM Products p
  JOIN Sales s ON p.product_id = s.product_id
  GROUP BY p.category, p.product_id, p.product_name
),
RankedSales AS (
  SELECT *,
         RANK() OVER (
           PARTITION BY category 
           ORDER BY total_quantity DESC
         ) AS sales_rank
  FROM ProductSales
)
SELECT category, product_name, total_quantity
FROM RankedSales
WHERE sales_rank = 2;


-------------------------------------------------------------------------
---- How would you find the average order amount for the top 10% of orders?
WITH OrderAmounts AS (
  SELECT order_id, amount
  FROM Orders
),
Threshold AS (
  SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY amount) AS cutoff
  FROM OrderAmounts
)
SELECT ROUND(AVG(amount), 2) AS avg_top_10_percent
FROM OrderAmounts, Threshold
WHERE amount >= Threshold.cutoff;

--------------------------------------------------------------------------
--- How do you find orders that took longer than the average processing time?

WITH ProcessingTimes AS (
  SELECT 
    order_id,
    order_date,
    shipped_date,
    (shipped_date - order_date) AS processing_days
  FROM Orders
),
AverageTime AS (
  SELECT AVG(processing_days) AS avg_days
  FROM ProcessingTimes
)
SELECT pt.*
FROM ProcessingTimes pt, AverageTime at
WHERE pt.processing_days > at.avg_days;


-------------------------------------------------------------------------
--- How would you find customers with both high purchase frequency and high average order value?

WITH CustomerStats AS (
  SELECT 
    customer_id,
    COUNT(*) AS total_orders,
    AVG(amount) AS avg_order_value
  FROM Orders
  GROUP BY customer_id
)
SELECT *
FROM CustomerStats
WHERE total_orders > (
    SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY total_orders)
    FROM CustomerStats
)
AND avg_order_value > (
    SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY avg_order_value)
    FROM CustomerStats
);


----------------------------------------------------------------------------
----How do you get the last three months' revenue and average revenue per month?
WITH recent_sales AS (
  SELECT 
    DATE_TRUNC('month', sale_date) AS sale_month,
    SUM(amount) AS monthly_revenue
  FROM Sales
  WHERE sale_date >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '3 months'
  GROUP BY sale_month
)
SELECT 
  SUM(monthly_revenue) AS total_revenue_last_3_months,
  ROUND(AVG(monthly_revenue), 2) AS avg_revenue_per_month
FROM recent_sales;


--------------------------------------------------------------------------------
------ How would you retrieve customers who’ve never made a purchase?
SELECT c.customer_id, c.name
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;


---------------------------------------------------------------------------
--- How would you check for salary discrepancies between employees in the same role?

SELECT 
  job_title,
  MIN(salary) AS min_salary,
  MAX(salary) AS max_salary,
  ROUND(AVG(salary), 2) AS avg_salary,
  COUNT(*) AS employee_count
FROM employees
GROUP BY job_title
HAVING MAX(salary) - MIN(salary) > 0;


SELECT 
  job_title,
  employee_id,
  employee_name,
  salary,
  ROUND(AVG(salary) OVER (PARTITION BY job_title), 2) AS avg_role_salary,
  salary - AVG(salary) OVER (PARTITION BY job_title) AS salary_diff
FROM employees
ORDER BY job_title, salary_diff DESC;


--------------------------------------------------------------------------
--- How do you calculate the average time between two events in an event log?
WITH ordered_events AS (
  SELECT 
    user_id,
    event_time,
    LEAD(event_time) OVER (
      PARTITION BY user_id 
      ORDER BY event_time
    ) AS next_event_time
  FROM event_log
),
event_deltas AS (
  SELECT 
    user_id,
    event_time,
    next_event_time,
    EXTRACT(EPOCH FROM next_event_time - event_time) AS seconds_between
  FROM ordered_events
  WHERE next_event_time IS NOT NULL
)
SELECT 
  user_id,
  ROUND(AVG(seconds_between), 2) AS avg_seconds_between_events
FROM event_deltas
GROUP BY user_id;


-----------------------------------------------------------------------------
---How would you find products that haven’t been sold in the last six months?
SELECT p.product_id, p.product_name
FROM Products p
LEFT JOIN Sales s 
  ON p.product_id = s.product_id 
  AND s.sale_date >= CURRENT_DATE - INTERVAL '6 months'
WHERE s.product_id IS NULL;


------------------------------------------------------------------------
---- How would you retrieve the highest daily sales for each month?

WITH daily_totals AS (
  SELECT 
    DATE_TRUNC('day', sale_date) AS sale_day,
    DATE_TRUNC('month', sale_date) AS sale_month,
    SUM(amount) AS daily_total
  FROM Sales
  GROUP BY sale_day, sale_month
),
ranked_days AS (
  SELECT *,
         RANK() OVER (
           PARTITION BY sale_month 
           ORDER BY daily_total DESC
         ) AS rank
  FROM daily_totals
)
SELECT sale_month, sale_day, daily_total
FROM ranked_days
WHERE rank = 1
ORDER BY sale_month;


------------------------------------------------------------------------
--- How do you rank products within each category by total revenue?

WITH ProductRevenue AS (
  SELECT 
    p.category,
    p.product_id,
    p.product_name,
    SUM(s.amount) AS total_revenue
  FROM Products p
  JOIN Sales s ON p.product_id = s.product_id
  GROUP BY p.category, p.product_id, p.product_name
),
RankedProducts AS (
  SELECT *,
         RANK() OVER (
           PARTITION BY category 
           ORDER BY total_revenue DESC
         ) AS revenue_rank
  FROM ProductRevenue
)
SELECT category, product_name, total_revenue, revenue_rank
FROM RankedProducts
ORDER BY category, revenue_rank;


-------------------------------------------------------------------------
---How would you handle outliers in a dataset for sales orders?

WITH stats AS (
  SELECT 
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) AS q1,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) AS q3
  FROM Sales
)
SELECT *
FROM Sales, stats
WHERE amount < q1 - 1.5 * (q3 - q1)
   OR amount > q3 + 1.5 * (q3 - q1);

---------------------------------------------------------------------------
/* How would you find customers whose total spending is within the top 20% of all customers? */

WITH CustomerSpend AS (
  SELECT 
    customer_id,
    SUM(amount) AS total_spent
  FROM Orders
  GROUP BY customer_id
),
Threshold AS (
  SELECT 
    PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY total_spent) AS cutoff
  FROM CustomerSpend
)
SELECT cs.customer_id, cs.total_spent
FROM CustomerSpend cs, Threshold t
WHERE cs.total_spent >= t.cutoff;

-----------------------------------------------------------------------
--- How do you select all orders with their most recent status?
WITH RankedStatus AS (
  SELECT 
    order_id,
    status,
    status_date,
    ROW_NUMBER() OVER (
      PARTITION BY order_id 
      ORDER BY status_date DESC
    ) AS rn
  FROM OrderStatus
)
SELECT o.order_id, o.customer_id, rs.status, rs.status_date
FROM Orders o
JOIN RankedStatus rs ON o.order_id = rs.order_id
WHERE rs.rn = 1;


--------------------------------------------------------------------------
--- How would you identify customers with irregular ordering patterns (e.g., high variance in order frequency)?

WITH ordered_events AS (
  SELECT 
    customer_id,
    order_date,
    LAG(order_date) OVER (
      PARTITION BY customer_id 
      ORDER BY order_date
    ) AS previous_order
  FROM Orders
),
order_gaps AS (
  SELECT 
    customer_id,
    EXTRACT(DAY FROM order_date - previous_order) AS gap_days
  FROM ordered_events
  WHERE previous_order IS NOT NULL
)
SELECT 
  customer_id,
  COUNT(*) AS num_gaps,
  ROUND(AVG(gap_days), 2) AS avg_gap,
  ROUND(STDDEV(gap_days), 2) AS stddev_gap,
  ROUND(STDDEV(gap_days) / NULLIF(AVG(gap_days), 0), 2) AS coeff_variation
FROM order_gaps
GROUP BY customer_id
ORDER BY coeff_variation DESC NULLS LAST;

----------------------------------------------------------------------------
-- How do you retrieve customers who haven’t ordered in the current year but did in previous years?

WITH previous_orders AS (
  SELECT DISTINCT customer_id
  FROM Orders
  WHERE EXTRACT(YEAR FROM order_date) < EXTRACT(YEAR FROM CURRENT_DATE)
),
current_year_orders AS (
  SELECT DISTINCT customer_id
  FROM Orders
  WHERE EXTRACT(YEAR FROM order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
)
SELECT c.customer_id, c.name
FROM Customers c
JOIN previous_orders p ON c.customer_id = p.customer_id
WHERE c.customer_id NOT IN (
  SELECT customer_id FROM current_year_orders
);


----------------------------------------------------------------------
--- How would you calculate the month-over-month growth rate in SQL?

WITH monthly_revenue AS (
  SELECT 
    DATE_TRUNC('month', sale_date) AS month,
    SUM(amount) AS total_revenue
  FROM Sales
  GROUP BY month
),
growth_calc AS (
  SELECT 
    month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY month) AS prev_month_revenue
  FROM monthly_revenue
)
SELECT 
  month,
  total_revenue,
  prev_month_revenue,
  ROUND(
    CASE 
      WHEN prev_month_revenue = 0 THEN NULL
      ELSE (total_revenue - prev_month_revenue) * 100.0 / prev_month_revenue
    END, 2
  ) AS mom_growth_percent
FROM growth_calc
ORDER BY month;


------------------------------------------------------------------------
--- How do you identify products that have been ordered together frequently?

SELECT 
  oi1.product_id AS product_a,
  oi2.product_id AS product_b,
  COUNT(DISTINCT oi1.order_id) AS times_ordered_together
FROM OrderItems oi1
JOIN OrderItems oi2 
  ON oi1.order_id = oi2.order_id 
  AND oi1.product_id < oi2.product_id
GROUP BY product_a, product_b
ORDER BY times_ordered_together DESC;


---------------------------------------------------------------------------
---- How would you find the most popular time slots for orders in a day?

SELECT 
  CASE 
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 16 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM order_time) BETWEEN 17 AND 21 THEN 'Evening'
    ELSE 'Night'
  END AS time_slot,
  COUNT(*) AS order_count
FROM Orders
GROUP BY time_slot
ORDER BY order_count DESC;


--------------------------------------------------------------------------
CREATE TABLE NUM (
    SN INT,
    NUMB INT
);

-- Step 2: Insert sample data
INSERT INTO NUM (SN, NUMB) VALUES
(1, 4),
(2, 7),
(3, 4),
(4, 9),
(5, 9),
(6, 7),
(7, 9),
(8, 4);

select a.numb from num a
join num b on a.sn+1=b.sn
join num c on a.sn+2=c.sn
where a.numb=c.numb
and a.numb<>b.numb;


-----------------------------------------------------------------------------------------------
-- Create the table
CREATE TABLE teams (
    team_name VARCHAR(50) NOT NULL
);

-- Insert team names
INSERT INTO teams (team_name) VALUES 
('CSK'),
('KKR'),
('GT'),
('DC'),
('LSG');

select concat(t1.team_name, ' vs ' ,t2.team_name) from teams t1
join teams t2 on t1.team_name < t2.team_name order by t1.team_name;


-------------------------------------------------------------------------------------------------------------------
CREATE TABLE credit_card_issuance (
    card_name VARCHAR(50) NOT NULL,
    issued_amount INT NOT NULL,
    issue_month INT NOT NULL CHECK (issue_month BETWEEN 1 AND 12),
    issue_year INT NOT NULL,
    PRIMARY KEY (card_name, issue_month, issue_year)
);

-- Insert the data
INSERT INTO credit_card_issuance (card_name, issued_amount, issue_month, issue_year) VALUES
('Chase Freedom Flex', 55000, 1, 2021),
('Chase Freedom Flex', 60000, 2, 2021),
('Chase Freedom Flex', 65000, 3, 2021),
('Chase Freedom Flex', 70000, 4, 2021),
('Chase Sapphire Reserve', 170000, 1, 2021),
('Chase Sapphire Reserve', 175000, 2, 2021),
('Chase Sapphire Reserve', 180000, 3, 2021);

select card_name,
max(issued_amount) - min(issued_amount) as amount_diff
from credit_card_issuance
group by card_name
order by amount_diff DESC;

------------------------------------------------------------------------------------------------------------
-- Create the table
CREATE TABLE transactions_avg (
    transaction_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_amount DECIMAL(10, 2) NOT NULL
);

-- Insert the data into the table
INSERT INTO transactions_avg (transaction_id, user_id, transaction_date, transaction_amount)
VALUES
    (1, 269, '2018-08-15', 500),
    (2, 478, '2018-11-25', 400),
    (3, 269, '2019-01-05', 1000),
    (4, 123, '2020-10-20', 600),
    (5, 478, '2021-07-05', 700),
    (6, 123, '2022-03-05', 900);

---Write a SQL query to calculate the average transaction amount per year for each client, where the years are in the range of 2018 to 2022.

select 
      extract(year from transaction_date) as yr,
      user_id,
      round(avg(transaction_amount),2)
      from transactions_avg
      where extract(year from transaction_date) BETWEEN 2018 and 2022
      group by user_id, yr
      order by yr;