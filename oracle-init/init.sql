-- Connect to pluggable database
ALTER SESSION SET CONTAINER = DEMOPDB;

-- Create monitoring user for Grafana Integration
CREATE USER grafanau IDENTIFIED BY oracle;
GRANT CONNECT TO grafanau;

-- Grant required permissions for metrics collection
GRANT SELECT ON SYS.GV_$RESOURCE_LIMIT TO grafanau;
GRANT SELECT ON SYS.V_$SESSION TO grafanau;
GRANT SELECT ON SYS.V_$WAITCLASSMETRIC TO grafanau;
GRANT SELECT ON SYS.GV_$PROCESS TO grafanau;
GRANT SELECT ON SYS.GV_$SYSSTAT TO grafanau;
GRANT SELECT ON SYS.V_$DATAFILE TO grafanau;
GRANT SELECT ON SYS.V_$ASM_DISKGROUP_STAT TO grafanau;
GRANT SELECT ON SYS.V_$SYSTEM_WAIT_CLASS TO grafanau;
GRANT SELECT ON SYS.DBA_TABLESPACE_USAGE_METRICS TO grafanau;
GRANT SELECT ON SYS.DBA_TABLESPACES TO grafanau;
GRANT SELECT ON SYS.GLOBAL_NAME TO grafanau;

-- Additional grants for full access
GRANT SELECT_CATALOG_ROLE TO grafanau;
GRANT SELECT ANY DICTIONARY TO grafanau;

-- Create demo schema
CREATE USER demo_user IDENTIFIED BY oracle;
GRANT CONNECT, RESOURCE TO demo_user;
GRANT UNLIMITED TABLESPACE TO demo_user;
GRANT EXECUTE ON SYS.DBMS_LOCK TO demo_user;

-- Switch to demo_user schema
ALTER SESSION SET CURRENT_SCHEMA = demo_user;

-- Create sample tables
CREATE TABLE sales (
    id NUMBER PRIMARY KEY,
    product VARCHAR2(100),
    amount NUMBER,
    sale_date DATE
);

CREATE TABLE customers (
    id NUMBER PRIMARY KEY,
    name VARCHAR2(200),
    email VARCHAR2(200)
);

-- Create sequences for primary keys
CREATE SEQUENCE sales_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE customers_seq START WITH 1 INCREMENT BY 1;

-- Create load generator procedure
CREATE OR REPLACE PROCEDURE generate_load AS
    v_count NUMBER := 0;
    v_dummy NUMBER;
BEGIN
    LOOP
        -- Insert operations
        INSERT INTO sales VALUES (sales_seq.NEXTVAL, 'Product_' || v_count, DBMS_RANDOM.VALUE(10, 1000), SYSDATE);
        INSERT INTO customers VALUES (customers_seq.NEXTVAL, 'Customer_' || v_count, 'email_' || v_count || '@demo.com');

        -- Select operations
        SELECT COUNT(*) INTO v_dummy FROM sales WHERE amount > 500;

        -- Update operations
        UPDATE sales SET amount = amount * 1.1 WHERE MOD(id, 10) = 0;

        COMMIT;

        -- Small delay
        DBMS_LOCK.SLEEP(1);

        v_count := v_count + 1;

        -- Exit after 1000 iterations to avoid infinite loop
        EXIT WHEN v_count > 1000;
    END LOOP;
END;
/

EXIT;
