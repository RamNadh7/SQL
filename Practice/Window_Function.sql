
drop table employee;
create table employee
( emp_ID int
, emp_NAME varchar(50)
, DEPT_NAME varchar(50)
, SALARY int);

insert into employee values(101, 'Mohan', 'Admin', 4000);
insert into employee values(102, 'Rajkumar', 'HR', 3000);
insert into employee values(103, 'Akbar', 'IT', 4000);
insert into employee values(104, 'Dorvin', 'Finance', 6500);
insert into employee values(105, 'Rohit', 'HR', 3000);
insert into employee values(106, 'Rajesh',  'Finance', 5000);
insert into employee values(107, 'Preet', 'HR', 7000);
insert into employee values(108, 'Maryam', 'Admin', 4000);
insert into employee values(109, 'Sanjay', 'IT', 6500);
insert into employee values(110, 'Vasudha', 'IT', 7000);
insert into employee values(111, 'Melinda', 'IT', 8000);
insert into employee values(112, 'Komal', 'IT', 10000);
insert into employee values(113, 'Gautham', 'Admin', 2000);
insert into employee values(114, 'Manisha', 'HR', 3000);
insert into employee values(115, 'Chandni', 'IT', 4500);
insert into employee values(116, 'Satya', 'Finance', 6500);
insert into employee values(117, 'Adarsh', 'HR', 3500);
insert into employee values(118, 'Tejaswi', 'Finance', 5500);
insert into employee values(119, 'Cory', 'HR', 8000);
insert into employee values(120, 'Monica', 'Admin', 5000);
insert into employee values(121, 'Rosalin', 'IT', 6000);
insert into employee values(122, 'Ibrahim', 'IT', 8000);
insert into employee values(123, 'Vikram', 'IT', 8000);
insert into employee values(124, 'Dheeraj', 'IT', 11000);
COMMIT;


/* **************
   Video Summary
 ************** */

select * from employee;


select max(salary) as max_salary from employee;


select max(salary) as max_salary from employee
group by dept_name;


SELECT e.*,
max(salary) over(PARTITION BY dept_name) as max_salary
from employee e;


---- ROW_NUMBER, RANK,DENSE_RANK,LEAD AND LAG

SELECT e.*,
ROW_NUMBER() over() as rn
from employee e;

SELECT e.*,
ROW_NUMBER() over(PARTITION by dept_name) as rn
from employee e;


--- Fetch the first 2 employees from each department to join the company
select * from (
SELECT e.*,
ROW_NUMBER() over(PARTITION by dept_name order by emp_id) as rn
from employee e) X
where x.rn<3;


--- Fetch top 3 employees in each department earning the max salary
SELECT * from ( 
SELECT e.*,
rank() over(PARTITION BY dept_name order by salary desc) as rnk
from employee e) X
where x.rnk<4;



SELECT e.*,
rank() over(PARTITION BY dept_name order by salary desc) as rnk,
dense_rank() over(PARTITION by dept_name order by salary desc) as dense_rnk,
row_number() over(PARTITION by dept_name order by salary desc) as rn
from employee e



---- Fetch a query to display if the salary of an employee is higher, lower or equal to previous employee
select e.*,
lag(salary) over(PARTITION by dept_name order by emp_ID) as prev_empl_sal,
lead(salary) over(PARTITION by dept_name order by emp_ID) as next_empl_sal from employee e;

select 
    e.*,
    lag(salary) over (partition by dept_name order by emp_ID) as prev_empl_sal,
    case 
        when e.salary > lag(salary) over (partition by dept_name order by emp_ID) then 'Higher than previous salary'
        when e.salary < lag(salary) over (partition by dept_name order by emp_ID) then 'Lower than previous salary'
        when e.salary = lag(salary) over (partition by dept_name order by emp_ID) then 'Same as the previous salary'
    end as sal_range
from 
    employee e;


--- FIRST VALUE
-- Script to create the Product table and load data into it.

DROP TABLE product;
CREATE TABLE product
( 
    product_category varchar(255),
    brand varchar(255),
    product_name varchar(255),
    price int
);

