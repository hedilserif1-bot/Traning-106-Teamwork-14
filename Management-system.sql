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
-- ادخال بيانات 5 فروع لجدول ال branches
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
-- ادخال 10 بيانات لجدول الشحنات shipments
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
-- ادخال 50 بيانات لجدول الشحنات shipments
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
-- ادخال بيانات 40 عملية توصيل لجدول ال deliveries
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
-- shipment_tracking ادخال بيانات 20 سجل تتبع الشحنات لجدول 
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
-- shipment_tracking ادخال بيانات 100 سجل تتبع الشحنات لجدول 
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

(18,3,'created','Shipment created','2026-01-22 09:05:00'),
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
--   40 دفعة لجدول ال payments ادخال
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
-- VIEWS
-- ============================================

-- ============================================
-- 1. active_shipments_view
-- ============================================

CREATE OR REPLACE VIEW active_shipments_view AS
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
WHERE s.shipment_status NOT IN
    ('delivered', 'cancelled', 'returned');


-- ============================================
-- 2. driver_performance_view
-- ============================================

CREATE OR REPLACE VIEW driver_performance_view AS
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
-- 3. customer_statistics_view
-- ============================================

CREATE OR REPLACE VIEW customer_statistics_view AS
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


-- ============================================
-- INDEXES
-- ============================================


-- ============================================
-- 1. tracking_number
-- ============================================

-- tracking_number is already UNIQUE.
-- Therefore MySQL already has a UNIQUE INDEX on this column.
-- Creating another normal index would be redundant and unnecessary.

EXPLAIN
SELECT *
FROM shipments
WHERE tracking_number = 'TRK-100001';

-- Expected:
-- type = const
-- key = tracking_number
-- rows = 1

-- Conclusion:
-- The existing UNIQUE index is sufficient.
-- No additional index is required.


-- ============================================
-- 2. customer_id
-- ============================================

-- customer_id is a FOREIGN KEY.
-- In InnoDB, MySQL automatically creates an index
-- if a suitable index does not already exist.
-- Therefore, an additional index is unnecessary.

EXPLAIN
SELECT *
FROM shipments
WHERE customer_id = 1;

-- Expected:
-- type = ref
-- key = customer_id
-- rows = approximately the number of matching shipments

-- Conclusion:
-- The existing index is sufficient.
-- No additional index is required.


-- ============================================
-- 3. shipment_status
-- ============================================

CREATE INDEX idx_shipments_status
ON shipments(shipment_status);

EXPLAIN
SELECT *
FROM shipments
WHERE shipment_status = 'delivered';

-- Before Index:
-- type = ALL
-- key = NULL
-- rows = 60

-- After Index:
-- type = ref
-- key = idx_shipments_status
-- rows = approximately the number of matching rows

-- Conclusion:
-- The index can help MySQL locate shipments
-- with a specific status without scanning the entire table.


-- ============================================
-- 4. created_at
-- ============================================

CREATE INDEX idx_shipments_created_at
ON shipments(created_at);

EXPLAIN
SELECT *
FROM shipments
WHERE created_at >= '2026-02-01';

-- On a small table, MySQL may still choose:
-- type = ALL
-- key = NULL

-- This does NOT mean the index is broken.
-- MySQL may consider a full table scan cheaper
-- when the table is small or the condition matches many rows.

-- Conclusion:
-- The index can become useful as the table grows
-- or when the query filters a smaller range of dates.


-- ============================================
-- 5. expected_delivery_date
-- ============================================

CREATE INDEX idx_shipments_expected_delivery
ON shipments(expected_delivery_date);

EXPLAIN
SELECT *
FROM shipments
WHERE expected_delivery_date <= '2026-03-01';

-- MySQL may choose:
-- type = ALL
-- key = NULL
-- even though the index exists.

-- possible_keys may show:
-- idx_shipments_expected_delivery

-- Conclusion:
-- The index exists and is available,
-- but MySQL may choose a full table scan
-- if it estimates that it is more efficient.


-- ============================================
-- 6. driver_id
-- ============================================

-- driver_id is a FOREIGN KEY.
-- MySQL already has a suitable index for the FK
-- if one was not previously created.
-- Therefore, an additional index is unnecessary.

EXPLAIN
SELECT *
FROM deliveries
WHERE driver_id = 1;

-- Expected:
-- type = ref
-- key = driver_id

-- Conclusion:
-- The existing index is sufficient.
-- No additional index is required.


-- ============================================
-- 7. payment_date
-- ============================================

CREATE INDEX idx_payments_payment_date
ON payments(payment_date);

EXPLAIN
SELECT *
FROM payments
WHERE payment_date >= '2026-02-01';

-- On the current small table MySQL may choose:
-- type = ALL
-- key = NULL

-- Conclusion:
-- The index exists, but MySQL may prefer
-- a full table scan because the payments table is small.
-- The index can become more useful as the table grows
-- or when the query selects a smaller date range.


-- ============================================
-- WHEN CAN AN EXTRA INDEX BECOME USELESS OR COSTLY?
-- ============================================

-- An additional index may be unnecessary when:
-- 1. The column already has a UNIQUE index.
-- 2. The column is already indexed because of a FOREIGN KEY.
-- 3. Another existing index already supports the same query.
--
-- An index also has a cost:
-- 1. It consumes additional disk/storage space.
-- 2. INSERT operations become slightly more expensive.
-- 3. UPDATE operations become more expensive when indexed
--    columns are modified.
-- 4. DELETE operations also require index maintenance.
-- 5. Too many indexes can make the optimizer's choices
--    more complicated.
--
-- Therefore, indexes should be added based on real queries
-- and performance requirements, not simply added to every column.


-- ============================================
-- TRANSACTION
-- ============================================

-- A transaction groups multiple SQL operations
-- into one logical unit.

-- START TRANSACTION:
-- Starts the transaction.

-- COMMIT:
-- Permanently saves all changes.

-- ROLLBACK:
-- Cancels all changes made during the transaction.


-- ============================================
-- Example: Create Shipment + Tracking + Payment
-- ============================================

START TRANSACTION;


-- 1. Create a new shipment

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
    expected_delivery_date,
    payment_status,
    shipment_status
)
VALUES
(
    CONCAT('TRX-', UUID_SHORT()),
    1,
    1,
    2,
    'Ahmad Hassan',
    '0501000001',
    'Sara Omar',
    '0501000002',
    'Kadikoy, Istanbul',
    'Istanbul',
    5.00,
    200.00,
    '2026-10-15',
    'pending',
    'created'
);


-- Save the new shipment ID

SET @new_shipment_id = LAST_INSERT_ID();


-- 2. Add the first tracking record

INSERT INTO shipment_tracking
(
    shipment_id,
    branch_id,
    status,
    description,
    recorded_at
)
VALUES
(
    @new_shipment_id,
    1,
    'created',
    'Shipment created successfully',
    NOW()
);


-- 3. Record the payment

INSERT INTO payments
(
    shipment_id,
    amount,
    payment_method,
    payment_date,
    transaction_reference,
    status
)
VALUES
(
    @new_shipment_id,
    200.00,
    'card',
    NOW(),
    CONCAT('PAY-', UUID_SHORT()),
    'successful'
);


-- 4. Save all operations

COMMIT;


-- ============================================
-- ROLLBACK EXAMPLE
-- ============================================

-- If a problem occurs before COMMIT,
-- use:

-- ROLLBACK;



-- ============================================
-- TRANSACTION VERIFICATION
-- ============================================

-- After the transaction, the inserted data can be verified
-- in all three related tables.

SELECT *
FROM shipments
WHERE id = 61;

SELECT *
FROM shipment_tracking
WHERE shipment_id = 61;

SELECT *
FROM payments
WHERE shipment_id = 61;


-- Expected result from the previous transaction:
--
-- Shipment 61 was created.
-- Tracking record 121 was created.
-- Payment record 41 was created.
-- COMMIT permanently saved all changes.


-- ============================================
-- ROLLBACK
-- ============================================

-- ROLLBACK is used when an error occurs
-- or when we want to cancel changes made
-- inside the current transaction.
--
-- All changes made after START TRANSACTION
-- are undone as long as they have not been committed.
--
-- COMMIT makes the changes permanent.
-- ROLLBACK cancels the uncommitted changes.
--
-- Transactions ensure that related operations
-- can be treated as one logical unit,
-- which helps maintain data consistency.


