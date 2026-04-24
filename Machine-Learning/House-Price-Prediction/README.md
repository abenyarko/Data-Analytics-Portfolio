# House Price Prediction — Machine Learning

## Overview

A supervised machine learning project that predicts residential property prices using gradient boosting (XGBoost). The pipeline covers end-to-end data preprocessing, feature engineering, model training, hyperparameter tuning, and evaluation.

## Problem Statement

Given a set of physical and locational property attributes, predict the **sale price** of a house. This is a regression problem — the target variable is continuous.

## Dataset

The project uses the **Ames Housing Dataset** (available on [Kaggle](https://www.kaggle.com/c/house-prices-advanced-regression-techniques)). It contains 79 explanatory variables describing almost every aspect of residential homes in Ames, Iowa.

Key features used:
- **Structural**: `GrLivArea` (living area), `TotalBsmtSF`, `GarageArea`, `YearBuilt`
- **Quality**: `OverallQual`, `OverallCond`, `KitchenQual`, `ExterQual`
- **Neighbourhood**: `Neighborhood`
- **Rooms**: `BedroomAbvGr`, `TotRmsAbvGrd`, `FullBath`, `HalfBath`

## Results

| Metric | Value |
|--------|-------|
| RMSE (test) | ~$20,500 |
| MAE (test)  | ~$14,800 |
| R² (test)   | ~0.912 |

## Project Structure

```
House-Price-Prediction/
├── README.md
└── house_price_prediction.py   # Full ML pipeline
```

## How to Run

### Install Dependencies

```bash
pip install pandas numpy scikit-learn xgboost matplotlib seaborn
```

### Run the Pipeline

```bash
python house_price_prediction.py
```

The script will:
1. Load and preprocess the data
2. Engineer new features
3. Train an XGBoost model with cross-validation
4. Tune hyperparameters with `RandomizedSearchCV`
5. Evaluate on a held-out test set
6. Plot feature importances and actual vs predicted values

## Techniques & Tools

| Tool / Technique | Purpose |
|-----------------|---------|
| `pandas` | Data loading and manipulation |
| `scikit-learn` | Preprocessing, pipeline, cross-validation, metrics |
| `XGBoost` | Gradient boosting regressor |
| `matplotlib` / `seaborn` | Visualisation |
| `RandomizedSearchCV` | Hyperparameter optimisation |
| Feature engineering | Log-transform of skewed features, interaction terms |
| `Pipeline` + `ColumnTransformer` | Clean, leak-free preprocessing |

## Skills Demonstrated

- End-to-end ML pipeline construction
- Handling missing values and categorical encoding
- Feature engineering (log transforms, interaction features)
- Gradient boosting with XGBoost
- Cross-validated hyperparameter search
- Model evaluation: RMSE, MAE, R², residual plots
- Feature importance visualisation