INSERT INTO product VALUES
('Phone', 'Apple', 'iPhone 12 Pro Max', 1300),
('Phone', 'Apple', 'iPhone 12 Pro', 1100),
('Phone', 'Apple', 'iPhone 12', 1000),
('Phone', 'Samsung', 'Galaxy Z Fold 3', 1800),
('Phone', 'Samsung', 'Galaxy Z Flip 3', 1000),
('Phone', 'Samsung', 'Galaxy Note 20', 1200),
('Phone', 'Samsung', 'Galaxy S21', 1000),
('Phone', 'OnePlus', 'OnePlus Nord', 300),
('Phone', 'OnePlus', 'OnePlus 9', 800),
('Phone', 'Google', 'Pixel 5', 600),
('Laptop', 'Apple', 'MacBook Pro 13', 2000),
('Laptop', 'Apple', 'MacBook Air', 1200),
('Laptop', 'Microsoft', 'Surface Laptop 4', 2100),
('Laptop', 'Dell', 'XPS 13', 2000),
('Laptop', 'Dell', 'XPS 15', 2300),
('Laptop', 'Dell', 'XPS 17', 2500),
('Earphone', 'Apple', 'AirPods Pro', 280),
('Earphone', 'Samsung', 'Galaxy Buds Pro', 220),
('Earphone', 'Samsung', 'Galaxy Buds Live', 170),
('Earphone', 'Sony', 'WF-1000XM4', 250),
('Headphone', 'Sony', 'WH-1000XM4', 400),
('Headphone', 'Apple', 'AirPods Max', 550),
('Headphone', 'Microsoft', 'Surface Headphones 2', 250),
('Smartwatch', 'Apple', 'Apple Watch Series 6', 1000),
('Smartwatch', 'Apple', 'Apple Watch SE', 400),
('Smartwatch', 'Samsung', 'Galaxy Watch 4', 600),
('Smartwatch', 'OnePlus', 'OnePlus Watch', 220);
COMMIT;




-- All the SQL Queries written during the video

select * from product;


--- write query to display the most expensive product under each category (corresponding to each record)

select *,
first_value(product_name) over (PARTITION BY product_category order by price desc) as most_exp_product
from product;




--- write query to display the least expensive product under each category (corresponding to each record)

select *,
first_value(product_name) 
over (PARTITION BY product_category order by price desc) 
as most_exp_product,
last_value(product_name) 
over (PARTITION BY product_category order by price desc
range BETWEEN UNBOUNDED PRECEDING and CURRENT ROW)
as default_least_exp_product,
last_value(product_name) 
over (PARTITION BY product_category order by price desc
range BETWEEN UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING)
as least_exp_product
from product;


--- you can use range or row or range between 2 preceding and 2 following
---- Alternate way of writing the Window Clause
select *,
first_value(product_name) 
over w
as most_exp_product,
last_value(product_name) 
over w
as default_least_exp_product
from product
WINDOW w as (PARTITION BY product_category order by price desc
range BETWEEN UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING);


--- Nth Value
--- Writee a query to display the second most expensive product under each category

select *,
first_value(product_name) 
over w
as most_exp_product,
last_value(product_name) 
over w
as least_exp_product,
nth_value(product_name,2) over w as second_most_exp_product
from product
WINDOW w as (PARTITION BY product_category order by price desc
range BETWEEN UNBOUNDED PRECEDING and UNBOUNDED FOLLOWING);


--- NTILE
--- Write a query to segregate all the expensive phones, midrange phones and the cheaper phones

SELECT *,
ntile(3) over (order by price desc) as buckets
from Product
where product_category='Phone';


select product_name,
CASE when x.buckets=1 then 'Expensive'
when x.buckets=2 then 'Mid Range'
when x.buckets=3 then 'Cheaper' END phone_category
from (
    SELECT *,
ntile(3) over (order by price desc) as buckets
from Product
where product_category='Phone'
)x;


--- CUME_DIST (Cumulative Distribution)
/* Value ---> 1  <= CUME_DIST >0 */
/* Formula = Current Row no (or Row no with value same as current row) / Total no of rows */
--- Query to fetch all the products which are constituting the first 30% of the data in products table based on the price

SELECT PRODUCT_NAME,
(CUME_DIST_PERCENTAGE||'%') AS CUME_DIST_PERCENTAGE 
from (
select * ,
cume_dist() over(order by price desc) as cume_distribution,
round(cume_dist() over(order by price desc):: NUMERIC *100,2) as CUME_DIST_PERCENTAGE
from product) X
WHERE x.CUME_DIST_PERCENTAGE<=30;


--- PERCENT_RANK
/* Value ---> 1  <= PERCENT_RANK >0 */
/* Formula = Current Row no -1 / Total no of rows -1*/
--- Query to identify how much percentage more expensive is 'Galaxy Z Fold 3' when compared to all the products

SELECT *,
PERCENT_RANK() OVER(ORDER BY price) as percentage_rnk,
round(PERCENT_RANK() OVER(ORDER BY price) :: numeric *100,2) as percentage_rnk
from product;