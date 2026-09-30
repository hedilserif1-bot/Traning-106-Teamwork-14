-- ============================================
-- Logistics Management System Database
-- ============================================

-- إنشاء قاعدة البيانات
CREATE DATABASE logistics_management;

USE logistics_management;


-- ============================================
-- 1. Table: customers - العملاء
-- ============================================

CREATE TABLE customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    customer_type VARCHAR(20) NOT NULL,
    city VARCHAR(50),
    address VARCHAR(255),
    registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active'
);


-- ============================================
-- 2. Table: branches - الفروع
-- ============================================

CREATE TABLE branches (
    id INT PRIMARY KEY AUTO_INCREMENT,
    branch_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    address VARCHAR(255),
    phone VARCHAR(20),
    manager_name VARCHAR(100),
    opened_at DATE,
    status VARCHAR(20) DEFAULT 'active'
);


-- ============================================
-- 3. Table: employees - الموظفين
-- ============================================

CREATE TABLE employees (
    id INT PRIMARY KEY AUTO_INCREMENT,
    branch_id INT NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    job_title VARCHAR(100),
    salary DECIMAL(10,2) CHECK (salary >= 0),
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'active',

    FOREIGN KEY (branch_id)
        REFERENCES branches(id)
);


-- ============================================
-- 4. Table: drivers - السائقين
-- ============================================

CREATE TABLE drivers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    branch_id INT NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    license_number VARCHAR(50) UNIQUE,
    license_expiry_date DATE,
    hire_date DATE,
    salary DECIMAL(10,2) CHECK (salary >= 0),
    status VARCHAR(20) DEFAULT 'active',

    FOREIGN KEY (branch_id)
        REFERENCES branches(id)
);


-- ============================================
-- 5. Table: vehicles - المركبات
-- ============================================

CREATE TABLE vehicles (
    id INT PRIMARY KEY AUTO_INCREMENT,
    branch_id INT NOT NULL,
    plate_number VARCHAR(20) UNIQUE NOT NULL,
    vehicle_type VARCHAR(50),
    model VARCHAR(100),
    manufacture_year YEAR,
    max_weight DECIMAL(10,2) NOT NULL CHECK (max_weight > 0),
    status VARCHAR(20) DEFAULT 'available',

    FOREIGN KEY (branch_id)
        REFERENCES branches(id)
);


-- ============================================
-- 6. Table: shipments - الشحنات
-- ============================================

CREATE TABLE shipments (
    id INT PRIMARY KEY AUTO_INCREMENT,

    tracking_number VARCHAR(50) UNIQUE NOT NULL,

    customer_id INT NOT NULL,
    origin_branch_id INT NOT NULL,
    destination_branch_id INT NOT NULL,

    sender_name VARCHAR(100) NOT NULL,
    sender_phone VARCHAR(20),

    receiver_name VARCHAR(100) NOT NULL,
    receiver_phone VARCHAR(20),
    receiver_address VARCHAR(255) NOT NULL,
    receiver_city VARCHAR(50) NOT NULL,

    weight DECIMAL(10,2) NOT NULL CHECK (weight > 0),
    shipping_cost DECIMAL(10,2) NOT NULL CHECK (shipping_cost >= 0),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expected_delivery_date DATE,
    delivered_at DATETIME,

    payment_status VARCHAR(20) DEFAULT 'pending',
    shipment_status VARCHAR(30) DEFAULT 'created',

    FOREIGN KEY (customer_id)
        REFERENCES customers(id),

    FOREIGN KEY (origin_branch_id)
        REFERENCES branches(id),

    FOREIGN KEY (destination_branch_id)
        REFERENCES branches(id),

    CHECK (origin_branch_id <> destination_branch_id)
);


-- ============================================
-- 7. Table: deliveries - عمليات التوصيل
-- ============================================

CREATE TABLE deliveries (
    id INT PRIMARY KEY AUTO_INCREMENT,

    shipment_id INT NOT NULL,
    driver_id INT NOT NULL,
    vehicle_id INT NOT NULL,

    assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,
    completed_at DATETIME,

    delivery_status VARCHAR(30) DEFAULT 'assigned',

    notes TEXT,

    FOREIGN KEY (shipment_id)
        REFERENCES shipments(id),

    FOREIGN KEY (driver_id)
        REFERENCES drivers(id),

    FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(id)
);


-- ============================================
-- 8. Table: shipment_tracking - تتبع الشحنة
-- ============================================

CREATE TABLE shipment_tracking (
    id INT PRIMARY KEY AUTO_INCREMENT,

    shipment_id INT NOT NULL,
    branch_id INT NOT NULL,

    status VARCHAR(30) NOT NULL,
    description VARCHAR(255),

    recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (shipment_id)
        REFERENCES shipments(id),

    FOREIGN KEY (branch_id)
        REFERENCES branches(id)
);


-- ============================================
-- 9. Table: payments - عمليات الدفع
-- ============================================

CREATE TABLE payments (
    id INT PRIMARY KEY AUTO_INCREMENT,

    shipment_id INT NOT NULL,

    amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),

    payment_method VARCHAR(30) NOT NULL,

    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,

    transaction_reference VARCHAR(100) UNIQUE,

    status VARCHAR(20) DEFAULT 'successful',

    FOREIGN KEY (shipment_id)
        REFERENCES shipments(id)
);


-- ============================================
-- تعديلات على جدول customers
-- ============================================

-- نوع العميل
ALTER TABLE customers
ADD CONSTRAINT chk_customer_type
CHECK (
    customer_type IN (
        'individual',
        'business'
    )
);

-- حالة العميل
ALTER TABLE customers
ADD CONSTRAINT chk_customer_status
CHECK (
    status IN (
        'active',
        'inactive',
        'blocked'
    )
);


-- ============================================
-- تعديلات على جدول branches
-- ============================================

ALTER TABLE branches
ADD CONSTRAINT chk_branch_status
CHECK (
    status IN (
        'active',
        'inactive'
    )
);


-- ============================================
-- تعديلات على جدول employees
-- ============================================

ALTER TABLE employees
ADD CONSTRAINT chk_employee_status
CHECK (
    status IN (
        'active',
        'inactive'
    )
);


-- ============================================
-- تعديلات على جدول drivers
-- ============================================

ALTER TABLE drivers
ADD CONSTRAINT chk_driver_status
CHECK (
    status IN (
        'active',
        'inactive'
    )
);


-- ============================================
-- تعديلات على جدول vehicles
-- حالة المركبة
-- ============================================

ALTER TABLE vehicles
ADD CONSTRAINT chk_vehicle_status
CHECK (
    status IN (
        'available',
        'in_delivery',
        'maintenance',
        'inactive'
    )
);


-- ============================================
-- تعديلات على جدول shipments
-- ============================================

-- حالة الدفع
ALTER TABLE shipments
ADD CONSTRAINT chk_shipment_payment_status
CHECK (
    payment_status IN (
        'pending',
        'paid',
        'refunded'
    )
);


-- حالة الشحنة
ALTER TABLE shipments
ADD CONSTRAINT chk_shipment_status
CHECK (
    shipment_status IN (
        'created',
        'received',
        'in_transit',
        'out_for_delivery',
        'delivered',
        'cancelled',
        'returned'
    )
);


-- ============================================
-- تعديلات على جدول payments
-- ============================================

-- طريقة الدفع
ALTER TABLE payments
ADD CONSTRAINT chk_payment_method
CHECK (
    payment_method IN (
        'cash',
        'card',
        'pix',
        'bank_transfer'
    )
);


