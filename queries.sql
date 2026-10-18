-- ============================================================
-- Loan Funnel & Portfolio Analysis | SQLite (synthetic data)
-- Tables: customers, applications, repayments
-- ============================================================

-- Q1. Overall funnel: applied -> approved -> disbursed (aggregate functions)
SELECT COUNT(*) AS applied,
       SUM(status='Approved') AS approved,
       SUM(disbursed) AS disbursed,
       ROUND(100.0*SUM(status='Approved')/COUNT(*),1) AS approval_pct,
       ROUND(100.0*SUM(disbursed)/SUM(status='Approved'),1) AS approved_to_disbursed_pct
FROM applications;

-- Q2. Funnel by channel (find where leads drop)  -> RCA starting point
SELECT channel,
       COUNT(*) AS applied,
       ROUND(100.0*SUM(status='Approved')/COUNT(*),1) AS approval_pct,
       ROUND(100.0*SUM(disbursed)/SUM(status='Approved'),1) AS approved_to_disbursed_pct,
       ROUND(100.0*SUM(disbursed)/COUNT(*),1) AS end_to_end_pct
FROM applications
GROUP BY channel
ORDER BY end_to_end_pct DESC;

-- Q3. Rejection reasons (JOIN + aggregate)
SELECT rejection_reason, COUNT(*) AS cnt,
       ROUND(100.0*COUNT(*)/SUM(COUNT(*)) OVER (),1) AS pct_of_rejections   -- window function
FROM applications
WHERE status='Rejected'
GROUP BY rejection_reason
ORDER BY cnt DESC;

-- Q4. Approval rate by bureau score band (JOIN + CASE)
SELECT CASE WHEN c.bureau_score<600 THEN '1. <600'
            WHEN c.bureau_score<650 THEN '2. 600-649'
            WHEN c.bureau_score<700 THEN '3. 650-699'
            ELSE '4. 700+' END AS score_band,
       COUNT(*) AS applications,
       ROUND(100.0*SUM(a.status='Approved')/COUNT(*),1) AS approval_pct
FROM applications a JOIN customers c ON c.customer_id=a.customer_id
GROUP BY score_band ORDER BY score_band;

-- Q5. Default rate by employment type and loan type (JOIN 3 tables)
SELECT c.employment, a.loan_type,
       COUNT(*) AS loans,
       ROUND(100.0*SUM(r.defaulted)/COUNT(*),1) AS default_pct
FROM repayments r
JOIN applications a ON a.app_id=r.app_id
JOIN customers c ON c.customer_id=a.customer_id
GROUP BY c.employment, a.loan_type
ORDER BY default_pct DESC;

-- Q6. Monthly applications with month-over-month change (CTE + LAG)
WITH monthly AS (
  SELECT strftime('%Y-%m', app_date) AS month, COUNT(*) AS apps,
         SUM(disbursed) AS disbursed
  FROM applications GROUP BY month
)
SELECT month, apps,
       LAG(apps) OVER (ORDER BY month) AS prev_apps,
       ROUND(100.0*(apps-LAG(apps) OVER (ORDER BY month))/LAG(apps) OVER (ORDER BY month),1) AS mom_pct,
       SUM(disbursed) OVER (ORDER BY month) AS cumulative_disbursed   -- running total
FROM monthly;

-- Q7. Top 3 cities by disbursed amount per loan type (CTE + RANK)
WITH city_amt AS (
  SELECT c.city, a.loan_type, SUM(a.amount) AS disbursed_amt
  FROM applications a JOIN customers c ON c.customer_id=a.customer_id
  WHERE a.disbursed=1
  GROUP BY c.city, a.loan_type
), ranked AS (
  SELECT *, RANK() OVER (PARTITION BY loan_type ORDER BY disbursed_amt DESC) AS rnk
  FROM city_amt
)
SELECT * FROM ranked WHERE rnk<=3;

-- Q8. Customers with bureau score above the average of their income band (subquery)
SELECT c.customer_id, c.income_band, c.bureau_score
FROM customers c
WHERE c.bureau_score > (SELECT AVG(bureau_score) FROM customers WHERE income_band=c.income_band)
LIMIT 10;

-- Q9. Repeat applicants: second application vs first (ROW_NUMBER)
WITH numbered AS (
  SELECT customer_id, app_id, status,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY app_date) AS app_no
  FROM applications
)
SELECT app_no, COUNT(*) AS apps, ROUND(100.0*SUM(status='Approved')/COUNT(*),1) AS approval_pct
FROM numbered GROUP BY app_no;
