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
(35, 2, '2026-11-05', '10:30:00', 'Flu vaccination', 'completed', '2026-10-07 09:30:00'),
(15, 3, '2026-11-06', '08:30:00', 'Routine checkup', 'scheduled', '2026-10-07 10:00:00'),
(28, 11, '2026-11-06', '10:00:00', 'Back pain', 'completed', '2026-10-07 10:30:00'),
(42, 19, '2026-11-07', '09:15:00', 'Headache', 'cancelled', '2026-10-08 08:00:00'),
(50, 4, '2026-11-07', '11:30:00', 'Fever', 'no_show', '2026-10-08 08:30:00'),
(12, 22, '2026-11-08', '08:00:00', 'Stomach ache', 'scheduled', '2026-10-08 09:00:00'),
(25, 7, '2026-11-08', '10:15:00', 'Skin allergy', 'completed', '2026-10-08 09:30:00'),
(38, 15, '2026-11-09', '09:00:00', 'Dental pain', 'cancelled', '2026-10-09 08:00:00'),
(55, 1, '2026-11-09', '11:00:00', 'Eye check', 'no_show', '2026-10-09 08:30:00'),
(4, 18, '2026-11-10', '08:45:00', 'Joint swelling', 'scheduled', '2026-10-09 09:00:00'),
(19, 23, '2026-11-10', '12:00:00', 'Throat pain', 'completed', '2026-10-09 09:30:00'),
(33, 9, '2026-11-11', '09:30:00', 'Chest pain', 'cancelled', '2026-10-10 08:00:00'),
(46, 2, '2026-11-11', '11:15:00', 'Physical therapy', 'scheduled', '2026-10-10 08:30:00'),
(8, 14, '2026-11-12', '08:15:00', 'Follow up', 'completed', '2026-10-10 09:00:00'),
(22, 21, '2026-11-12', '10:30:00', 'Dizziness', 'no_show', '2026-10-10 09:30:00'),
(36, 5, '2026-11-13', '09:00:00', 'Cough and cold', 'scheduled', '2026-10-11 08:00:00'),
(48, 12, '2026-11-13', '11:00:00', 'Migraine', 'completed', '2026-10-11 08:30:00'),
(14, 25, '2026-11-14', '08:30:00', 'Ear infection', 'cancelled', '2026-10-11 09:00:00'),
(27, 10, '2026-11-14', '10:15:00', 'Pediatric check', 'scheduled', '2026-10-11 09:30:00'),
(40, 17, '2026-11-15', '09:15:00', 'General checkup', 'completed', '2026-10-12 08:00:00'),
(52, 6, '2026-11-15', '11:45:00', 'Blood pressure', 'no_show', '2026-10-12 08:30:00'),
(3, 20, '2026-11-16', '08:00:00', 'Diabetes review', 'scheduled', '2026-10-12 09:00:00'),
(18, 13, '2026-11-16', '10:00:00', 'Orthopedic exam', 'completed', '2026-10-12 09:30:00'),
(31, 24, '2026-11-17', '09:00:00', 'Skin rash', 'cancelled', '2026-10-13 08:00:00'),
(45, 16, '2026-11-17', '11:00:00', 'Cardiac checkup', 'scheduled', '2026-10-13 08:30:00'),
(58, 8, '2026-11-18', '10:30:00', 'Flu vaccination', 'completed', '2026-10-13 09:00:00');

-- أمر إدخال البيانات الى جدول ال ( medical_visits ) 

INSERT INTO medical_visits (patient_id, doctor_id, appointment_id, visit_date, symptoms, diagnosis, doctor_notes, follow_up_date) VALUES
(3, 2, 1, '2026-10-01', 'Routine checkup', 'Healthy', 'Regular annual checkup completed.', '2027-10-01'),
(5, 4, 2, '2026-10-01', 'Severe headache and nausea', 'Migraine', 'Prescribed pain relievers and rest.', '2026-10-15'),
(12, 1, 3, '2026-10-01', 'High fever and persistent cough', 'Bronchitis', 'Antibiotics and cough syrup prescribed.', '2026-10-10'),
(15, 7, 0, '2026-10-02', 'Sudden chest pain', 'Angina pectoris', 'Urgent ECG performed, referred to cardiology.', '2026-10-05'),
(18, 3, 5, '2026-10-02', 'Lower back pain after lifting', 'Muscle strain', 'Physical therapy sessions recommended.', '2026-10-16'),
(22, 5, 6, '2026-10-02', 'Stomach cramps and indigestion', 'Gastritis', 'Antacids and dietary guidelines given.', '2026-10-12'),
(8, 10, 0, '2026-10-03', 'Itchy red rash on arms', 'Allergic dermatitis', 'Antihistamine cream and pills prescribed.', '2026-10-10'),
(30, 8, 8, '2026-10-03', 'Blurred vision and eye strain', 'Astigmatism', 'Referred to optometrist for glasses.', '2026-11-03'),
(35, 6, 9, '2026-10-04', 'Toothache and gum swelling', 'Dental abscess', 'Painkillers given and scheduled for extraction.', '2026-10-07'),
(40, 10, 11, '2026-10-05', 'Joint stiffness in knees', 'Osteoarthritis', 'Joint supplements and mild exercise advised.', '2026-11-05'),
(3, 1, 12, '2026-10-05', 'Follow-up for general health', 'Stable', 'Blood test results normal.', '2027-04-05'),
(45, 9, 13, '2026-10-05', 'Shortness of breath', 'Asthma exacerbation', 'Inhaler usage adjusted.', '2026-10-19'),
(18, 2, 14, '2026-10-06', 'High blood sugar levels', 'Type 2 Diabetes', 'Adjusted insulin dosage.', '2026-10-20'),
(50, 11, 15, '2026-10-06', 'Ear pain and discharge', 'Otitis media', 'Ear drops prescribed.', '2026-10-13'),
(22, 6, 16, '2026-10-07', 'Severe earache', 'Outer ear infection', 'Antibiotic ear drops given.', '2026-10-14'),
(55, 12, 17, '2026-10-07', 'Sneezing and watery eyes', 'Allergic rhinitis', 'Antihistamines prescribed.', '2026-10-21'),
(10, 14, 0, '2026-10-08', 'Sudden dizziness and fainting', 'Orthostatic hypotension', 'Hydration and salt intake increased.', '2026-10-15'),
(60, 14, 19, '2026-10-08', 'Post-injury stiffness', 'Rehabilitation needed', 'Started physical therapy program.', '2026-10-22'),
(5, 7, 20, '2026-10-09', 'Palpitations', 'Benign arrhythmia', 'Holter monitor attached for 24 hours.', '2026-10-16'),
(40, 15, 21, '2026-10-09', 'Fractured wrist follow-up', 'Healing well', 'Cast removed, light exercises started.', '2026-10-30'),
(25, 4, 0, '2026-10-10', 'High fever and body ache', 'Influenza', 'Bed rest and fluids recommended.', '2026-10-17'),
(35, 13, 23, '2026-10-10', 'Routine physical check', 'Healthy', 'Vitals within normal range.', '2027-10-10'),
(50, 8, 24, '2026-10-11', 'Acne flare-up', 'Acne vulgaris', 'Topical retinoids prescribed.', '2026-11-11'),
(8, 16, 26, '2026-10-12', 'General fatigue', 'Vitamin D deficiency', 'Vitamin D supplements prescribed.', '2026-11-12'),
(15, 4, 27, '2026-10-12', 'Upper back stiffness', 'Myofascial pain', 'Muscle relaxants prescribed.', '2026-10-26'),
(25, 9, 28, '2026-10-13', 'Persistent tension headache', 'Tension headache', 'Stress management and analgesics.', '2026-10-27'),
(33, 2, 29, '2026-10-13', 'Severe sore throat', 'Strep throat', 'Antibiotics prescribed.', '2026-10-20'),
(42, 11, 30, '2026-10-14', 'Nausea and abdominal cramps', 'Gastroenteritis', 'Dietary restrictions and hydration.', '2026-10-21'),
(51, 18, 31, '2026-10-14', 'Dry and flaky skin', 'Eczema', 'Moisturizing creams prescribed.', '2026-10-28'),
(7, 20, 32, '2026-10-15', 'Tooth sensitivity', 'Worn enamel', 'Fluoride treatment applied.', '2026-11-15'),
(19, 22, 33, '2026-10-15', 'Red and watery eyes', 'Conjunctivitis', 'Eye drops prescribed.', '2026-10-22'),
(28, 5, 34, '2026-10-16', 'Swollen ankle joint', 'Sprained ankle', 'RICE protocol and bandage applied.', '2026-10-23'),
(38, 12, 35, '2026-10-16', 'Hoarseness of voice', 'Acute laryngitis', 'Voice rest and steam inhalation.', '2026-10-23'),
(48, 1, 36, '2026-10-17', 'Tightness in chest', 'Anxiety attack', 'Reassurance and breathing exercises.', '2026-10-24'),
(58, 14, 37, '2026-10-17', 'Shoulder mobility issues', 'Frozen shoulder', 'Physiotherapy sessions scheduled.', '2026-10-31'),
(2, 7, 38, '2026-10-18', 'Blood pressure check', 'Hypertension controlled', 'Continue current medication.', '2026-11-18'),
(14, 17, 39, '2026-10-18', 'Frequent dizzy spells', 'Vertigo', 'Medication for motion sickness prescribed.', '2026-10-25'),
(26, 23, 40, '2026-10-19', 'Persistent dry cough', 'Allergic cough', 'Syrup and anti-allergic medication.', '2026-10-26'),
(36, 3, 41, '2026-10-19', 'Severe throbbing headache', 'Migraine attack', 'Triptans prescribed.', '2026-11-02'),
(46, 25, 42, '2026-10-20', 'Blocked ear canal', 'Earwax buildup', 'Wax removal procedure performed.', '2026-11-20'),
(59, 10, 43, '2026-10-20', 'Routine infant checkup', 'Healthy growth', 'Vaccines administered.', '2026-11-20'),
(10, 6, 44, '2026-10-21', 'Annual medical examination', 'Good health', 'Standard lab tests ordered.', '2027-10-21'),
(21, 13, 45, '2026-10-21', 'High blood pressure reading', 'Stage 1 Hypertension', 'Lifestyle modifications advised.', '2026-11-04'),
(31, 19, 46, '2026-10-22', 'Diabetes routine check', 'Stable glucose levels', 'Continue regimen.', '2026-11-22'),
(41, 21, 47, '2026-10-22', 'Knee joint pain', 'Meniscus irritation', 'MRI scan requested.', '2026-11-05'),
(52, 24, 48, '2026-10-23', 'Hives and itching', 'Urticaria', 'Antihistamines given.', '2026-10-30'),
(4, 15, 49, '2026-10-23', 'Chest discomfort on exertion', 'Stable angina', 'Stress test scheduled.', '2026-11-06'),
(16, 8, 50, '2026-10-24', 'Seasonal flu symptoms', 'Influenza', 'Vaccinated and sent home.', '2026-11-24'),
(11, 2, 51, '2026-10-24', 'General weakness', 'Anemia', 'Iron supplements prescribed.', '2026-11-14'),
(23, 9, 52, '2026-10-25', 'Chronic back pain', 'Lumbar spondylosis', 'Physical therapy recommended.', '2026-11-08'),
(34, 16, 53, '2026-10-25', 'Frequent headaches', 'Stress headache', 'Relaxation techniques advised.', '2026-11-08'),
(43, 21, 54, '2026-10-26', 'High fever and chills', 'Viral infection', 'Hydration and paracetamol.', '2026-11-02'),
(53, 4, 55, '2026-10-26', 'Upper abdominal pain', 'Gastric ulcer', 'Gastroscopy scheduled.', '2026-11-09'),
(9, 11, 56, '2026-10-27', 'Skin rash on face', 'Rosacea', 'Topical cream prescribed.', '2026-11-10'),
(20, 18, 57, '2026-10-27', 'Tooth decay pain', 'Caries', 'Filled cavity.', '2026-11-10'),
(29, 25, 58, '2026-10-28', 'Dry itchy eyes', 'Dry eye syndrome', 'Artificial tears prescribed.', '2026-11-11'),
(39, 7, 59, '2026-10-28', 'Wrist swelling', 'Carpal tunnel syndrome', 'Wrist splint recommended.', '2026-11-11'),
(49, 13, 60, '2026-10-29', 'Severe sore throat', 'Pharyngitis', 'Throat lozenges and antibiotics.', '2026-11-05'),
(1, 19, 61, '2026-10-29', 'Chest tightness', 'Mild bronchitis', 'Inhaler prescribed.', '2026-11-12'),
(13, 3, 62, '2026-10-30', 'Post-op knee check', 'Recovery on track', 'Continue exercises.', '2026-11-13'),
(24, 15, 63, '2026-10-30', 'Routine checkup', 'Healthy', 'All clear.', '2027-10-30'),
(32, 22, 64, '2026-10-31', 'Spells of dizziness', 'Benign positional vertigo', 'Epley maneuver performed.', '2026-11-07'),
(44, 6, 65, '2026-10-31', 'Cough and nasal congestion', 'Common cold', 'Rest and fluids.', '2026-11-07'),
(54, 12, 66, '2026-11-01', 'Severe migraine attack', 'Migraine', 'Injection administered.', '2026-11-15'),
(6, 1, 67, '2026-11-01', 'Earache and itching', 'Swimmer ear', 'Ear drops prescribed.', '2026-11-08'),
(17, 10, 68, '2026-11-02', 'Routine pediatric visit', 'Healthy child', 'Vitamins given.', '2027-05-02'),
(27, 17, 69, '2026-11-02', 'General health check', 'Normal', 'No issues found.', '2027-11-02'),
(37, 24, 70, '2026-11-03', 'High blood pressure', 'Hypertension', 'Medication adjusted.', '2026-11-17'),
(47, 5, 71, '2026-11-03', 'Diabetes follow-up', 'Stable', 'Diet plan reviewed.', '2026-12-03'),
(57, 14, 72, '2026-11-04', 'Hip joint pain', 'Bursitis', 'Anti-inflammatory drugs given.', '2026-11-18');

