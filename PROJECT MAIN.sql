
-- BANK CUSTOMER CHURN - ORACLE SQL LAYIHE ISI
-- Author: MAHAMMAD RASULOV
-- Description: Full project script with tables, constraints,
-- relations, DML, analytics and window functions

-- STEP 1: SEQUENCE YARATMAQ (PK ucun)

-- Customer_info ucun sequence (eger manual deyil system-generated lazimsa)
-- Bu dataset-de IDs artiq mevcut olduguna gore sequence-i reference olaraq yaradiriq

CREATE SEQUENCE seq_customer_id
START WITH 2366005
INCREMENT BY 1
NOCACHE
NOCYCLE;


-- STEP 2: TABLE 1 - CUSTOMER_INFO
-- Musteri demografik melumatlarini saxlayan esas table


CREATE TABLE customer_info (
    customer_id NUMBER(10) NOT NULL,
    name VARCHAR2(50) NOT NULL,
    surname VARCHAR2(50) NOT NULL,
    gender CHAR(1) NOT NULL,
    age NUMBER(3) NOT NULL,
    job VARCHAR2(50),
    marital VARCHAR2(20),
    education VARCHAR2(20),
    country VARCHAR2(50) NOT NULL,

    -- PRIMARY KEY constraint
    CONSTRAINT pk_customer_info PRIMARY KEY (customer_id),

    -- Gender yalniz 'M' ve ya 'F' ola biler
    CONSTRAINT chk_gender CHECK (gender IN ('M', 'F')),

    -- Yas 18-100 araliginda olmalidir
    CONSTRAINT chk_age CHECK (age BETWEEN 18 AND 100),

    -- Marital statusun kecerli deyerleri
    CONSTRAINT chk_marital CHECK (marital IN ('married', 'single', 'divorced')),

    -- Tehsil seveviyyesinin kecerli deyerleri
    CONSTRAINT chk_education CHECK (education IN ('primary', 'secondary', 'tertiary', 'unknown'))

);

-- Index: country ve gender uzre tez-tez sorgu atilacagindan composite index

CREATE INDEX idx_cust_country_gender ON customer_info (country, gender);

-- Index: age-e gore axtaris ucun

CREATE INDEX idx_cust_age ON customer_info (age);

-- Column-level comments
COMMENT ON TABLE customer_info IS 'Musteri demografik melumatlarini saxlayan esas cedvel';

COMMENT ON COLUMN customer_info.customer_id IS 'Musteteri ucun unikal identifikator';

COMMENT ON COLUMN customer_info.gender IS 'Mustericinin cinsi: M=Kisi, F=Qadin';

COMMENT ON COLUMN customer_info.country IS 'Mustericinin yasadigi olke (France, Germany, Spain)';


-- STEP 3: TABLE 2 - CUSTOMER_CHURN_INFO
-- Churns/mali melumatlar + kredit melumatlari

CREATE TABLE customer_churn_info (
    customer_id NUMBER(10) NOT NULL,
    credit_score NUMBER(5) NOT NULL,
    tenure NUMBER(3) NOT NULL,
    balance NUMBER(15, 2) DEFAULT 0,
    products_number NUMBER(2) NOT NULL,
    credit_card NUMBER(1) DEFAULT 0,
    active_member NUMBER(1) DEFAULT 0,
    estimated_salary NUMBER(15, 2),
    churn NUMBER(1) DEFAULT 0,
    max_cre_amount NUMBER(15, 2) DEFAULT NULL,  -- Task 4 ucun: maksimum kredit mebleg

    -- PRIMARY KEY
    CONSTRAINT pk_churn_info PRIMARY KEY (customer_id),

    -- FOREIGN KEY - customer_info-ya baglanir (3 table-i elaqelendiren zencir)
    CONSTRAINT fk_churn_customer FOREIGN KEY (customer_id) REFERENCES customer_info (customer_id) ON DELETE CASCADE,

    -- Credit score 300-850 araliginda olmalidir (FICO score range)
    CONSTRAINT chk_credit_score CHECK (credit_score BETWEEN 300 AND 850),

    -- Tenure (bankda kecirilen il) 0 ve ya pozitiv olmalidir
    CONSTRAINT chk_tenure CHECK (tenure >= 0),

    -- Balance menfiye duse bilmez
    CONSTRAINT chk_balance CHECK (balance >= 0),

    -- Products sayi 1-4 araliginda olmalidir
    CONSTRAINT chk_products_number CHECK (products_number BETWEEN 1 AND 4),

    -- Credit card: 0 (yox) ya 1 (var)
    CONSTRAINT chk_credit_card CHECK (credit_card IN (0, 1)),

    -- Active member: 0 (passiv) ya 1 (aktiv)
    CONSTRAINT chk_active_member CHECK (active_member IN (0, 1)),

    -- Churn: 0 (qalmis) ya 1 (terketmis)
    CONSTRAINT chk_churn CHECK (churn IN (0, 1)),

    -- Max kredit mebleg menfiye gedemeye bilmez
    CONSTRAINT chk_max_cre_amount CHECK (max_cre_amount IS NULL OR max_cre_amount >= 0)
);