-- ============================================
-- STORED PROCEDURES
-- ============================================

-- In this project, three Stored Procedures are created:
--
-- 1. create_shipment
-- 2. assign_delivery
-- 3. complete_delivery


-- ============================================
-- 1. create_shipment
-- ============================================

DROP PROCEDURE IF EXISTS create_shipment;

DELIMITER //

CREATE PROCEDURE create_shipment(
    IN p_tracking_number VARCHAR(50),
    IN p_customer_id INT,
    IN p_origin_branch_id INT,
    IN p_destination_branch_id INT,
    IN p_sender_name VARCHAR(100),
    IN p_sender_phone VARCHAR(20),
    IN p_receiver_name VARCHAR(100),
    IN p_receiver_phone VARCHAR(20),
    IN p_receiver_address VARCHAR(255),
    IN p_receiver_city VARCHAR(100),
    IN p_weight DECIMAL(10,2),
    IN p_shipping_cost DECIMAL(10,2),
    IN p_expected_delivery_date DATE
)
BEGIN

    DECLARE v_shipment_id INT;

    INSERT INTO shipments (
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
        expected_delivery_date
    )
    VALUES (
        p_tracking_number,
        p_customer_id,
        p_origin_branch_id,
        p_destination_branch_id,
        p_sender_name,
        p_sender_phone,
        p_receiver_name,
        p_receiver_phone,
        p_receiver_address,
        p_receiver_city,
        p_weight,
        p_shipping_cost,
        p_expected_delivery_date
    );

    SET v_shipment_id = LAST_INSERT_ID();

    INSERT INTO shipment_tracking (
        shipment_id,
        branch_id,
        status,
        description,
        recorded_at
    )
    VALUES (
        v_shipment_id,
        p_origin_branch_id,
        'created',
        'Shipment created',
        NOW()
    );

END //

DELIMITER ;


-- ============================================
-- TEST create_shipment
-- ============================================

CALL create_shipment(
    'TRK100063',
    1,
    1,
    2,
    'Omar Ali',
    '0502000002',
    'Lina Ali',
    '0506000002',
    'Kadikoy',
    'Istanbul',
    3.00,
    200.00,
    '2026-10-07'
);


-- Verify the newly created shipment

SELECT *
FROM shipments
WHERE tracking_number = 'TRK100063';

SELECT *
FROM shipment_tracking
WHERE shipment_id = (
    SELECT id
    FROM shipments
    WHERE tracking_number = 'TRK100063'
);


-- ============================================
-- 2. assign_delivery
-- ============================================

DROP PROCEDURE IF EXISTS assign_delivery;

DELIMITER //

CREATE PROCEDURE assign_delivery(
    IN p_shipment_id INT,
    IN p_driver_id INT,
    IN p_vehicle_id INT
)
BEGIN

    DECLARE v_delivery_exists INT DEFAULT 0;
    DECLARE v_driver_status VARCHAR(30);
    DECLARE v_vehicle_status VARCHAR(30);
    DECLARE v_shipment_status VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    -- Check shipment status

    SELECT shipment_status
    INTO v_shipment_status
    FROM shipments
    WHERE id = p_shipment_id;

    IF v_shipment_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Shipment not found';
    END IF;

    IF v_shipment_status <> 'created' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Shipment is not available for delivery assignment';
    END IF;


    -- Check driver status

    SELECT status
    INTO v_driver_status
    FROM drivers
    WHERE id = p_driver_id;

    IF v_driver_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Driver not found';
    END IF;

    IF v_driver_status <> 'active' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Driver is not active';
    END IF;


    -- Check vehicle status

    SELECT status
    INTO v_vehicle_status
    FROM vehicles
    WHERE id = p_vehicle_id;

    IF v_vehicle_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vehicle not found';
    END IF;

    IF v_vehicle_status <> 'available' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Vehicle is not available';
    END IF;


    -- Check whether this shipment already has a delivery

    SELECT COUNT(*)
    INTO v_delivery_exists
    FROM deliveries
    WHERE shipment_id = p_shipment_id;

    IF v_delivery_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Shipment already has a delivery';
    END IF;


    -- Create delivery

    INSERT INTO deliveries (
        shipment_id,
        driver_id,
        vehicle_id,
        delivery_status,
        started_at,
        completed_at
    )
    VALUES (
        p_shipment_id,
        p_driver_id,
        p_vehicle_id,
        'assigned',
        NULL,
        NULL
    );


    -- Update shipment status

    UPDATE shipments
    SET shipment_status = 'assigned'
    WHERE id = p_shipment_id;


    -- Update vehicle status

    UPDATE vehicles
    SET status = 'assigned'
    WHERE id = p_vehicle_id;


    -- Add tracking record

    INSERT INTO shipment_tracking (
        shipment_id,
        branch_id,
        status,
        description,
        recorded_at
    )
    SELECT
        s.id,
        s.origin_branch_id,
        'assigned',
        'Shipment assigned for delivery',
        NOW()
    FROM shipments s
    WHERE s.id = p_shipment_id;


    COMMIT;

END //

DELIMITER ;


-- ============================================
-- TEST assign_delivery
-- ============================================

-- Example:
--
-- CALL assign_delivery(
--     61,
--     1,
--     1
-- );


-- ============================================
-- 3. complete_delivery
-- ============================================

DROP PROCEDURE IF EXISTS complete_delivery;

DELIMITER //

CREATE PROCEDURE complete_delivery(
    IN p_delivery_id INT
)
BEGIN

    DECLARE v_shipment_id INT DEFAULT NULL;
    DECLARE v_vehicle_id INT DEFAULT NULL;
    DECLARE v_destination_branch_id INT DEFAULT NULL;
    DECLARE v_delivery_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;


    START TRANSACTION;


    -- Find the delivery and its shipment

    SELECT COUNT(*)
    INTO v_delivery_count
    FROM deliveries d
    JOIN shipments s
        ON d.shipment_id = s.id
    WHERE d.id = p_delivery_id
      AND d.delivery_status IN ('assigned', 'in_progress');


    IF v_delivery_count = 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Delivery is not available for completion';

    END IF;


    -- Get the required IDs

    SELECT
        d.shipment_id,
        d.vehicle_id,
        s.destination_branch_id
    INTO
        v_shipment_id,
        v_vehicle_id,
        v_destination_branch_id
    FROM deliveries d
    JOIN shipments s
        ON d.shipment_id = s.id
    WHERE d.id = p_delivery_id
      AND d.delivery_status IN ('assigned', 'in_progress')
    LIMIT 1;


    -- Complete delivery

    UPDATE deliveries
    SET
        started_at = IFNULL(started_at, NOW()),
        completed_at = NOW(),
        delivery_status = 'completed'
    WHERE id = p_delivery_id;


    -- Update shipment

    UPDATE shipments
    SET
        shipment_status = 'delivered',
        delivered_at = NOW()
    WHERE id = v_shipment_id;


    -- Add tracking record

    INSERT INTO shipment_tracking (
        shipment_id,
        branch_id,
        status,
        description,
        recorded_at
    )
    VALUES (
        v_shipment_id,
        v_destination_branch_id,
        'delivered',
        'Shipment delivered successfully',
        NOW()
    );


    -- Make vehicle available again

    UPDATE vehicles
    SET status = 'available'
    WHERE id = v_vehicle_id;


    COMMIT;

END //

DELIMITER ;


-- ============================================
-- TEST complete_delivery
-- ============================================

-- Example:
--
-- CALL complete_delivery(1);


-- Verify delivery

-- SELECT *
-- FROM deliveries
-- WHERE id = 1;

-- Verify shipment

-- SELECT *
-- FROM shipments
-- WHERE id = (
--     SELECT shipment_id
--     FROM deliveries
--     WHERE id = 1
-- );

-- Verify tracking

-- SELECT *
-- FROM shipment_tracking
-- WHERE shipment_id = (
--     SELECT shipment_id
--     FROM deliveries
--     WHERE id = 1
-- );



-- ================================================
-- ================== TRIGGERS ====================
-- ================================================


-- ================================================
-- 1. Update Shipment Status from Tracking
-- ================================================

