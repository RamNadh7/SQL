
CREATE TABLE Employee
(
    employee_id INT ,
    employee_name VARCHAR(50),
    department_id INT,
    position VARCHAR(50),
    salary DECIMAL(10, 2)
);


INSERT INTO Employee
    (employee_id, employee_name, department_id, position, salary)
VALUES
    (1, 'Alice Johnson', 101, 'Software Engineer', 70000),
    (2, 'Bob Smith', 102, 'Data Scientist', 80000),
    (3, 'Carol White', 103, 'Project Manager', 75000),
    (4, 'David Brown', 104, 'Quality Assurance', 60000),
    (5, 'Eva Green', 105, 'HR Specialist', 55000),
    (6, 'Frank Martin', 101, 'Software Engineer', 70000),
    (3, 'Carol White', 103, 'Project Manager', 75000),
    (4, 'David Brown', 104, 'Quality Assurance', 60000)

select *
from employee;


--- Remove duplicate values from employee table
select distinct *
from Employee;


--- Write a query to find out duplicate values from employee
with
    cte
    as
    (
        select *,
            ROW_NUMBER() over (partition by employee_id order by employee_id) as rn
        from employee
    )
select *
from cte
where rn>1


--- Write a query to find out highest earning employee based on each position
SELECT max(salary), position
from Employee
group by position;

---- write a query to get top 3 highest earning employee
select top 3
    *
from Employee
ORDER by salary desc;


with
    cte
    as
    
    (
        select distinct *
        from employee
    )
select top 3
    *
from cte
order by salary DESC


--- write a query to get the top 3 lowest earning employee
with
    cte
    as
    
    (
        select distinct *
        from employee
    )
select top 3
    *
from cte
order by salary ASC;



-------------------------------------------------------------------------------------

CREATE TABLE Emp
(
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    location VARCHAR(50)
);

INSERT INTO Emp
    (employee_id, employee_name, department, salary, location)
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

select *
from emp