-- Index: churn uzre - en cox filter edilecek sutun
CREATE INDEX idx_churn_flag ON customer_churn_info (churn);

-- Index: active_member uzre
CREATE INDEX idx_active_member ON customer_churn_info (active_member);

-- Index: estimated_salary uzre - Task 6, 9, 13 ucun
CREATE INDEX idx_salary ON customer_churn_info (estimated_salary);

-- Index: balance uzre - Task 8, 10, 12 ucun
CREATE INDEX idx_balance ON customer_churn_info (balance);

-- Composite index: churn + balance (Task 8 ucun optimal)
CREATE INDEX idx_churn_balance ON customer_churn_info (churn, balance DESC);

COMMENT ON TABLE customer_churn_info IS 'Mustericinin bank ile maliyye elaqeleri ve churn statusunu saxlayan cedvel';

COMMENT ON COLUMN customer_churn_info.churn IS '1 = Musteri banki terketmisdir, 0 = Musteri hala qalir';

COMMENT ON COLUMN customer_churn_info.max_cre_amount IS 'Mustecriye verilmesi planlasdirilan maksimum kredit meblegi';


-- STEP 4: TABLE 3 - UPDATED_LIST
-- Yenilenmis musteri siyahisi (MERGE ucun menbe table)


CREATE TABLE updated_list (
    customer_id NUMBER(10) NOT NULL,
    credit_score NUMBER(5) NOT NULL,
    tenure NUMBER(3) NOT NULL,
    balance NUMBER(15, 2) DEFAULT 0,
    products_number NUMBER(2) NOT NULL,
    credit_card NUMBER(1) DEFAULT 0,
    active_member NUMBER(1) DEFAULT 0,
    estimated_salary NUMBER(15, 2),
    churn NUMBER(1) DEFAULT 0,

    -- PRIMARY KEY
    CONSTRAINT pk_updated_list PRIMARY KEY (customer_id),

    -- Credit score check
    CONSTRAINT chk_ul_credit_score CHECK (credit_score BETWEEN 300 AND 850),

    CONSTRAINT chk_ul_tenure CHECK (tenure >= 0),

    CONSTRAINT chk_ul_balance CHECK (balance >= 0),

    CONSTRAINT chk_ul_products_number CHECK (products_number BETWEEN 1 AND 4),

    CONSTRAINT chk_ul_credit_card CHECK (credit_card IN (0, 1)),

    CONSTRAINT chk_ul_active_member CHECK (active_member IN (0, 1)),

    CONSTRAINT chk_ul_churn CHECK (churn IN (0, 1))
);


COMMENT ON TABLE updated_list IS 'Yenilenmis musteri siyahisi - MERGE meliiyyatinin menbe cedveli';


-- STEP 5: DATA INSERT - CUSTOMER_INFO
-- (Fayl serhed ID-si: Unnamed:0 sutunu = customer_id)

SELECT * FROM customer_info FOR UPDATE

-- STEP 6: DATA INSERT - CUSTOMER_CHURN_INFO

SELECT * FROM customer_churn_info FOR UPDATE

-- STEP 7: DATA INSERT - UPDATED_LIST

SELECT * FROM updated_list FOR UPDATE


-- TASK 3: MERGE - updated_list ile customer_churn_info sinxronizasiyasi
-- Qaydalar:
-- MATCH varsa -> balance ve churn-u updated_list-den yenile
-- MATCH yoxdursa-> yeni setr insert et
-- NOT: updated_list-deki yeni customer_id-ler customer_info-da ola bilmez
-- FK violation olmasin diye sadece movcud ID-leri MERGE edirik
-- Yeni ID-leri customer_info-ya da elave etmek lazimdir (asagida numune var)

-- Numune: updated_list-de olan amma customer_info-da olmayan ID-leri tapmaq

SELECT ul.customer_id
FROM updated_list ul
WHERE NOT EXISTS (
                  SELECT 1
                  FROM customer_info  ci
                  WHERE ci.customer_id = ul.customer_id);

-- MERGE amaliyyati
MERGE INTO customer_churn_info tgt
USING (
    -- updated_list ile customer_info join edirik
    -- Yalniz customer_info-da movcud olan ID-ler ucun merge edeceyik
    SELECT 
           ul.customer_id,
           ul.balance,
           ul.churn,
           ul.credit_score,
           ul.tenure,
           ul.products_number,
           ul.credit_card,
           ul.active_member,
           ul.estimated_salary
    FROM updated_list   ul
    JOIN customer_info  ci ON ci.customer_id = ul.customer_id) src