DROP TRIGGER IF EXISTS update_shipment_status_from_tracking;

DELIMITER //

CREATE TRIGGER update_shipment_status_from_tracking
AFTER INSERT
ON shipment_tracking
FOR EACH ROW
BEGIN

    UPDATE shipments
    SET shipment_status = NEW.status
    WHERE id = NEW.shipment_id;

END //

DELIMITER ;


-- ================================================
-- 2. Update Vehicle Status When Delivery Starts
-- ================================================

DROP TRIGGER IF EXISTS update_vehicle_status_on_delivery_start;

DELIMITER //

CREATE TRIGGER update_vehicle_status_on_delivery_start
AFTER UPDATE
ON deliveries
FOR EACH ROW
BEGIN

    IF NEW.delivery_status = 'in_progress'
       AND OLD.delivery_status <> 'in_progress' THEN

        UPDATE vehicles
        SET status = 'in_delivery'
        WHERE id = NEW.vehicle_id;

    END IF;

END //

DELIMITER ;


-- ================================================
-- 3. Update Vehicle Status When Delivery Completes
-- ================================================

DROP TRIGGER IF EXISTS update_vehicle_status_on_delivery_complete;

DELIMITER //

CREATE TRIGGER update_vehicle_status_on_delivery_complete
AFTER UPDATE
ON deliveries
FOR EACH ROW
BEGIN

    IF NEW.delivery_status = 'completed'
       AND OLD.delivery_status <> 'completed' THEN

        UPDATE vehicles
        SET status = 'available'
        WHERE id = NEW.vehicle_id;

    END IF;

END //

DELIMITER ;




-- ================================================
-- 4. Prevent Invalid Payments
-- ================================================

DROP TRIGGER IF EXISTS prevent_invalid_payment;

DELIMITER //

CREATE TRIGGER prevent_invalid_payment
BEFORE INSERT
ON payments
FOR EACH ROW
BEGIN

    IF NEW.amount <= 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Payment amount must be greater than 0';

    END IF;

END //

DELIMITER ;


-- ================================================
-- 5. Prevent Deleting Customers with Shipments
-- ================================================

DROP TRIGGER IF EXISTS prevent_customer_delete_with_shipments;

DELIMITER //

CREATE TRIGGER prevent_customer_delete_with_shipments
BEFORE DELETE
ON customers
FOR EACH ROW
BEGIN

    IF EXISTS (
        SELECT 1
        FROM shipments
        WHERE customer_id = OLD.id
    ) THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Cannot delete customer with shipments';

    END IF;

END //

DELIMITER ;


-- ================================================
-- 6. Prevent Invalid Delivery Completion
-- ================================================

DROP TRIGGER IF EXISTS prevent_invalid_delivery_completion;

DELIMITER //

CREATE TRIGGER prevent_invalid_delivery_completion
BEFORE UPDATE
ON deliveries
FOR EACH ROW
BEGIN

    DECLARE v_shipment_status VARCHAR(30);

    IF NEW.delivery_status = 'completed'
       AND OLD.delivery_status <> 'completed' THEN

        SELECT shipment_status
        INTO v_shipment_status
        FROM shipments
        WHERE id = NEW.shipment_id;

        IF v_shipment_status IS NULL THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Shipment does not exist';

        END IF;

        IF v_shipment_status IN
           ('created', 'cancelled', 'returned') THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Cannot complete delivery for this shipment status';

        END IF;

    END IF;

END //

DELIMITER ;


-- ================================================
-- 7. Prevent Multiple Active Deliveries
--    for the Same Vehicle
-- ================================================

DROP TRIGGER IF EXISTS prevent_vehicle_multiple_active_deliveries;

DELIMITER //

CREATE TRIGGER prevent_vehicle_multiple_active_deliveries
BEFORE INSERT
ON deliveries
FOR EACH ROW
BEGIN

    IF NEW.delivery_status IN ('assigned', 'in_progress')
       AND EXISTS (
            SELECT 1
            FROM deliveries
            WHERE vehicle_id = NEW.vehicle_id
              AND delivery_status IN ('assigned', 'in_progress')
       ) THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Vehicle already has an active delivery';

    END IF;

END //

DELIMITER ;


-- ================================================
-- 7-B. Prevent Vehicle Conflict on UPDATE
-- ================================================

DROP TRIGGER IF EXISTS prevent_vehicle_multiple_active_deliveries_update;

DELIMITER //

CREATE TRIGGER prevent_vehicle_multiple_active_deliveries_update
BEFORE UPDATE
ON deliveries
FOR EACH ROW
BEGIN

    IF NEW.delivery_status IN ('assigned', 'in_progress') THEN

        IF EXISTS (
            SELECT 1
            FROM deliveries
            WHERE vehicle_id = NEW.vehicle_id
              AND delivery_status IN ('assigned', 'in_progress')
              AND id <> NEW.id
        ) THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Vehicle already has an active delivery';

        END IF;

    END IF;

END //

DELIMITER ;


-- ================================================
-- 8. Prevent Multiple Active Deliveries
--    for the Same Driver
-- ================================================

DROP TRIGGER IF EXISTS prevent_driver_multiple_active_deliveries;

DELIMITER //

CREATE TRIGGER prevent_driver_multiple_active_deliveries
BEFORE INSERT
ON deliveries
FOR EACH ROW
BEGIN

    IF NEW.delivery_status IN ('assigned', 'in_progress')
       AND EXISTS (
            SELECT 1
            FROM deliveries
            WHERE driver_id = NEW.driver_id
              AND delivery_status IN ('assigned', 'in_progress')
       ) THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Driver already has an active delivery';

    END IF;

END //

DELIMITER ;


-- ================================================
-- 8-B. Prevent Driver Conflict on UPDATE
-- ================================================

DROP TRIGGER IF EXISTS prevent_driver_multiple_active_deliveries_update;

DELIMITER //

CREATE TRIGGER prevent_driver_multiple_active_deliveries_update
BEFORE UPDATE
ON deliveries
FOR EACH ROW
BEGIN

    IF NEW.delivery_status IN ('assigned', 'in_progress') THEN

        IF EXISTS (
            SELECT 1
            FROM deliveries
            WHERE driver_id = NEW.driver_id
              AND delivery_status IN ('assigned', 'in_progress')
              AND id <> NEW.id
        ) THEN

            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
            'Driver already has an active delivery';

        END IF;

    END IF;

END //

DELIMITER ;


-- ================================================
-- 9. Prevent Tracking Before Shipment Creation
-- ================================================

DROP TRIGGER IF EXISTS prevent_tracking_before_shipment;

DELIMITER //

CREATE TRIGGER prevent_tracking_before_shipment
BEFORE INSERT
ON shipment_tracking
FOR EACH ROW
BEGIN

    DECLARE v_created_at DATETIME;

    SELECT created_at
    INTO v_created_at
    FROM shipments
    WHERE id = NEW.shipment_id;

    IF v_created_at IS NULL THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Shipment does not exist';

    END IF;

    IF NEW.recorded_at < v_created_at THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Tracking date cannot be earlier than shipment creation';

    END IF;

END //

DELIMITER ;


-- ================================================
-- 10. Prevent Overweight Shipment Delivery
-- ================================================

DROP TRIGGER IF EXISTS prevent_overweight_shipment_delivery;

DELIMITER //

CREATE TRIGGER prevent_overweight_shipment_delivery
BEFORE INSERT
ON deliveries
FOR EACH ROW
BEGIN

    DECLARE v_shipment_weight DECIMAL(10,2);
    DECLARE v_vehicle_capacity DECIMAL(10,2);

    SELECT weight
    INTO v_shipment_weight
    FROM shipments
    WHERE id = NEW.shipment_id;

    SELECT max_weight
    INTO v_vehicle_capacity
    FROM vehicles
    WHERE id = NEW.vehicle_id;


    IF v_shipment_weight IS NULL THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Shipment does not exist';

    END IF;


    IF v_vehicle_capacity IS NULL THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Vehicle does not exist';

    END IF;


    IF v_shipment_weight > v_vehicle_capacity THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'Shipment weight exceeds vehicle capacity';

    END IF;

END //

DELIMITER ;





-- ======================================================
-- ================== Advanced Queries ==================
-- ======================================================


