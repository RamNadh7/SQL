/* ##########################################################################
   <<<<>>>> Scenario 1: Data duplicated based on SOME of the columns <<<<>>>>
   ########################################################################## */

-- Requirement: Delete duplicate data from cars table. Duplicate record is identified based on the model and brand name.

drop table if exists cars;
create table if not exists cars
(
    id      int,
    model   varchar(50),
    brand   varchar(40),
    color   varchar(30),
    make    int
);
insert into cars values (1, 'Model S', 'Tesla', 'Blue', 2018);
insert into cars values (2, 'EQS', 'Mercedes-Benz', 'Black', 2022);
insert into cars values (3, 'iX', 'BMW', 'Red', 2022);
insert into cars values (4, 'Ioniq 5', 'Hyundai', 'White', 2021);
insert into cars values (5, 'Model S', 'Tesla', 'Silver', 2018);
insert into cars values (6, 'Ioniq 5', 'Hyundai', 'Green', 2021);

select * from cars
order by model, brand;

---- using unique identifier

delete from cars 
where id in (
select max(id)
from cars
group by model, brand
having count(*)>1)


---- Using SELF JOIN
delete from cars where id in
(
select c2.id
from cars c1
join cars c2 on
c1.model=c2.model and c1.brand=c2.brand
where c1.id<c2.id)


---- Window FUNCTION
delete from cars where id in (
select id from (
select * 
, row_number() over (PARTITION by model,brand) as rn
from cars ) x
where x.rn>1 ) ;

---- or
with cte as (
    select *,
           row_number() over (partition by model, brand) as rn
    from cars
)
delete from cars
where id in (
    select id
    from cte
    where rn > 1
);


---- Using MIN function. This deletes even multiple duplicate records
delete from cars
where id not in (
SELECT min(id)
from Cars 
group by model,brand);


--- Using Backup table - not work in production environment
create table cars_bkp
as select * from cars where 1=2;


insert into cars_bkp 
select *
from cars
where id IN (
    select min(id)
    from cars 
    GROUP by model,brand
)

select * from cars_bkp;

drop table cars;

alter table cars_bkp rename to cars;

select * from cars;


--- Using backup table without dropping the original table

create table cars_bkp
as select * from cars where 1=2;


insert into cars_bkp 
select *
from cars
where id IN (
    select min(id)
    from cars 
    GROUP by model,brand
)

select * from cars_bkp;

truncate table cars;

insert into cars
select * from cars_bkp;

select * from cars;

drop table cars_bkp;


/* ##########################################################################
   <<<<>>>> Scenario 2: Data duplicated based on ALL of the columns <<<<>>>>
   ########################################################################## */

-- Requirement: Delete duplicate entry for a car in the CARS table.

drop table if exists cars;
create table if not exists cars
(
    id      int,
    model   varchar(50),
    brand   varchar(40),
    color   varchar(30),
    make    int
);
insert into cars values (1, 'Model S', 'Tesla', 'Blue', 2018);
insert into cars values (2, 'EQS', 'Mercedes-Benz', 'Black', 2022);
insert into cars values (3, 'iX', 'BMW', 'Red', 2022);
insert into cars values (4, 'Ioniq 5', 'Hyundai', 'White', 2021);
insert into cars values (1, 'Model S', 'Tesla', 'Blue', 2018);
insert into cars values (4, 'Ioniq 5', 'Hyundai', 'White', 2021);

select * from cars;

--- Delete using CTID -- only in postgresql
--- ROWID in oracle
select *,ctid from cars


delete from cars 
where ctid in 
(select max(ctid)
from cars group by model,brand
having count(*)>1)

--- By creating a temporary unique id column
alter table cars 
add column row_num int generated always as identity;

select * from cars;

delete from cars 
where row_num in 
(select max(row_num)
from cars group by model,brand
having count(*)>1)

alter table cars drop column row_num;


---- By creating a backup table
create table cars_bkp AS
select DISTINCT * from cars;

select * from cars_bkp;

drop table cars;

alter table cars_bkp rename to cars;

select * from cars;


--- By creating the backup table without creating the original table
create table cars_bkp AS
select DISTINCT * from cars;

select * from cars_bkp;

TRUNCATE table cars;


insert into cars select * from cars_bkp;

drop table cars_bkp;

select * from cars;