# Bank Customer Churn — Oracle SQL Layihəsi

Bu repoda **Bank Customer Churn** mövzusunda Oracle SQL layihəsi var. Layihə tam skript, cədvəllər, constraint-lər, əlaqələr, DML əməliyyatları, analitik və window funksiyalarını əhatə edir.

## Fayllar

- `PROJECT MAIN.sql` — əsas SQL skripti (cədvəllər, sequence, constraint-lər, index-lər, merge və analitik query-lər).
- Excel faylı — tablelər və dataset (məlumatların importu üçün istifadə olunur).

## Qısa Məzmun

SQL skripti aşağıdakı hissələrdən ibarətdir:

- **Sequence** yaradılması (`seq_customer_id`)
- **Cədvəllər**:
  - `customer_info` — müştəri demoqrafik məlumatları
  - `customer_churn_info` — maliyyə və churn məlumatları
  - `updated_list` — merge üçün yenilənmiş siyahı
- **Index və Constraint**-lər
- **MERGE** əməliyyatı ilə sinxronizasiya
- **Analitik tapşırıqlar** (RANK, DENSE_RANK, ROW_NUMBER, LAG, LEAD)

## İstifadə Qaydası

1. Oracle SQL mühitində `PROJECT MAIN.sql` faylını run edin.
2. Excel faylındakı dataları uyğun tablelərə import edin.
3. Skriptin sonunda verilən analitik query-ləri icra edin.

## Qeydlər

- `customer_churn_info` cədvəli `customer_info`-ya **foreign key** ilə bağlıdır.
- Merge əməliyyatı `updated_list`-də olub `customer_info`-da olmayan ID-ləri **insert etməyəcək** (FK violation olmasın deyə).

---

**Author:** Mahammad Rasulov