-- ======================================================
-- 1. Customers whose spending is higher than
--    the average spending of all customers
-- ======================================================

SELECT
    c.id,
    c.full_name,
    COALESCE(SUM(p.amount), 0) AS total_spending
FROM customers c
LEFT JOIN shipments s
    ON c.id = s.customer_id
LEFT JOIN payments p
    ON s.id = p.shipment_id
   AND p.status = 'successful'
GROUP BY
    c.id,
    c.full_name
HAVING COALESCE(SUM(p.amount), 0) > (
    SELECT AVG(customer_spending)
    FROM (
        SELECT
            c2.id,
            COALESCE(SUM(p2.amount), 0) AS customer_spending
        FROM customers c2
        LEFT JOIN shipments s2
            ON c2.id = s2.customer_id
        LEFT JOIN payments p2
            ON s2.id = p2.shipment_id
           AND p2.status = 'successful'
        GROUP BY
            c2.id
    ) AS spending_table
);


-- ======================================================
-- 2. Employees whose salary is higher than
--    the average salary of their branch
-- ======================================================

SELECT
    e.id,
    e.full_name,
    e.branch_id,
    e.salary
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.branch_id = e.branch_id
);


-- ======================================================
-- 3. Shipments whose shipping cost is higher than
--    the average shipping cost of all shipments
-- ======================================================

SELECT
    id,
    tracking_number,
    shipping_cost
FROM shipments
WHERE shipping_cost > (
    SELECT AVG(shipping_cost)
    FROM shipments
);


-- ======================================================
-- 4. Drivers whose number of deliveries is higher
--    than the average number of deliveries per driver
-- ======================================================

SELECT
    d.id,
    d.full_name,
    COUNT(del.id) AS delivery_count
FROM drivers d
LEFT JOIN deliveries del
    ON d.id = del.driver_id
GROUP BY
    d.id,
    d.full_name
HAVING COUNT(del.id) > (
    SELECT AVG(driver_delivery_count)
    FROM (
        SELECT
            d2.id,
            COUNT(del2.id) AS driver_delivery_count
        FROM drivers d2
        LEFT JOIN deliveries del2
            ON d2.id = del2.driver_id
        GROUP BY
            d2.id
    ) AS driver_counts
);


-- ======================================================
-- 5. Branches whose revenue is higher than
--    the average revenue of all branches
-- ======================================================

SELECT
    b.id,
    b.branch_name,
    COALESCE(SUM(p.amount), 0) AS branch_revenue
FROM branches b
LEFT JOIN shipments s
    ON b.id = s.origin_branch_id
LEFT JOIN payments p
    ON s.id = p.shipment_id
   AND p.status = 'successful'
GROUP BY
    b.id,
    b.branch_name
HAVING COALESCE(SUM(p.amount), 0) > (
    SELECT AVG(branch_revenue)
    FROM (
        SELECT
            b2.id,
            COALESCE(SUM(p2.amount), 0) AS branch_revenue
        FROM branches b2
        LEFT JOIN shipments s2
            ON b2.id = s2.origin_branch_id
        LEFT JOIN payments p2
            ON s2.id = p2.shipment_id
           AND p2.status = 'successful'
        GROUP BY
            b2.id
    ) AS branch_revenues
);


-- ======================================================
-- 6. Vehicles used more than the average usage
--    of all vehicles
-- ======================================================

SELECT
    v.id,
    v.plate_number,
    COUNT(d.id) AS usage_count
FROM vehicles v
LEFT JOIN deliveries d
    ON v.id = d.vehicle_id
GROUP BY
    v.id,
    v.plate_number
HAVING COUNT(d.id) > (
    SELECT AVG(vehicle_usage)
    FROM (
        SELECT
            v2.id,
            COUNT(d2.id) AS vehicle_usage
        FROM vehicles v2
        LEFT JOIN deliveries d2
            ON v2.id = d2.vehicle_id
        GROUP BY
            v2.id
    ) AS vehicle_usage_table
);


-- ====================================================
-- ================= WINDOW FUNCTIONS =================
-- ====================================================


-- 1. ترتيب العملاء حسب إجمالي الإنفاق — RANK()
SELECT
    c.id,
    c.full_name,
    COALESCE(SUM(p.amount), 0) AS total_spending,
    RANK() OVER (
        ORDER BY COALESCE(SUM(p.amount), 0) DESC
    ) AS spending_rank
FROM customers c
LEFT JOIN shipments s
    ON c.id = s.customer_id
LEFT JOIN payments p
    ON s.id = p.shipment_id
   AND p.status = 'successful'
GROUP BY
    c.id,
    c.full_name
ORDER BY
    spending_rank;


-- 2. ترتيب السائقين حسب عدد التوصيلات — DENSE_RANK()
SELECT
    d.id,
    d.full_name,
    COUNT(del.id) AS delivery_count,
    DENSE_RANK() OVER (
        ORDER BY COUNT(del.id) DESC
    ) AS delivery_rank
FROM drivers d
LEFT JOIN deliveries del
    ON d.id = del.driver_id
GROUP BY
    d.id,
    d.full_name
ORDER BY
    delivery_rank;


-- 3. ترتيب الموظفين حسب الراتب داخل كل فرع — ROW_NUMBER()
SELECT
    e.id,
    e.full_name,
    e.branch_id,
    e.salary,
    ROW_NUMBER() OVER (
        PARTITION BY e.branch_id
        ORDER BY e.salary DESC
    ) AS salary_rank
FROM employees e
ORDER BY
    e.branch_id,
    salary_rank;


-- 4. أعلى 3 موظفين راتبًا في كل فرع
SELECT
    id,
    full_name,
    branch_id,
    salary,
    salary_rank
