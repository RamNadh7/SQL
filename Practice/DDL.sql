--- DDL -- Data Definition Language
--- Create a new able called persons with columns: id, person_name, birth_date, and phone

CREATE TABLE persons (
    id INT NOT NULL,  --- COLUMN_NAME DATA_TYPE COSTRAINT
    person_name VARCHAR(50) NOT NULL,
    birth_date DATE,
    phone VARCHAR(15) NOT NULL
    CONSTRAINT pk_persons PRIMARY KEY (id)
) 


select * from persons;


---- Alter
--- Add new column to table persons
Alter table persons
ADD email VARCHAR(50) NOT NULL

-- Remove the column phone from table
ALTER table persons
drop COLUMN phone;


--- DROP
--- Delete the table persons
DROP TABLE persons;
