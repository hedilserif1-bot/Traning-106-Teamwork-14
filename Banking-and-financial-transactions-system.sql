--Banking-and-financial-transactions-system.sql
/*banking system DB */

CREATE DATABASE banking_system;

USE banking_system;


/* table branches */

CREATE TABLE branches(
    id INT PRIMARY KEY AUTO_INCREMENT,
    branch_code VARCHAR(20) NOT NULL UNIQUE,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    opened_at DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    
    CHECK (status IN ('active', 'inactive'))
);


/* table customers */

CREATE TABLE customers(
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_number VARCHAR(30) NOT NULL UNIQUE,
    full_name VARCHAR(150) NOT NULL,
    national_id VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100),
    phone VARCHAR(20),
    birthday DATE,
    city VARCHAR(100),
    address VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    
    CHECK(status IN ('active', 'inactive', 'blocked'))
);


/* table accounts */

CREATE TABLE accounts(
    id INT PRIMARY KEY AUTO_INCREMENT,
    account_number VARCHAR(30) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    branch_id INT NOT NULL,
    account_type VARCHAR(25),
    currency VARCHAR(3) NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0,
    opened_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',
    
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    
    CHECK (account_type IN ('checking', 'saving', 'business')),
    CHECK (currency IN ('SAR', 'USD', 'EUR', 'BRL')),
    CHECK (balance >= 0),
    CHECK (status IN ('active', 'frozen', 'closed'))
);


/* table beneficiaries */

CREATE TABLE beneficiaries (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    beneficiary_account_id INT NOT NULL,
    nickname VARCHAR(100) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active',

    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (beneficiary_account_id) REFERENCES accounts(id),

    CHECK (status IN ('active', 'inactive'))
);


/* table transfers */

CREATE TABLE transfers(
    id INT PRIMARY KEY AUTO_INCREMENT,
    reference_number VARCHAR(50) NOT NULL UNIQUE,
    from_account_id INT NOT NULL,
    to_account_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transfer_fee DECIMAL(15,2) DEFAULT 0,
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    status VARCHAR(20) DEFAULT 'pending',
    
    FOREIGN KEY (from_account_id) REFERENCES accounts(id),
    FOREIGN KEY (to_account_id) REFERENCES accounts(id),
    
    CHECK (amount > 0),
    CHECK (transfer_fee >= 0),
    CHECK (from_account_id <> to_account_id),
    CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled'))
    
);


/* ================================================================================== */

/* table transactions */

CREATE TABLE transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    transfer_id INT,
    transaction_type VARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    balance_before DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2) NOT NULL,
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'completed',
    
    FOREIGN KEY (account_id) REFERENCES accounts(id),
    FOREIGN KEY (transfer_id) REFERENCES transfers(id),
    
    CHECK (amount > 0),
    CHECK (transaction_type IN (
        'deposit',
        'withdrawal',
        'transfer_in',
        'transfer_out',
        'fee',
        'refund',
        'loan_payment'
    ))
);


/* TABLE cards */

CREATE TABLE cards (
    id INT PRIMARY KEY AUTO_INCREMENT,
    account_id INT NOT NULL,
    card_number VARCHAR(30) NOT NULL UNIQUE,
    card_type VARCHAR(20) NOT NULL,
    issued_at DATE NOT NULL,
    expiry_date DATE NOT NULL,
    daily_limit DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',

    FOREIGN KEY (account_id) REFERENCES accounts(id),

    CHECK (card_type IN ('debit', 'credit')),
    CHECK (daily_limit >= 0),

    CHECK (status IN (
        'active',
        'blocked',
        'expired',
        'cancelled'
    ))
);


/* TABLE card_transactions */

CREATE TABLE card_transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    merchant_name VARCHAR(150) NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending',
    
    FOREIGN KEY (card_id) REFERENCES cards(id),
    
    CHECK (amount > 0),
    CHECK (status IN (
        'pending',
        'approved',
        'declined',
        'refunded'
    ))
);


/* table loan */

CREATE TABLE loans (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    loan_number VARCHAR(50) NOT NULL UNIQUE,
    principal_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',

    FOREIGN KEY (customer_id) REFERENCES customers(id),

    CHECK (principal_amount >= 0),
    CHECK (interest_rate >= 0),
    CHECK (total_amount >= principal_amount),
    CHECK (
        status IN (
            'pending',
            'active',
            'paid',
            'defaulted',
            'cancelled'
        )
    )
);


/* TABLE loan_installments */

CREATE TABLE loan_installments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    installment_number INT NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    paid_amount DECIMAL(15,2) DEFAULT 0,
    paid_at DATETIME,
    status VARCHAR(20) DEFAULT 'pending',

    FOREIGN KEY (loan_id) REFERENCES loans(id),

    CHECK (amount >= 0),
    CHECK (paid_amount >= 0),
    CHECK (paid_amount <= amount),
    CHECK (
        status IN (
            'pending',
            'partially_paid',
            'paid',
            'overdue'
        )
    ),

    UNIQUE (loan_id, installment_number)
);


/* audit_logs */

CREATE TABLE audit_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    account_id INT,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (account_id) REFERENCES accounts(id)
);


-- inserting DATA to the banking system

-- =========================================
-- BRANCHES (6)
-- =========================================

INSERT INTO branches
(branch_code, branch_name, city, address, phone, opened_at, status)
VALUES
('BR001','Main Branch','Riyadh','King Fahd Road','0111111111','2020-01-01','active'),
('BR002','North Branch','Jeddah','King Road','0122222222','2020-02-01','active'),
('BR003','East Branch','Dammam','Main Street','0133333333','2020-03-01','active'),
('BR004','West Branch','Makkah','Central Road','0124444444','2020-04-01','active'),
('BR005','South Branch','Khobar','King Faisal Road','0135555555','2020-05-01','active'),
('BR006','Central Branch','Riyadh','Olaya Street','0116666666','2020-06-01','inactive');


-- =========================================
-- CUSTOMERS (50)
-- =========================================

INSERT INTO customers
(customer_number, full_name, national_id, email, phone,
 birthday, city, address, status)
VALUES
('C001','Ahmed Ali','N1001','ahmed01@email.com','0500000001','1990-01-10','Riyadh','Olaya','active'),
('C002','Mohammed Hassan','N1002','mohammed02@email.com','0500000002','1991-02-15','Jeddah','Al Hamra','active'),
('C003','Omar Khaled','N1003','omar03@email.com','0500000003','1988-03-20','Dammam','Al Shati','active'),
('C004','Sara Ahmed','N1004','sara04@email.com','0500000004','1995-04-25','Riyadh','Malaz','active'),
('C005','Noura Ali','N1005','noura05@email.com','0500000005','1993-05-30','Makkah','Aziziyah','active'),
('C006','Khalid Salem','N1006','khalid06@email.com','0500000006','1987-06-12','Khobar','Al Aqrabiyah','active'),
('C007','Fahad Omar','N1007','fahad07@email.com','0500000007','1992-07-18','Riyadh','Yasmin','active'),
('C008','Lama Hassan','N1008','lama08@email.com','0500000008','1994-08-22','Jeddah','Al Rawdah','active'),
('C009','Abdullah Saad','N1009','abdullah09@email.com','0500000009','1989-09-14','Dammam','Faisaliyah','active'),
('C010','Reem Khaled','N1010','reem10@email.com','0500000010','1996-10-05','Khobar','Al Ulaya','active'),

('C011','Yousef Ahmed','N1011','yousef11@email.com','0500000011','1986-11-19','Riyadh','Wurud','active'),
('C012','Huda Mohammed','N1012','huda12@email.com','0500000012','1991-12-08','Makkah','Aziziyah','active'),
('C013','Saad Ibrahim','N1013','saad13@email.com','0500000013','1985-01-27','Jeddah','Al Zahra','active'),
('C014','Maha Salem','N1014','maha14@email.com','0500000014','1993-02-11','Riyadh','Mursalat','active'),
('C015','Turki Nasser','N1015','turki15@email.com','0500000015','1990-03-17','Dammam','Shati','active'),
('C016','Rania Omar','N1016','rania16@email.com','0500000016','1995-04-29','Khobar','Bandariyah','active'),
('C017','Majed Hassan','N1017','majed17@email.com','0500000017','1988-05-13','Riyadh','Nakheel','active'),
('C018','Abeer Khaled','N1018','abeer18@email.com','0500000018','1992-06-21','Jeddah','Salamah','active'),
('C019','Nawaf Ahmed','N1019','nawaf19@email.com','0500000019','1987-07-09','Dammam','Nur','active'),
('C020','Dania Saad','N1020','dania20@email.com','0500000020','1994-08-16','Khobar','Hamra','active'),

('C021','Hassan Ali','N1021','hassan21@email.com','0500000021','1985-09-24','Riyadh','Batha','active'),
('C022','Nasser Mohammed','N1022','nasser22@email.com','0500000022','1990-10-12','Jeddah','Safa','active'),
('C023','Sultan Omar','N1023','sultan23@email.com','0500000023','1989-11-03','Dammam','Nur','active'),
('C024','Waleed Ibrahim','N1024','waleed24@email.com','0500000024','1993-12-15','Khobar','Aqrabiyah','active'),
('C025','Bader Salem','N1025','bader25@email.com','0500000025','1986-01-06','Riyadh','Rawdah','active'),
('C026','Faisal Saad','N1026','faisal26@email.com','0500000026','1991-02-28','Makkah','Misfalah','active'),
('C027','Rakan Nasser','N1027','rakan27@email.com','0500000027','1988-03-19','Riyadh','Hamra','active'),
('C028','Ziyad Majed','N1028','ziyad28@email.com','0500000028','1994-04-07','Jeddah','Marwah','active'),
('C029','Adel Ahmed','N1029','adel29@email.com','0500000029','1987-05-23','Dammam','Adamah','active'),
('C030','Yasser Saleh','N1030','yasser30@email.com','0500000030','1992-06-30','Khobar','Aqrabiyah','active'),

('C031','Mansour Mohammed','N1031','mansour31@email.com','0500000031','1986-07-14','Riyadh','Malaz','active'),
('C032','Ibrahim Ahmed','N1032','ibrahim32@email.com','0500000032','1990-08-26','Jeddah','Rawdah','active'),
('C033','Abdulrahman Khalid','N1033','abdulrahman33@email.com','0500000033','1988-09-05','Dammam','Shati','active'),
('C034','Meshari Omar','N1034','meshari34@email.com','0500000034','1993-10-18','Riyadh','Yasmin','active'),
('C035','Talal Hassan','N1035','talal35@email.com','0500000035','1987-11-29','Makkah','Aziziyah','active'),
('C036','Khalifa Salem','N1036','khalifa36@email.com','0500000036','1991-12-20','Khobar','Ulaya','active'),
('C037','Nasser Saad','N1037','nasser37@email.com','0500000037','1989-01-15','Jeddah','Hamra','active'),
('C038','Rami Nasser','N1038','rami38@email.com','0500000038','1994-02-09','Riyadh','Nakheel','active'),
('C039','Ayman Majed','N1039','ayman39@email.com','0500000039','1985-03-27','Dammam','Faisaliyah','active'),
('C040','Hatem Turki','N1040','hatem40@email.com','0500000040','1992-04-13','Khobar','Bandariyah','active'),

('C041','Khaled Abdullah','N1041','khaled41@email.com','0500000041','1988-05-21','Riyadh','Wurud','active'),
('C042','Amal Ali','N1042','amal42@email.com','0500000042','1990-06-08','Jeddah','Salamah','active'),
('C043','Mariam Hassan','N1043','mariam43@email.com','0500000043','1986-07-17','Dammam','Shati','active'),
('C044','Noor Ibrahim','N1044','noor44@email.com','0500000044','1993-08-25','Khobar','Aqrabiyah','active'),
('C045','Wijdan Salem','N1045','wijdan45@email.com','0500000045','1989-09-12','Riyadh','Olaya','active'),
('C046','Saeed Saad','N1046','saeed46@email.com','0500000046','1991-10-29','Makkah','Misfalah','active'),
('C047','Hind Nasser','N1047','hind47@email.com','0500000047','1995-11-06','Jeddah','Zahra','active'),
('C048','Faisal Majed','N1048','faisal48@email.com','0500000048','1987-12-22','Riyadh','Yasmin','active'),
('C049','Latifa Ahmed','N1049','latifa49@email.com','0500000049','1993-01-31','Dammam','Nur','inactive'),
('C050','Bandar Saleh','N1050','bandar50@email.com','0500000050','1985-02-18','Khobar','Khobar North','blocked');



/* two */

-- =========================================
-- ACCOUNTS (75)
-- =========================================

INSERT INTO accounts
(account_number, customer_id, branch_id, account_type, currency, balance, status)
VALUES
('A001',1,1,'checking','SAR',12500.00,'active'),
('A002',1,1,'saving','SAR',45000.00,'active'),
('A003',2,2,'checking','SAR',8200.00,'active'),
('A004',2,2,'saving','USD',12000.00,'active'),
('A005',3,3,'checking','SAR',15600.00,'active'),
('A006',3,3,'saving','EUR',9500.00,'active'),
('A007',4,1,'checking','SAR',23000.00,'active'),
('A008',5,1,'saving','SAR',67000.00,'active'),
('A009',5,1,'business','SAR',150000.00,'active'),
('A010',6,4,'checking','SAR',9100.00,'active'),

('A011',7,1,'checking','USD',7800.00,'active'),
('A012',8,2,'saving','SAR',34000.00,'active'),
('A013',9,3,'checking','EUR',5400.00,'active'),
('A014',10,5,'checking','SAR',18700.00,'active'),
('A015',11,1,'saving','SAR',29000.00,'active'),
('A016',12,4,'checking','SAR',11300.00,'active'),
('A017',13,3,'saving','USD',15600.00,'active'),
('A018',14,1,'checking','SAR',7200.00,'active'),
('A019',15,4,'saving','EUR',8700.00,'active'),
('A020',16,5,'checking','SAR',19200.00,'active'),

('A021',17,2,'checking','SAR',8100.00,'active'),
('A022',18,1,'saving','SAR',41000.00,'active'),
('A023',19,3,'checking','USD',6700.00,'active'),
('A024',20,5,'saving','SAR',53000.00,'active'),
('A025',21,1,'business','SAR',185000.00,'active'),
('A026',22,2,'checking','SAR',9300.00,'active'),
('A027',23,3,'saving','EUR',11400.00,'active'),
('A028',24,5,'checking','SAR',16100.00,'active'),
('A029',25,1,'saving','SAR',49000.00,'active'),
('A030',26,4,'checking','SAR',7600.00,'active'),

('A031',27,1,'checking','USD',8900.00,'active'),
('A032',28,2,'saving','SAR',37000.00,'active'),
('A033',29,3,'checking','SAR',12800.00,'active'),
('A034',30,5,'saving','EUR',10200.00,'active'),
('A035',31,1,'checking','SAR',21700.00,'active'),
('A036',32,2,'saving','SAR',61000.00,'active'),
('A037',33,3,'business','SAR',220000.00,'active'),
('A038',34,1,'checking','SAR',6800.00,'active'),
('A039',35,4,'saving','USD',13800.00,'active'),
('A040',36,5,'checking','SAR',17400.00,'active'),

('A041',37,2,'saving','SAR',33000.00,'active'),
('A042',38,1,'checking','EUR',7600.00,'active'),
('A043',39,3,'saving','SAR',45000.00,'active'),
('A044',40,5,'checking','SAR',9900.00,'active'),
('A045',41,1,'business','SAR',175000.00,'active'),
('A046',42,2,'checking','SAR',14300.00,'active'),
('A047',43,3,'saving','USD',9200.00,'active'),
('A048',44,5,'checking','SAR',18400.00,'active'),
('A049',45,1,'saving','SAR',56000.00,'active'),
('A050',46,4,'checking','SAR',8100.00,'active'),

('A051',47,2,'saving','EUR',11500.00,'active'),
('A052',48,1,'checking','SAR',13200.00,'active'),
('A053',49,3,'saving','SAR',39000.00,'active'),
('A054',50,5,'checking','SAR',4500.00,'frozen'),
('A055',7,1,'saving','SAR',27000.00,'active'),
('A056',12,2,'checking','USD',6500.00,'active'),
('A057',18,1,'saving','EUR',8700.00,'active'),
('A058',23,3,'checking','SAR',11900.00,'active'),
('A059',29,3,'saving','SAR',31000.00,'active'),
('A060',35,4,'checking','SAR',8700.00,'active'),

('A061',41,1,'saving','USD',14400.00,'active'),
('A062',46,4,'checking','SAR',10200.00,'active'),
('A063',2,2,'business','SAR',98000.00,'active'),
('A064',8,2,'checking','SAR',7600.00,'active'),
('A065',14,1,'saving','SAR',28500.00,'active'),
('A066',20,5,'checking','USD',7100.00,'active'),
('A067',26,4,'saving','SAR',36000.00,'active'),
('A068',32,2,'checking','EUR',6800.00,'active'),
('A069',38,1,'saving','SAR',42000.00,'active'),
('A070',44,5,'checking','SAR',9300.00,'active'),

('A071',10,5,'saving','USD',12000.00,'active'),
('A072',16,5,'checking','SAR',15500.00,'active'),
('A073',22,2,'saving','SAR',47000.00,'active'),
('A074',28,2,'checking','SAR',8200.00,'active'),
('A075',34,1,'saving','EUR',9700.00,'active');


-- =========================================
-- BENEFICIARIES (40)
-- =========================================

INSERT INTO beneficiaries
(customer_id, beneficiary_account_id, nickname, status)
VALUES
(1,3,'Mohammed Account','active'),
(1,5,'Omar Account','active'),
(2,1,'Ahmed Account','active'),
(2,7,'Khalid Account','active'),
(3,8,'Fahad Account','active'),
(3,10,'Abdullah Account','active'),
(4,12,'Yousef Account','active'),
(4,15,'Sara Account','active'),
(5,16,'Noura Account','active'),
(5,18,'Huda Account','active'),

(6,20,'Maha Account','active'),
(7,22,'Abeer Account','active'),
(8,24,'Asma Account','active'),
(9,25,'Business Account','active'),
(10,27,'Ziyad Account','active'),
(11,28,'Waleed Account','active'),
(12,29,'Bader Account','active'),
(13,30,'Faisal Account','active'),
(14,31,'Rakan Account','active'),
(15,32,'Majed Account','active'),

(16,33,'Adel Account','active'),
(17,34,'Yasser Account','active'),
(18,35,'Mansour Account','active'),
(19,36,'Ibrahim Account','active'),
(20,37,'Abdulrahman Account','active'),
(21,38,'Meshari Account','active'),
(22,39,'Talal Account','active'),
(23,40,'Khalifa Account','active'),
(24,41,'Nasser Account','active'),
(25,42,'Rami Account','active'),

(26,43,'Ayman Account','active'),
(27,44,'Hatem Account','active'),
(28,45,'Business Savings','active'),
(29,46,'Saeed Account','active'),
(30,47,'Faisal Account','active'),
(31,48,'Latifa Account','active'),
(32,49,'Wijdan Account','active'),
(33,50,'Hind Account','inactive'),
(34,51,'Faisal Account','active'),
(35,52,'Ahmed Account','active');



/* three */

-- =========================================
-- TRANSFERS (150)
-- =========================================

INSERT INTO transfers
(reference_number, from_account_id, to_account_id, amount, transfer_fee,
 description, created_at, completed_at, status)
VALUES
('TR001',1,3,500.00,5.00,'Family transfer','2024-01-01 09:00:00','2024-01-01 09:05:00','completed'),
('TR002',2,4,1000.00,10.00,'Monthly payment','2024-01-02 10:00:00','2024-01-02 10:05:00','completed'),
('TR003',3,5,750.00,5.00,'Personal transfer','2024-01-03 11:00:00',NULL,'pending'),
('TR004',4,7,1200.00,10.00,'Bill payment','2024-01-04 12:00:00',NULL,'failed'),
('TR005',5,8,850.00,5.00,'Family support','2024-01-05 13:00:00','2024-01-05 13:05:00','completed'),
('TR006',6,10,1500.00,10.00,'Rent payment','2024-01-06 09:30:00','2024-01-06 09:35:00','completed'),
('TR007',7,12,400.00,5.00,'Personal transfer','2024-01-07 10:30:00',NULL,'processing'),
('TR008',8,15,2300.00,10.00,'Family transfer','2024-01-08 11:30:00','2024-01-08 11:35:00','completed'),
('TR009',9,16,1800.00,5.00,'Business payment','2024-01-09 12:30:00',NULL,'pending'),
('TR010',10,18,600.00,5.00,'Personal transfer','2024-01-10 13:30:00',NULL,'cancelled'),

('TR011',11,20,950.00,5.00,'Family transfer','2024-01-11 09:00:00','2024-01-11 09:05:00','completed'),
('TR012',12,22,1100.00,10.00,'Monthly payment','2024-01-12 10:00:00','2024-01-12 10:05:00','completed'),
('TR013',13,24,700.00,5.00,'Personal transfer','2024-01-13 11:00:00','2024-01-13 11:05:00','completed'),
('TR014',14,25,2500.00,15.00,'Business payment','2024-01-14 12:00:00',NULL,'processing'),
('TR015',15,27,900.00,5.00,'Family support','2024-01-15 13:00:00',NULL,'pending'),
('TR016',16,28,1300.00,10.00,'Bill payment','2024-01-16 09:00:00','2024-01-16 09:05:00','completed'),
('TR017',17,30,650.00,5.00,'Personal transfer','2024-01-17 10:00:00',NULL,'failed'),
('TR018',18,31,1700.00,10.00,'Family transfer','2024-01-18 11:00:00','2024-01-18 11:05:00','completed'),
('TR019',19,33,1200.00,5.00,'Monthly payment','2024-01-19 12:00:00','2024-01-19 12:05:00','completed'),
('TR020',20,35,800.00,5.00,'Personal transfer','2024-01-20 13:00:00',NULL,'cancelled'),

