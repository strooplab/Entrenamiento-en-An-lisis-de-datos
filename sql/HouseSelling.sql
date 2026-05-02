--************************************************************************************
----****  HOUSE SELLING DATASET ANALYSIS - ANÁLISIS DE DATASET VENTA DE CASAS   ****
--************************************************************************************
--************************************************************************************
----****	By: STROOPLAB												****
----****    Inspired: Alex The Analyst (Youtube.com)								****
--************************************************************************************
--------------------------------------------------------------------------------------
-- 1) Cleaning Dataset - Limpieza del dataset

SELECT TOP(100) *
FROM dbo.Casas;

-- Vemos algunas columnas que pueden dividirse para una mejor interpretación
-- de los datos que tenemos. Empezaremos con la columna SaleDate, ya que parece no registrar correctamente
-- las horas, solo los dias nos interesan.

SELECT SaleDate, CONVERT(Date, SaleDate) as SimpleDate -- Conversión a solo fecha
FROM db_casas.dbo.Casas;

-- Creamos una columna formateada (Date)
ALTER TABLE Casas
ADD SimpleDate Date;

-- Aplicamos los cambios en la nueva columna
UPDATE Casas
SET SimpleDate = CONVERT(Date, SaleDate);

--------------------------------------------------------------------------------------
-- Limpir valores nulos en columna PropertyAddress


SELECT * -- Identificamos que hay valores nulos
FROM db_casas.dbo.Casas
WHERE PropertyAddress is null;

-- Al ser una columna tipo string que almacena las direcciones de las propiedades
-- no es posible reemplazar los valores nulos con ceros, debemos buscar un patrón que nos
-- permita manejar estos valores nulos.

SELECT * 
FROM db_casas.dbo.Casas
ORDER BY ParcelID;

-- UniqueID no se repite, pero ParcelID sí, esto puede ayudarnos a cumplir la tarea pendiente
-- ParcelID tiene varios registros repetidos, y en ellos siempre coincide la dirección de propiedad
-- Lo que debemos hacer es seguir la lógica sql y hacer un join on en ParcelID
-- donde el UniqueID no sea el mismo.

SELECT Casa1.ParcelID, Casa1.PropertyAddress, Casa2.ParcelID, Casa2.PropertyAddress, ISNULL(Casa1.PropertyAddress, Casa2.PropertyAddress)
FROM db_casas.dbo.Casas as Casa1
JOIN db_casas.dbo.Casas as Casa2
ON Casa1.ParcelID = Casa2.ParcelID -- Mismo ParcelID
AND Casa1.[UniqueID ] <> Casa2.[UniqueID ] -- Diferente UniqueID
WHERE Casa1.PropertyAddress is null;

-- Ya teniendo la columna que necesitabamos, podemos aplicar los cambios

UPDATE Casa1
SET PropertyAddress = ISNULL(Casa1.PropertyAddress, Casa2.PropertyAddress) -- Aplicamos de acuerdo a la condición
FROM db_casas.dbo.Casas as Casa1
JOIN db_casas.dbo.Casas as Casa2
ON Casa1.ParcelID = Casa2.ParcelID 
AND Casa1.[UniqueID ] <> Casa2.[UniqueID ] 
WHERE Casa1.PropertyAddress is null;

-- Finalmente, comprobamos que los cambios se aplicaron

SELECT PropertyAddress
FROM db_casas.dbo.Casas
ORDER BY ParcelID;

--------------------------------------------------------------------------------------
-- Separar valores en varias columnas de PropertyAddress

SELECT PropertyAddress
FROM db_casas.dbo.Casas;

-- Para separar debemos ver un patrón común que repitan todas las celdas.
-- En este caso vemos dirección y ciudad separado por comas. 
-- Podemos usar substring para separar ambos elementos en columnas diferentes

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)) AS Address
FROM db_casas.dbo.Casas;

-- Este query funciona, pero no queremos que se incluya la división

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1 ) AS Address, -- Cada carácter tiene un index, por tanto podemos simplemente tomar el valor antes de la coma restando 1 al resultado
SUBSTRING(PropertyAddress, CHARINDEX(', ', PropertyAddress) + 1,  LEN(PropertyAddress)) AS City -- Ciudad. El limite inferior debe empezar despues de la coma hasta el final, usamo el tamaño de Property
FROM db_casas.dbo.Casas;

ALTER TABLE dbo.Casas
ADD PropertyAddressNumber NVARCHAR(255); -- Creación de columna Address

ALTER TABLE dbo.Casas
ADD PropertyCity NVARCHAR(255); -- Creación de columna City

-- Insertamos los datos como registros para columna Address
UPDATE dbo.Casas
SET PropertyAddressNumber = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1 );

-- Y hacemos lo mismo para City
UPDATE dbo.Casas
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 2,  LEN(PropertyAddress)); 

-- Comprobamos los cambios
SELECT * 
FROM Casas;

