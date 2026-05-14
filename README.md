# Bank Customer Churn — Oracle SQL Layihəsi

Bu repo **Bank Customer Churn** mövzusunda Oracle SQL layihəsini ehtiva edir. Layihədə tam **SQL skript**, cədvəl dizaynı, constraint-lər, index-lər, **MERGE** sinxronizasiya və **analitik/window** funksiyaları ilə hesabat tapşırıqları mövcuddur. Excel faylı ilkin dataset və import üçün istifadə olunur.

---

## 📁 Repo Struktur

- `PROJECT MAIN.sql` — əsas SQL skripti (DDL, DML, MERGE, analitika).
- `sql Bank Customer Churn Prediction _lst.xlsx` — dataset (import üçün).
- `README.md` — layihə sənədi.

---

## 🎯 Layihənin Məqsədi

Bank müştərilərinin **churn (bankı tərk etmə)** davranışını təhlil etmək:
- Müştəri demoqrafiyası və maliyyə göstəricilərini birləşdirmək
- Churn göstəricilərini cins, ölkə, balans, maaş və aktivlik üzrə analiz etmək
- Analitik/window funksiyalarını praktiki tapşırıqlarda tətbiq etmək

---

## 🗂️ Məlumat Modeli (Entitylər)

### 1) `customer_info`
Müştəri demoqrafik məlumatları
- `customer_id` (PK)
- `name`, `surname`
- `gender` (M/F)
- `age` (18–100)
- `job`, `marital`, `education`
- `country`

### 2) `customer_churn_info`
Churn və maliyyə göstəriciləri
- `customer_id` (PK, FK → `customer_info`)
- `credit_score`, `tenure`
- `balance`, `products_number`
- `credit_card`, `active_member`
- `estimated_salary`
- `churn` (0/1)
- `max_cre_amount` (Task 4 üçün)

### 3) `updated_list`
MERGE üçün yenilənmiş siyahı
- `customer_id` (PK)
- `credit_score`, `tenure`, `balance`
- `products_number`, `credit_card`, `active_member`
- `estimated_salary`, `churn`

---

## 📊 Excel Dataset (XLSX)

Excel faylı Oracle cədvəllərinə import üçün nəzərdə tutulub. Skript və cədvəl dizaynına əsasən datasetdə aşağıdakı məzmunun olması gözlənilir:
- **Müştəri demoqrafiyası** (`customer_info` üçün)
- **Churn/maliyyə məlumatları** (`customer_churn_info` üçün)
- **Yenilənmiş siyahı** (`updated_list` üçün)

> Qeyd: Excel faylını SQL Developer / SQL*Loader vasitəsilə import etmək tövsiyə olunur. Faylın daxilində sheet adları və sütunları import zamanı uyğun cədvələ map edilməlidir.

---

## ⚙️ Qurulum və İcra Addımları

1. Oracle SQL mühitini hazırla (SQL Developer / SQL*Plus).
2. `PROJECT MAIN.sql` faylını **DDL + MERGE + Analitik query-lər** üçün run et.
3. Excel faylını import et:
   - `customer_info`
   - `customer_churn_info`
   - `updated_list`
4. Skriptin sonundakı analitik tapşırıqları icra et.

---

## ✅ Analitik Tapşırıqlar (Skriptin Daxilində)

Skript aşağıdakı analitik hesabatları ehtiva edir:

- **MERGE** — `updated_list` ilə `customer_churn_info` sinxronizasiya
- **Gender üzrə churn payı**
- **Ən az maaş alan churn etməyənlər** (ROW_NUMBER)
- **Ölkə üzrə churn top-ları** (DENSE_RANK)
- **Top 10 yüksək balanslı churn etmiş müştərilər**
- **Maaş və balans sıralamaları** (RANK / DENSE_RANK)
- **Ölkə üzrə yaş sıralaması** (ROW_NUMBER)
- **Balans və maaş fərqləri** (LAG / LEAD)
- **Aktiv müştərilərin tenure sıralaması**
- **Ölkə üzrə top 3 balanslı müştəri**
- **Credit score dəyişimi analizi**
- **Products number fərqləri** (LEAD)

---

## 🔍 Data Keyfiyyəti və Məhdudiyyətlər

- `customer_churn_info.customer_id` **foreign key** ilə `customer_info`-ya bağlıdır.
- `updated_list`-də olub `customer_info`-da olmayan ID-lər **MERGE-də insert edilmir** (FK violation olmasın deyə).
- Demo məqsədi ilə `max_cre_amount` bəzi müştərilərdə manual update edilir.

---

## 📌 Tövsiyə olunan Import Yanaşması

**SQL Developer (GUI):**
- Table → Import Data → Excel file → column mapping

**SQL*Loader (CLI):**
- Excel → CSV → control file ilə import

---

## 👤 Müəllif

**Mahammad Rasulov**

---

### Əlavə Təkliflər

Əlavə inkişaf üçün:
- ER diagram (draw.io) əlavə etmək
- Analitik nəticələri ayrıca `report.sql` faylında bölmək
- Dataset üçün data dictionary yaratmaq