('TR021',21,36,1450.00,10.00,'Family transfer','2024-01-21 09:00:00','2024-01-21 09:05:00','completed'),
('TR022',22,38,600.00,5.00,'Bill payment','2024-01-22 10:00:00','2024-01-22 10:05:00','completed'),
('TR023',23,40,2100.00,10.00,'Business payment','2024-01-23 11:00:00',NULL,'pending'),
('TR024',24,41,550.00,5.00,'Personal transfer','2024-01-24 12:00:00','2024-01-24 12:05:00','completed'),
('TR025',25,43,3200.00,15.00,'Business transfer','2024-01-25 13:00:00',NULL,'processing'),
('TR026',26,44,900.00,5.00,'Family transfer','2024-01-26 09:00:00','2024-01-26 09:05:00','completed'),
('TR027',27,46,750.00,5.00,'Personal transfer','2024-01-27 10:00:00',NULL,'failed'),
('TR028',28,47,1600.00,10.00,'Monthly payment','2024-01-28 11:00:00','2024-01-28 11:05:00','completed'),
('TR029',29,49,2000.00,10.00,'Family support','2024-01-29 12:00:00','2024-01-29 12:05:00','completed'),
('TR030',30,50,450.00,5.00,'Personal transfer','2024-01-30 13:00:00',NULL,'pending'),

('TR031',31,52,1150.00,5.00,'Family transfer','2024-02-01 09:00:00','2024-02-01 09:05:00','completed'),
('TR032',32,53,1300.00,10.00,'Bill payment','2024-02-02 10:00:00','2024-02-02 10:05:00','completed'),
('TR033',33,54,700.00,5.00,'Personal transfer','2024-02-03 11:00:00',NULL,'failed'),
('TR034',34,55,1800.00,10.00,'Family transfer','2024-02-04 12:00:00','2024-02-04 12:05:00','completed'),
('TR035',35,56,950.00,5.00,'Monthly payment','2024-02-05 13:00:00',NULL,'processing'),
('TR036',36,57,1450.00,10.00,'Personal transfer','2024-02-06 09:00:00','2024-02-06 09:05:00','completed'),
('TR037',37,58,800.00,5.00,'Family support','2024-02-07 10:00:00','2024-02-07 10:05:00','completed'),
('TR038',38,59,2200.00,10.00,'Business payment','2024-02-08 11:00:00',NULL,'pending'),
('TR039',39,60,650.00,5.00,'Personal transfer','2024-02-09 12:00:00',NULL,'cancelled'),
('TR040',40,61,1750.00,10.00,'Monthly payment','2024-02-10 13:00:00','2024-02-10 13:05:00','completed'),

('TR041',41,62,900.00,5.00,'Family transfer','2024-02-11 09:00:00','2024-02-11 09:05:00','completed'),
('TR042',42,63,2400.00,15.00,'Business payment','2024-02-12 10:00:00',NULL,'processing'),
('TR043',43,64,700.00,5.00,'Personal transfer','2024-02-13 11:00:00','2024-02-13 11:05:00','completed'),
('TR044',44,65,1100.00,10.00,'Bill payment','2024-02-14 12:00:00','2024-02-14 12:05:00','completed'),
('TR045',45,66,3500.00,15.00,'Business transfer','2024-02-15 13:00:00',NULL,'pending'),
('TR046',46,67,850.00,5.00,'Family support','2024-02-16 09:00:00','2024-02-16 09:05:00','completed'),
('TR047',47,68,1200.00,10.00,'Monthly payment','2024-02-17 10:00:00',NULL,'failed'),
('TR048',48,69,600.00,5.00,'Personal transfer','2024-02-18 11:00:00','2024-02-18 11:05:00','completed'),
('TR049',49,70,1800.00,10.00,'Family transfer','2024-02-19 12:00:00','2024-02-19 12:05:00','completed'),
('TR050',50,71,950.00,5.00,'Personal transfer','2024-02-20 13:00:00',NULL,'cancelled'),

('TR051',51,72,1300.00,10.00,'Bill payment','2024-02-21 09:00:00','2024-02-21 09:05:00','completed'),
('TR052',52,73,750.00,5.00,'Family transfer','2024-02-22 10:00:00','2024-02-22 10:05:00','completed'),
('TR053',53,74,2100.00,10.00,'Business payment','2024-02-23 11:00:00',NULL,'pending'),
('TR054',54,75,500.00,5.00,'Personal transfer','2024-02-24 12:00:00','2024-02-24 12:05:00','completed'),
('TR055',55,1,1500.00,10.00,'Family support','2024-02-25 13:00:00',NULL,'processing'),
('TR056',56,2,900.00,5.00,'Monthly payment','2024-02-26 09:00:00','2024-02-26 09:05:00','completed'),
('TR057',57,3,1200.00,10.00,'Personal transfer','2024-02-27 10:00:00','2024-02-27 10:05:00','completed'),
('TR058',58,4,800.00,5.00,'Family transfer','2024-02-28 11:00:00',NULL,'failed'),
('TR059',59,5,2300.00,10.00,'Business payment','2024-02-29 12:00:00','2024-02-29 12:05:00','completed'),
('TR060',60,6,650.00,5.00,'Personal transfer','2024-03-01 13:00:00',NULL,'pending'),

('TR061',61,7,1400.00,10.00,'Family transfer','2024-03-02 09:00:00','2024-03-02 09:05:00','completed'),
('TR062',62,8,950.00,5.00,'Bill payment','2024-03-03 10:00:00','2024-03-03 10:05:00','completed'),
('TR063',63,9,3000.00,15.00,'Business payment','2024-03-04 11:00:00',NULL,'processing'),
('TR064',64,10,700.00,5.00,'Personal transfer','2024-03-05 12:00:00','2024-03-05 12:05:00','completed'),
('TR065',65,11,1150.00,10.00,'Monthly payment','2024-03-06 13:00:00',NULL,'failed'),
('TR066',66,12,850.00,5.00,'Family support','2024-03-07 09:00:00','2024-03-07 09:05:00','completed'),
('TR067',67,13,1700.00,10.00,'Business transfer','2024-03-08 10:00:00','2024-03-08 10:05:00','completed'),
('TR068',68,14,600.00,5.00,'Personal transfer','2024-03-09 11:00:00',NULL,'pending'),
('TR069',69,15,2000.00,10.00,'Family transfer','2024-03-10 12:00:00','2024-03-10 12:05:00','completed'),
('TR070',70,16,900.00,5.00,'Bill payment','2024-03-11 13:00:00',NULL,'cancelled'),

('TR071',71,17,1250.00,10.00,'Family transfer','2024-03-12 09:00:00','2024-03-12 09:05:00','completed'),
('TR072',72,18,700.00,5.00,'Personal transfer','2024-03-13 10:00:00','2024-03-13 10:05:00','completed'),
('TR073',73,19,1600.00,10.00,'Monthly payment','2024-03-14 11:00:00',NULL,'pending'),
('TR074',74,20,800.00,5.00,'Family support','2024-03-15 12:00:00','2024-03-15 12:05:00','completed'),
('TR075',75,21,2400.00,15.00,'Business payment','2024-03-16 13:00:00',NULL,'processing'),
('TR076',1,22,550.00,5.00,'Personal transfer','2024-03-17 09:00:00','2024-03-17 09:05:00','completed'),
('TR077',2,23,1300.00,10.00,'Family transfer','2024-03-18 10:00:00','2024-03-18 10:05:00','completed'),
('TR078',3,24,900.00,5.00,'Bill payment','2024-03-19 11:00:00',NULL,'failed'),
('TR079',4,25,1750.00,10.00,'Business payment','2024-03-20 12:00:00','2024-03-20 12:05:00','completed'),
('TR080',5,26,650.00,5.00,'Personal transfer','2024-03-21 13:00:00',NULL,'pending'),

('TR081',6,27,1450.00,10.00,'Family transfer','2024-03-22 09:00:00','2024-03-22 09:05:00','completed'),
('TR082',7,28,800.00,5.00,'Monthly payment','2024-03-23 10:00:00','2024-03-23 10:05:00','completed'),
('TR083',8,29,2200.00,10.00,'Business payment','2024-03-24 11:00:00',NULL,'processing'),
('TR084',9,30,500.00,5.00,'Personal transfer','2024-03-25 12:00:00','2024-03-25 12:05:00','completed'),
('TR085',10,31,1000.00,10.00,'Family support','2024-03-26 13:00:00',NULL,'failed'),
('TR086',11,32,1350.00,10.00,'Bill payment','2024-03-27 09:00:00','2024-03-27 09:05:00','completed'),
('TR087',12,33,750.00,5.00,'Personal transfer','2024-03-28 10:00:00','2024-03-28 10:05:00','completed'),
('TR088',13,34,1800.00,10.00,'Family transfer','2024-03-29 11:00:00',NULL,'pending'),
('TR089',14,35,950.00,5.00,'Monthly payment','2024-03-30 12:00:00','2024-03-30 12:05:00','completed'),
('TR090',15,36,1250.00,10.00,'Personal transfer','2024-03-31 13:00:00',NULL,'cancelled'),

('TR091',16,37,700.00,5.00,'Family transfer','2024-04-01 09:00:00','2024-04-01 09:05:00','completed'),
('TR092',17,38,2100.00,10.00,'Business payment','2024-04-02 10:00:00','2024-04-02 10:05:00','completed'),
('TR093',18,39,600.00,5.00,'Personal transfer','2024-04-03 11:00:00',NULL,'pending'),
('TR094',19,40,1600.00,10.00,'Bill payment','2024-04-04 12:00:00','2024-04-04 12:05:00','completed'),
('TR095',20,41,900.00,5.00,'Family support','2024-04-05 13:00:00',NULL,'processing'),
('TR096',21,42,1450.00,10.00,'Monthly payment','2024-04-06 09:00:00','2024-04-06 09:05:00','completed'),
('TR097',22,43,800.00,5.00,'Personal transfer','2024-04-07 10:00:00',NULL,'failed'),
('TR098',23,44,1900.00,10.00,'Business transfer','2024-04-08 11:00:00','2024-04-08 11:05:00','completed'),
('TR099',24,45,550.00,5.00,'Family transfer','2024-04-09 12:00:00','2024-04-09 12:05:00','completed'),
('TR100',25,46,2500.00,15.00,'Business payment','2024-04-10 13:00:00',NULL,'pending'),

('TR101',26,47,750.00,5.00,'Personal transfer','2024-04-11 09:00:00','2024-04-11 09:05:00','completed'),
('TR102',27,48,1100.00,10.00,'Monthly payment','2024-04-12 10:00:00','2024-04-12 10:05:00','completed'),
('TR103',28,49,900.00,5.00,'Family support','2024-04-13 11:00:00',NULL,'failed'),
('TR104',29,50,1300.00,10.00,'Bill payment','2024-04-14 12:00:00','2024-04-14 12:05:00','completed'),
('TR105',30,51,650.00,5.00,'Personal transfer','2024-04-15 13:00:00',NULL,'processing'),
('TR106',31,52,1700.00,10.00,'Family transfer','2024-04-16 09:00:00','2024-04-16 09:05:00','completed'),
('TR107',32,53,850.00,5.00,'Monthly payment','2024-04-17 10:00:00','2024-04-17 10:05:00','completed'),
('TR108',33,54,2200.00,10.00,'Business payment','2024-04-18 11:00:00',NULL,'pending'),
('TR109',34,55,500.00,5.00,'Personal transfer','2024-04-19 12:00:00','2024-04-19 12:05:00','completed'),
('TR110',35,56,1200.00,10.00,'Family transfer','2024-04-20 13:00:00',NULL,'cancelled'),

('TR111',36,57,950.00,5.00,'Personal transfer','2024-04-21 09:00:00','2024-04-21 09:05:00','completed'),
('TR112',37,58,1500.00,10.00,'Bill payment','2024-04-22 10:00:00','2024-04-22 10:05:00','completed'),
('TR113',38,59,700.00,5.00,'Family support','2024-04-23 11:00:00',NULL,'pending'),
('TR114',39,60,1800.00,10.00,'Business payment','2024-04-24 12:00:00','2024-04-24 12:05:00','completed'),
('TR115',40,61,600.00,5.00,'Personal transfer','2024-04-25 13:00:00',NULL,'failed'),
('TR116',41,62,1250.00,10.00,'Monthly payment','2024-04-26 09:00:00','2024-04-26 09:05:00','completed'),
('TR117',42,63,900.00,5.00,'Family transfer','2024-04-27 10:00:00','2024-04-27 10:05:00','completed'),
('TR118',43,64,2400.00,15.00,'Business transfer','2024-04-28 11:00:00',NULL,'processing'),
('TR119',44,65,750.00,5.00,'Personal transfer','2024-04-29 12:00:00','2024-04-29 12:05:00','completed'),
('TR120',45,66,1350.00,10.00,'Family transfer','2024-04-30 13:00:00',NULL,'pending'),

('TR121',46,67,800.00,5.00,'Bill payment','2024-05-01 09:00:00','2024-05-01 09:05:00','completed'),
('TR122',47,68,2100.00,10.00,'Business payment','2024-05-02 10:00:00','2024-05-02 10:05:00','completed'),
('TR123',48,69,650.00,5.00,'Personal transfer','2024-05-03 11:00:00',NULL,'failed'),
('TR124',49,70,1000.00,10.00,'Family support','2024-05-04 12:00:00','2024-05-04 12:05:00','completed'),
('TR125',50,71,1450.00,10.00,'Monthly payment','2024-05-05 13:00:00',NULL,'processing'),
('TR126',51,72,900.00,5.00,'Personal transfer','2024-05-06 09:00:00','2024-05-06 09:05:00','completed'),
('TR127',52,73,1700.00,10.00,'Family transfer','2024-05-07 10:00:00','2024-05-07 10:05:00','completed'),
('TR128',53,74,700.00,5.00,'Bill payment','2024-05-08 11:00:00',NULL,'pending'),
('TR129',54,75,2300.00,10.00,'Business payment','2024-05-09 12:00:00','2024-05-09 12:05:00','completed'),
('TR130',55,1,550.00,5.00,'Personal transfer','2024-05-10 13:00:00',NULL,'cancelled'),

('TR131',56,2,1300.00,10.00,'Family transfer','2024-05-11 09:00:00','2024-05-11 09:05:00','completed'),
('TR132',57,3,850.00,5.00,'Monthly payment','2024-05-12 10:00:00','2024-05-12 10:05:00','completed'),
('TR133',58,4,1600.00,10.00,'Business payment','2024-05-13 11:00:00',NULL,'failed'),
('TR134',59,5,750.00,5.00,'Personal transfer','2024-05-14 12:00:00','2024-05-14 12:05:00','completed'),
('TR135',60,6,2000.00,10.00,'Family support','2024-05-15 13:00:00',NULL,'pending'),
('TR136',61,7,950.00,5.00,'Bill payment','2024-05-16 09:00:00','2024-05-16 09:05:00','completed'),
('TR137',62,8,1400.00,10.00,'Monthly payment','2024-05-17 10:00:00','2024-05-17 10:05:00','completed'),
('TR138',63,9,600.00,5.00,'Personal transfer','2024-05-18 11:00:00',NULL,'processing'),
('TR139',64,10,1850.00,10.00,'Family transfer','2024-05-19 12:00:00','2024-05-19 12:05:00','completed'),
('TR140',65,11,700.00,5.00,'Personal transfer','2024-05-20 13:00:00',NULL,'pending'),

('TR141',66,12,1250.00,10.00,'Family support','2024-05-21 09:00:00','2024-05-21 09:05:00','completed'),
('TR142',67,13,900.00,5.00,'Bill payment','2024-05-22 10:00:00','2024-05-22 10:05:00','completed'),
('TR143',68,14,2200.00,10.00,'Business payment','2024-05-23 11:00:00',NULL,'failed'),
('TR144',69,15,650.00,5.00,'Personal transfer','2024-05-24 12:00:00','2024-05-24 12:05:00','completed'),
('TR145',70,16,1500.00,10.00,'Family transfer','2024-05-25 13:00:00','2024-05-25 13:05:00','completed'),
('TR146',71,17,800.00,5.00,'Monthly payment','2024-05-26 09:00:00',NULL,'pending'),
('TR147',72,18,1100.00,10.00,'Personal transfer','2024-05-27 10:00:00','2024-05-27 10:05:00','completed'),
('TR148',73,19,1750.00,10.00,'Business transfer','2024-05-28 11:00:00',NULL,'processing'),
('TR149',74,20,500.00,5.00,'Family support','2024-05-29 12:00:00','2024-05-29 12:05:00','completed'),
('TR150',75,21,950.00,5.00,'Personal transfer','2024-05-30 13:00:00',NULL,'cancelled');


-- =========================================
-- TRANSACTIONS (400)
-- =========================================

INSERT INTO transactions
(account_id, transfer_id, transaction_type, amount,
 balance_before, balance_after, description, status)
VALUES
(1,NULL,'deposit',5000,7500,12500,'Cash deposit','completed'),
(2,NULL,'withdrawal',1000,46000,45000,'ATM withdrawal','completed'),
(3,1,'transfer_in',500,7700,8200,'Incoming transfer','completed'),
(4,2,'transfer_in',1000,11000,12000,'Incoming transfer','completed'),
(5,3,'transfer_out',750,16350,15600,'Outgoing transfer','pending'),
(6,4,'transfer_out',1200,10700,9500,'Outgoing transfer','failed'),
(7,5,'transfer_in',850,22150,23000,'Incoming transfer','completed'),
(8,6,'transfer_out',1500,68500,67000,'Outgoing transfer','completed'),
(9,NULL,'deposit',10000,140000,150000,'Business deposit','completed'),
(10,NULL,'withdrawal',900,10000,9100,'ATM withdrawal','completed'),

(11,7,'transfer_out',400,8200,7800,'Outgoing transfer','processing'),
(12,8,'transfer_in',2300,31700,34000,'Incoming transfer','completed'),
(13,9,'transfer_out',1800,7200,5400,'Outgoing transfer','pending'),
(14,10,'transfer_out',600,19300,18700,'Outgoing transfer','cancelled'),
(15,11,'transfer_in',950,28050,29000,'Incoming transfer','completed'),
(16,12,'transfer_out',1100,12400,11300,'Outgoing transfer','completed'),
(17,13,'transfer_in',700,14900,15600,'Incoming transfer','completed'),
(18,14,'transfer_out',2500,9700,7200,'Outgoing transfer','processing'),
(19,15,'transfer_out',900,9600,8700,'Outgoing transfer','pending'),
(20,16,'transfer_in',1300,17900,19200,'Incoming transfer','completed'),

(21,17,'transfer_out',650,8750,8100,'Outgoing transfer','failed'),
(22,18,'transfer_in',1700,39300,41000,'Incoming transfer','completed'),
(23,19,'transfer_out',1200,7900,6700,'Outgoing transfer','completed'),
(24,20,'transfer_out',800,53800,53000,'Outgoing transfer','cancelled'),
(25,21,'transfer_in',1450,183550,185000,'Incoming transfer','completed'),
(26,22,'transfer_out',600,9900,9300,'Outgoing transfer','completed'),
(27,23,'transfer_out',2100,13500,11400,'Outgoing transfer','pending'),
(28,24,'transfer_in',550,15550,16100,'Incoming transfer','completed'),
(29,25,'transfer_out',3200,52200,49000,'Outgoing transfer','processing'),
(30,26,'transfer_in',900,6700,7600,'Incoming transfer','completed'),

(31,27,'transfer_out',750,9650,8900,'Outgoing transfer','failed'),
(32,28,'transfer_in',1600,35400,37000,'Incoming transfer','completed'),
(33,29,'transfer_out',2000,14800,12800,'Outgoing transfer','completed'),
(34,30,'transfer_in',450,9750,10200,'Incoming transfer','pending'),
(35,31,'transfer_out',1150,22850,21700,'Outgoing transfer','completed'),
(36,32,'transfer_in',1300,59700,61000,'Incoming transfer','completed'),
(37,33,'transfer_out',700,220700,220000,'Outgoing transfer','failed'),
(38,34,'transfer_in',1800,5000,6800,'Incoming transfer','completed'),
(39,35,'transfer_out',950,14750,13800,'Outgoing transfer','processing'),
(40,36,'transfer_in',1450,15950,17400,'Incoming transfer','completed'),

(41,37,'transfer_in',800,32200,33000,'Incoming transfer','completed'),
(42,38,'transfer_out',2200,9800,7600,'Outgoing transfer','pending'),
(43,39,'transfer_out',650,45650,45000,'Outgoing transfer','cancelled'),
(44,40,'transfer_in',1750,8150,9900,'Incoming transfer','completed'),
(45,41,'transfer_out',900,175900,175000,'Outgoing transfer','completed'),
(46,42,'transfer_in',2400,11900,14300,'Incoming transfer','processing'),
(47,43,'transfer_out',700,9900,9200,'Outgoing transfer','completed'),
(48,44,'transfer_in',1100,17300,18400,'Incoming transfer','completed'),
(49,45,'transfer_out',3500,59500,56000,'Outgoing transfer','pending'),
(50,46,'transfer_in',850,7250,8100,'Incoming transfer','completed'),

(51,47,'transfer_out',1200,12700,11500,'Outgoing transfer','failed'),
(52,48,'transfer_in',600,12600,13200,'Incoming transfer','completed'),
(53,49,'transfer_out',1800,40800,39000,'Outgoing transfer','completed'),
(54,50,'transfer_out',950,5450,4500,'Outgoing transfer','cancelled'),
(55,51,'transfer_in',1300,25700,27000,'Incoming transfer','completed'),
(56,52,'transfer_out',750,7250,6500,'Outgoing transfer','completed'),
(57,53,'transfer_in',2100,6600,8700,'Incoming transfer','pending'),
(58,54,'transfer_out',500,12400,11900,'Outgoing transfer','completed'),
(59,55,'transfer_out',1500,32500,31000,'Outgoing transfer','processing'),
(60,56,'transfer_in',900,7800,8700,'Incoming transfer','completed'),