-- أمر إدخال البيانات الى جدول ال ( medicines ) 

INSERT INTO medicines (medicine_name, manufacturer, unit_price, stock_quantity, minimum_stock, expiry_date, status) VALUES
('Paracetamol 500mg', 'Pfizer', 5.50, 150, 20, '2028-05-12', 'Available'),
('Amoxicillin 250mg', 'Novartis', 12.00, 5, 15, '2027-03-20', 'Available'),
('Aspirin 100mg', 'Bayer', 4.25, 0, 10, '2028-01-15', 'Out of Stock'),
('Ibuprofen 400mg', 'GSK', 8.00, 45, 15, '2025-11-10', 'Expired'),
('Omeprazole 20mg', 'AstraZeneca', 15.50, 80, 10, '2028-08-30', 'Available'),
('Metformin 850mg', 'Sanofi', 9.75, 4, 25, '2027-06-15', 'Available'),
('Atorvastatin 20mg', 'Pfizer', 22.00, 0, 15, '2029-01-10', 'Out of Stock'),
('Lisinopril 10mg', 'Merck', 11.25, 120, 30, '2027-09-12', 'Available'),
('Cetirizine 10mg', 'Johnson & Johnson', 6.50, 12, 20, '2026-05-01', 'Expired'),
('Salbutamol Inhaler', 'Cipla', 18.00, 3, 10, '2026-02-14', 'Expired'),
('Azithromycin 500mg', 'Pfizer', 25.00, 0, 10, '2027-11-05', 'Discontinued'),
('Diclofenac Sodium', 'Novartis', 7.50, 6, 20, '2027-04-18', 'Available'),
('Simvastatin 20mg', 'Bayer', 14.00, 200, 40, '2028-10-10', 'Available'),
('Amlodipine 5mg', 'Sanofi', 10.50, 2, 15, '2027-12-01', 'Available'),
('Pantoprazole 40mg', 'Takeda', 16.80, 0, 10, '2026-08-20', 'Out of Stock'),
('Prednisone 5mg', 'Pfizer', 6.20, 50, 10, '2025-08-15', 'Expired'),
('Losartan 50mg', 'Merck', 13.50, 8, 25, '2027-07-22', 'Available'),
('Levothyroxine 50mcg', 'Abbott', 8.90, 90, 20, '2028-03-11', 'Available'),
('Ciprofloxacin 500mg', 'Bayer', 19.50, 0, 12, '2026-04-30', 'Expired'),
('Clindamycin 300mg', 'Pfizer', 28.00, 15, 10, '2027-01-30', 'Discontinued'),
('Hydrochlorothiazide', 'Novartis', 5.00, 110, 30, '2028-06-19', 'Available'),
('Gabapentin 300mg', 'Pfizer', 24.50, 4, 15, '2027-09-05', 'Available'),
('Meloxicam 15mg', 'Boehringer', 11.00, 0, 20, '2028-02-28', 'Out of Stock'),
('Montelukast 10mg', 'MSD', 21.00, 65, 15, '2027-10-15', 'Available'),
('Sertraline 50mg', 'Pfizer', 17.25, 3, 10, '2026-07-10', 'Expired'),
('Fluoxetine 20mg', 'Eli Lilly', 15.00, 75, 20, '2028-11-20', 'Available'),
('Escitalopram 10mg', 'Forest', 19.80, 0, 15, '2027-05-14', 'Discontinued'),
('Citalopram 20mg', 'Actavis', 12.40, 5, 20, '2027-08-19', 'Available'),
('Clopidogrel 75mg', 'Sanofi', 31.00, 140, 30, '2028-12-05', 'Available'),
('Warfarin 5mg', 'Bristol-Myers', 9.20, 2, 10, '2026-06-30', 'Expired'),
('Spironolactone 25mg', 'Pfizer', 14.50, 40, 15, '2028-01-25', 'Available'),
('Furosemide 40mg', 'Sanofi', 6.80, 0, 25, '2027-03-10', 'Out of Stock'),
('Allopurinol 100mg', 'GSK', 8.50, 85, 20, '2028-04-12', 'Available'),
('Colchicine 0.5mg', 'Takeda', 26.00, 7, 10, '2027-02-18', 'Available'),
('Insulin Glargine', 'Sanofi', 85.00, 0, 10, '2026-05-20', 'Expired'),
('Metronidazole 500mg', 'Pfizer', 10.00, 95, 25, '2028-07-08', 'Available'),
('Doxycycline 100mg', 'Pfizer', 16.50, 4, 15, '2027-09-30', 'Available'),
('Tramadol 50mg', 'Grunenthal', 13.00, 0, 20, '2027-11-11', 'Discontinued'),
('Melatonin 5mg', 'Nature Made', 11.50, 130, 30, '2029-05-15', 'Available'),
('Vitamin D3 1000IU', 'Solgar', 14.20, 6, 25, '2026-03-15', 'Expired');

-- أمر إدخال بيانات الى الجدول ( prescriptions ) 

 INSERT INTO prescriptions (visit_id, prescribed_at, notes) VALUES
