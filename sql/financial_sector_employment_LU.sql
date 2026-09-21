---------------------------------------------------------------------------------------------------------------------------------
-- Luxembourg Financial Sector Employment Analysis
-- Author: Hakim El Azzouzi
---------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------------------------
-- 1. Exploring Data :-----------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
-- 1.1. Exploring Data of Financial sector employment table :---------------------------

-- Preview the raw table : Financial sector employment table

SELECT *
FROM [PortfolioProject].[dbo].[financial_sector_employment_by_segment]

-- how many rows do we have?

SELECT COUNT(*) AS total_rows
FROM [PortfolioProject].[dbo].[financial_sector_employment_by_segment]

-- What segments exist?

SELECT DISTINCT Specification, Specification2
FROM [PortfolioProject].[dbo].[financial_sector_employment_by_segment]
ORDER BY Specification ASC

-- What employment categories exist within each segment?

SELECT DISTINCT Employment, Employment2
FROM [PortfolioProject].[dbo].[financial_sector_employment_by_segment]
ORDER BY Employment ASC

-- What years are covered?

SELECT MIN(TIME_PERIOD) AS first_year, MAX(TIME_PERIOD) AS last_year
FROM [PortfolioProject].[dbo].[financial_sector_employment_by_segment]

-- Basic statistics on headcount (MIN, MAX, AVG)

SELECT
	MIN(CAST(OBS_VALUE AS INTEGER)) AS min_headcount,
	MAX(CAST(OBS_VALUE AS INTEGER)) AS max_headcount,
	AVG(CAST(OBS_VALUE AS INTEGER)) AS avg_headcount
FROM [PortfolioProject].[dbo].[financial_sector_employment_by_segment]
WHERE Employment2 = 'TOTAL'
	AND OBS_VALUE <> '';

-- Same statistics, but broken down per segment

SELECT
	Specification,
	MIN(CAST(OBS_VALUE AS INTEGER)) AS min_headcount,
	MAX(CAST(OBS_VALUE AS INTEGER)) AS max_headcount,
	AVG(CAST(OBS_VALUE AS INTEGER)) AS avg_headcount
FROM [PortfolioProject].[dbo].[financial_sector_employment_by_segment]
WHERE Employment2 = 'TOTAL'
	AND OBS_VALUE <> ''
GROUP BY Specification;

-- 1.2. Exploring Data of Total Payroll Employment by Activity Table :-------------------------------

--  Preview the baseline table : Total Payroll Employment by Activity

SELECT *
FROM PortfolioProject.dbo.total_payroll_employment_by_activity

-- Confirming the ACTIVITY codes available

SELECT DISTINCT ACTIVITY, Economic_activity_NACE_Rev_2
FROM PortfolioProject.dbo.total_payroll_employment_by_activity
ORDER BY ACTIVITY

-- 1.3. Exploring Data of the 2 optional demographic tables : ----------------------------------------------------

-- Preview the raw table : Employment Percentage by Activity Education

SELECT TOP 10 * FROM PortfolioProject.dbo.employment_pct_by_activity_education

-- Preview the raw table : Employment Percentage by Activity Nationality

SELECT TOP 100 * FROM PortfolioProject.dbo.employment_pct_by_activity_nationality


---------------------------------------------------------------------------------------------------------------------------------
--  2. Cleaning Data :-----------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

-- 2.1. Cleaning the Financial Sector Employment By Segment Table ----------------------------------------------------------------

-- Checking data quality flag column

SELECT OBS_STATUS, Observation_status, COUNT(*) AS how_many
FROM [PortfolioProject].[dbo].[financial_sector_employment_by_segment]
GROUP BY OBS_STATUS, Observation_status;

-- Building a clean, typed table -------------------------------------------------------------------

DROP TABLE IF EXISTS PortfolioProject.dbo.financial_sector_employment_by_segment_clean;

