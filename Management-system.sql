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