(1, '2026-10-01 09:30:00', 'Take after meals with plenty of water.'),
(3, '2026-10-01 11:00:00', 'Complete the full course of antibiotics.'),
(5, '2026-10-02 10:15:00', 'Apply topically twice a day.'),
(7, '2026-10-03 08:45:00', 'Take one tablet every 8 hours as needed for pain.'),
(10, '2026-10-03 12:00:00', 'Use eye drops morning and evening.'),
(12, '2026-10-04 09:15:00', 'Strict bed rest for three days.'),
(15, '2026-10-05 10:30:00', 'Take on an empty stomach in the morning.'),
(18, '2026-10-05 11:45:00', 'Use inhaler during shortness of breath episodes.'),
(20, '2026-10-06 09:00:00', 'Check blood sugar levels daily before breakfast.'),
(22, '2026-10-06 10:15:00', 'Take syrup before sleep.'),
(25, '2026-10-07 08:30:00', 'Apply warm compress before ointment.'),
(28, '2026-10-07 11:00:00', 'Avoid dairy products during treatment.'),
(30, '2026-10-08 09:45:00', 'Take with food to avoid stomach irritation.'),
(33, '2026-10-08 12:15:00', 'Complete the 7-day course without interruption.'),
(35, '2026-10-09 08:00:00', 'Take one pill before bedtime.'),
(38, '2026-10-09 10:30:00', 'Gargle with warm salt water three times a day.'),
(40, '2026-10-10 09:15:00', 'Keep affected area clean and dry.'),
(42, '2026-10-10 11:00:00', 'Take painkiller only when pain is severe.'),
(45, '2026-10-11 08:45:00', 'Drink at least 3 liters of water daily.'),
(48, '2026-10-11 10:15:00', 'Take supplement with the main meal.'),
(50, '2026-10-12 09:30:00', 'Rest wrist using a splint at night.'),
(2, '2026-10-12 11:15:00', 'Take one tablet every 12 hours.'),
(4, '2026-10-13 08:30:00', 'Apply cream gently on the affected area.'),
(6, '2026-10-13 10:00:00', 'Take medication with a full glass of water.'),
(9, '2026-10-14 09:00:00', 'Follow low-sodium diet strictly.'),
(11, '2026-10-14 11:30:00', 'Take 30 minutes before breakfast.'),
(14, '2026-10-15 08:15:00', 'Use nasal spray twice daily.'),
(16, '2026-10-15 10:45:00', 'Avoid driving if drowsiness occurs.'),
(19, '2026-10-16 09:15:00', 'Take dose as prescribed by the specialist.'),
(21, '2026-10-16 12:00:00', 'Store medication in a cool, dry place.'),
(24, '2026-10-17 08:30:00', 'Take with meals to enhance absorption.'),
(26, '2026-10-17 10:15:00', 'Complete full prescription duration.'),
(29, '2026-10-18 09:00:00', 'Use eye ointment before sleep.'),
(31, '2026-10-18 11:00:00', 'Take one capsule daily in the morning.'),
(34, '2026-10-19 08:45:00', 'Do not crush or chew the tablets.'),
(37, '2026-10-19 10:30:00', 'Take syrup using the provided measuring cup.'),
(39, '2026-10-20 09:15:00', 'Apply patch on clean, hairless skin.'),
(43, '2026-10-20 11:15:00', 'Take extra vitamin C during treatment.'),
(46, '2026-10-21 08:30:00', 'Avoid direct sunlight while taking this medication.'),
(49, '2026-10-21 10:00:00', 'Take tablet with dinner.'),
(52, '2026-10-22 09:00:00', 'Repeat dosage after 8 hours if needed.'),
(55, '2026-10-22 11:30:00', 'Use ear drops for 5 consecutive days.'),
(58, '2026-10-23 08:15:00', 'Keep medication refrigerated.'),
(60, '2026-10-23 10:45:00', 'Take one tablet every morning on an empty stomach.'),
(63, '2026-10-24 09:30:00', 'Discontinue use if allergic reaction occurs.'),
(65, '2026-10-24 11:00:00', 'Take with plenty of fluids.'),
(67, '2026-10-25 08:30:00', 'Follow up with doctor after finishing prescription.'),
(69, '2026-10-25 10:15:00', 'Take one tablet twice daily after meals.'),
(8, '2026-10-26 09:00:00', 'Rest and avoid strenuous physical activities.'),
(13, '2026-10-26 11:15:00', 'Take medication regularly at the same time every day.');

-- أمر إدخال البيانات على الجدول ( prescription_items ) 

INSERT INTO prescription_items (prescription_id, medicine_id, dosage, frequency, duration_days, quantity) VALUES
(3, 12, '500mg', 'Twice daily', 7, 14),
(15, 25, '250mg', 'Three times daily', 5, 15),
(42, 8, '100mg', 'Once daily', 30, 30),
(10, 33, '400mg', 'Every 8 hours', 10, 30),
(28, 2, '20mg', 'Once daily', 14, 14),
(49, 19, '850mg', 'Twice daily', 60, 60),
(5, 37, '10mg', 'Once daily', 30, 30),
(33, 14, '500mg', 'Every 12 hours', 7, 14),
(18, 40, '250mg', 'Twice daily', 10, 20),
(22, 6, '50mg', 'Once daily', 30, 30),
(50, 11, '1000mg', 'Single dose', 1, 1),
(1, 23, '10mg', 'Twice daily', 14, 28),
(12, 29, '50mg', 'Once daily', 30, 30),
(39, 4, '400mg', 'Three times daily', 7, 21),
(25, 15, '20mg', 'Once daily', 30, 30),
(8, 30, '5mg', 'Once daily', 14, 14),
(44, 20, '500mg', 'Twice daily', 10, 20),
(16, 7, '300mg', 'Every 8 hours', 5, 15),
(29, 35, '15mg', 'Once daily', 30, 30),
(3, 18, '25mg', 'Twice daily', 14, 28),
(36, 1, '500mg', 'Once daily', 7, 7),
(21, 27, '10mg', 'Every 12 hours', 10, 20),
(47, 9, '20mg', 'Once daily', 30, 30),
(14, 22, '100mg', 'Three times daily', 7, 21),
(30, 38, '50mg', 'Once daily', 30, 30),
(2, 5, '500mg', 'Twice daily', 10, 20),
(11, 16, '250mg', 'Once daily', 30, 30),
(24, 32, '100mg', 'Every 8 hours', 7, 21),
(37, 3, '50mg', 'Once daily', 14, 14),
(45, 21, '400mg', 'Three times daily', 5, 15),
(7, 10, '10mg', 'Once daily', 30, 30),
(19, 28, '20mg', 'Every 12 hours', 10, 20),
(31, 39, '850mg', 'Twice daily', 30, 60),
(43, 13, '500mg', 'Once daily', 7, 7),
(4, 34, '250mg', 'Twice daily', 14, 28),
(13, 26, '100mg', 'Once daily', 30, 30),
(26, 17, '15mg', 'Every 8 hours', 10, 30),
(35, 1, '500mg', 'Twice daily', 7, 14),
(48, 22, '20mg', 'Once daily', 30, 30),
(9, 31, '250mg', 'Three times daily', 5, 15),
(20, 8, '100mg', 'Once daily', 14, 14),
(32, 36, '50mg', 'Every 12 hours', 10, 20),
(41, 12, '400mg', 'Once daily', 30, 30),
(6, 25, '300mg', 'Twice daily', 7, 14),
(17, 33, '10mg', 'Once daily', 30, 30),
(27, 15, '500mg', 'Every 8 hours', 5, 15),
(38, 4, '250mg', 'Twice daily', 14, 28),
(46, 18, '100mg', 'Once daily', 30, 30),
(16, 29, '20mg', 'Twice daily', 10, 20),
(50, 7, '50mg', 'Once daily', 14, 14)
(12, 5, '500mg', 'Twice daily', 10, 20),
(25, 14, '250mg', 'Once daily', 30, 30),
(38, 22, '100mg', 'Every 8 hours', 7, 21),
(45, 3, '50mg', 'Once daily', 14, 14),
(7, 39, '400mg', 'Three times daily', 5, 15),
(19, 11, '10mg', 'Once daily', 30, 30),
(31, 28, '20mg', 'Every 12 hours', 10, 20),
(48, 35, '850mg', 'Twice daily', 30, 60),
(3, 13, '500mg', 'Once daily', 7, 7),
(16, 24, '250mg', 'Twice daily', 14, 28),
(29, 37, '100mg', 'Once daily', 30, 30),
(42, 17, '15mg', 'Every 8 hours', 10, 30),
(10, 1, '500mg', 'Twice daily', 7, 14),
(23, 30, '20mg', 'Once daily', 30, 30),
(36, 12, '250mg', 'Three times daily', 5, 15),
(5, 8, '100mg', 'Once daily', 14, 14),
(18, 40, '50mg', 'Every 12 hours', 10, 20),
(27, 20, '400mg', 'Once daily', 30, 30),
(40, 26, '300mg', 'Twice daily', 7, 14),
(14, 33, '10mg', 'Once daily', 30, 30),
(22, 15, '500mg', 'Every 8 hours', 5, 15),
(34, 4, '250mg', 'Twice daily', 14, 28),
(47, 18, '100mg', 'Once daily', 30, 30),
(9, 29, '20mg', 'Twice daily', 10, 20),
(50, 7, '50mg', 'Once daily', 14, 14),
(4, 15, '500mg', 'Twice daily', 10, 20),
(15, 27, '250mg', 'Once daily', 30, 30),
(28, 33, '100mg', 'Every 8 hours', 7, 21),
(39, 2, '50mg', 'Once daily', 14, 14),
(46, 18, '400mg', 'Three times daily', 5, 15),
(8, 9, '10mg', 'Once daily', 30, 30),
(21, 24, '20mg', 'Every 12 hours', 10, 20),
(32, 35, '850mg', 'Twice daily', 30, 60),
(44, 10, '500mg', 'Once daily', 7, 7),
(2, 29, '250mg', 'Twice daily', 14, 28),
(13, 21, '100mg', 'Once daily', 30, 30),
(26, 16, '15mg', 'Every 8 hours', 10, 30),
(37, 3, '500mg', 'Twice daily', 7, 14),
(49, 23, '20mg', 'Once daily', 30, 30),
(6, 31, '250mg', 'Three times daily', 5, 15),
(19, 7, '100mg', 'Once daily', 14, 14),
(30, 38, '50mg', 'Every 12 hours', 10, 20),
(41, 12, '400mg', 'Once daily', 30, 30),
(11, 26, '300mg', 'Twice daily', 7, 14),
(24, 34, '10mg', 'Once daily', 30, 30),
(35, 14, '500mg', 'Every 8 hours', 5, 15),
(47, 5, '250mg', 'Twice daily', 14, 28),
(9, 19, '100mg', 'Once daily', 30, 30),
(22, 28, '20mg', 'Twice daily', 10, 20),
(50, 6, '50mg', 'Once daily', 14, 14),
(5, 12, '500mg', 'Twice daily', 10, 20),
(12, 25, '250mg', 'Once daily', 30, 30),
(22, 33, '100mg', 'Every 8 hours', 7, 21),
(34, 4, '50mg', 'Once daily', 14, 14),
(45, 18, '400mg', 'Three times daily', 5, 15),
(3, 9, '10mg', 'Once daily', 30, 30),
(17, 24, '20mg', 'Every 12 hours', 10, 20),
(29, 35, '850mg', 'Twice daily', 30, 60),
(41, 10, '500mg', 'Once daily', 7, 7),
(50, 29, '250mg', 'Twice daily', 14, 28),
(8, 21, '100mg', 'Once daily', 30, 30),
(19, 16, '15mg', 'Every 8 hours', 10, 30),
(31, 3, '500mg', 'Twice daily', 7, 14),
(43, 23, '20mg', 'Once daily', 30, 30),
(1, 31, '250mg', 'Three times daily', 5, 15),
(14, 7, '100mg', 'Once daily', 14, 14),
(27, 38, '50mg', 'Every 12 hours', 10, 20),
(39, 12, '400mg', 'Once daily', 30, 30),
(48, 26, '300mg', 'Twice daily', 7, 14),
(25, 40, '10mg', 'Once daily', 14, 14);

-- أمر إدخال البيانات في جدول  ( lab_tests ) 

