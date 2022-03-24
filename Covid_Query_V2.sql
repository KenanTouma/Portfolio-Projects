-- Our database has 3 tables: CovidDeaths, CovidHosp, and CovidVaccinations with information about Deaths, Hospitilizations, and Vaccinations pertaining to COVID, respectively.
-- Lets take a look a glimpse of each of our tables

SELECT *
FROM [Portolio Project - Covid]..CovidDeaths$

SELECT *
FROM [Portolio Project - Covid]..CovidHosp$

SELECT *
FROM [Portolio Project - Covid]..CovidVaccinations$

-- Let us begin exploring the COVID Deaths table

SELECT location, date, population, new_cases, total_cases, new_deaths, total_deaths
FROM [Portolio Project - Covid]..CovidDeaths$

-- Let us take a look at the Total Cases Vs Total Deaths. This shows us the likelihood of death if COVID is contracted

SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM [Portolio Project - Covid]..CovidDeaths$

-- Let us take a look at which country had the highest average death rate

SELECT location, AVG((total_deaths/total_cases)*100) AS death_rate
FROM [Portolio Project - Covid]..CovidDeaths$
GROUP BY location
ORDER BY death_rate DESC

-- Let us take a look at when Canada's Death Rate was highest

SELECT location, date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_rate
FROM [Portolio Project - Covid]..CovidDeaths$
WHERE location = 'Canada'
ORDER BY death_rate DESC

-- Let us now take a look at the Total Cases vs. Population

SELECT location, date, population, total_cases, (total_cases/population)*100 AS infec_rate
FROM [Portolio Project - Covid]..CovidDeaths$

-- What countries have the highest infection rate

SELECT location, population, MAX(total_cases) AS highest_total_cases, MAX((total_cases/population)*100) AS highest_infec_rate
FROM [Portolio Project - Covid]..CovidDeaths$
GROUP BY location, population
ORDER BY highest_infec_rate DESC

-- What countries have the highest mortality rate (Death count per population)

SELECT location, MAX(total_deaths) AS highest_death_count
FROM [Portolio Project - Covid]..CovidDeaths$
GROUP BY location
ORDER BY highest_death_count DESC

-- We saw that the last query gave us an error. To fix this, we need to change the formatting of the total_deaths columns

SELECT location, MAX(cast(total_deaths as int)) AS highest_death_count
FROM [Portolio Project - Covid]..CovidDeaths$
GROUP BY location
ORDER BY highest_death_count DESC

-- We now need to get rid of results that aren't countries. By looking at the data we notice that we can do this by adding a where clause.

SELECT location, MAX(cast(total_deaths as int)) AS highest_death_count
FROM [Portolio Project - Covid]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count DESC

-- Let us break things down by continent, as this is important if we were to visualize this data in a dashboard

SELECT continent, MAX(cast(total_deaths as int)) AS highest_death_count
FROM [Portolio Project - Covid]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count DESC

-- Let us look at some global numbers

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 AS death_rate
FROM [Portolio Project - Covid]..CovidDeaths$
WHERE continent IS NOT NULL

-- Let us look at how that number changes with time

SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 AS death_rate
FROM [Portolio Project - Covid]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date ASC

-- Now we will take a look at vaccination data

SELECT *
FROM [Portolio Project - Covid]..CovidVaccinations$

-- We can perform a join on the deaths table

SELECT *
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date

-- Let us look at  Canada's Total Population vs. Vaccination Data

SELECT dea.location, dea.date, dea.population, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date), vac.people_fully_vaccinated, vac.total_boosters
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- The previous query gives out an error because when it is trying to calculate the sum of new_vaccinations, the number is too large to be stored as an int. We will fix it by using bigint

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations, vac.people_fully_vaccinated, vac.total_boosters
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location = 'Canada'

-- We will now use a CTE so we can properly query

WITH population_vs_vaccination (Continent, Location, Date, Population, New_vaccinations, rolling_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON 
		dea.location = vac.location AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_vaccinations/population)*100 AS vaccinations_population
FROM population_vs_vaccination
WHERE location = 'Canada'

-- We can also get the same result by creating a temporary table

CREATE TABLE #percent_pop_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_vaccinations numeric,
)
INSERT INTO #percent_pop_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL
SELECT *,(rolling_vaccinations/population)*100 AS vaccinations_population
FROM #percent_pop_vaccinated

-- Finally, let us create a View to store data for later visualization

CREATE VIEW percent_pop_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL