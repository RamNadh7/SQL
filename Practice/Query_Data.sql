use MyDatabase;

---- DQL - Data Query language - Select
---- Retrieve all the records
select * from customers;

---- Retrieve name and country columns

 

----- Retrieve each customer name , country and score
select first_name,country,score from customers;

------ WHERE Clause - To filter the Data

select * from customers where score>500;

select first_name, country, score from customers
where score >500;

--- Retrieve customers with score not equal to 0
select * 
from customers 
where score!=0;

--- Retrieve customers from germany
select *
from customers
where country='Germany';

select first_name,
country
from customers
where country='Germany';


--- ORDER BY - Sort Your Data
--- select * from Table order by score [[DEFAULT/ASC] OR DESC]

--- Retrieve all customers and sort the results in highest score first
SELECT * FROM customers
ORDER BY score DESC;

--- Retrieve all customers and sort the results in Lowest score first
SELECT *
FROM customers
ORDER By score asc;

--- ORDER BY (Nested)
--- select * from table order by country asc, score desc

select * from customers order by country asc, score desc; 

--- Retrieve all customers and sort the results by the country and then by the highest score
select * from customers order by country ,score desc;


---- GROUP BY - Aggregate Your Data
--- Group BY - Combines rows with the same value, Aggregates a column
--- Total score by country
--- select country,sum(score) from table group by country

---- Find total score by each country
select country,sum(score) as total_score
from customers group by country;


select country,first_name,sum(score) as total_score
from customers group by country;  --- error


select country,first_name,sum(score) as total_score
from customers group by country,first_name;  

select country,sum(score) as total_score,count(id) as count
from customers group by country;


---- HAVING - Filter Aggregated Data
---- it filters the data after aggregation
---- can be used only with Group by
--- select country,sum(score) from table group by country having sum(score)>800

select country,sum(score) from customers
group by country having sum(score)>800; 


--- using where and having at same t  ime
select country,sum(score) from customers where score >400
group by country having sum(score)>800; 


--- Find the avg score for each country considering only customers with a score not equal to 0
--- and return only those country with an average greater than 430

select country,avg(score) from customers
where score !=0
group by country
having avg(score)>430;


--- DISTINCT -- Remove Duplicates (Repeated values)
--- each value appears only once
--- select distinct col from table

select distinct country from customers;

--- Note: don't use distinct unless its necessary, it can slow down your query

--- TOP --- Limit your Data
--- TOP(Limit) -- restrict no of rows returnd
--- select top 3 * from table

select top 3 * from customers;


select top 3 * from customers order by score desc;

select top 2 * from customers order by score asc;

select top 3 country from customers order by score desc;

select top 2 * from orders order by order_date desc;


/*
coding order

select                  --- Filter cols
DISTINCT                --- Filter Duplicates
TOP 2                   --- Filter result rows
col1,
col2
FROM table
WHERE col=10           --- Filter rows before aggregation
GROUP BY col1
HAVING sum(col2)>30        --- Filter rows after aggregation
ORDER BY col1 ASC

Execute order

FROM
WHERE
GROUP BY
HAVING
SELECT DISTINCT
ORDER BY
TOP 2


*/