(61,57,'transfer_in',1200,13200,14400,'Incoming transfer','completed'),
(62,58,'transfer_out',800,11000,10200,'Outgoing transfer','failed'),
(63,59,'transfer_in',2300,95700,98000,'Incoming transfer','completed'),
(64,60,'transfer_out',650,8250,7600,'Outgoing transfer','pending'),
(65,61,'transfer_in',1400,27100,28500,'Incoming transfer','completed'),
(66,62,'transfer_out',950,8050,7100,'Outgoing transfer','completed'),
(67,63,'transfer_out',3000,39000,36000,'Outgoing transfer','processing'),
(68,64,'transfer_in',700,6100,6800,'Incoming transfer','completed'),
(69,65,'transfer_out',1150,43150,42000,'Outgoing transfer','failed'),
(70,66,'transfer_in',850,8450,9300,'Incoming transfer','completed'),

(71,67,'transfer_out',1700,13700,12000,'Outgoing transfer','completed'),
(72,68,'transfer_in',600,14900,15500,'Incoming transfer','pending'),
(73,69,'transfer_out',2000,49000,47000,'Outgoing transfer','completed'),
(74,70,'transfer_out',900,9100,8200,'Outgoing transfer','cancelled'),
(75,71,'transfer_in',1250,8450,9700,'Incoming transfer','completed'),

(1,NULL,'deposit',2000,10500,12500,'Salary deposit','completed'),
(2,NULL,'withdrawal',500,45500,45000,'ATM withdrawal','completed'),
(3,NULL,'deposit',1200,7000,8200,'Cash deposit','completed'),
(4,NULL,'withdrawal',800,12800,12000,'ATM withdrawal','completed'),
(5,NULL,'deposit',2500,13100,15600,'Salary deposit','completed'),
(6,NULL,'withdrawal',700,10200,9500,'ATM withdrawal','completed'),
(7,NULL,'deposit',1800,21200,23000,'Cash deposit','completed'),
(8,NULL,'withdrawal',1000,68000,67000,'ATM withdrawal','completed'),
(9,NULL,'deposit',5000,145000,150000,'Business deposit','completed'),
(10,NULL,'withdrawal',400,9500,9100,'ATM withdrawal','completed'),

(11,NULL,'deposit',1500,6300,7800,'Salary deposit','completed'),
(12,NULL,'withdrawal',600,34600,34000,'ATM withdrawal','completed'),
(13,NULL,'deposit',1000,4400,5400,'Cash deposit','completed'),
(14,NULL,'withdrawal',500,19200,18700,'ATM withdrawal','completed'),
(15,NULL,'deposit',2000,27000,29000,'Salary deposit','completed'),
(16,NULL,'withdrawal',700,12000,11300,'ATM withdrawal','completed'),
(17,NULL,'deposit',1000,14600,15600,'Cash deposit','completed'),
(18,NULL,'withdrawal',800,8000,7200,'ATM withdrawal','completed'),
(19,NULL,'deposit',1500,7200,8700,'Salary deposit','completed'),
(20,NULL,'withdrawal',500,19700,19200,'ATM withdrawal','completed'),

(21,NULL,'deposit',900,7200,8100,'Cash deposit','completed'),
(22,NULL,'withdrawal',1000,42000,41000,'ATM withdrawal','completed'),
(23,NULL,'deposit',800,5900,6700,'Salary deposit','completed'),
(24,NULL,'withdrawal',1000,54000,53000,'ATM withdrawal','completed'),
(25,NULL,'deposit',5000,180000,185000,'Business deposit','completed'),
(26,NULL,'withdrawal',500,9800,9300,'ATM withdrawal','completed'),
(27,NULL,'deposit',1000,10400,11400,'Cash deposit','completed'),
(28,NULL,'withdrawal',700,16800,16100,'ATM withdrawal','completed'),
(29,NULL,'deposit',2000,47000,49000,'Salary deposit','completed'),
(30,NULL,'withdrawal',600,8200,7600,'ATM withdrawal','completed'),

(31,NULL,'deposit',1200,7700,8900,'Cash deposit','completed'),
(32,NULL,'withdrawal',800,37800,37000,'ATM withdrawal','completed'),
(33,NULL,'deposit',3000,12500,15500,'Business deposit','completed'),
(34,NULL,'withdrawal',400,10600,10200,'ATM withdrawal','completed'),
(35,NULL,'deposit',2000,19700,21700,'Salary deposit','completed'),
(36,NULL,'withdrawal',1000,62000,61000,'ATM withdrawal','completed'),
(37,NULL,'deposit',5000,215000,220000,'Business deposit','completed'),
(38,NULL,'withdrawal',500,7300,6800,'ATM withdrawal','completed'),
(39,NULL,'deposit',1500,12300,13800,'Salary deposit','completed'),
(40,NULL,'withdrawal',700,18100,17400,'ATM withdrawal','completed'),

(41,NULL,'deposit',2000,31000,33000,'Cash deposit','completed'),
(42,NULL,'withdrawal',500,8100,7600,'ATM withdrawal','completed'),
(43,NULL,'deposit',2500,42500,45000,'Salary deposit','completed'),
(44,NULL,'withdrawal',600,10500,9900,'ATM withdrawal','completed'),
(45,NULL,'deposit',5000,170000,175000,'Business deposit','completed'),
(46,NULL,'withdrawal',800,11000,10200,'ATM withdrawal','completed'),
(47,NULL,'deposit',1000,8200,9200,'Cash deposit','completed'),
(48,NULL,'withdrawal',500,18900,18400,'ATM withdrawal','completed'),
(49,NULL,'deposit',3000,53000,56000,'Salary deposit','completed'),
(50,NULL,'withdrawal',400,8500,8100,'ATM withdrawal','completed'),

(51,NULL,'deposit',1500,10000,11500,'Cash deposit','completed'),
(52,NULL,'withdrawal',800,14000,13200,'ATM withdrawal','completed'),
(53,NULL,'deposit',2000,37000,39000,'Salary deposit','completed'),
(54,NULL,'withdrawal',500,5000,4500,'ATM withdrawal','completed'),
(55,NULL,'deposit',1000,26000,27000,'Cash deposit','completed'),
(56,NULL,'withdrawal',700,7200,6500,'ATM withdrawal','completed'),
(57,NULL,'deposit',1500,7200,8700,'Salary deposit','completed'),
(58,NULL,'withdrawal',500,12400,11900,'ATM withdrawal','completed'),
(59,NULL,'deposit',2500,28500,31000,'Cash deposit','completed'),
(60,NULL,'withdrawal',600,9300,8700,'ATM withdrawal','completed'),

(61,NULL,'deposit',2000,12400,14400,'Salary deposit','completed'),
(62,NULL,'withdrawal',700,10900,10200,'ATM withdrawal','completed'),
(63,NULL,'deposit',5000,93000,98000,'Business deposit','completed'),
(64,NULL,'withdrawal',500,8100,7600,'ATM withdrawal','completed'),
(65,NULL,'deposit',1500,27000,28500,'Cash deposit','completed'),
(66,NULL,'withdrawal',600,7700,7100,'ATM withdrawal','completed'),
(67,NULL,'deposit',3000,33000,36000,'Salary deposit','completed'),
(68,NULL,'withdrawal',500,7300,6800,'ATM withdrawal','completed'),
(69,NULL,'deposit',2500,39500,42000,'Cash deposit','completed'),
(70,NULL,'withdrawal',500,9800,9300,'ATM withdrawal','completed'),

(71,NULL,'deposit',1000,11000,12000,'Salary deposit','completed'),
(72,NULL,'withdrawal',500,16000,15500,'ATM withdrawal','completed'),
(73,NULL,'deposit',3000,44000,47000,'Cash deposit','completed'),
(74,NULL,'withdrawal',400,8600,8200,'ATM withdrawal','completed'),
(75,NULL,'deposit',1000,8700,9700,'Salary deposit','completed'),

(1,NULL,'fee',25,12500,12475,'Monthly service fee','completed'),
(2,NULL,'fee',15,45000,44985,'Account fee','completed'),
(3,NULL,'refund',100,8200,8300,'Refund','completed'),
(4,NULL,'fee',20,12000,11980,'Service fee','completed'),
(5,NULL,'loan_payment',850,15600,14750,'Loan payment','completed'),
(6,NULL,'fee',15,9500,9485,'Account fee','completed'),
(7,NULL,'refund',75,23000,23075,'Refund','completed'),
(8,NULL,'fee',25,67000,66975,'Monthly fee','completed'),
(9,NULL,'loan_payment',2000,150000,148000,'Loan payment','completed'),
(10,NULL,'fee',15,9100,9085,'Service fee','completed'),

(11,NULL,'loan_payment',900,7800,6900,'Loan payment','completed'),
(12,NULL,'fee',20,34000,33980,'Service fee','completed'),
(13,NULL,'refund',150,5400,5550,'Refund','completed'),
(14,NULL,'fee',15,18700,18685,'Account fee','completed'),
(15,NULL,'loan_payment',1200,29000,27800,'Loan payment','completed'),
(16,NULL,'fee',25,11300,11275,'Monthly fee','completed'),
(17,NULL,'refund',80,15600,15680,'Refund','completed'),
(18,NULL,'fee',15,7200,7185,'Service fee','completed'),
(19,NULL,'loan_payment',1000,8700,7700,'Loan payment','completed'),
(20,NULL,'fee',20,19200,19180,'Account fee','completed'),

(21,NULL,'loan_payment',750,8100,7350,'Loan payment','completed'),
(22,NULL,'fee',15,41000,40985,'Service fee','completed'),
(23,NULL,'refund',120,6700,6820,'Refund','completed'),
(24,NULL,'fee',25,53000,52975,'Monthly fee','completed'),
(25,NULL,'loan_payment',2500,185000,182500,'Loan payment','completed'),
(26,NULL,'fee',15,9300,9285,'Account fee','completed'),
(27,NULL,'refund',90,11400,11490,'Refund','completed'),
(28,NULL,'fee',20,16100,16080,'Service fee','completed'),
(29,NULL,'loan_payment',1400,49000,47600,'Loan payment','completed'),
(30,NULL,'fee',15,7600,7585,'Account fee','completed'),

(31,NULL,'loan_payment',1100,8900,7800,'Loan payment','completed'),
(32,NULL,'fee',25,37000,36975,'Monthly fee','completed'),
(33,NULL,'refund',200,15500,15700,'Refund','completed'),
(34,NULL,'fee',15,10200,10185,'Service fee','completed'),
(35,NULL,'loan_payment',900,21700,20800,'Loan payment','completed'),
(36,NULL,'fee',20,61000,60980,'Account fee','completed'),
(37,NULL,'loan_payment',3000,220000,217000,'Loan payment','completed'),
(38,NULL,'fee',15,6800,6785,'Service fee','completed'),
(39,NULL,'refund',100,13800,13900,'Refund','completed'),
(40,NULL,'fee',25,17400,17375,'Monthly fee','completed'),

(41,NULL,'loan_payment',850,33000,32150,'Loan payment','completed'),
(42,NULL,'fee',15,7600,7585,'Account fee','completed'),
(43,NULL,'refund',150,45000,45150,'Refund','completed'),
(44,NULL,'fee',20,9900,9880,'Service fee','completed'),
(45,NULL,'loan_payment',2200,175000,172800,'Loan payment','completed'),
(46,NULL,'fee',15,10200,10185,'Account fee','completed'),
(47,NULL,'refund',75,9200,9275,'Refund','completed'),
(48,NULL,'fee',25,18400,18375,'Monthly fee','completed'),
(49,NULL,'loan_payment',1500,56000,54500,'Loan payment','completed'),
(50,NULL,'fee',15,8100,8085,'Service fee','completed'),

(51,NULL,'loan_payment',800,11500,10700,'Loan payment','completed'),
(52,NULL,'fee',20,13200,13180,'Account fee','completed'),
(53,NULL,'refund',100,39000,39100,'Refund','completed'),
(54,NULL,'fee',15,4500,4485,'Service fee','completed'),
(55,NULL,'loan_payment',700,27000,26300,'Loan payment','completed'),
(56,NULL,'fee',20,6500,6480,'Account fee','completed'),
(57,NULL,'refund',90,8700,8790,'Refund','completed'),
(58,NULL,'fee',15,11900,11885,'Service fee','completed'),
(59,NULL,'loan_payment',1000,31000,30000,'Loan payment','completed'),
(60,NULL,'fee',25,8700,8675,'Monthly fee','completed'),

(61,NULL,'loan_payment',1200,14400,13200,'Loan payment','completed'),
(62,NULL,'fee',15,10200,10185,'Account fee','completed'),
(63,NULL,'loan_payment',3000,98000,95000,'Loan payment','completed'),
(64,NULL,'fee',20,7600,7580,'Service fee','completed'),
(65,NULL,'refund',125,28500,28625,'Refund','completed'),
(66,NULL,'fee',15,7100,7085,'Account fee','completed'),
(67,NULL,'loan_payment',1800,36000,34200,'Loan payment','completed'),
(68,NULL,'fee',20,6800,6780,'Service fee','completed'),
(69,NULL,'refund',100,42000,42100,'Refund','completed'),
(70,NULL,'fee',15,9300,9285,'Account fee','completed'),

(71,NULL,'loan_payment',900,12000,11100,'Loan payment','completed'),
(72,NULL,'fee',20,15500,15480,'Service fee','completed'),
(73,NULL,'refund',150,47000,47150,'Refund','completed'),
(74,NULL,'fee',15,8200,8185,'Account fee','completed'),
(75,NULL,'loan_payment',1000,9700,8700,'Loan payment','completed'),

(1,NULL,'deposit',3000,12475,15475,'Salary deposit','completed'),
(2,NULL,'withdrawal',1200,44985,43785,'ATM withdrawal','completed'),
(3,NULL,'deposit',800,8300,9100,'Cash deposit','completed'),
(4,NULL,'withdrawal',600,11980,11380,'ATM withdrawal','completed'),
(5,NULL,'deposit',2000,14750,16750,'Salary deposit','completed'),
(6,NULL,'withdrawal',500,9485,8985,'ATM withdrawal','completed'),
(7,NULL,'deposit',1500,23075,24575,'Cash deposit','completed'),
(8,NULL,'withdrawal',800,66975,66175,'ATM withdrawal','completed'),
(9,NULL,'deposit',4000,148000,152000,'Business deposit','completed'),
(10,NULL,'withdrawal',300,9085,8785,'ATM withdrawal','completed'),

(11,NULL,'deposit',1200,6900,8100,'Salary deposit','completed'),
(12,NULL,'withdrawal',500,33980,33480,'ATM withdrawal','completed'),
(13,NULL,'deposit',700,5550,6250,'Cash deposit','completed'),
(14,NULL,'withdrawal',400,18685,18285,'ATM withdrawal','completed'),
(15,NULL,'deposit',1800,27800,29600,'Salary deposit','completed'),
(16,NULL,'withdrawal',500,11275,10775,'ATM withdrawal','completed'),
(17,NULL,'deposit',900,15680,16580,'Cash deposit','completed'),
(18,NULL,'withdrawal',300,7185,6885,'ATM withdrawal','completed'),
(19,NULL,'deposit',1100,7700,8800,'Salary deposit','completed'),
(20,NULL,'withdrawal',700,19180,18480,'ATM withdrawal','completed'),

(21,NULL,'deposit',1000,7350,8350,'Cash deposit','completed'),
(22,NULL,'withdrawal',800,40985,40185,'ATM withdrawal','completed'),
(23,NULL,'deposit',900,6820,7720,'Salary deposit','completed'),
(24,NULL,'withdrawal',500,52975,52475,'ATM withdrawal','completed'),
(25,NULL,'deposit',4000,182500,186500,'Business deposit','completed'),
(26,NULL,'withdrawal',400,9285,8885,'ATM withdrawal','completed'),
(27,NULL,'deposit',700,11490,12190,'Cash deposit','completed'),
(28,NULL,'withdrawal',600,16080,15480,'ATM withdrawal','completed'),
(29,NULL,'deposit',2000,47600,49600,'Salary deposit','completed'),
(30,NULL,'withdrawal',300,7585,7285,'ATM withdrawal','completed'),

(31,NULL,'deposit',1000,7800,8800,'Cash deposit','completed'),
(32,NULL,'withdrawal',700,36975,36275,'ATM withdrawal','completed'),
(33,NULL,'deposit',2500,15700,18200,'Business deposit','completed'),
(34,NULL,'withdrawal',400,10185,9785,'ATM withdrawal','completed'),
(35,NULL,'deposit',1500,20800,22300,'Salary deposit','completed'),
(36,NULL,'withdrawal',800,60980,60180,'ATM withdrawal','completed'),
(37,NULL,'deposit',3500,217000,220500,'Business deposit','completed'),
(38,NULL,'withdrawal',300,6785,6485,'ATM withdrawal','completed'),
(39,NULL,'deposit',1200,13900,15100,'Salary deposit','completed'),
(40,NULL,'withdrawal',500,17375,16875,'ATM withdrawal','completed'),

(41,NULL,'deposit',1500,32150,33650,'Cash deposit','completed'),
(42,NULL,'withdrawal',400,7585,7185,'ATM withdrawal','completed'),
(43,NULL,'deposit',2000,45150,47150,'Salary deposit','completed'),
(44,NULL,'withdrawal',300,9880,9580,'ATM withdrawal','completed'),
(45,NULL,'deposit',4000,172800,176800,'Business deposit','completed'),
(46,NULL,'withdrawal',500,10185,9685,'ATM withdrawal','completed'),
(47,NULL,'deposit',800,9275,10075,'Cash deposit','completed'),
(48,NULL,'withdrawal',400,18375,17975,'ATM withdrawal','completed'),
(49,NULL,'deposit',2500,54500,57000,'Salary deposit','completed'),
(50,NULL,'withdrawal',300,8085,7785,'ATM withdrawal','completed'),

(51,NULL,'deposit',1000,10700,11700,'Cash deposit','completed'),
(52,NULL,'withdrawal',500,13180,12680,'ATM withdrawal','completed'),
(53,NULL,'deposit',1800,39100,40900,'Salary deposit','completed'),
(54,NULL,'withdrawal',300,4485,4185,'ATM withdrawal','completed'),
(55,NULL,'deposit',1200,26300,27500,'Cash deposit','completed'),
(56,NULL,'withdrawal',400,6480,6080,'ATM withdrawal','completed'),
(57,NULL,'deposit',800,8790,9590,'Salary deposit','completed'),
(58,NULL,'withdrawal',300,11885,11585,'ATM withdrawal','completed'),
(59,NULL,'deposit',2000,30000,32000,'Cash deposit','completed'),
(60,NULL,'withdrawal',500,8675,8175,'ATM withdrawal','completed'),

(61,NULL,'deposit',1500,13200,14700,'Salary deposit','completed'),
(62,NULL,'withdrawal',400,10185,9785,'ATM withdrawal','completed'),
(63,NULL,'deposit',5000,95000,100000,'Business deposit','completed'),
(64,NULL,'withdrawal',300,7580,7280,'ATM withdrawal','completed'),
(65,NULL,'deposit',1200,28625,29825,'Cash deposit','completed'),
(66,NULL,'withdrawal',400,7085,6685,'ATM withdrawal','completed'),
(67,NULL,'deposit',2500,34200,36700,'Salary deposit','completed'),
(68,NULL,'withdrawal',300,6780,6480,'ATM withdrawal','completed'),
(69,NULL,'deposit',2000,42100,44100,'Cash deposit','completed'),
(70,NULL,'withdrawal',300,9285,8985,'ATM withdrawal','completed'),

(71,NULL,'deposit',1000,11100,12100,'Salary deposit','completed'),
(72,NULL,'withdrawal',400,15480,15080,'ATM withdrawal','completed'),
(73,NULL,'deposit',2500,47150,49650,'Cash deposit','completed'),
(74,NULL,'withdrawal',300,8185,7885,'ATM withdrawal','completed'),
(75,NULL,'deposit',900,8700,9600,'Salary deposit','completed');


INSERT INTO transactions
(account_id, transfer_id, transaction_type, amount, balance_before, balance_after, description, status)
VALUES
(1,NULL,'deposit',500,5000,5500,'Cash deposit','completed'),
(2,NULL,'withdrawal',200,6000,5800,'ATM withdrawal','completed'),
(3,1,'transfer_in',1000,7000,8000,'Transfer received','completed'),
(4,2,'transfer_out',750,9000,8250,'Transfer sent','completed'),
(5,NULL,'deposit',1200,4500,5700,'Salary deposit','completed'),
(6,NULL,'withdrawal',300,8000,7700,'ATM withdrawal','completed'),
(7,3,'transfer_in',1500,5000,6500,'Transfer received','completed'),
(8,4,'transfer_out',600,7500,6900,'Transfer sent','completed'),
(9,NULL,'deposit',900,4000,4900,'Cash deposit','completed'),
(10,NULL,'withdrawal',150,5000,4850,'ATM withdrawal','completed'),

(11,5,'transfer_in',2000,6000,8000,'Transfer received','completed'),
(12,6,'transfer_out',800,9000,8200,'Transfer sent','completed'),
(13,NULL,'deposit',700,3500,4200,'Cash deposit','completed'),
(14,NULL,'withdrawal',250,7000,6750,'ATM withdrawal','completed'),
(15,7,'transfer_in',1100,5000,6100,'Transfer received','completed'),
(16,8,'transfer_out',450,6500,6050,'Transfer sent','completed'),
(17,NULL,'deposit',1300,4200,5500,'Cash deposit','completed'),
(18,NULL,'withdrawal',400,8000,7600,'ATM withdrawal','completed'),
(19,9,'transfer_in',900,3000,3900,'Transfer received','completed'),
(20,10,'transfer_out',350,6000,5650,'Transfer sent','completed'),

