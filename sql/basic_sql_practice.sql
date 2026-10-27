-- =========================================================
-- SUPPLY CHAIN ANALYTICS PROJECT
-- Database: PostgreSQL
-- =========================================================


-- =========================================================
-- 1. SALES ANALYSIS
-- =========================================================

-- 1. Total Revenue and Profit by Product Category

SELECT
    P.category,
    SUM(S.net_revenue) AS total_revenue,
    SUM(S.profit) AS total_profit
FROM dim_product AS P
INNER JOIN fact_sales AS S
    ON P.product_id = S.product_id
GROUP BY P.category
ORDER BY total_revenue DESC;


-- 2. Top 5 Customers by Total Revenue

SELECT
    C.customer_id,
    C.customer_name,
    SUM(S.net_revenue) AS total_revenue
FROM dim_customer AS C
INNER JOIN fact_sales AS S
    ON C.customer_id = S.customer_id
GROUP BY C.customer_id, C.customer_name
ORDER BY total_revenue DESC
LIMIT 5;


-- 3. Total Revenue and Profit by Product

SELECT
    P.product_name,
    SUM(S.net_revenue) AS total_revenue,
    SUM(S.profit) AS total_profit
FROM dim_product AS P
INNER JOIN fact_sales AS S
    ON P.product_id = S.product_id
GROUP BY P.product_id, P.product_name
ORDER BY total_revenue DESC;


-- 4. Year-wise Sales Trend

SELECT
    EXTRACT(YEAR FROM D.date::DATE) AS sales_year,
    SUM(S.net_revenue) AS total_revenue
FROM dim_date AS D
INNER JOIN fact_sales AS S
    ON D.date_key = S.date_key
GROUP BY EXTRACT(YEAR FROM D.date::DATE)
ORDER BY sales_year;


-- 5. Quarter-wise Revenue Trend

SELECT
    EXTRACT(YEAR FROM D.date::DATE) AS sales_year,
    EXTRACT(QUARTER FROM D.date::DATE) AS sales_quarter,
    SUM(S.net_revenue) AS total_revenue
FROM dim_date AS D
INNER JOIN fact_sales AS S
    ON D.date_key = S.date_key
GROUP BY
    EXTRACT(YEAR FROM D.date::DATE),
    EXTRACT(QUARTER FROM D.date::DATE)
ORDER BY sales_year, sales_quarter;


-- 6. Monthly Revenue and Profit

SELECT
    DATE_TRUNC('month', D.date::DATE)::DATE AS sales_month,
    SUM(S.net_revenue) AS total_revenue,
    SUM(S.profit) AS total_profit
FROM dim_date AS D
INNER JOIN fact_sales AS S
    ON D.date_key = S.date_key
GROUP BY DATE_TRUNC('month', D.date::DATE)
ORDER BY sales_month;


-- 7. Month-over-Month Revenue Growth Using LAG()

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', D.date::DATE)::DATE AS sales_month,
        SUM(S.net_revenue) AS total_revenue
    FROM dim_date AS D
    INNER JOIN fact_sales AS S
        ON D.date_key = S.date_key
    GROUP BY DATE_TRUNC('month', D.date::DATE)
),
previous_sales AS (
    SELECT
        sales_month,
        total_revenue,
        LAG(total_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_revenue
    FROM monthly_sales
)
SELECT
    sales_month,
    total_revenue,
    previous_revenue,
    ROUND(
        (
            (total_revenue - previous_revenue) * 100.0
            / NULLIF(previous_revenue, 0)
        )::NUMERIC,
        2
    ) AS mom_growth_pct
FROM previous_sales
ORDER BY sales_month;


-- 8. Products Ranked by Revenue Within Each Category

SELECT
    P.category,
    P.product_name,
    SUM(S.net_revenue) AS total_revenue,
    RANK() OVER (
        PARTITION BY P.category
        ORDER BY SUM(S.net_revenue) DESC
    ) AS revenue_rank
FROM dim_product AS P
INNER JOIN fact_sales AS S
    ON P.product_id = S.product_id
GROUP BY P.category, P.product_id, P.product_name
ORDER BY P.category, revenue_rank;


-- 9. Products Generating Above-Average Total Revenue

WITH product_sales AS (
    SELECT
        P.product_id,
        P.product_name,
        SUM(S.net_revenue) AS total_revenue
    FROM dim_product AS P
    INNER JOIN fact_sales AS S
        ON P.product_id = S.product_id
    GROUP BY P.product_id, P.product_name
)
SELECT
    product_name,
    total_revenue
FROM product_sales
WHERE total_revenue > (
    SELECT AVG(total_revenue)
    FROM product_sales
)
ORDER BY total_revenue DESC;


-- 10. Total Revenue, Profit and Profit Margin by Category

SELECT
    P.category,
    SUM(S.net_revenue) AS total_revenue,
    SUM(S.profit) AS total_profit,
    ROUND(
        (
            SUM(S.profit) * 100.0
            / NULLIF(SUM(S.net_revenue), 0)
        )::NUMERIC,
        2
    ) AS profit_margin_pct
FROM dim_product AS P
INNER JOIN fact_sales AS S
    ON P.product_id = S.product_id
GROUP BY P.category
ORDER BY profit_margin_pct DESC;


-- 11. Customers with More Than 100 Discounted Sales Records

SELECT
    C.customer_id,
    C.customer_name,
    COUNT(*) AS discounted_orders
FROM dim_customer AS C
INNER JOIN fact_sales AS S
    ON C.customer_id = S.customer_id
WHERE S.discount_pct > 0
GROUP BY C.customer_id, C.customer_name
HAVING COUNT(*) > 100
ORDER BY discounted_orders DESC;


-- =========================================================
-- 2. PRODUCTION ANALYSIS
-- =========================================================

-- 12. Total Production and Average Defect Rate by Facility

SELECT
    F.facility_name,
    SUM(P.quantity_produced) AS total_produced,
    ROUND(AVG(P.defect_rate_pct)::NUMERIC, 2)
        AS avg_defect_rate_pct
FROM dim_facility AS F
INNER JOIN fact_production AS P
    ON F.facility_id = P.facility_id
GROUP BY F.facility_id, F.facility_name
ORDER BY total_produced DESC;


-- 13. Total Production by Product

SELECT
    P.product_name,
    SUM(PR.quantity_produced) AS total_produced
FROM dim_product AS P
INNER JOIN fact_production AS PR
    ON P.product_id = PR.product_id
GROUP BY P.product_id, P.product_name
ORDER BY total_produced DESC;


-- 14. Top 3 Products by Production at Each Facility

WITH product_production AS (
    SELECT
        F.facility_name,
        P.product_name,
        SUM(PR.quantity_produced) AS total_produced
    FROM fact_production AS PR
    INNER JOIN dim_facility AS F
        ON PR.facility_id = F.facility_id
    INNER JOIN dim_product AS P
        ON PR.product_id = P.product_id
    GROUP BY
        F.facility_id,
        F.facility_name,
        P.product_id,
        P.product_name
),
ranked_products AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY facility_name
            ORDER BY total_produced DESC
        ) AS product_rank
    FROM product_production
)
SELECT
    facility_name,
    product_name,
    total_produced,
    product_rank
