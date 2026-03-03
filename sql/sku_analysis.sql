-- ============================================================
-- Amazon SKU Performance Analysis — Pierre Henry Socks
-- Author: Nandni Talreja
-- Description: SQL queries replicating the R turnover and
--              segmentation analysis, suitable for use in
--              MySQL, PostgreSQL, or SQLite.
--
-- Assumed table schema:
--   orders(order_id, purchase_date, sku, product_name,
--          asin, quantity, item_price, item_tax,
--          ship_state, order_status, fulfillment_channel)
--
--   inventory(sku, snapshot_month, units_available)
--   -- snapshot_month values: 'Jan', 'Jun', 'Sep'
-- ============================================================


-- ============================================================
-- SECTION 1: BASIC EXPLORATION
-- ============================================================

-- 1.1 Total orders and revenue by month
SELECT
    DATE_FORMAT(purchase_date, '%Y-%m')  AS month,
    COUNT(DISTINCT order_id)             AS total_orders,
    SUM(quantity)                        AS total_units_sold,
    ROUND(SUM(item_price), 2)            AS total_revenue
FROM orders
WHERE order_status NOT IN ('Cancelled')
GROUP BY DATE_FORMAT(purchase_date, '%Y-%m')
ORDER BY month;


-- 1.2 Top 20 SKUs by total units sold (Jan–Sept 2024)
SELECT
    sku,
    product_name,
    SUM(quantity)              AS total_units,
    ROUND(SUM(item_price), 2)  AS total_revenue,
    ROUND(AVG(item_price), 2)  AS avg_price
FROM orders
WHERE order_status NOT IN ('Cancelled')
GROUP BY sku, product_name
ORDER BY total_units DESC
LIMIT 20;


-- 1.3 Monthly sales breakdown per SKU (pivot-style using CASE)
SELECT
    sku,
    SUM(CASE WHEN MONTH(purchase_date) = 1  THEN quantity ELSE 0 END) AS sales_jan,
    SUM(CASE WHEN MONTH(purchase_date) = 2  THEN quantity ELSE 0 END) AS sales_feb,
    SUM(CASE WHEN MONTH(purchase_date) = 3  THEN quantity ELSE 0 END) AS sales_mar,
    SUM(CASE WHEN MONTH(purchase_date) = 4  THEN quantity ELSE 0 END) AS sales_apr,
    SUM(CASE WHEN MONTH(purchase_date) = 5  THEN quantity ELSE 0 END) AS sales_may,
    SUM(CASE WHEN MONTH(purchase_date) = 6  THEN quantity ELSE 0 END) AS sales_jun,
    SUM(CASE WHEN MONTH(purchase_date) = 7  THEN quantity ELSE 0 END) AS sales_jul,
    SUM(CASE WHEN MONTH(purchase_date) = 8  THEN quantity ELSE 0 END) AS sales_aug,
    SUM(CASE WHEN MONTH(purchase_date) = 9  THEN quantity ELSE 0 END) AS sales_sep,
    SUM(quantity)                                                       AS total_units
FROM orders
WHERE order_status NOT IN ('Cancelled')
  AND YEAR(purchase_date) = 2024
GROUP BY sku
ORDER BY total_units DESC;


-- ============================================================
-- SECTION 2: SKU TURNOVER RATE CALCULATION
-- ============================================================

