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

-- We will create a view of this query to visualize later (View#1)

CREATE VIEW highest_death_count AS
SELECT location, MAX(cast(total_deaths as int)) AS highest_death_count
FROM [Portolio Project - Covid]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location


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

-- Finally, let us create a View to store data for later visualization (View 2)

CREATE VIEW percent_pop_vaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- Let us now take a look at hospitalization rates

SELECT *
FROM [Portolio Project - Covid]..CovidHosp$

-- It would be interesting to see hospitalization data correlated with vaccination data, so let us first merge the two table

SELECT *
FROM [Portolio Project - Covid]..CovidVaccinations$ AS vac
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON 
		vac.location = hosp.location AND
		vac.date = hosp.date

-- Let us look at the categories of interest in Canada

SELECT vac.location, vac.date, vac.people_vaccinated, vac.people_fully_vaccinated, hosp.icu_patients, hosp.hosp_patients, hosp.positive_rate
FROM [Portolio Project - Covid]..CovidVaccinations$ AS vac
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON
		vac.location = hosp.location AND
		vac.date = hosp.date
WHERE vac.location = 'Canada'

-- Finally, it is important to see if vaccinations had an impact on stopping the spread of covid and how it affected hospitalization rates

SELECT *
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON
		dea.location = hosp.location AND
		dea.date = hosp.date

-- We will now look at key metrics

SELECT dea.location, dea.date, dea.new_cases, dea.new_deaths, vac.people_vaccinated, vac.people_fully_vaccinated, hosp.icu_patients, hosp.hosp_patients, hosp.positive_rate
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON
		dea.location = hosp.location AND
		dea.date = hosp.date
WHERE dea.location = 'Canada'

-- Let us create a view of the last query (View 3)

CREATE VIEW vaccination_effect AS

SELECT dea.location, dea.date, dea.new_cases, dea.new_deaths, vac.people_vaccinated, vac.people_fully_vaccinated, hosp.icu_patients, hosp.hosp_patients, hosp.positive_rate
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON
		dea.location = hosp.location AND
		dea.date = hosp.date
WHERE dea.location = 'Canada'



-- I am interested in finding out how the stringency index affected hospitalization rates

SELECT hosp.location, hosp.date, hosp.new_cases, hosp.hosp_patients, demo.stringency_index
FROM [Portolio Project - Covid]..CovidHosp$ AS hosp
JOIN [Portolio Project - Covid]..CovidDemographics$ AS demo
	ON
		hosp.location = demo.location AND
		hosp.date = demo.date

-- Let us create a view (View 4)

CREATE VIEW stringency_cases AS
SELECT hosp.location, hosp.date, hosp.new_cases, hosp.hosp_patients, demo.stringency_index
FROM [Portolio Project - Covid]..CovidHosp$ AS hosp
JOIN [Portolio Project - Covid]..CovidDemographics$ AS demo
	ON
		hosp.location = demo.location AND
		hosp.date = demo.date

-- Let us now take a look at how GDP affects death rate

SELECT dea.location, 
	demo.gdp_per_capita, 
	MAX(dea.total_cases) AS highest_total_cases, 
	MAX((dea.total_cases/dea.population)*100) AS highest_infec_rate,
	MAX(CONVERT(BIGINT,dea.total_deaths)) AS highest_total_deaths,
	MAX(((CONVERT(BIGINT,dea.total_deaths))/dea.population)*100) AS highest_death_rate
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidDemographics$ AS demo
	ON
		dea.location = demo.location AND
		dea.date = demo.date
WHERE dea.continent IS NOT NULL AND demo.gdp_per_capita IS NOT NULL
GROUP BY dea.location, dea.population, demo.gdp_per_capita
ORDER BY demo.gdp_per_capita ASC

-- Create View (View 5)

CREATE VIEW gdp_cases_deaths AS
SELECT dea.location, demo.gdp_per_capita, MAX(dea.total_cases) AS highest_total_cases, MAX((dea.total_cases/dea.population)*100) AS highest_infec_rate, MAX(CONVERT(BIGINT,dea.total_deaths)) AS highest_total_deaths, MAX(((CONVERT(BIGINT,dea.total_deaths))/dea.population)*100) AS highest_death_rate
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidDemographics$ AS demo
	ON
		dea.location = demo.location AND
		dea.date = demo.date
WHERE dea.continent IS NOT NULL AND demo.gdp_per_capita IS NOT NULL
GROUP BY dea.location, dea.population, demo.gdp_per_capita

-- Let us take a look at death rate with respect to available hospital beds

SELECT dea.location,
	bed.hospital_beds_per_thousand,
	MAX(((CONVERT(BIGINT,dea.total_deaths))/dea.population)*100) AS highest_death_rate,
	MAX(((CONVERT(BIGINT,hosp.icu_patients))/hosp.population)*100) AS max_icu_patients_perc
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidBeds$	AS bed
	ON
		dea.location = bed.location AND
		dea.date = bed.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON
		dea.location = hosp.location AND
		dea.date = hosp.date
WHERE dea.continent IS NOT NULL AND  bed.hospital_beds_per_thousand IS NOT NULL
GROUP BY dea.location, bed.hospital_beds_per_thousand
ORDER BY bed.hospital_beds_per_thousand DESC

-- Create View (View 6)

CREATE VIEW bed_data AS
SELECT dea.location,
	bed.hospital_beds_per_thousand,
	MAX(((CONVERT(BIGINT,dea.total_deaths))/dea.population)*100) AS highest_death_rate,
	MAX(((CONVERT(BIGINT,hosp.icu_patients))/hosp.population)*100) AS max_icu_patients_perc
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidBeds$	AS bed
	ON
		dea.location = bed.location AND
		dea.date = bed.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON
		dea.location = hosp.location AND
		dea.date = hosp.date
WHERE dea.continent IS NOT NULL AND  bed.hospital_beds_per_thousand IS NOT NULL
GROUP BY dea.location, bed.hospital_beds_per_thousand


-- Herd immunity

SELECT *
FROM 
(
	SELECT
		location, date, population, people_fully_vaccinated/population *100 AS perc_people_vaccinated
	FROM [Portolio Project - Covid]..CovidVaccinations$ AS vac
) AS Subquery
WHERE  perc_people_vaccinated BETWEEN 80 AND 100
ORDER BY location, date ASC
		


----------------------------------------------------------------------------------------------------------
-- Queries For Tableau

-- Query 1 - Looking at Death Count Per Country

SELECT location, MAX(cast(total_deaths as int)) AS highest_death_count
FROM [Portolio Project - Covid]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count DESC


-- Query 2 - Looking at Rolling Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(BIGINT,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location = 'Canada'

SELECT dea.continent, dea.date, vac.new_vaccinations, SUM(CONVERT(BIGINT, vac.new_vaccinations)) AS rolling_vaccinations
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent, dea.date, vac.new_vaccinations


SELECT location, date, people_fully_vaccinated/population*100 AS perc_pop_vaccinated
FROM [Portolio Project - Covid]..CovidVaccinations$
WHERE continent IS NOT NULL
ORDER BY location, date






-- Query 3 - Looking at the effect of vaccinations VS. New cases, New Deaths, ICU Patients, Hospital Patients, and Positive Rate

SELECT dea.location, dea.date, vac.people_fully_vaccinated, dea.new_cases, dea.new_deaths,  hosp.icu_patients, hosp.hosp_patients, hosp.positive_rate
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidVaccinations$ AS vac
	ON
		dea.location = vac.location AND
		dea.date = vac.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON
		dea.location = hosp.location AND
		dea.date = hosp.date
WHERE dea.location = 'Canada'


-- Query 4 - Looking at the Effect of the Stringency Index on Hospital Patients

SELECT hosp.location, MAX(hosp.total_cases)/ MAX(hosp.population)*100 AS infec_rate, AVG(demo.stringency_index) AS avg_stringency_index
FROM [Portolio Project - Covid]..CovidHosp$ AS hosp
JOIN [Portolio Project - Covid]..CovidDemographics$ AS demo
	ON
		hosp.location = demo.location AND
		hosp.date = demo.date
WHERE hosp.continent IS NOT NULL
GROUP BY hosp.location


-- Query 5 - Looking at the effect of GDP on infetion rate and death rate

SELECT dea.location, demo.gdp_per_capita, MAX(dea.total_cases) AS highest_total_cases, MAX((dea.total_cases/dea.population)*100) AS highest_infec_rate, MAX(CONVERT(BIGINT,dea.total_deaths)) AS highest_total_deaths, MAX(((CONVERT(BIGINT,dea.total_deaths))/dea.population)*100) AS highest_death_rate
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidDemographics$ AS demo
	ON
		dea.location = demo.location AND
		dea.date = demo.date
WHERE dea.continent IS NOT NULL AND demo.gdp_per_capita IS NOT NULL
GROUP BY dea.location, dea.population, demo.gdp_per_capita


-- Query 6 - Looking at the effects of hospital beds on death rate and icu patient percentage

SELECT dea.location,
	bed.hospital_beds_per_thousand,
	MAX(((CONVERT(BIGINT,dea.total_deaths))/dea.population)*100) AS highest_death_rate,
	MAX(((CONVERT(BIGINT,hosp.icu_patients))/hosp.population)*100) AS max_icu_patients_perc
FROM [Portolio Project - Covid]..CovidDeaths$ AS dea
JOIN [Portolio Project - Covid]..CovidBeds$	AS bed
	ON
		dea.location = bed.location AND
		dea.date = bed.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON
		dea.location = hosp.location AND
		dea.date = hosp.date
WHERE dea.continent IS NOT NULL AND  bed.hospital_beds_per_thousand IS NOT NULL
GROUP BY dea.location, bed.hospital_beds_per_thousand


--------------------------------------------------------------------------------------------

-- 1) We want to look at total deaths as a percentage in each country

SELECT location, (MAX(CONVERT(BIGINT,total_deaths))/MAX(population))*100 AS mortality_rate
FROM [Portolio Project - Covid]..CovidDeaths$
Group by location
ORDER BY mortality_rate DESC


-- 2) We want to look at the total cases per country

