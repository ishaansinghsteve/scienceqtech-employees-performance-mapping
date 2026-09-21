/* 1. Create a database named employee, then import data_science_team.csv, proj_table.csv, and emp_record_table.csv 
into the employee database from the given resources. */

CREATE DATABASE employee;

USE employee;

-- Import all three data tables using the import wizard.

-- We will now build relationships for the ERD.

ALTER TABLE emp_record_table
MODIFY EMP_ID VARCHAR(20) NOT NULL;

ALTER TABLE emp_record_table
ADD PRIMARY KEY (EMP_ID);

ALTER TABLE emp_record_table
MODIFY PROJ_ID VARCHAR(20);

ALTER TABLE proj_table
MODIFY PROJECT_ID VARCHAR(20) NOT NULL;

ALTER TABLE proj_table
ADD PRIMARY KEY (PROJECT_ID);

ALTER TABLE data_science_team
MODIFY EMP_ID VARCHAR(20) NOT NULL;

UPDATE emp_record_table
SET PROJ_ID = TRIM(PROJ_ID);

UPDATE proj_table
SET PROJECT_ID = TRIM(PROJECT_ID);

UPDATE emp_record_table
SET PROJ_ID = NULL
WHERE PROJ_ID = 'NA';

ALTER TABLE emp_record_table
ADD CONSTRAINT fk_employee_project
FOREIGN KEY (PROJ_ID)
REFERENCES proj_table (PROJECT_ID);

ALTER TABLE data_science_team
ADD CONSTRAINT fk_team_employee
FOREIGN KEY (EMP_ID)
REFERENCES emp_record_table (EMP_ID);

ALTER TABLE data_science_team
ADD CONSTRAINT uq_team_employee UNIQUE (EMP_ID);

/* 2. Write a query to fetch EMP_ID, FIRST_NAME, LAST_NAME, GENDER, and DEPARTMENT from the employee record table, 
and make a list of employees and details of their department. */

SELECT 
EMP_ID,
FIRST_NAME,
LAST_NAME,
GENDER,
DEPT
FROM emp_record_table;

/* 3. Write a query to fetch EMP_ID, FIRST_NAME, LAST_NAME, GENDER, DEPARTMENT, and EMP_RATING if the EMP_RATING is:
● less than two
● between two and four
● greater than four */

SELECT 
EMP_ID,
FIRST_NAME,
LAST_NAME,
GENDER,
DEPT,
EMP_RATING
FROM emp_record_table
WHERE EMP_RATING<2 OR (EMP_RATING BETWEEN 2 AND 4) OR EMP_RATING>4;

/* 4. Write a SQL query to retrieve the employee ID, first name, role, and department of employees who hold leadership 
positions (Manager, President, or CEO). */

SELECT 
EMP_ID,
FIRST_NAME,
ROLE,
DEPT
FROM emp_record_table
WHERE ROLE IN ("Manager", "CEO", "President");

/* 5. Write a query to list employee details, including EMP_ID, FIRST_NAME, LAST_NAME, ROLE, DEPARTMENT, and EMP_RATING, grouped 
by department. Also include the respective employee rating along with the max emp rating for the department. */

SELECT
EMP_ID,
FIRST_NAME,
LAST_NAME,
ROLE,
DEPT,
EMP_RATING,
MAX(EMP_RATING) OVER (PARTITION BY DEPT) AS MAX_DEPT_RATING
FROM emp_record_table;

/* 6. Write a query to find the minimum and maximum salary for employees grouped by their role, 
using data from the employee record table. */

SELECT 
ROLE,
MIN(SALARY) AS MIN_ROLE_SALARY,
MAX(SALARY) AS MAX_ROLE_SALARY
FROM emp_record_table
GROUP BY ROLE;

/* 7. Write a query to assign a rank to each employee based on their years of experience, 
using data from the employee record table. */

SELECT
EMP_ID,
FIRST_NAME,
LAST_NAME,
DENSE_RANK() OVER (ORDER BY EXP DESC) AS EXP_RANK
FROM emp_record_table;

/* 8. Write a query to create a view that displays employees in various countries whose 
salary is more than six thousand, using data from the employee record table. */

CREATE VIEW view_1 AS SELECT 
EMP_ID,
FIRST_NAME,
LAST_NAME,
SALARY,
COUNTRY
FROM emp_record_table
WHERE SALARY>6000;