-- 2.1 Calculate COGS per SKU per window
--     Unit cost assumed at $2.30 per pair
WITH monthly_sales AS (
    SELECT
        sku,
        SUM(CASE WHEN MONTH(purchase_date) BETWEEN 1 AND 6
                 THEN quantity ELSE 0 END) * 2.30  AS cogs_jan_june,
        SUM(CASE WHEN MONTH(purchase_date) BETWEEN 1 AND 9
                 THEN quantity ELSE 0 END) * 2.30  AS cogs_jan_sept,
        SUM(CASE WHEN MONTH(purchase_date) BETWEEN 6 AND 9
                 THEN quantity ELSE 0 END) * 2.30  AS cogs_june_sept,
        SUM(CASE WHEN MONTH(purchase_date) BETWEEN 1 AND 6
                 THEN quantity ELSE 0 END)          AS units_jan_june,
        SUM(CASE WHEN MONTH(purchase_date) BETWEEN 1 AND 9
                 THEN quantity ELSE 0 END)          AS units_jan_sept,
        SUM(CASE WHEN MONTH(purchase_date) BETWEEN 6 AND 9
                 THEN quantity ELSE 0 END)          AS units_june_sept
    FROM orders
    WHERE order_status NOT IN ('Cancelled')
      AND YEAR(purchase_date) = 2024
    GROUP BY sku
),
inventory_snapshots AS (
    SELECT
        sku,
        MAX(CASE WHEN snapshot_month = 'Jan' THEN units_available ELSE 0 END) AS inv_jan,
        MAX(CASE WHEN snapshot_month = 'Jun' THEN units_available ELSE 0 END) AS inv_june,
        MAX(CASE WHEN snapshot_month = 'Sep' THEN units_available ELSE 0 END) AS inv_sept
    FROM inventory
    GROUP BY sku
),
avg_inventory AS (
    SELECT
        sku,
        -- Average inventory for each window: (opening + closing) / 2
        GREATEST((inv_jan  + inv_june) / 2.0, 1) AS avg_inv_jan_june,
        GREATEST((inv_jan  + inv_sept) / 2.0, 1) AS avg_inv_jan_sept,
        GREATEST((inv_june + inv_sept) / 2.0, 1) AS avg_inv_june_sept
    FROM inventory_snapshots
)
SELECT
    s.sku,
    s.units_jan_sept                                            AS total_units_sold,
    ROUND(s.cogs_jan_sept, 2)                                  AS total_cogs,
    ROUND(a.avg_inv_jan_sept, 1)                               AS avg_inventory,
    -- Turnover Rate = Units Sold / Average Inventory
    ROUND(s.units_jan_june  / a.avg_inv_jan_june,  2)          AS turnover_jan_june,
    ROUND(s.units_jan_sept  / a.avg_inv_jan_sept,  2)          AS turnover_jan_sept,
    ROUND(s.units_june_sept / a.avg_inv_june_sept, 2)          AS turnover_june_sept,
    -- Average across all three windows
    ROUND((s.units_jan_june  / a.avg_inv_jan_june +
           s.units_jan_sept  / a.avg_inv_jan_sept +
           s.units_june_sept / a.avg_inv_june_sept) / 3.0, 2)  AS avg_turnover
FROM monthly_sales s
JOIN avg_inventory a ON s.sku = a.sku
ORDER BY turnover_jan_sept DESC;


-- ============================================================
-- SECTION 3: SKU SEGMENTATION
-- ============================================================

-- 3.1 Flag SKUs by performance tier
WITH turnover_rates AS (
    -- (Reuse CTE from Section 2 above in a full query)
    SELECT
        s.sku,
        ROUND((s.units_jan_june  / a.avg_inv_jan_june +
               s.units_jan_sept  / a.avg_inv_jan_sept +
               s.units_june_sept / a.avg_inv_june_sept) / 3.0, 2) AS avg_turnover,
        s.units_jan_sept AS total_units_sold
    FROM monthly_sales s
    JOIN avg_inventory a ON s.sku = a.sku
)
SELECT
    sku,
    avg_turnover,
    total_units_sold,
    CASE
        WHEN avg_turnover = 0                      THEN 'Discontinue'
        WHEN avg_turnover > 0 AND avg_turnover < 3 THEN 'Reduce Inventory'
        WHEN avg_turnover >= 3 AND avg_turnover < 5 THEN 'Monitor'
        WHEN avg_turnover >= 5 AND avg_turnover < 10 THEN 'Maintain'
        WHEN avg_turnover >= 10                    THEN 'Prioritize Restock'
    END AS recommendation
FROM turnover_rates
ORDER BY avg_turnover DESC;


-- 3.2 Count SKUs in each performance tier
WITH turnover_rates AS (
    SELECT
        s.sku,
        ROUND((s.units_jan_june  / a.avg_inv_jan_june +
               s.units_jan_sept  / a.avg_inv_jan_sept +
               s.units_june_sept / a.avg_inv_june_sept) / 3.0, 2) AS avg_turnover
    FROM monthly_sales s
    JOIN avg_inventory a ON s.sku = a.sku
)
SELECT
    CASE
        WHEN avg_turnover = 0                        THEN 'Discontinue'
        WHEN avg_turnover BETWEEN 0.01 AND 2.99      THEN 'Reduce Inventory'
        WHEN avg_turnover BETWEEN 3.00 AND 4.99      THEN 'Monitor'
        WHEN avg_turnover BETWEEN 5.00 AND 9.99      THEN 'Maintain'
        WHEN avg_turnover >= 10                      THEN 'Prioritize Restock'
    END                AS tier,
    COUNT(*)           AS sku_count,
    ROUND(AVG(avg_turnover), 2) AS avg_turnover_in_tier
FROM turnover_rates
GROUP BY tier
ORDER BY avg_turnover_in_tier DESC;


