-- أمر إنشاء قاعدة البيانات مع الترميز الخاص بها 

CREATE DATABASE hospital_management
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE hospital_management;


-- أمر إنشاء جدول ال ( departments ) مع الحماية الكاملة عليه 

CREATE TABLE departments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL CHECK (TRIM(department_name) <> ''),
    floor_number INT NOT NULL CHECK (floor_number > 0),
    phone VARCHAR(20) NOT NULL CHECK (TRIM(phone) <> ''),
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive', 'maintenance'))
);


-- كود إضافة فهرس على عمودي اسم القسم ورقم الطابق

CREATE UNIQUE INDEX idx_departments_name_floor
ON departments (department_name, floor_number);



-- أمر إنشاء جدول ( doctors ) مع الحماية الكاملة عليه 

CREATE TABLE doctors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    department_id INT NOT NULL,
    full_name VARCHAR(150) NOT NULL CHECK (TRIM(full_name) <> ''),
    email VARCHAR(150) NOT NULL UNIQUE CHECK (TRIM(email) <> ''),
    phone VARCHAR(20) NOT NULL UNIQUE CHECK (TRIM(phone) <> ''),
    specialization VARCHAR(100) NOT NULL CHECK (TRIM(specialization) <> ''),
    license_number VARCHAR(100) NOT NULL UNIQUE CHECK (TRIM(license_number) <> ''),
    hire_date DATE NOT NULL,
    consultation_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00
        CHECK (consultation_fee >= 0.00),
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive', 'on_leave')),

    FOREIGN KEY (department_id)
        REFERENCES departments(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


-- أمر إنشاء الفهارس المناسبة على جدول الأطباء لتسهيل البحث 

CREATE INDEX idx_doctors_department
ON doctors (department_id);

CREATE INDEX idx_doctors_specialization
ON doctors (specialization);



-- أمر إنشاء جدول ال ( patients ) مع الحماية الكاملة عليه

CREATE TABLE patients (
    id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(150) NOT NULL CHECK (TRIM(full_name) <> ''),
    national_id VARCHAR(50) NOT NULL UNIQUE CHECK (TRIM(national_id) <> ''),
    birth_date DATE NOT NULL,
    gender VARCHAR(20) NOT NULL
        CHECK (gender IN ('Male', 'Female')),
    phone VARCHAR(20) NOT NULL UNIQUE CHECK (TRIM(phone) <> ''),
    email VARCHAR(150) NOT NULL UNIQUE CHECK (TRIM(email) <> ''),
    blood_type VARCHAR(10) NOT NULL
        CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    city VARCHAR(100) NOT NULL CHECK (TRIM(city) <> ''),
    address VARCHAR(255) NOT NULL CHECK (TRIM(address) <> ''),
    emergency_contact_name VARCHAR(150) NOT NULL
        CHECK (TRIM(emergency_contact_name) <> ''),
    emergency_contact_phone VARCHAR(20) NOT NULL
        CHECK (TRIM(emergency_contact_phone) <> ''),
    registered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive', 'admitted'))
);


-- أمر إنشاء فهرس على الجدول لتسهيل البحث 

CREATE INDEX idx_patients_city
ON patients (city);



-- أمر إنشاء جدول ( rooms ) مع حماية كل الأعمدة 

CREATE TABLE rooms (
    id INT PRIMARY KEY AUTO_INCREMENT,
    department_id INT NOT NULL,
    room_number VARCHAR(50) NOT NULL UNIQUE
        CHECK (TRIM(room_number) <> ''),
    room_type VARCHAR(50) NOT NULL
        CHECK (room_type IN ('normal', 'private', 'icu', 'emergency')),
    floor_number INT NOT NULL
        CHECK (floor_number > 0),
    daily_price DECIMAL(10,2) NOT NULL DEFAULT 0.00
        CHECK (daily_price >= 0.00),
    status VARCHAR(20) NOT NULL DEFAULT 'available'
        CHECK (status IN ('available', 'occupied', 'maintenance', 'inactive')),

    FOREIGN KEY (department_id)
        REFERENCES departments(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


-- أمر إنشاء فهارس على الجدول لتسهيل البحث 

CREATE INDEX idx_rooms_department
ON rooms (department_id);

CREATE INDEX idx_rooms_status
ON rooms (status);



-- أمر إنشاء جدول ال ( appointments ) مع الحماية الكاملة عليه

CREATE TABLE appointments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    reason VARCHAR(255) NOT NULL CHECK (TRIM(reason) <> ''),
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled'
        CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (patient_id)
        REFERENCES patients(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    FOREIGN KEY (doctor_id)
        REFERENCES doctors(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);


-- إضافة فهارس على الجدول لتسهيل عملية البحث 

CREATE INDEX idx_appointments_patient
ON appointments (patient_id);

CREATE INDEX idx_appointments_doctor
ON appointments (doctor_id);

CREATE INDEX idx_appointments_date
ON appointments (appointment_date);



-- أمر إنشاء جدول ال ( medical_visits ) مع الحماية الكاملة عليه

CREATE TABLE medical_visits (
    id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_id INT NOT NULL DEFAULT 0,
    visit_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    symptoms VARCHAR(255) NOT NULL CHECK (TRIM(symptoms) <> ''),
    diagnosis VARCHAR(255) NOT NULL CHECK (TRIM(diagnosis) <> ''),
    doctor_notes VARCHAR(500) NOT NULL DEFAULT 'لا توجد ملاحظات' CHECK (TRIM(doctor_notes) <> ''),
    follow_up_date DATE NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- أمر إنشاء الفهارس لتسهيل البحث بالجدول 

CREATE INDEX idx_medical_visits_patient ON medical_visits (patient_id);
CREATE INDEX idx_medical_visits_doctor ON medical_visits (doctor_id);
CREATE INDEX idx_medical_visits_date ON medical_visits (visit_date);

-- أمر إنشاء مشغل ( trigger ) لحماية الفهرس الاجنبي

DELIMITER //

CREATE TRIGGER check_appointment_validity
BEFORE INSERT ON medical_visits
FOR EACH ROW
BEGIN
    IF NEW.appointment_id <> 0 AND NOT EXISTS (SELECT 1 FROM appointments WHERE id = NEW.appointment_id) THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Error: Appointment ID does not exist in the system!';
    END IF;
END;
//

DELIMITER ;

-- أمر إنشاء جدول ( medicines ) مع الحماية الخاصة بالاعمدة

CREATE TABLE medicines (
    id INT PRIMARY KEY AUTO_INCREMENT,
    medicine_name VARCHAR(100) NOT NULL DEFAULT 'Unnamed Medicine' CHECK (TRIM(medicine_name) <> ''),
    manufacturer VARCHAR(100) NOT NULL DEFAULT 'Unknown' CHECK (TRIM(manufacturer) <> ''),
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (unit_price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    minimum_stock INT NOT NULL DEFAULT 0 CHECK (minimum_stock >= 0),
    expiry_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Available' CHECK (status IN ('Available', 'Out of Stock', 'Expired', 'Discontinued'))
);

-- أمر انشاء الفهارس المناسبة لنسهيل الاستعلام 

CREATE INDEX idx_medicines_name ON medicines (medicine_name);
CREATE INDEX idx_medicines_status ON medicines (status);
CREATE INDEX idx_medicines_expiry ON medicines (expiry_date);

-- أمر إنشاء جدول ( prescriptions ) مع حمايته 

CREATE TABLE prescriptions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    visit_id INT NOT NULL,
    prescribed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(500) NOT NULL DEFAULT 'لا توجد ملاحظات' CHECK (TRIM(notes) <> ''), 
    FOREIGN KEY (visit_id) REFERENCES medical_visits(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- أمر إنشاء الفهارس على الجدول لتسهيل البحث فيه

CREATE INDEX idx_prescriptions_visit ON prescriptions (visit_id);

-- أمر إنشاء جدول ( prescription_items ) مع الحماية على الجداول

CREATE TABLE prescription_items (
    id INT PRIMARY KEY AUTO_INCREMENT,
    prescription_id INT NOT NULL,
    medicine_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL CHECK (TRIM(dosage) <> ''),
    frequency VARCHAR(100) NOT NULL CHECK (TRIM(frequency) <> ''),
    duration_days INT NOT NULL DEFAULT 1 CHECK (duration_days > 0),
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- أمر إنشاء الفهارس على الجدول 

CREATE INDEX idx_prescription_items_prescription ON prescription_items (prescription_id);
CREATE INDEX idx_prescription_items_medicine ON prescription_items (medicine_id);

-- أمر إنشاء جدول ( lab_tests ) مع كامل الحماية عليه

CREATE TABLE lab_tests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    test_name VARCHAR(100) NOT NULL DEFAULT 'Unnamed Test' CHECK (TRIM(test_name) <> ''),
    category VARCHAR(100) NOT NULL DEFAULT 'General' CHECK (TRIM(category) <> ''),
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (price >= 0),
    normal_range VARCHAR(100) NOT NULL DEFAULT 'Not Specified' CHECK (TRIM(normal_range) <> '')
    status VARCHAR(50) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive', 'Discontinued'))
);

-- أمر إنشاء الفهارس على الجدول لتسهيل البحث

CREATE INDEX idx_lab_tests_name ON lab_tests (test_name);
CREATE INDEX idx_lab_tests_category ON lab_tests (category);
CREATE INDEX idx_lab_tests_status ON lab_tests (status);

-- أمر إنشاء جدول ( patient_lab_tests ) مع الحماية الكاملة على اعمدته 

CREATE TABLE patient_lab_tests (
    id INT PRIMARY KEY AUTO_INCREMENT,
    visit_id INT NOT NULL,
    lab_test_id INT NOT NULL,
    ordered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME NULL,
    result TEXT NOT NULL DEFAULT 'Pending Result' CHECK (TRIM(result) <> ''),
    result_status VARCHAR(50) NOT NULL DEFAULT 'Normal' CHECK (TRIM(result_status) <> ''),
    status VARCHAR(50) NOT NULL DEFAULT 'ordered' CHECK (status IN ('ordered', 'processing', 'completed', 'cancelled')),
    FOREIGN KEY (visit_id) REFERENCES medical_visits(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (lab_test_id) REFERENCES lab_tests(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (completed_at >= ordered_at)
);

-- أمر انشاء الفهارس المناسبة على الجدول 

CREATE INDEX idx_patient_lab_tests_visit ON patient_lab_tests (visit_id);
CREATE INDEX idx_patient_lab_tests_test ON patient_lab_tests (lab_test_id);
CREATE INDEX idx_patient_lab_tests_status ON patient_lab_tests (status);

-- أمر إنشاء جدول (admissions) مع حمايته

CREATE TABLE admissions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    room_id INT NOT NULL,
    doctor_id INT NOT NULL,
    admitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    discharged_at DATETIME NULL,
    admission_reason VARCHAR(255) NOT NULL DEFAULT 'General Admission' CHECK (TRIM(admission_reason) <> ''),
    status VARCHAR(50) NOT NULL DEFAULT 'admitted' CHECK (status IN ('admitted', 'discharged', 'cancelled')),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (room_id) REFERENCES rooms(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (discharged_at >= admitted_at)
);

-- أمر إنشاء الفهارس المناسبة لتسهيل البحث

CREATE INDEX idx_admissions_patient ON admissions (patient_id);
CREATE INDEX idx_admissions_room ON admissions (room_id);
CREATE INDEX idx_admissions_doctor ON admissions (doctor_id);
CREATE INDEX idx_admissions_status ON admissions (status);
CREATE INDEX idx_admissions_admitted_at ON admissions (admitted_at);

-- أمر إنشاء جدول ( insurance_companies ) مع حمايته  

CREATE TABLE insurance_companies (
    id INT PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(100) NOT NULL DEFAULT 'Unnamed Company' CHECK (TRIM(company_name) <> ''),
    phone VARCHAR(50) NOT NULL UNIQUE DEFAULT 'Not Specified' CHECK (TRIM(phone) <> ''),
    email VARCHAR(100) NOT NULL UNIQUE DEFAULT 'no-email@hospital.com' CHECK (TRIM(email) <> ''),
    coverage_percentage DECIMAL(5, 2) NOT NULL DEFAULT 0.00 CHECK (coverage_percentage >= 0 AND coverage_percentage <= 100),
    status VARCHAR(50) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive'))
);

-- أمر إنشاء الفهارس المناسبة 

CREATE INDEX idx_insurance_companies_name ON insurance_companies (company_name);
CREATE INDEX idx_insurance_companies_status ON insurance_companies (status);

-- أمر إنشاء جدول ( patient_insurance ) مع حمايته كاملاً 
 
CREATE TABLE patient_insurance (
    id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    insurance_company_id INT NOT NULL,
    policy_number VARCHAR(100) NOT NULL UNIQUE CHECK (TRIM(policy_number) <> ''),
    start_date DATE NOT NULL,
    expiry_date DATE NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Expired', 'Cancelled')),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (insurance_company_id) REFERENCES insurance_companies(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (expiry_date >= start_date)
);

-- أمر إنشاء الفهارس المناسبة 

CREATE INDEX idx_patient_insurance_patient ON patient_insurance (patient_id);
CREATE INDEX idx_patient_insurance_company ON patient_insurance (insurance_company_id);
CREATE INDEX idx_patient_insurance_status ON patient_insurance (status);

-- أمر إنشاء جدول ال ( invoices ) مع حماية كل اعمدته بالكامل 

CREATE TABLE invoices (
    id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    visit_id INT NOT NULL,
    admission_id INT NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (subtotal >= 0),
    insurance_discount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (insurance_discount >= 0),
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0),
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date DATE NOT NULL,
    payment_status VARCHAR(50) NOT NULL DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'partially_paid', 'paid', 'cancelled')),
    FOREIGN KEY (patient_id) REFERENCES patients(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (visit_id) REFERENCES medical_visits(id) ON UPDATE CASCADE ON DELETE RESTRICT,
    FOREIGN KEY (admission_id) REFERENCES admissions(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- أمر إنشاء الفهارس المناسبة على الجدول لتسهيل عملية البحث 

CREATE INDEX idx_invoices_patient ON invoices (patient_id);
CREATE INDEX idx_invoices_visit ON invoices (visit_id);
CREATE INDEX idx_invoices_admission ON invoices (admission_id);
CREATE INDEX idx_invoices_status ON invoices (payment_status);
CREATE INDEX idx_invoices_issued_at ON invoices (issued_at);

-- أمر إنشاء جدول ( payments ) مع حمايه كل الاعمدة 

CREATE TABLE payments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_id INT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 CHECK (amount >= 0),
    payment_method VARCHAR(50) NOT NULL DEFAULT 'cash' CHECK (payment_method IN ('cash', 'card', 'pix', 'bank_transfer', 'insurance')),
    transaction_reference VARCHAR(100) NOT NULL DEFAULT 'N/A' CHECK (TRIM(transaction_reference) <> ''),
    paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'failed', 'refunded')),
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- أمر إنشاء كل الفهارس المناسبة لتسهيل البحث

CREATE INDEX idx_payments_invoice ON payments (invoice_id);
CREATE INDEX idx_payments_status ON payments (status);
CREATE INDEX idx_payments_method ON payments (payment_method);

-- من هنا تبدا أكواد إدخال البيانات 

-- امر إدخال البيانات على الجدول الاول ( departments )

INSERT INTO departments (department_name, floor_number, phone, status) VALUES
('Emergency Department', 1, '+1-555-0101', 'active'),
('Cardiology', 2, '+1-555-0102', 'active'),
('Pediatrics', 3, '+1-555-0103', 'active'),
('Orthopedics', 2, '+1-555-0104', 'active'),
('Neurology', 4, '+1-555-0105', 'active'),
('Radiology', 1, '+1-555-0106', 'active'),
('Internal Medicine', 3, '+1-555-0107', 'active'),
('Ophthalmology', 4, '+1-555-0108', 'active');

-- أمر إدخال البيانات على الجدول الثاني ( doctors )

INSERT INTO doctors (department_id, full_name, email, phone, specialization, license_number, hire_date, consultation_fee, status) VALUES
(1, 'Dr. Ahmed Al-Masri', 'ahmed.masri@hospital.com', '+1-555-1101', 'Emergency Medicine', 'LIC-1001', '2022-01-15', 150.00, 'active'),
(2, 'Dr. Sarah Johnson', 'sarah.johnson@hospital.com', '+1-555-1102', 'Cardiologist', 'LIC-1002', '2021-05-20', 250.00, 'active'),
(3, 'Dr. Mohammed Al-Khatib', 'mohammed.khatib@hospital.com', '+1-555-1103', 'Pediatrician', 'LIC-1003', '2023-02-10', 120.00, 'active'),
(4, 'Dr. Emily Davis', 'emily.davis@hospital.com', '+1-555-1104', 'Orthopedic Surgeon', 'LIC-1004', '2020-11-05', 300.00, 'active'),
(5, 'Dr. Omar Farooq', 'omar.farooq@hospital.com', '+1-555-1105', 'Neurologist', 'LIC-1005', '2019-08-12', 280.00, 'active'),
(6, 'Dr. Laura Wilson', 'laura.wilson@hospital.com', '+1-555-1106', 'Radiologist', 'LIC-1006', '2022-04-18', 200.00, 'active'),
(7, 'Dr. Khalid Mansour', 'khalid.mansour@hospital.com', '+1-555-1107', 'Internal Medicine', 'LIC-1007', '2021-09-30', 140.00, 'active'),
(8, 'Dr. Jessica Taylor', 'jessica.taylor@hospital.com', '+1-555-1108', 'Ophthalmologist', 'LIC-1008', '2023-01-25', 180.00, 'active'),
(1, 'Dr. Rami Nazzal', 'rami.nazzal@hospital.com', '+1-555-1109', 'Emergency Medicine', 'LIC-1009', '2023-06-11', 150.00, 'active'),
(2, 'Dr. Elena Rostova', 'elena.rostova@hospital.com', '+1-555-1110', 'Cardiologist', 'LIC-1010', '2020-03-14', 250.00, 'active'),
(3, 'Dr. Youssef Nader', 'youssef.nader@hospital.com', '+1-555-1111', 'Pediatrician', 'LIC-1011', '2022-10-01', 120.00, 'active'),
(4, 'Dr. Anna Smith', 'anna.smith@hospital.com', '+1-555-1112', 'Orthopedic Surgeon', 'LIC-1012', '2021-12-19', 300.00, 'active'),
(5, 'Dr. Ziad Tariq', 'ziad.tariq@hospital.com', '+1-555-1113', 'Neurologist', 'LIC-1013', '2022-07-07', 280.00, 'active'),
(6, 'Dr. Maria Garcia', 'maria.garcia@hospital.com', '+1-555-1114', 'Radiologist', 'LIC-1014', '2018-05-16', 200.00, 'active'),
(7, 'Dr. Hassan Al-Amine', 'hassan.amine@hospital.com', '+1-555-1115', 'Internal Medicine', 'LIC-1015', '2023-03-22', 140.00, 'active'),
(8, 'Dr. Chloe Martin', 'chloe.martin@hospital.com', '+1-555-1116', 'Ophthalmologist', 'LIC-1016', '2020-09-09', 180.00, 'active'),
(1, 'Dr. Fadi Haddad', 'fadi.haddad@hospital.com', '+1-555-1117', 'Emergency Medicine', 'LIC-1017', '2024-01-10', 160.00, 'active'),
(2, 'Dr. Robert Chen', 'robert.chen@hospital.com', '+1-555-1118', 'Cardiologist', 'LIC-1018', '2019-11-25', 260.00, 'active'),
(3, 'Dr. Mona Zaki', 'mona.zaki@hospital.com', '+1-555-1119', 'Pediatrician', 'LIC-1019', '2023-08-14', 125.00, 'active'),
(4, 'Dr. David Miller', 'david.miller@hospital.com', '+1-555-1120', 'Orthopedic Surgeon', 'LIC-1020', '2021-02-28', 290.00, 'active'),
(5, 'Dr. Samer Kassir', 'samer.kassir@hospital.com', '+1-555-1121', 'Neurologist', 'LIC-1021', '2022-05-12', 270.00, 'active'),
(6, 'Dr. Raniah Saed', 'raniah.saed@hospital.com', '+1-555-1122', 'Radiologist', 'LIC-1022', '2023-04-05', 190.00, 'active'),
(7, 'Dr. Tarek Basha', 'tarek.basha@hospital.com', '+1-555-1123', 'Internal Medicine', 'LIC-1023', '2020-10-15', 135.00, 'active'),
(8, 'Dr. Nadine Labaki', 'nadine.labaki@hospital.com', '+1-555-1124', 'Ophthalmologist', 'LIC-1024', '2021-07-19', 175.00, 'active'),
(2, 'Dr. Karim Fawzi', 'karim.fawzi@hospital.com', '+1-555-1125', 'Cardiologist', 'LIC-1025', '2024-02-01', 250.00, 'active');

-- أمر إدخال بيانات في جدول ال ( patients )

INSERT INTO patients (full_name, national_id, birth_date, gender, phone, email, blood_type, city, address, emergency_contact_name, emergency_contact_phone, registered_at, status) VALUES
('Ibrahim Al-Sayed', 'ID100001', '1985-05-12', 'Male', '+1-555-2001', 'ibrahim.sayed@gmail.com', 'A+', 'Beirut', 'Street 10, Building 3', 'Fatima Al-Sayed', '+1-555-2901', '2026-01-10 10:00:00', 'active'),
('Zainab Ali', 'ID100002', '1990-08-22', 'Female', '+1-555-2002', 'zainab.ali@gmail.com', 'O+', 'Beirut', 'Street 5, Building 12', 'Ali Ali', '+1-555-2902', '2026-01-11 11:30:00', 'active'),
('Mahmoud Hassan', 'ID100003', '1975-03-15', 'Male', '+1-555-2003', 'mahmoud.hassan@gmail.com', 'B+', 'Tripoli', 'Main Road, Apt 4', 'Amina Hassan', '+1-555-2903', '2026-01-12 09:15:00', 'active'),
('Layla Mourad', 'ID100004', '1992-11-30', 'Female', '+1-555-2004', 'layla.mourad@gmail.com', 'AB+', 'Sidon', 'Sea Side Ave', 'Samir Mourad', '+1-555-2904', '2026-01-15 14:20:00', 'active'),
('Khaled Othman', 'ID100005', '1982-07-19', 'Male', '+1-555-2005', 'khaled.othman@gmail.com', 'O-', 'Byblos', 'Old Market St', 'Rula Othman', '+1-555-2905', '2026-01-16 08:45:00', 'active'),
('Nourhan Salem', 'ID100006', '1998-02-05', 'Female', '+1-555-2006', 'nourhan.salem@gmail.com', 'A-', 'Zahle', 'University St', 'Tamer Salem', '+1-555-2906', '2026-01-18 16:00:00', 'active'),
('Sami Barakat', 'ID100007', '1968-12-01', 'Male', '+1-555-2007', 'sami.barakat@gmail.com', 'B-', 'Beirut', 'Hamra St', 'Nada Barakat', '+1-555-2907', '2026-01-20 10:10:00', 'active'),
('Raniah Jaber', 'ID100008', '1995-06-25', 'Female', '+1-555-2008', 'rania.jaber@gmail.com', 'AB-', 'Tripoli', '醫院 St', 'Hadi Jaber', '+1-555-2908', '2026-01-22 13:50:00', 'active'),
('Bilal Nasser', 'ID100009', '1988-09-10', 'Male', '+1-555-2009', 'bilal.nasser@gmail.com', 'O+', 'Tyre', 'Corniche Rd', 'Sawsan Nasser', '+1-555-2909', '2026-01-25 09:30:00', 'active'),
('Dina Farhat', 'ID100010', '2000-04-14', 'Female', '+1-555-2010', 'dina.farhat@gmail.com', 'A+', 'Beirut', 'Achrafieh St', 'Ziad Farhat', '+1-555-2910', '2026-01-26 11:00:00', 'active'),
('Tariq Zidan', 'ID100011', '1979-10-03', 'Male', '+1-555-2011', 'tariq.zidan@gmail.com', 'B+', 'Sidon', 'Park Ave', 'Mona Zidan', '+1-555-2911', '2026-01-28 15:15:00', 'active'),
('Hala Kanso', 'ID100012', '1993-01-18', 'Female', '+1-555-2012', 'hala.kanso@gmail.com', 'O-', 'Jounieh', 'Bay Rd', 'Adel Kanso', '+1-555-2912', '2026-02-01 08:30:00', 'active'),
('Rami Daher', 'ID100013', '1986-07-28', 'Male', '+1-555-2013', 'rami.daher@gmail.com', 'A-', 'Beirut', 'Verdun St', 'Noha Daher', '+1-555-2913', '2026-02-03 12:00:00', 'active'),
('Yasmin Radi', 'ID100014', '1991-05-09', 'Female', '+1-555-2014', 'yasmin.radi@gmail.com', 'AB+', 'Tripoli', 'Al-Mina St', 'Karim Radi', '+1-555-2914', '2026-02-05 10:45:00', 'active'),
('Adel Shami', 'ID100015', '1972-12-19', 'Male', '+1-555-2015', 'adel.shami@gmail.com', 'B-', 'Zahle', 'Main St', 'Samira Shami', '+1-555-2915', '2026-02-08 09:00:00', 'active'),
('Maha Traboulsi', 'ID100016', '1997-03-21', 'Female', '+1-555-2016', 'maha.traboulsi@gmail.com', 'O+', 'Beirut', 'Ras Beirut', 'Fadi Traboulsi', '+1-555-2916', '2026-02-10 14:10:00', 'active'),
('Wael Halabi', 'ID100017', '1980-08-11', 'Male', '+1-555-2017', 'wael.halabi@gmail.com', 'A+', 'Sidon', 'Old City', 'Rima Halabi', '+1-555-2917', '2026-02-12 11:20:00', 'active'),
('Sawsan Akari', 'ID100018', '1994-09-17', 'Female', '+1-555-2018', 'sawsan.akari@gmail.com', 'AB-', 'Byblos', 'Harbor Rd', 'Nabil Akari', '+1-555-2918', '2026-02-15 16:30:00', 'active'),
('Ziad Maalouf', 'ID100019', '1977-06-04', 'Male', '+1-555-2019', 'ziad.maalouf@gmail.com', 'B+', 'Beirut', 'Badaro St', 'Eliane Maalouf', '+1-555-2919', '2026-02-18 10:00:00', 'active'),
('Nadine Salam', 'ID100020', '1989-10-29', 'Female', '+1-555-2020', 'nadine.salam@gmail.com', 'O-', 'Tripoli', 'Azmi St', 'George Salam', '+1-555-2920', '2026-02-20 13:15:00', 'active'),
('Fadi Ghanem', 'ID100021', '1983-02-14', 'Male', '+1-555-2021', 'fadi.ghanem@gmail.com', 'A-', 'Beirut', 'Mar Mikhael', 'Maya Ghanem', '+1-555-2921', '2026-02-22 09:40:00', 'active'),
('Maya Karam', 'ID100022', '1996-12-07', 'Female', '+1-555-2022', 'maya.karam@gmail.com', 'B-', 'Zahle', 'Industrial Rd', 'Joseph Karam', '+1-555-2922', '2026-02-25 15:00:00', 'active'),
('Nabil Kassir', 'ID100023', '1974-04-20', 'Male', '+1-555-2023', 'nabil.kassir@gmail.com', 'AB+', 'Sidon', 'Riad El Solh', 'Salma Kassir', '+1-555-2923', '2026-02-28 08:50:00', 'active'),
('Rula Saad', 'ID100024', '1990-07-13', 'Female', '+1-555-2024', 'rula.saad@gmail.com', 'O+', 'Tyre', 'Al-Bass St', 'Elias Saad', '+1-555-2924', '2026-03-01 10:30:00', 'active'),
('Elias Matar', 'ID100025', '1981-11-02', 'Male', '+1-555-2025', 'elias.matar@gmail.com', 'A+', 'Beirut', 'Furn El Chebbak', 'Carla Matar', '+1-555-2925', '2026-03-03 12:20:00', 'active'),
('Carla Khoury', 'ID100026', '1995-01-26', 'Female', '+1-555-2026', 'carla.khoury@gmail.com', 'B+', 'Jounieh', 'Autostrad', 'Georges Khoury', '+1-555-2926', '2026-03-05 14:00:00', 'active'),
('Georges Chaoul', 'ID100027', '1976-06-18', 'Male', '+1-555-2027', 'georges.chaoul@gmail.com', 'O-', 'Byblos', 'University Rd', 'Therese Chaoul', '+1-555-2927', '2026-03-08 09:10:00', 'active'),
('Therese Azar', 'ID100028', '1992-08-05', 'Female', '+1-555-2028', 'therese.azar@gmail.com', 'AB-', 'Beirut', 'Sodeco', 'Pierre Azar', '+1-555-2928', '2026-03-10 11:45:00', 'active'),
('Pierre Sfeir', 'ID100029', '1984-03-09', 'Male', '+1-555-2029', 'pierre.sfeir@gmail.com', 'A-', 'Tripoli', 'Tall Square', 'Noha Sfeir', '+1-555-2929', '2026-03-12 15:30:00', 'active'),
('Noha Haddad', 'ID100030', '1999-10-11', 'Female', '+1-555-2030', 'noha.haddad@gmail.com', 'B-', 'Sidon', 'ablus St', 'Samir Haddad', '+1-555-2930', '2026-03-15 08:15:00', 'active'),
('Samir Naccour', 'ID100031', '1970-09-24', 'Male', '+1-555-2031', 'samir.naccour@gmail.com', 'O+', 'Zahle', 'Railway St', 'Rita Naccour', '+1-555-2931', '2026-03-18 10:00:00', 'active'),
('Rita Boushnak', 'ID100032', '1987-12-04', 'Female', '+1-555-2032', 'rita.boushnak@gmail.com', 'AB+', 'Beirut', 'Corniche El Mazraa', 'Ziad Boushnak', '+1-555-2932', '2026-03-20 13:20:00', 'active'),
('Hassan Mroueh', 'ID100033', '1978-05-27', 'Male', '+1-555-2033', 'hassan.mroueh@gmail.com', 'A+', 'Tyre', 'Main Market', 'Fatima Mroueh', '+1-555-2933', '2026-03-22 09:50:00', 'active'),
('Fatima Choucair', 'ID100034', '1993-02-15', 'Female', '+1-555-2034', 'fatima.choucair@gmail.com', 'B+', 'Beirut', 'Manara', 'Ali Choucair', '+1-555-2934', '2026-03-25 16:10:00', 'active'),
('Ali Fakih', 'ID100035', '1985-08-08', 'Male', '+1-555-2035', 'ali.fakih@gmail.com', 'O-', 'Nabatieh', 'Hospital St', 'Zainab Fakih', '+1-555-2935', '2026-03-28 11:00:00', 'active'),
('Zainab Bazzi', 'ID100036', '1996-06-19', 'Female', '+1-555-2036', 'zainab.bazzi@gmail.com', 'A-', 'Bint Jbeil', 'Main St', 'Hassan Bazzi', '+1-555-2936', '2026-03-30 14:30:00', 'active'),
('Hussein Hammoud', 'ID100037', '1982-01-30', 'Male', '+1-555-2037', 'hussein.hammoud@gmail.com', 'AB-', 'Beirut', 'Dahiyeh', 'Mariam Hammoud', '+1-555-2937', '2026-04-02 09:20:00', 'active'),
('Mariam Zein', 'ID100038', '1991-04-12', 'Female', '+1-555-2038', 'mariam.zein@gmail.com', 'B-', 'Sidon', 'Old Harbour', 'Ahmad Zein', '+1-555-2938', '2026-04-05 10:40:00', 'active'),
('Ahmad Dakik', 'ID100039', '1979-07-21', 'Male', '+1-555-2039', 'ahmad.dakik@gmail.com', 'O+', 'Tyre', 'Commercial St', 'Suha Dakik', '+1-555-2939', '2026-04-08 13:00:00', 'active'),
('Suha Harb', 'ID100040', '1994-11-16', 'Female', '+1-555-2040', 'suha.harb@gmail.com', 'A+', 'Beirut', 'Tariq El Jdideh', 'Bilal Harb', '+1-555-2940', '2026-04-10 15:20:00', 'active'),
('Kassem Al-Amin', 'ID100041', '1973-10-08', 'Male', '+1-555-2041', 'kassem.amin@gmail.com', 'B+', 'Baalbek', 'Roman St', 'Wafaa Al-Amin', '+1-555-2941', '2026-04-12 08:30:00', 'active'),
('Wafaa Ismail', 'ID100042', '1988-03-25', 'Female', '+1-555-2042', 'wafaa.ismail@gmail.com', 'AB+', 'Hermel', 'Main Rd', 'Hassan Ismail', '+1-555-2942', '2026-04-15 11:10:00', 'active'),
('Imad Shaito', 'ID100043', '1980-12-05', 'Male', '+1-555-2043', 'imad.shaito@gmail.com', 'O-', 'Beirut', 'Clemenceau', 'Randa Shaito', '+1-555-2943', '2026-04-18 12:00:00', 'active'),
('Randa Mneimneh', 'ID100044', '1992-05-14', 'Female', '+1-555-2044', 'randa.mneimneh@gmail.com', 'A-', 'Beirut', 'Corniche', 'Ziad Mneimneh', '+1-555-2944', '2026-04-20 09:15:00', 'active'),
('Nizar Sinno', 'ID100045', '1975-09-01', 'Male', '+1-555-2045', 'nizar.sinno@gmail.com', 'B-', 'Beirut', 'Kantari', 'Lina Sinno', '+1-555-2945', '2026-04-22 14:45:00', 'active'),
('Lina Itani', 'ID100046', '1997-02-18', 'Female', '+1-555-2046', 'lina.itani@gmail.com', 'AB-', 'Beirut', 'Wata', 'Omar Itani', '+1-555-2946', '2026-04-25 10:20:00', 'active'),
('Kamal Beydoun', 'ID100047', '1984-06-22', 'Male', '+1-555-2047', 'kamal.beydoun@gmail.com', 'O+', 'Tyre', 'Al-Housh', 'Nadia Beydoun', '+1-555-2947', '2026-04-28 16:00:00', 'active'),
('Nadia Chehab', 'ID100048', '1990-10-31', 'Female', '+1-555-2048', 'nadia.chehab@gmail.com', 'A+', 'Sidon', 'Dakerman', 'Samih Chehab', '+1-555-2948', '2026-05-01 08:50:00', 'active'),
('Samih Assaad', 'ID100049', '1971-01-15', 'Male', '+1-555-2049', 'samih.assaad@gmail.com', 'B+', 'Zahle', 'Berdawni', 'Salma Assaad', '+1-555-2949', '2026-05-03 11:30:00', 'active'),
('Salma Daouk', 'ID100050', '1995-07-09', 'Female', '+1-555-2050', 'salma.daouk@gmail.com', 'O-', 'Beirut', 'Sanayeh', 'Amine Daouk', '+1-555-2950', '2026-05-05 13:40:00', 'active'),
('Amine Sayegh', 'ID100051', '1986-04-03', 'Male', '+1-555-2051', 'amine.sayegh@gmail.com', 'A-', 'Beirut', 'Achrafieh', 'Nour Sayegh', '+1-555-2951', '2026-05-08 09:00:00', 'active'),
('Nour Bizri', 'ID100052', '1993-09-21', 'Female', '+1-555-2052', 'nour.bizri@gmail.com', 'B-', 'Sidon', 'Main St', 'Ziad Bizri', '+1-555-2952', '2026-05-10 10:15:00', 'active'),
('Ziad Kabbani', 'ID100053', '1978-12-11', 'Male', '+1-555-2053', 'ziad.kabbani@gmail.com', 'AB+', 'Beirut', 'Hamra', 'Mona Kabbani', '+1-555-2953', '2026-05-12 14:20:00', 'active'),
('Mona Solh', 'ID100054', '1991-02-27', 'Female', '+1-555-2054', 'mona.solh@gmail.com', 'O+', 'Tripoli', 'Tell', 'Tarek Solh', '+1-555-2954', '2026-05-15 11:00:00', 'active'),
('Tarek Mikati', 'ID100055', '1983-08-19', 'Male', '+1-555-2055', 'tarek.mikati@gmail.com', 'A+', 'Tripoli', 'Mina', 'Rania Mikati', '+1-555-2955', '2026-05-18 15:30:00', 'active'),
('Rania Karami', 'ID100056', '1996-05-04', 'Female', '+1-555-2056', 'rania.karami@gmail.com', 'B+', 'Tripoli', 'Azmi', 'Omar Karami', '+1-555-2956', '2026-05-20 08:40:00', 'active'),
('Omar Salam', 'ID100057', '1974-11-23', 'Male', '+1-555-2057', 'omar.salam@gmail.com', 'O-', 'Beirut', 'Verdun', 'Hoda Salam', '+1-555-2957', '2026-05-22 12:10:00', 'active'),
('Hoda Jisr', 'ID100058', '1989-06-16', 'Female', '+1-555-2058', 'hoda.jisr@gmail.com', 'AB-', 'Sidon', 'Sea Castle', 'Khaled Jisr', '+1-555-2958', '2026-05-25 09:50:00', 'active'),
('Khaled Houri', 'ID100059', '1981-01-29', 'Male', '+1-555-2059', 'khaled.houri@gmail.com', 'A-', 'Beirut', 'Mazraa', 'Layla Houri', '+1-555-2959', '2026-05-28 14:00:00', 'active'),
('Layla Rabbat', 'ID100060', '1994-07-07', 'Female', '+1-555-2060', 'layla.rabbat@gmail.com', 'B-', 'Beirut', 'Gemmayzeh', 'Sami Rabbat', '+1-555-2960', '2026-05-30 16:20:00', 'active');

-- أمر إدخال البيانات الى جدول ال ( rooms ) 

INSERT INTO rooms (department_id, room_number, room_type, floor_number, daily_price, status) VALUES
(1, 1, 'normal', 1, 100.00, 'available'),
(2, 2, 'private', 1, 250.00, 'occupied'),
(3, 3, 'icu', 2, 600.00, 'available'),
(4, 4, 'emergency', 2, 450.00, 'occupied'),
(5, 5, 'normal', 3, 110.00, 'maintenance'),
(6, 6, 'private', 3, 260.00, 'available'),
(7, 7, 'icu', 4, 620.00, 'occupied'),
(8, 8, 'emergency', 4, 470.00, 'inactive'),
(1, 9, 'normal', 5, 120.00, 'available'),
(2, 10, 'private', 5, 270.00, 'occupied'),
(3, 11, 'icu', 6, 650.00, 'available'),
(4, 12, 'emergency', 6, 480.00, 'maintenance'),
(5, 13, 'normal', 7, 130.00, 'available'),
(6, 14, 'private', 7, 280.00, 'inactive'),
(7, 15, 'icu', 8, 700.00, 'occupied'),
(8, 16, 'emergency', 8, 500.00, 'available'),
(1, 17, 'normal', 9, 105.00, 'maintenance'),
(2, 18, 'private', 9, 255.00, 'available'),
(3, 19, 'icu', 10, 630.00, 'occupied'),
(4, 20, 'emergency', 10, 460.00, 'available'),
(5, 21, 'normal', 1, 115.00, 'inactive'),
(6, 22, 'private', 2, 265.00, 'occupied'),
(7, 23, 'icu', 3, 640.00, 'available'),
(8, 24, 'emergency', 4, 490.00, 'maintenance'),
(1, 25, 'normal', 5, 125.00, 'available'),
(2, 26, 'private', 6, 275.00, 'occupied'),
(3, 27, 'icu', 7, 680.00, 'available'),
(4, 28, 'emergency', 8, 510.00, 'inactive'),
(5, 29, 'normal', 9, 135.00, 'occupied'),
(6, 30, 'private', 10, 290.00, 'available');

-- أمر إدخال البيانات على جدول ال ( appointments ) 

INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, reason, status, created_at) VALUES
(3, 2, '2026-10-01', '09:00:00', 'Routine checkup', 'completed', '2026-09-25 08:30:00'),
(5, 4, '2026-10-01', '10:00:00', 'Headache', 'scheduled', '2026-09-25 09:15:00'),
(12, 1, '2026-10-01', '11:30:00', 'Fever and cough', 'cancelled', '2026-09-25 10:00:00'),
(3, 7, '2026-10-02', '08:30:00', 'Follow-up visit', 'no_show', '2026-09-25 11:20:00'),
(18, 3, '2026-10-02', '09:45:00', 'Back pain', 'scheduled', '2026-09-25 12:00:00'),
(22, 5, '2026-10-02', '11:00:00', 'Stomach ache', 'completed', '2026-09-25 13:10:00'),
(5, 2, '2026-10-03', '10:15:00', 'Skin rash', 'cancelled', '2026-09-26 08:00:00'),
(30, 8, '2026-10-03', '12:00:00', 'Eye irritation', 'scheduled', '2026-09-26 09:30:00'),
(35, 6, '2026-10-04', '09:00:00', 'Dental cleaning', 'completed', '2026-09-26 10:45:00'),
(12, 4, '2026-10-04', '10:30:00', 'Blood pressure check', 'no_show', '2026-09-26 11:15:00'),
(40, 10, '2026-10-05', '08:00:00', 'Joint pain', 'scheduled', '2026-09-27 08:20:00'),
(3, 1, '2026-10-05', '09:30:00', 'General consultation', 'completed', '2026-09-27 09:00:00'),
(45, 9, '2026-10-05', '11:00:00', 'Chest discomfort', 'cancelled', '2026-09-27 10:10:00'),
(18, 2, '2026-10-06', '09:15:00', 'Diabetes follow-up', 'scheduled', '2026-09-27 11:00:00'),
(50, 11, '2026-10-06', '10:45:00', 'Pediatric checkup', 'completed', '2026-09-27 12:30:00'),
(22, 6, '2026-10-07', '08:30:00', 'Earache', 'no_show', '2026-09-28 08:10:00'),
(55, 12, '2026-10-07', '10:00:00', 'Allergy symptoms', 'scheduled', '2026-09-28 09:05:00'),
(30, 3, '2026-10-08', '11:15:00', 'Throat infection', 'completed', '2026-09-28 10:00:00'),
(60, 14, '2026-10-08', '12:30:00', 'Physical therapy session', 'cancelled', '2026-09-28 11:25:00'),
(5, 7, '2026-10-09', '09:00:00', 'Cardiac check', 'scheduled', '2026-09-28 12:00:00'),
(40, 15, '2026-10-09', '10:30:00', 'Orthopedic consultation', 'completed', '2026-09-28 13:00:00'),
(12, 5, '2026-10-10', '08:15:00', 'Flu symptoms', 'no_show', '2026-09-29 08:00:00'),
(35, 13, '2026-10-10', '09:45:00', 'Annual physical', 'scheduled', '2026-09-29 08:45:00'),
(50, 8, '2026-10-11', '11:00:00', 'Dermatology follow-up', 'completed', '2026-09-29 09:30:00'),
(18, 1, '2026-10-11', '12:15:00', 'Post-operative check', 'cancelled', '2026-09-29 10:15:00'),
(8, 16, '2026-10-12', '09:00:00', 'Routine checkup', 'scheduled', '2026-09-29 11:00:00'),
(15, 4, '2026-10-12', '10:30:00', 'Back pain', 'completed', '2026-09-29 11:30:00'),
(25, 9, '2026-10-13', '08:15:00', 'Headache', 'cancelled', '2026-09-29 12:00:00'),
(33, 2, '2026-10-13', '11:00:00', 'Fever', 'no_show', '2026-09-29 12:15:00'),
(42, 11, '2026-10-14', '09:30:00', 'Stomach ache', 'scheduled', '2026-09-29 13:00:00'),
(51, 18, '2026-10-14', '10:45:00', 'Skin allergy', 'completed', '2026-09-29 13:30:00'),
(7, 20, '2026-10-15', '08:30:00', 'Dental pain', 'cancelled', '2026-09-30 08:00:00'),
(19, 22, '2026-10-15', '12:00:00', 'Eye check', 'no_show', '2026-09-30 08:30:00'),
(28, 5, '2026-10-16', '09:00:00', 'Joint swelling', 'scheduled', '2026-09-30 09:00:00'),
(38, 12, '2026-10-16', '10:15:00', 'Throat pain', 'completed', '2026-09-30 09:30:00'),
(48, 1, '2026-10-17', '11:15:00', 'Chest pain', 'cancelled', '2026-09-30 10:00:00'),
(58, 14, '2026-10-17', '12:30:00', 'Physical therapy', 'scheduled', '2026-09-30 10:30:00'),
(2, 7, '2026-10-18', '08:45:00', 'Follow up', 'completed', '2026-09-30 11:00:00'),
(14, 17, '2026-10-18', '10:00:00', 'Dizziness', 'no_show', '2026-09-30 11:30:00'),
(26, 23, '2026-10-19', '09:15:00', 'Cough and cold', 'scheduled', '2026-10-01 08:00:00'),
(36, 3, '2026-10-19', '11:30:00', 'Migraine', 'completed', '2026-10-01 08:30:00'),
(46, 25, '2026-10-20', '08:00:00', 'Ear infection', 'cancelled', '2026-10-01 09:00:00'),
(59, 10, '2026-10-20', '10:30:00', 'Pediatric check', 'scheduled', '2026-10-01 09:30:00'),
(10, 6, '2026-10-21', '09:00:00', 'General checkup', 'completed', '2026-10-01 10:00:00'),
(21, 13, '2026-10-21', '11:15:00', 'Blood pressure', 'no_show', '2026-10-01 10:30:00'),
(31, 19, '2026-10-22', '08:30:00', 'Diabetes review', 'scheduled', '2026-10-02 08:00:00'),
(41, 21, '2026-10-22', '10:00:00', 'Orthopedic exam', 'completed', '2026-10-02 08:30:00'),
(52, 24, '2026-10-23', '11:00:00', 'Skin rash', 'cancelled', '2026-10-02 09:00:00'),
(4, 15, '2026-10-23', '12:15:00', 'Cardiac checkup', 'scheduled', '2026-10-02 09:30:00'),
(16, 8, '2026-10-24', '09:30:00', 'Flu vaccination', 'completed', '2026-10-02 10:00:00'),
(11, 2, '2026-10-24', '11:00:00', 'Routine checkup', 'scheduled', '2026-10-02 10:30:00'),
(23, 9, '2026-10-25', '09:00:00', 'Back pain', 'completed', '2026-10-02 11:00:00'),
(34, 16, '2026-10-25', '10:15:00', 'Headache', 'cancelled', '2026-10-02 11:30:00'),
(43, 21, '2026-10-26', '08:30:00', 'Fever', 'no_show', '2026-10-03 08:00:00'),
(53, 4, '2026-10-26', '11:45:00', 'Stomach ache', 'scheduled', '2026-10-03 08:30:00'),
(9, 11, '2026-10-27', '09:15:00', 'Skin allergy', 'completed', '2026-10-03 09:00:00'),
(20, 18, '2026-10-27', '10:30:00', 'Dental pain', 'cancelled', '2026-10-03 09:30:00'),
(29, 25, '2026-10-28', '12:00:00', 'Eye check', 'no_show', '2026-10-03 10:00:00'),
(39, 7, '2026-10-28', '08:15:00', 'Joint swelling', 'scheduled', '2026-10-04 08:00:00'),
(49, 13, '2026-10-29', '09:45:00', 'Throat pain', 'completed', '2026-10-04 08:30:00'),
(1, 19, '2026-10-29', '11:15:00', 'Chest pain', 'cancelled', '2026-10-04 09:00:00'),
(13, 3, '2026-10-30', '08:45:00', 'Physical therapy', 'scheduled', '2026-10-04 09:30:00'),
(24, 15, '2026-10-30', '10:00:00', 'Follow up', 'completed', '2026-10-04 10:00:00'),
(32, 22, '2026-10-31', '09:00:00', 'Dizziness', 'no_show', '2026-10-05 08:00:00'),
(44, 6, '2026-10-31', '11:30:00', 'Cough and cold', 'scheduled', '2026-10-05 08:30:00'),
(54, 12, '2026-11-01', '08:00:00', 'Migraine', 'completed', '2026-10-05 09:00:00'),
(6, 1, '2026-11-01', '10:15:00', 'Ear infection', 'cancelled', '2026-10-05 09:30:00'),
(17, 10, '2026-11-02', '09:15:00', 'Pediatric check', 'scheduled', '2026-10-06 08:00:00'),
(27, 17, '2026-11-02', '11:00:00', 'General checkup', 'completed', '2026-10-06 08:30:00'),
(37, 24, '2026-11-03', '08:30:00', 'Blood pressure', 'no_show', '2026-10-06 09:00:00'),
(47, 5, '2026-11-03', '10:45:00', 'Diabetes review', 'scheduled', '2026-10-06 09:30:00'),
(57, 14, '2026-11-04', '11:30:00', 'Orthopedic exam', 'completed', '2026-10-07 08:00:00'),
(9, 20, '2026-11-04', '12:15:00', 'Skin rash', 'cancelled', '2026-10-07 08:30:00'),
(21, 8, '2026-11-05', '09:00:00', 'Cardiac checkup', 'scheduled', '2026-10-07 09:00:00'),
(35, 2, '2026-11-05', '10:30:00', 'Flu vaccination', 'completed', '2026-10-07 09:30:00');