(21,NULL,'deposit',600,5000,5600,'Cash deposit','completed'),
(22,NULL,'withdrawal',180,7000,6820,'ATM withdrawal','completed'),
(23,11,'transfer_in',1250,4500,5750,'Transfer received','completed'),
(24,12,'transfer_out',550,8000,7450,'Transfer sent','completed'),
(25,NULL,'deposit',1000,6000,7000,'Salary deposit','completed'),
(26,NULL,'withdrawal',220,5000,4780,'ATM withdrawal','completed'),
(27,13,'transfer_in',1600,7000,8600,'Transfer received','completed'),
(28,14,'transfer_out',700,9000,8300,'Transfer sent','completed'),
(29,NULL,'deposit',850,3500,4350,'Cash deposit','completed'),
(30,NULL,'withdrawal',300,6000,5700,'ATM withdrawal','completed'),

(31,15,'transfer_in',1400,5000,6400,'Transfer received','completed'),
(32,16,'transfer_out',500,7500,7000,'Transfer sent','completed'),
(33,NULL,'deposit',750,4000,4750,'Cash deposit','completed'),
(34,NULL,'withdrawal',200,5500,5300,'ATM withdrawal','completed'),
(35,17,'transfer_in',1800,6000,7800,'Transfer received','completed'),
(36,18,'transfer_out',900,8500,7600,'Transfer sent','completed'),
(37,NULL,'deposit',1100,4500,5600,'Cash deposit','completed'),
(38,NULL,'withdrawal',350,7000,6650,'ATM withdrawal','completed'),
(39,19,'transfer_in',950,5000,5950,'Transfer received','completed'),
(40,20,'transfer_out',400,6500,6100,'Transfer sent','completed'),

(41,NULL,'deposit',500,3000,3500,'Cash deposit','completed'),
(42,NULL,'withdrawal',150,5000,4850,'ATM withdrawal','completed'),
(43,21,'transfer_in',1300,6000,7300,'Transfer received','completed'),
(44,22,'transfer_out',650,8000,7350,'Transfer sent','completed'),
(45,NULL,'deposit',900,4500,5400,'Cash deposit','completed'),
(46,NULL,'withdrawal',250,7000,6750,'ATM withdrawal','completed'),
(47,23,'transfer_in',1700,5000,6700,'Transfer received','completed'),
(48,24,'transfer_out',800,9000,8200,'Transfer sent','completed'),
(49,NULL,'deposit',1200,3500,4700,'Cash deposit','completed'),
(50,NULL,'withdrawal',300,6000,5700,'ATM withdrawal','completed'),

(51,25,'transfer_in',1000,5000,6000,'Transfer received','completed'),
(52,26,'transfer_out',450,7500,7050,'Transfer sent','completed'),
(53,NULL,'deposit',800,4000,4800,'Cash deposit','completed'),
(54,NULL,'withdrawal',200,5500,5300,'ATM withdrawal','completed'),
(55,27,'transfer_in',1500,6000,7500,'Transfer received','completed'),
(56,28,'transfer_out',700,8500,7800,'Transfer sent','completed'),
(57,NULL,'deposit',950,4500,5450,'Cash deposit','completed'),
(58,NULL,'withdrawal',250,7000,6750,'ATM withdrawal','completed'),
(59,29,'transfer_in',1200,5000,6200,'Transfer received','completed'),
(60,30,'transfer_out',500,6500,6000,'Transfer sent','completed'),

(61,NULL,'deposit',700,3500,4200,'Cash deposit','completed'),
(62,NULL,'withdrawal',180,5000,4820,'ATM withdrawal','completed'),
(63,31,'transfer_in',1600,6000,7600,'Transfer received','completed'),
(64,32,'transfer_out',600,8000,7400,'Transfer sent','completed'),
(65,NULL,'deposit',1000,4500,5500,'Salary deposit','completed'),
(66,NULL,'withdrawal',300,7000,6700,'ATM withdrawal','completed'),
(67,33,'transfer_in',1400,5000,6400,'Transfer received','completed'),
(68,34,'transfer_out',750,9000,8250,'Transfer sent','completed'),
(69,NULL,'deposit',850,4000,4850,'Cash deposit','completed'),
(70,NULL,'withdrawal',200,6000,5800,'ATM withdrawal','completed'),

(71,35,'transfer_in',1100,5000,6100,'Transfer received','completed'),
(72,36,'transfer_out',400,7500,7100,'Transfer sent','completed'),
(73,NULL,'deposit',1300,3500,4800,'Cash deposit','completed'),
(74,NULL,'withdrawal',250,7000,6750,'ATM withdrawal','completed'),
(75,37,'transfer_in',1800,6000,7800,'Transfer received','completed'),

(1,38,'transfer_out',850,8500,7650,'Transfer sent','completed'),
(2,NULL,'deposit',900,4500,5400,'Cash deposit','completed'),
(3,NULL,'withdrawal',350,7000,6650,'ATM withdrawal','completed'),
(4,39,'transfer_in',1250,5000,6250,'Transfer received','completed'),
(5,40,'transfer_out',550,6500,5950,'Transfer sent','completed'),

(6,NULL,'deposit',600,3000,3600,'Cash deposit','completed'),
(7,NULL,'withdrawal',150,5000,4850,'ATM withdrawal','completed'),
(8,41,'transfer_in',1450,6000,7450,'Transfer received','completed'),
(9,42,'transfer_out',650,8000,7350,'Transfer sent','completed'),
(10,NULL,'deposit',1050,4500,5550,'Cash deposit','completed'),

(11,NULL,'withdrawal',280,7000,6720,'ATM withdrawal','completed'),
(12,43,'transfer_in',1700,5000,6700,'Transfer received','completed'),
(13,44,'transfer_out',750,9000,8250,'Transfer sent','completed'),
(14,NULL,'deposit',800,3500,4300,'Cash deposit','completed'),
(15,NULL,'withdrawal',200,6000,5800,'ATM withdrawal','completed'),

(16,45,'transfer_in',1000,5000,6000,'Transfer received','completed'),
(17,46,'transfer_out',500,7500,7000,'Transfer sent','completed'),
(18,NULL,'deposit',1250,4000,5250,'Cash deposit','completed'),
(19,NULL,'withdrawal',300,7000,6700,'ATM withdrawal','completed'),
(20,47,'transfer_in',1500,6000,7500,'Transfer received','completed'),

(21,48,'transfer_out',800,8500,7700,'Transfer sent','completed'),
(22,NULL,'deposit',950,4500,5450,'Cash deposit','completed'),
(23,NULL,'withdrawal',250,7000,6750,'ATM withdrawal','completed'),
(24,49,'transfer_in',1200,5000,6200,'Transfer received','completed'),
(25,50,'transfer_out',600,6500,5900,'Transfer sent','completed');


/* four */

-- =========================================
-- CARDS (60)
-- =========================================

INSERT INTO cards
(account_id, card_number, card_type, issued_at, expiry_date, daily_limit, status)
VALUES
(1,'4000000000000001','debit','2023-01-10','2027-01-10',5000,'active'),
(2,'4000000000000002','credit','2023-02-15','2027-02-15',10000,'active'),
(3,'4000000000000003','debit','2023-03-20','2027-03-20',4000,'active'),
(4,'4000000000000004','debit','2023-04-05','2027-04-05',5000,'blocked'),
(5,'4000000000000005','credit','2023-05-12','2027-05-12',15000,'active'),
(6,'4000000000000006','debit','2023-06-18','2027-06-18',6000,'active'),
(7,'4000000000000007','debit','2023-07-22','2027-07-22',5000,'expired'),
(8,'4000000000000008','credit','2023-08-14','2027-08-14',12000,'active'),
(9,'4000000000000009','debit','2023-09-01','2027-09-01',7000,'active'),
(10,'4000000000000010','debit','2023-09-15','2027-09-15',4000,'cancelled'),

(11,'4000000000000011','credit','2023-10-01','2027-10-01',10000,'active'),
(12,'4000000000000012','debit','2023-10-10','2027-10-10',5000,'active'),
(13,'4000000000000013','debit','2023-10-20','2027-10-20',6000,'active'),
(14,'4000000000000014','credit','2023-11-01','2027-11-01',15000,'blocked'),
(15,'4000000000000015','debit','2023-11-12','2027-11-12',5000,'active'),
(16,'4000000000000016','credit','2023-11-20','2027-11-20',12000,'active'),
(17,'4000000000000017','debit','2023-12-01','2027-12-01',4000,'expired'),
(18,'4000000000000018','debit','2023-12-10','2027-12-10',5000,'active'),
(19,'4000000000000019','credit','2023-12-20','2027-12-20',15000,'active'),
(20,'4000000000000020','debit','2024-01-05','2028-01-05',6000,'active'),

(21,'4000000000000021','debit','2024-01-10','2028-01-10',5000,'active'),
(22,'4000000000000022','credit','2024-01-15','2028-01-15',12000,'active'),
(23,'4000000000000023','debit','2024-01-20','2028-01-20',4000,'blocked'),
(24,'4000000000000024','debit','2024-02-01','2028-02-01',7000,'active'),
(25,'4000000000000025','credit','2024-02-05','2028-02-05',15000,'active'),
(26,'4000000000000026','debit','2024-02-10','2028-02-10',5000,'expired'),
(27,'4000000000000027','debit','2024-02-15','2028-02-15',6000,'active'),
(28,'4000000000000028','credit','2024-02-20','2028-02-20',10000,'active'),
(29,'4000000000000029','debit','2024-03-01','2028-03-01',5000,'active'),
(30,'4000000000000030','credit','2024-03-05','2028-03-05',12000,'cancelled'),

(31,'4000000000000031','debit','2024-03-10','2028-03-10',4000,'active'),
(32,'4000000000000032','debit','2024-03-15','2028-03-15',5000,'active'),
(33,'4000000000000033','credit','2024-03-20','2028-03-20',15000,'blocked'),
(34,'4000000000000034','debit','2024-04-01','2028-04-01',6000,'active'),
(35,'4000000000000035','debit','2024-04-05','2028-04-05',5000,'active'),
(36,'4000000000000036','credit','2024-04-10','2028-04-10',10000,'expired'),
(37,'4000000000000037','debit','2024-04-15','2028-04-15',7000,'active'),
(38,'4000000000000038','credit','2024-04-20','2028-04-20',12000,'active'),
(39,'4000000000000039','debit','2024-05-01','2028-05-01',5000,'active'),
(40,'4000000000000040','debit','2024-05-05','2028-05-05',4000,'active'),

(41,'4000000000000041','credit','2024-05-10','2028-05-10',15000,'active'),
(42,'4000000000000042','debit','2024-05-15','2028-05-15',6000,'blocked'),
(43,'4000000000000043','debit','2024-05-20','2028-05-20',5000,'active'),
(44,'4000000000000044','credit','2024-06-01','2028-06-01',10000,'active'),
(45,'4000000000000045','debit','2024-06-05','2028-06-05',7000,'expired'),
(46,'4000000000000046','debit','2024-06-10','2028-06-10',5000,'active'),
(47,'4000000000000047','credit','2024-06-15','2028-06-15',15000,'active'),
(48,'4000000000000048','debit','2024-06-20','2028-06-20',4000,'cancelled'),
(49,'4000000000000049','debit','2024-07-01','2028-07-01',6000,'active'),
(50,'4000000000000050','credit','2024-07-05','2028-07-05',12000,'active'),

(51,'4000000000000051','debit','2024-07-10','2028-07-10',5000,'active'),
(52,'4000000000000052','credit','2024-07-15','2028-07-15',15000,'active'),
(53,'4000000000000053','debit','2024-07-20','2028-07-20',4000,'blocked'),
(54,'4000000000000054','debit','2024-08-01','2028-08-01',6000,'active'),
(55,'4000000000000055','credit','2024-08-05','2028-08-05',10000,'active'),
(56,'4000000000000056','debit','2024-08-10','2028-08-10',5000,'expired'),
(57,'4000000000000057','debit','2024-08-15','2028-08-15',7000,'active'),
(58,'4000000000000058','credit','2024-08-20','2028-08-20',12000,'active'),
(59,'4000000000000059','debit','2024-09-01','2028-09-01',5000,'active'),
(60,'4000000000000060','credit','2024-09-05','2028-09-05',15000,'active');


-- =========================================
-- CARD TRANSACTIONS (120)
-- =========================================

INSERT INTO card_transactions
(card_id, amount, merchant_name, transaction_type, transaction_date, status)
VALUES
(1,120.50,'Carrefour','purchase','2024-01-05 10:15:00','approved'),
(2,850.00,'Amazon','online_purchase','2024-01-06 11:20:00','approved'),
(3,75.00,'Starbucks','purchase','2024-01-07 09:10:00','approved'),
(4,250.00,'Uber','transport','2024-01-08 14:30:00','declined'),
(5,1500.00,'Noon','online_purchase','2024-01-09 16:45:00','approved'),
(6,320.00,'Lulu Market','purchase','2024-01-10 18:20:00','approved'),
(7,90.00,'McDonalds','purchase','2024-01-11 13:15:00','refunded'),
(8,2100.00,'Booking','hotel','2024-01-12 20:30:00','approved'),
(9,450.00,'IKEA','purchase','2024-01-13 12:00:00','approved'),
(10,130.00,'Uber Eats','food_delivery','2024-01-14 19:10:00','declined'),

(11,600.00,'Carrefour','purchase','2024-01-15 10:30:00','approved'),
(12,220.00,'Careem','transport','2024-01-16 15:20:00','approved'),
(13,95.00,'Starbucks','purchase','2024-01-17 09:45:00','approved'),
(14,1800.00,'Amazon','online_purchase','2024-01-18 17:30:00','declined'),
(15,350.00,'Lulu Market','purchase','2024-01-19 12:40:00','approved'),
(16,1250.00,'Noon','online_purchase','2024-01-20 16:10:00','approved'),
(17,75.00,'McDonalds','purchase','2024-01-21 13:20:00','refunded'),
(18,3000.00,'Booking','hotel','2024-01-22 21:00:00','approved'),
(19,550.00,'IKEA','purchase','2024-01-23 14:15:00','approved'),
(20,160.00,'Uber Eats','food_delivery','2024-01-24 19:45:00','approved'),

(21,430.00,'Carrefour','purchase','2024-02-01 11:00:00','approved'),
(22,900.00,'Amazon','online_purchase','2024-02-02 16:30:00','approved'),
(23,120.00,'Starbucks','purchase','2024-02-03 09:30:00','declined'),
(24,300.00,'Uber','transport','2024-02-04 15:20:00','approved'),
(25,1700.00,'Noon','online_purchase','2024-02-05 18:10:00','approved'),
(26,280.00,'Lulu Market','purchase','2024-02-06 12:50:00','refunded'),
(27,110.00,'McDonalds','purchase','2024-02-07 13:30:00','approved'),
(28,2500.00,'Booking','hotel','2024-02-08 20:45:00','approved'),
(29,700.00,'IKEA','purchase','2024-02-09 14:10:00','approved'),
(30,200.00,'Uber Eats','food_delivery','2024-02-10 19:20:00','declined'),

(31,520.00,'Carrefour','purchase','2024-02-11 10:20:00','approved'),
(32,1050.00,'Amazon','online_purchase','2024-02-12 17:00:00','approved'),
(33,80.00,'Starbucks','purchase','2024-02-13 09:15:00','approved'),
(34,275.00,'Careem','transport','2024-02-14 15:45:00','approved'),
(35,1900.00,'Noon','online_purchase','2024-02-15 18:30:00','declined'),
(36,360.00,'Lulu Market','purchase','2024-02-16 12:00:00','approved'),
(37,95.00,'McDonalds','purchase','2024-02-17 13:40:00','refunded'),
(38,2800.00,'Booking','hotel','2024-02-18 21:15:00','approved'),
(39,480.00,'IKEA','purchase','2024-02-19 14:40:00','approved'),
(40,145.00,'Uber Eats','food_delivery','2024-02-20 20:00:00','approved'),

(41,610.00,'Carrefour','purchase','2024-03-01 10:10:00','approved'),
(42,780.00,'Amazon','online_purchase','2024-03-02 16:20:00','approved'),
(43,105.00,'Starbucks','purchase','2024-03-03 09:40:00','declined'),
(44,330.00,'Uber','transport','2024-03-04 15:10:00','approved'),
(45,2200.00,'Noon','online_purchase','2024-03-05 18:50:00','approved'),
(46,290.00,'Lulu Market','purchase','2024-03-06 12:30:00','approved'),
(47,125.00,'McDonalds','purchase','2024-03-07 13:10:00','refunded'),
(48,3200.00,'Booking','hotel','2024-03-08 21:30:00','approved'),
(49,620.00,'IKEA','purchase','2024-03-09 14:25:00','approved'),
(50,175.00,'Uber Eats','food_delivery','2024-03-10 19:50:00','declined'),

(51,450.00,'Carrefour','purchase','2024-03-11 10:00:00','approved'),
(52,1150.00,'Amazon','online_purchase','2024-03-12 16:40:00','approved'),
(53,90.00,'Starbucks','purchase','2024-03-13 09:25:00','approved'),
(54,240.00,'Careem','transport','2024-03-14 15:00:00','approved'),
(55,1600.00,'Noon','online_purchase','2024-03-15 18:15:00','declined'),
(56,410.00,'Lulu Market','purchase','2024-03-16 12:45:00','approved'),
(57,100.00,'McDonalds','purchase','2024-03-17 13:25:00','refunded'),
(58,2700.00,'Booking','hotel','2024-03-18 20:50:00','approved'),
(59,590.00,'IKEA','purchase','2024-03-19 14:00:00','approved'),
(60,155.00,'Uber Eats','food_delivery','2024-03-20 19:30:00','approved'),

(1,200.00,'Carrefour','purchase','2024-04-01 10:10:00','approved'),
(2,700.00,'Amazon','online_purchase','2024-04-02 16:20:00','approved'),
(3,65.00,'Starbucks','purchase','2024-04-03 09:30:00','approved'),
(4,180.00,'Uber','transport','2024-04-04 15:00:00','declined'),
(5,950.00,'Noon','online_purchase','2024-04-05 18:20:00','approved'),
(6,300.00,'Lulu Market','purchase','2024-04-06 12:40:00','approved'),
(7,80.00,'McDonalds','purchase','2024-04-07 13:30:00','refunded'),
(8,1800.00,'Booking','hotel','2024-04-08 20:45:00','approved'),
(9,500.00,'IKEA','purchase','2024-04-09 14:20:00','approved'),
(10,120.00,'Uber Eats','food_delivery','2024-04-10 19:15:00','declined'),

(11,560.00,'Carrefour','purchase','2024-04-11 10:00:00','approved'),
(12,250.00,'Careem','transport','2024-04-12 15:20:00','approved'),
(13,110.00,'Starbucks','purchase','2024-04-13 09:20:00','approved'),
(14,1400.00,'Amazon','online_purchase','2024-04-14 17:10:00','declined'),
(15,390.00,'Lulu Market','purchase','2024-04-15 12:30:00','approved'),
(16,1000.00,'Noon','online_purchase','2024-04-16 16:30:00','approved'),
(17,90.00,'McDonalds','purchase','2024-04-17 13:20:00','refunded'),
(18,2300.00,'Booking','hotel','2024-04-18 21:10:00','approved'),
(19,430.00,'IKEA','purchase','2024-04-19 14:00:00','approved'),
(20,180.00,'Uber Eats','food_delivery','2024-04-20 19:40:00','approved'),

(21,480.00,'Carrefour','purchase','2024-05-01 10:15:00','approved'),
(22,950.00,'Amazon','online_purchase','2024-05-02 16:45:00','approved'),
(23,70.00,'Starbucks','purchase','2024-05-03 09:10:00','declined'),
(24,280.00,'Uber','transport','2024-05-04 15:30:00','approved'),
(25,1800.00,'Noon','online_purchase','2024-05-05 18:40:00','approved'),
(26,340.00,'Lulu Market','purchase','2024-05-06 12:20:00','refunded'),
(27,115.00,'McDonalds','purchase','2024-05-07 13:50:00','approved'),
(28,2900.00,'Booking','hotel','2024-05-08 21:20:00','approved'),
(29,650.00,'IKEA','purchase','2024-05-09 14:30:00','approved'),
(30,190.00,'Uber Eats','food_delivery','2024-05-10 19:25:00','declined'),

(31,530.00,'Carrefour','purchase','2024-05-11 10:30:00','approved'),
(32,880.00,'Amazon','online_purchase','2024-05-12 16:10:00','approved'),
(33,85.00,'Starbucks','purchase','2024-05-13 09:35:00','approved'),
(34,310.00,'Careem','transport','2024-05-14 15:40:00','approved'),
(35,1750.00,'Noon','online_purchase','2024-05-15 18:25:00','declined'),
(36,375.00,'Lulu Market','purchase','2024-05-16 12:15:00','approved'),
(37,105.00,'McDonalds','purchase','2024-05-17 13:45:00','refunded'),
(38,2600.00,'Booking','hotel','2024-05-18 20:55:00','approved'),
(39,540.00,'IKEA','purchase','2024-05-19 14:35:00','approved'),
(40,165.00,'Uber Eats','food_delivery','2024-05-20 19:55:00','approved');


/* five */

-- =========================================
-- LOANS (25)
-- =========================================

INSERT INTO loans
(customer_id, loan_number, principal_amount, interest_rate,
 total_amount, start_date, end_date, status)
VALUES
(1,'LN0001',20000,5.00,21000,'2024-01-01','2025-12-01','active'),
(2,'LN0002',35000,6.50,37275,'2024-01-15','2026-01-15','active'),
(3,'LN0003',15000,4.50,15675,'2024-02-01','2025-08-01','paid'),
(4,'LN0004',50000,7.00,53500,'2024-02-15','2027-02-15','active'),
(5,'LN0005',10000,5.00,10500,'2024-03-01','2025-03-01','paid'),

(6,'LN0006',25000,6.00,26500,'2024-03-15','2026-03-15','active'),
(7,'LN0007',40000,8.00,43200,'2024-04-01','2027-04-01','active'),
(8,'LN0008',18000,5.50,18990,'2024-04-15','2025-10-15','paid'),
(9,'LN0009',60000,7.50,64500,'2024-05-01','2028-05-01','active'),
(10,'LN0010',12000,4.00,12480,'2024-05-15','2025-05-15','paid'),