-- ============================================================
-- SECTION 4: CUSTOMER & GEOGRAPHIC ANALYSIS
-- ============================================================

-- 4.1 Revenue by US state (top 15)
SELECT
    ship_state,
    COUNT(DISTINCT order_id)  AS total_orders,
    SUM(quantity)             AS total_units,
    ROUND(SUM(item_price), 2) AS total_revenue
FROM orders
WHERE order_status NOT IN ('Cancelled')
  AND ship_state IS NOT NULL
GROUP BY ship_state
ORDER BY total_revenue DESC
LIMIT 15;


-- 4.2 Day-of-week sales pattern (for forecasting context)
SELECT
    DAYNAME(purchase_date)    AS day_of_week,
    DAYOFWEEK(purchase_date)  AS day_num,
    COUNT(DISTINCT order_id)  AS total_orders,
    SUM(quantity)             AS total_units,
    ROUND(AVG(quantity), 2)   AS avg_units_per_order
FROM orders
WHERE order_status NOT IN ('Cancelled')
GROUP BY DAYNAME(purchase_date), DAYOFWEEK(purchase_date)
ORDER BY day_num;


-- 4.3 Fulfillment channel comparison (FBA vs FBM)
SELECT
    fulfillment_channel,
    COUNT(DISTINCT order_id)  AS total_orders,
    SUM(quantity)             AS total_units,
    ROUND(SUM(item_price), 2) AS total_revenue,
    ROUND(AVG(item_price), 2) AS avg_order_value
FROM orders
WHERE order_status NOT IN ('Cancelled')
GROUP BY fulfillment_channel;


-- ============================================================
-- SECTION 5: PRICING ANALYSIS
-- ============================================================

-- 5.1 Price distribution by SKU (for pricing strategy review)
SELECT
    sku,
    COUNT(*)                         AS order_lines,
    ROUND(MIN(item_price), 2)        AS min_price,
    ROUND(MAX(item_price), 2)        AS max_price,
    ROUND(AVG(item_price), 2)        AS avg_price,
    ROUND(STDDEV(item_price), 2)     AS price_stddev
FROM orders
WHERE order_status NOT IN ('Cancelled')
  AND item_price > 0
GROUP BY sku
HAVING order_lines >= 5  -- Only SKUs with meaningful sample size
ORDER BY avg_price DESC
LIMIT 30;


-- 5.2 Promotion impact — compare discounted vs non-discounted orders
SELECT
    CASE
        WHEN item_promotion_discount > 0 THEN 'Discounted'
        ELSE 'Full Price'
    END                           AS price_type,
    COUNT(DISTINCT order_id)      AS total_orders,
    SUM(quantity)                 AS total_units,
    ROUND(AVG(item_price), 2)     AS avg_price,
    ROUND(AVG(quantity), 2)       AS avg_units_per_order,
    ROUND(SUM(item_price), 2)     AS total_revenue
FROM orders
WHERE order_status NOT IN ('Cancelled')
GROUP BY price_type;


-- ============================================================
-- SECTION 6: RESTOCK ALERT LOGIC
-- ============================================================

-- 6.1 Identify SKUs that need restocking
--     Logic: high turnover but low current inventory = restock risk
WITH latest_inventory AS (
    SELECT sku, units_available AS current_stock
    FROM inventory
    WHERE snapshot_month = 'Sep'  -- Most recent snapshot
),
sales_velocity AS (
    SELECT
        sku,
        -- Average monthly sales over last 3 months
        ROUND(SUM(CASE WHEN MONTH(purchase_date) IN (7,8,9)
                       THEN quantity ELSE 0 END) / 3.0, 1) AS avg_monthly_sales
    FROM orders
    WHERE order_status NOT IN ('Cancelled')
      AND YEAR(purchase_date) = 2024
    GROUP BY sku
)
SELECT
    i.sku,
    i.current_stock,
    v.avg_monthly_sales,
    -- Weeks of stock remaining at current sales rate
    ROUND(i.current_stock / NULLIF(v.avg_monthly_sales / 4.0, 0), 1) AS weeks_of_stock,
    CASE
        WHEN i.current_stock / NULLIF(v.avg_monthly_sales / 4.0, 0) < 2
             THEN '🔴 Restock Now'
        WHEN i.current_stock / NULLIF(v.avg_monthly_sales / 4.0, 0) < 4
             THEN '🟡 Restock Soon'
        ELSE '🟢 OK'
    END AS restock_status
FROM latest_inventory i
JOIN sales_velocity v ON i.sku = v.sku
WHERE v.avg_monthly_sales > 0  -- Only SKUs with active sales
ORDER BY weeks_of_stock ASC;
