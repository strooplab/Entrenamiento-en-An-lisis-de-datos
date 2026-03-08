--*************************************************************************
----****  COVID 19 DATASET ANALYSIS - ANÁLISIS DE DATASET COVID 19     ****
--*************************************************************************
--*************************************************************************
----****	HECHO POR: STROOPLAB									   ****
----****    GUIA: Alex The Analyst (www.youtube.com)				   ****
--*************************************************************************
SELECT *
FROM db_portafolio..CovidDeaths$
WHERE continent is not null
ORDER by 3,4

SELECT *
FROM db_portafolio..CovidVaccinations$
ORDER by 3,4

-- Seleccionar los datos que vamos a usar
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM db_portafolio..CovidDeaths$
order by 1,2

-- Analizar Total de casos de COVID VS Muertes totales por COVID en Colombia
-- Muestra el porcentaje de muerte por covid con respecto a los casos totales
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM db_portafolio..CovidDeaths$
WHERE location like '%colombia%'
order by 1,2

-- Analizar los casos totales de COVID vs Población en Colombia
-- Muestra el porcentaje de contagio por covid con respecto a los casos totales
SELECT location, date, population, total_cases, (total_cases/population)*100 as '%_contagio'
FROM db_portafolio..CovidDeaths$
WHERE location like '%colombia%'
order by 1,2

-- Analizar el país con mayor número de contagios en relación con su población
SELECT location, population, MAX(total_cases) as MayorNumeroInfectados, MAX((total_cases/population))*100 as '%_contagio'
FROM db_portafolio..CovidDeaths$
GROUP BY location, population
ORDER BY '%_contagio' DESC

-- Analizar el país con mayor número de muertes
SELECT location, MAX(cast(total_deaths as int)) as MayorNumeroDeMuertes
FROM db_portafolio..CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY MayorNumeroDeMuertes DESC

-- Analizar por continente el mayor número de muertes
SELECT location, MAX(cast(total_deaths as int)) as MayorNumeroDeMuertes
FROM db_portafolio..CovidDeaths$
WHERE continent is null
GROUP BY location
ORDER BY MayorNumeroDeMuertes DESC

-- Analizar el continente con el mayor número de muertes por población

SELECT location, population, MAX(cast(total_deaths as int)) as muertes
FROM db_portafolio..CovidDeaths$
WHERE continent is null
GROUP BY location, population
ORDER BY muertes DESC

-- Número de nuevos casos por día a nivel mundial
SELECT date, SUM(new_cases) as casos_confirmados, 
	SUM(cast(new_deaths as int)) as muertes, 
	SUM(cast(new_deaths as int))
	/SUM(new_cases)*100 as porcentaje_de_muertes
FROM db_portafolio..CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 4 DESC -- Necesito encontrar el día mas crítico a nivel mundial con respecto al porcentaje de muertes

-- Analizar población vs vacunaciones

SELECT dea.date, dea.continent, dea.location, dea.population, vac.new_vaccinations
FROM db_portafolio..CovidDeaths$ dea
JOIN db_portafolio..CovidVaccinations$ vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.date, dea.location

-- Pais con mayor número de vacunaciones
SELECT dea.date, dea.location, dea.population, SUM(cast(vac.new_vaccinations as int)) as vacunaciones_totales
FROM db_portafolio..CovidDeaths$ dea
JOIN db_portafolio..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL 
GROUP BY dea.date, dea.location, dea.population
ORDER BY vacunaciones_totales DESC 

-- Pais con mayor número de vacunaciones acumuladas por población, es decir, el porcentaje de vacunación acumulada con respecto a la población total
SELECT dea.date, dea.location, dea.continent, 
	dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, -- Esto permite que se muestre la suma de vacunaciones por dia y a su lado el total de vacunados por zona
	dea.date)
	as vacunaciones_totales
--	(vacunaciones_totales/dea.population)*100
FROM db_portafolio..CovidDeaths$ dea
JOIN db_portafolio..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,1 

-- Porcentaje de vacunados por población usando CTE
-- DROP TABLE IF EXISTS #porcentaje_de_poblacion_vacunada

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, vacunaciones_totales)
as 
(
SELECT dea.date, dea.location, dea.continent, 
	dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, -- Esto permite que se muestre la suma de vacunaciones por dia y a su lado el total de vacunados por zona
	dea.date)
	as vacunaciones_totales
FROM db_portafolio..CovidDeaths$ dea
JOIN db_portafolio..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT * , (vacunaciones_totales/Population)*100 as porcentaje_vacunados
FROM PopvsVac
ORDER BY 2,1 

-- TEMP TABLE
CREATE TABLE #porcentaje_de_poblacion_vacunada
(
	Continent NVARCHAR(255),
	Location NVARCHAR(255),
	Date DATETIME,
	Population NUMERIC,
	New_Vaccinations NUMERIC,
	Vacunaciones_Totales NUMERIC
)
Insert into #porcentaje_de_poblacion_vacunada
SELECT dea.continent, dea.location, dea.date, 
	dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, -- Esto permite que se muestre la suma de vacunaciones por dia y a su lado el total de vacunados por zona
	dea.date)
	as vacunaciones_totales
FROM db_portafolio..CovidDeaths$ dea
JOIN db_portafolio..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * , (vacunaciones_totales/Population)*100 as porcentaje_vacunados
FROM #porcentaje_de_poblacion_vacunada
order BY 3,2


-- Creando una view

CREATE VIEW porcentaje_de_poblacion_vacunada as
SELECT dea.continent, dea.location, dea.date, 
	dea.population, vac.new_vaccinations,
	SUM(CONVERT(INT, vac.new_vaccinations)) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, -- Esto permite que se muestre la suma de vacunaciones por dia y a su lado el total de vacunados por zona
	dea.date)
	as vacunaciones_totales
FROM db_portafolio..CovidDeaths$ dea
JOIN db_portafolio..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND  dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * , (vacunaciones_totales/Population)*100 as porcentaje_vacunados
FROM porcentaje_de_poblacion_vacunada
order BY 3,2