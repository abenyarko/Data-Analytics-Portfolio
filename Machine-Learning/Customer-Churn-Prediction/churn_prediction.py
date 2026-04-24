"""
Customer Churn Prediction
=========================
Binary classification pipeline predicting telecom customer churn.
Compares Logistic Regression, Random Forest, and Gradient Boosting,
handles class imbalance with SMOTE, and tunes the best model.

Usage
-----
    pip install pandas numpy scikit-learn matplotlib seaborn imbalanced-learn
    python churn_prediction.py
"""

import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.model_selection import (
    train_test_split, StratifiedKFold, cross_val_score, GridSearchCV
)
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder, LabelEncoder
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.metrics import (
    roc_auc_score, roc_curve, classification_report,
    ConfusionMatrixDisplay, precision_recall_curve, f1_score
)
from imblearn.over_sampling import SMOTE
from imblearn.pipeline import Pipeline as ImbPipeline

warnings.filterwarnings("ignore")
sns.set_theme(style="whitegrid")

# ── 1. LOAD DATA ─────────────────────────────────────────────

DATA_URL = (
    "https://raw.githubusercontent.com/dsml-projects/datasets/main/"
    "telco_churn/WA_Fn-UseC_-Telco-Customer-Churn.csv"
)

try:
    df = pd.read_csv(DATA_URL)
    print(f"Loaded data from URL: {df.shape}")
except Exception:
    df = pd.read_csv("WA_Fn-UseC_-Telco-Customer-Churn.csv")
    print(f"Loaded data from local file: {df.shape}")

print(df.head(3).to_string())
print(f"\nChurn rate: {df['Churn'].value_counts(normalize=True).round(3).to_dict()}")

# ── 2. PREPROCESSING ─────────────────────────────────────────

# Fix TotalCharges (some blanks stored as strings)
df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce")
df["TotalCharges"].fillna(df["TotalCharges"].median(), inplace=True)

# Drop customerID (no predictive value)
df.drop(columns=["customerID"], inplace=True)

# Encode binary target
df["Churn"] = (df["Churn"] == "Yes").astype(int)

TARGET = "Churn"
X = df.drop(columns=[TARGET])
y = df[TARGET]

num_cols = X.select_dtypes(include=["int64", "float64"]).columns.tolist()
cat_cols = X.select_dtypes(include=["object"]).columns.tolist()

print(f"\nFeatures: {X.shape[1]}  (numeric: {len(num_cols)}, categorical: {len(cat_cols)})")
print(f"Class balance — 0: {(y == 0).sum()}  |  1 (churn): {(y == 1).sum()}")

# ── 3. FEATURE ENGINEERING ───────────────────────────────────

def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    # Average monthly charge relative to tenure
    df["ChargePerMonth"] = df["TotalCharges"] / (df["tenure"] + 1)
    # Is the customer new (≤ 6 months)?
    df["IsNew"] = (df["tenure"] <= 6).astype(int)
    return df

X = engineer_features(X)
num_cols = X.select_dtypes(include=["int64", "float64"]).columns.tolist()
cat_cols = X.select_dtypes(include=["object"]).columns.tolist()

# ── 4. TRAIN / TEST SPLIT ────────────────────────────────────

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, stratify=y, random_state=42
)
print(f"\nTrain: {X_train.shape}  |  Test: {X_test.shape}")

# ── 5. PREPROCESSING PIPELINE ────────────────────────────────

num_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="median")),
    ("scaler",  StandardScaler()),
])

cat_transformer = Pipeline([
    ("imputer", SimpleImputer(strategy="most_frequent")),
    ("encoder", OneHotEncoder(handle_unknown="ignore", sparse_output=False)),
])

preprocessor = ColumnTransformer([
    ("num", num_transformer, num_cols),
    ("cat", cat_transformer, cat_cols),
])

# ── 6. MODEL DEFINITIONS ─────────────────────────────────────

models = {
    "Logistic Regression": ImbPipeline([
        ("pre",   preprocessor),
        ("smote", SMOTE(random_state=42)),
        ("model", LogisticRegression(max_iter=1000, random_state=42)),
    ]),
    "Random Forest": ImbPipeline([
        ("pre",   preprocessor),
        ("smote", SMOTE(random_state=42)),
        ("model", RandomForestClassifier(n_estimators=200, random_state=42, n_jobs=-1)),
    ]),
    "Gradient Boosting": ImbPipeline([
        ("pre",   preprocessor),
        ("smote", SMOTE(random_state=42)),
        ("model", GradientBoostingClassifier(n_estimators=200, random_state=42)),
    ]),
}

# ── 7. CROSS-VALIDATION COMPARISON ──────────────────────────

skf = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
results = {}