(11,'LN0011',30000,6.00,31800,'2024-06-01','2026-06-01','active'),
(12,'LN0012',45000,7.00,48150,'2024-06-15','2027-06-15','active'),
(13,'LN0013',22000,5.50,23210,'2024-07-01','2026-01-01','defaulted'),
(14,'LN0014',55000,8.00,59400,'2024-07-15','2028-07-15','active'),
(15,'LN0015',14000,5.00,14700,'2024-08-01','2025-08-01','paid'),

(16,'LN0016',28000,6.50,29820,'2024-08-15','2026-08-15','active'),
(17,'LN0017',75000,9.00,81750,'2024-09-01','2029-09-01','active'),
(18,'LN0018',16000,4.50,16720,'2024-09-15','2025-09-15','paid'),
(19,'LN0019',38000,7.00,40660,'2024-10-01','2027-10-01','active'),
(20,'LN0020',20000,5.50,21100,'2024-10-15','2026-04-15','cancelled'),

(21,'LN0021',42000,6.00,44520,'2024-11-01','2027-11-01','active'),
(22,'LN0022',18000,5.00,18900,'2024-11-15','2026-05-15','active'),
(23,'LN0023',65000,8.50,70525,'2024-12-01','2029-12-01','pending'),
(24,'LN0024',24000,6.00,25440,'2024-12-15','2026-12-15','active'),
(25,'LN0025',32000,7.50,34400,'2025-01-01','2027-01-01','active');


-- =========================================
-- LOAN INSTALLMENTS (150)
-- 6 installments for each of 25 loans
-- =========================================

INSERT INTO loan_installments
(loan_id, installment_number, due_date, amount, paid_amount, paid_at, status)
VALUES

-- Loan 1
(1,1,'2024-02-01',1750,1750,'2024-02-01 10:00:00','paid'),
(1,2,'2024-03-01',1750,1750,'2024-03-01 10:10:00','paid'),
(1,3,'2024-04-01',1750,1750,'2024-04-01 10:15:00','paid'),
(1,4,'2024-05-01',1750,1000,'2024-05-02 11:00:00','partially_paid'),
(1,5,'2024-06-01',1750,0,NULL,'pending'),
(1,6,'2024-07-01',1750,0,NULL,'pending'),

-- Loan 2
(2,1,'2024-02-15',3100,3100,'2024-02-15 09:00:00','paid'),
(2,2,'2024-03-15',3100,3100,'2024-03-15 09:20:00','paid'),
(2,3,'2024-04-15',3100,3100,'2024-04-15 09:30:00','paid'),
(2,4,'2024-05-15',3100,2000,'2024-05-16 10:00:00','partially_paid'),
(2,5,'2024-06-15',3100,0,NULL,'pending'),
(2,6,'2024-07-15',3100,0,NULL,'pending'),

-- Loan 3
(3,1,'2024-03-01',2612.50,2612.50,'2024-03-01 10:00:00','paid'),
(3,2,'2024-04-01',2612.50,2612.50,'2024-04-01 10:00:00','paid'),
(3,3,'2024-05-01',2612.50,2612.50,'2024-05-01 10:00:00','paid'),
(3,4,'2024-06-01',2612.50,2612.50,'2024-06-01 10:00:00','paid'),
(3,5,'2024-07-01',2612.50,2612.50,'2024-07-01 10:00:00','paid'),
(3,6,'2024-08-01',2612.50,2612.50,'2024-08-01 10:00:00','paid'),

-- Loan 4
(4,1,'2024-03-15',4458.33,4458.33,'2024-03-15 09:00:00','paid'),
(4,2,'2024-04-15',4458.33,4458.33,'2024-04-15 09:00:00','paid'),
(4,3,'2024-05-15',4458.33,3000,'2024-05-16 10:00:00','partially_paid'),
(4,4,'2024-06-15',4458.33,0,NULL,'overdue'),
(4,5,'2024-07-15',4458.33,0,NULL,'pending'),
(4,6,'2024-08-15',4458.33,0,NULL,'pending'),

-- Loan 5
(5,1,'2024-04-01',1750,1750,'2024-04-01 10:00:00','paid'),
(5,2,'2024-05-01',1750,1750,'2024-05-01 10:00:00','paid'),
(5,3,'2024-06-01',1750,1750,'2024-06-01 10:00:00','paid'),
(5,4,'2024-07-01',1750,1750,'2024-07-01 10:00:00','paid'),
(5,5,'2024-08-01',1750,1750,'2024-08-01 10:00:00','paid'),
(5,6,'2024-09-01',1750,1750,'2024-09-01 10:00:00','paid'),

-- Loan 6
(6,1,'2024-04-15',2208.33,2208.33,'2024-04-15 09:00:00','paid'),
(6,2,'2024-05-15',2208.33,2208.33,'2024-05-15 09:00:00','paid'),
(6,3,'2024-06-15',2208.33,2208.33,'2024-06-15 09:00:00','paid'),
(6,4,'2024-07-15',2208.33,1500,'2024-07-16 11:00:00','partially_paid'),
(6,5,'2024-08-15',2208.33,0,NULL,'pending'),
(6,6,'2024-09-15',2208.33,0,NULL,'pending'),

-- Loan 7
(7,1,'2024-05-01',3600,3600,'2024-05-01 10:00:00','paid'),
(7,2,'2024-06-01',3600,3600,'2024-06-01 10:00:00','paid'),
(7,3,'2024-07-01',3600,3600,'2024-07-01 10:00:00','paid'),
(7,4,'2024-08-01',3600,0,NULL,'overdue'),
(7,5,'2024-09-01',3600,0,NULL,'pending'),
(7,6,'2024-10-01',3600,0,NULL,'pending'),

-- Loan 8
(8,1,'2024-05-15',3165,3165,'2024-05-15 09:00:00','paid'),
(8,2,'2024-06-15',3165,3165,'2024-06-15 09:00:00','paid'),
(8,3,'2024-07-15',3165,3165,'2024-07-15 09:00:00','paid'),
(8,4,'2024-08-15',3165,3165,'2024-08-15 09:00:00','paid'),
(8,5,'2024-09-15',3165,3165,'2024-09-15 09:00:00','paid'),
(8,6,'2024-10-15',3165,3165,'2024-10-15 09:00:00','paid'),

-- Loan 9
(9,1,'2024-06-01',5375,5375,'2024-06-01 10:00:00','paid'),
(9,2,'2024-07-01',5375,5375,'2024-07-01 10:00:00','paid'),
(9,3,'2024-08-01',5375,4000,'2024-08-02 10:00:00','partially_paid'),
(9,4,'2024-09-01',5375,0,NULL,'pending'),
(9,5,'2024-10-01',5375,0,NULL,'pending'),
(9,6,'2024-11-01',5375,0,NULL,'pending'),

-- Loan 10
(10,1,'2024-06-15',2080,2080,'2024-06-15 09:00:00','paid'),
(10,2,'2024-07-15',2080,2080,'2024-07-15 09:00:00','paid'),
(10,3,'2024-08-15',2080,2080,'2024-08-15 09:00:00','paid'),
(10,4,'2024-09-15',2080,2080,'2024-09-15 09:00:00','paid'),
(10,5,'2024-10-15',2080,2080,'2024-10-15 09:00:00','paid'),
(10,6,'2024-11-15',2080,2080,'2024-11-15 09:00:00','paid'),

-- Loan 11
(11,1,'2024-07-01',5300,5300,'2024-07-01 10:00:00','paid'),
(11,2,'2024-08-01',5300,5300,'2024-08-01 10:00:00','paid'),
(11,3,'2024-09-01',5300,5300,'2024-09-01 10:00:00','paid'),
(11,4,'2024-10-01',5300,3000,'2024-10-02 11:00:00','partially_paid'),
(11,5,'2024-11-01',5300,0,NULL,'pending'),
(11,6,'2024-12-01',5300,0,NULL,'pending'),

-- Loan 12
(12,1,'2024-07-15',8025,8025,'2024-07-15 09:00:00','paid'),
(12,2,'2024-08-15',8025,8025,'2024-08-15 09:00:00','paid'),
(12,3,'2024-09-15',8025,5000,'2024-09-16 10:00:00','partially_paid'),
(12,4,'2024-10-15',8025,0,NULL,'overdue'),
(12,5,'2024-11-15',8025,0,NULL,'pending'),
(12,6,'2024-12-15',8025,0,NULL,'pending'),

-- Loan 13
(13,1,'2024-08-01',3868.33,3868.33,'2024-08-01 10:00:00','paid'),
(13,2,'2024-09-01',3868.33,3868.33,'2024-09-01 10:00:00','paid'),
(13,3,'2024-10-01',3868.33,1000,'2024-10-03 10:00:00','partially_paid'),
(13,4,'2024-11-01',3868.33,0,NULL,'overdue'),
(13,5,'2024-12-01',3868.33,0,NULL,'overdue'),
(13,6,'2025-01-01',3868.33,0,NULL,'pending'),

-- Loan 14
(14,1,'2024-08-15',9900,9900,'2024-08-15 09:00:00','paid'),
(14,2,'2024-09-15',9900,9900,'2024-09-15 09:00:00','paid'),
(14,3,'2024-10-15',9900,9900,'2024-10-15 09:00:00','paid'),
(14,4,'2024-11-15',9900,5000,'2024-11-16 10:00:00','partially_paid'),
(14,5,'2024-12-15',9900,0,NULL,'pending'),
(14,6,'2025-01-15',9900,0,NULL,'pending'),

-- Loan 15
(15,1,'2024-09-01',2450,2450,'2024-09-01 10:00:00','paid'),
(15,2,'2024-10-01',2450,2450,'2024-10-01 10:00:00','paid'),
(15,3,'2024-11-01',2450,2450,'2024-11-01 10:00:00','paid'),
(15,4,'2024-12-01',2450,2450,'2024-12-01 10:00:00','paid'),
(15,5,'2025-01-01',2450,2450,'2025-01-01 10:00:00','paid'),
(15,6,'2025-02-01',2450,2450,'2025-02-01 10:00:00','paid'),

-- Loan 16
(16,1,'2024-09-15',4970,4970,'2024-09-15 09:00:00','paid'),
(16,2,'2024-10-15',4970,4970,'2024-10-15 09:00:00','paid'),
(16,3,'2024-11-15',4970,3000,'2024-11-16 10:00:00','partially_paid'),
(16,4,'2024-12-15',4970,0,NULL,'pending'),
(16,5,'2025-01-15',4970,0,NULL,'pending'),
(16,6,'2025-02-15',4970,0,NULL,'pending'),

-- Loan 17
(17,1,'2024-10-01',13625,13625,'2024-10-01 10:00:00','paid'),
(17,2,'2024-11-01',13625,13625,'2024-11-01 10:00:00','paid'),
(17,3,'2024-12-01',13625,13625,'2024-12-01 10:00:00','paid'),
(17,4,'2025-01-01',13625,7000,'2025-01-02 10:00:00','partially_paid'),
(17,5,'2025-02-01',13625,0,NULL,'pending'),
(17,6,'2025-03-01',13625,0,NULL,'pending'),

-- Loan 18
(18,1,'2024-10-15',2786.67,2786.67,'2024-10-15 09:00:00','paid'),
(18,2,'2024-11-15',2786.67,2786.67,'2024-11-15 09:00:00','paid'),
(18,3,'2024-12-15',2786.67,2786.67,'2024-12-15 09:00:00','paid'),
(18,4,'2025-01-15',2786.67,2786.67,'2025-01-15 09:00:00','paid'),
(18,5,'2025-02-15',2786.67,2786.67,'2025-02-15 09:00:00','paid'),
(18,6,'2025-03-15',2786.67,2786.67,'2025-03-15 09:00:00','paid'),

-- Loan 19
(19,1,'2024-11-01',6776.67,6776.67,'2024-11-01 10:00:00','paid'),
(19,2,'2024-12-01',6776.67,6776.67,'2024-12-01 10:00:00','paid'),
(19,3,'2025-01-01',6776.67,3000,'2025-01-02 10:00:00','partially_paid'),
(19,4,'2025-02-01',6776.67,0,NULL,'pending'),
(19,5,'2025-03-01',6776.67,0,NULL,'pending'),
(19,6,'2025-04-01',6776.67,0,NULL,'pending'),

-- Loan 20
(20,1,'2024-11-15',3516.67,0,NULL,'overdue'),
(20,2,'2024-12-15',3516.67,0,NULL,'overdue'),
(20,3,'2025-01-15',3516.67,0,NULL,'pending'),
(20,4,'2025-02-15',3516.67,0,NULL,'pending'),
(20,5,'2025-03-15',3516.67,0,NULL,'pending'),
(20,6,'2025-04-15',3516.67,0,NULL,'pending'),

-- Loan 21
(21,1,'2024-12-01',7420,7420,'2024-12-01 10:00:00','paid'),
(21,2,'2025-01-01',7420,7420,'2025-01-01 10:00:00','paid'),
(21,3,'2025-02-01',7420,4000,'2025-02-02 10:00:00','partially_paid'),
(21,4,'2025-03-01',7420,0,NULL,'pending'),
(21,5,'2025-04-01',7420,0,NULL,'pending'),
(21,6,'2025-05-01',7420,0,NULL,'pending'),

-- Loan 22
(22,1,'2024-12-15',3150,3150,'2024-12-15 09:00:00','paid'),
(22,2,'2025-01-15',3150,3150,'2025-01-15 09:00:00','paid'),
(22,3,'2025-02-15',3150,3150,'2025-02-15 09:00:00','paid'),
(22,4,'2025-03-15',3150,1500,'2025-03-16 10:00:00','partially_paid'),
(22,5,'2025-04-15',3150,0,NULL,'pending'),
(22,6,'2025-05-15',3150,0,NULL,'pending'),

-- Loan 23
(23,1,'2025-01-01',11754.17,0,NULL,'pending'),
(23,2,'2025-02-01',11754.17,0,NULL,'pending'),
(23,3,'2025-03-01',11754.17,0,NULL,'pending'),
(23,4,'2025-04-01',11754.17,0,NULL,'pending'),
(23,5,'2025-05-01',11754.17,0,NULL,'pending'),
(23,6,'2025-06-01',11754.17,0,NULL,'pending'),

-- Loan 24
(24,1,'2025-01-15',4240,4240,'2025-01-15 09:00:00','paid'),
(24,2,'2025-02-15',4240,4240,'2025-02-15 09:00:00','paid'),
(24,3,'2025-03-15',4240,2000,'2025-03-16 10:00:00','partially_paid'),
(24,4,'2025-04-15',4240,0,NULL,'pending'),
(24,5,'2025-05-15',4240,0,NULL,'pending'),
(24,6,'2025-06-15',4240,0,NULL,'pending'),

-- Loan 25
(25,1,'2025-02-01',5733.33,5733.33,'2025-02-01 10:00:00','paid'),
(25,2,'2025-03-01',5733.33,5733.33,'2025-03-01 10:00:00','paid'),
(25,3,'2025-04-01',5733.33,5733.33,'2025-04-01 10:00:00','paid'),
(25,4,'2025-05-01',5733.33,3000,'2025-05-02 10:00:00','partially_paid'),
(25,5,'2025-06-01',5733.33,0,NULL,'pending'),
(25,6,'2025-07-01',5733.33,0,NULL,'pending');


/* six & final */

-- =========================================
-- AUDIT LOGS (100)
-- =========================================

INSERT INTO audit_logs
(customer_id, account_id, action_type, table_name, record_id, old_value, new_value, created_at)
VALUES
(1,1,'CREATE','customers',1,NULL,'Customer created','2024-01-01 09:00:00'),
(2,2,'UPDATE','customers',2,'status=inactive','status=active','2024-01-02 10:00:00'),
(3,3,'UPDATE','accounts',3,'balance=5000','balance=7500','2024-01-03 11:00:00'),
(4,4,'CREATE','accounts',4,NULL,'Account created','2024-01-04 12:00:00'),
(5,5,'UPDATE','accounts',5,'status=frozen','status=active','2024-01-05 13:00:00'),
(6,6,'CREATE','beneficiaries',1,NULL,'Beneficiary created','2024-01-06 09:30:00'),
(7,7,'UPDATE','beneficiaries',2,'status=inactive','status=active','2024-01-07 10:30:00'),
(8,8,'CREATE','transfers',1,NULL,'Transfer created','2024-01-08 11:30:00'),
(9,9,'UPDATE','transfers',2,'status=pending','status=completed','2024-01-09 12:30:00'),
(10,10,'UPDATE','transfers',3,'status=processing','status=completed','2024-01-10 13:30:00'),

(11,11,'CREATE','transactions',1,NULL,'Transaction created','2024-01-11 09:00:00'),
(12,12,'UPDATE','transactions',2,'status=pending','status=completed','2024-01-12 10:00:00'),
(13,13,'CREATE','cards',1,NULL,'Card issued','2024-01-13 11:00:00'),
(14,14,'UPDATE','cards',2,'status=blocked','status=active','2024-01-14 12:00:00'),
(15,15,'UPDATE','cards',3,'status=active','status=blocked','2024-01-15 13:00:00'),
(16,16,'CREATE','card_transactions',1,NULL,'Card transaction created','2024-01-16 09:15:00'),
(17,17,'UPDATE','card_transactions',2,'status=pending','status=approved','2024-01-17 10:15:00'),
(18,18,'UPDATE','card_transactions',3,'status=approved','status=refunded','2024-01-18 11:15:00'),
(19,19,'CREATE','loans',1,NULL,'Loan created','2024-01-19 12:15:00'),
(20,20,'UPDATE','loans',2,'status=pending','status=active','2024-01-20 13:15:00'),

(21,21,'UPDATE','loans',3,'status=active','status=paid','2024-01-21 09:00:00'),
(22,22,'CREATE','loan_installments',1,NULL,'Installment created','2024-01-22 10:00:00'),
(23,23,'UPDATE','loan_installments',2,'paid_amount=0','paid_amount=1500','2024-01-23 11:00:00'),
(24,24,'UPDATE','loan_installments',3,'status=pending','status=paid','2024-01-24 12:00:00'),
(25,25,'UPDATE','loan_installments',4,'status=pending','status=overdue','2024-01-25 13:00:00'),

(1,1,'LOGIN','customers',1,NULL,'Successful login','2024-02-01 09:00:00'),
(2,2,'LOGIN','customers',2,NULL,'Successful login','2024-02-01 10:00:00'),
(3,3,'LOGIN_FAILED','customers',3,NULL,'Invalid password','2024-02-01 11:00:00'),
(4,4,'LOGIN','customers',4,NULL,'Successful login','2024-02-01 12:00:00'),
(5,5,'LOGIN_FAILED','customers',5,NULL,'Invalid password','2024-02-01 13:00:00'),
(6,6,'UPDATE','accounts',6,'balance=8000','balance=9200','2024-02-02 09:00:00'),
(7,7,'UPDATE','accounts',7,'status=active','status=frozen','2024-02-02 10:00:00'),
(8,8,'UPDATE','accounts',8,'status=frozen','status=active','2024-02-02 11:00:00'),
(9,9,'CREATE','transfers',10,NULL,'Transfer created','2024-02-02 12:00:00'),
(10,10,'UPDATE','transfers',11,'status=pending','status=failed','2024-02-02 13:00:00'),

(11,11,'CREATE','transactions',10,NULL,'Deposit transaction','2024-02-03 09:00:00'),
(12,12,'CREATE','transactions',11,NULL,'Withdrawal transaction','2024-02-03 10:00:00'),
(13,13,'CREATE','cards',13,NULL,'Card issued','2024-02-03 11:00:00'),
(14,14,'UPDATE','cards',14,'status=active','status=blocked','2024-02-03 12:00:00'),
(15,15,'UPDATE','cards',15,'status=blocked','status=active','2024-02-03 13:00:00'),
(16,16,'CREATE','card_transactions',16,NULL,'Purchase created','2024-02-04 09:00:00'),
(17,17,'UPDATE','card_transactions',17,'status=pending','status=declined','2024-02-04 10:00:00'),
(18,18,'UPDATE','card_transactions',18,'status=approved','status=refunded','2024-02-04 11:00:00'),
(19,19,'CREATE','loans',19,NULL,'Loan application created','2024-02-04 12:00:00'),
(20,20,'UPDATE','loans',20,'status=pending','status=cancelled','2024-02-04 13:00:00'),

(21,21,'CREATE','loan_installments',21,NULL,'Installment created','2024-02-05 09:00:00'),
(22,22,'UPDATE','loan_installments',22,'paid_amount=0','paid_amount=3000','2024-02-05 10:00:00'),
(23,23,'UPDATE','loan_installments',23,'status=pending','status=partially_paid','2024-02-05 11:00:00'),
(24,24,'UPDATE','loan_installments',24,'status=pending','status=overdue','2024-02-05 12:00:00'),
(25,25,'UPDATE','loan_installments',25,'status=partially_paid','status=paid','2024-02-05 13:00:00'),

(1,1,'UPDATE','customers',1,'city=Riyadh','city=Jeddah','2024-02-06 09:00:00'),
(2,2,'UPDATE','customers',2,'status=active','status=blocked','2024-02-06 10:00:00'),
(3,3,'UPDATE','customers',3,'status=blocked','status=active','2024-02-06 11:00:00'),
(4,4,'UPDATE','accounts',4,'currency=SAR','currency=USD','2024-02-06 12:00:00'),
(5,5,'UPDATE','accounts',5,'balance=10000','balance=12500','2024-02-06 13:00:00'),
(6,6,'CREATE','beneficiaries',6,NULL,'Beneficiary created','2024-02-07 09:00:00'),
(7,7,'UPDATE','beneficiaries',7,'status=active','status=inactive','2024-02-07 10:00:00'),
(8,8,'CREATE','transfers',20,NULL,'Transfer created','2024-02-07 11:00:00'),
(9,9,'UPDATE','transfers',21,'status=pending','status=completed','2024-02-07 12:00:00'),
(10,10,'UPDATE','transfers',22,'status=pending','status=cancelled','2024-02-07 13:00:00'),

