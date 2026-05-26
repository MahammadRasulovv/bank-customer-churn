# 🏦 Bank Customer Churn — Oracle SQL Layihəsi

Bu repo bank müştərilərinin **churn (bankı tərk etmə) davranışını** analiz edən **Oracle SQL** layihəsini ehtiva edir. Layihədə tam **cədvəl dizaynı**, **constraint-lər**, **index-lər**, **MERGE** sinxronizasiyası və **18+ analitik query** istifadə olunur.

**Texnoloji Stack:** Oracle SQL | DDL/DML | Window Functions (RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD) | MERGE | Subqueries | Composite Indexes | SEQUENCES

---

## 📁 Layihə Struktur

```
bank-customer-churn/
├── PROJECT MAIN.sql                              # Əsas SQL skripti (DDL, DML, MERGE, analitik queries)
├── sql Bank Customer Churn Prediction _lst.xlsx  # Excel dataset (import üçün)
├── README.md                                      # Layihə sənədi (bu fayldır)
└── [Digər resurslar]
```

---

## 🎯 Layihənin Məqsədi

Bu layihə aşağıdakı **SQL texnikalarının praktiki tətbiqini** göstərir:

✅ **Məlumat Modeli Dizaynı** — ERD, Primary Key, Foreign Key, Constraints  
✅ **Performans Optimallaşdırılması** — Composite Index-lər, Execution Plans  
✅ **Data Sinxronizasiyası** — MERGE amaliyyatı (INSERT/UPDATE)  
✅ **Analitik Hesabatlar** — Window Functions, Aggregations, CTE (WITH clause)  
✅ **Data Integriteyi** — CHECK Constraints, Referential Integrity  
✅ **Audit Sistemi** — SEQUENCES for Transaction IDs  

---

## 🗂️ Məlumat Modeli (3 Cədvəl)

### 1️⃣ `CUSTOMER_INFO` — Müştəri Demoqrafiyası

**Məqsəd:** Müştərinin şəxsi və demoqrafik məlumatlarını saxlamaq

| Sütun | Tip | Məhdudiyyət | Açıqlanması |
|-------|-----|-------------|------------|
| `customer_id` | NUMBER(10) | **PRIMARY KEY** | Müştərinin unikal identifikatoru |
| `name` | VARCHAR2(50) | NOT NULL | Ad |
| `surname` | VARCHAR2(50) | NOT NULL | Soyad |
| `gender` | CHAR(1) | CHECK (M/F) | Cins: **M** = Kişi, **F** = Qadın |
| `age` | NUMBER(3) | CHECK (18-100) | Yaş (18-100 aralığında) |
| `job` | VARCHAR2(50) | - | Peşə |
| `marital` | VARCHAR2(20) | CHECK (married/single/divorced) | Ailə vəziyyəti |
| `education` | VARCHAR2(20) | CHECK (primary/secondary/tertiary/unknown) | Təhsil səviyyəsi |
| `country` | VARCHAR2(50) | NOT NULL | Ölkə (France, Germany, Spain) |

**Index-lər:**
- `idx_cust_country_gender` — Composite index (ölkə + cins üzrə axtarış)
- `idx_cust_age` — Yaş üzrə axtarış

**Məlumat Həcmi:** ~10,000 müştəri

---

### 2️⃣ `CUSTOMER_CHURN_INFO` — Churn & Maliyyə Göstəriciləri

**Məqsəd:** Müştərinin churn statusu və maliyyə məlumatlarını saxlamaq

| Sütun | Tip | Məhdudiyyət | Açıqlanması |
|-------|-----|-------------|------------|
| `customer_id` | NUMBER(10) | **PK, FK** | FK → customer_info |
| `credit_score` | NUMBER(5) | CHECK (300-850) | Kredit balı (FICO skalası) |
| `tenure` | NUMBER(3) | CHECK (≥ 0) | Bankda keçən il |
| `balance` | NUMBER(15,2) | CHECK (≥ 0) | Hesab balansi |
| `products_number` | NUMBER(2) | CHECK (1-4) | Banka rəğbət sayı |
| `credit_card` | NUMBER(1) | CHECK (0/1) | Kredit kartı var? (1=var, 0=yox) |
| `active_member` | NUMBER(1) | CHECK (0/1) | Aktiv üzv? (1=aktiv, 0=passiv) |
| `estimated_salary` | NUMBER(15,2) | - | Təxmin edilən maaş |
| `churn` | NUMBER(1) | CHECK (0/1) | **Churn Flagi:** 1=Bankı tərk etdi, 0=Qaldı |
| `max_cre_amount` | NUMBER(15,2) | DEFAULT NULL | Maksimum kredit məbləği (Task 4) |

