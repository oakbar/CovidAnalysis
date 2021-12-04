/* 
COVID-19 Exploration and Visualization Project
Skills Used: Aggregate functions, CTEs, Temp Tables, Casting Data Types, Joins, Creating Views
*/

Select *
From CovidAnalysis..CovidDeaths
where continent is not null
order by 3,4

-- Select relevant data
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidAnalysis..CovidDeaths
order by 1,2

-- Comparing Total Cases vs. Total Deaths
-- Shows chance of dying if you contract COVID in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
From CovidAnalysis..CovidDeaths
where location like '%states%'
order by 1,2

-- Comparing Total Cases vs. Population
-- Shows percentage of population that contracted COVID
Select Location, date, total_cases, Population, (total_cases/population) * 100 InfectedPercentage
From CovidAnalysis..CovidDeaths
--where location like '%states%'
order by 1,2

-- Exploring countries with Highest Infection Rate vs. Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 as InfectionRate
From CovidAnalysis..CovidDeaths
Group by Location, Population
order by InfectionRate desc

-- Shows countries with Highest Death Count per Population
Select Location, Population, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidAnalysis..CovidDeaths
Where continent is not null
Group by Location, Population
order by TotalDeathCount desc

-- Shows continents with Highest Death Count Per Population 
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidAnalysis..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount desc

-- Global scope of Total Cases. vs Total Deaths
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths
, SUM(cast(new_deaths as int)) / SUM(new_cases) * 100 as GlobalDeathPercentage
From CovidAnalysis..CovidDeaths
where continent is not null
Group by date
order by 1,2

-- Comparing Total Population vs. Vaccinations
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location order by dth.location, dth.date) as RollingVaccinations
From CovidAnalysis..CovidDeaths dth
Join CovidAnalysis..CovidVaccinations vac
	On dth.location = vac.location
	and dth.date = vac.date
where dth.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
With PopVsVac (Continent, Location, Date, Population, new_vaccinations, RollingVaccinations)
as
(
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location order by dth.location, dth.date) as RollingVaccinations
From CovidAnalysis..CovidDeaths dth
Join CovidAnalysis..CovidVaccinations vac
	On dth.location = vac.location
	and dth.date = vac.date
where dth.continent is not null
)
Select *, (RollingVaccinations/Population) * 100 as PercentVaccinated
From PopVsVac

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric, 
RollingVaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location order by dth.location, dth.date) as RollingVaccinations
From CovidAnalysis..CovidDeaths dth
Join CovidAnalysis..CovidVaccinations vac
	On dth.location = vac.location
	and dth.date = vac.date
where dth.continent is not null

Select *, (RollingVaccinations / Population) * 100 as PercentVaccinated
From #PercentPopulationVaccinated

-- Creating View to store data for visualization
Create View PercentPopulationVaccinated as
Select dth.continent, dth.location, dth.date, dth.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dth.location order by dth.location, dth.date) as RollingVaccinations
From CovidAnalysis..CovidDeaths dth
Join CovidAnalysis..CovidVaccinations vac
	On dth.location = vac.location
	and dth.date = vac.date
where dth.continent is not null