-- حالة الدفع
ALTER TABLE payments
ADD CONSTRAINT chk_payment_status
CHECK (
    status IN (
        'successful',
        'failed',
        'refunded'
    )
);

-- ============================================
-----ادخال بيانات 5 فروع لجدول ال branches
-- ============================================

INSERT INTO branches
(branch_name, city, address, phone, manager_name, opened_at, status)
VALUES
('Kayseri Central', 'Kayseri', 'Melikgazi, Cumhuriyet Mah.', '03522000001', 'Ahmad Hassan', '2022-03-15', 'active'),
('Istanbul Main', 'Istanbul', 'Kadikoy, Istanbul', '02162000002', 'Sara Omar', '2021-06-10', 'active'),
('Ankara Branch', 'Ankara', 'Cankaya, Ankara', '03122000003', 'Omar Khaled', '2023-01-20', 'active'),
('Izmir Branch', 'Izmir', 'Konak, Izmir', '02322000004', 'Lina Hassan', '2022-09-05', 'active'),
('Bursa Branch', 'Bursa', 'Nilufer, Bursa', '02242000005', 'Yusuf Kaya', '2024-02-12', 'active');




-- ============================================
--  customers ادخال بيانات 25 عميل لجدول العملاء 
-- ============================================
INSERT INTO customers
(full_name, email, phone, customer_type, city, address, registered_at, status)
VALUES
('Ahmad Hassan', 'ahmad.hassan@gmail.com', '0501000001', 'individual', 'Kayseri', 'Melikgazi', '2026-01-05', 'active'),
('Sara Omar', 'sara.omar@gmail.com', '0501000002', 'individual', 'Istanbul', 'Kadikoy', '2026-01-07', 'active'),
('Omar Khaled', 'omar.khaled@gmail.com', NULL, 'individual', 'Ankara', 'Cankaya', '2026-01-10', 'active'),
('Lina Hassan', 'lina.hassan@gmail.com', '0501000004', 'individual', 'Izmir', 'Konak', '2026-01-12', 'active'),
('Yusuf Kaya', 'yusuf.kaya@gmail.com', NULL, 'individual', 'Bursa', 'Nilufer', '2026-01-15', 'active'),

('Maya Smith', 'maya.smith@gmail.com', '0501000006', 'individual', 'Kayseri', 'Kocasinan', '2026-01-18', 'active'),
('Adam Brown', 'adam.brown@gmail.com', '0501000007', 'individual', 'Istanbul', 'Besiktas', '2026-01-20', 'active'),
('Nora Ali', 'nora.ali@gmail.com', NULL, 'individual', 'Ankara', 'Yenimahalle', '2026-01-22', 'active'),
('Daniel Wilson', 'daniel.wilson@gmail.com', '0501000009', 'individual', 'Izmir', 'Bornova', '2026-01-25', 'inactive'),
('Emma Davis', 'emma.davis@gmail.com', '0501000010', 'individual', 'Bursa', 'Osmangazi', '2026-01-27', 'active'),

('TechNova Ltd', 'contact@technova.com', '0502000001', 'business', 'Kayseri', 'Organize Sanayi', '2026-02-01', 'active'),
('Anatolia Foods', 'info@anatoliafoods.com', '0502000002', 'business', 'Ankara', 'Cankaya', '2026-02-03', 'active'),
('BlueLine Trading', 'info@blueline.com', NULL, 'business', 'Istanbul', 'Atasehir', '2026-02-05', 'active'),
('Green Market', 'contact@greenmarket.com', '0502000004', 'business', 'Izmir', 'Konak', '2026-02-08', 'active'),
('Bursa Textile', 'info@bursatextile.com', '0502000005', 'business', 'Bursa', 'Nilufer', '2026-02-10', 'inactive'),

('Kayseri Electronics', 'info@kayserielectronics.com', '0502000006', 'business', 'Kayseri', 'Melikgazi', '2026-02-12', 'active'),
('Istanbul Furniture', 'info@istanbulfurniture.com', '0502000007', 'business', 'Istanbul', 'Umraniye', '2026-02-15', 'active'),
('Capital Office', 'contact@capitaloffice.com', NULL, 'business', 'Ankara', 'Cankaya', '2026-02-18', 'active'),
('Aegean Textiles', 'info@aegeantextiles.com', '0502000009', 'business', 'Izmir', 'Bornova', '2026-02-20', 'blocked'),
('Marmara Logistics', 'info@marmaralogistics.com', '0502000010', 'business', 'Bursa', 'Osmangazi', '2026-02-22', 'active'),

('Huda Ahmed', 'huda.ahmed@gmail.com', '0501000021', 'individual', 'Kayseri', 'Talas', '2026-02-25', 'active'),
('Karim Saleh', 'karim.saleh@gmail.com', NULL, 'individual', 'Ankara', 'Etimesgut', '2026-02-27', 'active'),
('Fatima Noor', 'fatima.noor@gmail.com', '0501000023', 'individual', 'Istanbul', 'Uskudar', '2026-03-01', 'active'),
('James Taylor', 'james.taylor@gmail.com', '0501000024', 'individual', 'Izmir', 'Karsiyaka', '2026-03-03', 'inactive'),
('Mary Johnson', 'mary.johnson@gmail.com', '0501000025', 'individual', 'Bursa', 'Nilufer', '2026-03-05', 'active');






-- ============================================
-- ادخال بيانات 20 موظف لجدول الموظفين  employees
-- ============================================
INSERT INTO employees
(branch_id, full_name, email, phone, job_title, salary, hire_date, status)
VALUES
(1, 'Mehmet Yilmaz', 'mehmet.yilmaz@logistics.com', '0503000001', 'Branch Clerk', 28000, '2023-02-10', 'active'),
(1, 'Ayse Demir', 'ayse.demir@logistics.com', '0503000002', 'Customer Service', 30000, '2023-05-15', 'active'),
(1, 'Hasan Kaya', 'hasan.kaya@logistics.com', '0503000003', 'Operations Officer', 35000, '2024-01-20', 'active'),
(1, 'Zeynep Acar', 'zeynep.acar@logistics.com', '0503000004', 'Accountant', 38000, '2022-09-12', 'active'),

(2, 'Ali Demir', 'ali.demir@logistics.com', '0503000005', 'Branch Clerk', 29000, '2023-03-18', 'active'),
(2, 'Elif Kaya', 'elif.kaya@logistics.com', '0503000006', 'Customer Service', 31000, '2023-07-22', 'active'),
(2, 'Murat Ozkan', 'murat.ozkan@logistics.com', '0503000007', 'Operations Officer', 36000, '2024-02-14', 'active'),
(2, 'Selin Arslan', 'selin.arslan@logistics.com', '0503000008', 'Branch Manager', 48000, '2021-11-05', 'active'),

(3, 'Emre Yildiz', 'emre.yildiz@logistics.com', '0503000009', 'Branch Clerk', 27500, '2024-03-10', 'active'),
(3, 'Derya Sahin', 'derya.sahin@logistics.com', '0503000010', 'Customer Service', 30500, '2023-08-17', 'active'),
(3, 'Burak Celik', 'burak.celik@logistics.com', '0503000011', 'Operations Officer', 37000, '2022-12-01', 'active'),
(3, 'Nesrin Kurt', 'nesrin.kurt@logistics.com', '0503000012', 'Accountant', 39000, '2023-06-25', 'inactive'),