ON (tgt.customer_id = src.customer_id)

-- MATCH olan setrler: balance ve churn-u yenile
WHEN MATCHED THEN
    UPDATE SET
             tgt.balance = src.balance,
             tgt.churn = src.churn,
             tgt.credit_score = src.credit_score,
             tgt.tenure = src.tenure,
             tgt.products_number = src.products_number,
             tgt.credit_card = src.credit_card,
             tgt.active_member = src.active_member,
             tgt.estimated_salary = src.estimated_salary

-- MATCH olmayan setrler: yeni setr elave et

WHEN NOT MATCHED THEN
    INSERT (
        customer_id, credit_score, tenure, balance,
        products_number, credit_card, active_member,
        estimated_salary, churn)
    VALUES (
        src.customer_id, src.credit_score, src.tenure, src.balance,
        src.products_number, src.credit_card, src.active_member,
        src.estimated_salary, src.churn);



-- TASK 4: MAX_CRE_AMOUNT sutunu - artiq CREATE TABLE-da elave etdik
-- İndi bezi (random) musteriler ucun UPDATE ile deyerler menimsedirik

-- Bezi musterilere manual UPDATE ile max kredit mebleg teyini

SELECT * FROM customer_churn_info

UPDATE customer_churn_info
SET max_cre_amount = 1000
WHERE customer_id = 2365987;

UPDATE customer_churn_info
SET max_cre_amount = 2000
WHERE customer_id = 2365988;

UPDATE customer_churn_info
SET max_cre_amount = 5000
WHERE customer_id = 2365991;

UPDATE customer_churn_info
SET max_cre_amount = 10000
WHERE customer_id = 2365994;


-- TASK 5: EN COX CHURN EDEN MUSTERILERIN HANSI CINSTEN OLDUGUNU TEYIN ETMEK
-- Qeyd: gender customer_info-da, churn customer_churn_info-da

SELECT   
       ci.gender,
       COUNT(*) AS churn_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS churn_pct

FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
WHERE cci.churn = 1
GROUP BY ci.gender
ORDER BY churn_count DESC;


-- TASK 6: CHURN ETMEYEN MUSTERILER ARASINDA EN AZ MAAŞ ALANLAR
-- Ilk en az maaş alan musteri XARIC, novbeti 3-u tapmaq
-- FETCH / OFFSET OLMADAN yazilmalidir -> ROW_NUMBER ile


SELECT customer_id,
       estimated_salary,
       salary_rank
FROM (
    SELECT   
           cci.customer_id,
           cci.estimated_salary,
           ROW_NUMBER() OVER (ORDER BY cci.estimated_salary ASC) AS salary_rank
    FROM customer_churn_info cci
    WHERE cci.churn = 0
)
WHERE salary_rank BETWEEN 2 AND 4
ORDER BY salary_rank;


-- TASK 7: CHURN EDEN MUSTERILERIN SAYININ EN COX OLDUGU TOP 10 OLKE
-- Qeyd : OLKE SAYI AZ OLDUGUNDAN (3 OLKE) HAMISINI GOSTERIR

SELECT 
       country,
       churn_count,
       country_rank
FROM (
    SELECT ci.country,
           COUNT(*) AS churn_count,
           DENSE_RANK() OVER ( ORDER BY COUNT(*) DESC ) AS country_rank
    FROM customer_churn_info   cci
    JOIN customer_info ci ON ci.customer_id = cci.customer_id
    WHERE cci.churn = 1
    GROUP BY ci.country
)

WHERE country_rank <= 10
ORDER BY country_rank, country;


-- TASK 8: CHURN EDEN MUSTERILERIN KARTI BALANSI EN COX OLAN TOP 10
-- QEYD: INDEX

SELECT 
       customer_id,
       full_name,
       balance,
       balance_rank
FROM (
       SELECT   
              cci.customer_id,
              ci.name || ' ' || ci.surname AS full_name,
              cci.balance,
              DENSE_RANK() OVER (ORDER BY cci.balance DESC) AS balance_rank
       FROM customer_churn_info cci
       JOIN customer_info ci ON ci.customer_id = cci.customer_id
       WHERE cci.churn = 1
)

WHERE balance_rank <= 10
ORDER BY balance_rank;


-- TASK 9: MAAŞA GORE SIRALAMA + RANK funksiyasi
-- Eyni maaş -> eyni RANK, novbeti deger atlanir


SELECT cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       cci.estimated_salary,
       RANK() OVER (ORDER BY cci.estimated_salary DESC) AS salary_rank
FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
ORDER BY salary_rank;