INSERT INTO lab_tests (test_name, category, price, normal_range, status) VALUES
('Complete Blood Count (CBC)', 'Hematology', 15.00, '4.5-11.0 10^3/uL', 'Active'),
('Fast Blood Glucose', 'Biochemistry', 10.00, '70-99 mg/dL', 'Active'),
('Lipid Profile', 'Biochemistry', 25.00, 'Desirable < 200 mg/dL', 'Active'),
('Liver Function Test (LFT)', 'Biochemistry', 30.00, 'Various ranges', 'Active'),
('Kidney Function Test (KFT)', 'Biochemistry', 28.00, 'Various ranges', 'Active'),
('Thyroid Stimulating Hormone (TSH)', 'Endocrinology', 35.00, '0.4-4.0 mIU/L', 'Active'),
('Hemoglobin A1c (HbA1c)', 'Biochemistry', 22.00, '< 5.7 %', 'Active'),
('Urinalysis', 'Pathology', 12.50, 'Negative for protein/glucose', 'Active'),
('Prothrombin Time (PT/INR)', 'Hematology', 18.00, '11.0-13.5 sec', 'Inactive'),
('Vitamin D 25-Hydroxy', 'Endocrinology', 45.00, '30-100 ng/mL', 'Active'),
('C-Reactive Protein (CRP)', 'Immunology', 20.00, '< 3.0 mg/L', 'Active'),
('Erythrocyte Sedimentation Rate (ESR)', 'Hematology', 14.00, '0-22 mm/hr', 'Inactive'),
('Serum Electrolytes', 'Biochemistry', 24.00, 'Na: 135-145, K: 3.5-5.0', 'Active'),
('Hepatitis B Surface Antigen', 'Virology', 30.00, 'Non-Reactive', 'Discontinued'),
('HIV 1/2 Antibody', 'Virology', 40.00, 'Non-Reactive', 'Active'),
('Pregnancy Test (Serum)', 'Endocrinology', 15.00, 'Negative', 'Active'),
('Stool Analysis', 'Pathology', 12.00, 'No parasites detected', 'Inactive'),
('Iron Panel', 'Biochemistry', 35.00, '60-170 mcg/dL', 'Active'),
('Rheumatoid Factor (RF)', 'Immunology', 22.00, '< 14 IU/mL', 'Discontinued'),
('PSA (Prostate Specific Antigen)', 'Endocrinology', 40.00, '< 4.0 ng/mL', 'Active'),
('Blood Typing (ABO/Rh)', 'Hematology', 10.00, 'Positive/Negative', 'Active'),
('Magnesium Serum', 'Biochemistry', 18.50, '1.7-2.2 mg/dL', 'Inactive'),
('Calcium Serum', 'Biochemistry', 16.00, '8.5-10.2 mg/dL', 'Active'),
('Uric Acid', 'Biochemistry', 14.00, '3.4-7.0 mg/dL', 'Active'),
('Troponin I', 'Cardiology', 50.00, '< 0.04 ng/mL', 'Discontinued');

-- أمر إدخال البيانات الى الجدول ( patient_lab_tests ) 

INSERT INTO patient_lab_tests (visit_id, lab_test_id, ordered_at, completed_at, result, result_status, status) VALUES
(5, 2, '2026-10-01 08:30:00', '2026-10-01 10:00:00', 'Hemoglobin: 14.2 g/dL', 'Normal', 'completed'),
(12, 5, '2026-10-01 09:00:00', '2026-10-01 11:30:00', 'Pending review', 'Pending', 'ordered'),
(20, 1, '2026-10-02 08:15:00', '2026-10-02 11:30:00', 'WBC: 7.5 10^3/uL', 'Normal', 'completed'),
(35, 10, '2026-10-02 10:00:00', '2026-10-02 12:00:00', 'In progress result', 'Pending', 'processing'),
(45, 15, '2026-10-03 08:00:00', '2026-10-03 09:30:00', 'Negative', 'Normal', 'completed'),
(8, 22, '2026-10-03 11:15:00', '2026-10-03 11:45:00', 'Cancelled by doctor', 'N/A', 'cancelled'),
(50, 3, '2026-10-04 08:30:00', '2026-10-04 12:00:00', 'Total Cholesterol: 190 mg/dL', 'Normal', 'completed'),
(15, 8, '2026-10-04 09:45:00', '2026-10-04 11:15:00', 'Clear yellow, Protein negative', 'Normal', 'completed'),
(62, 12, '2026-10-05 08:00:00', '2026-10-05 10:00:00', 'Sample collected', 'Pending', 'processing'),
(3, 20, '2026-10-05 09:30:00', '2026-10-05 14:00:00', 'PSA: 2.1 ng/mL', 'Normal', 'completed'),
(25, 7, '2026-10-06 08:10:00', '2026-10-06 10:30:00', 'HbA1c: 5.4%', 'Normal', 'completed'),
(33, 18, '2026-10-06 10:00:00', '2026-10-06 12:00:00', 'Awaiting processing', 'Pending', 'ordered'),
(55, 4, '2026-10-07 08:00:00', '2026-10-07 13:00:00', 'ALT: 25, AST: 22 U/L', 'Normal', 'completed'),
(18, 9, '2026-10-07 09:15:00', '2026-10-07 09:45:00', 'Sample rejected', 'N/A', 'cancelled'),
(40, 11, '2026-10-08 08:30:00', '2026-10-08 10:45:00', 'CRP: 2.1 mg/L', 'Normal', 'completed'),
(68, 25, '2026-10-08 11:00:00', '2026-10-08 12:30:00', 'Troponin: 0.01 ng/mL', 'Normal', 'completed'),
(10, 6, '2026-10-09 08:20:00', '2026-10-09 10:00:00', 'Processing', 'Pending', 'processing'),
(28, 14, '2026-10-09 09:50:00', '2026-10-09 11:40:00', 'ESR: 12 mm/hr', 'Normal', 'completed'),
(42, 17, '2026-10-10 08:00:00', '2026-10-10 09:30:00', 'Stool normal', 'Normal', 'completed'),
(58, 21, '2026-10-10 10:15:00', '2026-10-10 12:00:00', 'New order', 'Pending', 'ordered'),
(7, 13, '2026-10-11 08:30:00', '2026-10-11 11:00:00', 'Na: 140, K: 4.2', 'Normal', 'completed'),
(22, 19, '2026-10-11 09:30:00', '2026-10-11 10:00:00', 'Cancelled test', 'N/A', 'cancelled'),
(36, 23, '2026-10-12 08:00:00', '2026-10-12 09:45:00', 'Calcium: 9.4 mg/dL', 'Normal', 'completed'),
(49, 24, '2026-10-12 10:30:00', '2026-10-12 12:15:00', 'Uric Acid: 5.2 mg/dL', 'Normal', 'completed'),
(60, 1, '2026-10-13 08:15:00', '2026-10-13 10:30:00', 'Sample in lab', 'Pending', 'processing'),
(14, 4, '2026-10-13 09:00:00', '2026-10-13 11:00:00', 'Normal levels', 'Normal', 'completed'),
(23, 12, '2026-10-14 08:30:00', '2026-10-14 10:15:00', 'Pending review', 'Pending', 'ordered'),
(31, 7, '2026-10-14 10:00:00', '2026-10-14 12:30:00', 'Glucose: 95 mg/dL', 'Normal', 'completed'),
(44, 16, '2026-10-15 08:15:00', '2026-10-15 09:45:00', 'In progress', 'Pending', 'processing'),
(52, 2, '2026-10-15 09:30:00', '2026-10-15 11:00:00', 'Negative', 'Normal', 'completed'),
(61, 19, '2026-10-16 08:00:00', '2026-10-16 08:30:00', 'Cancelled by patient', 'N/A', 'cancelled'),
(4, 9, '2026-10-16 10:15:00', '2026-10-16 13:00:00', 'Cholesterol: 180 mg/dL', 'Normal', 'completed'),
(19, 15, '2026-10-17 08:30:00', '2026-10-17 10:00:00', 'Clear', 'Normal', 'completed'),
(37, 21, '2026-10-17 09:00:00', '2026-10-17 11:30:00', 'Sample processing', 'Pending', 'processing'),
(48, 5, '2026-10-18 08:00:00', '2026-10-18 12:00:00', 'TSH: 2.5 mIU/L', 'Normal', 'completed'),
(11, 22, '2026-10-18 08:45:00', '2026-10-18 10:30:00', 'HbA1c: 5.6%', 'Normal', 'completed'),
(26, 11, '2026-10-19 09:15:00', '2026-10-19 11:00:00', 'Ordered test', 'Pending', 'ordered'),
(39, 13, '2026-10-19 10:30:00', '2026-10-19 14:00:00', 'ALT: 20 U/L', 'Normal', 'completed'),
(53, 8, '2026-10-20 08:10:00', '2026-10-20 08:40:00', 'Rejected sample', 'N/A', 'cancelled'),
(65, 1, '2026-10-20 09:00:00', '2026-10-20 11:15:00', 'CRP: 1.5 mg/L', 'Normal', 'completed'),
(9, 18, '2026-10-21 08:30:00', '2026-10-21 10:00:00', 'Troponin: normal', 'Normal', 'completed'),
(21, 24, '2026-10-21 09:45:00', '2026-10-21 11:30:00', 'Processing state', 'Pending', 'processing'),
(34, 10, '2026-10-22 08:00:00', '2026-10-22 10:00:00', 'ESR: 10 mm/hr', 'Normal', 'completed'),
(46, 17, '2026-10-22 09:30:00', '2026-10-22 11:00:00', 'Stool sample normal', 'Normal', 'completed'),
(57, 25, '2026-10-23 08:15:00', '2026-10-23 10:30:00', 'New lab order', 'Pending', 'ordered'),
(13, 6, '2026-10-23 09:00:00', '2026-10-23 11:45:00', 'Electrolytes normal', 'Normal', 'completed'),
(29, 20, '2026-10-24 08:30:00', '2026-10-24 09:00:00', 'Cancelled order', 'N/A', 'cancelled'),
(41, 14, '2026-10-24 10:00:00', '2026-10-24 11:30:00', 'Calcium: 9.2 mg/dL', 'Normal', 'completed'),
(56, 3, '2026-10-25 08:15:00', '2026-10-25 10:15:00', 'Uric acid normal', 'Normal', 'completed'),
(67, 9, '2026-10-25 09:30:00', '2026-10-25 11:30:00', 'Lab in progress', 'Pending', 'processing'),
(15, 12, '2026-10-26 08:00:00', '2026-10-26 10:00:00', 'Normal', 'Normal', 'completed'),
(32, 5, '2026-10-26 09:15:00', '2026-10-26 11:30:00', 'Pending check', 'Pending', 'ordered'),
(48, 18, '2026-10-27 08:30:00', '2026-10-27 12:00:00', 'Glucose: 110 mg/dL', 'Normal', 'completed'),
(65, 2, '2026-10-27 10:00:00', '2026-10-27 11:15:00', 'Processing test', 'Pending', 'processing'),
(10, 22, '2026-10-28 08:00:00', '2026-10-28 09:30:00', 'Negative', 'Normal', 'completed'),
(27, 9, '2026-10-28 11:00:00', '2026-10-28 11:45:00', 'Cancelled by physician', 'N/A', 'cancelled'),
(42, 14, '2026-10-29 08:15:00', '2026-10-29 11:00:00', 'Cholesterol: 210 mg/dL', 'Normal', 'completed'),
(55, 3, '2026-10-29 09:30:00', '2026-10-29 10:45:00', 'Urine clear', 'Normal', 'completed'),
(6, 20, '2026-10-30 08:00:00', '2026-10-30 09:30:00', 'Sample collected', 'Pending', 'processing'),
(19, 7, '2026-10-30 10:00:00', '2026-10-30 13:00:00', 'PSA: 1.8 ng/mL', 'Normal', 'completed'),
(38, 11, '2026-10-31 08:30:00', '2026-10-31 10:00:00', 'HbA1c: 5.8%', 'Normal', 'completed'),
(50, 25, '2026-10-31 09:45:00', '2026-10-31 11:15:00', 'New request', 'Pending', 'ordered'),
(68, 16, '2026-11-01 08:00:00', '2026-11-01 12:30:00', 'ALT: 30 U/L', 'Normal', 'completed'),
(12, 4, '2026-11-01 09:15:00', '2026-11-01 09:45:00', 'Sample rejected', 'N/A', 'cancelled'),
(29, 13, '2026-11-02 08:30:00', '2026-11-02 10:45:00', 'CRP: 1.2 mg/L', 'Normal', 'completed'),
(44, 8, '2026-11-02 11:00:00', '2026-11-02 12:30:00', 'Troponin: 0.02', 'Normal', 'completed'),
(59, 1, '2026-11-03 08:20:00', '2026-11-03 10:00:00', 'In laboratory', 'Pending', 'processing'),
(21, 19, '2026-11-03 09:50:00', '2026-11-03 11:40:00', 'ESR: 15 mm/hr', 'Normal', 'completed'),
(35, 23, '2026-11-04 08:00:00', '2026-11-04 09:30:00', 'Stool test normal', 'Normal', 'completed'),
(49, 6, '2026-11-04 10:15:00', '2026-11-04 11:30:00', 'Order logged', 'Pending', 'ordered'),
(63, 15, '2026-11-05 08:30:00', '2026-11-05 11:00:00', 'Na: 138, K: 4.1', 'Normal', 'completed'),
(8, 10, '2026-11-05 09:30:00', '2026-11-05 10:00:00', 'Cancelled request', 'N/A', 'cancelled'),
(24, 21, '2026-11-06 08:00:00', '2026-11-06 09:45:00', 'Calcium: 9.5 mg/dL', 'Normal', 'completed'),
(41, 17, '2026-11-06 10:30:00', '2026-11-06 12:15:00', 'Uric acid: 5.0', 'Normal', 'completed'),
(57, 24, '2026-11-07 08:15:00', '2026-11-07 10:30:00', 'Processing sample', 'Pending', 'processing'),
(14, 18, '2026-11-08 08:00:00', '2026-11-08 10:30:00', 'Normal ranges', 'Normal', 'completed'),
(31, 3, '2026-11-08 09:15:00', '2026-11-08 11:00:00', 'Pending review', 'Pending', 'ordered'),
(45, 11, '2026-11-09 08:30:00', '2026-11-09 12:00:00', 'Glucose: 98 mg/dL', 'Normal', 'completed'),
(60, 22, '2026-11-09 10:00:00', '2026-11-09 11:15:00', 'Processing sample', 'Pending', 'processing'),
(5, 7, '2026-11-10 08:00:00', '2026-11-10 09:30:00', 'Negative result', 'Normal', 'completed'),
(22, 14, '2026-11-10 11:00:00', '2026-11-10 11:45:00', 'Cancelled by doctor', 'N/A', 'cancelled'),
(39, 25, '2026-11-11 08:15:00', '2026-11-11 11:00:00', 'Lipid profile normal', 'Normal', 'completed'),
(52, 9, '2026-11-11 09:30:00', '2026-11-11 10:45:00', 'Urine test clean', 'Normal', 'completed'),
(11, 2, '2026-11-12 08:00:00', '2026-11-12 09:30:00', 'Sample collected', 'Pending', 'processing'),
(28, 19, '2026-11-12 10:00:00', '2026-11-12 13:00:00', 'PSA: 2.0 ng/mL', 'Normal', 'completed'),
(43, 12, '2026-11-13 08:30:00', '2026-11-13 10:00:00', 'HbA1c: 5.5%', 'Normal', 'completed'),
(58, 4, '2026-11-13 09:45:00', '2026-11-13 11:15:00', 'New order logged', 'Pending', 'ordered'),
(67, 16, '2026-11-14 08:00:00', '2026-11-14 12:30:00', 'ALT: 28 U/L', 'Normal', 'completed'),
(7, 23, '2026-11-14 09:15:00', '2026-11-14 09:45:00', 'Sample rejected', 'N/A', 'cancelled'),
(24, 8, '2026-11-15 08:30:00', '2026-11-15 10:45:00', 'CRP: 1.0 mg/L', 'Normal', 'completed'),
(36, 20, '2026-11-15 11:00:00', '2026-11-15 12:30:00', 'Troponin: normal', 'Normal', 'completed'),
(51, 1, '2026-11-16 08:20:00', '2026-11-16 10:00:00', 'Lab in progress', 'Pending', 'processing'),
(18, 13, '2026-11-16 09:50:00', '2026-11-16 11:40:00', 'ESR: 10 mm/hr', 'Normal', 'completed'),
(33, 17, '2026-11-17 08:00:00', '2026-11-17 09:30:00', 'Stool test normal', 'Normal', 'completed'),
(47, 6, '2026-11-17 10:15:00', '2026-11-17 11:30:00', 'Order registered', 'Pending', 'ordered'),
(62, 21, '2026-11-18 08:30:00', '2026-11-18 11:00:00', 'Na: 140, K: 4.0', 'Normal', 'completed'),
(4, 15, '2026-11-18 09:30:00', '2026-11-18 10:00:00', 'Cancelled request', 'N/A', 'cancelled'),
(20, 10, '2026-11-19 08:00:00', '2026-11-19 09:45:00', 'Calcium: 9.3 mg/dL', 'Normal', 'completed'),
(38, 24, '2026-11-19 10:30:00', '2026-11-19 12:15:00', 'Uric acid: 5.4', 'Normal', 'completed'),
(55, 5, '2026-11-20 08:15:00', '2026-11-20 10:30:00', 'Processing sample', 'Pending', 'processing');