(4, 'Can Erdem', 'can.erdem@logistics.com', '0503000013', 'Branch Clerk', 28500, '2024-01-05', 'active'),
(4, 'Ece Gunes', 'ece.gunes@logistics.com', '0503000014', 'Customer Service', 32000, '2023-04-11', 'active'),
(4, 'Kerem Aslan', 'kerem.aslan@logistics.com', '0503000015', 'Operations Officer', 35500, '2022-10-19', 'active'),
(4, 'Sibel Tas', 'sibel.tas@logistics.com', '0503000016', 'Branch Manager', 47000, '2022-02-08', 'active'),

(5, 'Okan Polat', 'okan.polat@logistics.com', '0503000017', 'Branch Clerk', 28000, '2024-05-12', 'active'),
(5, 'Buse Cakir', 'buse.cakir@logistics.com', '0503000018', 'Customer Service', 31500, '2023-09-20', 'active'),
(5, 'Tolga Koc', 'tolga.koc@logistics.com', '0503000019', 'Operations Officer', 36500, '2022-07-14', 'active'),
(5, 'Esra Yalcin', 'esra.yalcin@logistics.com', '0503000020', 'Accountant', 40000, '2023-01-30', 'active');


-- ============================================
-- ادخال بيانات 12 سائق لجول السائقين drivers
-- ============================================
INSERT INTO drivers
(branch_id, full_name, phone, license_number, license_expiry_date, hire_date, salary, status)
VALUES
(1, 'Ahmad Yasin', '0504000001', 'LIC-KS-1001', '2028-05-20', '2023-03-10', 38000, 'active'),
(1, 'Mustafa Ali', '0504000002', 'LIC-KS-1002', '2027-11-15', '2024-01-12', 36000, 'active'),
(1, 'Hakan Demir', '0504000003', 'LIC-KS-1003', '2029-02-18', '2022-08-05', 40000, 'active'),

(2, 'Mehmet Arslan', '0504000004', 'LIC-IST-1004', '2028-09-10', '2023-05-22', 39000, 'active'),
(2, 'Serkan Kaya', '0504000005', 'LIC-IST-1005', '2027-12-30', '2024-02-15', 37000, 'active'),
(2, 'Cem Ozkan', '0504000006', 'LIC-IST-1006', '2029-06-12', '2022-11-20', 42000, 'active'),

(3, 'Burak Yilmaz', '0504000007', 'LIC-ANK-1007', '2028-03-25', '2023-07-18', 38500, 'active'),
(3, 'Eren Sahin', '0504000008', 'LIC-ANK-1008', '2027-10-05', '2024-03-01', 35500, 'active'),

(4, 'Kaan Celik', '0504000009', 'LIC-IZM-1009', '2029-01-15', '2022-09-10', 41000, 'active'),
(4, 'Mert Acar', '0504000010', 'LIC-IZM-1010', '2028-07-22', '2023-12-05', 37500, 'active'),

(5, 'Ozan Kaya', '0504000011', 'LIC-BRS-1011', '2027-09-18', '2024-01-25', 36500, 'active'),
(5, 'Emir Tas', '0504000012', 'LIC-BRS-1012', '2029-04-30', '2023-06-14', 39500, 'active');




-- ============================================
-- ادخال بيانات 10 مركبات لجدول المركبات vehicles--
-- ============================================
INSERT INTO vehicles
(branch_id, plate_number, vehicle_type, model, manufacture_year, max_weight, status)
VALUES
(1, '38 ABC 101', 'Van', 'Ford Transit', 2022, 1500, 'available'),
(1, '38 ABC 102', 'Truck', 'Mercedes Atego', 2021, 5000, 'available'),

(2, '34 XYZ 201', 'Van', 'Fiat Ducato', 2023, 1800, 'available'),
(2, '34 XYZ 202', 'Truck', 'Isuzu NPR', 2020, 4500, 'maintenance'),

(3, '06 DEF 301', 'Van', 'Ford Transit', 2022, 1500, 'available'),
(3, '06 DEF 302', 'Truck', 'Mercedes Atego', 2023, 6000, 'available'),

(4, '35 GHI 401', 'Van', 'Renault Master', 2021, 1700, 'available'),
(4, '35 GHI 402', 'Truck', 'Isuzu NPR', 2022, 4000, 'available'),

(5, '16 JKL 501', 'Van', 'Fiat Ducato', 2023, 1800, 'available'),
(5, '16 JKL 502', 'Truck', 'Ford Cargo', 2020, 5500, 'inactive');





-- ============================================
--- ادخال 10 بيانات لجدول الشحنات shipments---
-- ============================================
INSERT INTO shipments
(
    tracking_number,
    customer_id,
    origin_branch_id,
    destination_branch_id,
    sender_name,
    sender_phone,
    receiver_name,
    receiver_phone,
    receiver_address,
    receiver_city,
    weight,
    shipping_cost,
    created_at,
    expected_delivery_date,
    delivered_at,
    payment_status,
    shipment_status
)
VALUES
('TRK100001', 1, 1, 2, 'Ahmad Hassan', '0501000001', 'Sara Omar', '0505000001', 'Kadikoy', 'Istanbul', 2.5, 180, '2026-01-05 09:00:00', '2026-01-08', NULL, 'paid', 'in_transit'),

('TRK100002', 2, 2, 3, 'Sara Omar', '0501000002', 'Omar Khaled', '0505000002', 'Cankaya', 'Ankara', 5.0, 300, '2026-01-06 10:00:00', '2026-01-10', NULL, 'pending', 'received'),

('TRK100003', 3, 3, 1, 'Omar Khaled', '0501000003', 'Ahmad Hassan', '0505000003', 'Melikgazi', 'Kayseri', 1.5, 120, '2026-01-07 11:00:00', '2026-01-09', NULL, 'paid', 'out_for_delivery'),

('TRK100004', 4, 1, 4, 'Lina Hassan', '0501000004', 'Maya Smith', '0505000004', 'Konak', 'Izmir', 8.0, 450, '2026-01-08 09:30:00', '2026-01-12', NULL, 'paid', 'in_transit'),

('TRK100005', 5, 4, 5, 'Yusuf Kaya', '0501000005', 'Adam Brown', '0505000005', 'Nilufer', 'Bursa', 3.2, 220, '2026-01-09 12:00:00', '2026-01-13', NULL, 'pending', 'created'),

('TRK100006', 6, 5, 1, 'Maya Smith', '0501000006', 'Nora Ali', '0505000006', 'Talas', 'Kayseri', 12.0, 600, '2026-01-10 08:30:00', '2026-01-14', NULL, 'paid', 'received'),

('TRK100007', 7, 2, 4, 'Adam Brown', '0501000007', 'Daniel Wilson', '0505000007', 'Bornova', 'Izmir', 4.5, 275, '2026-01-11 14:00:00', '2026-01-15', NULL, 'paid', 'in_transit'),

('TRK100008', 8, 3, 5, 'Nora Ali', '0501000008', 'Emma Davis', '0505000008', 'Osmangazi', 'Bursa', 2.0, 150, '2026-01-12 09:00:00', '2026-01-16', NULL, 'pending', 'created'),

('TRK100009', 9, 4, 2, 'Daniel Wilson', '0501000009', 'TechNova Ltd', '0505000009', 'Atasehir', 'Istanbul', 15.0, 750, '2026-01-13 10:30:00', '2026-01-18', NULL, 'paid', 'in_transit'),

('TRK100010', 10, 5, 3, 'Emma Davis', '0501000010', 'Anatolia Foods', '0505000010', 'Cankaya', 'Ankara', 20.0, 900, '2026-01-14 13:00:00', NULL, NULL, 'pending', 'cancelled');



-- ============================================
--- ادخال 50 بيانات لجدول الشحنات shipments---
-- ============================================

