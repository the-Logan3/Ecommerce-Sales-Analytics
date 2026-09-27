CREATE SCHEMA IF NOT EXISTS ecommerce;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'ecommerce';

CREATE TABLE ecommerce.transactions (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INTEGER,
    InvoiceDate TIMESTAMP,
    UnitPrice NUMERIC(12, 4),
    CustomerID NUMERIC(10, 1),
    Country VARCHAR(100),

    IsCancelled BOOLEAN,
    IsNegativeQuantity BOOLEAN,
    IsZeroPrice BOOLEAN,
    IsNegativePrice BOOLEAN,
    IsMissingCustomer BOOLEAN,
    IsOperationalAdjustment BOOLEAN,
    IsAccountingAdjustment BOOLEAN,

    Revenue NUMERIC(14, 2),

    IsSalesTransaction BOOLEAN,̇
    IsMerchandise BOOLEAN
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'ecommerce';

SELECT current_database(), current_user;

SELECT schema_name
FROM information_schema.schemata
WHERE schema_name = 'ecommerce';

SELECT COUNT(*) AS row_count
FROM ecommerce.transactions;

SELECT
    COUNT(*) AS rows,
    SUM(CASE WHEN issalestransaction THEN 1 ELSE 0 END) AS sales_rows,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM ecommerce.transactions;

SELECT
    ROUND(SUM(quantity * unitprice), 2) AS calculated_revenue,
    ROUND(SUM(revenue), 2) AS imported_revenue
FROM ecommerce.transactions
WHERE issalestransaction = TRUE;

CREATE TABLE ecommerce.customer_summary AS
SELECT
    customerid AS customer_id,
    SUM(revenue) AS revenue,
    COUNT(DISTINCT invoiceno) AS orders,
    SUM(quantity) AS units
FROM ecommerce.transactions
WHERE issalestransaction = TRUE
  AND customerid IS NOT NULL
GROUP BY customerid;

SELECT COUNT(*) AS customers
FROM ecommerce.customer_summary;

SELECT
    customer_id,
    ROUND(revenue, 2) AS revenue,
    orders,
    units,
    ROUND(revenue / NULLIF(orders, 0), 2) AS aov
FROM ecommerce.customer_summary
ORDER BY revenue DESC
LIMIT 10;

CREATE TABLE ecommerce.product_summary AS
SELECT
    stockcode AS stock_code,
    description,
    SUM(revenue) AS revenue,
    SUM(quantity) AS units,
    COUNT(DISTINCT invoiceno) AS orders,
    COUNT(DISTINCT customerid) AS customers
FROM ecommerce.transactions
WHERE issalestransaction = TRUE
  AND ismerchandise = TRUE
GROUP BY stockcode, description;

SELECT COUNT(*) AS products
FROM ecommerce.product_summary;

SELECT
    COUNT(*) AS summary_rows,
    COUNT(DISTINCT stock_code) AS unique_stock_codes
FROM ecommerce.product_summary;

SELECT
    stock_code,
    COUNT(*) AS description_count
FROM ecommerce.product_summary
GROUP BY stock_code
HAVING COUNT(*) > 1
ORDER BY description_count DESC
LIMIT 20;

SELECT
    stock_code,
    description,
    revenue,
    units,
    orders,
    customers
FROM ecommerce.product_summary
WHERE stock_code = '23196'
ORDER BY revenue DESC;

DROP TABLE ecommerce.product_summary;

CREATE TABLE ecommerce.product_summary AS
WITH product_agg AS (
    SELECT
        stockcode AS stock_code,
        description,
        SUM(revenue) AS revenue,
        SUM(quantity) AS units,
        COUNT(DISTINCT invoiceno) AS orders,
        COUNT(DISTINCT customerid) AS customers
    FROM ecommerce.transactions
    WHERE issalestransaction = TRUE
      AND ismerchandise = TRUE
    GROUP BY stockcode, description
),
ranked_products AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY stock_code
            ORDER BY revenue DESC
        ) AS rn
    FROM product_agg
)
SELECT
    stock_code,
    description,
    revenue,
    units,
    orders,
    customers
FROM ranked_products
WHERE rn = 1;

SELECT COUNT(*) AS products
FROM ecommerce.product_summary;

SELECT
    stock_code,
    description,
    ROUND(revenue, 2) AS revenue,
    units,
    orders,
    customers
FROM ecommerce.product_summary
ORDER BY revenue DESC
LIMIT 10;

CREATE TABLE ecommerce.country_summary AS
SELECT
    country,
    SUM(revenue) AS revenue,
    COUNT(DISTINCT invoiceno) AS orders,
    COUNT(DISTINCT customerid) AS customers,
    SUM(quantity) AS units
