# Customer Segmentation (RFM Analysis) — SQL

## Overview

Customer segmentation using the **RFM model** (Recency, Frequency, Monetary) to classify customers into actionable marketing segments. The analysis uses pure SQL window functions and CTEs to score and label each customer, producing a ready-to-use segmentation table.

## What is RFM?

| Dimension | Definition |
|-----------|-----------|
| **Recency (R)** | How recently a customer made a purchase (days since last order) |
| **Frequency (F)** | How many times the customer has purchased |
| **Monetary (M)** | How much the customer has spent in total |

Each dimension is scored 1–5 (5 = best). Customers are then assigned to segments based on their combined score.

## Segments

| Segment | RFM Criteria | Description |
|---------|-------------|-------------|
| Champions | R=5, F≥4 | Bought recently, buy often, and spend the most |
| Loyal Customers | F≥4 | Buy regularly and have high frequency |
| Potential Loyalists | R≥4, F 2–3 | Recent customers with growing engagement |
| At Risk | R=2–3, F≥3 | Were good customers but haven't bought recently |
| Can't Lose Them | R≤2, F≥4 | Made large purchases but not seen for a while |
| Hibernating | R≤2, F≤2 | Low recency and frequency |
| New Customers | R=5, F=1 | Bought recently but only once |
| Promising | R=4, F=1 | Recent one-time buyers |

## Repository Structure

```
Customer-Segmentation/
├── README.md
└── customer_segmentation.sql   # Full RFM analysis script
```

## How to Run

```bash
psql -d ecommerce_db -f customer_segmentation.sql
```

*Assumes the schema from the [E-commerce Sales Analysis](../Ecommerce-Sales-Analysis/) project is already created.*

## Key SQL Techniques Demonstrated

- `NTILE(5)` for percentile-based scoring
- Multi-layered CTEs for staged transformations
- `CASE WHEN` for segment labelling
- Window functions with `PARTITION BY`
- Self-referencing aggregations with `GROUP BY`
