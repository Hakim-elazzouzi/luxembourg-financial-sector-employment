-- View 1: Total sector headcount by year (Q1)

CREATE OR ALTER VIEW vw_total_headcount_trend AS
SELECT year, SUM(headcount) AS total_sector_headcount
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE employment_category = 'TOTAL'
GROUP BY year;
GO

-- View 2a: Average headcount by segment (Q2, part 1)
-- Which segment is largest on average, and how much does it vary?

CREATE OR ALTER VIEW vw_segment_avg_headcount AS
SELECT
	segment,
	MIN(headcount) AS min_headcount,
	MAX(headcount) AS max_headcount,
	AVG(headcount) AS avg_headcount
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE employment_category = 'TOTAL'
GROUP BY segment;
Go

-- View 2b: Segment share of yearly total (Q2, part 2)

CREATE OR ALTER VIEW vw_segment_share_by_year AS
SELECT
	year, segment, headcount,
	SUM(headcount) OVER (PARTITION BY year) AS year_total,
	CAST(headcount AS FLOAT)
		/ SUM(headcount) OVER (PARTITION BY year) * 100 AS pct_of_year_total
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE employment_category = 'TOTAL';
GO

-- View 3: Year-over-year growth per segment (Q3)

CREATE OR ALTER VIEW vw_segment_yoy_growth AS
SELECT
	segment, year, headcount,
	LAG(headcount) OVER (PARTITION BY segment ORDER BY year) AS previous_year_headcount,
	headcount - LAG(headcount) OVER (PARTITION BY segment ORDER BY year) AS year_over_year_change,
	CAST(headcount - LAG(headcount) OVER (PARTITION BY segment ORDER BY year) AS FLOAT)
		/ NULLIF(LAG(headcount) OVER (PARTITION BY segment ORDER BY year), 0)
		* 100 AS year_over_year_pct_change
FROM PortfolioProject.dbo.financial_sector_employment_by_segment_clean
WHERE employment_category = 'TOTAL';
GO

-- View 4: Finance vs. national employment, share + growth (Q4)

CREATE OR ALTER VIEW vw_finance_vs_national AS
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
	f.year, f.total_finance_sector_headcount, n.avg_national_quarterly_headcount,
	CAST(f.total_finance_sector_headcount AS FLOAT)
		/ n.avg_national_quarterly_headcount * 100 AS finance_pct_of_national,
	ROUND(CAST(f.total_finance_sector_headcount
		- LAG(f.total_finance_sector_headcount) OVER (ORDER BY f.year) AS FLOAT)
		/ NULLIF(LAG(f.total_finance_sector_headcount) OVER (ORDER BY f.year), 0) * 100, 2)
		AS finance_yoy_pct_change,
	ROUND(CAST(n.avg_national_quarterly_headcount
		- LAG(n.avg_national_quarterly_headcount) OVER (ORDER BY f.year) AS FLOAT)
		/ NULLIF(LAG(n.avg_national_quarterly_headcount) OVER (ORDER BY f.year), 0) * 100, 2)
		AS national_yoy_pct_change
FROM finance_sector_annual f
JOIN national_employment_annual n ON f.year = n.year;
Go

-- View 5: Education level mix (Q5.1)

CREATE OR ALTER VIEW vw_education_mix AS
SELECT year, education_level, education_level_code, percentage_of_branch
FROM PortfolioProject.dbo.education_finance_clean
WHERE education_level_code <> '_T';
GO
-- View 6: Nationality mix (Q5.2)

CREATE OR ALTER VIEW vw_nationality_mix AS
SELECT year, Place_of_residence, residence_code, pct_of_branch
FROM PortfolioProject.dbo.nationality_finance_clean
WHERE residence_code IN ('LU', 'RES_FOR_ALL');
GO

-- View 7: Inflection points (Q6)
CREATE OR ALTER VIEW vw_inflection_points AS
SELECT segment, year, headcount, year_over_year_change, year_over_year_pct_change
FROM vw_segment_yoy_growth
WHERE year_over_year_change IS NOT NULL;
GO