INSERT INTO shipments
(
    tracking_number,
    customer_id,
    origin_branch_id,
    destination_branch_id,
    sender_name,
    sender_phone,
    receiver_name,
    receiver_phone,
    receiver_address,
    receiver_city,
    weight,
    shipping_cost,
    created_at,
    expected_delivery_date,
    delivered_at,
    payment_status,
    shipment_status
)
VALUES
('TRK100011', 11, 1, 2, 'TechNova Ltd', '0502000001', 'BlueLine Trading', '0506000001', 'Atasehir', 'Istanbul', 6.0, 350, '2026-01-15 09:00:00', '2026-01-19', NULL, 'paid', 'delivered'),

('TRK100012', 12, 2, 3, 'Anatolia Foods', '0502000002', 'Capital Office', '0506000002', 'Cankaya', 'Ankara', 10.0, 500, '2026-01-16 10:00:00', '2026-01-20', NULL, 'paid', 'delivered'),

('TRK100013', 13, 3, 4, 'BlueLine Trading', '0502000003', 'Green Market', '0506000003', 'Konak', 'Izmir', 7.5, 420, '2026-01-17 11:00:00', '2026-01-21', NULL, 'pending', 'in_transit'),

('TRK100014', 14, 4, 5, 'Green Market', '0502000004', 'Bursa Textile', '0506000004', 'Nilufer', 'Bursa', 9.0, 480, '2026-01-18 09:30:00', '2026-01-22', NULL, 'paid', 'delivered'),

('TRK100015', 15, 5, 1, 'Bursa Textile', '0502000005', 'Kayseri Electronics', '0506000005', 'Melikgazi', 'Kayseri', 14.0, 700, '2026-01-19 12:00:00', '2026-01-24', NULL, 'pending', 'returned'),

('TRK100016', 16, 1, 3, 'Kayseri Electronics', '0502000006', 'Marmara Logistics', '0506000006', 'Osmangazi', 'Bursa', 11.0, 580, '2026-01-20 08:30:00', '2026-01-25', NULL, 'paid', 'delivered'),

('TRK100017', 17, 2, 4, 'Istanbul Furniture', '0502000007', 'Aegean Textiles', '0506000007', 'Bornova', 'Izmir', 18.0, 850, '2026-01-21 14:00:00', '2026-01-26', NULL, 'paid', 'in_transit'),

('TRK100018', 18, 3, 5, 'Capital Office', '0502000008', 'Marmara Logistics', '0506000008', 'Nilufer', 'Bursa', 4.0, 240, '2026-01-22 09:00:00', '2026-01-27', NULL, 'pending', 'created'),

('TRK100019', 19, 4, 2, 'Aegean Textiles', '0502000009', 'Istanbul Furniture', '0506000009', 'Umraniye', 'Istanbul', 16.0, 800, '2026-01-23 10:30:00', '2026-01-28', NULL, 'paid', 'delivered'),

('TRK100020', 20, 5, 3, 'Marmara Logistics', '0502000010', 'Anatolia Foods', '0506000010', 'Cankaya', 'Ankara', 22.0, 950, '2026-01-24 13:00:00', '2026-01-29', NULL, 'pending', 'cancelled'),

('TRK100021', 21, 1, 4, 'Huda Ahmed', '0501000021', 'Green Market', '0506000021', 'Konak', 'Izmir', 3.5, 210, '2026-01-25 09:00:00', '2026-01-29', NULL, 'paid', 'delivered'),

('TRK100022', 22, 2, 5, 'Karim Saleh', '0501000022', 'Bursa Textile', '0506000022', 'Nilufer', 'Bursa', 5.5, 300, '2026-01-26 10:00:00', '2026-01-30', NULL, 'pending', 'in_transit'),

('TRK100023', 23, 3, 1, 'Fatima Noor', '0501000023', 'Ahmad Hassan', '0506000023', 'Talas', 'Kayseri', 2.5, 170, '2026-01-27 11:00:00', '2026-01-31', NULL, 'paid', 'delivered'),

('TRK100024', 24, 4, 2, 'James Taylor', '0501000024', 'Sara Omar', '0506000024', 'Kadikoy', 'Istanbul', 8.5, 460, '2026-01-28 12:00:00', '2026-02-02', NULL, 'paid', 'delivered'),

('TRK100025', 25, 5, 1, 'Mary Johnson', '0501000025', 'Ahmad Hassan', '0506000025', 'Melikgazi', 'Kayseri', 6.5, 330, '2026-01-29 13:00:00', '2026-02-03', NULL, 'pending', 'in_transit'),

('TRK100026', 1, 1, 3, 'Ahmad Hassan', '0501000001', 'Omar Khaled', '0506000026', 'Cankaya', 'Ankara', 4.5, 260, '2026-02-01 09:00:00', '2026-02-06', NULL, 'paid', 'delivered'),

('TRK100027', 2, 2, 4, 'Sara Omar', '0501000002', 'Maya Smith', '0506000027', 'Konak', 'Izmir', 9.5, 520, '2026-02-02 10:00:00', '2026-02-07', NULL, 'paid', 'delivered'),

('TRK100028', 3, 3, 5, 'Omar Khaled', '0501000003', 'Adam Brown', '0506000028', 'Nilufer', 'Bursa', 13.0, 650, '2026-02-03 11:00:00', '2026-02-08', NULL, 'pending', 'received'),

('TRK100029', 4, 4, 1, 'Lina Hassan', '0501000004', 'Nora Ali', '0506000029', 'Talas', 'Kayseri', 3.0, 190, '2026-02-04 09:30:00', '2026-02-09', NULL, 'paid', 'delivered'),

('TRK100030', 5, 5, 2, 'Yusuf Kaya', '0501000005', 'Daniel Wilson', '0506000030', 'Besiktas', 'Istanbul', 7.0, 390, '2026-02-05 12:00:00', '2026-02-10', NULL, 'pending', 'cancelled'),

('TRK100031', 6, 1, 5, 'Maya Smith', '0501000006', 'Emma Davis', '0506000031', 'Osmangazi', 'Bursa', 5.0, 280, '2026-02-06 08:30:00', '2026-02-11', NULL, 'paid', 'delivered'),

('TRK100032', 7, 2, 1, 'Adam Brown', '0501000007', 'Huda Ahmed', '0506000032', 'Talas', 'Kayseri', 2.0, 140, '2026-02-07 14:00:00', '2026-02-12', NULL, 'paid', 'delivered'),

('TRK100033', 8, 3, 2, 'Nora Ali', '0501000008', 'Karim Saleh', '0506000033', 'Cankaya', 'Ankara', 12.5, 620, '2026-02-08 09:00:00', '2026-02-13', NULL, 'pending', 'in_transit'),

('TRK100034', 9, 4, 3, 'Daniel Wilson', '0501000009', 'Fatima Noor', '0506000034', 'Cankaya', 'Ankara', 4.0, 230, '2026-02-09 10:30:00', '2026-02-14', NULL, 'paid', 'delivered'),

('TRK100035', 10, 5, 4, 'Emma Davis', '0501000010', 'James Taylor', '0506000035', 'Bornova', 'Izmir', 10.5, 550, '2026-02-10 13:00:00', '2026-02-15', NULL, 'paid', 'delivered'),

('TRK100036', 11, 1, 2, 'TechNova Ltd', '0502000001', 'Istanbul Furniture', '0506000036', 'Umraniye', 'Istanbul', 17.0, 820, '2026-02-11 09:00:00', '2026-02-16', NULL, 'pending', 'received'),

('TRK100037', 12, 2, 3, 'Anatolia Foods', '0502000002', 'Capital Office', '0506000037', 'Cankaya', 'Ankara', 6.0, 340, '2026-02-12 10:00:00', '2026-02-17', NULL, 'paid', 'delivered'),

