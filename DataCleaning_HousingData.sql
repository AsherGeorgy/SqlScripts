-- 1. Update SaleDate Column to show dates only (exclude time)
-- Convert SaleDate to Date type, removing the time component
SELECT 
    SaleDate, 
    CONVERT(Date, SaleDate)
FROM dbo.NashvilleHousing;

-- Update SaleDate to store only the date (without time)
UPDATE dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate);




-- 2. Fill NULL values in PropertyAddress column
-- Explanation:
-- ParcelID refers to a unique identifier assigned to a specific parcel of land.
-- It corresponds to a single unique property address.
-- A given ParcelID may have multiple UniqueIDs if there are separate units (e.g., apartment complexes) at the same address.
-- Therefore, NULL values in the PropertyAddress column can be filled using a different UniqueID for the same ParcelID.

-- Step 1: Self Join to identify records where PropertyAddress is NULL, but another UniqueID for the same ParcelID has a non-null PropertyAddress
SELECT 
    a.ParcelID, 
    a.PropertyAddress AS PropertyAddress_A, 
    b.ParcelID, 
    b.PropertyAddress AS PropertyAddress_B,
    ISNULL(a.PropertyAddress, b.PropertyAddress) AS FilledPropertyAddress
FROM NashvilleHousing a
INNER JOIN NashvilleHousing b ON a.ParcelID = b.ParcelID  -- Join on ParcelID
    AND a.UniqueID <> b.UniqueID                         -- Ensure different UniqueIDs
WHERE a.PropertyAddress IS NULL;                          -- Target rows with NULL PropertyAddress

-- Step 2: Update PropertyAddress for rows with NULL values using the non-null value from another UniqueID
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
INNER JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;





-- 3. Split PropertyAddress into individual columns: Address and City
-- Explanation: String functions are used to split PropertyAddress into Address and City

-- Sample Query to preview the splitting:
SELECT 
    PropertyAddress,
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1) - 1) AS Address, 
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress, 1) + 1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing;

-- Step 1: Add Address column and update it with the Address part of PropertyAddress
ALTER TABLE NashvilleHousing
ADD Address NVARCHAR(255);

UPDATE NashvilleHousing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress, 1) - 1);

-- Step 2: Add City column and update it with the City part of PropertyAddress
ALTER TABLE NashvilleHousing
ADD City NVARCHAR(255);

UPDATE NashvilleHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress, 1) + 1, LEN(PropertyAddress));





-- 4. Split OwnerAddress into individual columns: Address, City, State
-- Explanation: The PARSENAME and REPLACE functions are used to split the OwnerAddress into components (Address, City, State)

-- Sample query to preview the splitting:
SELECT 
    OwnerAddress, 
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddressSplit,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM NashvilleHousing;

-- Step 1: Add OwnerSplitAddress column and update it with the Address part of OwnerAddress
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

-- Step 2: Add OwnerCity column and update it with the City part of OwnerAddress
ALTER TABLE NashvilleHousing
ADD OwnerCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

-- Step 3: Add OwnerState column and update it with the State part of OwnerAddress
ALTER TABLE NashvilleHousing
ADD OwnerState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);





-- 5. Update SoldAsVacant 1 to Yes and 0 to No
-- Explanation: The `SoldAsVacant` column values are updated from 1/0 to 'Yes'/'No'

-- Step 1: Check distinct values and counts in the SoldAsVacant column
SELECT 
    DISTINCT(SoldAsVacant), 
    COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant;

-- Step 2: Alter the SoldAsVacant column to varchar data type for storing 'Yes'/'No'
ALTER TABLE NashvilleHousing
ALTER COLUMN SoldAsVacant VARCHAR(10);

-- Step 3: Update the SoldAsVacant column using a CASE statement
UPDATE NashvilleHousing
SET SoldAsVacant = 
    CASE 
        WHEN SoldAsVacant = 0 THEN 'No'
        WHEN SoldAsVacant = 1 THEN 'Yes'
    END;





-- 6. Remove duplicates based on ParcelID, PropertyAddress, SalePrice, SaleDate, and LegalReference
-- Explanation: A CTE is created to assign a row number to duplicate rows,
-- and rows with row_number greater than 1 are deleted, keeping only the first occurrence.

WITH RowNumCTE AS (
    SELECT 
        UniqueID,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, 
                         PropertyAddress, 
                         SalePrice, 
                         SaleDate, 
                         LegalReference  -- Partition by these columns
            ORDER BY UniqueID  -- Order by UniqueID to keep the first occurrence
        ) AS row_num
    FROM NashvilleHousing
)

-- Step 2: Delete duplicates where row_number > 1
DELETE NH
FROM NashvilleHousing NH
JOIN RowNumCTE RCTE ON NH.UniqueID = RCTE.UniqueID
WHERE RCTE.row_num > 1;





-- 7. Delete redundant or unwanted columns
-- Explanation: Columns that are no longer needed in the table are dropped.

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