-- TASK 10: BALANSA GORE SIRALAMA + DENSE_RANK
-- Eyni balans -> eyni rank, novbeti deger ATLANMIR


SELECT cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       cci.balance,
       DENSE_RANK() OVER (ORDER BY cci.balance DESC) AS balance_dense_rank
FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
ORDER BY balance_dense_rank;


-- TASK 11: HER OLKE UZRE MUSTERILERIN YASA GORE SIRANMASI - ROW_NUMBER
-- Her olke uchun musterqil siralama
-- INDEX

SELECT 
       ci.country,
       cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       ci.age,
       ROW_NUMBER() OVER (PARTITION BY ci.country ORDER BY ci.age ASC) AS age_row_num

FROM customer_churn_info   cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
ORDER BY ci.country, age_row_num;


-- TASK 12: MUSTERI BALANS FERQINI TAPMAQ - LAG funksiyasi
-- Her mustericinin balansi ile evvelki mustericinin balansi arasindaki ferq


SELECT
       cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       cci.balance,
       LAG(cci.balance, 1, 0) OVER (ORDER BY cci.balance) AS prev_balance,
       cci.balance - LAG(cci.balance, 1, 0) OVER ( ORDER BY cci.balance) AS balance_diff

FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
ORDER BY cci.balance;

-- TASK 13: MAAŞ FERQINI MUEYYEN ETMEK - LEAD funksiyasi
-- Her mustericinin maasi ile novbeti mustericinin maasi arasindaki ferq

SELECT   
       cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       cci.estimated_salary,
       LEAD(cci.estimated_salary, 1, NULL) OVER (ORDER BY cci.estimated_salary) AS next_salary,
       LEAD(cci.estimated_salary, 1, NULL) OVER (ORDER BY cci.estimated_salary) - cci.estimated_salary AS salary_diff

FROM customer_churn_info   cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
ORDER BY cci.estimated_salary;


-- TASK 14(1) : AKTIV MUSTERILERIN TENURE GORE SIRANMASI + ROW_NUMBER
-- active_member = 1 olanlari tenure-e gore azalan sirada + unikal ROW_NUMBER


SELECT 
       cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       cci.tenure,
       cci.active_member,
       ROW_NUMBER() OVER (ORDER BY cci.tenure DESC) AS tenure_row_num

FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id

WHERE cci.active_member = 1
ORDER BY tenure_row_num;



-- TASK 14(2) : DENSE_RANK ile OLKELERDE CHURN EDEN MUSTERILERIN SIRANMASI
-- Her olke uzre churn=1 olan musterileri balansa gore siralayib DENSE_RANK ver


SELECT   
       ci.country,
       cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       cci.balance,
       DENSE_RANK() OVER (PARTITION BY ci.country ORDER BY cci.balance DESC) AS country_balance_rank

FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
WHERE cci.churn = 1
ORDER BY ci.country, country_balance_rank;



-- TASK 15: KREDIT SKORUNUN DEVISHMESINI ANALIZ ETMEK - LAG
-- Musterileri customer_id sirasi ile siralayib evvelki kredit skoru ile ferqi tap


SELECT   
       cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       cci.credit_score,
       LAG(cci.credit_score, 1, NULL) OVER ( ORDER BY cci.customer_id) AS prev_credit_score,
       cci.credit_score - LAG(cci.credit_score, 1, NULL) OVER (ORDER BY cci.customer_id) AS credit_score_diff
FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
ORDER BY cci.customer_id;



-- TASK 16: HER OLKEDE EN YUKSEK BALANSLI ILK 3 MUSTERI - ROW_NUMBER


SELECT 
       country,
       customer_id,
       full_name,
       balance,
       country_balance_row
FROM (
       SELECT   
              ci.country,
              cci.customer_id,
              ci.name || ' ' || ci.surname AS full_name,
              cci.balance,
              ROW_NUMBER() OVER (PARTITION BY ci.country ORDER BY cci.balance DESC) AS country_balance_row
       
       FROM customer_churn_info cci
       JOIN customer_info ci ON ci.customer_id = cci.customer_id
)

WHERE country_balance_row <= 3
ORDER BY country, country_balance_row;



-- TASK 17: MEHSUL SAYINA GORE DEVISHMENI TEHLIL ETMEK - LEAD
-- Her mustericinin products_number ile novbeti mustericinin products_number ferqi


SELECT   
       cci.customer_id,
       ci.name || ' ' || ci.surname AS full_name,
       cci.products_number,
       LEAD(cci.products_number, 1, NULL) OVER ( ORDER BY cci.customer_id) AS next_products_number,
       LEAD(cci.products_number, 1, NULL) OVER (ORDER BY cci.customer_id) - cci.products_number AS products_diff

FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
ORDER BY cci.customer_id;


