SELECT
	Specification2					AS segment,
	SPECIFICATION                   AS segment_code,
	Employment2						AS employment_category,
	EMPLOYMENT						AS employment_category_code,
	CAST(TIME_PERIOD AS INTEGER)	AS year,
	CASE WHEN OBS_VALUE = '' THEN NULL
		 ELSE CAST(OBS_VALUE AS INTEGER)
	END								AS headcount,
	Observation_status				AS status_flag,
	OBS_STATUS						AS status_flag_code
INTO PortfolioProject.dbo.financial_sector_employment_by_segment_clean
FROM PortfolioProject.dbo.financial_sector_employment_by_segment;

-- Verifying the clean table looks right

SELECT *
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean

-- Counting the missing values of headcount (OBS_Values)

SELECT COUNT(*) AS missing_values
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE headcount IS NULL;

-- Breaking down missing headcount values by employment category
-- to confirm the gaps are expected (newer categories / untracked nationality splits)
-- rather than a cleaning error

SELECT employment_category, employment_category_code, COUNT(*) AS missing_count
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE headcount IS NULL
GROUP BY employment_category, employment_category_code
ORDER BY missing_count DESC;

-- 2.2. Cleaning the Payroll Employment By Activity Table  ----------------------------------------------------------

-- 2.2.1 Cleaning the raw table to get : total_payroll_employment_finance_clean (finance sector only, raw not seasonally adjusted)

DROP TABLE IF EXISTS PortfolioProject.dbo.total_payroll_employment_finance_clean;

SELECT 
	Economic_activity_NACE_Rev_2			AS Economic_activity_NACE,
	LEFT(TIME_PERIOD, 4)					AS year_text,
	TRY_CAST(LEFT(TIME_PERIOD, 4) AS INT)	AS year,         /* Using TRY_CAST instead of CAST to convert blank and */
	RIGHT(TIME_PERIOD, 2)					AS quarter,		/*	empty values in OBS_Value into NULL and avoiding the error CAST will throw*/
	TRY_CAST(OBS_VALUE AS INT)				AS headcount
INTO PortfolioProject.dbo.total_payroll_employment_finance_clean
FROM PortfolioProject.dbo.total_payroll_employment_by_activity
WHERE ACTIVITY = 'K'
	AND ADJUSTMENT = 0;

-- 2.2.2 Cleaning the raw table to get : total_payroll_employment_national_clean (whole Luxembourg country, all sectors)

DROP TABLE IF EXISTS PortfolioProject.dbo.total_payroll_employment_national_clean;

SELECT
    Economic_activity_NACE_Rev_2       AS Economic_activity_NACE,
    LEFT(TIME_PERIOD, 4)               AS year_text,
    TRY_CAST(LEFT(TIME_PERIOD, 4) AS INT) AS year,
    RIGHT(TIME_PERIOD, 2)              AS quarter,
    TRY_CAST(OBS_VALUE AS INT)         AS headcount
INTO PortfolioProject.dbo.total_payroll_employment_national_clean
FROM PortfolioProject.dbo.total_payroll_employment_by_activity
WHERE ACTIVITY = '_T'
  AND ADJUSTMENT = 0;

-- Verifying the clean baseline tables look right

-- Preview Raw Table :
SELECT * FROM PortfolioProject.dbo.total_payroll_employment_by_activity 

-- Preview Clean Table : total_payroll_employment_national_clean
SELECT * FROM PortfolioProject.dbo.total_payroll_employment_national_clean

-- Preview Clean Table : total_payroll_employment_finance_clean
SELECT * FROM PortfolioProject.dbo.total_payroll_employment_finance_clean

-- 2.3. Cleaning the education table (finance sector only) -----------------------------------------------------------------------------------------

DROP TABLE IF EXISTS PortfolioProject.dbo.education_finance_clean;

SELECT
	Economic_activity_NACE_Rev_2	AS economic_activity,
	Educational_level				AS education_level,
	EDUC_LEVEL						AS education_level_code,
	TRY_CAST(TIME_PERIOD AS INT)	AS year,
	TRY_CAST(OBS_VALUE   AS FLOAT)	AS percentage_of_branch
