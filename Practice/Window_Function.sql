
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