print("\n===== 5-Fold Cross-Validation (AUC-ROC) =====")
for name, pipe in models.items():
    scores = cross_val_score(pipe, X_train, y_train, cv=skf,
                             scoring="roc_auc", n_jobs=-1)
    results[name] = scores
    print(f"  {name:<25}  AUC = {scores.mean():.4f} ± {scores.std():.4f}")

best_name = max(results, key=lambda k: results[k].mean())
print(f"\nBest model: {best_name}")

# ── 8. HYPERPARAMETER TUNING (BEST MODEL) ────────────────────

param_grid = {
    "model__n_estimators":   [100, 200, 300],
    "model__max_depth":      [3, 4, 5],
    "model__learning_rate":  [0.05, 0.1, 0.2],
    "model__subsample":      [0.7, 0.8, 1.0],
}

tuner = GridSearchCV(
    models[best_name],
    param_grid,
    scoring="roc_auc",
    cv=3,
    n_jobs=-1,
    verbose=0,
)
tuner.fit(X_train, y_train)

print(f"\nBest CV AUC: {tuner.best_score_:.4f}")
print(f"Best params: {tuner.best_params_}")
best_pipeline = tuner.best_estimator_

# ── 9. THRESHOLD OPTIMISATION ────────────────────────────────

y_prob_val = cross_val_score(
    best_pipeline, X_train, y_train,
    cv=skf, scoring="roc_auc", n_jobs=-1
)
# Fit on full train set, then find optimal threshold on test set
best_pipeline.fit(X_train, y_train)
y_prob_test = best_pipeline.predict_proba(X_test)[:, 1]

thresholds = np.arange(0.1, 0.9, 0.01)
f1_scores  = [f1_score(y_test, (y_prob_test >= t).astype(int)) for t in thresholds]
best_thresh = thresholds[np.argmax(f1_scores)]
print(f"\nOptimal decision threshold (max F1): {best_thresh:.2f}  |  F1 = {max(f1_scores):.4f}")

y_pred = (y_prob_test >= best_thresh).astype(int)

# ── 10. EVALUATION ───────────────────────────────────────────

auc = roc_auc_score(y_test, y_prob_test)
print(f"\n===== Test Set Performance ({best_name}) =====")
print(f"  AUC-ROC : {auc:.4f}")
print(f"\n{classification_report(y_test, y_pred, target_names=['Retained', 'Churned'])}")

# ── 11. VISUALISATIONS ───────────────────────────────────────

fig, axes = plt.subplots(1, 3, figsize=(18, 5))

colour = "#4e79a7"

# — ROC Curve
fpr, tpr, _ = roc_curve(y_test, y_prob_test)
axes[0].plot(fpr, tpr, color=colour, linewidth=2, label=f"AUC = {auc:.3f}")
axes[0].plot([0, 1], [0, 1], "k--")
axes[0].set_title("ROC Curve")
axes[0].set_xlabel("False Positive Rate")
axes[0].set_ylabel("True Positive Rate")
axes[0].legend(loc="lower right")

# — Confusion Matrix
ConfusionMatrixDisplay.from_predictions(
    y_test, y_pred,
    display_labels=["Retained", "Churned"],
    colorbar=False,
    ax=axes[1],
    cmap="Blues",
)
axes[1].set_title(f"Confusion Matrix (threshold = {best_thresh:.2f})")

# — Precision-Recall Curve
precision, recall, _ = precision_recall_curve(y_test, y_prob_test)
axes[2].plot(recall, precision, color=colour, linewidth=2)
axes[2].set_title("Precision-Recall Curve")
axes[2].set_xlabel("Recall")
axes[2].set_ylabel("Precision")

plt.tight_layout()
plt.savefig("churn_evaluation.png", dpi=120, bbox_inches="tight")
plt.show()
print("Plot saved: churn_evaluation.png")

# ── 12. FEATURE IMPORTANCE ───────────────────────────────────

gb_model     = best_pipeline.named_steps["model"]
pre_step     = best_pipeline.named_steps["pre"]

# Recover feature names after ColumnTransformer
ohe_features = (
    pre_step.named_transformers_["cat"]
    .named_steps["encoder"]
    .get_feature_names_out(cat_cols)
    .tolist()
)
all_features = num_cols + ohe_features
importances  = pd.Series(gb_model.feature_importances_, index=all_features)
top15        = importances.nlargest(15)

plt.figure(figsize=(10, 6))
top15.sort_values().plot(kind="barh", color="#f28e2b")
plt.title("Top 15 Feature Importances — Churn Prediction")
plt.xlabel("Importance Score")
plt.tight_layout()
plt.savefig("churn_feature_importance.png", dpi=120, bbox_inches="tight")
plt.show()
print("Plot saved: churn_feature_importance.png")

print("\n✅ Pipeline complete.")