INTO PortfolioProject.dbo.education_finance_clean
FROM PortfolioProject.dbo.employment_pct_by_activity_education
WHERE ACTIVITY = 'K'
	AND UNIT_MEASURE = 'PC_EMP_NACE';

-- Verifying the clean education table looks right
-- Preview Raw Table
SELECT * FROM PortfolioProject.dbo.employment_pct_by_activity_education
-- Preview Clean Table
SELECT * FROM PortfolioProject.dbo.education_finance_clean

-- 2.4. Cleaning the nationality table (finance sector only) -----------------------------------------------------------------------------------------

DROP TABLE IF EXISTS PortfolioProject.dbo.nationality_finance_clean;

SELECT
	Place_of_residence,
	RESIDENCE							AS residence_code,
	TRY_CAST(TIME_PERIOD AS INT)		AS year,
	TRY_CAST(OBS_VALUE AS FLOAT)		AS pct_of_branch
INTO PortfolioProject.dbo.nationality_finance_clean
FROM PortfolioProject.dbo.employment_pct_by_activity_nationality
WHERE ACTIVITY = 'K'
	AND UNIT_MEASURE = 'PC_EMP_NACE';

-- Verifying the clean nationality table looks right
-- Preview Raw Table
SELECT TOP 100 * FROM PortfolioProject.dbo.employment_pct_by_activity_nationality
-- Preview Clean Table
SELECT * FROM PortfolioProject.dbo.nationality_finance_clean


------------------------------------------------------------------------------------------------------------
-- 3. Main Questions: --------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------

-- 3.1. How has total financial-sector headcount changed year by year?

SELECT
	year,
	SUM(headcount) AS total_sector_headcount
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE employment_category = 'TOTAL'
GROUP BY year
ORDER BY year;

-- 3.2. How is headcount split across banks, PSF, management companies, and investment fund managers,
--      and has that mix shifted over time?

-- 3.2.1. Which segment is largest on average, and how much does it vary?

SELECT
    segment,
    MIN(headcount) AS min_headcount,
    MAX(headcount) AS max_headcount,
    AVG(headcount) AS avg_headcount
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE employment_category = 'TOTAL'
GROUP BY segment
ORDER BY avg_headcount DESC;

-- 3.2.2. What percentage of the total does each segment represent each year, and has that share shifted over time?

SELECT
	year,
	segment,
	headcount,
	SUM(headcount) OVER (PARTITION BY year) AS year_total,
	CAST(headcount AS FLOAT) 
		/ SUM(headcount) OVER (PARTITION BY year) * 100 AS pct_of_year_total
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE employment_category = 'TOTAL'
ORDER BY year, segment;

-- 3.3. Which sub-segment (banks, PSF, management companies) is growing fastest, and which is flat or shrinking?
--      Year-over-year growth per segment

SELECT
	segment,
	year,
	headcount,
	LAG(headcount) OVER (PARTITION BY segment ORDER BY year) AS previous_year_headcount,
	headcount - LAG(headcount) OVER (PARTITION BY segment ORDER BY year) AS year_over_year_change,
	CAST(headcount - LAG(headcount) OVER (PARTITION BY segment ORDER BY year) AS FLOAT)
		/ NULLIF(LAG(headcount) OVER (PARTITION BY segment ORDER BY year), 0)
		* 100 AS year_over_year_pct_change
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE employment_category = 'TOTAL'
ORDER BY segment, year;

-- 3.4. Does financial-sector employment growth track differently from overall national salaried employment?
-- Checking is Finance bigger or smaller slice of the economy over time
WITH finance_sector_annual AS (
	SELECT year, SUM(headcount) AS total_finance_sector_headcount
	FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
	WHERE employment_category = 'TOTAL'
	GROUP BY year
	),
national_employment_annual AS (
	SELECT year, AVG(headcount) AS avg_national_quarterly_headcount
	FROM PortfolioProject.dbo.total_payroll_employment_national_clean
	GROUP BY year
	)