SELECT location, MAX(CONVERT(BIGINT,total_cases)) AS total_cases
FROM [Portolio Project - Covid]..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY location ASC

-- 3) We want to look at percentage of population vaccinated per country

SELECT location, date, people_fully_vaccinated/population*100 AS perc_pop_vaccinated
FROM [Portolio Project - Covid]..CovidVaccinations$
WHERE continent IS NOT NULL
ORDER BY location, date

-- 4) We want to look at different parameters plotted against vaccination status

SELECT vac.date, 
	vac.people_fully_vaccinated/vac.population*100 AS perc_pop_vaccinated, 
	dea.new_deaths, 
	dea.new_cases, 
	hosp.hosp_patients, 
	hosp.icu_patients
FROM [Portolio Project - Covid]..CovidVaccinations$ AS vac
JOIN [Portolio Project - Covid]..CovidDeaths$ AS dea
	ON dea.location = vac.location AND
	dea.date = vac.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON vac.location = hosp.location AND
	vac.date = hosp.date
		
WHERE vac.continent IS NOT NULL AND vac.location = 'canada'
ORDER BY vac.date ASC


SELECT vac.date, 
	(vac.people_fully_vaccinated / vac.population) * 100 AS perc_pop_vaccinated,
	(dea.new_cases / vac.population) * 100 AS perc_new_cases,
	(dea.new_deaths / vac.population) * 100 AS perc_new_deaths,  
	(hosp.hosp_patients / vac.population) * 100 AS perc_hosp_patients, 
	(hosp.icu_patients / vac.population) * 100 AS perc_icu_patients