('TRK100038', 13, 3, 4, 'BlueLine Trading', '0502000003', 'Green Market', '0506000038', 'Konak', 'Izmir', 8.0, 430, '2026-02-13 11:00:00', '2026-02-18', NULL, 'paid', 'delivered'),

('TRK100039', 14, 4, 5, 'Green Market', '0502000004', 'Bursa Textile', '0506000039', 'Nilufer', 'Bursa', 5.0, 290, '2026-02-14 09:30:00', '2026-02-19', NULL, 'pending', 'in_transit'),

('TRK100040', 15, 5, 1, 'Bursa Textile', '0502000005', 'Kayseri Electronics', '0506000040', 'Melikgazi', 'Kayseri', 19.0, 900, '2026-02-15 12:00:00', '2026-02-20', NULL, 'paid', 'delivered'),

('TRK100041', 16, 1, 3, 'Kayseri Electronics', '0502000006', 'Anatolia Foods', '0506000041', 'Cankaya', 'Ankara', 11.5, 570, '2026-02-16 08:30:00', '2026-02-21', NULL, 'pending', 'returned'),

('TRK100042', 17, 2, 5, 'Istanbul Furniture', '0502000007', 'Marmara Logistics', '0506000042', 'Nilufer', 'Bursa', 15.0, 730, '2026-02-17 14:00:00', '2026-02-22', NULL, 'paid', 'delivered'),

('TRK100043', 18, 3, 1, 'Capital Office', '0502000008', 'Ahmad Hassan', '0506000043', 'Melikgazi', 'Kayseri', 3.5, 200, '2026-02-18 09:00:00', '2026-02-23', NULL, 'paid', 'delivered'),

('TRK100044', 19, 4, 2, 'Aegean Textiles', '0502000009', 'Sara Omar', '0506000044', 'Kadikoy', 'Istanbul', 7.5, 410, '2026-02-19 10:30:00', '2026-02-24', NULL, 'pending', 'in_transit'),

('TRK100045', 20, 5, 3, 'Marmara Logistics', '0502000010', 'Omar Khaled', '0506000045', 'Cankaya', 'Ankara', 21.0, 980, '2026-02-20 13:00:00', '2026-02-25', NULL, 'paid', 'delivered'),

('TRK100046', 21, 1, 4, 'Huda Ahmed', '0501000021', 'Lina Hassan', '0506000046', 'Konak', 'Izmir', 2.5, 160, '2026-02-21 09:00:00', '2026-02-26', NULL, 'paid', 'delivered'),

('TRK100047', 22, 2, 5, 'Karim Saleh', '0501000022', 'Yusuf Kaya', '0506000047', 'Nilufer', 'Bursa', 6.5, 350, '2026-02-22 10:00:00', '2026-02-27', NULL, 'pending', 'created'),

('TRK100048', 23, 3, 2, 'Fatima Noor', '0501000023', 'Maya Smith', '0506000048', 'Kadikoy', 'Istanbul', 4.5, 270, '2026-02-23 11:00:00', '2026-02-28', NULL, 'paid', 'delivered'),

('TRK100049', 24, 4, 1, 'James Taylor', '0501000024', 'Nora Ali', '0506000049', 'Talas', 'Kayseri', 9.0, 480, '2026-02-24 12:00:00', '2026-03-01', NULL, 'paid', 'delivered'),

('TRK100050', 25, 5, 2, 'Mary Johnson', '0501000025', 'Adam Brown', '0506000050', 'Besiktas', 'Istanbul', 13.5, 670, '2026-02-25 13:00:00', '2026-03-02', NULL, 'pending', 'in_transit'),

('TRK100051', 1, 1, 5, 'Ahmad Hassan', '0501000001', 'Marmara Logistics', '0506000051', 'Osmangazi', 'Bursa', 18.0, 850, '2026-02-26 09:00:00', '2026-03-03', NULL, 'paid', 'delivered'),

('TRK100052', 2, 2, 3, 'Sara Omar', '0501000002', 'Anatolia Foods', '0506000052', 'Cankaya', 'Ankara', 5.0, 300, '2026-02-27 10:00:00', '2026-03-04', NULL, 'pending', 'in_transit'),

('TRK100053', 3, 3, 4, 'Omar Khaled', '0501000003', 'Green Market', '0506000053', 'Konak', 'Izmir', 7.0, 380, '2026-02-28 11:00:00', '2026-03-05', NULL, 'paid', 'delivered'),

('TRK100054', 4, 4, 5, 'Lina Hassan', '0501000004', 'Bursa Textile', '0506000054', 'Nilufer', 'Bursa', 10.0, 520, '2026-03-01 09:30:00', '2026-03-06', NULL, 'paid', 'delivered'),

('TRK100055', 5, 5, 1, 'Yusuf Kaya', '0501000005', 'Kayseri Electronics', '0506000055', 'Melikgazi', 'Kayseri', 14.5, 710, '2026-03-02 12:00:00', '2026-03-07', NULL, 'pending', 'cancelled'),

('TRK100056', 6, 1, 3, 'Maya Smith', '0501000006', 'Capital Office', '0506000056', 'Cankaya', 'Ankara', 8.5, 450, '2026-03-03 08:30:00', '2026-03-08', NULL, 'paid', 'delivered'),

('TRK100057', 7, 2, 4, 'Adam Brown', '0501000007', 'Aegean Textiles', '0506000057', 'Bornova', 'Izmir', 12.0, 620, '2026-03-04 14:00:00', '2026-03-09', NULL, 'pending', 'received'),

('TRK100058', 8, 3, 5, 'Nora Ali', '0501000008', 'Marmara Logistics', '0506000058', 'Nilufer', 'Bursa', 3.0, 190, '2026-03-05 09:00:00', '2026-03-10', NULL, 'paid', 'delivered'),

('TRK100059', 9, 4, 2, 'Daniel Wilson', '0501000009', 'Istanbul Furniture', '0506000059', 'Umraniye', 'Istanbul', 16.5, 780, '2026-03-06 10:30:00', '2026-03-11', NULL, 'pending', 'in_transit'),

('TRK100060', 10, 5, 4, 'Emma Davis', '0501000010', 'Green Market', '0506000060', 'Konak', 'Izmir', 20.0, 920, '2026-03-07 13:00:00', '2026-03-12', NULL, 'paid', 'delivered');

-- ============================================
-- ادخال بيانات 40 عملية توصيل لجدول ال deliveries----
-- ============================================
INSERT INTO deliveries
(
    shipment_id,
    driver_id,
    vehicle_id,
    assigned_at,
    started_at,
    completed_at,
    delivery_status,
    notes
)
VALUES
(11, 1, 1, '2026-01-15 10:00:00', '2026-01-15 11:00:00', '2026-01-16 15:00:00', 'completed', 'Delivered successfully'),
(12, 2, 2, '2026-01-16 11:00:00', '2026-01-16 12:00:00', '2026-01-17 16:00:00', 'completed', 'Delivered successfully'),
(14, 4, 3, '2026-01-18 10:00:00', '2026-01-18 11:00:00', '2026-01-19 14:00:00', 'completed', 'Delivered successfully'),
(16, 6, 5, '2026-01-20 09:00:00', '2026-01-20 10:00:00', '2026-01-21 13:00:00', 'completed', 'Delivered successfully'),
(19, 9, 7, '2026-01-23 11:00:00', '2026-01-23 12:00:00', '2026-01-24 17:00:00', 'completed', 'Delivered successfully'),
(21, 1, 1, '2026-01-25 10:00:00', '2026-01-25 11:00:00', '2026-01-26 15:00:00', 'completed', 'Delivered successfully'),
(23, 7, 5, '2026-01-27 12:00:00', '2026-01-27 13:00:00', '2026-01-28 16:00:00', 'completed', 'Delivered successfully'),
(24, 4, 3, '2026-01-28 13:00:00', '2026-01-28 14:00:00', '2026-01-29 15:00:00', 'completed', 'Delivered successfully'),

