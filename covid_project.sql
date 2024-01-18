-- Select data being queried
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM deaths;

-- Querying Total cases vs total deaths per location (continent)
SELECT location, date, total_cases, total_deaths,
		(total_deaths/total_cases)*100 AS deathPercentage
FROM deaths
	WHERE location LIKE '%africa%';

/*On 2020/03/08 death percentage was 6.25%
2024/01/07 death percentage is 1.97% 
Reflects the likelihood of dying of covid based on the data*/

-- Total cases VS population
SELECT location, date, total_cases, population, 
		(total_cases/population)*100 AS deathPercentage
FROM deaths
	WHERE location LIKE '%africa%';

/*Shows percentage of population that contracted covid*/


-- Countries with highest infection rate
SELECT location, MAX(total_cases) AS infectionCount, population, 
		MAX((total_cases/population))*100 AS percentOFpopulationInfected
FROM deaths
	GROUP BY population, location
	ORDER BY percentOFpopulationInfected DESC;

/*Brunei has has the highest infection count to date 74.43%
Although the country does not necessarily have the largest population */


-- Countries with highest death count per population
ALTER TABLE deaths
MODIFY total_deaths int; -- imported data had the wrong data type

SELECT location, MAX(total_deaths) AS totalDeathCount
FROM deaths
	GROUP BY location
	ORDER BY totalDeathCount DESC;
/*countries in Asia highest death count*/


-- By continent
SELECT continent, MAX(total_deaths) AS totalDeathCount
FROM deaths
	GROUP BY continent
	ORDER BY totalDeathCount DESC;

/*South America has the highest death count*/


-- Global numbers
SELECT date, SUM(new_cases) AS globalNumbers		
FROM deaths
	WHERE continent IS NOT NULL
	GROUP BY date;

ALTER TABLE deaths
MODIFY new_deaths int; -- imported data had the wrong data type

SELECT date, SUM(new_cases) AS globalcases, SUM(new_deaths) AS globaldeaths
FROM deaths
	WHERE continent IS NOT NULL
	GROUP BY date;

SELECT date, SUM(new_cases) AS globalcases, SUM(new_deaths) AS globaldeaths, 
			SUM(new_deaths)/ SUM(new_cases) * 100 as deathPercentage
FROM deaths
	WHERE continent IS NOT NULL
	GROUP BY date;
/*total of new cases and deaths*/

SELECT  SUM(new_cases) AS globalcases, SUM(new_deaths) AS globaldeaths, 
			SUM(new_deaths)/ SUM(new_cases) * 100 as deathPercentage
FROM deaths
WHERE continent IS NOT NULL;    -- total global numbers to date


-- Joining Deaths, Vaccinations to find total population vs vaccination
SELECT *
FROM deaths AS dea
	JOIN covidvaccines AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM deaths AS dea
	JOIN covidvaccines AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE continent IS NOT NULL;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) AS totalVaccinationsperlocation
FROM deaths AS dea
	JOIN covidvaccines AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL;

-- CTE
WITH popvsvac (continent, location, date, population,new_vaccinations, totalVaccinationsperlocation)
 AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) AS totalVaccinationsperlocation
FROM deaths AS dea
	JOIN covidvaccines AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
)
Select * , (totalVaccinationsperlocation/ population) *100
FROM popvsvac; 
/*using a common table expression to calculate the percentage of vaccinations vs total population*/

-- Create view as an alternative
CREATE VIEW percentPopVaccinated AS(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
			SUM(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) AS totalVaccinationsperlocation
FROM deaths AS dea
	JOIN covidvaccines AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent IS NOT NULL
);

-- Joining deaths, vaccines, tests, demographic tables
SELECT *
FROM deaths AS dea
	JOIN covidvaccines AS vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	JOIN covidtests AS tes
		ON dea.location = tes.location
	JOIN coviddemographics AS demo
		ON dea.location = demo.location;
 