FROM ecommerce.transactions
WHERE issalestransaction = TRUE
  AND customerid IS NOT NULL
GROUP BY country;

SELECT COUNT(*) AS countries
FROM ecommerce.country_summary;

SELECT
    country,
    ROUND(revenue, 2) AS revenue,
    orders,
    customers,
    units
FROM ecommerce.country_summary
ORDER BY revenue DESC
LIMIT 10;

CREATE TABLE ecommerce.monthly_sales AS
SELECT
    TO_CHAR(invoiceDate, 'YYYY-MM') AS month,
    SUM(revenue) AS revenue,
    COUNT(DISTINCT invoiceNo) AS orders,
    SUM(quantity) AS units,
    COUNT(DISTINCT customerid) AS customers
FROM ecommerce.transactions
WHERE isSalesTransaction = TRUE
GROUP BY TO_CHAR(invoiceDate, 'YYYY-MM');

SELECT COUNT(*) AS months
FROM ecommerce.monthly_sales;

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    orders,
    units,
    customers
FROM ecommerce.monthly_sales
ORDER BY month;

SELECT
    COUNT(DISTINCT invoiceno) AS orders,
    SUM(quantity) AS units,
    COUNT(*) AS rows
FROM ecommerce.transactions
WHERE issalestransaction = TRUE
  AND invoicedate >= '2010-12-01'
  AND invoicedate < '2011-01-01';

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    orders,
    units,
    customers
FROM ecommerce.monthly_sales
ORDER BY month;

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    orders,
    ROUND(revenue / NULLIF(orders, 0), 2) AS aov,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100,
        2
    ) AS mom_growth_pct
FROM ecommerce.monthly_sales
ORDER BY month;

CREATE VIEW ecommerce.monthly_sales_analysis AS
SELECT
    month,
    revenue,
    orders,
    units,
    customers,
    ROUND(revenue / NULLIF(orders, 0), 2) AS aov,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100,
        2
    ) AS mom_growth_pct
FROM ecommerce.monthly_sales;

SELECT COUNT(*) AS months
FROM ecommerce.monthly_sales_analysis;

WITH ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        orders,
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
        SUM(revenue) OVER () AS total_revenue,
        SUM(revenue) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_revenue
    FROM ecommerce.customer_summary
)
SELECT
    customer_id,
    ROUND(revenue, 2) AS revenue,
    orders,
    revenue_rank,
    ROUND(revenue / total_revenue * 100, 2) AS revenue_pct,
    ROUND(cumulative_revenue / total_revenue * 100, 2) AS cumulative_revenue_pct
FROM ranked_customers
ORDER BY revenue_rank
LIMIT 10;

WITH ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
        SUM(revenue) OVER () AS total_revenue
    FROM ecommerce.customer_summary
)
SELECT
    CASE
        WHEN revenue_rank <= 10 THEN 'Top 10'
        WHEN revenue_rank <= 50 THEN 'Top 50'
        WHEN revenue_rank <= 100 THEN 'Top 100'
        WHEN revenue_rank <= 500 THEN 'Top 500'
    END AS customer_group,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(revenue) / MAX(total_revenue) * 100, 2) AS revenue_share_pct
FROM ranked_customers
WHERE revenue_rank <= 500
GROUP BY
    CASE
        WHEN revenue_rank <= 10 THEN 'Top 10'
        WHEN revenue_rank <= 50 THEN 'Top 50'
        WHEN revenue_rank <= 100 THEN 'Top 100'
        WHEN revenue_rank <= 500 THEN 'Top 500'
    END
ORDER BY
    CASE customer_group
        WHEN 'Top 10' THEN 1
        WHEN 'Top 50' THEN 2
        WHEN 'Top 100' THEN 3
        WHEN 'Top 500' THEN 4
    END;

WITH ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS revenue_rank,
        SUM(revenue) OVER () AS total_revenue
    FROM ecommerce.customer_summary
),
customer_groups AS (
    SELECT
        CASE
            WHEN revenue_rank <= 10 THEN 'Top 10'
            WHEN revenue_rank <= 50 THEN 'Top 50'
            WHEN revenue_rank <= 100 THEN 'Top 100'
            WHEN revenue_rank <= 500 THEN 'Top 500'
        END AS customer_group,
        revenue,
        total_revenue
    FROM ranked_customers
    WHERE revenue_rank <= 500
)
SELECT
    customer_group,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(revenue) / MAX(total_revenue) * 100, 2) AS revenue_share_pct
FROM customer_groups
GROUP BY customer_group
ORDER BY
    MIN(
        CASE customer_group
            WHEN 'Top 10' THEN 1
            WHEN 'Top 50' THEN 2
            WHEN 'Top 100' THEN 3
            WHEN 'Top 500' THEN 4
        END
    );