(26, 2, 2, '2026-02-01 10:00:00', '2026-02-01 11:00:00', '2026-02-02 16:00:00', 'completed', 'Delivered successfully'),
(27, 6, 6, '2026-02-02 11:00:00', '2026-02-02 12:00:00', '2026-02-03 15:00:00', 'completed', 'Delivered successfully'),
(29, 9, 7, '2026-02-04 10:00:00', '2026-02-04 11:00:00', '2026-02-05 14:00:00', 'completed', 'Delivered successfully'),
(31, 1, 1, '2026-02-06 09:00:00', '2026-02-06 10:00:00', '2026-02-07 15:00:00', 'completed', 'Delivered successfully'),
(32, 2, 2, '2026-02-07 15:00:00', '2026-02-07 16:00:00', '2026-02-08 14:00:00', 'completed', 'Delivered successfully'),
(34, 4, 3, '2026-02-09 11:00:00', '2026-02-09 12:00:00', '2026-02-10 16:00:00', 'completed', 'Delivered successfully'),
(35, 6, 6, '2026-02-10 14:00:00', '2026-02-10 15:00:00', '2026-02-11 17:00:00', 'completed', 'Delivered successfully'),
(37, 9, 7, '2026-02-12 11:00:00', '2026-02-12 12:00:00', '2026-02-13 16:00:00', 'completed', 'Delivered successfully'),

(38, 1, 1, '2026-02-13 12:00:00', '2026-02-13 13:00:00', '2026-02-14 15:00:00', 'completed', 'Delivered successfully'),
(40, 4, 3, '2026-02-15 13:00:00', '2026-02-15 14:00:00', '2026-02-16 17:00:00', 'completed', 'Delivered successfully'),
(42, 6, 5, '2026-02-17 11:00:00', '2026-02-17 12:00:00', '2026-02-18 16:00:00', 'completed', 'Delivered successfully'),
(43, 9, 7, '2026-02-18 10:00:00', '2026-02-18 11:00:00', '2026-02-19 15:00:00', 'completed', 'Delivered successfully'),
(45, 2, 2, '2026-02-20 14:00:00', '2026-02-20 15:00:00', '2026-02-21 16:00:00', 'completed', 'Delivered successfully'),
(46, 4, 3, '2026-02-21 10:00:00', '2026-02-21 11:00:00', '2026-02-22 15:00:00', 'completed', 'Delivered successfully'),
(48, 6, 5, '2026-02-23 12:00:00', '2026-02-23 13:00:00', '2026-02-24 16:00:00', 'completed', 'Delivered successfully'),
(49, 9, 7, '2026-02-24 13:00:00', '2026-02-24 14:00:00', '2026-02-25 17:00:00', 'completed', 'Delivered successfully'),

(51, 1, 1, '2026-02-26 10:00:00', '2026-02-26 11:00:00', '2026-02-27 15:00:00', 'completed', 'Delivered successfully'),
(53, 2, 2, '2026-02-28 12:00:00', '2026-02-28 13:00:00', '2026-03-01 16:00:00', 'completed', 'Delivered successfully'),
(54, 4, 3, '2026-03-01 10:00:00', '2026-03-01 11:00:00', '2026-03-02 15:00:00', 'completed', 'Delivered successfully'),
(56, 6, 5, '2026-03-03 10:00:00', '2026-03-03 11:00:00', '2026-03-04 16:00:00', 'completed', 'Delivered successfully'),
(58, 9, 7, '2026-03-05 10:00:00', '2026-03-05 11:00:00', '2026-03-06 15:00:00', 'completed', 'Delivered successfully'),
(60, 1, 1, '2026-03-07 14:00:00', '2026-03-07 15:00:00', '2026-03-08 16:00:00', 'completed', 'Delivered successfully'),

(13, 3, 4, '2026-01-17 12:00:00', '2026-01-17 13:00:00', NULL, 'in_progress', 'Delivery in progress'),
(17, 5, 6, '2026-01-21 15:00:00', '2026-01-21 16:00:00', NULL, 'in_progress', 'Currently in transit'),
(22, 8, 8, '2026-01-26 11:00:00', NULL, NULL, 'assigned', 'Waiting to start'),
(28, 3, 4, '2026-02-03 13:00:00', '2026-02-03 14:00:00', NULL, 'in_progress', 'Delivery in progress'),
(33, 7, 5, '2026-02-08 12:00:00', NULL, NULL, 'assigned', 'Waiting for driver'),
(36, 10, 9, '2026-02-11 11:00:00', '2026-02-11 12:00:00', NULL, 'in_progress', 'Delivery in progress'),
(39, 5, 6, '2026-02-14 12:00:00', NULL, NULL, 'cancelled', 'Customer cancelled delivery'),
(44, 8, 8, '2026-02-19 12:00:00', NULL, NULL, 'failed', 'Receiver unavailable'),
(47, 10, 9, '2026-02-22 13:00:00', '2026-02-22 14:00:00', NULL, 'in_progress', 'Delivery in progress'),
(50, 3, 4, '2026-02-25 11:00:00', NULL, NULL, 'assigned', 'Waiting to start');


-- ============================================
--shipment_tracking ادخال بيانات 20 سجل تتبع الشحنات لجدول 
-- ============================================
INSERT INTO shipment_tracking
(shipment_id, branch_id, status, description, recorded_at)
VALUES
(1, 1, 'created', 'Shipment created at origin branch', '2026-01-05 09:05:00'),
(1, 1, 'in_transit', 'Shipment left origin branch', '2026-01-05 14:00:00'),

(2, 2, 'created', 'Shipment created at origin branch', '2026-01-06 10:05:00'),
(2, 2, 'received', 'Shipment received at origin branch', '2026-01-06 13:00:00'),

(3, 3, 'created', 'Shipment created at origin branch', '2026-01-07 11:05:00'),
(3, 1, 'out_for_delivery', 'Shipment is out for delivery', '2026-01-08 09:00:00'),

(4, 1, 'created', 'Shipment created at origin branch', '2026-01-08 09:35:00'),
(4, 1, 'in_transit', 'Shipment left origin branch', '2026-01-08 15:00:00'),

(5, 4, 'created', 'Shipment created at origin branch', '2026-01-09 12:05:00'),
(5, 4, 'created', 'Shipment is waiting for processing', '2026-01-09 15:00:00'),

(6, 5, 'created', 'Shipment created at origin branch', '2026-01-10 08:35:00'),
(6, 5, 'received', 'Shipment received and registered', '2026-01-10 12:00:00'),

(7, 2, 'created', 'Shipment created at origin branch', '2026-01-11 14:05:00'),
(7, 2, 'in_transit', 'Shipment departed from branch', '2026-01-12 08:00:00'),

(8, 3, 'created', 'Shipment created at origin branch', '2026-01-12 09:05:00'),
(8, 3, 'created', 'Shipment waiting for processing', '2026-01-12 13:00:00'),

(9, 4, 'created', 'Shipment created at origin branch', '2026-01-13 10:35:00'),
(9, 4, 'in_transit', 'Shipment departed from origin branch', '2026-01-13 16:00:00'),

