/*
Select data to be used for project
*/

SELECT 
	[Location],
	[Date],
	TRY_CONVERT(DECIMAL(10,0),[total_cases]) [TotalCases],
	TRY_CONVERT(DECIMAL(10,0),[new_cases]) [NewCases],
	TRY_CONVERT(DECIMAL(10,0),[total_deaths]) [TotalDeaths],
	TRY_CONVERT(DECIMAL(10,0),[population]) [Population]
FROM
	PortfolioProjects..CovidDeaths
ORDER BY
	1,2

/*
--Alter data types to help with subsequent calculated fields
ALTER TABLE CovidDeaths 
ALTER COLUMN [total_deaths] DECIMAL(10,2)
*/

-- 1. Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying after contracting covid
--USA
WITH cte1 AS (SELECT 
	[Location],
	[Date],
	TRY_CONVERT(DECIMAL(10,2),[total_cases]) [TotalCases],
	TRY_CONVERT(DECIMAL(10,2),[total_deaths]) [TotalDeaths]
	--CASE
	--	WHEN [total_cases] = '' OR [total_deaths] = '' THEN NULL 
	--	ELSE TRY_CAST([total_deaths] AS FLOAT)/TRY_CAST([total_cases] AS FLOAT)*100 
	--	END [DeathRate]
FROM
	PortfolioProjects..CovidDeaths
WHERE
	[location] LIKE '%States%')
SELECT 
	[Location],
	[Date],
	IIF([TotalCases] = '' OR [TotalDeaths] = '',NULL,([TotalDeaths]/[TotalCases]*100)) [DeathRate]
FROM
	cte1
ORDER BY
	1,2

--Ghana
SELECT 
	[Location],
	[Date],
	[total_cases] [TotalCases],
	[total_deaths] [TotalDeaths],
	CASE
		WHEN [total_cases] = '' OR [total_deaths] = '' THEN NULL 
		ELSE TRY_CAST([total_deaths] AS FLOAT)/TRY_CAST([total_cases] AS FLOAT)*100 
		END [DeathRate]
FROM
	PortfolioProjects..CovidDeaths
WHERE
	[location] LIKE '%Ghana%'
ORDER BY
	1,2

-- 2. Looking at total cases vs population
-- Shows percentage of population that got covid
--USA
SELECT 
	[Location],
	[Date],
	[population] [Population],
	[total_cases] [TotalCases],	
	CASE
		WHEN [total_cases] = '' OR [total_deaths] = '' THEN NULL 
		ELSE TRY_CAST([total_cases] AS FLOAT)/TRY_CAST([population] AS FLOAT)*100 
		END [CovidPercentage]
FROM
	PortfolioProjects..CovidDeaths
WHERE
	[location] LIKE '%States%'
ORDER BY
	1,2
--Ghana
SELECT 
	[Location],
	[Date],
	[population] [Population],
	[total_cases] [TotalCases],	
	CASE
		WHEN [total_cases] = '' OR [total_deaths] = '' THEN NULL 
		ELSE TRY_CAST([total_cases] AS FLOAT)/TRY_CAST([population] AS FLOAT)*100 
		END [PercentofPopulationInfected]
FROM
	PortfolioProjects..CovidDeaths
WHERE
	[location] LIKE '%Ghana%'
ORDER BY
	1,2

-- Looking at Countries with highest infection rates compared to population
WITH cte AS (SELECT 
	[Location],
	TRY_CONVERT(DECIMAL(10,2),[population]) [Population],
	TRY_CONVERT(DECIMAL(10,2),[total_cases]) [TotalCases]
FROM
	PortfolioProjects..CovidDeaths
GROUP BY
	[Location],
	[population],
	[total_cases]
)

SELECT
	[Location],
	[Population],
	MAX([TotalCases]) [HighestInfectionCount],
	TRY_CONVERT(DECIMAL(10,2),MAX([TotalCases]/[Population])*100) [PercentageOfPopulationInfected]
FROM
	cte
WHERE
	location LIKE '%Lebano%'
GROUP BY
	[Location],
	[Population]
ORDER BY
	[PercentageOfPopulationInfected] DESC


-- 4. Showing Countries with Hightst Death Count with Population
SELECT 
	[Location],
	MAX(TRY_CONVERT(DECIMAL(10,0),[total_deaths])) [TotalDeathCount]
FROM
	PortfolioProjects..CovidDeaths
WHERE 
	[Continent] != ''
GROUP BY 
	[Location]
ORDER BY
	2 DESC


-- 5. Breakdown things by Continent
SELECT 
	[continent] [Continent],
	--MAX(TRY_CONVERT(DECIMAL(10,0),[total_deaths])) [TotalDeathCount]
	MAX(CAST([total_deaths] AS INT)) [TotalDeathCount]
FROM
	PortfolioProjects..CovidDeaths
WHERE 
	[Continent] != ''
GROUP BY 
	[Continent]
ORDER BY
	2 DESC



-- Join Vaccinations and Deaths

SELECT
	*
FROM
	PortfolioProjects..CovidDeaths d JOIN PortfolioProjects..CovidVaccinations v
	ON d.[Location] = v.[Location] AND d.[date] = v.[date]


-- Total Populations vs Vaccinations
WITH cte2 AS (SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	TRY_CONVERT(DECIMAL(10,0),v.[new_vaccinations]) [NewVacs]
	--SUM(TRY_CAST(v.new_vaccinations) AS DECIMAL(10,0)) OVER (PARTITION BY d.[Location] ORDER BY d.[Location], d.[date]) AS [RollingPeopleVaccinated]
FROM
	PortfolioProjects..CovidDeaths d JOIN PortfolioProjects..CovidVaccinations v
	ON d.[Location] = v.[Location] AND d.[date] = v.[date]
WHERE
	d.[continent] != '')
SELECT
	continent,
	location,
	date,
	population,
	NewVacs,
	SUM(NewVacs) OVER (PARTITION BY [Location] ORDER BY [Location], [Date]) As [RollingPeopleVaccinated]
FROM
	cte2
ORDER BY
	2,3


-- Creating views to store data for visualizations

CREATE OR ALTER VIEW PercentPopVacinated
AS
WITH cte2 AS (SELECT
	d.continent,
	d.location,
	d.date,
	d.population,
	TRY_CONVERT(DECIMAL(10,0),v.[new_vaccinations]) [NewVacs]
	--SUM(TRY_CAST(v.new_vaccinations) AS DECIMAL(10,0)) OVER (PARTITION BY d.[Location] ORDER BY d.[Location], d.[date]) AS [RollingPeopleVaccinated]
FROM
	PortfolioProjects..CovidDeaths d JOIN PortfolioProjects..CovidVaccinations v
	ON d.[Location] = v.[Location] AND d.[date] = v.[date]
WHERE
	d.[continent] != '')
SELECT
	continent,
	location,
	date,
	population,
	NewVacs,
	SUM(NewVacs) OVER (PARTITION BY [Location] ORDER BY [Location], [Date]) As [RollingPeopleVaccinated]
FROM
	cte2