CREATE VIEW ecommerce.customer_concentration AS
WITH ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS revenue_rank,
        SUM(revenue) OVER () AS total_revenue
    FROM ecommerce.customer_summary
)
SELECT
    customer_id,
    revenue,
    revenue_rank,
    ROUND(revenue / total_revenue * 100, 2) AS revenue_pct,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY revenue_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / total_revenue * 100,
        2
    ) AS cumulative_revenue_pct
FROM ranked_customers;

SELECT COUNT(*) AS customers
FROM ecommerce.customer_concentration;

CREATE TABLE sales (
    InvoiceNo VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INTEGER,
    InvoiceDate TIMESTAMP,
    UnitPrice NUMERIC(12,4),
    CustomerID NUMERIC(10,1),
    Country VARCHAR(50),
    IsCancelled BOOLEAN,
    TransactionType VARCHAR(30),
    TransactionValue NUMERIC(14,4),
    Revenue NUMERIC(14,4),
    ProductType VARCHAR(20)
);


SELECT COUNT(*) AS row_count
FROM ecommerce.transactions;

SELECT *
FROM ecommerce.transactions
LIMIT 5;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE issalestransaction = true) AS sales_rows,
    COUNT(*) FILTER (WHERE ismerchandise = true) AS merchandise_rows,
    COUNT(*) FILTER (WHERE iscancelled = true) AS cancellation_rows,
    COUNT(*) FILTER (WHERE isaccountingadjustment = true) AS accounting_adjustments,
    COUNT(*) FILTER (WHERE isoperationaladjustment = true) AS operational_adjustments,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM ecommerce.transactions;

SELECT
    COUNT(*) AS sales_rows,
    ROUND(SUM(quantity * unitprice), 2) AS sales_revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoiceno) AS orders,
    COUNT(DISTINCT customerid) AS customers,
    COUNT(DISTINCT stockcode) AS products
FROM ecommerce.transactions
WHERE issalestransaction = true;

SELECT
    DATE_TRUNC('month', invoicedate)::date AS month,
    ROUND(SUM(quantity * unitprice), 2) AS revenue,
    COUNT(DISTINCT invoiceno) AS orders,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customerid) AS customers,
    ROUND(
        SUM(quantity * unitprice) / COUNT(DISTINCT invoiceno),
        2
    ) AS average_order_value
FROM ecommerce.transactions
WHERE issalestransaction = true
GROUP BY DATE_TRUNC('month', invoicedate)
ORDER BY month;

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoicedate)::date AS month,
        SUM(quantity * unitprice) AS revenue,
        COUNT(DISTINCT invoiceno) AS orders
    FROM ecommerce.transactions
    WHERE issalestransaction = true
    GROUP BY DATE_TRUNC('month', invoicedate)
)

SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    orders,
    ROUND(
        LAG(revenue) OVER (ORDER BY month),
        2
    ) AS previous_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100,
        2
    ) AS mom_growth_pct
FROM monthly_sales
ORDER BY month;

SELECT
    stockcode,
    description,
    ROUND(SUM(quantity * unitprice), 2) AS revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoiceno) AS orders
FROM ecommerce.transactions
WHERE issalestransaction = true
  AND ismerchandise = true
GROUP BY stockcode, description
ORDER BY revenue DESC
LIMIT 10;

SELECT
    customerid,
    ROUND(SUM(quantity * unitprice), 2) AS revenue,
    COUNT(DISTINCT invoiceno) AS orders,
    SUM(quantity) AS units,
    COUNT(DISTINCT stockcode) AS products,
    ROUND(
        SUM(quantity * unitprice) / COUNT(DISTINCT invoiceno),
        2
    ) AS average_order_value
FROM ecommerce.transactions
WHERE issalestransaction = true
  AND customerid IS NOT NULL
GROUP BY customerid
ORDER BY revenue DESC
LIMIT 10;

WITH customer_revenue AS (
    SELECT
        customerid,
        SUM(quantity * unitprice) AS revenue
    FROM ecommerce.transactions
    WHERE issalestransaction = true
      AND customerid IS NOT NULL
    GROUP BY customerid
),

ranked_customers AS (
    SELECT
        customerid,
        revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS revenue_rank,
        SUM(revenue) OVER () AS total_customer_revenue
    FROM customer_revenue
)

SELECT
    revenue_rank,
    ROUND(revenue, 2) AS customer_revenue,
    ROUND(
        revenue / total_customer_revenue * 100,
        2
    ) AS revenue_share_pct,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY revenue_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / total_customer_revenue * 100,
        2
    ) AS cumulative_revenue_share_pct
FROM ranked_customers
WHERE revenue_rank IN (1, 5, 10, 20, 50, 100)
ORDER BY revenue_rank;

