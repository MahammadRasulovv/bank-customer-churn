# 🏦 Bank Customer Churn — Oracle SQL Project

This repository contains a comprehensive **Oracle SQL project** analyzing **bank customer churn behavior**. The project includes complete **table design**, **constraints**, **indexes**, **window functions**, and **analytical queries**.

**Technology Stack:** Oracle SQL | DDL/DML | Window Functions (RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD) | MERGE | Subqueries | Composite Indexes | SEQUENCES

---

## 📁 Project Structure

```
bank-customer-churn/
├── PROJECT MAIN.sql                              # Main SQL script (DDL, DML, MERGE, analytical queries)
├── sql Bank Customer Churn Prediction _lst.xlsx  # Excel dataset (for import)
├── README.md                                      # Project documentation (this file)
└── [Additional resources]
```

---

## 🎯 Project Objectives

This project demonstrates the practical application of the following **SQL techniques:**

✅ **Data Model Design** — ERD, Primary Key, Foreign Key, Constraints  
✅ **Performance Optimization** — Composite Indexes, Execution Plans  
✅ **Data Synchronization** — MERGE operation (INSERT/UPDATE)  
✅ **Analytical Reports** — Window Functions, Aggregations, CTE (WITH clause)  
✅ **Data Integrity** — CHECK Constraints, Referential Integrity  
✅ **Audit System** — SEQUENCES for Transaction IDs

---

## 🗂️ Data Model (3 Tables)

### 1️⃣ `CUSTOMER_INFO` — Customer Demographics

**Purpose:** Store customer personal and demographic information

| Column | Type | Constraint | Description |
|--------|------|-----------|------------|
| `customer_id` | NUMBER(10) | **PRIMARY KEY** | Unique customer identifier |
| `name` | VARCHAR2(50) | NOT NULL | First name |
| `surname` | VARCHAR2(50) | NOT NULL | Last name |
| `gender` | CHAR(1) | CHECK (M/F) | Gender: **M** = Male, **F** = Female |
| `age` | NUMBER(3) | CHECK (18-100) | Age (range 18-100) |
| `job` | VARCHAR2(50) | — | Occupation |
| `marital` | VARCHAR2(20) | CHECK (married/single/divorced) | Marital status |
| `education` | VARCHAR2(20) | CHECK (primary/secondary/tertiary/unknown) | Education level |
| `country` | VARCHAR2(50) | NOT NULL | Country (France, Germany, Spain) |

**Indexes:**
- `idx_cust_country_gender` — Composite index (country + gender search)
- `idx_cust_age` — Age-based search

**Data Volume:** ~10,000 customers

---

### 2️⃣ `CUSTOMER_CHURN_INFO` — Churn & Financial Indicators

**Purpose:** Store customer churn status and financial information

| Column | Type | Constraint | Description |
|--------|------|-----------|------------|
| `customer_id` | NUMBER(10) | **PK, FK** | FK → customer_info |
| `credit_score` | NUMBER(5) | CHECK (300-850) | Credit score (FICO scale) |
| `tenure` | NUMBER(3) | CHECK (≥ 0) | Years as customer |
| `balance` | NUMBER(15,2) | CHECK (≥ 0) | Account balance |
| `products_number` | NUMBER(2) | CHECK (1-4) | Number of products with bank |
| `credit_card` | NUMBER(1) | CHECK (0/1) | Has credit card? (1=yes, 0=no) |
| `active_member` | NUMBER(1) | CHECK (0/1) | Active member? (1=active, 0=inactive) |
| `estimated_salary` | NUMBER(15,2) | — | Estimated salary |
| `churn` | NUMBER(1) | CHECK (0/1) | **Churn Flag:** 1=Left bank, 0=Remained |
| `max_cre_amount` | NUMBER(15,2) | DEFAULT NULL | Maximum credit amount (Task 4) |

**Indexes (5 total):**
- `idx_churn_flag` — Churn-based filtering
- `idx_active_member` — Active member search
- `idx_salary` — Salary sorting/filtering
- `idx_balance` — Balance sorting/filtering
- `idx_churn_balance` — Composite (churn + balance DESC) — **Optimal for TOP 10 queries**

**Performance:** 0.031–0.064 seconds average query time

---

### 3️⃣ `UPDATED_LIST` — Updated List for MERGE

**Purpose:** Store new/updated customer information from external sources

| Column | Type | Purpose |
|--------|------|---------|
| All | Same as `customer_churn_info` | — | MERGE source table |

**Importance:**
- No FK constraint (for external sources)
- Synchronized with `customer_churn_info` via MERGE operation
- New IDs must first be inserted into `customer_info`

