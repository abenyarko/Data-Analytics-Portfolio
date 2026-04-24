# Sales Performance Dashboard — Power BI

## Overview

An interactive Power BI dashboard that tracks sales performance across regions, product categories, and time periods. The report enables sales managers to monitor KPIs, identify underperforming segments, and spot seasonal trends at a glance.

## Business Questions Answered

- What are the total revenue and profit figures for the selected period?
- Which regions and product categories drive the most revenue?
- How do sales trend month-over-month and year-over-year?
- Which sales representatives are hitting their targets?
- What is the average order value and how does it vary by region?

## Dashboard Pages

| Page | Description |
|------|-------------|
| **Executive Summary** | High-level KPI cards: Total Revenue, Total Profit, Profit Margin %, Units Sold, and YoY growth |
| **Regional Analysis** | Map visual and bar charts breaking down revenue and profit by region |
| **Product Performance** | Treemap and ranked table of product categories and sub-categories by revenue and margin |
| **Sales Rep Tracker** | Individual rep performance vs. targets with conditional formatting |
| **Trend Analysis** | Line charts for monthly/quarterly revenue and profit with a slicer for year selection |

## Key DAX Measures

```dax
-- Total Revenue
Total Revenue = SUMX(Sales, Sales[Quantity] * Sales[Unit Price])

-- Total Profit
Total Profit = SUMX(Sales, (Sales[Unit Price] - Sales[Unit Cost]) * Sales[Quantity])

-- Profit Margin %
Profit Margin % = DIVIDE([Total Profit], [Total Revenue], 0)

-- Revenue YoY Growth %
Revenue YoY % =
VAR CurrentYear = [Total Revenue]
VAR PriorYear   = CALCULATE([Total Revenue], SAMEPERIODLASTYEAR('Date'[Date]))
RETURN DIVIDE(CurrentYear - PriorYear, PriorYear, 0)

-- Running Total Revenue
Running Total Revenue =
CALCULATE(
    [Total Revenue],
    DATESYTD('Date'[Date])
)
```

## Data Model

```
Sales (fact)
 ├── Date[DateKey]        → Date (dimension)
 ├── ProductKey           → Products (dimension)
 ├── CustomerKey          → Customers (dimension)
 ├── RegionKey            → Regions (dimension)
 └── SalesRepKey          → SalesReps (dimension)
```

## Sample Data

The `data/` folder contains a CSV file (`sales_data.csv`) used to populate the report. It includes:

| Column | Description |
|--------|-------------|
| OrderID | Unique order identifier |
| OrderDate | Date the order was placed |
| Region | Geographic sales region |
| SalesRep | Name of the sales representative |
| Category | Product category |
| SubCategory | Product sub-category |
| Product | Product name |
| Quantity | Number of units sold |
| UnitPrice | Selling price per unit |
| UnitCost | Cost per unit |

## How to Use

1. Download `Sales-Performance-Dashboard.pbix` *(link when published)*.
2. Open the file in **Power BI Desktop**.
3. Refresh the data connection pointing to `data/sales_data.csv`.
4. Publish to Power BI Service and configure scheduled refresh as needed.

## Screenshot

> *Dashboard screenshot to be added after publishing.*

## Tools & Skills Demonstrated

- Power BI Desktop (data modeling, report design)
- DAX (calculated columns, measures, time intelligence)
- Star schema data modeling
- Conditional formatting and KPI cards
- Drill-through and cross-filtering interactions
