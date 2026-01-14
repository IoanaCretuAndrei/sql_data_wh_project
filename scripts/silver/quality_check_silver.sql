/*
Script Purpose: 
    This script performs various quality checks for data consistency,accuracy and standarization 
    across the 'silver' schema. It includes checks for: 
        >>Null or duplicate primary keys
        >>unwantes spaces
        >>Date standarization
        >>Invalid ranges
        >> Data consistency between related fields
*/


/*
=====================================================================
crm.cust_info
======================================================================
*/

--El cliente se ha registrado varias veces. Nos interesa la información más reciente, del último registro. Para ello se usan funciones ventana y rankings
--Con este codigo se seleccionan solo los registros mas recientes

PRINT '>> Truncating Table: silver.crm_cust_info'
TRUNCATE TABLE silver.crm_cust_info;

PRINT'>>Inserting Data Into: silver.crm_cust_info'
INSERT INTO silver.crm_cust_info(
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date)

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname,
TRIM(cst_lastname) AS cst_lastname,
CASE 
     WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
     WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
END cst_marital_status,
CASE 
     WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
     WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
END cst_gndr,

cst_create_date
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY cst_id
            ORDER BY cst_create_date DESC
        ) AS flag_last
    FROM bronze.crm_cust_info
) t WHERE flag_last = 1

--Check for unwanted spaces
-- 

SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)

SELECT cst_lastname
FROM silver.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname)


/*
=====================================================================
crm.prd_info
======================================================================
*/

--Selecting useful new columns for joins
PRINT '>> Truncating Table: silver.crm_prd_info'
TRUNCATE TABLE silver.crm_prd_info;

PRINT'>>Inserting Data Into: silver.crm_prd_info'
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT 
    prd_id,
    REPLACE(SUBSTRING(prd_key, 1, 5), '-','_') AS cat_id, --se elige la columna prd_key, empezando en la posicion 1 extrae los 5 primeros caracteres. 
    SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
    prd_nm, 
    ISNULL(prd_cost,0) AS prd_cost,
    CASE
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_stard_dt,
    CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS DATE) AS prd_end_dt
FROM bronze.crm_prd_info

--Check for duplicates or nulls in the promary key

SELECT prd_id, COUNT (*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT (*) > 1 OR prd_id IS NULL;

--Check for unwanted Spaces
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm);

--Check for NULLS or Negative numbers
--Replace NULLS with 0 in upper section. 

SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL; 

--Data Standarization and consistency

SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;


--Check for invalid date orders

SELECT * 
FROM bronze.crm_prd_info
WHERE prd_end_date<prd_start_dt;


SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details


--Check invalid dates
 

 /*
=====================================================================
crm.sales_details
======================================================================
*/

PRINT '>> Truncating Table: silver.crm_sales_details'
TRUNCATE TABLE silver.crm_sales_details;

PRINT'>>Inserting Data Into: silver.crm_sales_details'
INSERT INTO silver.crm_sales_details(
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price 
)
SELECT 
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE 
    WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8 THEN NULL
    ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
END AS sls_order_dt,
CASE
    WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8 THEN NULL
    ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
END AS sls_ship_dt,
CASE
    WHEN sls_due_dt = 0 OR LEN (sls_due_dt) <> 8 THEN NULL
    ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
END AS sls_due_dt,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
    ELSE sls_sales
END AS sls_sales,
sls_quantity,
CASE WHEN sls_price IS NULL or sls_price <= 0 
         THEN sls_sales/NULLIF(sls_quantity,0)
     ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details;


-- Check Invalid Dates

SELECT 
NULLIF(sls_order_dt,0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR LEN (sls_order_dt) <> 8
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101;

SELECT 
NULLIF(sls_ship_dt,0) sls_ship_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 OR LEN (sls_ship_dt) <> 8
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101;

SELECT 
NULLIF(sls_due_dt,0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 OR LEN (sls_due_dt) <> 8
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101;

-- Check invalid Dare Orders

SELECT 
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_due_dt;

--Check data consistency, considering: 
--  >> Sales= Quantity x Price
--  >> Values must not be NULL, zero or negative

SELECT
sls_quantity,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
    ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL or sls_price <= 0 
         THEN sls_sales/NULLIF(sls_quantity,0)
     ELSE sls_price
END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_quantity;
--Changes we have to do: 
-->>If sales is negative, zero or null, derive using quantity and price
-->>If price is zero or null, calculate it using sales and quantity
-->>If price is negative, convert it to a positive value



 /*
=====================================================================
erp_cust_az12
======================================================================
*/
PRINT '>> Truncating Table: silver.erp_cust_az12'
TRUNCATE TABLE silver.erp_cust_az12;

PRINT'>>Inserting Data Into: silver.erp_cust_az12'
INSERt INTO silver.erp_cust_az12 (cid, bdate, gen)
SELECT 
CASE 
    WHEN cid LIKE 'NAS%' THEN SUBSTRING (cid, 4, LEN(cid))
    ELSE cid
END  AS cid,
CASE WHEN bdate > GETDATE() THEN NULL
    ELSE bdate
END AS bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
    WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
    ELSE 'n/a'
END AS gen
FROM bronze.erp_cust_az12;


--Check birth date

SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE();

--We have future birth dates. 

--Check gender

SELECT DISTINCT 
gen
FROM silver.erp_cust_az12;


 /*
=====================================================================
erp_loc_a101
======================================================================
*/
PRINT '>> Truncating Table: silver.erp_loc_a101'
TRUNCATE TABLE silver.erp_loc_a101;

PRINT'>>Inserting Data Into: silver.erp_loc_a101'
INSERT INTO silver.erp_loc_a101(cid,cntry)
SELECT 
REPLACE(cid,'-','') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
     WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
     WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
     ELSE TRIM(cntry)
END AS cntry
FROM bronze.erp_loc_a101

--Data Standarization and Consistency

SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

 /*
=====================================================================
erp_px_cat_g1v2
======================================================================
*/
PRINT '>> Truncating Table: silver.erp_px_cat_g1v2'
TRUNCATE TABLE silver.erp_px_cat_g1v2;

PRINT'>>Inserting Data Into: silver.erp_px_cat_g1v2'
INSERT INTO silver.erp_px_cat_g1v2
(id,cat,subcat,maintenance)

SELECT 
id,
cat,
subcat,
maintenance
FROM bronze.erp_px_cat_g1v2

--Check for unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat <> TRIM (cat) OR subcat <> TRIM(subcat) OR maintenance <> TRIM(maintenance)

--Check data standarization
SELECT DISTINCT 
cat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT 
subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT 
maintenance
FROM bronze.erp_px_cat_g1v2;


SELECT * FROM silver.erp_px_cat_g1v2;