--- أمر إدخال بيانات الى الجدول ( admissions ) 

INSERT INTO admissions (patient_id, room_id, doctor_id, admitted_at, discharged_at, admission_reason, status) VALUES
(5, 10, 3, '2026-10-01 08:00:00', '2026-10-05 14:00:00', 'Acute Appendicitis', 'discharged'),
(12, 22, 7, '2026-10-02 09:30:00', '2026-10-10 10:00:00', 'Severe Pneumonia', 'discharged'),
(25, 5, 15, '2026-10-03 14:00:00', '2026-10-04 12:00:00', 'Hypertensive Crisis', 'discharged'),
(40, 18, 2, '2026-10-04 11:15:00', '2026-10-04 16:30:00', 'Scheduled Surgery Admission - Cancelled', 'cancelled'),
(3, 1, 20, '2026-10-05 07:30:00', '2026-10-12 09:00:00', 'Myocardial Infarction', 'discharged'),
(50, 14, 11, '2026-10-06 10:00:00', '2026-10-15 11:30:00', 'Type 2 Diabetes Complications', 'discharged'),
(18, 25, 9, '2026-10-07 12:30:00', '2026-10-14 15:00:00', 'Asthma Exacerbation', 'discharged'),
(33, 8, 4, '2026-10-08 08:15:00', '2026-10-08 13:00:00', 'Patient requested discharge against medical advice', 'cancelled'),
(60, 30, 22, '2026-10-09 15:00:00', '2026-10-20 10:00:00', 'Bone Fracture Recovery', 'discharged'),
(22, 12, 1, '2026-10-10 09:00:00', '2026-10-18 14:00:00', 'Gastroenteritis', 'discharged'),
(7, 19, 13, '2026-10-11 16:20:00', '2026-10-25 11:00:00', 'Severe Burn Injury', 'discharged'),
(45, 3, 18, '2026-10-12 11:00:00', '2026-10-12 14:00:00', 'Administrative cancellation', 'cancelled'),
(14, 27, 6, '2026-10-13 08:30:00', '2026-10-19 12:00:00', 'Kidney Stones', 'discharged'),
(31, 9, 25, '2026-10-14 10:45:00', '2026-10-22 09:30:00', 'Viral Meningitis', 'discharged'),
(58, 21, 10, '2026-10-15 13:10:00', '2026-10-28 16:00:00', 'Stroke Rehabilitation', 'discharged'),
(2, 16, 14, '2026-10-16 07:00:00', '2026-10-16 11:00:00', 'Duplicate booking cancellation', 'cancelled'),
(29, 4, 19, '2026-10-17 14:30:00', '2026-10-24 10:00:00', 'Cellulitis Treatment', 'discharged'),
(36, 28, 5, '2026-10-18 09:15:00', '2026-11-02 12:00:00', 'Post-operative Care', 'discharged'),
(11, 11, 21, '2026-10-19 11:00:00', '2026-10-30 09:00:00', 'Appendectomy Recovery', 'discharged'),
(52, 20, 8, '2026-10-20 08:00:00', '2026-10-20 12:30:00', 'Patient transfer error - cancelled', 'cancelled'),
(20, 6, 12, '2026-10-21 10:00:00', '2026-10-29 15:00:00', 'Bacterial Infection', 'discharged'),
(39, 23, 17, '2026-10-22 15:30:00', '2026-11-05 11:00:00', 'Chronic Heart Failure', 'discharged'),
(8, 15, 3, '2026-10-23 09:45:00', '2026-11-01 10:30:00', 'Pancreatitis', 'discharged'),
(55, 2, 24, '2026-10-24 12:00:00', '2026-10-24 17:00:00', 'Bed availability issue - cancelled', 'cancelled'),
(16, 26, 16, '2026-10-25 08:30:00', '2026-11-03 14:00:00', 'Cholecystitis', 'discharged'),
(34, 13, 2, '2026-10-26 10:15:00', '2026-11-10 09:00:00', 'Deep Vein Thrombosis under observation', 'admitted'),
(48, 29, 9, '2026-10-27 11:00:00', '2026-11-15 16:30:00', 'Severe Migraine Ongoing Treatment', 'admitted'),
(24, 7, 23, '2026-10-28 14:00:00', '2026-10-28 18:00:00', 'Family request cancellation', 'cancelled'),
(41, 17, 11, '2026-10-29 09:00:00', '2026-11-20 11:00:00', 'Pneumothorax Active Care', 'admitted'),
(19, 24, 15, '2026-10-30 08:00:00', '2026-11-25 10:00:00', 'General Trauma Recovery Ward', 'admitted');

