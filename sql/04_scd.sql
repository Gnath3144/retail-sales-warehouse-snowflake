DESC TABLE SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER;
DESC TABLE SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER_ADDRESS;


USE WAREHOUSE COMPUTE_WH;
USE DATABASE SNOWFLAKE_LEARNING_DB;


CREATE OR REPLACE TABLE SILVER.CUSTOMER_DIM (
    customer_sk NUMBER AUTOINCREMENT,
    customer_id NUMBER,
    state STRING,
    start_date DATE,
    end_date DATE,
    is_current STRING
);

-- initial load

INSERT INTO SILVER.CUSTOMER_DIM
(customer_id, state, start_date, end_date, is_current)
SELECT
    c.c_customer_sk,
    ca.ca_state,
    CURRENT_DATE,
    NULL,
    'Y'
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER c
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF100TCL.CUSTOMER_ADDRESS ca
    ON c.c_current_addr_sk = ca.ca_address_sk;

    SELECT COUNT(*) FROM SILVER.CUSTOMER_DIM;

    SELECT * FROM SILVER.CUSTOMER_DIM LIMIT 5;

    -- create a small stage
CREATE OR REPLACE TABLE SILVER.CUSTOMER_STAGE AS
SELECT customer_id, state
FROM SILVER.CUSTOMER_DIM
WHERE is_current = 'Y';

-- mannually update one row
UPDATE SILVER.CUSTOMER_STAGE
SET state = 'TX'
WHERE customer_id = 79911230;

-- implement stage 2 using merge

MERGE INTO SILVER.CUSTOMER_DIM target
USING SILVER.CUSTOMER_STAGE source
ON target.customer_id = source.customer_id
AND target.is_current = 'Y'

WHEN MATCHED AND target.state <> source.state THEN
UPDATE SET
    target.end_date = CURRENT_DATE,
    target.is_current = 'N'

WHEN NOT MATCHED THEN
INSERT (customer_id, state, start_date, end_date, is_current)
VALUES (source.customer_id, source.state, CURRENT_DATE, NULL, 'Y');

-- validate SCD behaviour
SELECT *
FROM SILVER.CUSTOMER_DIM
WHERE customer_id = 79911230
ORDER BY start_date;