**Index-lər (5 adet):**
- `idx_churn_flag` — Churn üzrə filter
- `idx_active_member` — Aktiv üzü axtarış
- `idx_salary` — Maaş üzrə sort/filter
- `idx_balance` — Balans üzrə sort/filter
- `idx_churn_balance` — Composite (churn + balans DESC) — **TOP 10 queries üçün optimal**

**Performance:** 0.031–0.064 saniyə ortalama sorgu zamanı

---

### 3️⃣ `UPDATED_LIST` — MERGE üçün Yenilənmiş Siyahı

**Məqsəd:** Xarici mənbədən gələn yeni/yenilənmiş müştəri məlumatlarını saxlamaq

| Sütun | Tip | Məqsəd |
|-------|-----|-------|
| Hamısı `customer_churn_info` ilə eyni | - | MERGE source cədvəli |

**Əhəmiyyət:** 
- FK constraint yoxdur (xarici mənbə üçün)
- MERGE operasiyası ilə `customer_churn_info`-ya sinxronize edilir
- Yeni ID-lər əvvəlcə `customer_info`-ya insert edilməlidir

---

## 🧩 Entity Relationship Diagram (ERD)

```
┌──────────────────────────┐
│    CUSTOMER_INFO         │
│  (Demoqrafiya Cədvəli)   │
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
│  (Churn & Maliyyə Məlumatları Cədvəli) │
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
│ (Yenilənmiş/Bərzənd Siyahı)       │
├────────────────────────────────────┤
│    (customer_churn_info-la eyni)   │
│    FK constraint YOX               │
│    (Xarici mənbə üçün)             │
└────────────────────────────────────┘
```

---

## 📋 Analitik Tapşırıqlar (17 Query)

Skriptdə aşağıdakı analitik sorguların **3–4 versiyası** həyata keçirilir (müxtəlif texnikalarla):

### ✅ Task 1-4: DDL & Data Management
- **Task 1-2:** Cədvəllərin yaradılması, constraint-lərin qurulması
- **Task 3:** MERGE — `updated_list` ilə `customer_churn_info` sinxronizasiyası
- **Task 4:** `max_cre_amount` sütununun əlavə edilməsi və manual UPDATE-lər

### ✅ Task 5: Gender üzrə Churn Analizi
**Sual:** Hansi cinsdən müştərilər daha çox bankı tərk edir?

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

**Texnika:** Window Function (SUM OVER)

---

### ✅ Task 6: Churn Etməyənlər Arasında Ən Az Maaş Alan
**Sual:** Ən az maaş alan müştəridən sonra gələn 3 müştəri (2-4 mövqe)

**Texnika:** ROW_NUMBER() OVER (ORDER BY salary ASC), BETWEEN 2 AND 4

---

### ✅ Task 7: Ölkə üzrə Churn Top 10
**Sual:** Hansı 10 ölkədə ən çox churn olmuşdur?

**Texnika:** DENSE_RANK() OVER (ORDER BY COUNT DESC), Composite Index

**Performans:** 0.031 saniyə (Composite index əlçatanlığında)

---

### ✅ Task 8: Churn Etmiş Müştərilərin Yüksək Balanslı Top 10
**Sual:** Bankı tərk edən müştərilər arasında ən yüksək balansa sahib 10 müştəri

**Texnika:** DENSE_RANK() (bytes optimallaşdırılması)

---

### ✅ Task 9: Maaş üzrə RANK Sıralaması
**Texnika:** RANK() — eyni maaş → eyni rank, sonrakı dəyər atlanır

---

### ✅ Task 10: Balans üzrə DENSE_RANK Sıralaması
**Texnika:** DENSE_RANK() — eyni balans → eyni rank, sonrakı dəyər ATLANMIR

---

### ✅ Task 11: Ölkə üzrə Yaş Sıralaması
**Sual:** Hər ölkə üçün müştərilər yaşa görə sıralanır (ROW_NUMBER)

**Texnika:** ROW_NUMBER() OVER (PARTITION BY country ORDER BY age ASC)

**Performans:** 0.056 saniyə

---

### ✅ Task 12: LAG — Balans Fərqi
**Sual:** Hər müştərinin balansi ilə əvvəlkisinin balansi arasındakı fərq

```sql
SELECT cci.customer_id,
       cci.balance,
       LAG(cci.balance, 1, 0) OVER (ORDER BY cci.balance) AS prev_balance,
       cci.balance - LAG(...) AS balance_diff
FROM customer_churn_info cci;
```

---

