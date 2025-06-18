
CREATE TABLE Employee (
    employee_id INT ,
    employee_name VARCHAR(50),
    department_id INT,
    position VARCHAR(50),
    salary DECIMAL(10, 2)
);


INSERT INTO Employee (employee_id, employee_name, department_id, position, salary)
VALUES 
(1, 'Alice Johnson', 101, 'Software Engineer', 70000),
(2, 'Bob Smith', 102, 'Data Scientist', 80000),
(3, 'Carol White', 103, 'Project Manager', 75000),
(4, 'David Brown', 104, 'Quality Assurance', 60000),
(5, 'Eva Green', 105, 'HR Specialist', 55000),
(6, 'Frank Martin', 101, 'Software Engineer', 70000),
(3, 'Carol White', 103, 'Project Manager', 75000),
(4, 'David Brown', 104, 'Quality Assurance', 60000)

select * from employee

--query 1. Remove duplicate values from employee table 
select distinct * from employee

-- query 2. write a query to find out duplicate values from employee 
with cte as(
select *, row_number() over(partition by employee_id order by employee_id ) as rn from employee
)
select * from cte where rn=2
-- query 3. write a query to find out highest earning employee based on each position 
select max(salary), position from employee group by position 

--query 4. write a query to get top 3 highest earning employee 
select top 3 * from employee order by salary desc 

with cte as(
select distinct * from employee)
select top 3* from cte order by salary desc

-- query 5 write a query to get top 3 lowest earning employee 

with cte as(
select distinct * from employee)
select top 3 * from cte order by salary asc 




CREATE TABLE Emp (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    location VARCHAR(50)
);

INSERT INTO Emp (employee_id, employee_name, department, salary, location)
VALUES 
(1, 'Alice Johnson', 'Engineering', 75000, 'New York'),
(2, 'Bob Smith', 'Data Science', 85000, 'San Francisco'),
(3, 'Carol White', 'Human Resources', 65000, 'Chicago'),
(4, 'David Brown', 'Engineering', 78000, 'Austin'),
(5, 'Eva Green', 'Marketing', 70000, 'Seattle'),
(6, 'Frank Martin', 'Data Science', 82000, 'New York'),
(7, 'Grace Lee', 'Finance', 90000, 'Los Angeles'),
(8, 'Harry Clark', 'Sales', 72000, 'Chicago'),
(9, 'Ivy Baker', 'Human Resources', 67000, 'Austin'),
(10, 'Jack Wilson', 'Marketing', 71000, 'San Francisco'),
(11, 'Karen Evans', 'Engineering', 76000, 'Seattle'),
(12, 'Leo Adams', 'Data Science', 84000, 'New York'),
(13, 'Mona Scott', 'Finance', 88000, 'Los Angeles'),
(14, 'Nate Perry', 'Sales', 74000, 'Chicago'),
(15, 'Olivia Cooper', 'Engineering', 78000, 'Austin');

select *from emp

--query 5 write a query to find out 2nd highest salary employee

with cte as(
select * , row_number() over(order by salary desc) rn from emp
)
select * from cte where rn=3

--query 6 write a query to get 2nd lowest earning employee 
with cte as(
select * , row_number() over(order by salary asc) rn from emp
)
select * from cte where rn=2

--query 7 write a query to get 2nd highest salary based on each department 

with cte as(
select * , row_number() over(partition by department order by salary desc) as rn from emp
)
select * from cte where rn=2

--query 8 write query to get 3rd lowest salary based on each location 
with cte as(
select * , row_number() over(partition by location order by salary asc) as rn from emp
)
select * from cte where rn=3
--query 9 write a query to get bottom 2 salary based on each location 

with cte as(
select * ,row_number() over(partition by location order by salary asc) as rn from emp
)
select * from cte where rn in (1,2)

--query 10 write a query to get top 2 salary based on each department 

with cte as(
select * ,row_number() over(partition by location order by salary desc) rn from emp
)
select * from cte where rn in (1,2)


---join related que

create table table1  (id int) 
Insert into table1 values(1),(1),(1),(1),(1)

create table table2 (id int)
Insert into table2 values(1),(1),(1),(1),(1),(null)


select * from table1
select * from table2

--query1. how many rows will you get when you will perform inner join 

select * from table1 join table2 on table1.id=table2.id

--query1. how many rows will you get when you will perform left join 
select * from table1 left join table2 on table1.id=table2.id

--query1. how many rows will you get when you will perform right join 

select * from table1 right join table2 on table1.id=table2.id
--query1. how many rows will you get when you will perform full join 

select * from table1 full join table2 on table1.id=table2.id


insert into table1 values(null)


--------
select * from employee
select * from table3
select * from table4

--query : write a query to create new table with same schema as employee table (only schema)
select * into table3 from employee where 1=2
--query 2: create new table same like employee table (data + schema) 
select * into table4 from employee where 1=1
--query 3 : write a query where employee_name starts with letter A
select * from employee where employee_name like 'A%'
--query 4 : write a query where department_id starts letter and ends letter is same 
select * from employee where left(department_id,1)=right(department_id,1)

