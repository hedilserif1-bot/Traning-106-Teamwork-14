-- أمر أنشاء قاعدة البيانات مع الترميز الخاص بها 

CREATE DATABASE hospital_management
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
USE hospital_management;

-- أمر إنشاء جدول ال ( departments ) مع الحماية الكاملة عليه 

CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL CHECK (TRIM(department_name) <> ''),
    floor_number INT NOT NULL CHECK (TRIM(floor_number) <> ''),
    phone VARCHAR(20) NOT NULL CHECK (TRIM(phone) <> ''),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance'))
);

-- كود إضافة فرس على عمودي إسم القسم و رقم الطابق

CREATE UNIQUE INDEX idx_departments_name_floor ON departments (department_name, floor_number);

-- أمر إنشاء جدول ( doctors ) مع الحماية الكاملة عليه 

CREATE TABLE doctors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    department_id INT NOT NULL,
    full_name VARCHAR(150) NOT NULL CHECK (TRIM(full_name) <> ''),
    email VARCHAR(150) NOT NULL UNIQUE CHECK (TRIM(email) <> ''),
    phone VARCHAR(20) NOT NULL UNIQUE CHECK (TRIM(phone) <> ''),
    specialization VARCHAR(100) NOT NULL CHECK (TRIM(specialization) <> ''),
    license_number VARCHAR(100) NOT NULL UNIQUE CHECK (TRIM(license_number) <> ''),
    hire_date DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    consultation_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (consultation_fee >= 0.00),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave')),
    FOREIGN KEY (department_id) REFERENCES departments(id)
);

-- أمر إنشاء الفهارس المناسبة على جدول الاطباء لتسهيل البحث 

CREATE INDEX idx_doctors_department ON doctors (department_id);
CREATE INDEX idx_doctors_specialization ON doctors (specialization);

-- أمر إنشاء جدول ال ( patients ) مع الحماية الكاملة عليه

CREATE TABLE patients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(150) NOT NULL CHECK (TRIM(full_name) <> ''),
    national_id VARCHAR(50) NOT NULL UNIQUE CHECK (TRIM(national_id) <> ''),
    birth_date DATE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    gender VARCHAR(20) NOT NULL CHECK (gender IN ('Male', 'Female')),
    phone VARCHAR(20) NOT NULL UNIQUE CHECK (TRIM(phone) <> ''),
    email VARCHAR(150) NOT NULL UNIQUE CHECK (TRIM(email) <> ''),
    blood_type VARCHAR(10) NOT NULL CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    city VARCHAR(100) NOT NULL CHECK (TRIM(city) <> ''),
    address VARCHAR(255) NOT NULL CHECK (TRIM(address) <> ''),
    emergency_contact_name VARCHAR(150) NOT NULL CHECK (TRIM(emergency_contact_name) <> ''),
    emergency_contact_phone VARCHAR(20) NOT NULL CHECK (TRIM(emergency_contact_phone) <> ''),
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'admitted'))
);

-- أمر أنشاء فهرس على الجدول لتسهيل البحث 

CREATE INDEX idx_patients_city ON patients (city);
CREATE INDEX idx_patients_phone ON patients (phone);