---

## 🧩 Entity Relationship Diagram (ERD)

```
┌──────────────────────────┐
│    CUSTOMER_INFO         │
│  (Demographics Table)    │
├──────────────────────────┤
│ PK | customer_id         │
│    | name, surname       │
│    | gender (M/F)        │
│    | age (18-100)        │
│    | job, marital        │
│    | education, country  │
└──────────────┬───────────┘
               │ (1:1)
               │ ON DELETE CASCADE
               │ FK: customer_id
┌──────────────▼─────────────────────────┐
│  CUSTOMER_CHURN_INFO                   │
│  (Churn & Financial Data Table)        │
├────────────────────────────────────────┤
│ PK | customer_id                       │
│    | credit_score (300-850)            │
│    | tenure, balance, products_number  │
│    | credit_card (0/1)                 │
│    | active_member (0/1)               │
│    | estimated_salary                  │
│    | churn (0/1) ← CORE ANALYSIS      │
│    | max_cre_amount (Task 4)           │
└────────────────────────────────────────┘
               △
               │ (MERGE Source)
               │
┌──────────────┴────────────────────┐
│      UPDATED_LIST                  │
│ (Updated/Fresh Data List)          │
├────────────────────────────────────┤
│    (Same as customer_churn_info)   │
│    No FK constraint                │
│    (For external sources)          │
└────────────────────────────────────┘
```

---

## 📋 Analytical Tasks (17 Queries)

The script implements **3–4 versions** of each analytical task (with different techniques):

### ✅ Task 1-4: DDL & Data Management
- **Task 1-2:** Table creation, constraint configuration
- **Task 3:** MERGE — Synchronization of `updated_list` with `customer_churn_info`
- **Task 4:** Adding `max_cre_amount` column and manual UPDATEs

### ✅ Task 5: Gender-Based Churn Analysis
**Question:** Which gender churns more from the bank?

```sql
SELECT ci.gender,
       COUNT(*) AS churn_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS churn_pct
FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
WHERE cci.churn = 1
GROUP BY ci.gender
ORDER BY churn_count DESC;
```

**Technique:** Window Function (SUM OVER)

---

### ✅ Task 6: Lowest Salary Among Non-Churned Customers
**Question:** The 3 customers following the lowest-paid (positions 2-4)

**Technique:** ROW_NUMBER() OVER (ORDER BY salary ASC), BETWEEN 2 AND 4

---

### ✅ Task 7: Top 10 Countries by Churn
**Question:** Which 10 countries have the highest churn?

**Technique:** DENSE_RANK() OVER (ORDER BY COUNT DESC), Composite Index

**Performance:** 0.031 seconds (with composite index)

---

### ✅ Task 8: Top 10 Churned Customers with High Balance
**Question:** The 10 customers who left the bank with the highest balances

**Technique:** DENSE_RANK() (bytes optimization)

---

### ✅ Task 9: Salary-Based RANK Ordering
**Technique:** RANK() — Same salary → Same rank, next value skipped

---

### ✅ Task 10: Balance-Based DENSE_RANK Ordering
**Technique:** DENSE_RANK() — Same balance → Same rank, next value NOT skipped

---

### ✅ Task 11: Age Ranking by Country
**Question:** Customers ranked by age within each country (ROW_NUMBER)

**Technique:** ROW_NUMBER() OVER (PARTITION BY country ORDER BY age ASC)

**Performance:** 0.056 seconds

---

### ✅ Task 12: LAG — Balance Difference
**Question:** Difference between each customer's balance and the previous one

```sql
SELECT cci.customer_id,
       cci.balance,
       LAG(cci.balance, 1, 0) OVER (ORDER BY cci.balance) AS prev_balance,
       cci.balance - LAG(...) AS balance_diff
FROM customer_churn_info cci;
```

---

### ✅ Task 13: LEAD — Salary Difference
**Question:** Difference between each customer's salary and the next one

**Technique:** LEAD(salary, 1, NULL) OVER (ORDER BY salary)

---

### ✅ Task 14 (1): Tenure Ranking of Active Customers
**Technique:** ROW_NUMBER() WHERE active_member = 1

**Performance:** 0.031 seconds

---

### ✅ Task 14 (2): Balance Ranking of Churned Customers by Country
**Technique:** DENSE_RANK() OVER (PARTITION BY country ORDER BY balance DESC)

---

### ✅ Task 15: Credit Score Change Analysis
**Question:** Credit score changes ordered by customer_id

**Technique:** LAG(credit_score) OVER (ORDER BY customer_id)