(11,11,'CREATE','transactions',20,NULL,'Deposit transaction','2024-02-08 09:00:00'),
(12,12,'CREATE','transactions',21,NULL,'Transfer transaction','2024-02-08 10:00:00'),
(13,13,'UPDATE','cards',20,'status=active','status=blocked','2024-02-08 11:00:00'),
(14,14,'UPDATE','cards',21,'status=blocked','status=active','2024-02-08 12:00:00'),
(15,15,'CREATE','card_transactions',25,NULL,'Purchase created','2024-02-08 13:00:00'),
(16,16,'UPDATE','card_transactions',26,'status=pending','status=approved','2024-02-09 09:00:00'),
(17,17,'UPDATE','card_transactions',27,'status=approved','status=refunded','2024-02-09 10:00:00'),
(18,18,'CREATE','loans',21,NULL,'Loan created','2024-02-09 11:00:00'),
(19,19,'UPDATE','loans',22,'status=pending','status=active','2024-02-09 12:00:00'),
(20,20,'UPDATE','loans',23,'status=pending','status=active','2024-02-09 13:00:00'),

(21,21,'CREATE','loan_installments',31,NULL,'Installment created','2024-02-10 09:00:00'),
(22,22,'UPDATE','loan_installments',32,'paid_amount=0','paid_amount=2500','2024-02-10 10:00:00'),
(23,23,'UPDATE','loan_installments',33,'status=pending','status=paid','2024-02-10 11:00:00'),
(24,24,'UPDATE','loan_installments',34,'status=pending','status=overdue','2024-02-10 12:00:00'),
(25,25,'UPDATE','loan_installments',35,'status=partially_paid','status=paid','2024-02-10 13:00:00'),

(1,1,'LOGIN','customers',1,NULL,'Successful login','2024-02-11 09:00:00'),
(2,2,'LOGIN','customers',2,NULL,'Successful login','2024-02-11 10:00:00'),
(3,3,'LOGIN_FAILED','customers',3,NULL,'Invalid password','2024-02-11 11:00:00'),
(4,4,'LOGIN','customers',4,NULL,'Successful login','2024-02-11 12:00:00'),
(5,5,'LOGIN_FAILED','customers',5,NULL,'Invalid password','2024-02-11 13:00:00'),
(6,6,'UPDATE','accounts',16,'balance=7000','balance=9500','2024-02-12 09:00:00'),
(7,7,'UPDATE','accounts',17,'status=active','status=frozen','2024-02-12 10:00:00'),
(8,8,'UPDATE','accounts',18,'status=frozen','status=active','2024-02-12 11:00:00'),
(9,9,'CREATE','transfers',40,NULL,'Transfer created','2024-02-12 12:00:00'),
(10,10,'UPDATE','transfers',41,'status=pending','status=completed','2024-02-12 13:00:00'),

(11,11,'CREATE','transactions',40,NULL,'Deposit transaction','2024-02-13 09:00:00'),
(12,12,'CREATE','transactions',41,NULL,'Withdrawal transaction','2024-02-13 10:00:00'),
(13,13,'UPDATE','cards',30,'status=active','status=cancelled','2024-02-13 11:00:00'),
(14,14,'UPDATE','cards',31,'status=blocked','status=active','2024-02-13 12:00:00'),
(15,15,'CREATE','card_transactions',50,NULL,'Purchase created','2024-02-13 13:00:00'),
(16,16,'UPDATE','card_transactions',51,'status=pending','status=approved','2024-02-14 09:00:00'),
(17,17,'UPDATE','card_transactions',52,'status=approved','status=refunded','2024-02-14 10:00:00'),
(18,18,'CREATE','loans',24,NULL,'Loan created','2024-02-14 11:00:00'),
(19,19,'UPDATE','loans',24,'status=pending','status=active','2024-02-14 12:00:00'),
(20,20,'UPDATE','loans',25,'status=pending','status=active','2024-02-14 13:00:00');



-- 2. العملاء الذين لديهم أكثر من حساب
SELECT c.full_name, COUNT(a.id) AS accounts
FROM customers c
JOIN accounts a ON c.id = a.customer_id
GROUP BY c.id
HAVING COUNT(a.id) > 1;

-- 3. العملاء الذين لديهم أكثر من عملة
SELECT c.full_name, COUNT(DISTINCT a.currency) AS currencies
FROM customers c
JOIN accounts a ON c.id = a.customer_id
GROUP BY c.id
HAVING COUNT(DISTINCT a.currency) > 1;

-- 4. إجمالي الرصيد لكل عميل
SELECT c.full_name, SUM(a.balance) AS total_balance
FROM customers c
JOIN accounts a ON c.id = a.customer_id
GROUP BY c.id;

-- 5. الحسابات التي لم تنفذ أي حركة
SELECT a.account_number
FROM accounts a
LEFT JOIN transactions t ON a.id = t.account_id
WHERE t.id IS NULL;

-- Transactions
-- 6. عدد Transactions لكل حساب
SELECT account_id, COUNT(*) AS transaction_count
FROM transactions
GROUP BY account_id;

-- 7. الحسابات التي لديها أكثر من 20 Transaction
SELECT account_id, COUNT(*) AS transaction_count
FROM transactions
GROUP BY account_id
HAVING COUNT(*) > 20;

-- 8. إجمالي Deposits لكل حساب
SELECT account_id, SUM(amount) AS total_deposits
FROM transactions
WHERE transaction_type = 'deposit'
GROUP BY account_id;

-- 9. إجمالي Withdrawals لكل حساب
SELECT account_id, SUM(amount) AS total_withdrawals
FROM transactions
WHERE transaction_type = 'withdrawal'
GROUP BY account_id;

-- 10. الفرق بين Deposits و Withdrawals
SELECT account_id,
SUM(CASE WHEN transaction_type = 'deposit' THEN amount ELSE 0 END)
-
SUM(CASE WHEN transaction_type = 'withdrawal' THEN amount ELSE 0 END)
AS difference
FROM transactions
GROUP BY account_id;

-- 11. أعلى 10 حسابات من حيث الحركة
SELECT account_id, SUM(amount) AS total
FROM transactions
GROUP BY account_id
ORDER BY total DESC
LIMIT 10;

-- 12. التحويلات الفاشلة
SELECT *
FROM transfers
WHERE status = 'failed';

-- 13. التحويلات Pending
SELECT *
FROM transfers
WHERE status = 'pending';

-- 14. متوسط قيمة التحويل
SELECT AVG(amount) AS average_transfer
FROM transfers;

-- 15. التحويلات الأعلى من المتوسط
SELECT *
FROM transfers
WHERE amount > (SELECT AVG(amount) FROM transfers);

-- الفروع
-- 16. عدد الحسابات في كل فرع
SELECT branch_id, COUNT(*) AS accounts
FROM accounts
GROUP BY branch_id;

-- 17. إجمالي أرصدة كل فرع
SELECT branch_id, SUM(balance) AS total_balance
FROM accounts
GROUP BY branch_id;

-- 18. متوسط رصيد كل فرع
SELECT branch_id, AVG(balance) AS average_balance
FROM accounts
GROUP BY branch_id;

-- البطاقات
-- 19. البطاقات التي ستنتهي خلال 60 يوم
SELECT *
FROM cards
WHERE expiry_date <= CURDATE() + INTERVAL 60 DAY;

-- 20. البطاقات التي لم تستخدم
SELECT c.*
FROM cards c
LEFT JOIN card_transactions ct ON c.id = ct.card_id
WHERE ct.id IS NULL;

-- 21. إجمالي استخدام كل بطاقة
SELECT card_id, SUM(amount) AS total_used
FROM card_transactions
WHERE status = 'approved'
GROUP BY card_id;

-- 22. أكثر Merchant
SELECT merchant_name, COUNT(*) AS purchases
FROM card_transactions
GROUP BY merchant_name
ORDER BY purchases DESC
LIMIT 1;

-- القروض
-- 23. القروض النشطة
SELECT *
FROM loans
WHERE status = 'active';

-- 24. إجمالي القروض لكل عميل
SELECT customer_id, SUM(total_amount) AS total_loans
FROM loans
GROUP BY customer_id;

-- 25. الأقساط المتأخرة
SELECT *
FROM loan_installments
WHERE status = 'overdue';

-- 26. عدد الأقساط المتأخرة لكل عميل
SELECT l.customer_id, COUNT(*) AS overdue
FROM loans l
JOIN loan_installments li ON l.id = li.loan_id
WHERE li.status = 'overdue'
GROUP BY l.customer_id;

-- 27. المبلغ المتبقي لكل قرض
SELECT l.loan_number,
       l.total_amount - SUM(li.paid_amount) AS remaining
FROM loans l
JOIN loan_installments li ON l.id = li.loan_id
GROUP BY l.id;

-- 28. نسبة الدفع لكل قرض
SELECT l.loan_number,
       SUM(li.paid_amount) / l.total_amount * 100 AS paid_percent
FROM loans l
JOIN loan_installments li ON l.id = li.loan_id
GROUP BY l.id;

-- 29. أكثر شهر تم فيه منح قروض
SELECT MONTH(start_date) AS month, COUNT(*) AS loans
FROM loans
GROUP BY MONTH(start_date)
ORDER BY loans DESC
LIMIT 1;

-- 30. إجمالي الفوائد المتوقعة
SELECT SUM(total_amount - principal_amount) AS total_interest
FROM loans;

-- 31. آخر Transaction لكل حساب
SELECT account_id, MAX(created_at) AS last_transaction
FROM transactions
GROUP BY account_id;

-- 32. أول Transaction لكل حساب
SELECT account_id, MIN(created_at) AS first_transaction
FROM transactions
GROUP BY account_id;

-- 33. الحسابات التي لم تتحرك خلال آخر 90 يوم
SELECT account_id, MAX(created_at) AS last_transaction
FROM transactions
GROUP BY account_id
HAVING MAX(created_at) < CURRENT_DATE - INTERVAL 90 DAY;

-- 34. إجمالي التحويلات لكل شهر
SELECT MONTH(created_at) AS month,
       SUM(amount) AS total
FROM transfers
GROUP BY MONTH(created_at);

-- 35. العملاء الذين يحولون لأكثر من 5 حسابات مختلفة
SELECT a.customer_id,
       COUNT(DISTINCT t.to_account_id) AS accounts
FROM accounts a
JOIN transfers t ON a.id = t.from_account_id
GROUP BY a.customer_id
HAVING COUNT(DISTINCT t.to_account_id) > 5;

-- 36. أكثر حساب استقبل تحويلات
SELECT to_account_id, COUNT(*) AS received
FROM transfers
WHERE status = 'completed'
GROUP BY to_account_id
ORDER BY received DESC
LIMIT 1;

-- 37. أكثر حساب أرسل تحويلات
SELECT from_account_id, COUNT(*) AS sent
FROM transfers
WHERE status = 'completed'
GROUP BY from_account_id
ORDER BY sent DESC
LIMIT 1;

-- الفروع
-- 38. الحسابات التي رصيدها أعلى من متوسط فرعها
SELECT a.account_number, a.branch_id, a.balance
FROM accounts a
WHERE a.balance >
(
    SELECT AVG(a2.balance)
    FROM accounts a2
    WHERE a2.branch_id = a.branch_id
);

-- البطاقات
-- 39. العملاء الذين لديهم أكثر من بطاقة
SELECT a.customer_id, COUNT(c.id) AS cards
FROM accounts a
JOIN cards c ON a.id = c.account_id
GROUP BY a.customer_id
HAVING COUNT(c.id) > 1;

-- 40. البطاقات التي تجاوزت daily_limit
SELECT c.id, c.card_number, c.daily_limit,
       SUM(ct.amount) AS total_used
FROM cards c
JOIN card_transactions ct ON c.id = ct.card_id
WHERE ct.status = 'approved'
GROUP BY c.id
HAVING SUM(ct.amount) > c.daily_limit;

-- القروض
-- 41. العملاء الذين لديهم أكثر من 3 أقساط متأخرة
SELECT l.customer_id, COUNT(*) AS overdue
FROM loans l
JOIN loan_installments li ON l.id = li.loan_id
WHERE li.status = 'overdue'
GROUP BY l.customer_id
HAVING COUNT(*) > 3;

-- 42. العملاء الذين سددوا جميع قروضهم
SELECT customer_id
FROM loans
GROUP BY customer_id
HAVING SUM(status <> 'paid') = 0;

-- 43. العملاء الذين لديهم قرض بدون أي دفعة
SELECT l.customer_id
FROM loans l
JOIN loan_installments li ON l.id = li.loan_id
GROUP BY l.id, l.customer_id
HAVING SUM(li.paid_amount) = 0;

-- 44. إجمالي الفوائد لكل قرض
SELECT loan_number,
       total_amount - principal_amount AS interest
FROM loans;

-- 45. إجمالي الفوائد لجميع القروض
SELECT SUM(total_amount - principal_amount) AS total_interest
FROM loans;

-- 46. القروض حسب الحالة
SELECT status, COUNT(*) AS loan_count
FROM loans
GROUP BY status;

-- 47. الأقساط حسب الحالة
SELECT status, COUNT(*) AS installment_count
FROM loan_installments
GROUP BY status;

-- 48. إجمالي المبالغ المدفوعة لكل قرض
SELECT loan_id, SUM(paid_amount) AS paid
FROM loan_installments
GROUP BY loan_id;

-- 49. القروض التي لم يُدفع منها شيء
SELECT l.loan_number
FROM loans l
JOIN loan_installments li ON l.id = li.loan_id
GROUP BY l.id
HAVING SUM(li.paid_amount) = 0;

-- 50. إجمالي قيمة القروض
SELECT SUM(total_amount) AS total_loans
FROM loans;



/*customer_financial_summary view*/
DROP VIEW IF EXISTS customer_financial_summary;

CREATE VIEW customer_financial_summary AS
SELECT
    c.id AS customer,
    c.customer_number,
    c.full_name,

    COALESCE(a.number_of_accounts, 0) AS number_of_accounts,
    COALESCE(a.total_balance, 0) AS total_balance,

    COALESCE(s.transfers_sent, 0) AS total_transfers_sent,
    COALESCE(s.sent_amount, 0) AS total_sent_amount,

    COALESCE(r.transfers_received, 0) AS total_transfers_received,
    COALESCE(r.received_amount, 0) AS total_received_amount,

    COALESCE(l.total_loans, 0) AS total_loans,
    COALESCE(l.total_loan_amount, 0) AS total_loan_amount,

    t.last_transaction

FROM customers c

LEFT JOIN
(
    SELECT
        customer_id,
        COUNT(*) AS number_of_accounts,
        SUM(balance) AS total_balance
    FROM accounts
    GROUP BY customer_id
) a
ON c.id = a.customer_id

LEFT JOIN
(
    SELECT
        a.customer_id,
        COUNT(t.id) AS transfers_sent,
        SUM(t.amount) AS sent_amount
    FROM accounts a
    JOIN transfers t
        ON t.from_account_id = a.id
    WHERE t.status = 'completed'
    GROUP BY a.customer_id
) s
ON c.id = s.customer_id

LEFT JOIN
(
    SELECT
        a.customer_id,
        COUNT(t.id) AS transfers_received,
        SUM(t.amount) AS received_amount
    FROM accounts a
    JOIN transfers t
        ON t.to_account_id = a.id
    WHERE t.status = 'completed'
    GROUP BY a.customer_id
) r
ON c.id = r.customer_id

LEFT JOIN
(
    SELECT
        customer_id,
        COUNT(*) AS total_loans,
        SUM(total_amount) AS total_loan_amount
    FROM loans
    GROUP BY customer_id
) l
ON c.id = l.customer_id

LEFT JOIN
(
    SELECT
        a.customer_id,
        MAX(t.created_at) AS last_transaction
    FROM accounts a
    JOIN transactions t
        ON t.account_id = a.id
    GROUP BY a.customer_id
) t
ON c.id = t.customer_id;

/*account_activity_view*/

DROP VIEW IF EXISTS account_activity_view;

CREATE VIEW account_activity_view AS
SELECT
    a.id AS account,
    a.account_number,
    a.customer_id AS customer,
    a.balance,

    COALESCE(
        SUM(
            CASE
                WHEN t.transaction_type = 'deposit'
                THEN t.amount
                ELSE 0
            END
        ), 0
    ) AS deposits,

    COALESCE(
        SUM(
            CASE
                WHEN t.transaction_type = 'withdrawal'
                THEN t.amount
                ELSE 0
            END
        ), 0
    ) AS withdrawals,

    COUNT(t.id) AS transaction_count,
    MAX(t.created_at) AS last_transaction

FROM accounts a
LEFT JOIN transactions t
    ON a.id = t.account_id
GROUP BY
    a.id,
    a.account_number,
    a.customer_id,
    a.balance;


/*loan_status_view*/

USE banking_system;

DROP VIEW IF EXISTS loan_status_view;

CREATE VIEW loan_status_view AS
SELECT
    l.id AS loan,
    l.loan_number,
    l.customer_id AS customer,
    l.principal_amount AS principal,
    l.total_amount,

    COALESCE(SUM(li.paid_amount), 0) AS paid_amount,

    l.total_amount
        - COALESCE(SUM(li.paid_amount), 0)
        AS remaining_amount,

    COUNT(li.id) AS total_installments,

    COALESCE(
        SUM(
            CASE
                WHEN li.status = 'overdue'
                THEN 1
                ELSE 0
            END
        ), 0
    ) AS overdue_installments

FROM loans l
LEFT JOIN loan_installments li
    ON l.id = li.loan_id

GROUP BY
    l.id,
    l.loan_number,
    l.customer_id,
    l.principal_amount,
    l.total_amount;

-- ========================================
/*deposit_money procedure*/
USE banking_system;

DROP PROCEDURE IF EXISTS deposit_money;

DELIMITER //

CREATE PROCEDURE deposit_money(
    IN acc_id INT,
    IN money DECIMAL(15,2)
)
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_before DECIMAL(15,2);
    DECLARE v_after DECIMAL(15,2);
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF money <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deposit amount must be greater than zero';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM accounts
    WHERE id = acc_id;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account does not exist';
    END IF;

    START TRANSACTION;

    SELECT balance, status
    INTO v_before, v_status
    FROM accounts
    WHERE id = acc_id
    FOR UPDATE;

    IF v_status <> 'active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account is not active';
    END IF;

    SET v_after = v_before + money;

    UPDATE accounts
    SET balance = v_after
    WHERE id = acc_id;

    INSERT INTO transactions
    (
        account_id,
        transfer_id,
        transaction_type,
        amount,
        balance_before,
        balance_after,
        description,
        status
    )
    VALUES
    (
        acc_id,
        NULL,
        'deposit',
        money,
        v_before,
        v_after,
        'Deposit',
        'completed'
    );

    COMMIT;
END //

DELIMITER ;

/*run deposit_money procedure*/
CALL deposit_money(1, 500);

-- ====================================
/*withdraw_money procedure*/
DROP PROCEDURE IF EXISTS withdraw_money;

DELIMITER //

CREATE PROCEDURE withdraw_money(
    IN acc_id INT,
    IN money DECIMAL(15,2)
)
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_before DECIMAL(15,2);
    DECLARE v_after DECIMAL(15,2);
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF money <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Withdrawal amount must be greater than zero';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM accounts
    WHERE id = acc_id;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account does not exist';
    END IF;

    START TRANSACTION;

    SELECT balance, status
    INTO v_before, v_status
    FROM accounts
    WHERE id = acc_id
    FOR UPDATE;

    IF v_status <> 'active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Account is not active';
    END IF;

    IF v_before < money THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;

    SET v_after = v_before - money;

    UPDATE accounts
    SET balance = v_after
    WHERE id = acc_id;

    INSERT INTO transactions
    (
        account_id,
        transfer_id,
        transaction_type,
        amount,
        balance_before,
        balance_after,
        description,
        status
    )
    VALUES
    (
        acc_id,
        NULL,
        'withdrawal',
        money,
        v_before,
        v_after,
        'Withdrawal',
        'completed'
    );

    COMMIT;
END //

DELIMITER ;
/*run withdraw_money procedure*/
CALL withdraw_money(1, 200);

-- ======================================
/*pay_loan_installment procedure*/
DROP PROCEDURE IF EXISTS pay_loan_installment;

DELIMITER //

CREATE PROCEDURE pay_loan_installment(
    IN inst_id INT,
    IN money DECIMAL(15,2)
)
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_amount DECIMAL(15,2);
    DECLARE v_paid DECIMAL(15,2);
    DECLARE v_due_date DATE;
    DECLARE v_new_paid DECIMAL(15,2);
    DECLARE v_new_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF money <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment amount must be greater than zero';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM loan_installments
    WHERE id = inst_id;

    IF v_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Installment does not exist';
    END IF;

    START TRANSACTION;

    SELECT amount, paid_amount, due_date
    INTO v_amount, v_paid, v_due_date
    FROM loan_installments
    WHERE id = inst_id
    FOR UPDATE;

    IF v_paid >= v_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Installment is already fully paid';
    END IF;

    IF v_paid + money > v_amount THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Payment exceeds installment amount';
    END IF;

    SET v_new_paid = v_paid + money;

    IF v_new_paid = v_amount THEN
        SET v_new_status = 'paid';
    ELSEIF v_due_date < CURDATE() THEN
        SET v_new_status = 'overdue';
    ELSE
        SET v_new_status = 'partially_paid';
    END IF;

    UPDATE loan_installments
    SET
        paid_amount = v_new_paid,
        paid_at = NOW(),
        status = v_new_status
    WHERE id = inst_id;

    COMMIT;
END //

DELIMITER ;
/*run pay_loan_installment procedure*/
CALL pay_loan_installment(1, 500);

-- =============================
/*block_account procedure*/

DELIMITER //

CREATE PROCEDURE block_account(
IN acc_id INT
)
BEGIN

UPDATE accounts
SET status = 'frozen'
WHERE id = acc_id;

