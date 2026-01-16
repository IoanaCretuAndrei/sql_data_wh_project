# 📊 Proyecto Data Warehouse

## 📌 Descripción general

Este proyecto implementa un **Data Warehouse en SQL** siguiendo una arquitectura por capas **Bronze / Silver / Gold**.  
El objetivo es transformar datos operacionales de clientes, productos y compras (artículos de montaña/deporte) en un modelo analítico confiable, consistente y listo para consumo por herramientas de BI o análisis avanzado.

El diseño prioriza:

- Trazabilidad de los datos  
- Separación clara de responsabilidades por capa  
- Reprocesabilidad y control de calidad  

---

## 🏗️ Arquitectura del Data Warehouse

El Data Warehouse se organiza en tres capas claramente diferenciadas: **Bronze**, **Silver** y **Gold**, cada una con una responsabilidad específica dentro del pipeline analítico.

---

### 🔹 Bronze Layer (Raw / Ingesta)

**Objetivo:** almacenar los datos originales tal como provienen de los sistemas fuente, sin transformaciones de negocio.

**Tablas disponibles en Bronze:**

- `crm.cus_info` – información básica de clientes (CRM)
- `crm_prd_info` – información de productos
- `crm_sales_details` – detalle de ventas / transacciones
- `erp.cust_az12` – información adicional de clientes (ERP)
- `erp_loc_a101` – datos de localización / región
- `erp_px_cat_g1v2` – catálogo y categorización de productos

**Características:**

- Datos crudos (raw)
- Puede contener duplicados, inconsistencias y valores nulos
- Incluye históricos completos
- Sirve como respaldo y punto de reproceso

---

### 🔸 Silver Layer (Cleansed / Conformada)

**Objetivo:** limpiar, estandarizar e integrar los datos provenientes de Bronze.

**Tablas en Silver (mismas entidades que Bronze):**

- `silver.crm_cus_info`
- `silver.crm_prd_info`
- `silver.crm_sales_details`
- `silver.erp_cust_az12`
- `silver.erp_loc_a101`
- `silver.erp_px_cat_g1v2`

**Transformaciones aplicadas:**

- Corrección de inconsistencias de datos
- Tratamiento de valores nulos y datos faltantes
- Normalización de tipos de datos
- Estandarización de formatos (fechas, textos, claves)
- Eliminación de duplicados

La capa Silver contiene datos **confiables y coherentes**, pero sin lógica analítica compleja.

---

### 🟡 Gold Layer (Analytics / Business)

**Objetivo:** exponer datos listos para análisis mediante un **modelo dimensional en estrella (Star Schema)**.

**Estructura Gold:**

**Dimensiones**
- `gold.dim_customers` – clientes consolidados (CRM + ERP)
- `gold.dim_products` – productos y categorías

**Tabla de hechos**
- `gold.fact_sales` – ventas y métricas asociadas

**Características:**

- Joins entre entidades Silver
- Claves analíticas estables
- Métricas de negocio definidas
- Datos optimizados para BI y análisis

---

## 🛠️ Tecnologías utilizadas

- SQL (motor relacional / cloud warehouse)
- Vistas y/o tablas materializadas
- Control de versiones (Git)