### ✅ Task 13: LEAD — Maaş Fərqi
**Sual:** Hər müştərinin maaşı ilə sonrakının maaşı arasındakı fərq

**Texnika:** LEAD(salary, 1, NULL) OVER (ORDER BY salary)

---

### ✅ Task 14 (1): Aktiv Müştərilerin Tenure Sıralaması
**Texnika:** ROW_NUMBER() WHERE active_member = 1

**Performans:** 0.031 saniyə

---

### ✅ Task 14 (2): Ölkə üzrə Churn Etmiş Müştərilərin Balans Sıralaması
**Texnika:** DENSE_RANK() OVER (PARTITION BY country ORDER BY balance DESC)

---

### ✅ Task 15: Credit Score Dəyişimi Analizi
**Sual:** Mütləq customer_id sırasında kredit skorunun dəyişməsi

**Texnika:** LAG(credit_score) OVER (ORDER BY customer_id)

---

### ✅ Task 16: Hər Ölkədə Top 3 Balanslı Müştəri
**Texnika:** ROW_NUMBER() OVER (PARTITION BY country ...) WHERE row_num ≤ 3

---

### ✅ Task 17: Products Number Fərqləri
**Texnika:** LEAD(products_number) — sonrakı məhsul sayı ilə fərq

---

## ⚙️ MERGE Operasiyası (Task 3)

**Məqsəd:** Xarici datasource (`updated_list`) ilə `customer_churn_info` sinxronize etmək

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

**Qayda:**
- Müştəri artıq varsa → **UPDATE** (balance, churn)
- Müştəri yoxdursa → **INSERT** (yeni müştəri əlavə et)
- **FK Violation Qarşısı:** Yeni customer_id əvvəlcə `customer_info`-ya insert edilməlidir

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

Fayldı: **`sql Bank Customer Churn Prediction _lst.xlsx`**

**İçində 3 Sheet olması gözlənilir:**

| Sheet | Sütunlar | Uyğun Cədvəl |
|-------|----------|-------------|
| **sheet1** | customer_id, name, surname, gender, age, job, marital, education, country | `customer_info` |
| **sheet2** | customer_id, credit_score, tenure, balance, products_number, credit_card, active_member, estimated_salary, churn | `customer_churn_info` |
| **sheet3** | (Eyni customer_churn_info sütunları) | `updated_list` (MERGE-də istifadə) |

**Məlumat Həcmi:** ~10,000 sıra hər cədvəl üçün

---

## 🚀 Qurulum və İcra Addımları

### 1️⃣ Mühit Hazırlığı
```
✓ Oracle Database (11g, 12c, 19c, 21c)
✓ SQL Developer / SQL*Plus / Toad
✓ XLSX Import tool (SQL Developer / SQL*Loader)
```

### 2️⃣ Cədvəllərin Yaradılması
```sql
-- Açın: PROJECT MAIN.sql
-- Run et: DDL bölmə (TABLE CREATE, INDEX, COMMENT)
```

### 3️⃣ Data Import
**Seçim A — SQL Developer GUI:**
```
Table → Import Data → Select XLSX file
↓
Column Mapping (XLSX column → DB column)
↓
Insert / Update Rows
```

**Seçim B — SQL*Loader (CLI):**
```bash
# XLSX → CSV çevir
# control_file.ctl yaratır
# sqlload paramfile=control_file.ctl
```

### 4️⃣ MERGE Operasiyasını İcra Et
```sql
-- MERGE Task 3-ü çalıştırın
-- MERGE INTO customer_churn_info ...
-- (Yeni/yenilənmiş məlumatlar sinxron edilir)
```

### 5️⃣ Analitik Queries
```sql
-- Task 5-17 queries-ərini icra et
-- Hər bir Task-ın 2-3 versiyası mövcud (performance müqayisəsi)
SELECT * FROM customer_info;
SELECT * FROM customer_churn_info;
-- ... və s.
```

---

## 🔍 Index Stratejiyası

**Məqsəd:** OLAP queries-lərin performansını artırmaq

### Cədvəl 1: `customer_info`
| Index Adı | Sütunlar | Istifadə Məqsədi |
|-----------|----------|-----------------|
| `pk_customer_info` | customer_id | Primary Key |
| `idx_cust_country_gender` | (country, gender) | WHERE country=X AND gender=Y axtarış |
| `idx_cust_age` | age | ORDER BY age, BETWEEN age queries |