/* 9. Create an index to improve the cost and performance of the query to find the employee whose 
FIRST_NAME is Eric in the employee table, after checking the execution plan. */

EXPLAIN
SELECT *
FROM emp_record_table
WHERE FIRST_NAME = 'Eric';

CREATE INDEX idx_first_name
ON emp_record_table (FIRST_NAME(50));

/* 10. Write a query to calculate the average salary distribution based on the continent and country. 
Take data from the employee record table. */

SELECT 
CONTINENT,
COUNTRY,
AVG (SALARY) AS AVG_SALARY
FROM emp_record_table
GROUP BY CONTINENT, COUNTRY
ORDER BY CONTINENT, COUNTRY;

/* 11. Which departments have the most experienced data-science employees on average? */

SELECT 
DEPT,
ROUND(AVG(EXP), 2) AS AVG_EXP,
MIN(EXP) AS MIN_EXP,
MAX(EXP) AS MAX_EXP,
COUNT(EMP_ID) AS TOTAL_EMP
FROM data_science_team
GROUP BY DEPT
ORDER BY AVG_EXP DESC;

/* 12. Write a query to classify data science team employees into Junior, Middle-Level, and Senior categories based 
on their years of experience, while displaying their employee details. */

SELECT 
*,
CASE 
WHEN EXP BETWEEN 0 and 3 THEN "Junior"
WHEN EXP BETWEEN 4 and 7 THEN "Middle"
ELSE "Senior" 
END AS EXP_LEVEL
FROM data_science_team
ORDER BY EXP DESC;

/* 13. Using a CTE, calculate the duration of each project in days. Then, using a subquery, calculate the average project duration and 
display the projects whose duration is greater than the overall average. */

-- We will first fix date columns in proj_table.

ALTER TABLE proj_table
ADD COLUMN START_DATE DATE;

ALTER TABLE proj_table
RENAME COLUMN `START _DATE` TO X;

UPDATE proj_table
SET `X` = REPLACE(`X`, '/', '-');

UPDATE proj_table
SET START_DATE = STR_TO_DATE(X, '%m-%d-%Y');

ALTER TABLE proj_table
DROP COLUMN X;

ALTER TABLE proj_table
ADD COLUMN CLOSURE_DATE_NEW DATE;

UPDATE proj_table
SET CLOSURE_DATE_NEW = STR_TO_DATE(CLOSURE_DATE, '%m/%d/%Y');

ALTER TABLE proj_table
DROP COLUMN CLOSURE_DATE;

ALTER TABLE proj_table
CHANGE CLOSURE_DATE_NEW CLOSURE_DATE DATE;

WITH project_duration AS (
    SELECT
        *,
        DATEDIFF(CLOSURE_DATE, START_DATE) AS DURATION_DAYS
    FROM proj_table
)
SELECT *
FROM project_duration
WHERE DURATION_DAYS > (
    SELECT AVG(DURATION_DAYS)
    FROM project_duration
)
ORDER BY DURATION_DAYS DESC;

/* 14. Using employee records and Data Science team records, display all employees 
and indicate whether each employee belongs to the Data Science team. */

SELECT 
e.EMP_ID,
e.FIRST_NAME,
e.LAST_NAME,
e.ROLE,
e.DEPT,
CASE 
WHEN d.EMP_ID IS NULL THEN 'No'
ELSE 'Yes'
END AS IN_DATA_SCIENCE_TEAM
FROM emp_record_table AS e
LEFT JOIN data_science_team AS d
ON e.EMP_ID = d.EMP_ID;

/* 15. Using emp_record_table and proj_table, calculate the number of employees assigned to 
each project. Display the project ID, project name, and employee count. */

SELECT 
P.PROJECT_ID,
P.PROJ_NAME,
COUNT(e.EMP_ID) AS EMP_COUNT
FROM proj_table AS p
LEFT JOIN emp_record_table AS e
ON p.PROJECT_ID = e.PROJ_ID
GROUP BY PROJECT_ID, PROJ_NAME;

/* 16. Using emp_record_table and proj_table, calculate the number of employees working in each 
project domain. Display the project domain and employee count. */

SELECT 
P.DOMAIN,
COUNT(e.EMP_ID) AS EMP_COUNT
FROM proj_table AS p
LEFT JOIN emp_record_table AS e
ON p.PROJECT_ID = e.PROJ_ID
GROUP BY DOMAIN;






