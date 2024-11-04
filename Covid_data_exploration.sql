-- Notes
-- 1. Most large numbers are in Bigint. Integer division will return zero if the denominator is larger. Therefore CAST either to decimals where required.
-- 2. The total cases and total deaths columns (as the names suggest) are cumulative totals, not each day's number.
-- 3. The location column includes regions divided based on continent and wealth. Their corresponding location columns are empty.

-- View the country data excluding regions
SELECT *
FROM dbo.CovidDeaths 
WHERE continent <> ' '
ORDER BY 3, 4;

-- India
---- Calculate death rates
SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    (total_deaths / NULLIF(CAST(total_cases AS decimal(10, 1)), 0)) * 100 AS death_rate
FROM [dbo].[CovidDeaths]
WHERE location = 'India' 
ORDER BY 3;

---- Calculate infection rates
SELECT 
    date, 
    population, 
    new_cases, 
    total_cases, 
    total_cases / CAST(population AS decimal(11, 1)) * 100 AS infection_rate
FROM [dbo].[CovidDeaths]
WHERE location = 'India'
ORDER BY date;

-- Global
---- Top countries in terms of infection rate per capita
SELECT 
    location, 
    population, 
    MAX(total_cases) AS total_cases, 
    MAX(total_cases / CAST(population AS decimal(11, 1)) * 100) AS infection_rate
FROM dbo.CovidDeaths
WHERE continent <> ' '
GROUP BY location, population
ORDER BY 4 DESC;

---- Top countries in terms of death rate per capita
SELECT 
    location, 
    population, 
    MAX(total_deaths) AS total_deaths, 
    MAX(total_deaths / CAST(population AS decimal(11, 1))) * 100 AS death_rate
FROM dbo.CovidDeaths
WHERE continent <> ' '
GROUP BY location, population
ORDER BY 4 DESC;

---- Top countries in terms of number of deaths 
SELECT 
    location, 
    MAX(total_deaths) AS Total_Deaths
FROM dbo.CovidDeaths
WHERE continent <> ' '
GROUP BY location
ORDER BY Total_Deaths DESC;

----- Top continents in terms of number of deaths
SELECT 
    continent, 
    MAX(total_deaths) AS Total_Deaths
FROM dbo.CovidDeaths
WHERE continent <> ' '
GROUP BY continent
ORDER BY Total_Deaths DESC;

---- Total cases, total deaths, and death percentage 
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths, 
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS death_rate
FROM dbo.CovidDeaths
WHERE continent <> ' ';

-- Notes
-- 1. There’s no built-in SQL syntax to directly select all columns except specific ones.

-- Cumulative total number of vaccinations by country using PARTITION BY
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vaccinations_ToDate
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac 
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> '' 
ORDER BY 2, 3;

-- Cumulative percentage population vaccinated (assuming one dose per person)
-- Can't be done directly as cumulative total number of vaccinations column doesn't exist and needs to be added.
-- Can be done only by adding the previous table to a CTE or TEMP TABLE
---- 1. CTE
WITH PopVsVac AS 
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS Total_Vaccinations_To_Date
    FROM dbo.CovidDeaths dea
    JOIN dbo.CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent <> '' 
)
-- The above CTE, PopVsVac, aggregates vaccination data, providing total vaccinations to date per location alongside population data.
-- It is created to allow referencing the 'total_vaccinations_To_Date' column in the following query.

SELECT *, 
       (Total_Vaccinations_To_Date / CAST(population AS decimal(11, 1))) * 100 AS Pct_Vaccinated_To_Date
FROM PopVsVac;

---- 2. TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated;  -- In order to facilitate alterations
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    Total_Vaccinations_To_Date numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS Total_Vaccinations_To_Date
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> '';

SELECT *,
       (Total_Vaccinations_To_Date / CAST(population AS decimal(11, 1))) * 100 AS Pct_Vaccinated_To_Date
FROM #PercentPopulationVaccinated;

-- Creating views 
GO  -- Batch separator
CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS Total_Vaccinations_To_Date
FROM dbo.CovidDeaths dea
JOIN dbo.CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> '';
GO
