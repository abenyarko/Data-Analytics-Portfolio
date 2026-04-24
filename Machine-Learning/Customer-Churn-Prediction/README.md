# Customer Churn Prediction — Machine Learning

## Overview

A binary classification project that predicts whether a telecom customer will churn (cancel their subscription). The pipeline uses multiple classification algorithms, compares performance, and applies threshold optimisation to balance precision and recall.

## Problem Statement

Customer churn is costly — acquiring a new customer is typically 5–7× more expensive than retaining an existing one. Identifying at-risk customers early allows the business to take targeted retention actions.

**Target variable**: `Churn` — 1 = churned, 0 = retained

## Dataset

The **IBM Telco Customer Churn dataset** (available on [Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)) contains 7,043 customer records with 20 features including:

- Demographics: `gender`, `SeniorCitizen`, `Partner`, `Dependents`
- Services: `PhoneService`, `InternetService`, `StreamingTV`, `TechSupport`
- Account: `tenure`, `Contract`, `PaperlessBilling`, `PaymentMethod`
- Financials: `MonthlyCharges`, `TotalCharges`

## Results

| Model | AUC-ROC | Precision | Recall | F1 |
|-------|---------|-----------|--------|-----|
| Logistic Regression | 0.843 | 0.64 | 0.58 | 0.61 |
| Random Forest | 0.861 | 0.67 | 0.62 | 0.64 |
| **Gradient Boosting** | **0.876** | **0.71** | **0.65** | **0.68** |

*Best model: Gradient Boosting with threshold optimised for F1.*

## Project Structure

```
Customer-Churn-Prediction/
├── README.md
└── churn_prediction.py     # Full classification pipeline
```

## How to Run

### Install Dependencies

```bash
pip install pandas numpy scikit-learn matplotlib seaborn imbalanced-learn
```

### Run the Pipeline

```bash
python churn_prediction.py
```

The script will:
1. Load and preprocess the Telco Churn dataset
2. Handle class imbalance with SMOTE
3. Train Logistic Regression, Random Forest, and Gradient Boosting
4. Compare models with cross-validation
5. Tune the best model with `GridSearchCV`
6. Evaluate on a held-out test set
7. Plot ROC curves, confusion matrix, and feature importances

## Techniques & Tools

| Tool / Technique | Purpose |
|-----------------|---------|
| `pandas` | Data loading and preprocessing |
| `scikit-learn` | Pipelines, models, metrics, cross-validation |
| `imbalanced-learn (SMOTE)` | Handling class imbalance |
| `matplotlib` / `seaborn` | Visualisation |
| `GridSearchCV` | Hyperparameter optimisation |
| Threshold optimisation | Maximise F1 on validation set |
| ROC / AUC, Precision-Recall curves | Model evaluation |

## Skills Demonstrated

- Binary classification with imbalanced data
- SMOTE for synthetic oversampling
- Multi-model comparison and selection
- Threshold optimisation for business objectives
- Confusion matrix, classification report
- ROC-AUC and Precision-Recall evaluation
- Interpretability via feature importance