(10, 5, 'created', 'Shipment created at origin branch', '2026-01-14 13:05:00'),
(10, 5, 'cancelled', 'Shipment cancelled by customer', '2026-01-15 10:00:00');

-- ============================================
--shipment_tracking ادخال بيانات 100 سجل تتبع الشحنات لجدول 
-- ============================================

INSERT INTO shipment_tracking
(shipment_id, branch_id, status, description, recorded_at)
VALUES
(11,1,'created','Shipment created','2026-01-15 09:05:00'),
(11,2,'delivered','Shipment delivered successfully','2026-01-16 15:00:00'),

(12,2,'created','Shipment created','2026-01-16 10:05:00'),
(12,3,'delivered','Shipment delivered successfully','2026-01-17 16:00:00'),

(13,3,'created','Shipment created','2026-01-17 11:05:00'),
(13,4,'in_transit','Shipment in transit','2026-01-18 09:00:00'),

(14,4,'created','Shipment created','2026-01-18 09:35:00'),
(14,5,'delivered','Shipment delivered successfully','2026-01-19 14:00:00'),

(15,5,'created','Shipment created','2026-01-19 12:05:00'),
(15,5,'returned','Shipment returned to sender','2026-01-21 15:00:00'),

(16,1,'created','Shipment created','2026-01-20 08:35:00'),
(16,3,'delivered','Shipment delivered successfully','2026-01-21 13:00:00'),

(17,2,'created','Shipment created','2026-01-21 14:05:00'),
(17,4,'in_transit','Shipment in transit','2026-01-22 10:00:00'),

(18,3,'created','Shipment created','Shipment created and waiting','2026-01-22 09:05:00'),
(18,3,'created','Shipment waiting for processing','2026-01-23 11:00:00'),

(19,4,'created','Shipment created','2026-01-23 10:35:00'),
(19,2,'delivered','Shipment delivered successfully','2026-01-24 17:00:00'),

(20,5,'created','Shipment created','2026-01-24 13:05:00'),
(20,5,'cancelled','Shipment cancelled','2026-01-25 10:00:00'),

(21,1,'created','Shipment created','2026-01-25 09:05:00'),
(21,4,'delivered','Shipment delivered successfully','2026-01-26 15:00:00'),

(22,2,'created','Shipment created','2026-01-26 10:05:00'),
(22,5,'in_transit','Shipment in transit','2026-01-27 09:00:00'),

(23,3,'created','Shipment created','2026-01-27 11:05:00'),
(23,1,'delivered','Shipment delivered successfully','2026-01-28 16:00:00'),

(24,4,'created','Shipment created','2026-01-28 12:05:00'),
(24,2,'delivered','Shipment delivered successfully','2026-01-29 15:00:00'),

(25,5,'created','Shipment created','2026-01-29 13:05:00'),
(25,1,'in_transit','Shipment in transit','2026-01-30 10:00:00'),

(26,1,'created','Shipment created','2026-02-01 09:05:00'),
(26,3,'delivered','Shipment delivered successfully','2026-02-02 16:00:00'),

(27,2,'created','Shipment created','2026-02-02 10:05:00'),
(27,4,'delivered','Shipment delivered successfully','2026-02-03 15:00:00'),

(28,3,'created','Shipment created','2026-02-03 11:05:00'),
(28,5,'received','Shipment received at destination branch','2026-02-04 10:00:00'),

(29,4,'created','Shipment created','2026-02-04 09:35:00'),
(29,1,'delivered','Shipment delivered successfully','2026-02-05 14:00:00'),

(30,5,'created','Shipment created','2026-02-05 12:05:00'),
(30,5,'cancelled','Shipment cancelled','2026-02-06 09:00:00'),

(31,1,'created','Shipment created','2026-02-06 08:35:00'),
(31,5,'delivered','Shipment delivered successfully','2026-02-07 15:00:00'),

(32,2,'created','Shipment created','2026-02-07 14:05:00'),
(32,1,'delivered','Shipment delivered successfully','2026-02-08 14:00:00'),

(33,3,'created','Shipment created','2026-02-08 09:05:00'),
(33,2,'in_transit','Shipment in transit','2026-02-09 11:00:00'),

(34,4,'created','Shipment created','2026-02-09 10:35:00'),
(34,3,'delivered','Shipment delivered successfully','2026-02-10 16:00:00'),

(35,5,'created','Shipment created','2026-02-10 13:05:00'),
(35,4,'delivered','Shipment delivered successfully','2026-02-11 17:00:00'),

(36,1,'created','Shipment created','2026-02-11 09:05:00'),
(36,3,'received','Shipment received at destination branch','2026-02-12 10:00:00'),

(37,2,'created','Shipment created','2026-02-12 10:05:00'),
(37,3,'delivered','Shipment delivered successfully','2026-02-13 16:00:00'),

(38,3,'created','Shipment created','2026-02-13 11:05:00'),
(38,4,'delivered','Shipment delivered successfully','2026-02-14 15:00:00'),

(39,4,'created','Shipment created','2026-02-14 09:35:00'),
(39,5,'in_transit','Shipment in transit','2026-02-15 10:00:00'),

(40,5,'created','Shipment created','2026-02-15 12:05:00'),
(40,1,'delivered','Shipment delivered successfully','2026-02-16 17:00:00'),

(41,1,'created','Shipment created','2026-02-16 08:35:00'),
(41,3,'returned','Shipment returned to sender','2026-02-18 16:00:00'),

(42,2,'created','Shipment created','2026-02-17 14:05:00'),
(42,5,'delivered','Shipment delivered successfully','2026-02-18 16:00:00'),

(43,3,'created','Shipment created','2026-02-18 09:05:00'),
(43,1,'delivered','Shipment delivered successfully','2026-02-19 15:00:00'),

(44,4,'created','Shipment created','2026-02-19 10:35:00'),
(44,2,'in_transit','Shipment in transit','2026-02-20 11:00:00'),

(45,5,'created','Shipment created','2026-02-20 13:05:00'),
(45,3,'delivered','Shipment delivered successfully','2026-02-21 16:00:00'),

(46,1,'created','Shipment created','2026-02-21 09:05:00'),
(46,4,'delivered','Shipment delivered successfully','2026-02-22 15:00:00'),

(47,2,'created','Shipment created','2026-02-22 10:05:00'),
(47,5,'created','Shipment waiting for processing','2026-02-23 11:00:00'),

(48,3,'created','Shipment created','2026-02-23 11:05:00'),
(48,2,'delivered','Shipment delivered successfully','2026-02-24 16:00:00'),

(49,4,'created','Shipment created','2026-02-24 12:05:00'),
(49,1,'delivered','Shipment delivered successfully','2026-02-25 17:00:00'),

(50,5,'created','Shipment created','2026-02-25 13:05:00'),
(50,2,'in_transit','Shipment in transit','2026-02-26 10:00:00'),

(51,1,'created','Shipment created','2026-02-26 09:05:00'),
(51,5,'delivered','Shipment delivered successfully','2026-02-27 15:00:00'),

(52,2,'created','Shipment created','2026-02-27 10:05:00'),
(52,3,'in_transit','Shipment in transit','2026-02-28 10:00:00'),

(53,3,'created','Shipment created','2026-02-28 11:05:00'),
(53,4,'delivered','Shipment delivered successfully','2026-03-01 16:00:00'),

(54,4,'created','Shipment created','2026-03-01 09:35:00'),
(54,5,'delivered','Shipment delivered successfully','2026-03-02 15:00:00'),

(55,5,'created','Shipment created','2026-03-02 12:05:00'),
(55,5,'cancelled','Shipment cancelled','2026-03-03 09:00:00'),