### Cədvəl 2: `customer_churn_info`
| Index Adı | Sütunlar | Istifadə Məqsədi |
|-----------|----------|-----------------|
| `pk_churn_info` | customer_id | Primary Key |
| `idx_churn_flag` | churn | WHERE churn = 1 (~50% sorguları) |
| `idx_active_member` | active_member | WHERE active_member = 1 |
| `idx_salary` | estimated_salary | ORDER BY, TOP N |
| `idx_balance` | balance | ORDER BY balance DESC, TOP 10 |
| `idx_churn_balance` | **(churn, balance DESC)** | **TOP 10 churn-ed customers (composite)** |

**Execution Plan Misal:**
```
Task 8 Query (Top 10 High Balance Churned Customers):
├─ Full Table Scan customer_churn_info (1500 rows)
├─ Filter: churn = 1 (via idx_churn_flag)
├─ Sort: balance DESC (via idx_churn_balance)
└─ DENSE_RANK() — Bytes: ~1000
   ✓ Time: 0.031 sec
```

---

## 📌 Constraint-lər (Data Integriteyi)

### PRIMARY KEY Constraints
- `pk_customer_info` → customer_id unikal
- `pk_churn_info` → customer_id unikal
- `pk_updated_list` → customer_id unikal

### FOREIGN KEY Constraints
- **`fk_churn_customer`** → customer_churn_info.customer_id → customer_info.customer_id
  - **Aktion:** ON DELETE CASCADE (müştəri silinərsə, churn məlumatı da silinir)

### CHECK Constraints

| Constraint | Qayda | Məqsəd |
|-----------|-------|--------|
| `chk_gender` | gender IN ('M', 'F') | Cins yalnız M/F |
| `chk_age` | age BETWEEN 18 AND 100 | Yaş 18-100 |
| `chk_marital` | marital IN ('married', 'single', 'divorced') | Ailə vəziyyəti tənzimlənib |
| `chk_education` | education IN ('primary',...) | Təhsil səviyyəsi tənzimlənib |
| `chk_credit_score` | credit_score BETWEEN 300 AND 850 | FICO balı standart |
| `chk_balance` | balance >= 0 | Mənfi balans yoxdur |
| `chk_products_number` | products_number BETWEEN 1 AND 4 | 1-4 məhsul |
| `chk_credit_card` | credit_card IN (0, 1) | Binary flag |
| `chk_active_member` | active_member IN (0, 1) | Binary flag |
| `chk_churn` | churn IN (0, 1) | Binary flag |
| `chk_max_cre_amount` | max_cre_amount IS NULL OR >= 0 | Mənfi olmayan məbləğ |

---

## 🔐 SEQUENCE-lər (Audit & Transaction IDs)

Skriptdə 3 SEQUENCE yaradılır (audit log, transaction tracking üçün):

```sql
-- 1. Transaction ID Generator (1 billion+ ID qabiliyyəti)
CREATE SEQUENCE seq_transaction_id
START WITH 1000000001
INCREMENT BY 1
CACHE 100
NOCYCLE;

-- 2. Audit Log ID (Dəyişiklik tarixçəsi)
CREATE SEQUENCE seq_audit_id
START WITH 1
INCREMENT BY 1
CACHE 50
NOCYCLE;

-- 3. Loan Application ID (Kredit müraciətləri)
CREATE SEQUENCE seq_loan_id
START WITH 100000
INCREMENT BY 1
CACHE 20
NOCYCLE;
```

**İstifadə:**
```sql
INSERT INTO transaction_log (transaction_id, ...)
VALUES (seq_transaction_id.NEXTVAL, ...);
```

---

## 📊 Query Performance Analizi

**Məqsəd:** Hər Task-ın performance xüsusiyyətlərini müqayisə etmək

### Task 7 — Top 10 Ölkə (3 Versiya Müqayisəsi)

| Versiya | Texnika | Performance | Memory | Bytes |
|---------|---------|-----------|---------|-------|
| **Best ✓** | DENSE_RANK() | 0.031 sec | ~500 KB | ~1000 |
| **Medium** | ROW_NUMBER() | 0.041 sec | ~600 KB | ~1200 |
| **Poor** | ROWNUM / FETCH | 0.045 sec | ~800 KB | ~1400 |

### Task 11 — Ölkə üzrə Yaş Sıralaması

| Versiya | ORDER | Performance |
|---------|-------|-----------|
| Query 1 | BY country, age_row_num | **0.056 sec** ✓ |
| Query 2 | BY country (FROM clause) | 0.064 sec |

**Nəticə:** Window Function ORDER-u ORDER BY-dən daha səmərəlidir

---

## 🛠️ Troubleshooting & Tips

### ❌ Problem: FK Violation (ORA-02291)
**Səbəb:** `updated_list`-də olan customer_id `customer_info`-da yoxdur

