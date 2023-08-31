---Data cleaning and pre-processing ---

--1) Changing the name of the column to 'Emp_id'---

EXEC sp_rename '[ProjectDB].[dbo].[Human Resources-1].id', 'Emp_id';


--2) Changing the datatype of column 'birthdate' from VARCHAR to DATE-------

ALTER TABLE [ProjectDB].[dbo].[Human Resources-1]
ALTER COLUMN birthdate DATE;


--3) Standardizing the date format of 'birthdate' column to 'yyyy-mm-dd'-----

UPDATE [ProjectDB].[dbo].[Human Resources-1]
SET birthdate = CASE
 WHEN birthdate LIKE '%/%' THEN CONVERT(date, birthdate, 23)
 WHEN birthdate LIKE '%-%' THEN CONVERT(date, birthdate, 23)
 ELSE NULL
END;


--4) Changing the datatype of column 'hire_date' from VARCHAR to DATE-------

ALTER TABLE [ProjectDB].[dbo].[Human Resources-1]
ALTER COLUMN hire_date DATE;


---5) Standardizing the date format of 'hire_date' column to 'yyyy-mm-dd'-----

UPDATE [ProjectDB].[dbo].[Human Resources-1]
SET hire_date = CASE
 WHEN hire_date LIKE '%/%' THEN CONVERT(date, hire_date, 23)
 WHEN hire_date LIKE '%-%' THEN CONVERT(date, hire_date, 23)
 ELSE NULL
END;


---6) Create a new column for 'termdate' called 'termdate1'------------

ALTER TABLE [ProjectDB].[dbo].[Human Resources-1]
ADD termdate1 DATE;


---7) To extract the date character from original column 'termdate'----------

UPDATE [ProjectDB].[dbo].[Human Resources-1]
SET termdate1 = SUBSTRING(termdate, 0, 11)
WHERE termdate IS NOT NULL;

--- 8) Created a new column called 'age' to get present age of the employees----------

ALTER TABLE [ProjectDB].[dbo].[Human Resources-1]
ADD age INT;

---9) Update the new column 'age' with present age--------

UPDATE [ProjectDB].[dbo].[Human Resources-1]
SET age = datediff(year,birthdate, GETDATE())

SELECT *
FROM [ProjectDB].[dbo].[Human Resources-1];

---Data analysis---

--1) What is the gender breakdown of employees in the company?--------------------
SELECT gender, count(*) as count
FROM [ProjectDB].[dbo].[Human Resources-1]
GROUP BY gender;

--2) What is the race/ethnicity breakdown of employees in the company?------------

SELECT race, count(*) as count
FROM [ProjectDB].[dbo].[Human Resources-1]
GROUP BY race
ORDER by count DESC;

--3)What is the age distribution of employees in the company?--------

SELECT 
min(age) as Youngest,
max(age) as Oldest
FROM [ProjectDB].[dbo].[Human Resources-1];

SELECT 
  CASE
	WHEN age >= 18 and age <= 24 THEN '18-24'
	WHEN age >=25 AND age <= 34 THEN '25-34'
	WHEN age >= 35 AND age <= 44 THEN '35-44'
	WHEN age >= 45 AND age <= 54 THEN '44-54'
	WHEN age >= 55 AND age <= 64 THEN '55-64'
	ELSE '65+'
  END AS age_gr,
  count(*) AS count1
FROM [ProjectDB].[dbo].[Human Resources-1]  
GROUP BY CASE
	WHEN age >= 18 and age <= 24 THEN '18-24'
	WHEN age >=25 AND age <= 34 THEN '25-34'
	WHEN age >= 35 AND age <= 44 THEN '35-44'
	WHEN age >= 45 AND age <= 54 THEN '44-54'
	WHEN age >= 55 AND age <= 64 THEN '55-64'
	ELSE '65+'
  END 
ORDER BY age_gr