END //

DELIMITER ;

/*run block_account procedure*/
CALL block_account(1);

-- ====================================
/*transfer transaction*/

ALTER TABLE transfers
ADD COLUMN idempotency_key VARCHAR(100) NULL
AFTER reference_number;

ALTER TABLE transfers
ADD CONSTRAINT uq_transfers_idempotency_key
UNIQUE (idempotency_key);

-- ====================================
/*Transfer Money Core*/

DROP PROCEDURE IF EXISTS transfer_money_core;

DELIMITER //

CREATE PROCEDURE transfer_money_core(
    IN p_request_id VARCHAR(100),
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2),
    IN p_description VARCHAR(255)
)
main_block:
BEGIN
    DECLARE v_count INT DEFAULT 0;
    DECLARE v_existing_id INT DEFAULT 0;

    DECLARE v_from_balance DECIMAL(15,2);
    DECLARE v_to_balance DECIMAL(15,2);

    DECLARE v_from_currency VARCHAR(3);
    DECLARE v_to_currency VARCHAR(3);

    DECLARE v_from_status VARCHAR(20);
    DECLARE v_to_status VARCHAR(20);

    DECLARE v_from_after DECIMAL(15,2);
    DECLARE v_to_after DECIMAL(15,2);

    DECLARE v_fee DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_reference VARCHAR(50);
    DECLARE v_request VARCHAR(100);

    DECLARE v_existing_from INT;
    DECLARE v_existing_to INT;
    DECLARE v_existing_amount DECIMAL(15,2);
    DECLARE v_existing_description VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_from_account = p_to_account THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Source and destination accounts must differ';
    END IF;

    IF p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transfer amount must be greater than zero';
    END IF;

    SET v_request = COALESCE(
        NULLIF(TRIM(p_request_id), ''),
        UUID()
    );

    START TRANSACTION;

    /* =========================================
       IDEMPOTENCY CHECK
       ========================================= */

    SELECT COALESCE(MAX(id), 0)
    INTO v_existing_id
    FROM transfers
    WHERE idempotency_key = v_request;

    IF v_existing_id > 0 THEN

        SELECT
            from_account_id,
            to_account_id,
            amount,
            description
        INTO
            v_existing_from,
            v_existing_to,
            v_existing_amount,
            v_existing_description
        FROM transfers
        WHERE id = v_existing_id;

        IF v_existing_from <> p_from_account
           OR v_existing_to <> p_to_account
           OR v_existing_amount <> p_amount
           OR NOT (v_existing_description <=> p_description)
        THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Idempotency key already belongs to another request';
        END IF;

        COMMIT;

        SELECT
            id AS transfer_id,
            reference_number,
            idempotency_key,
            status,
            'Already processed' AS result
        FROM transfers
        WHERE id = v_existing_id;

    ELSE

        /* =========================================
           CHECK BOTH ACCOUNTS EXIST
           ========================================= */

        SELECT COUNT(*)
        INTO v_count
        FROM accounts
        WHERE id IN (p_from_account, p_to_account);

        IF v_count <> 2 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'One or both accounts do not exist';
        END IF;

        /* =========================================
           DETERMINISTIC LOCK ORDER
           ========================================= */

        IF p_from_account < p_to_account THEN

            SELECT balance, currency, status
            INTO v_from_balance, v_from_currency, v_from_status
            FROM accounts
            WHERE id = p_from_account
            FOR UPDATE;

            SELECT balance, currency, status
            INTO v_to_balance, v_to_currency, v_to_status
            FROM accounts
            WHERE id = p_to_account
            FOR UPDATE;

        ELSE

            SELECT balance, currency, status
            INTO v_to_balance, v_to_currency, v_to_status
            FROM accounts
            WHERE id = p_to_account
            FOR UPDATE;

            SELECT balance, currency, status
            INTO v_from_balance, v_from_currency, v_from_status
            FROM accounts
            WHERE id = p_from_account
            FOR UPDATE;

        END IF;

        /* =========================================
           VALIDATIONS
           ========================================= */

        IF v_from_status <> 'active' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Source account is not active';
        END IF;

        IF v_to_status <> 'active' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Destination account is not active';
        END IF;

        IF v_from_currency <> v_to_currency THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Currency mismatch: conversion is not configured';
        END IF;

        IF v_from_balance < p_amount THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient balance';
        END IF;

        /* No transfer limit exists in current schema. */

        SET v_from_after = v_from_balance - p_amount;
        SET v_to_after = v_to_balance + p_amount;

        SET v_reference =
            CONCAT(
                'TR-',
                REPLACE(UUID(), '-', '')
            );

        /* =========================================
           CREATE TRANSFER
           ========================================= */

        INSERT INTO transfers
        (
            reference_number,
            idempotency_key,
            from_account_id,
            to_account_id,
            amount,
            transfer_fee,
            description,
            created_at,
            status
        )
        VALUES
        (
            v_reference,
            v_request,
            p_from_account,
            p_to_account,
            p_amount,
            v_fee,
            p_description,
            NOW(),
            'processing'
        );

        /* =========================================
           UPDATE BALANCES
           ========================================= */

        UPDATE accounts
        SET balance = v_from_after
        WHERE id = p_from_account;

        UPDATE accounts
        SET balance = v_to_after
        WHERE id = p_to_account;

        /* =========================================
           TRANSFER OUT
           ========================================= */

        INSERT INTO transactions
        (
            account_id,
            transfer_id,
            transaction_type,
            amount,
            balance_before,
            balance_after,
            description,
            created_at,
            status
        )
        VALUES
        (
            p_from_account,
            LAST_INSERT_ID(),
            'transfer_out',
            p_amount,
            v_from_balance,
            v_from_after,
            COALESCE(p_description, 'Transfer out'),
            NOW(),
            'completed'
        );

        /* =========================================
           TRANSFER IN
           ========================================= */

        INSERT INTO transactions
        (
            account_id,
            transfer_id,
            transaction_type,
            amount,
            balance_before,
            balance_after,
            description,
            created_at,
            status
        )
        SELECT
            p_to_account,
            id,
            'transfer_in',
            p_amount,
            v_to_balance,
            v_to_after,
            COALESCE(p_description, 'Transfer in'),
            NOW(),
            'completed'
        FROM transfers
        WHERE reference_number = v_reference;

        /* =========================================
           FEE, IF THERE IS ONE
           ========================================= */

        IF v_fee > 0 THEN

            INSERT INTO transactions
            (
                account_id,
                transfer_id,
                transaction_type,
                amount,
                balance_before,
                balance_after,
                description,
                created_at,
                status
            )
            VALUES
            (
                p_from_account,
                (
                    SELECT id
                    FROM transfers
                    WHERE reference_number = v_reference
                ),
                'fee',
                v_fee,
                v_from_after,
                v_from_after - v_fee,
                'Transfer fee',
                NOW(),
                'completed'
            );

            UPDATE accounts
            SET balance = balance - v_fee
            WHERE id = p_from_account;

        END IF;

        /* =========================================
           COMPLETE TRANSFER
           ========================================= */

        UPDATE transfers
        SET
            status = 'completed',
            completed_at = NOW()
        WHERE reference_number = v_reference;

        COMMIT;

        SELECT
            id AS transfer_id,
            reference_number,
            idempotency_key,
            status,
            'Transfer completed' AS result
        FROM transfers
        WHERE reference_number = v_reference;

    END IF;

END //

DELIMITER ;

-- ====================================
/*Transfer Money*/

USE banking_system;

DROP PROCEDURE IF EXISTS transfer_money;

DELIMITER //

CREATE PROCEDURE transfer_money(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2),
    IN p_description VARCHAR(255)
)
BEGIN

    CALL transfer_money_core(
        UUID(),
        p_from_account,
        p_to_account,
        p_amount,
        p_description
    );

END //

CALL transfer_money(1, 3,  500.00, 'Family support');

DELIMITER ;

-- ====================================
/*Network-safe Idempotent Transfer*/

DROP PROCEDURE IF EXISTS transfer_money_request;

DELIMITER //

CREATE PROCEDURE transfer_money_request(
    IN p_request_id VARCHAR(100),
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(15,2),
    IN p_description VARCHAR(255)
)
BEGIN

    IF p_request_id IS NULL
       OR TRIM(p_request_id) = ''
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Request ID is required';
    END IF;

    CALL transfer_money_core(
        p_request_id,
        p_from_account,
        p_to_account,
        p_amount,
        p_description
    );

END //

DELIMITER ;

-- ====================================
/*Double Execution Challenge*/

SELECT
    id,
    reference_number,
    idempotency_key,
    from_account_id,
    to_account_id,
    amount,
    status
FROM transfers
WHERE idempotency_key = 'REQ-10001';

-- ====================================

SELECT
    t.id,
    t.transfer_id,
    t.account_id,
    t.transaction_type,
    t.amount,
    t.balance_before,
    t.balance_after
FROM transactions t
JOIN transfers tr
    ON tr.id = t.transfer_id
WHERE tr.idempotency_key = 'REQ-10001';

-- ====================================
/*Concurrency Challenge*/

SELECT balance FROM accounts;

-- ====================================

UPDATE accounts
SET balance = balance - 800
WHERE id = 1
AND balance >= 800;

-- ====================================

UPDATE accounts
SET balance = balance - 700
WHERE id = 1
AND balance >= 700;

-- ====================================
/*Balance Integrity*/

WITH ordered_transactions AS
(
    SELECT
        t.*,

        ROW_NUMBER() OVER
        (
            PARTITION BY t.account_id
            ORDER BY t.created_at, t.id
        ) AS rn,

        CASE
            WHEN t.transaction_type IN
            (
                'deposit',
                'transfer_in',
                'refund'
            )
            THEN t.amount

            WHEN t.transaction_type IN
            (
                'withdrawal',
                'transfer_out',
                'fee',
                'loan_payment'
            )
            THEN -t.amount

            ELSE 0
        END AS signed_amount

    FROM transactions t
    WHERE t.status = 'completed'
),

calculated AS
(
    SELECT
        account_id,

        MAX(
            CASE
                WHEN rn = 1
                THEN balance_before
            END
        ) AS opening_balance,

        SUM(signed_amount) AS net_change,

        MAX(
            CASE
                WHEN rn = 1
                THEN balance_before
            END
        ) + SUM(signed_amount)
        AS calculated_balance

    FROM ordered_transactions
    GROUP BY account_id
)

SELECT
    a.id AS account_id,
    a.account_number,
    a.balance AS stored_balance,
    c.opening_balance,
    c.net_change,
    c.calculated_balance,

    a.balance - c.calculated_balance
    AS difference

FROM accounts a
JOIN calculated c
    ON c.account_id = a.id

WHERE a.balance <> c.calculated_balance

ORDER BY ABS(a.balance - c.calculated_balance) DESC; 

-- ====================================
/*Balance Integrity - control*/

WITH ordered AS
(
    SELECT
        t.*,

        LEAD(balance_before) OVER
        (
            PARTITION BY account_id
            ORDER BY created_at, id
        ) AS next_balance_before

    FROM transactions t
)

SELECT
    id,
    account_id,
    balance_after,
    next_balance_before

FROM ordered

WHERE next_balance_before IS NOT NULL
  AND balance_after <> next_balance_before;

-- ====================================
/*Window Functions*/

SELECT
    c.id,
    c.full_name,
    SUM(a.balance) AS total_balance,

    ROW_NUMBER() OVER
    (
        ORDER BY SUM(a.balance) DESC
    ) AS row_number_rank,

    RANK() OVER
    (
        ORDER BY SUM(a.balance) DESC
    ) AS rank_position,

    DENSE_RANK() OVER
    (
        ORDER BY SUM(a.balance) DESC
    ) AS dense_rank_position

FROM customers c
JOIN accounts a
    ON c.id = a.customer_id

GROUP BY c.id, c.full_name;

-- ====================================

SELECT
    a.branch_id,
    a.account_number,
    a.balance,

    ROW_NUMBER() OVER
    (
        PARTITION BY a.branch_id
        ORDER BY a.balance DESC
    ) AS row_number_position,

    RANK() OVER
    (
        PARTITION BY a.branch_id
        ORDER BY a.balance DESC
    ) AS rank_position,

    DENSE_RANK() OVER
    (
        PARTITION BY a.branch_id
        ORDER BY a.balance DESC
    ) AS dense_rank_position

FROM accounts a;

-- ====================================
/*her branchte Top 3 account */

WITH ranked_accounts AS
(
    SELECT
        a.*,

        ROW_NUMBER() OVER
        (
            PARTITION BY branch_id
            ORDER BY balance DESC
        ) AS rn

    FROM accounts a
)

SELECT
    id,
    account_number,
    branch_id,
    balance

FROM ranked_accounts

WHERE rn <= 3

ORDER BY branch_id, balance DESC;

-- ====================================
/*transaction sıralama*/

SELECT
    account_id,
    id,
    transaction_type,
    amount,
    created_at,

    ROW_NUMBER() OVER
    (
        PARTITION BY account_id
        ORDER BY created_at, id
    ) AS transaction_number

FROM transactions;

-- ====================================
/*previous transaction*/

SELECT
    account_id,
    id,
    transaction_type,
    amount,
    created_at,

    LAG(amount) OVER
    (
        PARTITION BY account_id
        ORDER BY created_at, id
    ) AS previous_amount

FROM transactions;

-- ====================================
/*Next transaction*/

SELECT
    account_id,
    id,
    transaction_type,
    amount,
    created_at,

    LEAD(amount) OVER
    (
        PARTITION BY account_id
        ORDER BY created_at, id
    ) AS next_amount

FROM transactions;

-- ====================================
/*balance farkı*/

SELECT
    account_id,
    id,
    created_at,
    balance_after,

    LAG(balance_after) OVER
    (
        PARTITION BY account_id
        ORDER BY created_at, id
    ) AS previous_balance_after,

    balance_after
    -
    LAG(balance_after) OVER
    (
        PARTITION BY account_id
        ORDER BY created_at, id
    ) AS balance_difference

FROM transactions

ORDER BY account_id, created_at, id;

-- ====================================
/*running balance*/

WITH tx AS
(
    SELECT
        t.*,

        ROW_NUMBER() OVER
        (
            PARTITION BY account_id
            ORDER BY created_at, id
        ) AS rn,

        CASE
            WHEN transaction_type IN
            ('deposit', 'transfer_in', 'refund')
                THEN amount

            WHEN transaction_type IN
            ('withdrawal', 'transfer_out', 'fee', 'loan_payment')
                THEN -amount

            ELSE 0
        END AS signed_amount

    FROM transactions t
    WHERE status = 'completed'
)

SELECT
    account_id,
    id,
    transaction_type,
    amount,
    created_at,

    FIRST_VALUE(balance_before) OVER
    (
        PARTITION BY account_id
        ORDER BY created_at, id
    )
    +

    SUM(signed_amount) OVER
    (
        PARTITION BY account_id
        ORDER BY created_at, id
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    )
    AS running_balance

FROM tx

ORDER BY account_id, created_at, id;

-- ====================================
/*Monthly running total transfers*/

WITH monthly_transfers AS
(
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS transfer_month,
        SUM(amount) AS monthly_total

    FROM transfers

    WHERE status = 'completed'

    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)