--------------------------------------------------------------------------------------
-- Separar columnas de OwnerAddress

SELECT OwnerAddress
FROM db_casas.dbo.Casas;

-- Aquí debemos usar un mejor método de separación, esta vez son 3 datos que podemos dividir

-- Intentemos con PARSENAME, aunque solo funciona con puntos, podemos reemplazar las comas por puntos y aun así tener un query mejor optimizado

SELECT
PARSENAME(REPLACE(OwnerAddress,',', '.'),1) as State,
PARSENAME(REPLACE(OwnerAddress,',', '.'),2) as City,
PARSENAME(REPLACE(OwnerAddress,',', '.'),3) as Address
FROM dbo.Casas

ALTER TABLE dbo.Casas
ADD OwnerNumberAddress NVARCHAR(255); -- Creación de columna OwnerAddressNumber

ALTER TABLE dbo.Casas
ADD OwnerCity NVARCHAR(255); -- Creación de columna OwnerCity

ALTER TABLE dbo.Casas
ADD OwnerState NVARCHAR(255); -- Creación de columna OwnerState

-- Insertamos los datos como registros para columna OwnerNumberAddress
UPDATE dbo.Casas
SET OwnerNumberAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'),3);

-- Y hacemos lo mismo para OwnerCity
UPDATE dbo.Casas
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress,',', '.'),2); 

UPDATE dbo.Casas
SET OwnerState = PARSENAME(REPLACE(OwnerAddress,',', '.'),1); 

-- Comprobación de cambios
SELECT *
FROM Casas;

--------------------------------------------------------------------------------------
-- Declarar propiedades como vendidas

-- Algo que se notó al revisar las columnas es que hay muchos valores con Y y N
-- Esto resulta confuso al darnos cuenta que hay valores de Yes y No, quebrando el formato
-- que se intenta manejar, cambiaremos estas Y por Yes, y N por No para mayor claridad.

SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) AS Conteo
FROM Casas 
GROUP BY SoldAsVacant
ORDER BY conteo DESC; -- El conteo de Y y N es poco en comparación de Yes y No, lo mejor que podemos hacer es reemplazar estos valores al formato ya establecido

-- Apliquemos un condicional

SELECT DISTINCT SoldAsVacant, -- Agregué esto para que sea más rápido de verificar
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant
     END AS FixedColumn    
FROM Casas; 

-- Aplicamos los cambios
UPDATE Casas
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
     WHEN SoldAsVacant = 'N' THEN 'No'
     ELSE SoldAsVacant
     END;

-- Y comprobamos que haya quedado aplicado
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant) AS Conteo
FROM Casas 
GROUP BY SoldAsVacant
ORDER BY conteo DESC; -- Podemos ver que solo existen dos elementos distintos, el Yes y No, como necesitabamos

SELECT *
FROM Casas;

--------------------------------------------------------------------------------------
-- Remover duplicados

SELECT *
FROM Casas;

-- Debemos hallar registros duplicados
WITH Row_Num AS (
    SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID, -- Dividiendo en particiones
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference
    ORDER BY UniqueID) row_num -- Ordenar por UniqueID
    FROM Casas
)
SELECT * 
FROM Row_Num
WHERE row_num > 1;

-- El Query funciona! entonces usemoslo para eliminar las filas duplicadas
WITH Row_Num AS (
    SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID, 
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference
    ORDER BY UniqueID) row_num 
    FROM Casas
)
DELETE 
FROM Row_Num
WHERE row_num > 1;

-- Comprobamos que no haya ningún duplicado

WITH Row_Num AS (
    SELECT *,
    ROW_NUMBER() OVER (
    PARTITION BY ParcelID, 
    PropertyAddress,
    SalePrice,
    SaleDate,
    LegalReference
    ORDER BY UniqueID) row_num 
    FROM Casas
)
SELECT DISTINCT row_num -- Solo hay valores únicos
FROM Row_Num;

--------------------------------------------------------------------------------------
-- Remover columnas irrelevantes

-- Para optimizar nuestro modelo, podemos eliminar columnas sin uso analítico, o que sepamos que no usariamos ni en un reporte ni ninguna operación

SELECT * 
FROM Casas;

-- Podemos empezar  eliminando las columnas PropertyAddress, OwnerAddress y SaleDate, ya no las necesitamos
ALTER TABLE Casas
DROP COLUMN PropertyAddress, OwnerAddress, SaleDate;

-- Tambien eliminamos la columna TaxDistrict, esta información en un informe de ventas general es poco usado.
ALTER TABLE Casas
DROP COLUMN TaxDistrict;

-- Conclusiones:
-- Hemos limpiado el dataset, eliminando valores nulos, separando columnas para una mejor interpretación, y eliminando columnas irrelevantes.
-- Ahora tenemos un dataset más limpio y optimizado para análisis y reportes.