-- أمر إدخال البيانات الى جدول ال ( insurance_companies ) 

INSERT INTO insurance_companies (company_name, phone, email, coverage_percentage, status) VALUES
('Global Insurance Co.', '+1-800-555-0199', 'info@globalins.com', 80.00, 'Active'),
('SafeLife Health Care', '+1-800-555-0288', 'support@safelife.com', 75.50, 'Active'),
('MedGuard Assurance', '+1-800-555-0377', 'contact@medguard.net', 90.00, 'Inactive'),
('Prime Care Insurance', '+1-800-555-0466', 'help@primecare.org', 60.00, 'Active'),
('Trustworthy Health Plan', '+1-800-555-0555', 'service@trustworthy.com', 85.00, 'Inactive');

-- أمر إضافة البيانات الى الجدول ( patient_insurance ) 

INSERT INTO patient_insurance (patient_id, insurance_company_id, policy_number, start_date, expiry_date, status) VALUES
(5, 2, 'POL-98210', '2025-01-01', '2026-01-01', 'Expired'),
(12, 1, 'POL-44125', '2026-01-15', '2027-01-15', 'Active'),
(24, 3, 'POL-77839', '2025-06-01', '2025-12-01', 'Cancelled'),
(35, 4, 'POL-11923', '2026-03-01', '2027-03-01', 'Active'),
(48, 5, 'POL-55648', '2024-02-10', '2025-02-10', 'Expired'),
(3, 2, 'POL-33214', '2026-02-01', '2027-02-01', 'Active'),
(15, 1, 'POL-88912', '2025-04-10', '2026-04-10', 'Expired'),
(29, 3, 'POL-66523', '2026-05-12', '2027-05-12', 'Active'),
(42, 4, 'POL-12345', '2025-03-15', '2025-09-15', 'Cancelled'),
(55, 5, 'POL-99876', '2026-06-01', '2027-06-01', 'Active'),
(8, 1, 'POL-23456', '2024-01-01', '2025-01-01', 'Expired'),
(19, 2, 'POL-34567', '2026-04-01', '2027-04-01', 'Active'),
(31, 3, 'POL-45678', '2025-05-20', '2025-11-20', 'Cancelled'),
(45, 4, 'POL-56789', '2026-07-01', '2027-07-01', 'Active'),
(58, 5, 'POL-67890', '2023-11-10', '2024-11-10', 'Expired'),
(1, 2, 'POL-11122', '2026-01-10', '2027-01-10', 'Active'),
(14, 3, 'POL-22233', '2025-08-01', '2026-02-01', 'Cancelled'),
(27, 4, 'POL-33344', '2026-02-15', '2027-02-15', 'Active'),
(38, 5, 'POL-44455', '2024-06-01', '2025-06-01', 'Expired'),
(50, 1, 'POL-55566', '2026-03-20', '2027-03-20', 'Active'),
(7, 3, 'POL-66677', '2025-09-10', '2026-03-10', 'Cancelled'),
(22, 4, 'POL-77788', '2026-04-10', '2027-04-10', 'Active'),
(33, 5, 'POL-88899', '2024-05-15', '2025-05-15', 'Expired'),
(46, 1, 'POL-99900', '2026-05-01', '2027-05-01', 'Active'),
(59, 2, 'POL-12131', '2025-07-15', '2025-12-31', 'Cancelled'),
(4, 4, 'POL-14151', '2026-06-10', '2027-06-10', 'Active'),
(17, 5, 'POL-16171', '2024-08-20', '2025-08-20', 'Expired'),
(28, 1, 'POL-18192', '2026-01-25', '2027-01-25', 'Active'),
(39, 2, 'POL-20212', '2025-02-10', '2025-08-10', 'Cancelled'),
(53, 3, 'POL-22232', '2026-02-28', '2027-02-28', 'Active'),
(10, 5, 'POL-24252', '2023-12-01', '2024-12-01', 'Expired'),
(21, 1, 'POL-26272', '2026-03-15', '2027-03-15', 'Active'),
(32, 2, 'POL-28293', '2025-04-05', '2025-10-05', 'Cancelled'),
(44, 3, 'POL-30313', '2026-04-20', '2027-04-20', 'Active'),
(57, 4, 'POL-32333', '2024-09-10', '2025-09-10', 'Expired'),
(6, 2, 'POL-34353', '2026-05-10', '2027-05-10', 'Active'),
(18, 3, 'POL-36373', '2025-06-15', '2025-12-15', 'Cancelled'),
(30, 4, 'POL-38393', '2026-06-25', '2027-06-25', 'Active'),
(41, 5, 'POL-40414', '2024-10-01', '2025-10-01', 'Expired'),
(56, 1, 'POL-42434', '2026-07-10', '2027-07-10', 'Active');

--- أمر إدخال البيانات الى الجدول ( invoices ) 