--query 5 : write a query to get records in xml format 
select * from employee for xml auto

--query 6 : how to get current date 
select getdate()
select CURRENT_TIMESTAMP

--query 7: query to get cuurent month 
select month(getdate())

--query 8: query to get current year \

select year(getdate())




---question 1 . difference betwwn Union and Union all

UNION: Combines the results of two queries and removes duplicate rows.
UNION ALL: Combines the results of two queries without removing duplicate

--question 2 . primary key vs union difference 
primary key - Used to serve as a unique identifier for each row in a table.
Cannot accept NULL values.
Only one primary key

UNIQUE KEY- Uniquely determines a row that isn�t the primary key.
Can accept NULL values.
More than one unique key

emp_id  primary key     mobile nmber unique




--question difference between rank and dense rank 
RANK(): Skips ranks if there are ties.
DENSE_RANK(): Does not skip ranks, even if there are ties.

rank      dense rank     salary 
1          1             100000
2          2              70000
2          2              70000
4           3             50000


--questiuon 4 . delete vs drop vs truncate 

The TRUNCATE command helps us delete the complete records from an existing table

The DROP command drops the existing table from the database. It only requires the name of the table to be dropped.

The SQL DELETE command is a DML (Data Manipulation Language) command that deletes existing
records from the table in the database. It can delete one or more rows from the table
depending on the condition given with the WHERE clause

--question 5. what are different windows function 

Window functions perform calculations across a set of table rows related to the current row. Examples include:

ROW_NUMBER()
RANK()
DENSE_RANK()
AVG() OVER()

--question 6 . where and having clause difference
WHERE: Filters rows before grouping (GROUP BY).
HAVING: Filters groups created by GROUP BY.

--question 7. how to handle null values in sql 
Use functions like:
IS NULL or IS NOT NULL to filter records.
COALESCE(column, default_value) to replace NULL with a default value.




---important employee manager related sql question 

CREATE TABLE Emp4 (
    EmpID INT PRIMARY KEY,
    EmpName VARCHAR(50),
    ManagerID INT,
    Department VARCHAR(50)
);

INSERT INTO Emp4 (EmpID, EmpName, ManagerID, Department)
VALUES 
    (1, 'John', NULL, 'HR'),        -- John is the top-level manager
    (2, 'Alice', 1, 'Finance'),    -- Alice reports to John
    (3, 'Bob', 1, 'IT'),           -- Bob reports to John
    (4, 'Charlie', 2, 'Finance'),  -- Charlie reports to Alice
    (5, 'Eve', 3, 'IT');         

select * from emp4
-- Find out the employees manager details from employee table

select a.empname, b.empname as manager_name , a.department from emp4 a left join emp4 b 
on a.managerid=b.empid

-- query : write a query to find out cumulative sum of salary
select * from employee

select * , sum(salary) over(order by employee_id) as rn from employee


--- Fill null value with previous values 

CREATE TABLE Chocolate_Brands (
    chocolate_name VARCHAR(50),
    brand_name VARCHAR(50)
);

INSERT INTO Chocolate_Brands (chocolate_name, brand_name) VALUES
('KitKat', 'Nestle'),
('Perk', NULL),
('Munch', NULL),
('Dairy Milk', 'Cadbury'),
('5 Star', NULL),
('Silk', NULL);

select * from chocolate_brands


with cte as(
select * , row_number() over(order by (select null)) rn ,
case when brand_name is null then 0 else 1 end rn1
from chocolate_brands
)
,cte1 as(
select * , sum(rn1) over(order by rn) roll_sum from cte
)
select chocolate_name, brand_name , 
max(brand_name) over(partition by roll_sum) as new_brand_name from cte1


-- find new and repeated customer 

create table customer_orders (
order_id integer,
customer_id integer,
order_date date,
order_amount integer
);

insert into customer_orders values(1,100,cast('2022-01-01' as date),2000),(2,200,cast('2022-01-01' as date),2500),(3,300,cast('2022-01-01' as date),2100)
,(4,100,cast('2022-01-02' as date),2000),(5,400,cast('2022-01-02' as date),2200),(6,500,cast('2022-01-02' as date),2700)
,(7,100,cast('2022-01-03' as date),3000),(8,400,cast('2022-01-03' as date),1000),(9,600,cast('2022-01-03' as date),3000)


-- find new and repeated customer on each date 
select * from customer_orders



with first_visit_date as (
select customer_id , min(order_date) first_order from customer_orders
group by customer_id
),
final as(
select a.* , b.first_order ,case when order_date=first_order then 1 else 0 end new_customer,
case when order_date!=first_order then 1 else 0 end repeated_customer
from customer_orders a join first_visit_date b 
on a.customer_id=b.customer_id 
)
select sum(new_customer) new , sum(repeated_customer) as repeated , order_date from final
group by order_date

select * from first_visit_date













SQLQuery3.sql
Displaying SQLQuery3.sql.