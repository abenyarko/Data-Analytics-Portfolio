-- ============================================================
-- Customer Segmentation — RFM Analysis
-- Database: PostgreSQL 14+
-- Description: Score and segment customers using Recency,
--              Frequency, and Monetary (RFM) dimensions.
--
-- Assumes the schema from Ecommerce-Sales-Analysis exists:
--   customers, orders, order_items, products
-- ============================================================


-- ── 1. RAW RFM METRICS PER CUSTOMER ─────────────────────────

CREATE OR REPLACE VIEW vw_rfm_raw AS
WITH order_totals AS (
    SELECT
        o.customer_id,
        o.order_id,
        o.order_date,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS order_value
    FROM orders      o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY o.customer_id, o.order_id, o.order_date
)
SELECT
    customer_id,
    -- Recency: days since last purchase (lower = more recent)
    CURRENT_DATE - MAX(order_date)::DATE   AS recency_days,
    -- Frequency: number of distinct orders
    COUNT(DISTINCT order_id)               AS frequency,
    -- Monetary: total spend
    ROUND(SUM(order_value), 2)             AS monetary
FROM order_totals
GROUP BY customer_id;


-- ── 2. RFM SCORES (NTILE 1–5) ───────────────────────────────
--    For Recency: LOWER days = BETTER, so we invert the score.

CREATE OR REPLACE VIEW vw_rfm_scores AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    -- R score: highest recency_days (oldest) gets 1, lowest gets 5
    6 - NTILE(5) OVER (ORDER BY recency_days ASC)  AS r_score,
    -- F score: highest frequency gets 5
    NTILE(5) OVER (ORDER BY frequency ASC)          AS f_score,
    -- M score: highest monetary gets 5
    NTILE(5) OVER (ORDER BY monetary ASC)            AS m_score
FROM vw_rfm_raw;


-- ── 3. COMBINED RFM SCORE & SEGMENT LABEL ───────────────────

CREATE OR REPLACE VIEW vw_rfm_segments AS
SELECT
    s.customer_id,
    c.first_name || ' ' || c.last_name  AS customer_name,
    c.country,
    s.recency_days,
    s.frequency,
    s.monetary,
    s.r_score,
    s.f_score,
    s.m_score,
    (s.r_score + s.f_score + s.m_score) AS rfm_total,
    -- Segment assignment
    CASE
        WHEN s.r_score = 5 AND s.f_score >= 4                     THEN 'Champions'
        WHEN s.f_score >= 4                                        THEN 'Loyal Customers'
        WHEN s.r_score >= 4 AND s.f_score BETWEEN 2 AND 3         THEN 'Potential Loyalists'
        WHEN s.r_score = 5 AND s.f_score = 1                      THEN 'New Customers'
        WHEN s.r_score = 4 AND s.f_score = 1                      THEN 'Promising'
        WHEN s.r_score BETWEEN 2 AND 3 AND s.f_score >= 3         THEN 'At Risk'
        WHEN s.r_score <= 2 AND s.f_score >= 4                    THEN 'Can''t Lose Them'
        WHEN s.r_score BETWEEN 2 AND 3 AND s.f_score BETWEEN 1 AND 2 THEN 'About to Sleep'
        WHEN s.r_score <= 2 AND s.f_score <= 2                    THEN 'Hibernating'
        ELSE 'Needs Attention'
    END AS segment
FROM vw_rfm_scores s
JOIN customers      c ON s.customer_id = c.customer_id;


-- ── 4. SEGMENT SUMMARY ───────────────────────────────────────

SELECT
    segment,
    COUNT(*)                                          AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers,
    ROUND(AVG(recency_days), 1)                       AS avg_recency_days,
    ROUND(AVG(frequency), 1)                          AS avg_frequency,
    ROUND(AVG(monetary), 2)                           AS avg_monetary,
    ROUND(SUM(monetary), 2)                           AS total_monetary,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (), 1) AS pct_of_revenue
FROM vw_rfm_segments
GROUP BY segment
ORDER BY total_monetary DESC;


-- ── 5. FULL CUSTOMER-LEVEL RFM TABLE ────────────────────────

SELECT
    customer_id,
    customer_name,
    country,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_total,
    segment
FROM vw_rfm_segments
ORDER BY rfm_total DESC, monetary DESC;


-- ── 6. CHAMPIONS DETAIL ──────────────────────────────────────
-- Who are our best customers?

SELECT
    customer_name,
    country,
    recency_days,
    frequency,
    monetary
FROM vw_rfm_segments
WHERE segment = 'Champions'
ORDER BY monetary DESC;


-- ── 7. AT-RISK CUSTOMERS FOR WIN-BACK CAMPAIGN ───────────────
-- High-value customers who haven't purchased recently

SELECT
    customer_id,
    customer_name,
    country,
    recency_days,
    frequency,
    monetary,
    segment
FROM vw_rfm_segments
WHERE segment IN ('At Risk', 'Can''t Lose Them')
ORDER BY monetary DESC;


-- ── 8. REVENUE CONCENTRATION (PARETO CHECK) ─────────────────
-- What percentage of revenue comes from the top 20% of customers?

WITH ranked AS (
    SELECT
        customer_id,
        monetary,
        NTILE(5) OVER (ORDER BY monetary DESC) AS revenue_quintile
    FROM vw_rfm_raw
)
SELECT
    revenue_quintile,
    COUNT(*)                                                            AS customers,
    ROUND(SUM(monetary), 2)                                             AS total_monetary,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (), 1)       AS pct_of_total_revenue
FROM ranked
GROUP BY revenue_quintile
ORDER BY revenue_quintile;


-- ── 9. AVERAGE METRICS BY SEGMENT ───────────────────────────

SELECT
    segment,
    ROUND(AVG(r_score), 2)   AS avg_r,
    ROUND(AVG(f_score), 2)   AS avg_f,
    ROUND(AVG(m_score), 2)   AS avg_m,
    ROUND(AVG(rfm_total), 2) AS avg_rfm_total
FROM vw_rfm_segments
GROUP BY segment
ORDER BY avg_rfm_total DESC;
