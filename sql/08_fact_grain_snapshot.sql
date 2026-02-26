USE WAREHOUSE COMPUTE_WH;
USE DATABASE SNOWFLAKE_LEARNING_DB;

CREATE OR REPLACE TABLE GOLD.MONTHLY_SALES AS
SELECT
    DATE_TRUNC('month', transaction_date) AS sales_month,
    SUM(sales_price) AS total_sales
FROM SILVER.FACT_SALES
GROUP BY sales_month;

DROP TABLE IF EXISTS SILVER.FACT_SALES;
DROP TABLE IF EXISTS SILVER.FACT_STAGE;
DROP TABLE IF EXISTS SILVER.CUSTOMER_DIM;
DROP TABLE IF EXISTS SILVER.STORE_SALES_ENRICHED;

CREATE OR REPLACE TABLE SILVER.CUSTOMER_DIM (
    customer_sk NUMBER AUTOINCREMENT,
    customer_id NUMBER,
    state STRING,
    start_date DATE,
    end_date DATE,
    is_current STRING
);

INSERT INTO SILVER.CUSTOMER_DIM
(customer_id, state, start_date, end_date, is_current)
SELECT
    c.c_customer_sk,
    ca.ca_state,
    '1900-01-01',   -- critical fix
    NULL,
    'Y'
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER c
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER_ADDRESS ca
    ON c.c_current_addr_sk = ca.ca_address_sk;

    SELECT COUNT(*) FROM SILVER.CUSTOMER_DIM;

    CREATE OR REPLACE TABLE SILVER.STORE_SALES_ENRICHED AS
SELECT
    ss.ss_customer_sk AS customer_id,
    ss.ss_store_sk    AS store_id,
    ss.ss_sales_price AS sales_price,
    d.d_date          AS transaction_date
FROM SILVER.STORE_SALES_CLEAN ss
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.DATE_DIM d
    ON ss.ss_sold_date_sk = d.d_date_sk;

    SELECT COUNT(*) FROM SILVER.STORE_SALES_ENRICHED;

    CREATE OR REPLACE TABLE SILVER.FACT_SALES AS
SELECT
    d.customer_sk,
    f.store_id,
    f.sales_price,
    f.transaction_date
FROM SILVER.STORE_SALES_ENRICHED f
JOIN SILVER.CUSTOMER_DIM d
    ON f.customer_id = d.customer_id
    AND f.transaction_date >= d.start_date
    AND (f.transaction_date < d.end_date OR d.end_date IS NULL);

    SELECT COUNT(*) FROM SILVER.FACT_SALES;