---

### ✅ Task 16: Top 3 Customers by Balance Per Country
**Technique:** ROW_NUMBER() OVER (PARTITION BY country ...) WHERE row_num ≤ 3

---

### ✅ Task 17: Products Number Differences
**Technique:** LEAD(products_number) — Difference with next product count

---

## ⚙️ MERGE Operation (Task 3)

**Purpose:** Synchronize `customer_churn_info` with external datasource (`updated_list`)

```sql
MERGE INTO customer_churn_info tgt
USING updated_list src
ON (tgt.customer_id = src.customer_id)

WHEN MATCHED THEN
    UPDATE SET
        tgt.balance = src.balance,
        tgt.churn   = src.churn

WHEN NOT MATCHED THEN
    INSERT (customer_id, credit_score, tenure, balance, ...)
    VALUES (src.customer_id, src.credit_score, ...);
```

**Rules:**
- If customer exists → **UPDATE** (balance, churn)
- If customer doesn't exist → **INSERT** (add new customer)
- **Prevent FK Violation:** New customer_id must first be inserted into `customer_info`

```sql
INSERT INTO customer_info (customer_id, name, surname, gender, age, country)
SELECT ul.customer_id, 'Unknown', 'Unknown', 'M', 18, 'Unknown'
FROM updated_list ul
WHERE NOT EXISTS (
    SELECT 1 FROM customer_info ci WHERE ci.customer_id = ul.customer_id
);
```

---

## 📊 Excel Dataset (XLSX)

**File:** **`sql Bank Customer Churn Prediction _lst.xlsx`**

**Expected 3 Sheets:**

| Sheet | Columns | Corresponding Table |
|-------|---------|-------------------|
| **sheet1** | customer_id, name, surname, gender, age, job, marital, education, country | `customer_info` |
| **sheet2** | customer_id, credit_score, tenure, balance, products_number, credit_card, active_member, estimated_salary, churn | `customer_churn_info` |
| **sheet3** | (Same as customer_churn_info columns) | `updated_list` (used in MERGE) |

**Data Volume:** ~10,000 rows per table

---

## 🚀 Setup and Execution Steps

### 1️⃣ Environment Preparation
```
✓ Oracle Database (11g, 12c, 19c, 21c)
✓ SQL Developer / SQL*Plus / Toad
✓ XLSX Import tool (SQL Developer / SQL*Loader)
```

### 2️⃣ Create Tables
```sql
-- Open: PROJECT MAIN.sql
-- Run: DDL section (TABLE CREATE, INDEX, COMMENT)
```

### 3️⃣ Data Import
**Option A — SQL Developer GUI:**
```
Table → Import Data → Select XLSX file
↓
Column Mapping (XLSX column → DB column)
↓
Insert / Update Rows
```

**Option B — SQL*Loader (CLI):**
```bash
# Convert XLSX → CSV
# Create control_file.ctl
# sqlload paramfile=control_file.ctl
```

### 4️⃣ Execute MERGE Operation
```sql
-- Run MERGE Task 3
-- MERGE INTO customer_churn_info ...
-- (New/updated data is synchronized)
```

### 5️⃣ Run Analytical Queries
```sql
-- Execute Task 5-17 queries
-- Multiple versions available per task (for performance comparison)
SELECT * FROM customer_info;
SELECT * FROM customer_churn_info;
-- ... and more
```

---

## 🔍 Index Strategy

**Purpose:** Improve OLAP query performance

### Table 1: `customer_info`
| Index Name | Columns | Use Case |
|-----------|---------|----------|
| `pk_customer_info` | customer_id | Primary Key |
| `idx_cust_country_gender` | (country, gender) | WHERE country=X AND gender=Y search |
| `idx_cust_age` | age | ORDER BY age, BETWEEN age queries |

### Table 2: `customer_churn_info`
| Index Name | Columns | Use Case |
|-----------|---------|----------|
| `pk_churn_info` | customer_id | Primary Key |
| `idx_churn_flag` | churn | WHERE churn = 1 (~50% of queries) |
| `idx_active_member` | active_member | WHERE active_member = 1 |
| `idx_salary` | estimated_salary | ORDER BY, TOP N |
| `idx_balance` | balance | ORDER BY balance DESC, TOP 10 |
| `idx_churn_balance` | **(churn, balance DESC)** | **TOP 10 churned customers (composite)** |

