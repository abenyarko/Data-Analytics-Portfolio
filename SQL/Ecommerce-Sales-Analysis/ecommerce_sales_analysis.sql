-- ============================================================
-- E-commerce Sales Analysis
-- Database: PostgreSQL 14+
-- Description: Multi-table analysis of orders, customers,
--              products, and revenue performance.
-- ============================================================


-- ── 0. SCHEMA SETUP ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS customers (
    customer_id       SERIAL PRIMARY KEY,
    first_name        VARCHAR(50)  NOT NULL,
    last_name         VARCHAR(50)  NOT NULL,
    email             VARCHAR(100) UNIQUE NOT NULL,
    city              VARCHAR(80),
    country           VARCHAR(80),
    registration_date DATE         NOT NULL
);

CREATE TABLE IF NOT EXISTS products (
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(120) NOT NULL,
    category     VARCHAR(60)  NOT NULL,
    subcategory  VARCHAR(60),
    unit_cost    NUMERIC(10,2) NOT NULL,
    unit_price   NUMERIC(10,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    order_id        SERIAL PRIMARY KEY,
    customer_id     INT  NOT NULL REFERENCES customers(customer_id),
    order_date      DATE NOT NULL,
    ship_date       DATE,
    status          VARCHAR(30) NOT NULL DEFAULT 'Completed',
    shipping_method VARCHAR(40)
);

CREATE TABLE IF NOT EXISTS order_items (
    item_id    SERIAL PRIMARY KEY,
    order_id   INT           NOT NULL REFERENCES orders(order_id),
    product_id INT           NOT NULL REFERENCES products(product_id),
    quantity   INT           NOT NULL,
    unit_price NUMERIC(10,2) NOT NULL,
    discount   NUMERIC(5,4)  NOT NULL DEFAULT 0
);

-- Sample data inserts (abbreviated – full dataset in data/seed.sql)
INSERT INTO customers (first_name, last_name, email, city, country, registration_date)
VALUES
  ('Alice',   'Johnson', 'alice.johnson@email.com',  'New York',    'USA',    '2021-03-15'),
  ('Bob',     'Williams','bob.williams@email.com',   'London',      'UK',     '2021-06-22'),
  ('Carol',   'Davis',   'carol.davis@email.com',    'Toronto',     'Canada', '2021-08-01'),
  ('David',   'Brown',   'david.brown@email.com',    'Sydney',      'Australia','2022-01-10'),
  ('Eve',     'Martinez','eve.martinez@email.com',   'Madrid',      'Spain',  '2022-02-28'),
  ('Frank',   'Lee',     'frank.lee@email.com',      'Singapore',   'Singapore','2022-04-05'),
  ('Grace',   'Wilson',  'grace.wilson@email.com',   'Chicago',     'USA',    '2022-05-18'),
  ('Henry',   'Taylor',  'henry.taylor@email.com',   'Berlin',      'Germany','2022-07-11'),
  ('Isla',    'Anderson','isla.anderson@email.com',  'Paris',       'France', '2022-09-03'),
  ('Jack',    'Thomas',  'jack.thomas@email.com',    'Los Angeles', 'USA',    '2022-10-20')
ON CONFLICT DO NOTHING;

INSERT INTO products (product_name, category, subcategory, unit_cost, unit_price)
VALUES
  ('ProBook 450 G9',           'Electronics',   'Laptops',     620.00, 899.99),
  ('ErgoPlus Office Chair',    'Furniture',     'Chairs',      140.00, 249.99),
  ('Galaxy S22',               'Electronics',   'Phones',      480.00, 749.99),
  ('Premium Ballpoint Set',    'Office Supplies','Pens',          5.00,  14.99),
  ('Executive Standing Desk',  'Furniture',     'Desks',       720.00,1199.99),
  ('UltraWide 34 Monitor',     'Electronics',   'Monitors',    320.00, 549.99),
  ('Copy Paper A4 (500 sh)',   'Office Supplies','Paper',         4.00,   9.99),
  ('MacBook Pro 14',           'Electronics',   'Laptops',    1400.00,1999.99),
  ('4-Drawer Filing Cabinet',  'Furniture',     'Cabinets',    170.00, 299.99),
  ('Wireless Keyboard & Mouse','Electronics',   'Accessories',  28.00,  59.99)
ON CONFLICT DO NOTHING;


-- ── 1. REVENUE OVERVIEW ──────────────────────────────────────

SELECT
    COUNT(DISTINCT o.order_id)                          AS total_orders,
    COUNT(DISTINCT o.customer_id)                       AS unique_customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)  AS total_revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)), 2) AS total_profit,
    ROUND(
        SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)) /
        NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 0) * 100
    , 2)                                                AS profit_margin_pct
FROM orders o
JOIN order_items oi ON o.order_id  = oi.order_id
JOIN products    p  ON oi.product_id = p.product_id
WHERE o.status = 'Completed';


-- ── 2. MONTHLY REVENUE TREND WITH MoM GROWTH ────────────────

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_date)::DATE           AS month,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)                    AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) /
        NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100
    , 2)                                                  AS mom_growth_pct
FROM monthly
ORDER BY month;


-- ── 3. TOP 10 PRODUCTS BY REVENUE ────────────────────────────