FROM (
    SELECT
        e.id,
        e.full_name,
        e.branch_id,
        e.salary,
        ROW_NUMBER() OVER (
            PARTITION BY e.branch_id
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM employees e
) AS ranked_employees
WHERE salary_rank <= 3
ORDER BY
    branch_id,
    salary_rank;


-- 5. الإيراد الشهري التراكمي
SELECT
    YEAR(payment_date) AS payment_year,
    MONTH(payment_date) AS month_number,
    MONTHNAME(payment_date) AS month_name,
    SUM(amount) AS monthly_revenue,
    SUM(SUM(amount)) OVER (
        ORDER BY YEAR(payment_date), MONTH(payment_date)
    ) AS cumulative_revenue
FROM payments
WHERE status = 'successful'
GROUP BY
    YEAR(payment_date),
    MONTH(payment_date),
    MONTHNAME(payment_date)
ORDER BY
    payment_year,
    month_number;


-- 6. مقارنة إيراد كل شهر مع الشهر السابق — LAG()
WITH monthly_revenue AS (
    SELECT
        YEAR(payment_date) AS payment_year,
        MONTH(payment_date) AS month_number,
        MONTHNAME(payment_date) AS month_name,
        SUM(amount) AS monthly_revenue
    FROM payments
    WHERE status = 'successful'
    GROUP BY
        YEAR(payment_date),
        MONTH(payment_date),
        MONTHNAME(payment_date)
)
SELECT
    payment_year,
    month_number,
    month_name,
    monthly_revenue,
    LAG(monthly_revenue) OVER (
        ORDER BY payment_year, month_number
    ) AS previous_month_revenue,
    monthly_revenue -
    LAG(monthly_revenue) OVER (
        ORDER BY payment_year, month_number
    ) AS revenue_difference
FROM monthly_revenue
ORDER BY
    payment_year,
    month_number;


-- 7. الفرق بين كل دفعة والدفعة السابقة
SELECT
    id AS payment_id,
    shipment_id,
    payment_date,
    amount,
    LAG(amount) OVER (
        ORDER BY payment_date, id
    ) AS previous_payment_amount,
    amount -
    LAG(amount) OVER (
        ORDER BY payment_date, id
    ) AS payment_difference
FROM payments
ORDER BY
    payment_date,
    id;


-- 8. أول وآخر Tracking لكل شحنة
SELECT
    shipment_id,
    status,
    recorded_at,
    FIRST_VALUE(status) OVER (
        PARTITION BY shipment_id
        ORDER BY recorded_at
    ) AS first_tracking_status,
    LAST_VALUE(status) OVER (
        PARTITION BY shipment_id
        ORDER BY recorded_at
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND UNBOUNDED FOLLOWING
    ) AS last_tracking_status
FROM shipment_tracking
ORDER BY
    shipment_id,
    recorded_at;


-- 9. رقم تسلسلي لحركة الشحنة
SELECT
    shipment_id,
    status,
    branch_id,
    recorded_at,
    ROW_NUMBER() OVER (
        PARTITION BY shipment_id
        ORDER BY recorded_at
    ) AS movement_number
FROM shipment_tracking
ORDER BY
    shipment_id,
    movement_number;


-- 10. مساهمة كل عميل كنسبة من إجمالي إيرادات الشركة
SELECT
    c.id,
    c.full_name,
    COALESCE(SUM(p.amount), 0) AS customer_revenue,
    COALESCE(SUM(p.amount), 0) * 100.0 /
    NULLIF(SUM(SUM(p.amount)) OVER (), 0) AS contribution_percentage
FROM customers c
LEFT JOIN shipments s
    ON c.id = s.customer_id
LEFT JOIN payments p
    ON s.id = p.shipment_id
   AND p.status = 'successful'
GROUP BY
    c.id,
    c.full_name
ORDER BY
    contribution_percentage DESC;


-- ====================================================
-- ====================== CTE =========================
-- ====================================================


-- 1. CTE 1 — العملاء الذين إنفاقهم أعلى من المتوسط
WITH customer_spending AS (
    SELECT
        c.id,
        c.full_name,
        COALESCE(SUM(p.amount), 0) AS total_spending
    FROM customers c
    LEFT JOIN shipments s
        ON c.id = s.customer_id
    LEFT JOIN payments p
        ON s.id = p.shipment_id
       AND p.status = 'successful'
    GROUP BY
        c.id,
        c.full_name
)
SELECT
    id,
    full_name,
    total_spending
FROM customer_spending
WHERE total_spending > (
    SELECT AVG(total_spending)
    FROM customer_spending
)
ORDER BY
    total_spending DESC;


-- 2. CTE 2 — أداء الفروع: عدد الشحنات + الإيرادات
WITH branch_performance AS (
    SELECT
        b.id,
        b.branch_name,
        COUNT(DISTINCT s.id) AS shipment_count,
        COALESCE(
            SUM(
                CASE
                    WHEN p.status = 'successful' THEN p.amount
                    ELSE 0
                END
            ),
            0
        ) AS revenue
    FROM branches b
    LEFT JOIN shipments s
        ON b.id = s.origin_branch_id
    LEFT JOIN payments p
        ON s.id = p.shipment_id
    GROUP BY
        b.id,
        b.branch_name
)
SELECT
    id,
    branch_name,
    shipment_count,
    revenue
FROM branch_performance
ORDER BY
    revenue DESC;


-- 3. CTE 3 — الـ Overdue Shipments مع اسم العميل والسائق الحالي
WITH overdue_shipments AS (
    SELECT
        s.id,
        s.tracking_number,
        c.full_name AS customer_name,
        s.expected_delivery_date,
        d.full_name AS driver_name
    FROM shipments s
    JOIN customers c
        ON s.customer_id = c.id
    LEFT JOIN deliveries del
        ON s.id = del.shipment_id
       AND del.delivery_status IN ('assigned', 'in_progress')
    LEFT JOIN drivers d
        ON del.driver_id = d.id
    WHERE s.expected_delivery_date < CURDATE()
      AND s.shipment_status <> 'delivered'
)
SELECT
    id,
    tracking_number,
    customer_name,
    expected_delivery_date,
    driver_name
FROM overdue_shipments
ORDER BY
    expected_delivery_date;


-- 4. CTE 4 — أداء السائقين فوق المتوسط
WITH driver_performance AS (
    SELECT
        d.id,
        d.full_name,
        COUNT(del.id) AS delivery_count,
        COUNT(
            CASE
                WHEN del.delivery_status = 'completed'
                THEN 1
            END
        ) AS successful_deliveries,
        COALESCE(
            SUM(
                CASE
                    WHEN del.delivery_status = 'completed'
                    THEN s.shipping_cost
                    ELSE 0
                END
            ),
            0
        ) AS total_shipment_value
    FROM drivers d
    LEFT JOIN deliveries del
        ON d.id = del.driver_id
    LEFT JOIN shipments s
        ON del.shipment_id = s.id
    GROUP BY
        d.id,
        d.full_name
)
SELECT
    id,
    full_name,
    delivery_count,
    successful_deliveries,
    total_shipment_value
FROM driver_performance
WHERE successful_deliveries > (
    SELECT AVG(successful_deliveries)
    FROM driver_performance
)
ORDER BY
    successful_deliveries DESC;



-- ==========================================================
-- ============== INTEGRITY & SAFETY CHECKS ================
-- ==========================================================


-- 1. Delivered Shipment Must Have Delivered Date
SELECT
    id,
    tracking_number,
    shipment_status,
    delivered_at
FROM shipments
WHERE
    (shipment_status = 'delivered' AND delivered_at IS NULL)
    OR
    (shipment_status <> 'delivered' AND delivered_at IS NOT NULL);

-- Expected result:
-- 0 rows


-- 2. Shipment Cannot Have Delivered Date Before Delivery
SELECT
    id,
    tracking_number,
    shipment_status,
    delivered_at
FROM shipments
WHERE shipment_status <> 'delivered'
  AND delivered_at IS NOT NULL;

-- Expected result:
-- 0 rows


-- 3. Completed Delivery Cannot Belong to a Created Shipment
SELECT
    d.id AS delivery_id,
    d.shipment_id,
    d.delivery_status,
    s.shipment_status
FROM deliveries d
JOIN shipments s
    ON d.shipment_id = s.id
WHERE d.delivery_status = 'completed'
  AND s.shipment_status = 'created';

-- Expected result:
-- 0 rows


-- 4. A Vehicle Cannot Have Multiple Active Deliveries
SELECT
    vehicle_id,
    COUNT(*) AS active_deliveries
FROM deliveries
WHERE delivery_status IN ('assigned', 'in_progress')
GROUP BY vehicle_id
HAVING COUNT(*) > 1;

-- Expected result:
-- 0 rows


-- 5. A Driver Cannot Have Multiple Active Deliveries
SELECT
    driver_id,
    COUNT(*) AS active_deliveries
FROM deliveries
WHERE delivery_status IN ('assigned', 'in_progress')
GROUP BY driver_id
HAVING COUNT(*) > 1;

-- Expected result:
-- 0 rows


-- 6. Successful Payments Must Reference Existing Shipments
SELECT
    p.id AS payment_id,
    p.shipment_id,
    p.status
FROM payments p
LEFT JOIN shipments s
    ON p.shipment_id = s.id
WHERE p.status = 'successful'
  AND s.id IS NULL;

-- Expected result:
-- 0 rows


-- 7. Tracking Date Cannot Be Before Shipment Creation
SELECT
    st.id AS tracking_id,
    st.shipment_id,
    s.tracking_number,
    s.created_at,
    st.recorded_at
FROM shipment_tracking st
JOIN shipments s
    ON st.shipment_id = s.id
WHERE st.recorded_at < s.created_at;

-- Expected result:
-- 0 rows


-- 8. Shipment Weight Cannot Exceed Vehicle Capacity
SELECT
    d.id AS delivery_id,
    d.shipment_id,
    d.vehicle_id,
    s.weight AS shipment_weight,
    v.max_weight AS vehicle_max_weight
FROM deliveries d
JOIN shipments s
    ON d.shipment_id = s.id
JOIN vehicles v
    ON d.vehicle_id = v.id
WHERE s.weight > v.max_weight;

-- Expected result:
-- 0 rows


--============================================================================
              --================ Normalization==================
--=============================================================================


--- 1. Functional Dependencies====

Functional dependencies describe how one attribute determines other attributes in the database.

Examples from the Logistics & Delivery Management System:

- `customer_id → full_name, email, phone, customer_type, city, address, registered_at, status`
- `branch_id → branch_name, city, address, phone, manager_name, opened_at, status`
- `employee_id → branch_id, full_name, email, phone, job_title, salary, hire_date, status`
- `driver_id → branch_id, full_name, phone, license_number, license_expiry_date, hire_date, salary, status`
- `vehicle_id → branch_id, plate_number, vehicle_type, model, manufacture_year, max_weight, status`
- `shipment_id → tracking_number, customer_id, origin_branch_id, destination_branch_id, sender_name, sender_phone, receiver_name, receiver_phone, receiver_address, receiver_city, weight, shipping_cost, created_at, expected_delivery_date, delivered_at, payment_status, shipment_status`
- `delivery_id → shipment_id, driver_id, vehicle_id, assigned_at, started_at, completed_at, delivery_status, notes`
- `payment_id → shipment_id, amount, payment_method, payment_date, transaction_reference, status`

These dependencies show that each entity's primary key determines the attributes belonging to that entity.



---2. First Normal Form (1NF)

The database satisfies First Normal Form because:

- Each table has a primary key.
- Each column contains atomic values.
- There are no repeating groups.
- Multiple values are not stored in a single column.
- Each row represents one specific entity or transaction.

For example, customer phone numbers are stored as individual values rather than a comma-separated list.

Therefore, the database satisfies **1NF**.



---3. Second Normal Form (2NF)

The database satisfies Second Normal Form because:

- It already satisfies 1NF.
- The main tables use a single-column primary key such as `customer_id`, `shipment_id`, `employee_id`, and `vehicle_id`.
- There are no partial dependencies where a non-key attribute depends only on part of a composite primary key.

Therefore, non-key attributes depend on the complete primary key of their table.

The database satisfies **2NF**.

---
--- 4. Third Normal Form (3NF)

The database satisfies Third Normal Form because:

- It satisfies 2NF.
- Non-key attributes depend on the primary key of their own table.
- Attributes belonging to another entity are stored in that entity's table instead of being duplicated.


The `employees` table does not store `branch_name` or `branch_city`.

This prevents the following transitive dependency:

```text
employee_id → branch_id → branch_name
```

Instead, `branch_name` is determined by `branch_id` in the `branches` table.

Therefore, the database satisfies **3NF**.

---

--- 5. Transitive Dependencies

A transitive dependency occurs when:

```text
A → B
B → C
```

which means:

```text
A → C
```

In this system, branch information could create a transitive dependency if it were stored inside the `employees` table.

For example:

```text
employee_id → branch_id
branch_id → branch_name
```

Instead of storing `branch_name` in `employees`, the system stores only:

```text
branch_id
```

and retrieves branch information through the relationship with the `branches` table.

This reduces data duplication and prevents update anomalies.

---

----- 6. Proposed Changes

The current database design is already largely normalized to 3NF.

The main normalization decisions are:

- Store customers separately from shipments.
- Store branches separately from employees, drivers, and vehicles.
- Store shipments separately from deliveries.
- Store payments separately from shipments.
- Store shipment movement history separately in `shipment_tracking`.
- Use foreign keys instead of duplicating complete entity information.
- Avoid storing calculated or repeated entity information unnecessarily.

No major structural changes are required to achieve 3NF.

---

---- 7. When Denormalization Can Be Acceptable

Denormalization may be acceptable when performance becomes more important than minimizing data duplication.

For example, a frequently used reporting system might store a pre-calculated summary such as:

```text
customer_total_spending
```

instead of calculating it from all payment records every time.

However, denormalization should only be introduced when there is a clear performance or reporting requirement.

The current system prioritizes data consistency and normalization, while indexes, views, and optimized queries are used to improve performance without unnecessary duplication.


--==============================================================================================
                    --=================== Queries — 1 to 40================
-- =============================================================================================
-- Query 1
-- عرض جميع الشحنات مع اسم العميل وفرع الإرسال وفرع الاستلام
-- =====================================================

SELECT
    s.id,
    s.tracking_number,
    c.full_name AS customer_name,
    ob.branch_name AS origin_branch,
    db.branch_name AS destination_branch,
    s.shipping_cost,
    s.shipment_status
FROM shipments s
JOIN customers c
    ON s.customer_id = c.id
JOIN branches ob
    ON s.origin_branch_id = ob.id
JOIN branches db
    ON s.destination_branch_id = db.id;


-- =====================================================
-- Query 2
-- عرض الشحنات التي لم يتم تسليمها حتى الآن
-- =====================================================

SELECT
    id,
    tracking_number,
    customer_id,
    shipment_status,
    expected_delivery_date
FROM shipments
WHERE shipment_status <> 'delivered';


-- =====================================================
-- Query 3
-- عرض الشحنات التي تجاوزت expected_delivery_date ولم يتم تسليمها
-- =====================================================

SELECT
    id,
    tracking_number,
    expected_delivery_date,
    shipment_status
FROM shipments
WHERE expected_delivery_date < CURDATE()
  AND shipment_status <> 'delivered';


-- =====================================================
-- Query 4
-- عرض جميع الشحنات الخاصة بعميل محدد مرتبة من الأحدث إلى الأقدم
-- =====================================================

SELECT
    id,
    tracking_number,
    customer_id,
    shipping_cost,
    shipment_status,
    created_at
FROM shipments
WHERE customer_id = 1
ORDER BY created_at DESC;


-- =====================================================
-- Query 5
-- عرض عدد الشحنات لكل عميل، بما في ذلك العملاء الذين لم ينشئوا أي شحنة
-- =====================================================

SELECT
    c.id,
    c.full_name,
    COUNT(s.id) AS shipment_count
FROM customers c
LEFT JOIN shipments s
    ON c.id = s.customer_id
GROUP BY
    c.id,
    c.full_name;


-- =====================================================
-- Query 6
-- عرض إجمالي المبالغ التي دفعها كل عميل
-- =====================================================
SELECT
    c.id,
    c.full_name,
    COALESCE(SUM(p.amount), 0) AS total_paid
FROM customers c
LEFT JOIN shipments s
    ON c.id = s.customer_id
LEFT JOIN payments p
    ON s.id = p.shipment_id
   AND p.status = 'successful'
GROUP BY
    c.id,
    c.full_name;



-- =====================================================
-- Query 7
-- عرض العملاء الذين تجاوز مجموع قيمة شحناتهم 5000
-- =====================================================

SELECT
    c.id,
    c.full_name,
    SUM(s.shipping_cost) AS total_shipping_cost
FROM customers c
JOIN shipments s
    ON c.id = s.customer_id
GROUP BY
    c.id,
    c.full_name
HAVING SUM(s.shipping_cost) > 5000;


-- =====================================================
-- Query 8
-- عرض عدد الشحنات التي خرجت من كل فرع
-- =====================================================

SELECT
    b.id,
    b.branch_name,
    COUNT(s.id) AS outgoing_shipments
FROM branches b
LEFT JOIN shipments s
    ON b.id = s.origin_branch_id
GROUP BY
    b.id,
    b.branch_name;


-- =====================================================
-- Query 9
-- عرض عدد الشحنات المستلمة في كل فرع
-- =====================================================

SELECT
    b.id,
    b.branch_name,
    COUNT(s.id) AS incoming_shipments
FROM branches b
LEFT JOIN shipments s
    ON b.id = s.destination_branch_id
GROUP BY
    b.id,
    b.branch_name;


-- =====================================================
-- Query 10
-- عرض الفرع صاحب أكبر عدد من الشحنات المرسلة
-- =====================================================
SELECT
    b.id,
    b.branch_name,
    COUNT(s.id) AS outgoing_shipments
FROM branches b
LEFT JOIN shipments s
    ON b.id = s.origin_branch_id
GROUP BY
    b.id,
    b.branch_name
ORDER BY outgoing_shipments DESC
LIMIT 1;


-- =====================================================
-- Query 11
-- عرض متوسط تكلفة الشحن لكل فرع
-- =====================================================

SELECT
    b.id,
    b.branch_name,
    AVG(s.shipping_cost) AS average_shipping_cost
FROM branches b
LEFT JOIN shipments s
    ON b.id = s.origin_branch_id
GROUP BY
    b.id,
    b.branch_name;


-- =====================================================
-- Query 12
-- عرض أغلى شحنة في كل فرع
-- =====================================================
SELECT
    s.id,
    s.tracking_number,
    s.origin_branch_id,
    b.branch_name,
    s.shipping_cost
FROM shipments s
JOIN branches b
    ON s.origin_branch_id = b.id
WHERE s.shipping_cost = (
    SELECT MAX(s2.shipping_cost)
    FROM shipments s2
    WHERE s2.origin_branch_id = s.origin_branch_id
);


-- =====================================================
-- Query 13
-- عرض السائقين الذين قاموا بأكثر من 5 عمليات توصيل ناجحة
-- =====================================================

SELECT
    dr.id,
    dr.full_name,
    COUNT(d.id) AS successful_deliveries
FROM drivers dr
JOIN deliveries d
    ON dr.id = d.driver_id
WHERE d.delivery_status = 'completed'
GROUP BY
    dr.id,
    dr.full_name
HAVING COUNT(d.id) > 5;


-- =====================================================
-- Query 14
-- عرض عدد عمليات التوصيل لكل سائق، بما في ذلك السائقين
-- الذين لم ينفذوا أي عملية توصيل
-- =====================================================

SELECT
    dr.id,
    dr.full_name,
    COUNT(d.id) AS delivery_count
FROM drivers dr
LEFT JOIN deliveries d
    ON dr.id = d.driver_id
GROUP BY
    dr.id,
    dr.full_name;


-- =====================================================
-- Query 15
-- عرض السائق صاحب أكبر عدد من عمليات التوصيل المكتملة
-- =====================================================
SELECT
    d.id,
    d.full_name,
    COUNT(del.id) AS completed_deliveries
FROM drivers d
JOIN deliveries del
    ON d.id = del.driver_id
WHERE del.delivery_status = 'completed'
GROUP BY
    d.id,
    d.full_name
ORDER BY completed_deliveries DESC
LIMIT 1;


-- =====================================================
-- Query 16
-- عرض إجمالي قيمة الشحنات التي قام كل سائق بتوصيلها
-- =====================================================

SELECT
    dr.id,
    dr.full_name,
    SUM(s.shipping_cost) AS total_shipment_value
FROM drivers dr
JOIN deliveries d
    ON dr.id = d.driver_id
JOIN shipments s
    ON d.shipment_id = s.id
GROUP BY
    dr.id,
    dr.full_name;


-- =====================================================
-- Query 17
-- عرض المركبات التي لم تستخدم في أي عملية توصيل
-- =====================================================

SELECT
    v.id,
    v.plate_number,
    v.vehicle_type,
    v.status
FROM vehicles v
LEFT JOIN deliveries d
    ON v.id = d.vehicle_id
WHERE d.id IS NULL;


-- =====================================================
-- Query 18
-- عرض عدد مرات استخدام كل مركبة
-- =====================================================

SELECT
    v.id,
    v.plate_number,
    COUNT(d.id) AS usage_count
FROM vehicles v
LEFT JOIN deliveries d
    ON v.id = d.vehicle_id
GROUP BY
    v.id,
    v.plate_number;


-- =====================================================
-- Query 19
-- عرض المركبات التي استخدمت أكثر من متوسط استخدام جميع المركبات
-- =====================================================

SELECT
    v.id,
    v.plate_number,
    COUNT(d.id) AS usage_count
FROM vehicles v
LEFT JOIN deliveries d
    ON v.id = d.vehicle_id
GROUP BY
    v.id,
    v.plate_number
HAVING COUNT(d.id) > (
    SELECT AVG(vehicle_usage)
    FROM (
        SELECT
            v2.id,
            COUNT(d2.id) AS vehicle_usage
        FROM vehicles v2
        LEFT JOIN deliveries d2
            ON v2.id = d2.vehicle_id
        GROUP BY v2.id
    ) AS usage_table
);

-- =====================================================
-- Query 20
-- عرض الموظفين الذين رواتبهم أعلى من متوسط رواتب الموظفين
-- داخل نفس الفرع
-- =====================================================

SELECT
    e.id,
    e.full_name,
    e.branch_id,
    e.salary
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.branch_id = e.branch_id
);


