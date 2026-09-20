-- ============================================================
-- MEDICAL DATA ANALYSIS PROJECT
-- Platform: Simulated Medical Services Platform - Lazio
-- Database schema creation
-- ============================================================

-- Select database
USE medical_lazio_db;


-- ============================================================
-- RESET SCHEMA
-- Used during development before the final schema was created.
-- WARNING: this deletes all tables and data.
-- Do NOT execute this section after importing the dataset
-- unless you intentionally want to rebuild the database.
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS lab_results;
DROP TABLE IF EXISTS billing;
DROP TABLE IF EXISTS medications;
DROP TABLE IF EXISTS diagnoses;
DROP TABLE IF EXISTS appointments;
DROP TABLE IF EXISTS clinics;
DROP TABLE IF EXISTS providers;
DROP TABLE IF EXISTS patients;

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- TABLE: patients
-- Main patient master data
-- ============================================================

CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    age INT,
    birth_date DATE,
    gender VARCHAR(10),
    city VARCHAR(100),
    postcode VARCHAR(10),
    enrollment_date DATE,
    hypertension BOOLEAN,
    diabetes BOOLEAN,
    asthma_copd BOOLEAN,
    ischemic_heart BOOLEAN,
    obesity BOOLEAN,
    insurance_type VARCHAR(50)
);


-- ============================================================
-- TABLE: providers
-- Healthcare providers / doctors
-- ============================================================

CREATE TABLE providers (
    provider_id INT PRIMARY KEY,
    specialty VARCHAR(100),
    city VARCHAR(100),
    joined_date DATE,
    active_flag BOOLEAN,
    location_id INT
);


-- ============================================================
-- TABLE: clinics
-- Healthcare facilities / locations
-- ============================================================

CREATE TABLE clinics (
    location_id INT PRIMARY KEY,
    city VARCHAR(100),
    capacity INT
);


-- ============================================================
-- TABLE: appointments
-- Central transactional table
-- ============================================================

CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT,
    provider_id INT,
    location_id INT,
    booking_datetime DATETIME,
    scheduled_datetime DATETIME,
    lead_time_days INT,
    appointment_type VARCHAR(50),
    status VARCHAR(50),
    duration_min INT,
    price_eur DECIMAL(10,2),
    reminder_sent BOOLEAN,

    FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id),

    FOREIGN KEY (provider_id)
        REFERENCES providers(provider_id),

    FOREIGN KEY (location_id)
        REFERENCES clinics(location_id)
);


-- ============================================================
-- TABLE: diagnoses
-- ICD-10 diagnoses associated with appointments
-- ============================================================

CREATE TABLE diagnoses (
    diagnosis_id INT PRIMARY KEY,
    appointment_id INT,
    patient_id INT,
    icd10_code VARCHAR(10),
    diagnosis_date DATE,

    FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id),

    FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
);


-- ============================================================
-- TABLE: medications
-- ATC-coded prescriptions
-- ============================================================

CREATE TABLE medications (
    med_id INT PRIMARY KEY,
    appointment_id INT,
    patient_id INT,
    atc_code VARCHAR(10),
    dose_info VARCHAR(100),
    duration_days INT,
    prescribed_date DATE,

    FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id),

    FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
);


-- ============================================================
-- TABLE: billing
-- Financial transactions
--
-- paid_flag:
-- 1 = invoice paid
-- 0 = invoice unpaid
-- ============================================================

CREATE TABLE billing (
    invoice_id INT PRIMARY KEY,
    appointment_id INT,
    patient_id INT,
    total_amount_eur DECIMAL(10,2),
    paid_flag BOOLEAN,
    payment_method VARCHAR(50),
    invoice_date DATE,

    FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id),

    FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
);


-- ============================================================
-- TABLE: lab_results
-- Laboratory test results
-- ============================================================

CREATE TABLE lab_results (
    lab_id INT PRIMARY KEY,
    appointment_id INT,
    patient_id INT,
    test_name VARCHAR(100),
    result_value DECIMAL(10,2),
    unit VARCHAR(20),
    ref_min DECIMAL(10,2),
    ref_max DECIMAL(10,2),
    sample_datetime DATETIME,

    FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id),

    FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
);


-- ============================================================
-- TABLE: feedback
-- Patient feedback after completed appointments
-- ============================================================

CREATE TABLE feedback (
    feedback_id INT PRIMARY KEY,
    appointment_id INT,
    patient_id INT,
    rating INT,
    submitted_date DATE,

    FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id),

    FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
);


-- ============================================================
-- END OF SCHEMA CREATION
-- ============================================================