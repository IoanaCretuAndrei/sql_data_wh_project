/*

=============================================================================
DDL Script: Creates Gold Views
=============================================================================

Script Purpose: 
  This script creates views for the gold layer in the data warehous. 
  The Gold layer represents the final dimension and fact tables (Star Schema)
==============================================================================
*/


-- ----------------------------------------
-- >>Customer dimension: gold.dim_customer
-- ----------------------------------------

CREATE  OR ALTER VIEW gold.dim_customers AS
SELECT
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
		la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		ELSE COALESCE (ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci 
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key= ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid

--Check data integration

SELECT DISTINCT
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
		ELSE COALESCE (ca.gen, 'n/a')
	END AS new_gen
FROM silver.crm_cust_info ci 
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key= ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid
ORDER BY 1,2


-- ----------------------------------------
-- >>Product dimension: gold.dim_product
-- ----------------------------------------
CREATE OR ALTER VIEW gold.dim_product AS
SELECT
pn.prd_id AS product_id,
pn.prd_key AS product_key,
pn.prd_nm AS product_name,
pn.cat_id AS category_id,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL  --filter out historical data


--Check for duplicates

SELECT prd_key, COUNT(*) FROM
(SELECT
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
pn.prd_end_dt,
pc.subcat,
pc.maintenance
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL  --filter out historical data
)t GROUP BY prd_key
HAVING COUNT(*) >1



-- ----------------------------------------
-- >>Sales fact: gold.fact_sales
-- ----------------------------------------
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT 
sd.sls_ord_num AS order_number,
sd.sls_prd_key AS product_key,
pr.product_name,
cu.customer_number,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_product pr
ON sd.sls_prd_key= pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id=cu.customer_id
