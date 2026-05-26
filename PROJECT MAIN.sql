
-- BANK CUSTOMER CHURN - ORACLE SQL LAYIHE ISI
-- Author: MAHAMMAD RASULOV
-- Description: Full project script with tables, constraints,
-- relations, DML, analytics and window functions


-- TABLE 1 - CUSTOMER_INFO
-- Musteri demografik melumatlarini saxlayan esas table


CREATE TABLE customer_info (
    customer_id NUMBER(10),
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


-- STEP 2: TABLE 2 - CUSTOMER_CHURN_INFO
-- Churns melumatlari + kredit melumatlari

CREATE TABLE customer_churn_info (
    customer_id NUMBER(10),
    credit_score NUMBER(5) NOT NULL,
    tenure NUMBER(3) NOT NULL,
    balance NUMBER(15, 2) DEFAULT 0,
    products_number NUMBER(2) NOT NULL,
    credit_card NUMBER(1) DEFAULT 0,
    active_member NUMBER(1) DEFAULT 0,
    estimated_salary NUMBER(15, 2),
    churn NUMBER(1) DEFAULT 0,
    
    -- PRIMARY KEY
    CONSTRAINT pk_churn_info PRIMARY KEY (customer_id),

    -- FOREIGN KEY - customer_info-ya baglanir (3 table-i elaqelendiren zencir)
    CONSTRAINT fk_churn_customer FOREIGN KEY (customer_id) REFERENCES customer_info (customer_id) ON DELETE CASCADE,

    -- Credit score 300-850 araliginda olmalidir (FICO score range)
    CONSTRAINT chk_credit_score CHECK (credit_score BETWEEN 300 AND 850),

    -- Tenure (bankda kecirilen il) 0 ve ya musbet olmalidir
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
    CONSTRAINT chk_churn CHECK (churn IN (0, 1))

);

-- Index: churn uzre - en cox filter edilecek sutun
CREATE INDEX idx_churn_flag ON customer_churn_info (churn);

-- Index: active_member uzre
CREATE INDEX idx_active_member ON customer_churn_info (active_member);

-- Index: estimated_salary uzre
CREATE INDEX idx_salary ON customer_churn_info (estimated_salary);

-- Index: balance uzre
CREATE INDEX idx_balance ON customer_churn_info (balance);

-- Composite index: churn + balance
CREATE INDEX idx_churn_balance ON customer_churn_info (churn, balance DESC);

COMMENT ON TABLE customer_churn_info IS 'Mustericinin bank ile maliyye elaqeleri ve churn statusunu saxlayan cedvel';

COMMENT ON COLUMN customer_churn_info.churn IS '1 = Musteri banki terketmisdir, 0 = Musteri hala qalir';


-- STEP 3: TABLE 3 - UPDATED_LIST
-- Yenilenmis musteri siyahisi (MERGE ucun menbe table)


CREATE TABLE updated_list (
    customer_id NUMBER(10),
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


-- DATA INSERT - CUSTOMER_INFO

SELECT * FROM customer_info FOR UPDATE;

-- DATA INSERT - CUSTOMER_CHURN_INFO

SELECT * FROM customer_churn_info FOR UPDATE;

-- DATA INSERT - UPDATED_LIST

SELECT * FROM updated_list FOR UPDATE;


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


-- updated_list-də olan amma customer_info-da OLMAYAN müştərilər

INSERT INTO customer_info (customer_id, name, surname, gender, age, country)
SELECT 
    ul.customer_id,
    'Unknown'   AS name,
    'Unknown'   AS surname,
    'M'         AS gender,
    18          AS age,
    'Unknown'   AS country
FROM updated_list ul
WHERE NOT EXISTS (
    SELECT 1 
    FROM customer_info ci 
    WHERE ci.customer_id = ul.customer_id
);


-- MERGE amaliyyati
MERGE INTO customer_churn_info tgt
USING updated_list src
ON (tgt.customer_id = src.customer_id)

-- Eger musteri artiq customer_churn_info-da varsa -> UPDATE
WHEN MATCHED THEN
    UPDATE SET
        tgt.balance = src.balance,
        tgt.churn   = src.churn

-- Eger musteri customer_churn_info-da yoxdursa -> INSERT
WHEN NOT MATCHED THEN
    INSERT (
        customer_id,
        credit_score,
        tenure,
        balance,
        products_number,
        credit_card,
        active_member,
        estimated_salary,
        churn
    )
    VALUES (
        src.customer_id,
        src.credit_score,
        src.tenure,
        src.balance,
        src.products_number,
        src.credit_card,
        src.active_member,
        src.estimated_salary,
        src.churn
    );



-- TASK 4: MAX_CRE_AMOUNT sutunu elave edilmesi
-- İndi bezi (random) musteriler ucun UPDATE ile deyerler menimsedirik

-- Bezi musterilere manual UPDATE ile max kredit mebleg teyini

ALTER TABLE customer_churn_info 
ADD (max_cre_amount NUMBER(15, 2) DEFAULT NULL);

ALTER TABLE customer_churn_info
ADD CONSTRAINT chk_max_cre_amount CHECK (max_cre_amount IS NULL OR max_cre_amount >= 0);

COMMENT ON COLUMN customer_churn_info.max_cre_amount IS 'Mustecriye verilmesi planlasdirilan maksimum kredit meblegi';

--- Update
SELECT * FROM customer_churn_info FOR UPDATE;

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
       ci.gender AS gender,
       COUNT(*) AS churn_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS churn_pct

FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
WHERE cci.churn = 1
GROUP BY ci.gender
ORDER BY churn_count DESC;

---- 2 ci usul

SELECT ci.gender AS gender,
       COUNT(cci.churn) AS churn_count
FROM customer_info ci
JOIN customer_churn_info cci ON cci.customer_id = ci.customer_id
WHERE cci.churn = 1
GROUP BY ci.gender
ORDER BY COUNT(cci.churn) DESC 
FETCH FIRST 2 ROWS WITH TIES;

--- 3cu usul (with ile aqreqatlari ayiririg)

WITH churn_by_gender AS (
    SELECT ci.gender AS gender, COUNT(*) AS churn_count
    FROM customer_churn_info cci
    JOIN customer_info ci ON ci.customer_id = cci.customer_id
    WHERE cci.churn = 1
    GROUP BY ci.gender
)
SELECT 
    gender AS gender,
    churn_count AS churn_count,
    ROUND(churn_count * 100.0 / SUM(churn_count) OVER(), 2) AS churn_pct
FROM churn_by_gender
ORDER BY churn_count DESC;



-- TASK 6: CHURN ETMEYEN MUSTERILER ARASINDA EN AZ MAAŞ ALANLAR
-- Ilk en az maaş alan musteri XARIC, novbeti 3-u tapmaq
-- FETCH / OFFSET OLMADAN yazilmalidir -> ROW_NUMBER ile


SELECT 
       customer_id AS customer_id,
       estimated_salary AS estimated_salary,
       salary_rank AS salary_rank
FROM (
    SELECT   
           cci.customer_id AS customer_id,
           cci.estimated_salary AS estimated_salary,
           ROW_NUMBER() OVER (ORDER BY cci.estimated_salary ASC) AS salary_rank
    FROM customer_churn_info cci
    WHERE cci.churn = 0
)
WHERE salary_rank BETWEEN 2 AND 4
ORDER BY salary_rank;

---- 2 ci usul

WITH ranked_salaries AS (
    SELECT 
        customer_id AS customer_id,
        estimated_salary AS estimated_salary,
        ROW_NUMBER() OVER (ORDER BY estimated_salary ASC) AS salary_rank
    FROM customer_churn_info
    WHERE churn = 0
)
SELECT customer_id AS customer_id, estimated_salary AS estimated_salary, salary_rank AS salary_rank
FROM ranked_salaries
WHERE salary_rank BETWEEN 2 AND 4;

--- 3 cost(withden ustundu 1-2)

SELECT *
FROM (
  SELECT 
         ci.customer_id AS customer_id,
         cci.estimated_salary AS estimated_salary,
         ROW_NUMBER() OVER (ORDER BY cci.estimated_salary ASC) r       
  FROM customer_info ci
  JOIN customer_churn_info cci ON cci.customer_id = ci.customer_id
  WHERE cci.churn = 0
  ORDER BY cci.estimated_salary
)  
WHERE r BETWEEN 2 AND 4;


-- TASK 7: CHURN EDEN MUSTERILERIN SAYININ EN COX OLDUGU TOP 10 OLKE
-- en yaxsi varyant (withnende yazdim teqribi eyni olcu)

SELECT * 
FROM (
  SELECT ci.country AS country,
         COUNT(ci.customer_id) AS c_c_count,
         DENSE_RANK() OVER (ORDER BY COUNT(ci.customer_id) DESC) drn
  FROM customer_info ci
  JOIN customer_churn_info cci ON cci.customer_id = ci.customer_id
  WHERE cci.churn = 1
  GROUP BY ci.country
)
WHERE drn <= 10;

---- 2 Rownum ile (cost yuxari)

SELECT * FROM (
    SELECT 
        ci.country AS country,
        COUNT(*) AS churn_count
    FROM customer_churn_info cci
    JOIN customer_info ci ON ci.customer_id = cci.customer_id
    WHERE cci.churn = 1
    GROUP BY ci.country
    ORDER BY churn_count DESC
)
WHERE ROWNUM <= 10;

--- 3 Fetch+with ties (cost yuxari)

SELECT ci.country AS country,
       COUNT(ci.customer_id) AS c_c_count
FROM customer_info ci
JOIN customer_churn_info cci ON cci.customer_id = ci.customer_id
WHERE cci.churn = 1
GROUP BY ci.country
ORDER BY COUNT(ci.customer_id) DESC 
FETCH FIRST 10 ROWS WITH TIES;


-- TASK 8: CHURN EDEN MUSTERILERIN KARTI BALANSI EN COX OLAN TOP 10
-- INDEX Dense rank ile Best option 1000- bytes civari

SELECT 
       customer_id AS customer_id,
       balance AS balance,
       balance_rank AS balance_rank
FROM (
       SELECT   
              cci.customer_id AS customer_id,
              cci.balance AS balance,
              DENSE_RANK() OVER (ORDER BY cci.balance DESC) AS balance_rank
       FROM customer_churn_info cci
       WHERE cci.churn = 1
)

WHERE balance_rank <= 10
ORDER BY balance_rank;

---- 2 Row_number (index var lakin bytes coxdur)

SELECT * FROM (
    SELECT 
        cci.customer_id AS customer_id,
        cci.balance AS balance,
        ROW_NUMBER() OVER (ORDER BY cci.balance DESC) AS rn
    FROM customer_churn_info cci
    WHERE cci.churn = 1
)
WHERE rn <= 10;

--- 3 fetch ile (lakin bytes yene coxdur)

SELECT 
       cci.customer_id AS customer_id,
       cci.balance AS balance
FROM customer_churn_info cci
WHERE cci.churn = 1
ORDER BY cci.balance DESC 
FETCH FIRST 10 ROWS ONLY;



-- TASK 9: MAAŞA GORE SIRALAMA + RANK funksiyasi
-- Eyni maaş -> eyni RANK, novbeti deger atlanir
-- elave order by etmeye bu halda ehtiyac qalmir 
-- zaten siralayacag window func icerisinde

SELECT cci.customer_id AS customer_id,
       cci.estimated_salary AS estimated_salary,
       RANK() OVER (ORDER BY cci.estimated_salary DESC) e_s_rank
FROM customer_churn_info cci;


-- TASK 10: BALANSA GORE SIRALAMA + DENSE_RANK
-- Eyni balans -> eyni rank, novbeti deger ATLANMIR


SELECT cci.customer_id AS customer_id,
       cci.balance AS balance,
       DENSE_RANK() OVER (ORDER BY cci.balance DESC) b_rank
FROM customer_churn_info cci;


-- TASK 11: HER OLKE UZRE MUSTERILERIN YASA GORE SIRANMASI - ROW_NUMBER
-- Her olke uchun musterqil siralama
-- INDEX
-- 0.056 saniye
SELECT 
       ci.country AS country,
       cci.customer_id AS customer_id,
       ci.age AS age,
       ROW_NUMBER() OVER (PARTITION BY ci.country ORDER BY ci.age ASC) AS age_row_num

FROM customer_churn_info   cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
ORDER BY ci.country, age_row_num;

-- 0.064 saniye (eyni cost ama bytes ferqi)

SELECT ci.customer_id AS customer_id,
       ci.country AS country,
       ci.age AS age,
       ROW_NUMBER() OVER (PARTITION BY ci.country ORDER BY ci.age ASC) age_rank
FROM customer_info ci;


-- TASK 12: MUSTERI BALANS FERQINI TAPMAQ - LAG funksiyasi
-- Her mustericinin balansi ile evvelki mustericinin balansi arasindaki ferq
--(Teqribi 1500 byte)

SELECT
       cci.customer_id AS customer_id,
       cci.balance AS balance,
       LAG(cci.balance, 1, 0) OVER (ORDER BY cci.balance) AS prev_balance,
       cci.balance - LAG(cci.balance, 1, 0) OVER ( ORDER BY cci.balance) AS balance_diff

FROM customer_churn_info cci;


--- bele bir variantda kecerlidir subquery icerisinden getiresen

SELECT customer_id AS customer_id,
       balance AS balance,
       b_lag AS prev_balance,
       balance - b_lag AS diff
FROM (
  SELECT cci.customer_id AS customer_id,
         cci.balance AS balance,
         LAG(cci.balance) OVER (ORDER BY cci.balance DESC) b_lag
  FROM customer_churn_info cci
);



-- TASK 13: MAAŞ FERQINI MUEYYEN ETMEK - LEAD funksiyasi
-- Her mustericinin maasi ile novbeti mustericinin maasi arasindaki ferq

SELECT   
       cci.customer_id AS customer_id,
       cci.estimated_salary AS estimated_salary,
       LEAD(cci.estimated_salary, 1, NULL) OVER (ORDER BY cci.estimated_salary) AS next_salary,
       LEAD(cci.estimated_salary, 1, NULL) OVER (ORDER BY cci.estimated_salary) - cci.estimated_salary AS salary_diff

FROM customer_churn_info cci;


-- TASK 14 (1) : AKTIV MUSTERILERIN TENURE GORE SIRANMASI + ROW_NUMBER
-- active_member = 1 olanlari tenure-e gore azalan sirada + unikal ROW_NUMBER

-- 0.031 saniye
SELECT 
       cci.customer_id AS customer_id,
       cci.tenure AS tenure,
       cci.active_member AS active_member,
       ROW_NUMBER() OVER (ORDER BY cci.tenure DESC) AS tenure_row_num

FROM customer_churn_info cci
WHERE cci.active_member = 1;


-- 0.041 saniye rownumber yerine ranklar olan varyanti
SELECT 
    cci.customer_id AS customer_id,
    cci.tenure AS tenure,
    RANK() OVER (ORDER BY cci.tenure DESC) AS tenure_rank,
    DENSE_RANK() OVER (ORDER BY cci.tenure DESC) AS tenure_dense_rank
FROM customer_churn_info cci
WHERE cci.active_member = 1;



-- TASK 14 (2) : DENSE_RANK ile OLKELERDE CHURN EDEN MUSTERILERIN SIRANMASI
-- Her olke uzre churn=1 olan musterileri balansa gore siralayib DENSE_RANK ver


SELECT   
       ci.country AS country,
       cci.customer_id AS customer_id,
       cci.balance AS balance,
       DENSE_RANK() OVER (PARTITION BY ci.country ORDER BY cci.balance DESC) AS country_balance_rank

FROM customer_churn_info cci
JOIN customer_info ci ON ci.customer_id = cci.customer_id
WHERE cci.churn = 1;


-- TASK 15: KREDIT SKORUNUN DEVISHMESINI ANALIZ ETMEK - LAG
-- Musterileri customer_id sirasi ile siralayib evvelki kredit skoru ile ferqi tap


SELECT   
       cci.customer_id AS customer_id,
       cci.credit_score AS credit_score,
       LAG(cci.credit_score, 1, NULL) OVER ( ORDER BY cci.customer_id) AS prev_credit_score,
       cci.credit_score - LAG(cci.credit_score, 1, NULL) OVER (ORDER BY cci.customer_id) AS credit_score_diff
FROM customer_churn_info cci;

-- tenure elavesi zamani bytes artisi

SELECT 
       cci.customer_id AS customer_id,
       cci.tenure AS tenure,
       cci.credit_score AS credit_score,
       LAG(cci.credit_score) OVER (ORDER BY cci.tenure) cs_lag,
       cci.credit_score - LAG(cci.credit_score) OVER (ORDER BY cci.tenure) AS diff
FROM customer_churn_info cci;


-- TASK 16: HER OLKEDE EN YUKSEK BALANSLI ILK 3 MUSTERI - ROW_NUMBER

SELECT 
       country AS country,
       customer_id AS customer_id,
       balance AS balance,
       country_balance_row AS country_balance_row
FROM (
       SELECT   
              ci.country AS country,
              cci.customer_id AS customer_id,
              cci.balance AS balance,
              ROW_NUMBER() OVER (PARTITION BY ci.country ORDER BY cci.balance DESC) AS country_balance_row

       FROM customer_churn_info cci
       JOIN customer_info ci ON ci.customer_id = cci.customer_id
)
WHERE country_balance_row <= 3
ORDER BY country, country_balance_row;



-- TASK 17: MEHSUL SAYINA GORE DEVISHMENI TEHLIL ETMEK - LEAD
-- Her mustericinin products_number ile novbeti mustericinin products_number ferqi


SELECT   
       cci.customer_id AS customer_id,
       cci.products_number AS products_number,
       LEAD(cci.products_number, 1, NULL) OVER ( ORDER BY cci.customer_id) AS next_products_number,
       LEAD(cci.products_number, 1, NULL) OVER (ORDER BY cci.customer_id) - cci.products_number AS products_diff

FROM customer_churn_info cci;


--- elave emelyatlar 

SELECT * FROM customer_churn_info;
SELECT * FROM customer_info;
SELECT * FROM updated_list

DELETE FROM customer_churn_info WHERE 1=1;
DELETE FROM updated_list WHERE 1=1


-- Sequence yarada bilerik

-- TRANSACTION_ID üçün sequence
-- Hər yeni əməliyyat (transfer, kredit müraciəti, kart əməliyyatı) üçün unikal ID yaradır

CREATE SEQUENCE seq_transaction_id
START WITH 1000000001
INCREMENT BY 1
CACHE 100
NOCYCLE;

COMMENT ON SEQUENCE seq_transaction_id IS 'Bank əməliyyatları üçün unikal transaction ID generator';


--- Audit Log ID (Dəyişiklik tarixçəsi üçün)

CREATE SEQUENCE seq_audit_id
START WITH 1
INCREMENT BY 1
CACHE 50
NOCYCLE;


-- Loan Application ID (Kredit müraciətləri üçün)

CREATE SEQUENCE seq_loan_id
START WITH 100000
INCREMENT BY 1
CACHE 20
NOCYCLE;


----- Manual explain plan yaradib indexe baxag
---- Subquery ilə yazanda bu index işə düşür
--- Çünki hər iki sütun birlikdə filter olunur

EXPLAIN PLAN FOR
SELECT customer_id, balance
FROM (
    SELECT customer_id, balance,
           DENSE_RANK() OVER (ORDER BY balance DESC) AS rnk
    FROM customer_churn_info
    WHERE churn = 1        -- idx_churn_balance işə düşür
)
WHERE rnk <= 10;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


--- comentlere baxis ucun queryler:

SELECT * FROM user_tab_comments WHERE table_name = 'CUSTOMER_INFO';

SELECT * FROM user_col_comments WHERE table_name = 'CUSTOMER_INFO';

SELECT * FROM user_tab_comments WHERE table_name = 'CUSTOMER_CHURN_INFO';

SELECT * FROM user_tab_comments WHERE table_name = 'UPDATED_LIST';
