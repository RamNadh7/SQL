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