**Həll:**
```sql
-- Mətin script-inin əvvəlində çalışır:
INSERT INTO customer_info (customer_id, name, surname, gender, age, country)
SELECT ul.customer_id, 'Unknown', 'Unknown', 'M', 18, 'Unknown'
FROM updated_list ul
WHERE NOT EXISTS (
    SELECT 1 FROM customer_info ci WHERE ci.customer_id = ul.customer_id
);
```

---

### ❌ Problem: MERGE Heç Bir Sıra UPDATE Etmir
**Səbəb:** Sütun adları fərqlənir (`tgt.` prefix yoxdur)

**Düzəliş:**
```sql
-- ✓ DOĞRU:
UPDATE SET tgt.balance = src.balance

-- ✗ YANLIŞ:
UPDATE SET balance = src.balance
```

---

### ❌ Problem: Index İstifadə Olunmur (FULL TABLE SCAN)
**Səbəb:** Query optimizer index seçəkdə əngəl (mislə, implicit conversion)

**Həll:** EXPLAIN PLAN istifadə et
```sql
EXPLAIN PLAN FOR
SELECT * FROM customer_churn_info
WHERE churn = 1
ORDER BY balance DESC
FETCH FIRST 10 ROWS ONLY;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

---

### ❌ Problem: MERGE-dən Sonra Cədvəl Boş
**Səbəb:** UPDATED_LIST boş, və ya ON condition heç vaxt MATCHED olmadı

**Həll:**
```sql
SELECT COUNT(*) FROM updated_list;
SELECT COUNT(*) FROM customer_churn_info WHERE customer_id IN (
    SELECT customer_id FROM updated_list
);
```

---

## 🔧 Performance Tuning Önerisi

1. **Histogram/Stats Yenilə:**
   ```sql
   ANALYZE TABLE customer_churn_info COMPUTE STATISTICS;
   ```

2. **Index Fragmentation Yoxla:**
   ```sql
   SELECT index_name, leaf_blocks FROM user_indexes
   WHERE table_name = 'CUSTOMER_CHURN_INFO';
   ```

3. **Plan Stability (dbms_stats):**
   ```sql
   EXEC DBMS_STATS.GATHER_TABLE_STATS('HR', 'CUSTOMER_CHURN_INFO');
   ```

4. **Caching Layer (Redis/Memcached):** Top 10 queries üçün nəzarə edin

---

## 🏆 SQL Texnikalarının Xülasəsi

Bu layihədə istifadə olunan **17 mühüm texnika:**

| # | Texnika | Nümunə Task | Qiymətləndirmə |
|---|---------|-------------|-------|
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

## 📚 Əlavə Resurslar

- **Oracle SQL Reference:** [docs.oracle.com](https://docs.oracle.com/en/database/oracle/oracle-database/)
- **Window Functions Guide:** [Oracle Analytics Functions](https://docs.oracle.com/cd/B19306_01/server.102/b14200/functions004.htm)
- **MERGE Operasiyası:** [MERGE INTO Documentation](https://docs.oracle.com/en/database/oracle/oracle-database/)
- **Performance Tuning:** `EXPLAIN PLAN FOR` və `DBMS_XPLAN`

---

## 👨‍💼 Müəllif

**Mahammad Rasulov** ([GitHub](https://github.com/MahammadRasulovv))

**Layihə Tarixi:** 2024-2025  
**Versiya:** 1.0 (Final)  
**Dil:** Azerbaycanca (Documentation) | SQL (Kod)

---

## 📝 Sürüm Tarixçəsi

| Versiya | Tarix | Dəyişikliklər |
|---------|-------|--------------|
| **1.0** | 2025-05-26 | Ətraflı README yazıldı, 17 analitik task əlavə edildi |

---

## 🤝 Tövsiyə olunan İstifadə Halları

✅ **Öyrənmə Məqsədləri:**
- Oracle SQL advanced texnikalarını praktiki şəkildə öyrən
- Window Functions-un real dünya tətbiqini gör
- MERGE operasiyasının əsaslarını əldə et

✅ **Portfolio Layihəsi:**
- SQL Development interviews-ə hazırlıq
- Database Design əngəllərini dərinləş
- Performance optimization texnikalarını tətbiq et

✅ **Prototip & PoC:**
- Bank churn modeling-i sadə formada
- Müşəri segmentasiyası analitikası
- Risk assessment modeli

---

**Sonda qeyd:** Bu layihə tamamilə məlumatdır (demo data ilə). Real bank sistemləri üçün ek security, encryption, audit logging, role-based access control (RBAC) tələb olunur.

🎓 **Uğurlar Öyrənməkdə!** 📊
