-- ============================================================
-- 04_ANALISI_TEMPORALE_DEMOGRAFICA
-- Temporal and patient population analysis
-- ============================================================

USE medical_lazio_db;


-- ============================================================
-- 1. Visite e fatturato per anno
-- ============================================================

SELECT
    YEAR(scheduled_datetime) AS anno,
    COUNT(*) AS numero_visite,
    SUM(price_eur) AS valore_prestazioni
FROM appointments
WHERE status = 'completed'
GROUP BY YEAR(scheduled_datetime)
ORDER BY anno;


-- ============================================================
-- 2. Fatturato incassato per anno
-- ============================================================

SELECT
    YEAR(invoice_date) AS anno,
    SUM(total_amount_eur) AS fatturato_incassato
FROM billing
WHERE paid_flag = 1
GROUP BY YEAR(invoice_date)
ORDER BY anno;


-- ============================================================
-- 3. Distribuzione pazienti per fascia d'età
-- ============================================================

SELECT
    CASE
        WHEN age < 30 THEN 'Under 30'
        WHEN age BETWEEN 30 AND 44 THEN '30-44'
        WHEN age BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+'
    END AS fascia_eta,
    COUNT(*) AS numero_pazienti,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients),
        2
    ) AS percentuale
FROM patients
GROUP BY fascia_eta
ORDER BY fascia_eta;


-- ============================================================
-- 4. Prevalenza condizioni croniche
-- ============================================================

SELECT
    SUM(hypertension) * 100.0 / COUNT(*) AS perc_hypertension,
    SUM(diabetes) * 100.0 / COUNT(*) AS perc_diabetes,
    SUM(asthma_copd) * 100.0 / COUNT(*) AS perc_asthma_copd,
    SUM(ischemic_heart) * 100.0 / COUNT(*) AS perc_ischemic_heart,
    SUM(obesity) * 100.0 / COUNT(*) AS perc_obesity
FROM patients;


-- ============================================================
-- 5. Distribuzione per tipo di assicurazione
-- ============================================================

SELECT
    insurance_type,
    COUNT(*) AS numero_pazienti,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM patients),
        2
    ) AS percentuale
FROM patients
GROUP BY insurance_type
ORDER BY numero_pazienti DESC;


-- ============================================================
-- 6. Numero pazienti per città
-- ============================================================

SELECT
    city,
    COUNT(*) AS numero_pazienti
FROM patients
GROUP BY city
ORDER BY numero_pazienti DESC;


-- ============================================================
-- END OF TEMPORAL & DEMOGRAPHIC ANALYSIS
-- ============================================================