WITH customer_orders AS (
    SELECT
        customerid,
        COUNT(DISTINCT invoiceno) AS orders,
        SUM(quantity * unitprice) AS revenue
    FROM ecommerce.transactions
    WHERE issalestransaction = true
      AND customerid IS NOT NULL
    GROUP BY customerid
)

SELECT
    CASE
        WHEN orders = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,

    COUNT(*) AS customers,

    SUM(orders) AS total_orders,

    ROUND(SUM(revenue)::numeric, 2) AS revenue,

    ROUND(
        (
            SUM(revenue)
            / SUM(SUM(revenue)) OVER () * 100
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(AVG(revenue)::numeric, 2) AS avg_customer_revenue,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY revenue)::numeric,
        2
    ) AS median_customer_revenue

FROM customer_orders

GROUP BY
    CASE
        WHEN orders = 1 THEN 'One-time'
        ELSE 'Repeat'
    END

ORDER BY revenue DESC;

SELECT
    country,
    ROUND(SUM(quantity * unitprice)::numeric, 2) AS revenue,
    COUNT(DISTINCT invoiceno) AS orders,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customerid) AS customers,
    ROUND(
        (
            SUM(quantity * unitprice)
            / SUM(SUM(quantity * unitprice)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_share_pct
FROM ecommerce.transactions
WHERE issalestransaction = true
GROUP BY country
ORDER BY revenue DESC;

SELECT
    stockcode,
    description,
    ROUND(SUM(quantity * unitprice)::numeric, 2) AS revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoiceno) AS orders,
    ROUND(
        (
            SUM(quantity * unitprice)
            / COUNT(DISTINCT invoiceno)
        )::numeric,
        2
    ) AS revenue_per_order,
    ROUND(
        (
            SUM(quantity * unitprice)
            / NULLIF(SUM(quantity), 0)
        )::numeric,
        2
    ) AS revenue_per_unit
FROM ecommerce.transactions
WHERE issalestransaction = true
  AND ismerchandise = true
GROUP BY stockcode, description
ORDER BY revenue DESC
LIMIT 20;

SELECT
    CASE
        WHEN iscancelled = true THEN 'Cancelled'
        ELSE 'Sales'
    END AS transaction_status,
    COUNT(*) AS transactions,
    SUM(ABS(quantity)) AS units,
    ROUND(SUM(ABS(quantity * unitprice))::numeric, 2) AS transaction_value
FROM ecommerce.transactions
WHERE iscancelled = true
   OR issalestransaction = true
GROUP BY
    CASE
        WHEN iscancelled = true THEN 'Cancelled'
        ELSE 'Sales'
    END
ORDER BY transaction_status;

SELECT
    ROUND(
        9251.0 / 524877 * 100,
        2
    ) AS cancellation_rate_pct,

    ROUND(
        275560.0 / 5572419 * 100,
        2
    ) AS cancelled_units_pct,

    ROUND(
        893979.73 / 10631048.74 * 100,
        2
    ) AS cancelled_value_vs_sales_pct;

SELECT
    DATE_TRUNC('month', invoicedate)::date AS month,

    COUNT(*) FILTER (
        WHERE issalestransaction = true
    ) AS sales_transactions,

    COUNT(*) FILTER (
        WHERE iscancelled = true
    ) AS cancelled_transactions,

    ROUND(
        (
            COUNT(*) FILTER (WHERE iscancelled = true)::numeric
            /
            NULLIF(
                COUNT(*) FILTER (WHERE issalestransaction = true),
                0
            ) * 100
        ),
        2
    ) AS cancellation_rate_pct,

    SUM(quantity) FILTER (
        WHERE issalestransaction = true
    ) AS units_sold,

    SUM(ABS(quantity)) FILTER (
        WHERE iscancelled = true
    ) AS cancelled_units

FROM ecommerce.transactions

WHERE issalestransaction = true
   OR iscancelled = true

GROUP BY DATE_TRUNC('month', invoicedate)

ORDER BY month;


-- ============================================================
-- 1. OVERALL SALES PERFORMANCE
-- Business question:
-- What are the total sales, orders, units, customers and
-- products in the cleaned transaction dataset?
-- ============================================================

SELECT
    COUNT(*) AS sales_rows,
    ROUND(SUM(quantity * unitprice)::numeric, 2) AS sales_revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoiceno) AS orders,
    COUNT(DISTINCT customerid) AS customers,
    COUNT(DISTINCT stockcode) AS products
FROM ecommerce.transactions
WHERE issalestransaction = true;

-- ============================================================
-- E-COMMERCE SALES ANALYTICS
-- SQL Analysis
-- Dataset: UCI Online Retail
-- ============================================================


-- ============================================================
-- 1. OVERALL SALES PERFORMANCE
-- ============================================================
-- Business question:
-- What are the total sales, orders, units, customers,
-- and products in the cleaned transaction dataset?

SELECT
    COUNT(*) AS sales_rows,
    ROUND(SUM(quantity * unitprice)::numeric, 2) AS sales_revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoiceno) AS orders,
    COUNT(DISTINCT customerid) AS customers,
    COUNT(DISTINCT stockcode) AS products