**Execution Plan Example:**
```
Task 8 Query (Top 10 High Balance Churned Customers):
├─ Full Table Scan customer_churn_info (1500 rows)
├─ Filter: churn = 1 (via idx_churn_flag)
├─ Sort: balance DESC (via idx_churn_balance)
└─ DENSE_RANK() — Bytes: ~1000
   ✓ Time: 0.031 sec
```

---

## 📌 Constraints (Data Integrity)

### PRIMARY KEY Constraints
- `pk_customer_info` → customer_id unique
- `pk_churn_info` → customer_id unique
- `pk_updated_list` → customer_id unique

### FOREIGN KEY Constraints
- **`fk_churn_customer`** → customer_churn_info.customer_id → customer_info.customer_id
  - **Action:** ON DELETE CASCADE (if customer deleted, churn data deleted too)

### CHECK Constraints

| Constraint | Rule | Purpose |
|-----------|------|---------|
| `chk_gender` | gender IN ('M', 'F') | Gender limited to M/F |
| `chk_age` | age BETWEEN 18 AND 100 | Age 18-100 only |
| `chk_marital` | marital IN ('married', 'single', 'divorced') | Marital status defined |
| `chk_education` | education IN ('primary',...) | Education level defined |
| `chk_credit_score` | credit_score BETWEEN 300 AND 850 | FICO score standard |
| `chk_balance` | balance >= 0 | No negative balance |
| `chk_products_number` | products_number BETWEEN 1 AND 4 | 1-4 products |
| `chk_credit_card` | credit_card IN (0, 1) | Binary flag |
| `chk_active_member` | active_member IN (0, 1) | Binary flag |
| `chk_churn` | churn IN (0, 1) | Binary flag |
| `chk_max_cre_amount` | max_cre_amount IS NULL OR >= 0 | Non-negative amount |

---

## 🔐 SEQUENCES (Audit & Transaction IDs)

The script creates 3 SEQUENCEs for audit log and transaction tracking:

```sql
-- 1. Transaction ID Generator (capable of 1 billion+ IDs)
CREATE SEQUENCE seq_transaction_id
START WITH 1000000001
INCREMENT BY 1
CACHE 100
NOCYCLE;

-- 2. Audit Log ID (Change history)
CREATE SEQUENCE seq_audit_id
START WITH 1
INCREMENT BY 1
CACHE 50
NOCYCLE;

-- 3. Loan Application ID (Credit applications)
CREATE SEQUENCE seq_loan_id
START WITH 100000
INCREMENT BY 1
CACHE 20
NOCYCLE;
```

**Usage:**
```sql
INSERT INTO transaction_log (transaction_id, ...)
VALUES (seq_transaction_id.NEXTVAL, ...);
```

---

## 📊 Query Performance Analysis

**Purpose:** Compare performance characteristics of each task

### Task 7 — Top 10 Countries (3 Version Comparison)

| Version | Technique | Performance | Memory | Bytes |
|---------|-----------|-----------|---------|-------|
| **Best ✓** | DENSE_RANK() | 0.031 sec | ~500 KB | ~1000 |
| **Medium** | ROW_NUMBER() | 0.041 sec | ~600 KB | ~1200 |
| **Poor** | ROWNUM / FETCH | 0.045 sec | ~800 KB | ~1400 |

### Task 11 — Age Ranking by Country

| Version | ORDER | Performance |
|---------|-------|-----------|
| Query 1 | BY country, age_row_num | **0.056 sec** ✓ |
| Query 2 | BY country (FROM clause) | 0.064 sec |

**Conclusion:** Window Function ORDER is more efficient than ORDER BY

---

## 🛠️ Troubleshooting & Tips

### ❌ Problem: FK Violation (ORA-02291)
**Cause:** customer_id in `updated_list` does not exist in `customer_info`

**Solution:**
```sql
-- Runs at beginning of script:
INSERT INTO customer_info (customer_id, name, surname, gender, age, country)
SELECT ul.customer_id, 'Unknown', 'Unknown', 'M', 18, 'Unknown'
FROM updated_list ul
WHERE NOT EXISTS (
    SELECT 1 FROM customer_info ci WHERE ci.customer_id = ul.customer_id
);
```

---

### ❌ Problem: MERGE Does Not Update Any Rows
**Cause:** Column names differ (missing `tgt.` prefix)

**Fix:**
```sql
-- ✓ CORRECT:
UPDATE SET tgt.balance = src.balance

-- ✗ WRONG:
UPDATE SET balance = src.balance
```

---

### ❌ Problem: Index Not Used (FULL TABLE SCAN)
**Cause:** Query optimizer skips index (e.g., implicit conversion)

