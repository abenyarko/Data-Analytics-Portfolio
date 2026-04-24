"""
House Price Prediction
======================
End-to-end regression pipeline using XGBoost to predict
residential property sale prices (Ames Housing dataset).

Usage
-----
    pip install pandas numpy scikit-learn xgboost matplotlib seaborn
    python house_price_prediction.py

The script downloads the dataset from a public URL.  If offline,
place train.csv / test.csv in the same directory.
"""

import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.model_selection import train_test_split, KFold, cross_val_score
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OrdinalEncoder, StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.model_selection import RandomizedSearchCV
from xgboost import XGBRegressor

warnings.filterwarnings("ignore")
sns.set_theme(style="whitegrid")


# ── 1. LOAD DATA ─────────────────────────────────────────────

DATA_URL = (
    "https://raw.githubusercontent.com/dsml-projects/datasets/main/"
    "ames_housing/train.csv"
)

try:
    df = pd.read_csv(DATA_URL)
    print(f"Loaded data from URL: {df.shape}")
except Exception:
    # Fall back to local file
    df = pd.read_csv("train.csv")
    print(f"Loaded data from local file: {df.shape}")

print(df[["SalePrice", "GrLivArea", "OverallQual", "YearBuilt"]].describe().round(1))


# ── 2. EXPLORATORY CHECKS ────────────────────────────────────

print(f"\nMissing values (top 10):\n{df.isnull().sum().sort_values(ascending=False).head(10)}")
print(f"\nTarget skew (SalePrice): {df['SalePrice'].skew():.3f}")

# Distribution of SalePrice
fig, axes = plt.subplots(1, 2, figsize=(12, 4))
sns.histplot(df["SalePrice"], kde=True, ax=axes[0], color="#4e79a7")
axes[0].set_title("SalePrice Distribution")
axes[0].set_xlabel("Sale Price (USD)")

sns.histplot(np.log1p(df["SalePrice"]), kde=True, ax=axes[1], color="#f28e2b")
axes[1].set_title("log(SalePrice + 1) Distribution")
axes[1].set_xlabel("log(Sale Price + 1)")
plt.tight_layout()
plt.savefig("saleprice_distribution.png", dpi=120, bbox_inches="tight")
plt.show()
print("Plot saved: saleprice_distribution.png")


# ── 3. FEATURE ENGINEERING ───────────────────────────────────

def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # Total square footage
    df["TotalSF"] = (
        df.get("TotalBsmtSF", 0).fillna(0)
        + df.get("1stFlrSF",  0).fillna(0)
        + df.get("2ndFlrSF",  0).fillna(0)
    )

    # Total bathrooms
    df["TotalBath"] = (
        df.get("FullBath",   0).fillna(0)
        + df.get("HalfBath",  0).fillna(0) * 0.5
        + df.get("BsmtFullBath", 0).fillna(0)
        + df.get("BsmtHalfBath", 0).fillna(0) * 0.5
    )

    # House age and remodel age at time of sale
    df["HouseAge"]   = df["YrSold"] - df["YearBuilt"]
    df["RemodelAge"] = df["YrSold"] - df.get("YearRemodAdd", df["YearBuilt"])

    # Log-transform heavily skewed numeric features
    skewed_cols = ["GrLivArea", "LotArea", "TotalSF"]
    for col in skewed_cols:
        if col in df.columns:
            df[f"log_{col}"] = np.log1p(df[col])

    # Interaction: quality × living area
    df["QualArea"] = df["OverallQual"] * df["GrLivArea"]

    return df


df = engineer_features(df)

# ── 4. DEFINE FEATURES & TARGET ──────────────────────────────

TARGET = "SalePrice"
y = np.log1p(df[TARGET])  # log-transform target for better residual behaviour

DROP_COLS = [TARGET, "Id"]
X = df.drop(columns=[c for c in DROP_COLS if c in df.columns])

# Separate numeric and categorical columns
num_cols = X.select_dtypes(include=["int64", "float64"]).columns.tolist()
cat_cols = X.select_dtypes(include=["object", "category"]).columns.tolist()

print(f"\nFeatures: {X.shape[1]}  (numeric: {len(num_cols)}, categorical: {len(cat_cols)})")

# ── 5. PREPROCESSING PIPELINE ────────────────────────────────

num_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="median")),
    ("scaler",  StandardScaler()),
])

cat_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="most_frequent")),
    ("encoder", OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1)),
])