-- =====================================================
-- Query 21
-- عرض أعلى موظف راتبًا داخل كل فرع
-- =====================================================

SELECT
    e.id,
    e.full_name,
    e.branch_id,
    e.salary
FROM employees e
WHERE e.salary = (
    SELECT MAX(e2.salary)
    FROM employees e2
    WHERE e2.branch_id = e.branch_id
);


-- =====================================================
-- Query 22
-- عرض ثاني أعلى راتب داخل كل فرع
-- =====================================================

SELECT
    id,
    full_name,
    branch_id,
    salary
FROM (
    SELECT
        e.id,
        e.full_name,
        e.branch_id,
        e.salary,
        DENSE_RANK() OVER (
            PARTITION BY e.branch_id
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM employees e
) AS ranked_employees
WHERE salary_rank = 2;


-- =====================================================
-- Query 23
-- عرض الفروع التي متوسط رواتب موظفيها أعلى من متوسط رواتب
-- جميع الموظفين في الشركة
-- =====================================================

SELECT
    b.id,
    b.branch_name,
    AVG(e.salary) AS branch_average_salary
FROM branches b
JOIN employees e
    ON b.id = e.branch_id
GROUP BY
    b.id,
    b.branch_name
HAVING AVG(e.salary) > (
    SELECT AVG(salary)
    FROM employees
);


-- =====================================================
-- Query 24
-- عرض العملاء الذين لديهم شحنة واحدة على الأقل ولكن لا توجد
-- لديهم أي شحنة تم تسليمها بنجاح
-- =====================================================

SELECT
    c.id,
    c.full_name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM shipments s
    WHERE s.customer_id = c.id
)
AND NOT EXISTS (
    SELECT 1
    FROM shipments s2
    WHERE s2.customer_id = c.id
      AND s2.shipment_status = 'delivered'
);


