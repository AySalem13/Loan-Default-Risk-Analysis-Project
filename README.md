# Loan Default Risk Analysis — Horizon Financial Group

## Business Problem

Horizon Financial Group has issued 601 personal loans across 2024–2025. Management flagged a default rate of roughly 1 in 4 loans (24.3%) — well above their 12% target. The VP of Risk asked for a data-driven analysis of the existing loan book to identify which borrower and loan characteristics actually predict default, in order to inform changes to the credit scoring model and approval thresholds.

**Data provided:**
- `borrower_profiles.csv` (500 rows) — demographics, income, credit score, employment status, years employed
- `loan_applications.csv` (601 rows) — loan amount, term, interest rate, DTI ratio, loan purpose, loan status, days delinquent, default flag

## Key Analytical Decision: Defining "Default Rate"

Before any segmentation, I identified that `loan_status` includes 4 states: `Current` (239), `Late` (103), `Default` (146), `Paid Off` (113). Since 342 loans (57%) are still open and haven't reached a final outcome, a single "default rate" number is misleading on its own.

**Approach used throughout this analysis:** report the raw default rate across all loans (the headline number), and separately report the default rate among *resolved* loans only (Default + Paid Off), to show how risk compounds once loans mature. This is called out explicitly rather than picking one number and hiding the ambiguity.

- All loans (601): **24.3%** default rate
- Resolved loans only (259): **56.4%** default rate

This distinction is used per-segment throughout Q1.

## Tools Used

| Tool | Purpose |
|---|---|
| SQL Server (SSMS) | Data cleaning validation, segment analysis, default rate calculations |
| Excel | Correlation matrix, pivot tables, chart prototyping |
| Power BI | Interactive final dashboard *(in progress)* |

## Questions & Findings

### Q1: Default rate by credit score bucket

| Bucket | Loan Count | Default Rate (All Loans) | Default Rate (Resolved Only) |
|---|---|---|---|
| 520–599 | 116 | 49.1% | 81.4% |
| 600–649 | 93 | 29.0% | 62.8% |
| 650–699 | 75 | 28.0% | 67.7% |
| 700–749 | 86 | 16.3% | 41.2% |
| 750+ | 231 | 11.7% | 33.3% |

**Finding:** Clear, consistent inverse relationship — default rate falls as credit score rises. The 520–599 bucket shows a 49.1% raw default rate; among loans in this bucket that have already reached a final outcome, 81.4% ended in default — suggesting the true failure rate is likely to climb further as its remaining open loans resolve. **Credit score is the strongest single predictor of default in this dataset.**

### Q2: DTI ratio and default risk

Initial 5-bucket segmentation showed a non-monotonic pattern (a dip at 75–100% before rising again), which I hypothesized was sample-size noise around a real threshold near 50%. Testing a simple 2-bucket split (<50% vs. ≥50%) confirmed this:

| Bucket | Loan Count | Default Rate |
|---|---|---|
| Under 50% | 330 | 16.1% |
| 50%+ | 271 | 34.3% |

**Finding:** DTI ratio shows a clear risk threshold at 50% — default rate more than doubles above this line, with solid sample sizes on both sides. **Recommendation: cap loan approvals at 50% DTI, or apply stricter terms/higher scrutiny above that threshold.**

### Q3: Loan purpose & loan amount

**Default rate by loan purpose:**

| Purpose | Count | Default Rate |
|---|---|---|
| Wedding | 56 | 32.1% |
| Home Improvement | 70 | 28.6% |
| Auto Loan | 59 | 27.1% |
| Business Loan | 58 | 24.1% |
| Vacation | 62 | 22.6% |
| Education | 53 | 22.6% |
| Major Purchase | 68 | 22.1% |
| Debt Consolidation | 51 | 21.6% |
| Moving | 56 | 21.4% |
| Medical Expenses | 68 | 20.6% |

**Finding:** Loan purpose shows a modest spread (20.6%–32.1%), but the gap is far smaller than credit score or DTI, and category sample sizes (50–70 loans each) limit confidence in ranking individual purposes precisely. **Loan purpose is a secondary signal, not a primary underwriting lever.**

**Average loan amount, defaulted vs. non-defaulted:**

| Group | Avg Loan Amount |
|---|---|
| Non-defaulted | $22,012.75 |
| Defaulted | $22,570.55 |

**Finding:** No meaningful difference (~2.5% gap). **Loan amount is not a driver of default risk.**

### Q4: Employment status & years employed

**Default rate by employment status:**

| Status | Count | Default Rate |
|---|---|---|
| Full-Time | 305 | 23.9% |
| Retired | 60 | 23.3% |
| Contract | 66 | 22.7% |
| Self-Employed | 105 | 24.8% |
| Part-Time | 65 | 27.6% |

**Finding:** Tight band (22.7%–27.6%), no meaningful separation. **Employment status alone is not predictive.** (Note: no unemployed borrowers exist in this dataset — Horizon's underwriting likely screens these out pre-approval.)

**Default rate by years employed:**

| Bucket | Count | Default Rate |
|---|---|---|
| < 2 years | 84 | 34.5% |
| 2+ years | 517 | 22.6% |

**Finding:** A real ~12-point gap with solid sample sizes on both sides. **Years employed is a moderate, secondary predictor** — borrowers with under 2 years at their job default at a meaningfully higher rate.

## Correlation Analysis (Excel)

Built a full correlation matrix across all numeric variables against `defaulted`:

| Variable | Correlation with Default |
|---|---|
| Credit score | -0.286 |
| Interest rate | 0.199 |
| DTI ratio | 0.192 |
| Income | -0.082 |
| Loan amount | 0.018 |

**Key insight — multicollinearity:** Interest rate shows a 0.199 correlation with default, but also a -0.755 correlation with credit score — by far the strongest relationship in the matrix. This makes sense: Horizon already prices loans based on credit score at approval, so interest rate is largely a *proxy* for credit score rather than an independent risk signal. Recommending "watch interest rate" as a separate lever would mostly double-count a signal already captured by credit score. **Credit score and DTI ratio remain the two genuinely independent, actionable predictors.**

## Top 3 Risk Factors & Recommendations

1. **Credit score** — strongest independent predictor (r = -0.286; 49.1% default rate below 600 vs. 11.7% at 750+). *Recommendation: raise minimum approval threshold, or apply significantly stricter terms below 650.*
2. **DTI ratio** — clear threshold effect at 50% (16.1% vs. 34.3% default rate). *Recommendation: cap approvals at 50% DTI.*
3. **Years employed** — borrowers under 2 years tenure default at 34.5% vs. 22.6% for 2+ years. *Recommendation: treat <2 years employment as an additional risk flag, particularly when combined with borderline credit score or DTI.*

**Ruled out:** Loan amount, employment status category, and (independently) interest rate — the latter due to multicollinearity with credit score.

## Project Source

The business scenario and objectives for this project were sourced from [AnalystBuilder](https://www.analystbuilder.com/projects/loan-default-risk-analysis-Vjfdl?tab=overview).
