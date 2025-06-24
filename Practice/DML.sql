--- INSERT
--- TO insert a records to table
--- match number of columns and values
--- columns and values must be in same order
/*
Syntax
INSERT INTO table_name(col1, col2, col3, ...)
VALUES (value1, value2, value3,...)
,(value1, value2, value3,...)
*/

INSERT INTO CUSTOMERS (ID, first_name, country, score)
VALUES (6,'Anna','USA',NULL),
        (7,'Sam',NULL,100);


select * from customers;

---- Insert using another table
 