FROM ranked_products
WHERE product_rank <= 3
ORDER BY facility_name, product_rank;


-- =========================================================
-- 3. PROCUREMENT ANALYSIS
-- =========================================================

-- 15. Total Procurement Cost by Supplier

SELECT
    S.supplier_id,
    S.supplier_name,
    SUM(P.total_cost) AS total_procurement_cost
FROM dim_supplier AS S
INNER JOIN fact_procurement AS P
    ON S.supplier_id = P.supplier_id
GROUP BY S.supplier_id, S.supplier_name
ORDER BY total_procurement_cost DESC;


-- 16. Average Lead Time by Supplier

SELECT
    S.supplier_name,
    ROUND(AVG(P.lead_time_days)::NUMERIC, 2)
        AS avg_lead_time_days
FROM dim_supplier AS S
INNER JOIN fact_procurement AS P
    ON S.supplier_id = P.supplier_id
GROUP BY S.supplier_id, S.supplier_name
ORDER BY avg_lead_time_days DESC;


-- =========================================================
-- 4. INVENTORY ANALYSIS
-- =========================================================

-- 17. Products Below Safety Stock Level

SELECT
    P.product_name,
    I.stock_level,
    I.safety_stock_level
FROM dim_product AS P
INNER JOIN fact_inventory AS I
    ON P.product_id = I.product_id
WHERE I.stock_level < I.safety_stock_level
ORDER BY I.stock_level ASC;


-- 18. Classify Inventory Stock Status

SELECT
    P.product_name,
    I.stock_level,
    I.safety_stock_level,
    CASE
        WHEN I.stock_level < I.safety_stock_level
            THEN 'Critical'
        WHEN I.stock_level = I.safety_stock_level
            THEN 'Low'
        ELSE 'Healthy'
    END AS stock_status
FROM dim_product AS P
INNER JOIN fact_inventory AS I
    ON P.product_id = I.product_id
ORDER BY I.stock_level ASC;


-- =========================================================
-- 5. SHIPMENT ANALYSIS
-- =========================================================

-- 19. Total Shipments and Average Shipping Cost by Carrier

SELECT
    carrier,
    COUNT(*) AS total_shipments,
    ROUND(AVG(shipping_cost)::NUMERIC, 2)
        AS avg_shipping_cost
FROM fact_shipment
GROUP BY carrier
ORDER BY total_shipments DESC;


-- 20. Shipment Count and Percentage by Status

SELECT
    status,
    COUNT(*) AS total_shipments,
    ROUND(
        (
            COUNT(*) * 100.0
            / SUM(COUNT(*)) OVER ()
        )::NUMERIC,
        2
    ) AS shipment_percentage
FROM fact_shipment
GROUP BY status
ORDER BY total_shipments DESC;


-- 21. Shipment Delay Reasons

SELECT
    delay_reason,
    COUNT(*) AS total_delayed_shipments
FROM fact_shipment
WHERE delay_reason IS NOT NULL
GROUP BY delay_reason
ORDER BY total_delayed_shipments DESC;


-- 22. Average Shipping Cost by Carrier and Status

SELECT
    carrier,
    status,
    COUNT(*) AS total_shipments,
    ROUND(AVG(shipping_cost)::NUMERIC, 2)
        AS avg_shipping_cost
FROM fact_shipment
GROUP BY carrier, status
ORDER BY carrier, total_shipments DESC;