INSERT INTO invoices (patient_id, visit_id, admission_id, subtotal, insurance_discount, total_amount, issued_at, due_date, payment_status) VALUES
(5, 12, 3, 250.00, 50.00, 200.00, '2026-10-01 08:00:00', '2026-10-15 08:00:00', 'paid'),
(12, 25, 10, 450.00, 100.00, 350.00, '2026-10-02 09:30:00', '2026-10-16 09:30:00', 'unpaid'),
(24, 8, 15, 600.00, 150.00, 450.00, '2026-10-03 10:00:00', '2026-10-17 10:00:00', 'partially_paid'),
(35, 40, 22, 120.00, 20.00, 100.00, '2026-10-04 11:15:00', '2026-10-18 11:15:00', 'cancelled'),
(48, 55, 1, 800.00, 200.00, 600.00, '2026-10-05 08:30:00', '2026-10-19 08:30:00', 'paid'),
(3, 15, 28, 300.00, 50.00, 250.00, '2026-10-06 09:00:00', '2026-10-20 09:00:00', 'unpaid'),
(15, 30, 5, 150.00, 30.00, 120.00, '2026-10-07 10:30:00', '2026-10-21 10:30:00', 'paid'),
(29, 45, 12, 950.00, 250.00, 700.00, '2026-10-08 12:00:00', '2026-10-22 12:00:00', 'partially_paid'),
(42, 60, 18, 500.00, 100.00, 400.00, '2026-10-09 13:15:00', '2026-10-23 13:15:00', 'cancelled'),
(55, 10, 30, 400.00, 80.00, 320.00, '2026-10-10 14:00:00', '2026-10-24 14:00:00', 'paid'),
(8, 22, 14, 220.00, 20.00, 200.00, '2026-10-11 08:15:00', '2026-10-25 08:15:00', 'unpaid'),
(19, 35, 7, 750.00, 150.00, 600.00, '2026-10-12 09:45:00', '2026-10-26 09:45:00', 'paid'),
(31, 50, 20, 350.00, 50.00, 300.00, '2026-10-13 10:30:00', '2026-10-27 10:30:00', 'partially_paid'),
(45, 65, 25, 1100.00, 300.00, 800.00, '2026-10-14 11:00:00', '2026-10-28 11:00:00', 'unpaid'),
(58, 5, 9, 180.00, 30.00, 150.00, '2026-10-15 12:15:00', '2026-10-29 12:15:00', 'cancelled'),
(1, 18, 2, 550.00, 100.00, 450.00, '2026-10-16 08:00:00', '2026-10-30 08:00:00', 'paid'),
(14, 32, 16, 290.00, 40.00, 250.00, '2026-10-17 09:15:00', '2026-10-31 09:15:00', 'unpaid'),
(27, 48, 21, 620.00, 120.00, 500.00, '2026-10-18 10:00:00', '2026-11-01 10:00:00', 'partially_paid'),
(38, 58, 11, 410.00, 60.00, 350.00, '2026-10-19 11:30:00', '2026-11-02 11:30:00', 'paid'),
(50, 14, 27, 850.00, 200.00, 650.00, '2026-10-20 13:00:00', '2026-11-03 13:00:00', 'cancelled'),
(7, 27, 4, 330.00, 30.00, 300.00, '2026-10-21 08:30:00', '2026-11-04 08:30:00', 'unpaid'),
(22, 42, 19, 490.00, 90.00, 400.00, '2026-10-22 09:00:00', '2026-11-05 09:00:00', 'paid'),
(33, 56, 13, 710.00, 110.00, 600.00, '2026-10-23 10:15:00', '2026-11-06 10:15:00', 'partially_paid'),
(46, 68, 29, 230.00, 30.00, 200.00, '2026-10-24 11:45:00', '2026-11-07 11:45:00', 'paid'),
(59, 9, 8, 920.00, 220.00, 700.00, '2026-10-25 12:30:00', '2026-11-08 12:30:00', 'cancelled'),
(4, 21, 24, 380.00, 80.00, 300.00, '2026-10-26 08:00:00', '2026-11-09 08:00:00', 'unpaid'),
(17, 36, 17, 540.00, 90.00, 450.00, '2026-10-27 09:20:00', '2026-11-10 09:20:00', 'paid'),
(28, 51, 6, 670.00, 170.00, 500.00, '2026-10-28 10:10:00', '2026-11-11 10:10:00', 'partially_paid'),
(39, 62, 23, 260.00, 60.00, 200.00, '2026-10-29 11:00:00', '2026-11-12 11:00:00', 'paid'),
(53, 4, 12, 810.00, 210.00, 600.00, '2026-10-30 14:00:00', '2026-11-13 14:00:00', 'cancelled'),
(10, 20, 26, 430.00, 80.00, 350.00, '2026-10-31 08:15:00', '2026-11-14 08:15:00', 'unpaid'),
(21, 38, 15, 310.00, 60.00, 250.00, '2026-11-01 09:30:00', '2026-11-15 09:30:00', 'paid'),
(32, 55, 1, 590.00, 90.00, 500.00, '2026-11-02 10:00:00', '2026-11-16 10:00:00', 'partially_paid'),
(44, 11, 20, 720.00, 120.00, 600.00, '2026-11-03 11:15:00', '2026-11-17 11:15:00', 'paid'),
(57, 28, 9, 480.00, 80.00, 400.00, '2026-11-04 12:00:00', '2026-11-18 12:00:00', 'cancelled'),
(6, 43, 28, 240.00, 40.00, 200.00, '2026-11-05 08:00:00', '2026-11-19 08:00:00', 'unpaid'),
(18, 58, 14, 660.00, 160.00, 500.00, '2026-11-06 09:10:00', '2026-11-20 09:10:00', 'paid'),
(30, 67, 3, 390.00, 90.00, 300.00, '2026-11-07 10:30:00', '2026-11-21 10:30:00', 'partially_paid'),
(41, 7, 22, 530.00, 80.00, 450.00, '2026-11-08 11:20:00', '2026-11-22 11:20:00', 'paid'),
(56, 24, 10, 880.00, 180.00, 700.00, '2026-11-09 13:00:00', '2026-11-23 13:00:00', 'cancelled'),
(2, 36, 18, 270.00, 20.00, 250.00, '2026-11-10 08:30:00', '2026-11-24 08:30:00', 'unpaid'),
(13, 49, 5, 440.00, 90.00, 350.00, '2026-11-11 09:45:00', '2026-11-25 09:45:00', 'paid'),
(25, 62, 12, 610.00, 110.00, 500.00, '2026-11-12 10:15:00', '2026-11-26 10:15:00', 'partially_paid'),
(37, 3, 25, 360.00, 60.00, 300.00, '2026-11-13 11:00:00', '2026-11-27 11:00:00', 'paid'),
(49, 17, 30, 790.00, 190.00, 600.00, '2026-11-14 12:30:00', '2026-11-28 12:30:00', 'cancelled'),
(9, 31, 7, 340.00, 40.00, 300.00, '2026-11-15 08:00:00', '2026-11-29 08:00:00', 'unpaid'),
(20, 45, 19, 510.00, 110.00, 400.00, '2026-11-16 09:00:00', '2026-11-30 09:00:00', 'paid'),
(34, 59, 2, 630.00, 130.00, 500.00, '2026-11-17 10:00:00', '2026-12-01 10:00:00', 'partially_paid'),
(47, 12, 16, 420.00, 70.00, 350.00, '2026-11-18 11:15:00', '2026-12-02 11:15:00', 'paid'),
(60, 26, 21, 930.00, 230.00, 700.00, '2026-11-19 13:30:00', '2026-12-03 13:30:00', 'cancelled'),
(11, 39, 11, 280.00, 30.00, 250.00, '2026-11-20 08:15:00', '2026-12-04 08:15:00', 'unpaid'),
(23, 52, 27, 460.00, 110.00, 350.00, '2026-11-21 09:30:00', '2026-12-05 09:30:00', 'paid'),
(36, 64, 4, 740.00, 140.00, 600.00, '2026-11-22 10:45:00', '2026-12-06 10:45:00', 'partially_paid'),
(48, 8, 18, 320.00, 70.00, 250.00, '2026-11-23 11:00:00', '2026-12-07 11:00:00', 'paid'),
(1, 22, 13, 850.00, 150.00, 700.00, '2026-11-24 12:00:00', '2026-12-08 12:00:00', 'cancelled'),
(15, 35, 29, 390.00, 90.00, 300.00, '2026-11-25 08:00:00', '2026-12-09 08:00:00', 'unpaid'),
(26, 47, 8, 560.00, 60.00, 500.00, '2026-11-26 09:15:00', '2026-12-10 09:15:00', 'paid'),
(40, 61, 23, 690.00, 190.00, 500.00, '2026-11-27 10:30:00', '2026-12-11 10:30:00', 'partially_paid'),
(52, 15, 15, 450.00, 100.00, 350.00, '2026-11-28 11:15:00', '2026-12-12 11:15:00', 'paid'),
(5, 29, 20, 990.00, 290.00, 700.00, '2026-11-29 13:00:00', '2026-12-13 13:00:00', 'cancelled'),
(16, 42, 6, 210.00, 10.00, 200.00, '2026-11-30 08:30:00', '2026-12-14 08:30:00', 'unpaid'),
(29, 56, 22, 570.00, 120.00, 450.00, '2026-12-01 09:00:00', '2026-12-15 09:00:00', 'paid'),
(43, 69, 1, 680.00, 180.00, 500.00, '2026-12-02 10:10:00', '2026-12-16 10:10:00', 'partially_paid'),
(54, 6, 14, 370.00, 70.00, 300.00, '2026-12-03 11:20:00', '2026-12-17 11:20:00', 'paid'),
(8, 23, 27, 820.00, 220.00, 600.00, '2026-12-04 12:15:00', '2026-12-18 12:15:00', 'cancelled'),
(21, 37, 9, 310.00, 60.00, 250.00, '2026-12-05 08:00:00', '2026-12-19 08:00:00', 'unpaid'),
(33, 50, 25, 520.00, 120.00, 400.00, '2026-12-06 09:15:00', '2026-12-20 09:15:00', 'paid'),
(45, 63, 11, 640.00, 140.00, 500.00, '2026-12-07 10:30:00', '2026-12-21 10:30:00', 'partially_paid'),
(58, 10, 3, 400.00, 50.00, 350.00, '2026-12-08 11:00:00', '2026-12-22 11:00:00', 'paid'),
(3, 25, 19, 910.00, 210.00, 700.00, '2026-12-09 13:00:00', '2026-12-23 13:00:00', 'cancelled'),
(14, 40, 16, 290.00, 40.00, 250.00, '2026-12-10 08:15:00', '2026-12-24 08:15:00', 'unpaid'),
(27, 54, 7, 530.00, 80.00, 450.00, '2026-12-11 09:30:00', '2026-12-25 09:30:00', 'paid'),
(38, 66, 30, 750.00, 150.00, 600.00, '2026-12-12 10:45:00', '2026-12-26 10:45:00', 'partially_paid'),
(50, 13, 12, 380.00, 80.00, 300.00, '2026-12-13 11:00:00', '2026-12-27 11:00:00', 'paid'),
(7, 28, 24, 880.00, 180.00, 700.00, '2026-12-14 12:00:00', '2026-12-28 12:00:00', 'cancelled'),
(19, 44, 2, 260.00, 10.00, 250.00, '2026-12-15 08:00:00', '2026-12-29 08:00:00', 'unpaid'),
(31, 57, 18, 550.00, 100.00, 450.00, '2026-12-16 09:00:00', '2026-12-30 09:00:00', 'paid'),
(42, 70, 5, 710.00, 160.00, 550.00, '2026-12-17 10:15:00', '2026-12-31 10:15:00', 'partially_paid'),
(55, 5, 21, 420.00, 70.00, 350.00, '2026-12-18 11:30:00', '2027-01-01 11:30:00', 'paid'),
(12, 19, 10, 960.00, 260.00, 700.00, '2026-12-19 13:00:00', '2027-01-02 13:00:00', 'cancelled');

-- أمر إدخال البيانات الى الجدول ( payments ) 