--- 3 a) What is the age distribution of employees in the company based on gender?
SELECT 
  CASE
	WHEN age >= 18 and age <= 24 THEN '18-24'
	WHEN age >=25 AND age <= 34 THEN '25-34'
	WHEN age >= 35 AND age <= 44 THEN '35-44'
	WHEN age >= 45 AND age <= 54 THEN '44-54'
	WHEN age >= 55 AND age <= 64 THEN '55-64'
	ELSE '65+'
  END AS age_gr,
  gender,
  count(*) AS count1
FROM [ProjectDB].[dbo].[Human Resources-1]  
GROUP BY CASE
	WHEN age >= 18 and age <= 24 THEN '18-24'
	WHEN age >=25 AND age <= 34 THEN '25-34'
	WHEN age >= 35 AND age <= 44 THEN '35-44'
	WHEN age >= 45 AND age <= 54 THEN '44-54'
	WHEN age >= 55 AND age <= 64 THEN '55-64'
	ELSE '65+'
  END, gender
ORDER BY age_gr

-- 4) How many employees work at headquarters vs remote locations?----

SELECT location, count(*) as count
FROM [ProjectDB].[dbo].[Human Resources-1]
GROUP BY location;

---5) What is the average length of employment for employees who have been terminated?---

SELECT ABS(AVG(DATEDIFF(day,termdate1, hire_date))/365) AS avg_length_employment
FROM [ProjectDB].[dbo].[Human Resources-1]
WHERE termdate1 <= GETDATE()

--6) How does the gender distribution vary across departments and job titles?----
SELECT department, gender, COUNT(*) AS count
FROM [ProjectDB].[dbo].[Human Resources-1]
GROUP BY department, gender
ORDER BY department

--- 7) What is the distribution of job titles across the company?----
SELECT jobtitle, count(*) as count
FROM [ProjectDB].[dbo].[Human Resources-1]
GROUP BY jobtitle
ORDER BY count DESC

---8) Which department has highest turnover rate?

SELECT department,
	   total_count, 
	   terminated_count,
	   CAST((CAST(terminated_count as decimal)/CAST(total_count AS decimal)) AS decimal(5,2)) AS termination_rate
FROM (SELECT department,
      count(*) AS total_count,
	  SUM(CASE WHEN termdate1 IS NOT NULL AND termdate1 <= GETDATE() THEN 1 ELSE 0 END) AS terminated_count
	  FROM [ProjectDB].[dbo].[Human Resources-1]
	  GROUP BY department
     ) AS subquery
ORDER BY termination_rate DESC

--- 9) What is the distribution of employees across locations by city and state?------------------------

SELECT location_state, count(*) AS count
FROM [ProjectDB].[dbo].[Human Resources-1]
WHERE termdate1 IS NOT NULL
GROUP BY location_state
ORDER BY count DESC

--- 10) How has the company's employee count changed over time based on hire and term dates?------------
SELECT year,
   hires,
   terminations,
   hires - terminations AS net_change,
   CAST((CAST((hires - terminations) AS decimal)/CAST(hires AS decimal)* 100) AS decimal(5,2)) AS net_change_percent
FROM(
    SELECT YEAR(hire_date) AS year,
	       count(*) AS hires,
		   SUM(CASE WHEN termdate1 IS NOT NULL AND termdate1 <= GETDATE() THEN 1 ELSE 0 END) AS terminations
	FROM [ProjectDB].[dbo].[Human Resources-1]
	GROUP BY YEAR(hire_date)
	) AS subquery
ORDER BY year ASC;

--- 11) What is the tenure distribution for each department?-----
SELECT department,
	   ROUND(AVG(DATEDIFF(day,hire_date, termdate1)/365),0) AS avg_tenure
FROM [ProjectDB].[dbo].[Human Resources-1]
WHERE termdate1 < = GETDATE() AND termdate1 IS NOT NULL
GROUP BY department;


