preprocessor = ColumnTransformer([
    ("num", num_transformer, num_cols),
    ("cat", cat_transformer, cat_cols),
])

# ── 6. TRAIN / TEST SPLIT ────────────────────────────────────

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)
print(f"\nTrain: {X_train.shape}  |  Test: {X_test.shape}")

# ── 7. MODEL PIPELINE ────────────────────────────────────────

model_pipeline = Pipeline([
    ("pre",   preprocessor),
    ("model", XGBRegressor(
        n_estimators=500,
        learning_rate=0.05,
        max_depth=4,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        n_jobs=-1,
        verbosity=0,
    )),
])

# ── 8. CROSS-VALIDATION ──────────────────────────────────────

kf = KFold(n_splits=5, shuffle=True, random_state=42)
cv_rmse = np.sqrt(-cross_val_score(
    model_pipeline, X_train, y_train,
    scoring="neg_mean_squared_error", cv=kf, n_jobs=-1
))
print(f"\n5-Fold CV RMSE (log scale): {cv_rmse.mean():.4f} ± {cv_rmse.std():.4f}")

# ── 9. HYPERPARAMETER TUNING ─────────────────────────────────

param_dist = {
    "model__n_estimators":     [300, 500, 700],
    "model__learning_rate":    [0.01, 0.05, 0.1],
    "model__max_depth":        [3, 4, 5, 6],
    "model__subsample":        [0.7, 0.8, 0.9],
    "model__colsample_bytree": [0.6, 0.7, 0.8],
    "model__reg_alpha":        [0, 0.1, 0.5],
    "model__reg_lambda":       [1, 1.5, 2],
}

search = RandomizedSearchCV(
    model_pipeline,
    param_distributions=param_dist,
    n_iter=20,
    scoring="neg_mean_squared_error",
    cv=3,
    random_state=42,
    n_jobs=-1,
    verbose=0,
)
search.fit(X_train, y_train)

print(f"\nBest CV RMSE: {np.sqrt(-search.best_score_):.4f}")
print(f"Best params:  {search.best_params_}")

best_model = search.best_estimator_

# ── 10. EVALUATION ───────────────────────────────────────────

y_pred_log = best_model.predict(X_test)
y_pred     = np.expm1(y_pred_log)
y_true     = np.expm1(y_test)

rmse = np.sqrt(mean_squared_error(y_true, y_pred))
mae  = mean_absolute_error(y_true, y_pred)
r2   = r2_score(y_true, y_pred)

print("\n===== Test Set Performance =====")
print(f"  RMSE : ${rmse:,.0f}")
print(f"  MAE  : ${mae:,.0f}")
print(f"  R²   : {r2:.4f}")

# ── 11. RESIDUAL PLOT ────────────────────────────────────────

fig, axes = plt.subplots(1, 2, figsize=(14, 5))

axes[0].scatter(y_true, y_pred, alpha=0.4, color="#4e79a7", edgecolors="white", linewidths=0.4)
max_val = max(y_true.max(), y_pred.max())
axes[0].plot([0, max_val], [0, max_val], "r--", linewidth=1.5)
axes[0].set_title(f"Actual vs Predicted  |  R² = {r2:.3f}")
axes[0].set_xlabel("Actual Sale Price (USD)")
axes[0].set_ylabel("Predicted Sale Price (USD)")

residuals = y_true - y_pred
sns.histplot(residuals, kde=True, ax=axes[1], color="#f28e2b")
axes[1].axvline(0, color="red", linestyle="--")
axes[1].set_title("Residuals Distribution")
axes[1].set_xlabel("Residual (USD)")

plt.tight_layout()
plt.savefig("prediction_results.png", dpi=120, bbox_inches="tight")
plt.show()
print("Plot saved: prediction_results.png")

# ── 12. FEATURE IMPORTANCE ───────────────────────────────────

xgb_model   = best_model.named_steps["model"]
feat_names  = (
    num_cols
    + [f"cat_{i}" for i in range(len(cat_cols))]
)
importances = pd.Series(xgb_model.feature_importances_, index=feat_names)
top20       = importances.nlargest(20)

plt.figure(figsize=(10, 7))
top20.sort_values().plot(kind="barh", color="#4e79a7")
plt.title("Top 20 Feature Importances (XGBoost)")
plt.xlabel("Importance Score")
plt.tight_layout()
plt.savefig("feature_importances.png", dpi=120, bbox_inches="tight")
plt.show()
print("Plot saved: feature_importances.png")

print("\n✅ Pipeline complete.")