-- =====================================================
-- Query 25
-- عرض العملاء الذين لديهم شحنات في أكثر من فرع إرسال مختلف
-- =====================================================

SELECT
    c.id,
    c.full_name,
    COUNT(DISTINCT s.origin_branch_id) AS origin_branch_count
FROM customers c
JOIN shipments s
    ON c.id = s.customer_id
GROUP BY
    c.id,
    c.full_name
HAVING COUNT(DISTINCT s.origin_branch_id) > 1;


-- =====================================================
-- Query 26
-- عرض العملاء الذين لم ينشئوا أي شحنة خلال آخر 90 يومًا
-- =====================================================

SELECT
    c.id,
    c.full_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM shipments s
    WHERE s.customer_id = c.id
      AND s.created_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
);


-- =====================================================
-- Query 27
-- عرض الشحنات التي لا يوجد لها أي سجل داخل shipment_tracking
-- =====================================================

SELECT
    s.id,
    s.tracking_number
FROM shipments s
LEFT JOIN shipment_tracking st
    ON s.id = st.shipment_id
WHERE st.id IS NULL;


-- =====================================================
-- Query 28
-- عرض آخر حالة Tracking مسجلة لكل شحنة
-- =====================================================

SELECT
    st.id,
    st.shipment_id,
    s.tracking_number,
    st.status,
    st.description,
    st.recorded_at
FROM shipment_tracking st
JOIN shipments s
    ON st.shipment_id = s.id
WHERE st.recorded_at = (
    SELECT MAX(st2.recorded_at)
    FROM shipment_tracking st2
    WHERE st2.shipment_id = st.shipment_id
);


-- =====================================================
-- Query 29
-- عرض التاريخ الكامل لحركة شحنة باستخدام tracking_number
-- =====================================================

SELECT
    s.tracking_number,
    st.status,
    st.description,
    st.recorded_at,
    b.branch_name
FROM shipments s
JOIN shipment_tracking st
    ON s.id = st.shipment_id
JOIN branches b
    ON st.branch_id = b.id
WHERE s.tracking_number = 'TRK100001'
ORDER BY st.recorded_at ASC;


-- =====================================================
-- Query 30
-- حساب المدة بين إنشاء الشحنة وتسليمها لكل شحنة مكتملة
-- =====================================================

SELECT
    id,
    tracking_number,
    created_at,
    delivered_at,
    DATEDIFF(delivered_at, created_at) AS delivery_days
FROM shipments
WHERE shipment_status = 'delivered'
  AND delivered_at IS NOT NULL;


-- =====================================================
-- Query 31
-- حساب متوسط مدة التوصيل بالأيام
-- =====================================================

