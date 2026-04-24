# E-commerce Sales Analysis — SQL

## Overview

A multi-table SQL analysis of an e-commerce database covering orders, customers, products, and shipping. The queries answer key business questions about revenue performance, customer behaviour, and product profitability.

## Database Schema

```sql
customers   (customer_id, first_name, last_name, email, city, country, registration_date)
products    (product_id, product_name, category, subcategory, unit_cost, unit_price)
orders      (order_id, customer_id, order_date, ship_date, status, shipping_method)
order_items (item_id, order_id, product_id, quantity, unit_price, discount)
```

## Analyses in `ecommerce_sales_analysis.sql`

| Section | Description |
|---------|-------------|
| **0. Schema Setup** | DDL and sample data inserts |
| **1. Revenue Overview** | Total revenue, profit, margin, and order count |
| **2. Monthly Revenue Trend** | Month-over-month revenue with MoM growth % |
| **3. Top Products** | Top 10 products by revenue and profit |
| **4. Category Performance** | Revenue, profit, and margin by category |
| **5. Customer Lifetime Value** | Top 20 customers by total spend |
| **6. Cohort Retention** | Monthly cohort analysis of customer retention |
| **7. Geographic Analysis** | Revenue by country and city |
| **8. Order Status Breakdown** | Orders and revenue by fulfillment status |
| **9. Discount Impact** | Revenue and margin comparison by discount band |
| **10. Average Order Value** | AOV trend over time |

## How to Run

1. Create a PostgreSQL database:
   ```bash
   createdb ecommerce_db
   ```
2. Execute the script:
   ```bash
   psql -d ecommerce_db -f ecommerce_sales_analysis.sql
   ```

> The script is also compatible with MySQL 8+ with minor syntax adjustments (replace `EXTRACT` with `MONTH()`/`YEAR()` and use `LIMIT` instead of `FETCH FIRST`).

## Key SQL Techniques Demonstrated

- Window functions: `ROW_NUMBER()`, `RANK()`, `LAG()`, `SUM() OVER()`
- Common Table Expressions (CTEs)
- Aggregations with `GROUP BY`, `HAVING`
- `DATE_TRUNC` and `EXTRACT` for time-series analysis
- `CASE WHEN` for bucketing and conditional aggregation
- Multi-table `JOIN`s (INNER, LEFT)
- Subqueries and correlated subqueries