FROM ecommerce.transactions
WHERE issalestransaction = true;

-- ============================================================
-- 2. MONTHLY SALES PERFORMANCE
-- ============================================================
-- Business question:
-- How do revenue, orders, units sold, customers,
-- and average order value change month by month?

SELECT
    DATE_TRUNC('month', invoicedate)::date AS month,
    ROUND(SUM(quantity * unitprice)::numeric, 2) AS revenue,
    COUNT(DISTINCT invoiceno) AS orders,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT customerid) AS customers,
    ROUND(
        (
            SUM(quantity * unitprice)
            / COUNT(DISTINCT invoiceno)
        )::numeric,
        2
    ) AS average_order_value
FROM ecommerce.transactions
WHERE issalestransaction = true
GROUP BY DATE_TRUNC('month', invoicedate)
ORDER BY month;

-- ============================================================
-- 3. MONTH-OVER-MONTH REVENUE GROWTH
-- ============================================================
-- Business question:
-- How does monthly revenue change compared with the
-- previous month?
--
-- Note:
-- December 2011 is a partial month in the source dataset.
-- ============================================================

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoicedate)::date AS month,
        SUM(quantity * unitprice) AS revenue,
        COUNT(DISTINCT invoiceno) AS orders
    FROM ecommerce.transactions
    WHERE issalestransaction = true
    GROUP BY DATE_TRUNC('month', invoicedate)
)

SELECT
    month,
    ROUND(revenue::numeric, 2) AS revenue,
    orders,

    ROUND(
        LAG(revenue) OVER (ORDER BY month)::numeric,
        2
    ) AS previous_month_revenue,

    ROUND(
        (
            (
                revenue
                - LAG(revenue) OVER (ORDER BY month)
            )
            / NULLIF(
                LAG(revenue) OVER (ORDER BY month),
                0
            ) * 100
        )::numeric,
        2
    ) AS mom_growth_pct

FROM monthly_sales
ORDER BY month;

-- ============================================================
-- 4. TOP 10 PRODUCTS BY REVENUE
-- ============================================================
-- Business question:
-- Which merchandise products generate the most revenue?
--
-- ismerchandise = true excludes non-product transactions
-- such as postage, fees, discounts and adjustments.
-- ============================================================

SELECT
    stockcode,
    description,
    ROUND(SUM(quantity * unitprice)::numeric, 2) AS revenue,
    SUM(quantity) AS units_sold,
    COUNT(DISTINCT invoiceno) AS orders
FROM ecommerce.transactions
WHERE issalestransaction = true
  AND ismerchandise = true
GROUP BY stockcode, description
ORDER BY revenue DESC
LIMIT 10;

-- ============================================================
-- 5. TOP 10 CUSTOMERS BY REVENUE
-- ============================================================
-- Business question:
-- Which identified customers generate the most revenue?
--
-- Customers without a CustomerID are excluded because they
-- cannot be reliably attributed to an individual customer.
-- ============================================================

SELECT
    customerid,
    ROUND(SUM(quantity * unitprice)::numeric, 2) AS revenue,
    COUNT(DISTINCT invoiceno) AS orders,
    SUM(quantity) AS units,
    COUNT(DISTINCT stockcode) AS products,
    ROUND(
        (
            SUM(quantity * unitprice)
            / COUNT(DISTINCT invoiceno)
        )::numeric,
        2
    ) AS average_order_value
FROM ecommerce.transactions
WHERE issalestransaction = true
  AND customerid IS NOT NULL
GROUP BY customerid
ORDER BY revenue DESC
LIMIT 10;

-- ============================================================
-- 6. CUSTOMER REVENUE CONCENTRATION
-- ============================================================
-- Business question:
-- How concentrated is revenue among the highest-value
-- customers?
--
-- ROW_NUMBER() ranks customers by revenue.
-- The cumulative percentage shows how much of total
-- identified-customer revenue is generated by customers
-- up to each rank.
-- ============================================================

WITH customer_revenue AS (
    SELECT
        customerid,
        SUM(quantity * unitprice) AS revenue
    FROM ecommerce.transactions
    WHERE issalestransaction = true
      AND customerid IS NOT NULL
    GROUP BY customerid
),

ranked_customers AS (
    SELECT
        customerid,
        revenue,

        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank,

        SUM(revenue) OVER () AS total_customer_revenue

    FROM customer_revenue
)

