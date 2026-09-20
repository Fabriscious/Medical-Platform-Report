-- ============================================================
-- 05_ANALISI_ECONOMICA_CLINICA
-- Revenue, specialties, diagnoses, medications and geography
-- ============================================================

USE medical_lazio_db;


-- ============================================================
-- 1. Revenue per specialità
-- ============================================================

SELECT
    p.specialty,
    COUNT(a.appointment_id) AS numero_visite,
    SUM(a.price_eur) AS valore_prestazioni,
    AVG(a.price_eur) AS prezzo_medio
FROM appointments a
JOIN providers p
    ON a.provider_id = p.provider_id
WHERE a.status = 'completed'
GROUP BY p.specialty
ORDER BY valore_prestazioni DESC;


-- ============================================================
-- 2. Fatturato incassato per specialità
-- ============================================================

SELECT
    p.specialty,
    SUM(b.total_amount_eur) AS fatturato_incassato
FROM billing b
JOIN appointments a
    ON b.appointment_id = a.appointment_id
JOIN providers p
    ON a.provider_id = p.provider_id
WHERE b.paid_flag = 1
GROUP BY p.specialty
ORDER BY fatturato_incassato DESC;


-- ============================================================
-- 3. Top 10 diagnosi ICD-10
-- ============================================================

SELECT
    icd10_code,
    COUNT(*) AS occorrenze
FROM diagnoses
GROUP BY icd10_code
ORDER BY occorrenze DESC
LIMIT 10;


-- ============================================================
-- 4. Top 10 farmaci / categorie ATC
-- ============================================================

SELECT
    atc_code,
    COUNT(*) AS prescrizioni
FROM medications
GROUP BY atc_code
ORDER BY prescrizioni DESC
LIMIT 10;


-- ============================================================
-- 5. Fatturato incassato per città
-- ============================================================

SELECT
    c.city,
    SUM(b.total_amount_eur) AS fatturato_incassato
FROM billing b
JOIN appointments a
    ON b.appointment_id = a.appointment_id
JOIN clinics c
    ON a.location_id = c.location_id
WHERE b.paid_flag = 1
GROUP BY c.city
ORDER BY fatturato_incassato DESC;


-- ============================================================
-- 6. Prezzo medio per tipo di assicurazione
-- ============================================================

SELECT
    p.insurance_type,
    AVG(a.price_eur) AS prezzo_medio
FROM appointments a
JOIN patients p
    ON a.patient_id = p.patient_id
WHERE a.status = 'completed'
GROUP BY p.insurance_type
ORDER BY prezzo_medio DESC;


-- ============================================================
-- END OF ECONOMIC & CLINICAL ANALYSIS
-- ============================================================