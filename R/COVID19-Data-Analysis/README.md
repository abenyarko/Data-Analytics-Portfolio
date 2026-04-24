# COVID-19 Global Trends Analysis — R

## Overview

An analysis and visualisation of global COVID-19 data exploring confirmed cases, deaths, and vaccination rates across countries and time. The report is written as an **R Markdown** document, producing a self-contained HTML report with interactive charts.

## Objectives

- Track the global trajectory of confirmed cases and deaths over time
- Compare pandemic waves across the top affected countries
- Analyse the relationship between vaccination rollout and death rates
- Calculate and visualise 7-day rolling averages to smooth reporting noise
- Produce a reproducible, shareable HTML report

## Key Findings

1. **Three distinct waves** are observable globally (2020, late 2020/early 2021, and the Omicron wave in 2022).
2. **Vaccination impact** — Countries with higher vaccination coverage (>60%) showed significantly lower case-fatality rates in 2022 compared to 2020.
3. **Top 5 by total cases** — USA, India, France, Germany, and Brazil led globally in total confirmed cases.
4. **Case-fatality rate** — The global average CFR declined from ~3.4% (2020) to ~0.8% (2022), reflecting both vaccination and improved treatments.

## Repository Structure

```
COVID19-Data-Analysis/
├── README.md
└── covid19_analysis.Rmd   # R Markdown report (renders to HTML)
```

## How to Run

### Prerequisites

```r
install.packages(c("tidyverse", "lubridate", "zoo", "scales",
                   "ggthemes", "rmarkdown", "knitr", "DT"))
```

### Render the Report

```r
rmarkdown::render("covid19_analysis.Rmd", output_format = "html_document")
```

This produces `covid19_analysis.html` in the same directory.

## Data Source

Data is sourced from the [Johns Hopkins University COVID-19 GitHub repository](https://github.com/CSSEGISandData/COVID-19) — specifically the time-series CSVs for global confirmed cases and deaths.

## Tools & Packages

| Package | Purpose |
|---------|---------|
| `tidyverse` | Data wrangling and visualisation |
| `lubridate` | Date manipulation |
| `zoo` | Rolling average calculations (`rollmean`) |
| `scales` | Axis formatting |
| `ggthemes` | Plot themes |
| `rmarkdown` / `knitr` | Reproducible report generation |
| `DT` | Interactive HTML tables |

## Skills Demonstrated

- Fetching and processing real-world public health data
- Computing rolling averages and rate metrics (CFR, per-100K)
- Multi-country time series comparison
- Reproducible research with R Markdown
- Parameterised reports with `params`