SELECT
    transfer_month,
    monthly_total,

    SUM(monthly_total) OVER
    (
        ORDER BY transfer_month
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS running_total

FROM monthly_transfers

ORDER BY transfer_month;

-- ====================================
/*bu ay ile önceki ayı karşılaştırma */

WITH monthly_transfers AS
(
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS transfer_month,
        SUM(amount) AS monthly_total

    FROM transfers

    WHERE status = 'completed'

    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)

SELECT
    transfer_month,
    monthly_total,

    SUM(monthly_total) OVER
    (
        ORDER BY transfer_month
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS running_total

FROM monthly_transfers

ORDER BY transfer_month;

-- ====================================
/*müşterinin transfer katkısı*/

WITH customer_transfers AS
(
    SELECT
        a.customer_id,
        SUM(t.amount) AS sent_amount

    FROM accounts a

    JOIN transfers t
        ON t.from_account_id = a.id

    WHERE t.status = 'completed'

    GROUP BY a.customer_id
)

SELECT
    customer_id,
    sent_amount,

    ROUND(
        100 * sent_amount /
        NULLIF(SUM(sent_amount) OVER (), 0),
        2
    ) AS contribution_percent

FROM customer_transfers

ORDER BY contribution_percent DESC;

-- ====================================
/*CTE*/

WITH customer_balances AS
(
    SELECT
        c.id,
        c.full_name,
        COALESCE(SUM(a.balance), 0) AS total_balance

    FROM customers c

    LEFT JOIN accounts a
        ON c.id = a.customer_id

    GROUP BY c.id, c.full_name
),

average_balance AS
(
    SELECT AVG(total_balance) AS avg_balance
    FROM customer_balances
)

SELECT
    cb.id,
    cb.full_name,
    cb.total_balance,
    ab.avg_balance

FROM customer_balances cb
CROSS JOIN average_balance ab

WHERE cb.total_balance > ab.avg_balance; 

-- ====================================
/*CTE - account activity*/

WITH account_activity AS
(
    SELECT
        a.id AS account_id,
        a.account_number,
        a.customer_id,

        COUNT(t.id) AS transaction_count,

        COALESCE(SUM(t.amount), 0) AS transaction_value,

        MAX(t.created_at) AS last_transaction

    FROM accounts a

    LEFT JOIN transactions t
        ON a.id = t.account_id

    GROUP BY
        a.id,
        a.account_number,
        a.customer_id
)

SELECT *
FROM account_activity

ORDER BY transaction_count DESC;

-- ====================================
/*En aktif müşteriler*/

WITH customer_activity AS
(
    SELECT
        c.id,
        c.full_name,
        COUNT(t.id) AS transaction_count

    FROM customers c

    LEFT JOIN accounts a
        ON c.id = a.customer_id

    LEFT JOIN transactions t
        ON a.id = t.account_id

    GROUP BY c.id, c.full_name
)

SELECT *
FROM customer_activity

ORDER BY transaction_count DESC
LIMIT 10;

-- ====================================
/*Overdue installment analysis*/

WITH overdue AS
(
    SELECT
        l.customer_id,
        l.loan_number,
        li.id AS installment_id,
        li.amount,
        li.paid_amount,
        li.due_date

    FROM loans l

    JOIN loan_installments li
        ON l.id = li.loan_id

    WHERE li.status = 'overdue'
)

SELECT
    customer_id,
    COUNT(*) AS overdue_count,
    SUM(amount - paid_amount) AS overdue_amount

FROM overdue

GROUP BY customer_id

ORDER BY overdue_amount DESC;

-- ====================================
/*Branch performance*/

WITH branch_accounts AS
(
    SELECT
        branch_id,
        COUNT(*) AS account_count,
        SUM(balance) AS total_balance,
        AVG(balance) AS average_balance

    FROM accounts

    GROUP BY branch_id
),

branch_transactions AS
(
    SELECT
        a.branch_id,
        COUNT(t.id) AS transaction_count,
        COALESCE(SUM(t.amount), 0) AS transaction_volume

    FROM accounts a

    LEFT JOIN transactions t
        ON a.id = t.account_id

    GROUP BY a.branch_id
)

SELECT
    b.id AS branch_id,
    b.branch_name,

    COALESCE(ba.account_count, 0) AS account_count,
    COALESCE(ba.total_balance, 0) AS total_balance,
    COALESCE(ba.average_balance, 0) AS average_balance,

    COALESCE(bt.transaction_count, 0) AS transaction_count,
    COALESCE(bt.transaction_volume, 0) AS transaction_volume

FROM branches b

LEFT JOIN branch_accounts ba
    ON b.id = ba.branch_id

LEFT JOIN branch_transactions bt
    ON b.id = bt.branch_id

ORDER BY transaction_volume DESC;

-- ====================================
/*Şüpheli balance hesapları*/

WITH calculated AS
(
    SELECT
        account_id,

        MAX(
            CASE
                WHEN rn = 1
                THEN balance_before
            END
        ) AS opening_balance,

        SUM(signed_amount) AS net_change

    FROM
    (
        SELECT
            t.*,

            ROW_NUMBER() OVER
            (
                PARTITION BY account_id
                ORDER BY created_at, id
            ) AS rn,

            CASE
                WHEN transaction_type IN
                ('deposit', 'transfer_in', 'refund')
                    THEN amount

                WHEN transaction_type IN
                ('withdrawal', 'transfer_out', 'fee', 'loan_payment')
                    THEN -amount

                ELSE 0
            END AS signed_amount

        FROM transactions t

        WHERE status = 'completed'
    ) x

    GROUP BY account_id
)

SELECT
    a.id,
    a.account_number,
    a.balance AS stored_balance,

    c.opening_balance + c.net_change
    AS calculated_balance,

    a.balance -
    (c.opening_balance + c.net_change)
    AS difference

FROM accounts a

JOIN calculated c
    ON a.id = c.account_id

WHERE a.balance <>
      (c.opening_balance + c.net_change);

-- ====================================
/*trigers*/

DROP TRIGGER IF EXISTS trg_transactions_before_insert;
DROP TRIGGER IF EXISTS trg_transactions_before_delete;
DROP TRIGGER IF EXISTS trg_transactions_before_update;
DROP TRIGGER IF EXISTS trg_accounts_before_delete;
DROP TRIGGER IF EXISTS trg_accounts_after_update;
DROP TRIGGER IF EXISTS trg_customers_after_update;
DROP TRIGGER IF EXISTS trg_transfers_after_insert;
DROP TRIGGER IF EXISTS trg_transfers_after_update;
DROP TRIGGER IF EXISTS trg_loans_after_update;
DROP TRIGGER IF EXISTS trg_installments_before_update;
DROP TRIGGER IF EXISTS trg_installments_after_update;

-- ====================================

DELIMITER //

CREATE TRIGGER trg_transactions_before_insert
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN

    IF NEW.amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Financial transaction amount must be greater than zero';
    END IF;

END //

DELIMITER ;

-- ====================================
/*Completed transaction remove*/

DELIMITER //

CREATE TRIGGER trg_transactions_before_delete
BEFORE DELETE ON transactions
FOR EACH ROW
BEGIN

    IF OLD.status = 'completed' THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Completed financial transactions cannot be deleted';

    END IF;

END //

DELIMITER ;

-- ====================================
/*acount silme koruması*/

DELIMITER //

CREATE TRIGGER trg_accounts_before_delete
BEFORE DELETE ON accounts
FOR EACH ROW
BEGIN
    DECLARE v_transactions INT DEFAULT 0;
    DECLARE v_transfers INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_transactions
    FROM transactions
    WHERE account_id = OLD.id;

    SELECT COUNT(*)
    INTO v_transfers
    FROM transfers
    WHERE from_account_id = OLD.id
       OR to_account_id = OLD.id;

    IF v_transactions > 0
       OR v_transfers > 0
    THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Account with financial history cannot be deleted';

    END IF;

END //

DELIMITER ;

-- ====================================
/*Balance before/after değiştirmeyi engelle*/

DELIMITER //

CREATE TRIGGER trg_transactions_before_update
BEFORE UPDATE ON transactions
FOR EACH ROW
BEGIN

    IF OLD.status = 'completed'
       AND (
            NEW.balance_before <> OLD.balance_before
            OR
            NEW.balance_after <> OLD.balance_after
       )
    THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
            'Balance history of completed transaction is immutable';

    END IF;

END //

DELIMITER ;

-- ====================================
/*acount değişikleri "audit_log"a yazılsın*/

DELIMITER //

CREATE TRIGGER trg_accounts_after_update
AFTER UPDATE ON accounts
FOR EACH ROW
BEGIN

    IF OLD.balance <> NEW.balance THEN

        INSERT INTO audit_logs
        (
            customer_id,
            account_id,
            action_type,
            table_name,
            record_id,
            old_value,
            new_value
        )
        VALUES
        (
            NEW.customer_id,
            NEW.id,
            'UPDATE',
            'accounts',
            NEW.id,
            CONCAT('balance=', OLD.balance),
            CONCAT('balance=', NEW.balance)
        );

    END IF;

    IF OLD.status <> NEW.status THEN

        INSERT INTO audit_logs
        (
            customer_id,
            account_id,
            action_type,
            table_name,
            record_id,
            old_value,
            new_value
        )
        VALUES
        (
            NEW.customer_id,
            NEW.id,
            'UPDATE',
            'accounts',
            NEW.id,
            CONCAT('status=', OLD.status),
            CONCAT('status=', NEW.status)
        );

    END IF;

END //

DELIMITER ;

-- ====================================
/*costumer değişikliğini audit et*/

DELIMITER //

CREATE TRIGGER trg_customers_after_update
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN

    IF NOT (OLD.status <=> NEW.status) THEN

        INSERT INTO audit_logs
        (
            customer_id,
            action_type,
            table_name,
            record_id,
            old_value,
            new_value
        )
        VALUES
        (
            NEW.id,
            'UPDATE',
            'customers',
            NEW.id,
            CONCAT('status=', OLD.status),
            CONCAT('status=', NEW.status)
        );

    END IF;

    IF NOT (OLD.email <=> NEW.email) THEN

        INSERT INTO audit_logs
        (
            customer_id,
            action_type,
            table_name,
            record_id,
            old_value,
            new_value
        )
        VALUES
        (
            NEW.id,
            'UPDATE',
            'customers',
            NEW.id,
            CONCAT('email=', OLD.email),
            CONCAT('email=', NEW.email)
        );

    END IF;

END //

DELIMITER ;

-- ====================================
/*Transfer audit*/

DELIMITER //

CREATE TRIGGER trg_transfers_after_insert
AFTER INSERT ON transfers
FOR EACH ROW
BEGIN

    INSERT INTO audit_logs
    (
        account_id,
        action_type,
        table_name,
        record_id,
        old_value,
        new_value
    )
    VALUES
    (
        NEW.from_account_id,
        'CREATE',
        'transfers',
        NEW.id,
        NULL,
        CONCAT(
            'Transfer created: ',
            NEW.reference_number,
            ', amount=',
            NEW.amount
        )
    );

END //

DELIMITER ;

-- ====================================
/*Installment status trigger*/

DELIMITER //

CREATE TRIGGER trg_installments_before_update
BEFORE UPDATE ON loan_installments
FOR EACH ROW
BEGIN

    IF NEW.paid_amount >= NEW.amount THEN

        SET NEW.paid_amount = NEW.amount;
        SET NEW.status = 'paid';

        IF NEW.paid_at IS NULL THEN
            SET NEW.paid_at = NOW();
        END IF;

    ELSEIF NEW.paid_amount > 0 THEN

        SET NEW.status = 'partially_paid';

    ELSEIF NEW.due_date < CURDATE() THEN

        SET NEW.status = 'overdue';

    ELSE

        SET NEW.status = 'pending';

    END IF;

END //

DELIMITER ;

-- ====================================
/*Tüm installment'lar ödendiyse Loan = paid*/

DELIMITER //

CREATE TRIGGER trg_installments_after_update
AFTER UPDATE ON loan_installments
FOR EACH ROW
BEGIN
    DECLARE v_total INT DEFAULT 0;
    DECLARE v_paid INT DEFAULT 0;

    SELECT COUNT(*)
    INTO v_total
    FROM loan_installments
    WHERE loan_id = NEW.loan_id;

    SELECT COUNT(*)
    INTO v_paid
    FROM loan_installments
    WHERE loan_id = NEW.loan_id
      AND status = 'paid';

    IF v_total > 0 AND v_total = v_paid THEN

        UPDATE loans
        SET status = 'paid'
        WHERE id = NEW.loan_id
          AND status <> 'cancelled';

    END IF;

END //

DELIMITER ;

-- ====================================
/*Loan status audit*/

DELIMITER //

CREATE TRIGGER trg_loans_after_update
AFTER UPDATE ON loans
FOR EACH ROW
BEGIN

    IF OLD.status <> NEW.status THEN

        INSERT INTO audit_logs
        (
            customer_id,
            action_type,
            table_name,
            record_id,
            old_value,
            new_value
        )
        VALUES
        (
            NEW.customer_id,
            'UPDATE',
            'loans',
            NEW.id,
            CONCAT('status=', OLD.status),
            CONCAT('status=', NEW.status)
        );

    END IF;

END //

DELIMITER ;

-- ====================================
/*Fraud Detection*/

SELECT
    t1.from_account_id AS account_id,
    t1.created_at AS window_start,
    COUNT(t2.id) AS transfer_count

FROM transfers t1

JOIN transfers t2
    ON t2.from_account_id = t1.from_account_id
    AND t2.status = 'completed'
    AND t2.created_at BETWEEN
        t1.created_at
        AND DATE_ADD(t1.created_at, INTERVAL 1 HOUR)

WHERE t1.status = 'completed'

GROUP BY
    t1.from_account_id,
    t1.created_at

HAVING COUNT(t2.id) > 10

ORDER BY transfer_count DESC;

-- ====================================
/*Suspicious Transfer Frequency*/

SELECT
    t1.from_account_id AS account_id,
    t1.created_at AS window_start,
    COUNT(t2.id) AS transfer_count

FROM transfers t1

JOIN transfers t2
    ON t2.from_account_id = t1.from_account_id
    AND t2.status = 'completed'
    AND t2.created_at BETWEEN
        t1.created_at
        AND DATE_ADD(t1.created_at, INTERVAL 1 HOUR)

WHERE t1.status = 'completed'

GROUP BY
    t1.from_account_id,
    t1.created_at

HAVING COUNT(t2.id) > 10

ORDER BY transfer_count DESC;

-- ====================================
/*Multiple Senders to One Account*/

SELECT
    to_account_id,
    DATE(created_at) AS transfer_date,
    COUNT(DISTINCT from_account_id) AS unique_senders,
    SUM(amount) AS received_amount

FROM transfers

WHERE status = 'completed'

GROUP BY
    to_account_id,
    DATE(created_at)

HAVING COUNT(DISTINCT from_account_id) > 15

ORDER BY unique_senders DESC;

-- ====================================
/*Unusually Large Transfer*/

WITH customer_average AS
(
    SELECT
        a.customer_id,
        AVG(t.amount) AS average_transfer

    FROM accounts a

    JOIN transfers t
        ON a.id = t.from_account_id

    WHERE t.status = 'completed'

    GROUP BY a.customer_id
)

SELECT
    t.id,
    t.reference_number,
    a.customer_id,
    t.amount,
    ca.average_transfer

FROM transfers t

JOIN accounts a
    ON t.from_account_id = a.id

JOIN customer_average ca
    ON a.customer_id = ca.customer_id

WHERE t.status = 'completed'
  AND t.amount > 3 * ca.average_transfer;

-- ====================================
/*90 gün pasif kaldıktan sonra büyük transfer*/

WITH previous_activity AS
(
    SELECT
        t.id,
        t.from_account_id,
        t.amount,
        t.created_at,

        (
            SELECT MAX(t2.created_at)
            FROM transactions t2
            WHERE t2.account_id = t.from_account_id
              AND t2.created_at < t.created_at
              AND t2.status = 'completed'
        ) AS last_activity

    FROM transfers t

    WHERE t.status = 'completed'
)

SELECT
    id,
    from_account_id,
    amount,
    created_at,
    last_activity,
    DATEDIFF(created_at, last_activity) AS inactive_days

FROM previous_activity

WHERE last_activity IS NOT NULL
  AND DATEDIFF(created_at, last_activity) >= 90

  AND amount >
      (
          SELECT AVG(t3.amount) * 3
          FROM transfers t3
          WHERE t3.from_account_id =
                previous_activity.from_account_id
            AND t3.status = 'completed'
      );

-- ====================================
/*Kısa sürede birçok card transaction*/

SELECT
    c1.card_id,
    c1.transaction_date AS window_start,
    COUNT(c2.id) AS transaction_count

FROM card_transactions c1

JOIN card_transactions c2
    ON c2.card_id = c1.card_id
    AND c2.transaction_date BETWEEN
        c1.transaction_date
        AND DATE_ADD(c1.transaction_date, INTERVAL 10 MINUTE)

GROUP BY
    c1.card_id,
    c1.transaction_date

HAVING COUNT(c2.id) >= 4;

-- ====================================
/*Kısa sürede farklı merchant'lar*/

  c1.card_id,
    c1.transaction_date,
    COUNT(DISTINCT c2.merchant_name) AS merchant_count

FROM card_transactions c1

JOIN card_transactions c2
    ON c2.card_id = c1.card_id
    AND c2.transaction_date BETWEEN
        c1.transaction_date
        AND DATE_ADD(c1.transaction_date, INTERVAL 30 MINUTE)

GROUP BY
    c1.card_id,
    c1.transaction_date

HAVING COUNT(DISTINCT c2.merchant_name) >= 3;

-- ====================================
/*refund orjinal işlemden büyüktür*/

ALTER TABLE transactions
ADD COLUMN original_transaction_id INT NULL
AFTER transfer_id;

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_original
FOREIGN KEY (original_transaction_id)
REFERENCES transactions(id);

-- ====================================

SELECT
    refund.id AS refund_id,
    refund.amount AS refund_amount,
    original.id AS original_id,
    original.amount AS original_amount

FROM transactions refund

JOIN transactions original
    ON refund.original_transaction_id = original.id

WHERE refund.transaction_type = 'refund'
  AND refund.amount > original.amount;

-- ====================================
/*İNDEXSİNG*/

CREATE INDEX idx_accounts_customer_balance
ON accounts(customer_id, balance);

CREATE INDEX idx_transfers_status_created
ON transfers(status, created_at);

CREATE INDEX idx_transfers_from_created
ON transfers(from_account_id, created_at);

CREATE INDEX idx_transfers_to_created
ON transfers(to_account_id, created_at);

CREATE INDEX idx_transactions_account_created
ON transactions(account_id, created_at, id);

CREATE INDEX idx_transactions_type_created
ON transactions(transaction_type, created_at);

CREATE INDEX idx_loans_status_start
ON loans(status, start_date);

CREATE INDEX idx_installments_status_due
ON loan_installments(status, due_date);

CREATE INDEX idx_card_transactions_card_date
ON card_transactions(card_id, transaction_date);

-- ====================================
/*EXPLAIN Before*/

EXPLAIN
SELECT *
FROM transfers
WHERE status = 'completed'
  AND created_at >= '2024-01-01'
  AND created_at < '2024-02-01';

-- ====================================


EXPLAIN
SELECT *
FROM transactions
WHERE account_id = 1
ORDER BY created_at DESC;

/*! index oluşturulduktan sonra sorguları tekrarla !*/

-- ====================================
/*Isolation Levels*/

/*A;*/
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

UPDATE accounts
SET balance = balance - 500
WHERE id = 1;

-- ====================================

/*B;*/

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;

SELECT balance
FROM accounts
WHERE id = 1;

COMMIT;

/*A da commit yok ama B de var*/

-- ====================================
/*read commited ile dirty Read*/

SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT balance
FROM accounts
WHERE id = 1;

-- ====================================
non-repeatable read

/*A;*/
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT balance
FROM accounts
WHERE id = 1;

-- ====================================

/*B;*/
START TRANSACTION;

UPDATE accounts
SET balance = balance + 500
WHERE id = 1;

COMMIT;

-- ====================================
/*REPEATABLE READ*/

/*A;*/
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

START TRANSACTION;

SELECT balance
FROM accounts
WHERE id = 1;

-- ====================================

/*B;*/
START TRANSACTION;

UPDATE accounts
SET balance = balance + 500
WHERE id = 1;

COMMIT;

-- ====================================
/*phantom read*/

SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT *
FROM transactions
WHERE amount > 5000;

-- ====================================

START TRANSACTION;

INSERT INTO transactions
(
    account_id,
    transaction_type,
    amount,
    balance_before,
    balance_after,
    description,
    status
)
VALUES
(
    1,
    'deposit',
    9000,
    10000,
    19000,
    'Phantom test',
    'completed'
);

COMMIT;

-- ====================================
/*serıalızable */

START TRANSACTION;

INSERT INTO transactions
(
    account_id,
    transaction_type,
    amount,
    balance_before,
    balance_after,
    description,
    status
)
VALUES
(
    1,
    'deposit',
    9000,
    10000,
    19000,
    'Phantom test',
    'completed'
);

COMMIT;

-- ====================================

START TRANSACTION;

SELECT balance
FROM accounts
WHERE id = 1
FOR UPDATE;

UPDATE accounts
SET balance = balance - 100
WHERE id = 1;

COMMIT;

-- ====================================
/*FINAL REPORT */

WITH account_summary AS
(
    SELECT
        customer_id,
        COUNT(*) AS number_of_accounts,
        COALESCE(SUM(balance), 0) AS total_balance
    FROM accounts
    GROUP BY customer_id
),

sent_summary AS
(
    SELECT
        a.customer_id,
        COUNT(t.id) AS transfers_sent,
        COALESCE(SUM(t.amount), 0) AS sent_amount
    FROM accounts a
    JOIN transfers t
        ON t.from_account_id = a.id
    WHERE t.status = 'completed'
    GROUP BY a.customer_id
),

received_summary AS
(
    SELECT
        a.customer_id,
        COUNT(t.id) AS transfers_received,
        COALESCE(SUM(t.amount), 0) AS received_amount
    FROM accounts a
    JOIN transfers t
        ON t.to_account_id = a.id
    WHERE t.status = 'completed'
    GROUP BY a.customer_id
),

card_summary AS
(
    SELECT
        a.customer_id,
        COUNT(DISTINCT c.id) AS number_of_cards,
        COALESCE(
            SUM(
                CASE
                    WHEN ct.status = 'approved'
                    THEN ct.amount
                    ELSE 0
                END
            ),
            0
        ) AS card_spending
    FROM accounts a
    LEFT JOIN cards c
        ON a.id = c.account_id
    LEFT JOIN card_transactions ct
        ON c.id = ct.card_id
    GROUP BY a.customer_id
),

loan_summary AS
(
    SELECT
        customer_id,
        COUNT(*) AS total_loans,
        COALESCE(SUM(principal_amount), 0) AS total_borrowed,
        COALESCE(SUM(total_amount), 0) AS total_loan_value
    FROM loans
    GROUP BY customer_id
),

loan_payment_summary AS
(
    SELECT
        l.customer_id,
        COALESCE(SUM(li.paid_amount), 0) AS total_loan_paid,

        COALESCE(
            SUM(
                CASE
                    WHEN li.status = 'overdue'
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ) AS overdue_installments

    FROM loans l

    LEFT JOIN loan_installments li
        ON l.id = li.loan_id

    GROUP BY l.customer_id
),

transaction_summary AS
(
    SELECT
        a.customer_id,
        MAX(t.created_at) AS last_transaction_date

    FROM accounts a

    LEFT JOIN transactions t
        ON a.id = t.account_id

    GROUP BY a.customer_id
),

account_usage_base AS
(
    SELECT
        a.customer_id,
        a.id AS account_id,
        a.account_number,
        COUNT(t.id) AS transaction_count

    FROM accounts a

    LEFT JOIN transactions t
        ON a.id = t.account_id

    GROUP BY
        a.customer_id,
        a.id,
        a.account_number
),

account_usage_ranked AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY customer_id
            ORDER BY transaction_count DESC, account_id
        ) AS rn

    FROM account_usage_base
),

most_used_account AS
(
    SELECT
        customer_id,
        account_number
    FROM account_usage_ranked
    WHERE rn = 1
)

SELECT
    c.customer_number,
    c.full_name AS customer_name,

    COALESCE(a.number_of_accounts, 0)
        AS number_of_accounts,

    COALESCE(a.total_balance, 0)
        AS total_balance,

    COALESCE(
        (
            SELECT SUM(t.amount)
            FROM transactions t
            JOIN accounts acc
                ON t.account_id = acc.id
            WHERE acc.customer_id = c.id
              AND t.transaction_type = 'deposit'
              AND t.status = 'completed'
        ),
        0
    ) AS total_deposits,

    COALESCE(
        (
            SELECT SUM(t.amount)
            FROM transactions t
            JOIN accounts acc
                ON t.account_id = acc.id
            WHERE acc.customer_id = c.id
              AND t.transaction_type = 'withdrawal'
              AND t.status = 'completed'
        ),
        0
    ) AS total_withdrawals,

    COALESCE(s.transfers_sent, 0)
        AS transfers_sent,

    COALESCE(s.sent_amount, 0)
        AS sent_amount,

    COALESCE(r.transfers_received, 0)
        AS transfers_received,

    COALESCE(r.received_amount, 0)
        AS received_amount,

    COALESCE(cs.number_of_cards, 0)
        AS number_of_cards,

    COALESCE(cs.card_spending, 0)
        AS card_spending,

    COALESCE(ls.total_loans, 0)
        AS total_loans,

    COALESCE(ls.total_borrowed, 0)
        AS total_borrowed,

    COALESCE(lp.total_loan_paid, 0)
        AS total_loan_paid,

    COALESCE(ls.total_loan_value, 0)
        - COALESCE(lp.total_loan_paid, 0)
        AS remaining_debt,

    COALESCE(lp.overdue_installments, 0)
        AS overdue_installments,

    ts.last_transaction_date,

    mua.account_number
        AS most_used_account

FROM customers c

LEFT JOIN account_summary a
    ON c.id = a.customer_id

LEFT JOIN sent_summary s
    ON c.id = s.customer_id

LEFT JOIN received_summary r
    ON c.id = r.customer_id

LEFT JOIN card_summary cs
    ON c.id = cs.customer_id

LEFT JOIN loan_summary ls
    ON c.id = ls.customer_id

LEFT JOIN loan_payment_summary lp
    ON c.id = lp.customer_id

LEFT JOIN transaction_summary ts
    ON c.id = ts.customer_id

LEFT JOIN most_used_account mua
    ON c.id = mua.customer_id

ORDER BY c.id;

-- ====================================

INSERT INTO accounts
(
    account_number,
    customer_id,
    branch_id,
    account_type,
    currency,
    balance,
    status
)
SELECT
    'STRESS001',
    1,
    1,
    'checking',
    'SAR',
    10000.00,
    'active'
WHERE NOT EXISTS
(
    SELECT 1
    FROM accounts
    WHERE account_number = 'STRESS001'
);

-- ====================================

SET @stress_account_id =
(
    SELECT id
    FROM accounts
    WHERE account_number = 'STRESS001'
);

-- ====================================

SELECT
    id,
    account_number,
    balance
FROM accounts
WHERE id = @stress_account_id;

-- ====================================

SELECT
    account_number,
    balance AS final_balance
FROM accounts
WHERE id = @stress_account_id;

-- ====================================
/*stress testi transactionstan yeniden hesapla */

WITH ordered_transactions AS
(
    SELECT
        t.*,

        ROW_NUMBER() OVER
        (
            ORDER BY t.created_at, t.id
        ) AS rn,

        CASE
            WHEN t.transaction_type IN
            ('deposit', 'transfer_in', 'refund')
                THEN t.amount

            WHEN t.transaction_type IN
            ('withdrawal', 'transfer_out', 'fee', 'loan_payment')
                THEN -t.amount

            ELSE 0
        END AS signed_amount

    FROM transactions t
    WHERE t.account_id = @stress_account_id
      AND t.status = 'completed'
),

rebuilt AS
(
    SELECT
        @stress_account_id AS account_id,

        MAX(
            CASE
                WHEN rn = 1
                THEN balance_before
            END
        )
        +
        SUM(signed_amount)
        AS calculated_balance

    FROM ordered_transactions
)

SELECT
    a.account_number,

    a.balance AS stored_balance,

    r.calculated_balance,

    a.balance - r.calculated_balance
        AS difference,

    CASE
        WHEN a.balance = r.calculated_balance
            THEN 'BALANCE OK'
        ELSE 'BALANCE MISMATCH'
    END AS integrity_status

FROM accounts a

JOIN rebuilt r
    ON a.id = r.account_id;
