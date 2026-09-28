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
