
-- =====================================================
-- 1) Dimension Tables
-- =====================================================

CREATE TABLE dim_customer (
    customer_id        INT PRIMARY KEY,
    customer_key       VARCHAR(30),
    customer_name      VARCHAR(100),
    country            VARCHAR(50),
    channel_type       VARCHAR(30),
    size               VARCHAR(20),
    annual_volume_usd  BIGINT
);

CREATE TABLE dim_date (
    date_key     INT PRIMARY KEY,
    date         DATE,
    year         SMALLINT,
    quarter      SMALLINT,
    month        SMALLINT,
    month_name   VARCHAR(15),
    week         SMALLINT,
    day          SMALLINT,
    day_of_week  SMALLINT,
    day_name     VARCHAR(15),
    is_weekend   SMALLINT
);

CREATE TABLE dim_facility (
    facility_id     INT PRIMARY KEY,
    facility_key    VARCHAR(30),
    facility_name   VARCHAR(100),
    country         VARCHAR(50),
    city            VARCHAR(50),
    facility_type   VARCHAR(30),
    specialization  VARCHAR(50),
    annual_capacity INT
);

CREATE TABLE dim_product (
    product_id    INT PRIMARY KEY,
    product_key   VARCHAR(30),
    product_name  VARCHAR(100),
    category      VARCHAR(30),
    product_line  VARCHAR(30),
    spec          VARCHAR(30),
    color         VARCHAR(30),
    unit_price    NUMERIC(10,2),
    unit_cost     NUMERIC(10,2),
    weight_kg     NUMERIC(8,2),
    Img           TEXT
);

CREATE TABLE dim_supplier (
    supplier_id         INT PRIMARY KEY,
    supplier_key        VARCHAR(30),
    supplier_name       VARCHAR(100),
    country             VARCHAR(50),
    city                VARCHAR(50),
    specialty           VARCHAR(50),
    tier                VARCHAR(10),
    avg_quality_score   NUMERIC(5,2)
);


-- =====================================================
-- 2) Fact Tables
-- =====================================================

CREATE TABLE fact_sales (
    sales_id           INT PRIMARY KEY,
    date_key           INT REFERENCES dim_date(date_key),
    product_id         INT REFERENCES dim_product(product_id),
    customer_id        INT REFERENCES dim_customer(customer_id),
    quantity_sold      INT,
    unit_price         NUMERIC(10,2),
    discount_pct       NUMERIC(5,2),
    discount_amount    NUMERIC(14,2),
    gross_revenue      NUMERIC(14,2),
    net_revenue        NUMERIC(14,2),
    total_cost         NUMERIC(14,2),
    profit             NUMERIC(14,2),
    profit_margin_pct  NUMERIC(6,2),
    order_number       VARCHAR(30)
);

CREATE TABLE fact_procurement (
    procurement_id     INT PRIMARY KEY,
    order_date_key     INT REFERENCES dim_date(date_key),
    product_id         INT REFERENCES dim_product(product_id),
    supplier_id        INT REFERENCES dim_supplier(supplier_id),
    order_quantity     INT,
    unit_cost          NUMERIC(10,2),
    total_cost         NUMERIC(14,2),
    lead_time_days     INT,
    delivery_date_key  INT REFERENCES dim_date(date_key),
    quality_score      NUMERIC(5,2),
    po_number          VARCHAR(30)
);

CREATE TABLE fact_production (
    production_id      INT PRIMARY KEY,
    date_key           INT REFERENCES dim_date(date_key),
    product_id         INT REFERENCES dim_product(product_id),
    facility_id        INT REFERENCES dim_facility(facility_id),
    quantity_produced  INT,
    defective_units    INT,
    defect_rate_pct    NUMERIC(6,2),
    batch_number       VARCHAR(30)
);

CREATE TABLE fact_inventory (
    inventory_id        INT PRIMARY KEY,
    date_key            INT REFERENCES dim_date(date_key),
    product_id          INT REFERENCES dim_product(product_id),
    facility_id         INT REFERENCES dim_facility(facility_id),
    stock_level         INT,
    safety_stock_level  INT,
    reorder_point       INT
);

CREATE TABLE fact_shipment (
    shipment_id        INT PRIMARY KEY,
    ship_date_key      INT REFERENCES dim_date(date_key),
    delivery_date_key  INT REFERENCES dim_date(date_key),
    product_id         INT REFERENCES dim_product(product_id),
    facility_id        INT REFERENCES dim_facility(facility_id),
    customer_id        INT REFERENCES dim_customer(customer_id),
    quantity           INT,
    carrier            VARCHAR(40),
    status             VARCHAR(20),
    shipping_cost      NUMERIC(12,2),
    total_weight_kg    NUMERIC(12,2),
    tracking_number    VARCHAR(40),
    delay_reason       VARCHAR(40)
);


-- =====================================================
-- 3) View All Tables
-- =====================================================

SELECT * FROM dim_customer;
SELECT * FROM dim_date;
SELECT * FROM dim_facility;
SELECT * FROM dim_product;
SELECT * FROM dim_supplier;

SELECT * FROM fact_inventory;
SELECT * FROM fact_procurement;
SELECT * FROM fact_production;
SELECT * FROM fact_sales;
SELECT * FROM fact_shipment;