SELECT
    p.product_name,
    p.category,
    p.subcategory,
    SUM(oi.quantity)                                                     AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)       AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)), 2) AS profit,
    ROUND(
        SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)) /
        NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 0) * 100
    , 2)                                                                 AS margin_pct
FROM order_items oi
JOIN products    p  ON oi.product_id = p.product_id
JOIN orders      o  ON oi.order_id   = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.product_name, p.category, p.subcategory
ORDER BY revenue DESC
FETCH FIRST 10 ROWS ONLY;


-- ── 4. CATEGORY PERFORMANCE ──────────────────────────────────

SELECT
    p.category,
    COUNT(DISTINCT o.order_id)                                           AS orders,
    SUM(oi.quantity)                                                     AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)       AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)), 2) AS profit,
    ROUND(
        SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)) /
        NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 0) * 100
    , 2)                                                                 AS margin_pct,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) /
        NULLIF(COUNT(DISTINCT o.order_id), 0)
    , 2)                                                                 AS avg_order_value
FROM order_items oi
JOIN products    p  ON oi.product_id = p.product_id
JOIN orders      o  ON oi.order_id   = o.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY revenue DESC;


-- ── 5. CUSTOMER LIFETIME VALUE (TOP 20) ─────────────────────

WITH customer_stats AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name                              AS customer_name,
        c.country,
        COUNT(DISTINCT o.order_id)                                       AS total_orders,
        MIN(o.order_date)                                                AS first_order,
        MAX(o.order_date)                                                AS last_order,
        ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)  AS lifetime_value
    FROM customers   c
    JOIN orders      o  ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id    = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY c.customer_id, customer_name, c.country
)
SELECT
    RANK() OVER (ORDER BY lifetime_value DESC)  AS rank,
    customer_name,
    country,
    total_orders,
    first_order,
    last_order,
    ROUND(lifetime_value / total_orders, 2)      AS avg_order_value,
    lifetime_value
FROM customer_stats
ORDER BY lifetime_value DESC
FETCH FIRST 20 ROWS ONLY;


-- ── 6. MONTHLY COHORT RETENTION ──────────────────────────────

WITH cohorts AS (
    SELECT
        customer_id,
        DATE_TRUNC('month', MIN(order_date))::DATE AS cohort_month
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id
),
order_months AS (
    SELECT DISTINCT
        o.customer_id,
        DATE_TRUNC('month', o.order_date)::DATE AS order_month
    FROM orders o
    WHERE o.status = 'Completed'
),
cohort_activity AS (
    SELECT
        c.cohort_month,
        om.order_month,
        EXTRACT(YEAR FROM AGE(om.order_month, c.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(om.order_month, c.cohort_month)) AS months_since_cohort,
        COUNT(DISTINCT om.customer_id) AS active_customers
    FROM cohorts     c
    JOIN order_months om ON c.customer_id = om.customer_id
    GROUP BY c.cohort_month, om.order_month,
             months_since_cohort
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    cs.cohort_size,
    ca.months_since_cohort,
    ca.active_customers,
    ROUND(ca.active_customers::NUMERIC / cs.cohort_size * 100, 1) AS retention_rate_pct
FROM cohort_activity ca
JOIN cohort_sizes    cs ON ca.cohort_month = cs.cohort_month
ORDER BY ca.cohort_month, ca.months_since_cohort;


-- ── 7. REVENUE BY COUNTRY ────────────────────────────────────

SELECT
    c.country,
    COUNT(DISTINCT o.order_id)                                           AS orders,
    COUNT(DISTINCT o.customer_id)                                        AS customers,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)       AS revenue,
    ROUND(AVG(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)       AS avg_item_value
FROM customers   c
JOIN orders      o  ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id    = oi.order_id
WHERE o.status = 'Completed'
GROUP BY c.country
ORDER BY revenue DESC;


-- ── 8. ORDER STATUS BREAKDOWN ────────────────────────────────

SELECT
    status,
    COUNT(*)                                                             AS order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)                  AS pct_of_total,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)       AS revenue
FROM orders      o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY status
ORDER BY order_count DESC;


-- ── 9. DISCOUNT IMPACT ANALYSIS ──────────────────────────────

SELECT
    CASE
        WHEN oi.discount = 0          THEN '0% (No discount)'
        WHEN oi.discount <= 0.10      THEN '1–10%'
        WHEN oi.discount <= 0.20      THEN '11–20%'
        WHEN oi.discount <= 0.30      THEN '21–30%'
        ELSE '>30%'
    END                                                                  AS discount_band,
    COUNT(DISTINCT o.order_id)                                           AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)       AS net_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)                           AS gross_revenue,
    ROUND(
        SUM(oi.quantity * (oi.unit_price * (1 - oi.discount) - p.unit_cost)) /
        NULLIF(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 0) * 100
    , 2)                                                                 AS margin_pct
FROM order_items oi
JOIN orders   o ON oi.order_id   = o.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'Completed'
GROUP BY discount_band
ORDER BY MIN(oi.discount);


-- ── 10. AVERAGE ORDER VALUE TREND ────────────────────────────

SELECT
    DATE_TRUNC('month', o.order_date)::DATE                              AS month,
    COUNT(DISTINCT o.order_id)                                           AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2)       AS total_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) /
        NULLIF(COUNT(DISTINCT o.order_id), 0)
    , 2)                                                                 AS avg_order_value
FROM orders      o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY 1
ORDER BY 1;
