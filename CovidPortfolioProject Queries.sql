select *
from [Covid Portfolio Project].dbo.CovidDeaths
where continent is null
order by 3,4

select *
from [Covid Portfolio Project].dbo.CovidVaccinations
order by 3,4


-- Select Data that we are going to be using
select continent, location, date, total_cases, new_cases, total_deaths, population
from [Covid Portfolio Project].dbo.CovidDeaths
where continent is not null
order by 1,2


-- Looking at the total cases vs. total deaths
-- Shows the likelihood of dying if you contract Covid in your country
select continent, location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 as DeathPercentage
from [Covid Portfolio Project].dbo.CovidDeaths
where location like '%states%'
and continent is not null
order by 1,2


-- Looking at the total cases vs the population
-- Shows what percentage of population got covid
select continent, location, date, population, total_cases, (total_cases/population) * 100 as PositiveCasesPerPopulation
from [Covid Portfolio Project].dbo.CovidDeaths
where location like '%states%'
order by 1, 2


-- Looking at countries with highest infection rate compared to population
select continent, location, population, max(total_cases) as HighestInfectionCount, Max((total_cases/population)) * 100 as PercentPopulationInfected
from [Covid Portfolio Project].dbo.CovidDeaths
--where location like '%states%'
where continent is not null
group by continent, location, population
order by PercentPopulationInfected desc


-- Showing the countries with the highest death count per population
Select location, MAX(cast (total_deaths as int)) as TotalDeathCount
from [Covid Portfolio Project]..CovidDeaths
--where location like '%states%'
where continent is not null
group by location
order by TotalDeathCount desc


-- Let's break things down by continent
-- Total death count by continent
Select continent, MAX(cast (total_deaths as int)) as TotalDeathCount
from [Covid Portfolio Project]..CovidDeaths
--where location like '%states%'
where continent is not null
--and not location like '%income%' 
group by continent
order by TotalDeathCount desc


-- Global Numbers per day for total new cases, total new deaths, and death percentage
select date, SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
from [Covid Portfolio Project]..CovidDeaths
where continent is not null
group by date
order by 1,2

-- Total global numbers for covid death percentage
select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as New_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases) * 100 as DeathPercentage
from [Covid Portfolio Project]..CovidDeaths
where continent is not null
order by 1,2



--alter table [Covid Portfolio Project].dbo.CovidDeaths
--alter column location nvarchar(150)
-- Had to change the data type for dea.location to nvarchar(150) due to total bytes being >900

-- Looking at total population vs. vaccination globally
-- Using partition by to collect the running total
select Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.date) as RollingPeopleVaccinated
-- SUM(convert(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from [Covid Portfolio Project]..CovidDeaths as Dea
join [Covid Portfolio Project]..CovidVaccinations as Vac
	on Dea.location = Vac.location
	and Dea.date = Vac.date
where dea.continent is not null
order by 2,3


-- Use CTE
-- Rolling total of people vaccinated compared to the population
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.date) as RollingPeopleVaccinated
-- SUM(convert(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from [Covid Portfolio Project]..CovidDeaths as Dea
join [Covid Portfolio Project]..CovidVaccinations as Vac
	on Dea.location = Vac.location
	and Dea.date = Vac.date
where dea.continent is not null
-- order by 2,3
)
Select *, (RollingPeopleVaccinated/Population) * 100 as PercentageVaccinated
from PopvsVac


-- Use TEMP TABLE
-- Rolling total of people vaccinated compared to the population
Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.date) as RollingPeopleVaccinated
-- SUM(convert(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from [Covid Portfolio Project]..CovidDeaths as Dea
join [Covid Portfolio Project]..CovidVaccinations as Vac
	on Dea.location = Vac.location
	and Dea.date = Vac.date
where dea.continent is not null
order by 2,3

Select *, (RollingPeopleVaccinated/Population) * 100 as PercentageVaccinated
from #PercentPopulationVaccinated



--CREATE VIEW
--Create view is permanent, unlike a temp table
--Creating view to store data for later visualizations
Create view PercentPopulationVaccinated as 
select Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.date) as RollingPeopleVaccinated
-- SUM(convert(bigint, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from [Covid Portfolio Project]..CovidDeaths as Dea
join [Covid Portfolio Project]..CovidVaccinations as Vac
	on Dea.location = Vac.location
	and Dea.date = Vac.date
where dea.continent is not null
--order by 2,3