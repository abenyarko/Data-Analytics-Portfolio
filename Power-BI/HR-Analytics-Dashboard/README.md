# HR Analytics Dashboard — Power BI

## Overview

An interactive Power BI dashboard providing HR leaders with a comprehensive view of workforce composition, attrition trends, and employee demographics. The report supports data-driven decisions around retention, hiring, and diversity initiatives.

## Business Questions Answered

- What is the current headcount and how has it changed over time?
- Which departments and job roles have the highest attrition rates?
- What are the key drivers of employee attrition?
- How does compensation compare across departments and levels?
- What is the demographic breakdown of the workforce (age, gender, education)?

## Dashboard Pages

| Page | Description |
|------|-------------|
| **Workforce Overview** | Headcount by department, job level, and employment type with trend line |
| **Attrition Analysis** | Attrition rate KPIs, attrition by department/role, and monthly leavers trend |
| **Demographics** | Age distribution histogram, gender split, and education level breakdown |
| **Compensation Analysis** | Average salary heatmap by department and job level; salary band distribution |
| **Retention Risk** | Employees flagged as high attrition risk based on satisfaction, tenure, and overtime |

## Key DAX Measures

```dax
-- Total Headcount
Headcount = COUNTROWS(Employees)

-- Attrition Count
Attrition Count = CALCULATE([Headcount], Employees[Attrition] = "Yes")

-- Attrition Rate %
Attrition Rate % = DIVIDE([Attrition Count], [Headcount], 0)

-- Average Monthly Income
Avg Monthly Income = AVERAGE(Employees[MonthlyIncome])

-- Active Employees
Active Employees = CALCULATE([Headcount], Employees[Attrition] = "No")

-- Avg Years at Company
Avg Tenure = AVERAGE(Employees[YearsAtCompany])
```

## Data Model

```
Employees (fact + dimension — denormalised HR dataset)
 ├── EmployeeID
 ├── Department
 ├── JobRole
 ├── Attrition (Yes/No)
 ├── Age, Gender, Education
 ├── MonthlyIncome, JobLevel
 ├── YearsAtCompany, YearsInCurrentRole
 ├── JobSatisfaction, WorkLifeBalance
 └── OverTime
```

## Sample Data

The `data/` folder contains `hr_data.csv` — a synthetic HR dataset of 1,470 employees adapted from the IBM HR Analytics dataset. Fields include:

| Column | Description |
|--------|-------------|
| EmployeeID | Unique employee identifier |
| Age | Employee age |
| Department | Department name |
| JobRole | Job title |
| Attrition | Whether the employee left (Yes/No) |
| Gender | Employee gender |
| Education | Education level (1–5) |
| MonthlyIncome | Monthly salary |
| JobLevel | Seniority level (1–5) |
| YearsAtCompany | Tenure at the company |
| JobSatisfaction | Job satisfaction score (1–4) |
| OverTime | Whether employee works overtime (Yes/No) |
| WorkLifeBalance | Work-life balance score (1–4) |

## How to Use

1. Download `HR-Analytics-Dashboard.pbix` *(link when published)*.
2. Open in **Power BI Desktop**.
3. Refresh the data source pointing to `data/hr_data.csv`.
4. Use slicers on Department, Gender, and Job Level to filter views.

## Screenshot

> *Dashboard screenshot to be added after publishing.*

## Tools & Skills Demonstrated

- Power BI Desktop (report design, bookmarks, drill-through)
- DAX (measures, calculated columns, CALCULATE with filters)
- HR domain knowledge (attrition, headcount, compensation analysis)
- Data storytelling with conditional formatting and color coding
