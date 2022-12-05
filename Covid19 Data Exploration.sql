SELECT * FROM portfolio.coviddeaths;
SELECT location, date, total_cases, new_cases, total_deaths, population FROM portfolio.coviddeaths;

-- Total Cases VS Total Deaths
# Percentage of the population
SELECT location, CONCAT((SUM(new_cases)/population) * 100, '%') AS CovidPercentage, CONCAT((SUM(new_deaths)/population) * 100, '%') AS CovidDeathPercentage
FROM portfolio.coviddeaths
GROUP BY location;

-- Highest Infection Count and date for each country
SELECT location, MAX(new_cases) AS HighestDailyInfection #date
FROM portfolio.coviddeaths
GROUP BY location;

-- Number of total deaths per Country
SELECT location, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeaths
FROM portfolio.coviddeaths
GROUP BY location
ORDER BY TotalDeaths ASC;

-- Continents with Highest deaths per population
SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeaths
FROM portfolio.coviddeaths
WHERE continent IS NOT NULL
GROUP BY continent;

-- Global daily cases and deaths
SELECT date AS Date, 
	SUM(CAST(new_cases AS UNSIGNED)) AS NewCases,
    SUM(CAST(new_deaths AS UNSIGNED)) AS NewDeaths,
	SUM(CAST(total_cases AS UNSIGNED)) AS TotalCases, 
	SUM(CAST(total_deaths AS UNSIGNED)) AS TotalDeaths
FROM portfolio.coviddeaths
WHERE location NOT IN ('Africa', 'Asia', 'Europe', 'North America', 'South America', 'Oceania', 'European Union', 'High income', 'International', 'Low income')
GROUP BY date;

-- Find total global daily cases
SET @Cases := 0;
WITH cte_global (date, new_cases, new_deaths, total_deaths) AS(
SELECT date AS Date, 
	SUM(CAST(new_cases AS UNSIGNED)) AS NewCases,
    SUM(CAST(new_deaths AS UNSIGNED)) AS NewDeaths, 
	SUM(CAST(total_deaths AS UNSIGNED)) AS TotalDeaths
FROM portfolio.coviddeaths
WHERE location NOT IN ('Africa', 'Asia', 'Europe', 'North America', 'South America', 'Oceania', 'European Union', 'High income', 'International', 'Low income')
GROUP BY date
)
SELECT date, 
new_cases, 
(@Cases:= @Cases + new_cases) AS TotalCases #Cumulative Addition
FROM cte_global;




-- Highest Number of ICU patients in a single day
SELECT location, MAX(CAST(icu_patients AS UNSIGNED)) AS HighestICU
FROM portfolio.coviddeaths
GROUP BY location
ORDER BY HighestICU DESC;

-- Join the coviddeaths table and covidvaccinations table
SELECT * 
FROM portfolio.coviddeaths d
JOIN portfolio.covidvaccinations v
ON d.location = v.location  AND d.date = v.date;

-- Looking at total populations vs vaccinations
# We'll create a column showing the total vaccinations using the new_vaccinations column
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS TotalVaccinations
FROM portfolio.coviddeaths d
JOIN portfolio.covidvaccinations v
ON d.location = v.location AND d.date = v.date;

# Using CTE, find the maximum number of people vaccinated using the column created above
WITH cte_vac (continent, location, date, population, new_vaccinations, total_vaccinations) AS (
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS TotalVaccinations
FROM portfolio.coviddeaths d
JOIN portfolio.covidvaccinations v
ON d.location = v.location AND d.date = v.date
)
# Vaccination-Population Ratio
SELECT location, MAX(total_vaccinations) AS TotalVaccinations, (MAX(total_vaccinations)/population)*100 AS PercentageVaccinated 
FROM cte_vac
GROUP BY location;

CREATE OR REPLACE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS TotalVaccinations
FROM portfolio.coviddeaths d
JOIN portfolio.covidvaccinations v
ON d.location = v.location AND d.date = v.date;
