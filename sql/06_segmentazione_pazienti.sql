-- ============================================================
-- 06_SEGMENTAZIONE_PAZIENTI
-- Patient value and clinical risk segmentation
-- ============================================================

USE medical_lazio_db;


-- ============================================================
-- 1. Top 10% patients by total value
--
-- 5,000 patients = 10% of 50,000 simulated patients.
-- ============================================================

SELECT
    patient_id,
    SUM(price_eur) AS totale_speso
FROM appointments
WHERE status = 'completed'
GROUP BY patient_id
ORDER BY totale_speso DESC
LIMIT 5000;


-- ============================================================
-- 2. Average appointment value by insurance type
-- ============================================================

SELECT
    p.insurance_type,
    AVG(a.price_eur) AS spesa_media
FROM appointments a
JOIN patients p
    ON a.patient_id = p.patient_id
WHERE a.status = 'completed'
GROUP BY p.insurance_type;


-- ============================================================
-- 3. Clinical risk score
--
-- Score = number of chronic conditions among:
-- hypertension
-- diabetes
-- asthma/COPD
-- ischemic heart disease
-- obesity
-- ============================================================

SELECT
    patient_id,
    (
        hypertension
        + diabetes
        + asthma_copd
        + ischemic_heart
        + obesity
    ) AS risk_score
FROM patients
ORDER BY risk_score DESC;


-- ============================================================
-- 4. Risk score distribution
-- More useful than returning thousands of individual patients.
-- ============================================================

SELECT
    risk_score,
    COUNT(*) AS numero_pazienti
FROM (
    SELECT
        patient_id,
        (
            hypertension
            + diabetes
            + asthma_copd
            + ischemic_heart
            + obesity
        ) AS risk_score
    FROM patients
) AS risk_table
GROUP BY risk_score
ORDER BY risk_score DESC;


-- ============================================================
-- 5. High-frequency patients
--
-- At least 10 completed visits.
-- ============================================================

SELECT
    p.patient_id,
    COUNT(a.appointment_id) AS numero_visite,
    SUM(a.price_eur) AS totale_speso
FROM appointments a
JOIN patients p
    ON a.patient_id = p.patient_id
WHERE a.status = 'completed'
GROUP BY p.patient_id
HAVING numero_visite >= 10
ORDER BY totale_speso DESC;


-- ============================================================
-- 6. Top 20 patients by completed-visit value
-- ============================================================

SELECT
    patient_id,
    COUNT(*) AS numero_visite,
    SUM(price_eur) AS totale_speso
FROM appointments
WHERE status = 'completed'
GROUP BY patient_id
ORDER BY totale_speso DESC
LIMIT 20;


-- ============================================================
-- END OF PATIENT SEGMENTATION
-- ============================================================