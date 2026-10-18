# Loan Funnel & Portfolio Analysis (SQL)

I analysed a loan application dataset to understand where applicants drop off in the funnel (applied -> approved -> disbursed) and which customer segments carry more default risk.

**Data:** Synthetic dataset created with `generate_data.py` (5,000 customers, about 6,000 applications, about 3,700 disbursed loans, Jan-Sep 2026).
**Tool:** SQLite
**SQL concepts used:** JOINs, subqueries, CTEs, window functions (LAG, RANK, ROW_NUMBER, running totals), aggregates, CASE.

## How to run
```
python generate_data.py
sqlite3 loans.db < queries.sql
```
(Or open `loans.db` in DB Browser for SQLite and run the queries one by one.)

## What I found
1. **Funnel:** 78.6% of applications were approved, and 78.0% of approved loans were disbursed.
2. **Where leads drop:** Approval rates are similar across channels (about 77-84%), but only 60.8% of approved Paid Ads applicants were disbursed, against 85-89% for other channels. End-to-end conversion is 47.2% for Paid Ads and 74.0% for Referral. The drop happens after approval, not at underwriting.
3. **Rejections:** Low bureau score is the top reason (46% of rejections). Approval falls to 59% for scores below 600, compared with about 85% above 600.
4. **Risk:** Self-employed borrowers with business loans default the most (17.9%). Salaried personal loans default at 7.0%.
5. **Trend:** Applications were fairly flat from January to August, then fell 13.8% month over month in September (September may be incomplete).

## Recommendations
- Look into the post-approval experience for Paid Ads leads (offer clarity, KYC steps, follow-up speed) before increasing ad spend.
- Add stricter checks or lower limits for self-employed business loans.
- Pre-screen applicants with scores below 600 to cut down on avoidable rejections.

## Limitations
The data is synthetic, so the patterns are for practice and illustration. Real data would need cleaning and validation, and a drop-off cause can only be confirmed with further investigation.
