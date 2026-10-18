"""Creates a synthetic loan application dataset in SQLite (loans.db).
Tables: customers, applications, repayments."""
import sqlite3, random
from datetime import date, timedelta

random.seed(42)
conn = sqlite3.connect("loans.db")
c = conn.cursor()
c.executescript("""
DROP TABLE IF EXISTS customers; DROP TABLE IF EXISTS applications; DROP TABLE IF EXISTS repayments;
CREATE TABLE customers(customer_id INTEGER PRIMARY KEY, age INT, city TEXT, income_band TEXT, employment TEXT, bureau_score INT);
CREATE TABLE applications(app_id INTEGER PRIMARY KEY, customer_id INT, app_date TEXT, channel TEXT, loan_type TEXT,
  amount INT, status TEXT, rejection_reason TEXT, disbursed INT);
CREATE TABLE repayments(app_id INT, defaulted INT, dpd_max INT);
""")

cities = ["Delhi","Mumbai","Bengaluru","Kanpur","Pune","Lucknow"]
bands = [("<3L",0.30),("3-6L",0.35),("6-12L",0.25),(">12L",0.10)]
emps = [("Salaried",0.6),("Self-employed",0.3),("Student/Other",0.1)]
pick = lambda opts: random.choices([o for o,_ in opts],[w for _,w in opts])[0]

for cid in range(1, 5001):
    band, emp = pick(bands), pick(emps)
    base = {"<3L":600,"3-6L":650,"6-12L":690,">12L":730}[band]
    score = max(300, min(900, int(random.gauss(base, 60))))
    c.execute("INSERT INTO customers VALUES(?,?,?,?,?,?)",
              (cid, random.randint(21,58), random.choice(cities), band, emp, score))

start = date(2026,1,1)
aid = 0
for cid in range(1, 5001):
    for _ in range(random.choices([1,2],[0.8,0.2])[0]):
        aid += 1
        d = start + timedelta(days=random.randint(0,269))
        ch = random.choices(["Organic","Paid Ads","Referral","Partner"],[0.35,0.35,0.15,0.15])[0]
        lt = random.choices(["Personal","Business"],[0.75,0.25])[0]
        amt = random.choice([50000,100000,200000,300000,500000])
        score, emp = c.execute("SELECT bureau_score, employment FROM customers WHERE customer_id=?", (cid,)).fetchone()
        p_app = 0.85 - (0.25 if score < 600 else 0) - (0.1 if emp=="Student/Other" else 0) + (0.05 if ch=="Referral" else 0)
        approved = random.random() < p_app
        reason = None
        if not approved:
            reason = "Low bureau score" if score < 650 and random.random()<0.7 else random.choice(["Income mismatch","KYC failed","High existing debt"])
        # assumption: Paid Ads leads are less likely to proceed to disbursal after approval
        p_disb = 0.62 if ch=="Paid Ads" else 0.88
        disbursed = 1 if approved and random.random() < p_disb else 0
        status = "Approved" if approved else "Rejected"
        c.execute("INSERT INTO applications VALUES(?,?,?,?,?,?,?,?,?)",
                  (aid,cid,d.isoformat(),ch,lt,amt,status,reason,disbursed))
        if disbursed:
            p_def = 0.04 + (0.10 if score<620 else 0) + (0.05 if emp=="Self-employed" else 0) + (0.05 if lt=="Business" else 0)
            df = random.random() < p_def
            c.execute("INSERT INTO repayments VALUES(?,?,?)",(aid,int(df),random.randint(90,180) if df else random.choice([0,0,0,5,10,20])))
conn.commit()
for t in ["customers","applications","repayments"]:
    print(t, c.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0])
