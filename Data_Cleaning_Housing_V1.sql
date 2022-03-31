-- This project will focus on cleaning technniques in SQL

SELECT *
FROM [Portfolio Project Housing]..Housing

-- Standardize Sale Date 

SELECT *
FROM [Portfolio Project Housing]..Housing

ALTER TABLE Housing
ADD SaleDateConverted Date

UPDATE Housing
SET SaleDateConverted = CONVERT(Date, SaleDate)

-- Populating the PropertyAddress Data

SELECT *
FROM [Portfolio Project Housing]..Housing
ORDER BY ParcelID

--- We notice that rows with duplicate ParcelIDs also share the same Property Address. We can use that to populate the NULL PropertyAddress cells

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM [Portfolio Project Housing]..Housing AS a
JOIN [Portfolio Project Housing]..Housing AS b
	ON a.ParcelID = b.ParcelID AND
	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--- We now have a PropertyAddress for the NULL values, we just need to write a query to populate them

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Portfolio Project Housing]..Housing AS a
JOIN [Portfolio Project Housing]..Housing AS b
	ON a.ParcelID = b.ParcelID AND
	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM [Portfolio Project Housing]..Housing AS a
JOIN [Portfolio Project Housing]..Housing AS b
	ON a.ParcelID = b.ParcelID AND
	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Breaking out PropertyAddress into individual columns for Address and City

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM [Portfolio Project Housing]..Housing

ALTER TABLE Housing
ADD PropertySplitAddress NVARCHAR (255)

UPDATE Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE Housing
ADD PropertySplitCity NVARCHAR (255)

UPDATE Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- Breaking out OwnerAddress into individual columns for Address, City, and State

SELECT ownerAddress
FROM [Portfolio Project Housing]..Housing

SELECT
PARSENAME (REPLACE(OwnerAddress, ',','.') ,3),
PARSENAME (REPLACE(OwnerAddress, ',','.') ,2),
PARSENAME (REPLACE(OwnerAddress, ',','.') ,1)
FROM [Portfolio Project Housing]..Housing

ALTER TABLE Housing
ADD OwnerSplitAddress NVARCHAR (255)

UPDATE Housing
SET OwnerSplitAddress = PARSENAME (REPLACE(OwnerAddress, ',','.') ,3)

ALTER TABLE Housing
ADD OwnerSplitCity NVARCHAR (255)

UPDATE Housing
SET OwnerSplitCity = PARSENAME (REPLACE(OwnerAddress, ',','.') ,2)

ALTER TABLE Housing
ADD OwnerSplitState NVARCHAR (255)

UPDATE Housing
SET OwnerSplitState = PARSENAME (REPLACE(OwnerAddress, ',','.') ,1)


-- Replace Y and N in SoldAsVacant to Yes and No, Respectively

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM [Portfolio Project Housing]..Housing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM [Portfolio Project Housing]..Housing

UPDATE Housing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

-- Now we will remove duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
FROM [Portfolio Project Housing]..Housing
)
DELETE
FROM RowNumCTE
WHERE Row_Num > 1


-- We will now delete unused columns

SELECT *
FROM [Portfolio Project Housing]..Housing

ALTER TABLE [Portfolio Project Housing]..Housing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict

ALTER TABLE [Portfolio Project Housing]..Housing
DROP COLUMN SaleDate