SELECT
	f.year,
	f.total_finance_sector_headcount,
	n.avg_national_quarterly_headcount,
	-- Finance sector's share of national employment each year -
	-- this is what actually answers "does it track differently"
	CAST(f.total_finance_sector_headcount AS FLOAT)
		/ n.avg_national_quarterly_headcount * 100 AS finance_pct_of_national
FROM finance_sector_annual f
JOIN national_employment_annual n ON f.year = n.year
ORDER BY f.year;

-- 3.4 (continued) - Growth rate comparison, side by side
--                   Same idea as above, but instead of "what share is finance", this shows
--                   "in each given year, did finance grow faster or slower than the national rate"
 
WITH finance_sector_annual AS (
	SELECT year, SUM(headcount) AS total_finance_sector_headcount
	FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
	WHERE employment_category = 'TOTAL'
	GROUP BY year
	),
national_employment_annual AS (
	SELECT year, AVG(headcount) AS avg_national_quarterly_headcount
	FROM PortfolioProject.dbo.total_payroll_employment_national_clean
	GROUP BY year
	),
combined AS (
	SELECT f.year, f.total_finance_sector_headcount, n.avg_national_quarterly_headcount
	FROM finance_sector_annual f
	JOIN national_employment_annual n ON f.year = n.year
	)
SELECT
	year,
	total_finance_sector_headcount,
	ROUND(
		CAST(total_finance_sector_headcount
			- LAG(total_finance_sector_headcount) OVER (ORDER BY year) AS FLOAT)
		/ NULLIF(LAG(total_finance_sector_headcount) OVER (ORDER BY year), 0) * 100, 2
	) AS finance_yoy_pct_change,
	avg_national_quarterly_headcount,
	ROUND(
		CAST(avg_national_quarterly_headcount
			- LAG(avg_national_quarterly_headcount) OVER (ORDER BY year) AS FLOAT)
		/ NULLIF(LAG(avg_national_quarterly_headcount) OVER (ORDER BY year), 0) * 100, 2
	) AS national_yoy_pct_change
FROM combined
ORDER BY year;
-- 3.5. Are there demographic signals worth flagging (education level, nationality mix)?

-- 3.5.1. Education level mix in the financial sector, over time

SELECT year, education_level, education_level_code, percentage_of_branch
FROM PortfolioProject.dbo.education_finance_clean
WHERE education_level_code <> '_T'
ORDER BY year, education_level_code;

-- 3.5.2. Luxembourgers vs. foreign residents in the financial sector, over time

SELECT year, Place_of_residence, residence_code, pct_of_branch
FROM PortfolioProject.dbo.nationality_finance_clean
WHERE residence_code IN ('LU', 'RES_FOR_ALL')
ORDER BY year, residence_code;

-- 3.6. Are there visible inflection points in the time series worth calling out?
--      (biggest year-over-year swings, up or down, re-sorted from 3.3)

SELECT segment, year, headcount, year_over_year_change, year_over_year_pct_change
FROM (
	SELECT
		segment, year, headcount,
		headcount - LAG(headcount) OVER (PARTITION BY segment ORDER BY year) AS year_over_year_change,
		CAST(headcount - LAG(headcount) OVER (PARTITION BY segment ORDER BY year) AS FLOAT)
			/ NULLIF(LAG(headcount) OVER (PARTITION BY segment ORDER BY year), 0)
			* 100 AS year_over_year_pct_change
	FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
	WHERE employment_category = 'TOTAL'
) t
WHERE year_over_year_change IS NOT NULL
ORDER BY ABS(year_over_year_pct_change) DESC;

-- 3.7. OPTIONAL - Combined view: Management companies + Investment fund managers
--      (the two never overlap in time - Management companies data stops in 2018, Investment fund
--      managers starts in 2019 - suggesting a possible STATEC reclassification. No footnote confirms
--      this explicitly, so this combined view is presented as a secondary/inferred chart only,
--      not the primary segment breakdown.)

SELECT
	year,
	SUM(headcount) AS management_and_fund_managers_combined
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE segment IN ('Management companies', 'Investment fund managers')
	AND employment_category = 'TOTAL'
GROUP BY year
ORDER BY year;