FROM [Portolio Project - Covid]..CovidVaccinations$ AS vac
JOIN [Portolio Project - Covid]..CovidDeaths$ AS dea
	ON dea.location = vac.location AND
	dea.date = vac.date
JOIN [Portolio Project - Covid]..CovidHosp$ AS hosp
	ON vac.location = hosp.location AND
	vac.date = hosp.date
		
WHERE vac.continent IS NOT NULL AND vac.location = 'canada'









-- 5) We want to look at the same parameters

SELECT stringency_index_grouped, SUM(CONVERT(BIGINT,avg_new_cases)) AS avg_new_cases, SUM(CONVERT(BIGINT,avg_new_deaths)) AS avg_new_deaths
FROM (
	SELECT demo.location,
	CASE WHEN demo.stringency_index >= 81 THEN '81-100'
	WHEN demo.stringency_index >= 61 THEN '61-80'
	WHEN demo.stringency_index >= 41 THEN '41-60'
	WHEN demo.stringency_index >= 21 THEN '21-40'
	ELSE '0-20'
	END AS stringency_index_grouped,
	AVG(CONVERT(bigint,dea.new_cases)) AS avg_new_cases, 
	AVG(CONVERT(bigint,dea.new_deaths)) AS avg_new_deaths
FROM [Portolio Project - Covid]..CovidDemographics$ AS demo
JOIN [Portolio Project - Covid]..CovidDeaths$ AS dea
	ON demo.location = dea.location AND
	demo.date = dea.date
GROUP BY demo.stringency_index, demo.location
) metrics
GROUP BY stringency_index_grouped
ORDER BY stringency_index_grouped