SELECT
    AVG(DATEDIFF(delivered_at, created_at)) AS average_delivery_days
FROM shipments
WHERE shipment_status = 'delivered'
  AND delivered_at IS NOT NULL;


-- =====================================================
-- Query 32
-- عرض الشحنات التي مدة توصيلها أعلى من متوسط مدة التوصيل
-- =====================================================

SELECT
    id,
    tracking_number,
    DATEDIFF(delivered_at, created_at) AS delivery_days
FROM shipments
WHERE shipment_status = 'delivered'
  AND delivered_at IS NOT NULL
  AND DATEDIFF(delivered_at, created_at) > (
      SELECT AVG(DATEDIFF(delivered_at, created_at))
      FROM shipments
      WHERE shipment_status = 'delivered'
        AND delivered_at IS NOT NULL
  );


-- =====================================================
-- Query 33
-- عرض نسبة الشحنات التي تم تسليمها بنجاح من إجمالي الشحنات
-- =====================================================

SELECT
    (
        SELECT COUNT(*)
        FROM shipments
        WHERE shipment_status = 'delivered'
    ) * 100.0 / COUNT(*) AS delivered_percentage
FROM shipments;


-- =====================================================
-- Query 34
-- عرض نسبة الشحنات الملغاة لكل فرع
-- =====================================================

SELECT
    b.id,
    b.branch_name,
    COUNT(CASE
        WHEN s.shipment_status = 'cancelled' THEN 1
    END) * 100.0 / COUNT(s.id) AS cancelled_percentage
FROM branches b
LEFT JOIN shipments s
    ON b.id = s.origin_branch_id
GROUP BY
    b.id,
    b.branch_name;


-- =====================================================
-- Query 35
-- عرض الإيرادات الشهرية للسنة الحالية
-- =====================================================

SELECT
    YEAR(payment_date) AS year,
    MONTH(payment_date) AS month,
    SUM(amount) AS monthly_revenue
FROM payments
WHERE YEAR(payment_date) = YEAR(CURDATE())
  AND status = 'successful'
GROUP BY
    YEAR(payment_date),
    MONTH(payment_date)
ORDER BY
    month;


-- =====================================================
-- Query 36
-- عرض الشهر صاحب أعلى إيرادات
-- =====================================================

SELECT
    MONTH(payment_date) AS month_number,
    MONTHNAME(payment_date) AS month_name,
    SUM(amount) AS monthly_revenue
FROM payments
WHERE status = 'successful'
  AND YEAR(payment_date) = YEAR(CURDATE())
GROUP BY
    MONTH(payment_date),
    MONTHNAME(payment_date)
ORDER BY monthly_revenue DESC
LIMIT 1;

-- =====================================================
-- Query 37
-- عرض الإيرادات حسب طريقة الدفع
-- =====================================================

SELECT
    payment_method,
    SUM(amount) AS total_revenue
FROM payments
WHERE status = 'successful'
GROUP BY payment_method
ORDER BY total_revenue DESC;


-- =====================================================
-- Query 38
-- عرض عمليات الدفع التي قيمتها مختلفة عن تكلفة الشحنة المرتبطة بها
-- =====================================================


SELECT
    p.id AS payment_id,
    p.shipment_id,
    p.amount AS payment_amount,
    s.shipping_cost,
    p.status
FROM payments p
JOIN shipments s
    ON p.shipment_id = s.id
WHERE p.status = 'successful'
  AND p.amount <> s.shipping_cost;
    


-- =====================================================
-- Query 39
-- عرض الشحنات التي حالتها paid ولكن لا يوجد لها سجل دفع ناجح
-- =====================================================

SELECT
    s.id,
    s.tracking_number,
    s.payment_status
FROM shipments s
WHERE s.payment_status = 'paid'
  AND NOT EXISTS (
      SELECT 1
      FROM payments p
      WHERE p.shipment_id = s.id
        AND p.status = 'successful'
  );


-- =====================================================
-- Query 40
-- عرض العملاء الذين مجموع إنفاقهم أعلى من متوسط إنفاق جميع العملاء
-- =====================================================
SELECT
    c.id,
    c.full_name,
    COALESCE(SUM(
        CASE
            WHEN p.status = 'successful' THEN p.amount
            ELSE 0
        END
    ), 0) AS total_spending
FROM customers c
LEFT JOIN shipments s
    ON c.id = s.customer_id
LEFT JOIN payments p
    ON s.id = p.shipment_id
GROUP BY
    c.id,
    c.full_name
HAVING total_spending > (
    SELECT AVG(customer_spending)
    FROM (
        SELECT
            c2.id,
            COALESCE(SUM(
                CASE
                    WHEN p2.status = 'successful' THEN p2.amount
                    ELSE 0
                END
            ), 0) AS customer_spending
        FROM customers c2
        LEFT JOIN shipments s2
            ON c2.id = s2.customer_id
        LEFT JOIN payments p2
            ON s2.id = p2.shipment_id
        GROUP BY c2.id
    ) AS spending_table
);
-------=================================================================================
         ---------------------FINAL END-TO-END TEST-----------------------------
--=====================================================================================


The final end-to-end test validates the complete logistics workflow from customer creation to successful shipment delivery.

-- Test Flow

Customer
   ↓
Shipment
   ↓
Payment
   ↓
Initial Tracking
   ↓
Driver + Vehicle Assignment
   ↓
Delivery Started
   ↓
In-Transit Tracking
   ↓
Delivery Completed
   ↓
Final Delivered Tracking
```

---

 1. Create Customer

A new customer was created specifically for the final system test.

The customer was successfully inserted into the `customers` table with an active status.

---

 2. Create Shipment

A new shipment was created using the `create_shipment` stored procedure.

The procedure successfully:

- Created the shipment.
- Generated the shipment ID.
- Created the first tracking record.
- Set the initial shipment status to `created`.

Test tracking number:

FINALTEST001


---
 3. Create Payment

A successful payment was created for the test shipment.

The payment was correctly linked to the shipment through `shipment_id`.

The payment status was:


successful

The payment amount matched the shipment shipping cost.

---

 4. Initial Shipment Tracking

The first tracking record was created with status:


created


This confirmed that every newly created shipment can have an initial movement record.



 5. Assign Driver and Vehicle

The shipment was assigned to:

- An active driver.
- An available vehicle.
- A vehicle with sufficient weight capacity.

The `assign_delivery` stored procedure successfully created the delivery with status:


assigned


The vehicle remained:


available


until the delivery actually started.

---

 6. Start Delivery

The delivery status was changed from:


assigned


to:
in_progress


The corresponding trigger automatically changed the vehicle status from:


available

to:


in_delivery


This confirmed that the vehicle-status trigger works correctly.

---

 7. Add In-Transit Tracking

A new tracking record was inserted with status:


in_transit


The tracking trigger automatically updated the shipment status to:


in_transit


This confirmed that shipment status remains synchronized with shipment movement history.

---
 8. Complete Delivery

The `complete_delivery` stored procedure was executed successfully.

The procedure completed the delivery transaction and:

- Set the delivery status to `completed`.
- Updated the shipment status to `delivered`.
- Set `delivered_at`.
- Added a final `delivered` tracking record.
- Returned the vehicle to `available`.
- Used transaction handling to protect the operation from partial updates.

---

9. Final Tracking History

The final tracking history contained the expected movement sequence:


created
in_transit
delivered


This confirms that the system preserves the complete shipment movement history.

---

 10. Final Verification

The final state was verified across the related tables.

 Shipment


shipment_status = delivered
delivered_at IS NOT NULL
payment_status = paid

    
 Payment

status = successful


 Delivery


delivery_status = completed
completed_at IS NOT NULL


 Vehicle


status = available

 Tracking


created → in_transit → delivered


The relationships between customer, shipment, payment, delivery, driver, vehicle, and tracking records were verified successfully.

No orphan records were introduced during the final test.

---

**Final Result

The Logistics & Delivery Management System successfully completed the complete end-to-end workflow:


Customer
→ Shipment
→ Payment
→ Tracking
→ Driver Assignment
→ Vehicle Assignment
→ Delivery Start
→ In Transit
→ Delivery Completion
→ Final Tracking
```

The final shipment state, payment, delivery, vehicle status, and tracking history were all verified successfully.







