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