INSERT INTO payments (invoice_id, amount, payment_method, transaction_reference, paid_at, status) VALUES
(12, 200.00, 'card', 'TXN-9001', '2026-10-01 08:30:00', 'completed'),
(25, 350.00, 'cash', 'TXN-9002', '2026-10-02 09:45:00', 'completed'),
(8, 450.00, 'bank_transfer', 'TXN-9003', '2026-10-03 10:15:00', 'pending'),
(40, 100.00, 'pix', 'TXN-9004', '2026-10-04 11:20:00', 'failed'),
(55, 600.00, 'insurance', 'TXN-9005', '2026-10-05 12:00:00', 'completed'),
(15, 250.00, 'card', 'TXN-9006', '2026-10-06 13:10:00', 'refunded'),
(30, 120.00, 'cash', 'TXN-9007', '2026-10-07 14:25:00', 'completed'),
(45, 700.00, 'bank_transfer', 'TXN-9008', '2026-10-08 15:00:00', 'completed'),
(60, 400.00, 'pix', 'TXN-9009', '2026-10-09 08:15:00', 'pending'),
(10, 320.00, 'insurance', 'TXN-9010', '2026-10-10 09:30:00', 'completed'),
(22, 200.00, 'card', 'TXN-9011', '2026-10-11 10:00:00', 'completed'),
(35, 600.00, 'cash', 'TXN-9012', '2026-10-12 11:10:00', 'failed'),
(50, 300.00, 'bank_transfer', 'TXN-9013', '2026-10-13 12:20:00', 'completed'),
(65, 800.00, 'pix', 'TXN-9014', '2026-10-14 13:30:00', 'pending'),
(5, 150.00, 'insurance', 'TXN-9015', '2026-10-15 14:40:00', 'completed'),
(18, 450.00, 'card', 'TXN-9016', '2026-10-16 08:00:00', 'refunded'),
(32, 250.00, 'cash', 'TXN-9017', '2026-10-17 09:15:00', 'completed'),
(48, 500.00, 'bank_transfer', 'TXN-9018', '2026-10-18 10:30:00', 'completed'),
(58, 350.00, 'pix', 'TXN-9019', '2026-10-19 11:45:00', 'pending'),
(14, 650.00, 'insurance', 'TXN-9020', '2026-10-20 13:00:00', 'completed'),
(27, 300.00, 'card', 'TXN-9021', '2026-10-21 14:10:00', 'completed'),
(42, 400.00, 'cash', 'TXN-9022', '2026-10-22 08:20:00', 'failed'),
(56, 600.00, 'bank_transfer', 'TXN-9023', '2026-10-23 09:30:00', 'completed'),
(68, 200.00, 'pix', 'TXN-9024', '2026-10-24 10:40:00', 'refunded'),
(9, 700.00, 'insurance', 'TXN-9025', '2026-10-25 11:50:00', 'completed'),
(21, 300.00, 'card', 'TXN-9026', '2026-10-26 13:00:00', 'pending'),
(36, 450.00, 'cash', 'TXN-9027', '2026-10-27 14:15:00', 'completed'),
(51, 500.00, 'bank_transfer', 'TXN-9028', '2026-10-28 08:10:00', 'completed'),
(62, 200.00, 'pix', 'TXN-9029', '2026-10-29 09:25:00', 'failed'),
(4, 600.00, 'insurance', 'TXN-9030', '2026-10-30 10:40:00', 'completed'),
(20, 350.00, 'card', 'TXN-9031', '2026-10-31 11:55:00', 'completed'),
(38, 250.00, 'cash', 'TXN-9032', '2026-11-01 13:10:00', 'pending'),
(55, 500.00, 'bank_transfer', 'TXN-9033', '2026-11-02 14:25:00', 'completed'),
(11, 600.00, 'pix', 'TXN-9034', '2026-11-03 08:00:00', 'refunded'),
(28, 400.00, 'insurance', 'TXN-9035', '2026-11-04 09:15:00', 'completed'),
(43, 200.00, 'card', 'TXN-9036', '2026-11-05 10:30:00', 'completed'),
(58, 500.00, 'cash', 'TXN-9037', '2026-11-06 11:45:00', 'failed'),
(67, 300.00, 'bank_transfer', 'TXN-9038', '2026-11-07 13:00:00', 'completed'),
(7, 450.00, 'pix', 'TXN-9039', '2026-11-08 14:15:00', 'pending'),
(24, 700.00, 'insurance', 'TXN-9040', '2026-11-09 08:30:00', 'completed'),
(36, 250.00, 'card', 'TXN-9041', '2026-11-10 09:45:00', 'completed'),
(49, 350.00, 'cash', 'TXN-9042', '2026-11-11 11:00:00', 'refunded'),
(62, 500.00, 'bank_transfer', 'TXN-9043', '2026-11-12 12:15:00', 'completed'),
(3, 300.00, 'pix', 'TXN-9044', '2026-11-13 13:30:00', 'failed'),
(17, 600.00, 'insurance', 'TXN-9045', '2026-11-14 14:45:00', 'completed'),
(31, 300.00, 'card', 'TXN-9046', '2026-11-15 08:00:00', 'pending'),
(45, 400.00, 'cash', 'TXN-9047', '2026-11-16 09:15:00', 'completed'),
(59, 500.00, 'bank_transfer', 'TXN-9048', '2026-11-17 10:30:00', 'completed'),
(12, 350.00, 'pix', 'TXN-9049', '2026-11-18 11:45:00', 'refunded'),
(26, 700.00, 'insurance', 'TXN-9050', '2026-11-19 13:00:00', 'completed'),
(39, 250.00, 'card', 'TXN-9051', '2026-11-20 14:10:00', 'completed'),
(53, 450.00, 'cash', 'TXN-9052', '2026-11-21 08:20:00', 'failed'),
(69, 500.00, 'bank_transfer', 'TXN-9053', '2026-11-22 09:30:00', 'completed'),
(6, 300.00, 'pix', 'TXN-9054', '2026-11-23 10:40:00', 'pending'),
(23, 600.00, 'insurance', 'TXN-9055', '2026-11-24 11:50:00', 'completed'),
(37, 250.00, 'card', 'TXN-9056', '2026-11-25 13:00:00', 'completed'),
(50, 400.00, 'cash', 'TXN-9057', '2026-11-26 14:15:00', 'refunded'),
(63, 500.00, 'bank_transfer', 'TXN-9058', '2026-11-27 08:10:00', 'completed'),
(10, 350.00, 'pix', 'TXN-9059', '2026-11-28 09:25:00', 'failed'),
(25, 700.00, 'insurance', 'TXN-9060', '2026-11-29 10:40:00', 'completed'),
(40, 500.00, 'card', 'TXN-9061', '2026-11-30 11:55:00', 'completed'),
(54, 300.00, 'cash', 'TXN-9062', '2026-12-01 13:10:00', 'pending'),
(66, 600.00, 'bank_transfer', 'TXN-9063', '2026-12-02 14:25:00', 'completed'),
(13, 350.00, 'pix', 'TXN-9064', '2026-12-03 08:00:00', 'refunded'),
(27, 450.00, 'insurance', 'TXN-9065', '2026-12-04 09:15:00', 'completed'),
(41, 600.00, 'card', 'TXN-9066', '2026-12-05 10:30:00', 'completed'),
(55, 350.00, 'cash', 'TXN-9067', '2026-12-06 11:45:00', 'failed'),
(70, 700.00, 'bank_transfer', 'TXN-9068', '2026-12-07 13:00:00', 'completed'),
(19, 250.00, 'pix', 'TXN-9069', '2026-12-08 14:15:00', 'pending'),
(31, 450.00, 'insurance', 'TXN-9070', '2026-12-09 08:30:00', 'completed'),
(44, 550.00, 'card', 'TXN-9071', '2026-12-10 09:45:00', 'completed'),
(5, 350.00, 'cash', 'TXN-9072', '2026-12-11 11:00:00', 'refunded'),
(19, 700.00, 'bank_transfer', 'TXN-9073', '2026-12-12 12:15:00', 'completed'),
(32, 250.00, 'pix', 'TXN-9074', '2026-12-13 13:30:00', 'failed'),
(46, 450.00, 'insurance', 'TXN-9075', '2026-12-14 14:45:00', 'completed'),
(60, 600.00, 'card', 'TXN-9076', '2026-12-15 08:00:00', 'pending'),
(8, 300.00, 'cash', 'TXN-9077', '2026-12-16 09:15:00', 'completed'),
(22, 700.00, 'bank_transfer', 'TXN-9078', '2026-12-17 10:30:00', 'completed'),
(35, 250.00, 'pix', 'TXN-9079', '2026-12-18 11:45:00', 'refunded'),
(48, 450.00, 'insurance', 'TXN-9080', '2026-12-19 13:00:00', 'completed'),
(2, 550.00, 'card', 'TXN-9081', '2026-12-20 08:15:00', 'completed'),
(16, 350.00, 'cash', 'TXN-9082', '2026-12-21 09:30:00', 'pending'),
(29, 450.00, 'bank_transfer', 'TXN-9083', '2026-12-22 10:45:00', 'completed'),
(43, 500.00, 'pix', 'TXN-9084', '2026-12-23 11:00:00', 'failed'),
(57, 300.00, 'insurance', 'TXN-9085', '2026-12-24 12:00:00', 'completed'),
(71, 600.00, 'card', 'TXN-9086', '2026-12-25 08:00:00', 'completed'),
(11, 250.00, 'cash', 'TXN-9087', '2026-12-26 09:00:00', 'refunded'),
(24, 400.00, 'bank_transfer', 'TXN-9088', '2026-12-27 10:00:00', 'completed'),
(38, 600.00, 'pix', 'TXN-9089', '2026-12-28 11:15:00', 'pending'),
(52, 350.00, 'insurance', 'TXN-9090', '2026-12-29 12:30:00', 'completed'),
(65, 700.00, 'card', 'TXN-9091', '2026-12-30 13:15:00', 'completed'),
(1, 250.00, 'cash', 'TXN-9092', '2026-12-31 08:30:00', 'failed'),
(15, 450.00, 'bank_transfer', 'TXN-9093', '2027-01-01 09:00:00', 'completed'),
(28, 600.00, 'pix', 'TXN-9094', '2027-01-02 10:10:00', 'refunded'),
(42, 350.00, 'insurance', 'TXN-9095', '2027-01-03 11:20:00', 'completed'),
(55, 700.00, 'card', 'TXN-9096', '2027-01-04 12:15:00', 'pending'),
(12, 700.00, 'cash', 'TXN-9097', '2027-01-05 08:00:00', 'completed'),
(26, 500.00, 'bank_transfer', 'TXN-9098', '2027-01-06 09:15:00', 'completed'),
(40, 350.00, 'pix', 'TXN-9099', '2027-01-07 10:30:00', 'failed'),
(74, 400.00, 'insurance', 'TXN-9100', '2027-01-08 11:00:00', 'completed');

-- من هنا تبدا تعليمات ال ( Queries ) 

-- تعليمة عرض جميع المرضى 

SELECT * FROM patients;

-- عرض جميع الأطباء مع القسم الخاص بكل طبيب

SELECT doctors.id, doctors.full_name AS doctor_name, departments.department_name AS department_name 
FROM doctors 
JOIN departments ON doctors.department_id = departments.id 
ORDER BY doctors.id ASC;

-- عرض جميع المواعيد مع اسم المريض والطبيب والقسم

SELECT 
    appointments.id AS appointment_id,
    patients.full_name AS patient_name,
    doctors.full_name AS doctor_name,
    departments.department_name AS department_name
FROM appointments
JOIN patients ON appointments.patient_id = patients.id
JOIN doctors ON appointments.doctor_id = doctors.id
JOIN departments ON doctors.department_id = departments.id
ORDER BY appointments.id ASC;

-- عرض مواعيد اليوم

SELECT * FROM appointments WHERE appointment_date = CURDATE() ORDER BY id ASC;

-- عرض المواعيد القادمة خلال 7 أيام

SELECT * FROM appointments WHERE appointment_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) ORDER BY id ASC;

-- عرض المرضى الذين لديهم أكثر من 3 مواعيد

SELECT patients.id, patients.full_name, COUNT(appointments.id) AS total_appointments 
FROM patients 
JOIN appointments ON patients.id = appointments.patient_id 
GROUP BY patients.id, patients.full_name 
HAVING COUNT(appointments.id) > 3;

-- عرض المرضى الذين لم يحجزوا أي موعد

SELECT patients.id, patients.full_name 
FROM patients 
LEFT JOIN appointments ON patients.id = appointments.patient_id 
WHERE appointments.id IS NULL;

-- عرض الأطباء الذين لا توجد لديهم مواعيد

SELECT doctors.id, doctors.full_name 
FROM doctors 
LEFT JOIN appointments ON doctors.id = appointments.doctor_id 
WHERE appointments.id IS NULL;

-- حساب عدد المواعيد لكل طبيب 

SELECT 
    doctors.id, 
    doctors.full_name, 
    COUNT(appointments.id) AS total_appointments 
FROM doctors 
LEFT JOIN appointments ON doctors.id = appointments.doctor_id 
GROUP BY doctors.id, doctors.full_name 
ORDER BY doctors.id ASC;

-- حساب عدد المواعيد لكل قسم

SELECT 
    departments.id, 
    departments.department_name, 
    COUNT(appointments.id) AS total_appointments 
FROM departments 
LEFT JOIN doctors ON departments.id = doctors.department_id 
LEFT JOIN appointments ON doctors.id = appointments.doctor_id 
GROUP BY departments.id, departments.department_name 
ORDER BY departments.id ASC;

-- عرض الطبيب صاحب أكبر عدد من المواعيد المكتملة

SELECT 
    doctors.id, 
    doctors.full_name, 
    COUNT(appointments.id) AS completed_appointments 
FROM doctors 
JOIN appointments ON doctors.id = appointments.doctor_id 
WHERE appointments.status = 'completed' 
GROUP BY doctors.id, doctors.full_name 
ORDER BY completed_appointments DESC 
LIMIT 1;








