# Retail Sales Exploratory Data Analysis — R

## Overview

An exploratory data analysis (EDA) of retail transaction data to uncover sales patterns, seasonal trends, and customer purchasing behaviour. The analysis uses R with the tidyverse ecosystem to clean, transform, and visualise the dataset.

## Objectives

- Understand the overall sales performance over time
- Identify top-performing product categories and subcategories
- Analyse regional sales distribution
- Detect seasonal patterns and weekly purchasing trends
- Highlight outliers and anomalies in the transaction data

## Key Findings

1. **Seasonality** — Q4 (October–December) consistently drives the highest revenue, peaking in November and December due to holiday shopping.
2. **Top Category** — Electronics accounts for ~48% of total revenue, with Laptops and Phones as the leading subcategories.
3. **Regional performance** — The North region generates the highest revenue, while the East region leads on volume (units sold).
4. **Weekend effect** — Approximately 35% of orders are placed on weekends, with Saturday being the single highest-order day.
5. **Repeat customers** — ~62% of revenue comes from repeat buyers (2+ orders in the period).

## Repository Structure

```
Retail-Sales-EDA/
├── README.md
├── retail_sales_eda.R      # Main analysis script
└── data/
    └── retail_sales.csv    # Sample retail transaction dataset
```

## How to Run

### Prerequisites

```r
install.packages(c("tidyverse", "lubridate", "scales", "ggthemes", "knitr"))
```

### Execution

```r
source("retail_sales_eda.R")
```

The script will generate plots and print summary tables to the console.

## Tools & Packages

| Package | Purpose |
|---------|---------|
| `dplyr` | Data wrangling and aggregation |
| `tidyr` | Reshaping and pivoting data |
| `ggplot2` | Data visualisation |
| `lubridate` | Date/time parsing and manipulation |
| `scales` | Axis formatting (currency, percentages) |
| `ggthemes` | Clean and professional plot themes |

## Skills Demonstrated

- Data cleaning: handling missing values, type conversion, outlier detection
- Feature engineering: extracting month, quarter, weekday from dates
- Aggregation and grouping with `dplyr`
- Multi-panel visualisations with `ggplot2` and `facet_wrap`
- Narrative data storytelling through annotated charts