**Solution:** Use EXPLAIN PLAN
```sql
EXPLAIN PLAN FOR
SELECT * FROM customer_churn_info
WHERE churn = 1
ORDER BY balance DESC
FETCH FIRST 10 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

---

### ❌ Problem: Table Empty After MERGE
**Cause:** UPDATED_LIST empty, or ON condition never MATCHED

**Solution:**
```sql
SELECT COUNT(*) FROM updated_list;
SELECT COUNT(*) FROM customer_churn_info WHERE customer_id IN (
    SELECT customer_id FROM updated_list
);
```

---

## 🔧 Performance Tuning Recommendations

1. **Refresh Histogram/Stats:**
   ```sql
   ANALYZE TABLE customer_churn_info COMPUTE STATISTICS;
   ```

2. **Check Index Fragmentation:**
   ```sql
   SELECT index_name, leaf_blocks FROM user_indexes
   WHERE table_name = 'CUSTOMER_CHURN_INFO';
   ```

3. **Plan Stability (dbms_stats):**
   ```sql
   EXEC DBMS_STATS.GATHER_TABLE_STATS('HR', 'CUSTOMER_CHURN_INFO');
   ```

4. **Caching Layer (Redis/Memcached):** Consider for Top 10 queries

---

## 🏆 SQL Techniques Summary

**17 key techniques** used in this project:

| # | Technique | Example Task | Rating |
|---|-----------|-------------|--------|
| 1 | CREATE TABLE + Constraints | Task 1-2 | ⭐⭐⭐⭐⭐ |
| 2 | Primary/Foreign Key | Task 1-3 | ⭐⭐⭐⭐⭐ |
| 3 | CHECK Constraints | Task 1-2 | ⭐⭐⭐⭐ |
| 4 | Composite Indexes | Task 7-8 | ⭐⭐⭐⭐⭐ |
| 5 | MERGE (INSERT/UPDATE) | Task 3 | ⭐⭐⭐⭐⭐ |
| 6 | Aggregate Functions | Task 5 | ⭐⭐⭐⭐ |
| 7 | Window: RANK() | Task 9 | ⭐⭐⭐⭐⭐ |
| 8 | Window: DENSE_RANK() | Task 10 | ⭐⭐⭐⭐⭐ |
| 9 | Window: ROW_NUMBER() | Task 6,11 | ⭐⭐⭐⭐⭐ |
| 10 | Window: LAG() | Task 12,15 | ⭐⭐⭐⭐ |
| 11 | Window: LEAD() | Task 13,17 | ⭐⭐⭐⭐ |
| 12 | PARTITION BY | Task 11,14 | ⭐⭐⭐⭐⭐ |
| 13 | CTE (WITH clause) | Task 5-7 | ⭐⭐⭐⭐ |
| 14 | Subqueries | Task 6-8 | ⭐⭐⭐⭐ |
| 15 | JOIN (INNER) | Task 5,7 | ⭐⭐⭐⭐⭐ |
| 16 | SEQUENCE (NEXTVAL) | Audit | ⭐⭐⭐⭐ |
| 17 | EXPLAIN PLAN | Performance | ⭐⭐⭐⭐ |

---

## 📚 Additional Resources

- **Oracle SQL Reference:** [docs.oracle.com](https://docs.oracle.com/en/database/oracle/oracle-database/)
- **Window Functions Guide:** [Oracle Analytics Functions](https://docs.oracle.com/cd/B19306_01/server.102/b14200/functions004.htm)
- **MERGE Operation:** [MERGE INTO Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/)
- **Performance Tuning:** `EXPLAIN PLAN FOR` and `DBMS_XPLAN`

---

## 👨‍💼 Author

**Mahammad Rasulov** ([GitHub](https://github.com/MahammadRasulovv))

**Project Timeline:** 2024-2025  
**Version:** 1.0 (Final)  
**Languages:** English (Documentation) | SQL (Code)

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| **1.0** | 2025-05-30 | Complete README rewritten in English with 17 analytical tasks |

---

## 🤝 Recommended Use Cases

✅ **Learning Purposes:**
- Learn advanced Oracle SQL techniques practically
- See real-world application of Window Functions
- Master MERGE operation fundamentals

✅ **Portfolio Project:**
- Prepare for SQL Development interviews
- Deepen Database Design skills
- Apply performance optimization techniques

✅ **Prototype & PoC:**
- Bank churn modeling in simplified form
- Customer segmentation analytics
- Risk assessment model

---

**Final Note:** This project contains purely instructional data (demo data). Real banking systems require additional security, encryption, audit logging, and role-based access control (RBAC).

🎓 **Good luck with your learning!** 📊
