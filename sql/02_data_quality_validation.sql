-- ============================================================
-- 02_DATA_QUALITY_VALIDATION
-- Data quality and integrity checks
-- ============================================================

USE medical_lazio_db;


-- ============================================================
-- 1. Row counts
-- ============================================================

SELECT 'patients' AS table_name, COUNT(*) AS row_count
FROM patients

UNION ALL

SELECT 'clinics', COUNT(*)
FROM clinics

UNION ALL

SELECT 'providers', COUNT(*)
FROM providers

UNION ALL

SELECT 'appointments', COUNT(*)
FROM appointments

UNION ALL

SELECT 'diagnoses', COUNT(*)
FROM diagnoses

UNION ALL

SELECT 'medications', COUNT(*)
FROM medications

UNION ALL

SELECT 'billing', COUNT(*)
FROM billing

UNION ALL

SELECT 'lab_results', COUNT(*)
FROM lab_results

UNION ALL

SELECT 'feedback', COUNT(*)
FROM feedback;


-- ============================================================
-- 2. Referential integrity - appointments without patients
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS appointments_without_patient
FROM appointments a
LEFT JOIN patients p
    ON a.patient_id = p.patient_id
WHERE p.patient_id IS NULL;


-- ============================================================
-- 3. Referential integrity - appointments without providers
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS appointments_without_provider
FROM appointments a
LEFT JOIN providers p
    ON a.provider_id = p.provider_id
WHERE p.provider_id IS NULL;


-- ============================================================
-- 4. Referential integrity - appointments without clinics
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS appointments_without_clinic
FROM appointments a
LEFT JOIN clinics c
    ON a.location_id = c.location_id
WHERE c.location_id IS NULL;


-- ============================================================
-- 5. Negative prices
-- Expected result: 0
-- ============================================================

SELECT COUNT(*) AS negative_prices
FROM appointments
WHERE price_eur < 0;


-- ============================================================
-- 6. Appointment status distribution
-- ============================================================

SELECT
    status,
    COUNT(*) AS appointment_count,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments),
        2
    ) AS percentage
FROM appointments
GROUP BY status
ORDER BY appointment_count DESC;


-- ============================================================
-- 7. Duration sanity check
-- ============================================================

SELECT
    MIN(duration_min) AS minimum_duration,
    MAX(duration_min) AS maximum_duration,
    ROUND(AVG(duration_min), 2) AS average_duration
FROM appointments;


-- ============================================================
-- 8. Check paid_flag distribution
--
-- 1 = paid
-- 0 = unpaid
-- ============================================================

SELECT
    paid_flag,
    COUNT(*) AS invoice_count,
    ROUND(
        COUNT(*) * 100.0 / COUNT(*) OVER (),
        2
    ) AS percentage
FROM billing
GROUP BY paid_flag;


-- ============================================================
-- 9. Check reminder distribution
--
-- reminder_sent:
-- TRUE  = reminder sent
-- FALSE = reminder not sent
-- ============================================================

SELECT
    reminder_sent,
    COUNT(*) AS appointment_count
FROM appointments
GROUP BY reminder_sent;


-- ============================================================
-- END OF DATA QUALITY VALIDATION
-- ============================================================