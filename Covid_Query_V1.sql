-- Taking a quick glance at the data

SELECT
	*
FROM
	[Portolio Project - Covid]..CovidDeaths$
Order By 
	3,4

-- Select the Data We Will Be Using

SELECT
	location, date, total_cases, new_cases, total_deaths, population
FROM
	[Portolio Project - Covid]..CovidDeaths$
ORDER BY
	1,2

-- Looking at Total Cases vs. Total Deaths (Shows the chances of dying if covid is contracted per country)

SELECT
	location, date, total_cases, total_deaths, (Total_deaths/total_cases)*100 AS Infected_Death_Perc
FROM
	[Portolio Project - Covid]..CovidDeaths$
WHERE 
	location = 'Canada'
ORDER BY
	1,2

-- Looking at the Total Cases vs Population

SELECT
	location, date, population, total_cases, (total_cases/population)*100 AS infected_perc
FROM
	[Portolio Project - Covid]..CovidDeaths$
WHERE
	location = 'Canada'
ORDER BY
	1,2

-- What countries have the highest infection rates?

SELECT
	location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS infected_perc
FROM 
	[Portolio Project - Covid]..CovidDeaths$
GROUP BY
	location, population
ORDER BY
	infected_perc DESC

-- What countries have the highest deatch count per population

SELECT
	location, MAX(total_deaths) AS TotalDeathCount
FROM
	[Portolio Project - Covid]..CovidDeaths$
GROUP BY
	location
ORDER BY
	TotalDeathCount DESC

-- We need to change the formatting of the total_deaths column

SELECT
	location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM
	[Portolio Project - Covid]..CovidDeaths$
GROUP BY
	location
ORDER BY
	TotalDeathCount DESC

-- We need to get rid of the grouped continent data by setting a where clause

SELECT
	location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM
	[Portolio Project - Covid]..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	location
ORDER BY
	TotalDeathCount DESC

-- NOW WE BREAK THINGS DOWN BY CONTINENT

SELECT
	continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM
	[Portolio Project - Covid]..CovidDeaths$
WHERE
	continent IS NOT NULL
GROUP BY
	continent
ORDER BY
	TotalDeathCount DESC

-- Lets look at some global numbers 

SELECT
	date, SUM(new_cases) AS TotalCases, 
	SUM(cast(new_deaths AS int)) AS TotalDeaths, 
	SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPerc 
FROM
	[Portolio Project - Covid]..CovidDeaths$
WHERE 
	continent IS NOT NULL
GROUP BY
	date
ORDER BY
	1,2

-- Not grouped by Date

SELECT
	SUM(new_cases) AS TotalCases, 
	SUM(cast(new_deaths AS int)) AS TotalDeaths, 
	SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPerc 
FROM
	[Portolio Project - Covid]..CovidDeaths$
WHERE 
	continent IS NOT NULL
ORDER BY
	1,2

-- Lets look at the vaccination Data

SELECT
	*
FROM
	[Portolio Project - Covid]..CovidVaccinations$

-- Let us perform a join

SELECT
	*
FROM
	[Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN
	[Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON 
		dea.location = vac.location
		AND dea.date = vac.date

-- Looking at total population Vs. Vaccinations

SELECT
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
FROM
	[Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN
	[Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON 
		dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
ORDER BY
	2,3

-- As we can see, the previous query outputs an error. This is because the integer created is too high and thus we need to convert to bigint instead.

SELECT
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM
	[Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN
	[Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON 
		dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
ORDER BY
	2,1,3

-- Lets Use a CTE

WITH
	PopulationVsVaccination (Continent, Location, Date, Population, New_vaccinations, RollingVaccinations) 
AS
(
SELECT
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM
	[Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN
	[Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON 
		dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
)
SELECT
	*, (RollingVaccinations/Population)*100 As VaccinationsPerPopulation
FROM
	PopulationVsVaccination
WHERE
	location = 'Canada'

-- Lets Try with a Temp Table

CREATE TABLE 
	#PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingVaccinations numeric,
)
INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM
	[Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN
	[Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON 
		dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
SELECT
	*, (RollingVaccinations/Population)*100 As VaccinationsPerPopulation
FROM
	#PercentPopulationVaccinated

-- Creating View To Store Data for Viz

CREATE VIEW PercentPopulationVaccinated AS
SELECT
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM
	[Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN
	[Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON 
		dea.location = vac.location
		AND dea.date = vac.date
WHERE
	dea.continent IS NOT NULL