SELECT
    revenue_rank,
    ROUND(revenue::numeric, 2) AS customer_revenue,

    ROUND(
        (
            revenue
            / total_customer_revenue
            * 100
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(
        (
            SUM(revenue) OVER (
                ORDER BY revenue_rank
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )
            / total_customer_revenue
            * 100
        )::numeric,
        2
    ) AS cumulative_revenue_share_pct

FROM ranked_customers

WHERE revenue_rank IN (1, 5, 10, 20, 50, 100)

ORDER BY revenue_rank;

-- ============================================================
-- 7. REPEAT VS ONE-TIME CUSTOMERS
-- ============================================================
-- Business question:
-- How much revenue comes from repeat customers compared
-- with customers who placed only one order?
--
-- Customers without a CustomerID are excluded because
-- repeat behavior cannot be reliably determined for them.
-- ============================================================

WITH customer_orders AS (
    SELECT
        customerid,
        COUNT(DISTINCT invoiceno) AS orders,
        SUM(quantity * unitprice) AS revenue
    FROM ecommerce.transactions
    WHERE issalestransaction = true
      AND customerid IS NOT NULL
    GROUP BY customerid
)

SELECT
    CASE
        WHEN orders = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,

    COUNT(*) AS customers,

    SUM(orders) AS total_orders,

    ROUND(
        SUM(revenue)::numeric,
        2
    ) AS revenue,

    ROUND(
        (
            SUM(revenue)
            / SUM(SUM(revenue)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_share_pct,

    ROUND(
        AVG(revenue)::numeric,
        2
    ) AS avg_customer_revenue,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY revenue)::numeric,
        2
    ) AS median_customer_revenue

FROM customer_orders

GROUP BY
    CASE
        WHEN orders = 1 THEN 'One-time'
        ELSE 'Repeat'
    END

ORDER BY revenue DESC;

-- ============================================================
-- 8. SALES PERFORMANCE BY COUNTRY
-- ============================================================
-- Business question:
-- Which countries generate the most revenue, orders,
-- units sold, and customers?
--
-- Customer counts only include transactions with a
-- non-null CustomerID.
-- ============================================================

SELECT
    country,

    ROUND(
        SUM(quantity * unitprice)::numeric,
        2
    ) AS revenue,

    COUNT(DISTINCT invoiceno) AS orders,

    SUM(quantity) AS units_sold,

    COUNT(DISTINCT customerid) AS customers,

    ROUND(
        (
            SUM(quantity * unitprice)
            / SUM(SUM(quantity * unitprice)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_share_pct

FROM ecommerce.transactions

WHERE issalestransaction = true

GROUP BY country

ORDER BY revenue DESC;

-- ============================================================
-- 9. PRODUCT PERFORMANCE METRICS
-- ============================================================
-- Business question:
-- Which products generate revenue, and is that revenue
-- driven by high sales volume, frequent orders, or
-- higher revenue per order/unit?
--
-- ismerchandise = true excludes non-product transactions
-- such as postage, fees, discounts and adjustments.
-- ============================================================

SELECT
    stockcode,
    description,

    ROUND(
        SUM(quantity * unitprice)::numeric,
        2
    ) AS revenue,

    SUM(quantity) AS units_sold,

    COUNT(DISTINCT invoiceno) AS orders,

    ROUND(
        (
            SUM(quantity * unitprice)
            / COUNT(DISTINCT invoiceno)
        )::numeric,
        2
    ) AS revenue_per_order,

    ROUND(
        (
            SUM(quantity * unitprice)
            / NULLIF(SUM(quantity), 0)
        )::numeric,
        2
    ) AS revenue_per_unit

FROM ecommerce.transactions

WHERE issalestransaction = true
  AND ismerchandise = true

GROUP BY
    stockcode,
    description

ORDER BY revenue DESC

LIMIT 20;

-- ============================================================
-- 10. CANCELLATION ANALYSIS
-- ============================================================
-- Business question:
-- How significant are cancellations compared with sales
-- in terms of transaction count, units, and transaction value?
--
-- Cancellation value is shown as absolute transaction value.
-- It should NOT automatically be interpreted as lost revenue,
-- because the dataset does not establish whether every
-- cancellation represents revenue that would otherwise have
-- been realized.
-- ============================================================

SELECT
    CASE
        WHEN iscancelled = true THEN 'Cancelled'
        ELSE 'Sales'
    END AS transaction_status,

    COUNT(*) AS transactions,

    SUM(ABS(quantity)) AS units,

    ROUND(
        SUM(ABS(quantity * unitprice))::numeric,
        2
    ) AS transaction_value

FROM ecommerce.transactions

WHERE iscancelled = true
   OR issalestransaction = true

GROUP BY
    CASE
        WHEN iscancelled = true THEN 'Cancelled'
        ELSE 'Sales'
    END

ORDER BY transaction_status;

-- ============================================================
-- 11. CANCELLATION RATES
-- ============================================================
-- Business question:
-- What percentage of sales transactions, units, and sales
-- value is represented by cancellations?
--
-- Note:
-- Cancellation value is based on absolute transaction value.
-- It is not necessarily equivalent to lost revenue.
-- ============================================================

SELECT

    ROUND(
        (
            9251.0
            / 524877
            * 100
        )::numeric,
        2
    ) AS cancellation_rate_pct,

    ROUND(
        (
            275560.0
            / 5572419
            * 100
        )::numeric,
        2
    ) AS cancelled_units_pct,

    ROUND(
        (
            893979.73
            / 10631048.74
            * 100
        )::numeric,
        2
    ) AS cancelled_value_vs_sales_pct;
    
-- ============================================================
-- 12. MONTHLY CANCELLATION TREND
-- ============================================================
-- Business question:
-- How does the cancellation rate change over time?
--
-- December 2011 is a partial month in the source dataset.
-- ============================================================

SELECT
    DATE_TRUNC('month', invoicedate)::date AS month,

    COUNT(*) FILTER (
        WHERE issalestransaction = true
    ) AS sales_transactions,

    COUNT(*) FILTER (
        WHERE iscancelled = true
    ) AS cancelled_transactions,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE iscancelled = true
            )::numeric
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE issalestransaction = true
                ),
                0
            )
            * 100
        ),
        2
    ) AS cancellation_rate_pct,

    SUM(quantity) FILTER (
        WHERE issalestransaction = true
    ) AS units_sold,

    SUM(ABS(quantity)) FILTER (
        WHERE iscancelled = true
    ) AS cancelled_units

FROM ecommerce.transactions

WHERE issalestransaction = true
   OR iscancelled = true

GROUP BY DATE_TRUNC('month', invoicedate)

ORDER BY month;

-- ============================================================
-- 13. TOP PRODUCTS BY ORDER FREQUENCY
-- ============================================================
-- Business question:
-- Which products appear in the largest number of distinct
-- customer orders?
--
-- This provides a different perspective from revenue ranking.
-- A product can have high order frequency without being one
-- of the highest-revenue products.
-- ============================================================

SELECT
    stockcode,
    description,

    COUNT(DISTINCT invoiceno) AS orders,

    SUM(quantity) AS units_sold,

    ROUND(
        SUM(quantity * unitprice)::numeric,
        2
    ) AS revenue,

    ROUND(
        (
            SUM(quantity * unitprice)
            / COUNT(DISTINCT invoiceno)
        )::numeric,
        2
    ) AS revenue_per_order

FROM ecommerce.transactions

WHERE issalestransaction = true
  AND ismerchandise = true

GROUP BY
    stockcode,
    description

ORDER BY orders DESC

LIMIT 20;

-- ============================================================
-- 14. AVERAGE ORDER VALUE BY COUNTRY
-- ============================================================
-- Business question:
-- Which countries have the highest average order value?
--
-- Countries with very few orders can produce unusually high
-- averages, so order count should always be considered
-- alongside AOV.
-- ============================================================

SELECT
    country,

    COUNT(DISTINCT invoiceno) AS orders,

    COUNT(DISTINCT customerid) AS customers,

    ROUND(
        SUM(quantity * unitprice)::numeric,
        2
    ) AS revenue,

    ROUND(
        (
            SUM(quantity * unitprice)
            / COUNT(DISTINCT invoiceno)
        )::numeric,
        2
    ) AS average_order_value

FROM ecommerce.transactions

WHERE issalestransaction = true

GROUP BY country

ORDER BY average_order_value DESC;

-- ============================================================
-- 15. CUSTOMER REVENUE SEGMENTS
-- ============================================================
-- Business question:
-- How are identified customers distributed by their
-- total lifetime revenue?
--
-- Customers without a CustomerID are excluded because
-- individual customer revenue cannot be calculated.
-- ============================================================

WITH customer_revenue AS (
    SELECT
        customerid,
        SUM(quantity * unitprice) AS revenue
    FROM ecommerce.transactions
    WHERE issalestransaction = true
      AND customerid IS NOT NULL
    GROUP BY customerid
)

SELECT
    CASE
        WHEN revenue < 100 THEN 'Under £100'
        WHEN revenue < 500 THEN '£100–£499'
        WHEN revenue < 1000 THEN '£500–£999'
        WHEN revenue < 5000 THEN '£1,000–£4,999'
        WHEN revenue < 10000 THEN '£5,000–£9,999'
        ELSE '£10,000+'
    END AS revenue_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(revenue)::numeric,
        2
    ) AS total_revenue,

    ROUND(
        (
            SUM(revenue)
            / SUM(SUM(revenue)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_share_pct

FROM customer_revenue

GROUP BY
    CASE
        WHEN revenue < 100 THEN 'Under £100'
        WHEN revenue < 500 THEN '£100–£499'
        WHEN revenue < 1000 THEN '£500–£999'
        WHEN revenue < 5000 THEN '£1,000–£4,999'
        WHEN revenue < 10000 THEN '£5,000–£9,999'
        ELSE '£10,000+'
    END

ORDER BY
    MIN(revenue);

SELECT
    DATE_TRUNC('month', invoicedate)::date AS month,

    ROUND(
        SUM(quantity * unitprice)::numeric,
        2
    ) AS revenue,

    COUNT(DISTINCT invoiceno) AS orders,

    SUM(quantity) AS units_sold,

    COUNT(DISTINCT customerid) AS customers,

    ROUND(
        (
            SUM(quantity * unitprice)
            / COUNT(DISTINCT invoiceno)
        )::numeric,
        2
    ) AS average_order_value

FROM ecommerce.transactions

WHERE issalestransaction = true

GROUP BY DATE_TRUNC('month', invoicedate)

ORDER BY month;

SELECT
    stockcode,
    description,

    ROUND(
        SUM(quantity * unitprice)::numeric,
        2
    ) AS revenue,

    SUM(quantity) AS units_sold,

    COUNT(DISTINCT invoiceno) AS orders,

    ROUND(
        (
            SUM(quantity * unitprice)
            / COUNT(DISTINCT invoiceno)
        )::numeric,
        2
    ) AS revenue_per_order,

    ROUND(
        (
            SUM(quantity * unitprice)
            / NULLIF(SUM(quantity), 0)
        )::numeric,
        2
    ) AS revenue_per_unit

FROM ecommerce.transactions

WHERE issalestransaction = true
  AND ismerchandise = true

GROUP BY
    stockcode,
    description

ORDER BY revenue DESC

LIMIT 10;

SELECT
    country,

    ROUND(
        SUM(quantity * unitprice)::numeric,
        2
    ) AS revenue,

    COUNT(DISTINCT invoiceno) AS orders,

    SUM(quantity) AS units_sold,

    COUNT(DISTINCT customerid) AS customers,

    ROUND(
        (
            SUM(quantity * unitprice)
            / SUM(SUM(quantity * unitprice)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_share_pct

FROM ecommerce.transactions

WHERE issalestransaction = true

GROUP BY country

ORDER BY revenue DESC;

-- ============================================================
-- TABLEAU DATASET: REPEAT VS ONE-TIME CUSTOMERS
-- ============================================================

WITH customer_orders AS (
    SELECT
        customerid,
        COUNT(DISTINCT invoiceno) AS orders,
        SUM(quantity * unitprice) AS revenue
    FROM ecommerce.transactions
    WHERE issalestransaction = true
      AND customerid IS NOT NULL
    GROUP BY customerid
)

SELECT
    CASE
        WHEN orders = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,

    COUNT(*) AS customers,

    SUM(orders) AS total_orders,

    ROUND(
        SUM(revenue)::numeric,
        2
    ) AS revenue,

    ROUND(
        (
            SUM(revenue)
            / SUM(SUM(revenue)) OVER ()
            * 100
        )::numeric,
        2
    ) AS revenue_share_pct

FROM customer_orders

GROUP BY
    CASE
        WHEN orders = 1 THEN 'One-time'
        ELSE 'Repeat'
    END

ORDER BY revenue DESC;

-- ============================================================
-- TABLEAU DATASET: MONTHLY CANCELLATION TREND
-- ============================================================

SELECT
    DATE_TRUNC('month', invoicedate)::date AS month,

    COUNT(*) FILTER (
        WHERE issalestransaction = true
    ) AS sales_transactions,

    COUNT(*) FILTER (
        WHERE iscancelled = true
    ) AS cancelled_transactions,

    ROUND(
        (
            COUNT(*) FILTER (
                WHERE iscancelled = true
            )::numeric
            /
            NULLIF(
                COUNT(*) FILTER (
                    WHERE issalestransaction = true
                ),
                0
            )
            * 100
        ),
        2
    ) AS cancellation_rate_pct,

    SUM(quantity) FILTER (
        WHERE issalestransaction = true
    ) AS units_sold,

    SUM(ABS(quantity)) FILTER (
        WHERE iscancelled = true
    ) AS cancelled_units

FROM ecommerce.transactions

WHERE issalestransaction = true
   OR iscancelled = true

GROUP BY DATE_TRUNC('month', invoicedate)

ORDER BY month;





