(56,1,'created','Shipment created','2026-03-03 08:35:00'),
(56,3,'delivered','Shipment delivered successfully','2026-03-04 16:00:00'),

(57,2,'created','Shipment created','2026-03-04 14:05:00'),
(57,4,'received','Shipment received at destination branch','2026-03-05 10:00:00'),

(58,3,'created','Shipment created','2026-03-05 09:05:00'),
(58,5,'delivered','Shipment delivered successfully','2026-03-06 15:00:00'),

(59,4,'created','Shipment created','2026-03-06 10:35:00'),
(59,2,'in_transit','Shipment in transit','2026-03-07 09:00:00'),

(60,5,'created','Shipment created','2026-03-07 13:05:00'),
(60,4,'delivered','Shipment delivered successfully','2026-03-08 16:00:00');
-- ============================================
--   40 دفعة لجدول ال payments ادخال---
-- ============================================

INSERT INTO payments
(shipment_id, amount, payment_method, payment_date, transaction_reference, status)
VALUES

(1,150.00,'card','2026-01-05 10:00:00','TXN100001','successful'),
(2,220.00,'cash','2026-01-06 11:00:00','TXN100002','successful'),
(3,180.00,'bank_transfer','2026-01-07 09:30:00','TXN100003','successful'),
(4,350.00,'card','2026-01-08 12:00:00','TXN100004','successful'),
(5,125.00,'cash','2026-01-09 14:00:00','TXN100005','successful'),

(6,275.00,'pix','2026-01-10 10:15:00','TXN100006','successful'),
(7,410.00,'card','2026-01-11 13:00:00','TXN100007','successful'),
(8,195.00,'cash','2026-01-12 15:00:00','TXN100008','successful'),
(9,320.00,'bank_transfer','2026-01-13 09:45:00','TXN100009','successful'),
(10,150.00,'card','2026-01-14 11:30:00','TXN100010','successful'),

(11,285.00,'cash','2026-01-16 10:00:00','TXN100011','successful'),
(12,375.00,'card','2026-01-17 12:30:00','TXN100012','successful'),
(13,210.00,'pix','2026-01-18 14:00:00','TXN100013','successful'),
(14,450.00,'bank_transfer','2026-01-19 10:30:00','TXN100014','successful'),
(15,175.00,'cash','2026-01-20 13:15:00','TXN100015','successful'),

(16,290.00,'card','2026-01-21 09:30:00','TXN100016','successful'),
(17,330.00,'pix','2026-01-22 11:00:00','TXN100017','successful'),
(18,260.00,'cash','2026-01-23 14:30:00','TXN100018','successful'),
(19,520.00,'card','2026-01-24 16:00:00','TXN100019','successful'),
(20,195.00,'bank_transfer','2026-01-25 10:15:00','TXN100020','successful'),

(21,240.00,'cash','2026-01-26 11:30:00','TXN100021','successful'),
(22,310.00,'card','2026-01-27 13:00:00','TXN100022','successful'),
(23,275.00,'pix','2026-01-28 09:45:00','TXN100023','successful'),
(24,390.00,'bank_transfer','2026-01-29 12:00:00','TXN100024','successful'),
(25,160.00,'cash','2026-01-30 15:00:00','TXN100025','successful'),

(26,285.00,'card','2026-02-02 10:30:00','TXN100026','successful'),
(27,340.00,'pix','2026-02-03 11:45:00','TXN100027','successful'),
(28,225.00,'cash','2026-02-04 13:30:00','TXN100028','successful'),
(29,470.00,'card','2026-02-05 15:15:00','TXN100029','successful'),
(30,180.00,'bank_transfer','2026-02-06 09:30:00','TXN100030','successful'),

(31,300.00,'cash','2026-02-07 10:00:00','TXN100031','successful'),
(32,260.00,'card','2026-02-08 12:15:00','TXN100032','successful'),
(33,350.00,'pix','2026-02-09 14:00:00','TXN100033','failed'),
(34,420.00,'bank_transfer','2026-02-10 16:00:00','TXN100034','successful'),
(35,200.00,'cash','2026-02-11 10:30:00','TXN100035','failed'),

(36,275.00,'card','2026-02-12 11:45:00','TXN100036','successful'),
(37,315.00,'pix','2026-02-13 13:15:00','TXN100037','refunded'),
(38,450.00,'bank_transfer','2026-02-14 15:00:00','TXN100038','successful'),
(39,190.00,'cash','2026-02-15 09:30:00','TXN100039','failed'),
(40,500.00,'card','2026-02-16 12:00:00','TXN100040','successful');


-- ============================================
---- views----
-- ============================================

-- ============================================
-- 1 . active_shipments_view---
-- ============================================
CREATE VIEW active_shipments_view AS
SELECT
    s.id,
    s.tracking_number,
    c.full_name AS customer_name,
    ob.branch_name AS origin_branch,
    db.branch_name AS destination_branch,
    s.sender_name,
    s.receiver_name,
    s.receiver_city,
    s.weight,
    s.shipping_cost,
    s.created_at,
    s.expected_delivery_date,
    s.payment_status,
    s.shipment_status
FROM shipments s
JOIN customers c
    ON s.customer_id = c.id
JOIN branches ob
    ON s.origin_branch_id = ob.id
JOIN branches db
    ON s.destination_branch_id = db.id
WHERE s.shipment_status NOT IN ('delivered', 'cancelled', 'returned');

-- ============================================
---2 . driver_performance_view---
-- ============================================
CREATE VIEW driver_performance_view AS
SELECT
    d.id AS driver_id,
    d.full_name AS driver_name,

    COUNT(del.id) AS total_deliveries,

    (
        SELECT COUNT(*)
        FROM deliveries d2
        WHERE d2.driver_id = d.id
        AND d2.delivery_status = 'completed'
    ) AS successful_deliveries,

    (
        SELECT COUNT(*)
        FROM deliveries d3
        WHERE d3.driver_id = d.id
        AND d3.delivery_status <> 'completed'
    ) AS unsuccessful_deliveries,

    (
        SELECT SUM(s.shipping_cost)
        FROM deliveries d4
        JOIN shipments s
            ON d4.shipment_id = s.id
        WHERE d4.driver_id = d.id
    ) AS total_shipment_value,

    (
        SELECT MAX(d5.completed_at)
        FROM deliveries d5
        WHERE d5.driver_id = d.id
    ) AS last_delivery

FROM drivers d

LEFT JOIN deliveries del
    ON d.id = del.driver_id

GROUP BY
    d.id,
    d.full_name;
-- ============================================
--3 . customer_statistics_view---
-- ============================================
CREATE VIEW customer_statistics_view AS
SELECT
    c.id AS customer_id,
    c.full_name AS customer_name,
    c.email,
    c.phone,
    c.customer_type,
    c.city,

    COUNT(s.id) AS shipment_count,

    SUM(s.shipping_cost) AS total_shipping_cost,

    (
        SELECT COUNT(*)
        FROM shipments s2
        WHERE s2.customer_id = c.id
        AND s2.shipment_status = 'delivered'
    ) AS completed_shipments,

    (
        SELECT COUNT(*)
        FROM shipments s3
        WHERE s3.customer_id = c.id
        AND s3.shipment_status = 'cancelled'
    ) AS cancelled_shipments,

    (
        SELECT MAX(s4.created_at)
        FROM shipments s4
        WHERE s4.customer_id = c.id
    ) AS last_shipment

FROM customers c

LEFT JOIN shipments s
    ON c.id = s.customer_id

GROUP BY
    c.id,
    c.full_name,
    c.email,
    c.phone,
    c.customer_type,
    c.city;






