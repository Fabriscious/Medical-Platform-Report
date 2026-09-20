-- ============================================================
-- 03_KPI_GENERALI
-- Main business KPIs
-- ============================================================

USE medical_lazio_db;


-- ============================================================
-- 1. Fatturato incassato
--
-- Only invoices with paid_flag = 1 are included.
-- This is the official revenue KPI.
-- ============================================================

SELECT
    SUM(total_amount_eur) AS fatturato_incassato
FROM billing
WHERE paid_flag = 1;


-- ============================================================
-- 2. Visite completate
-- ============================================================

SELECT
    COUNT(*) AS visite_completate
FROM appointments
WHERE status = 'completed';


-- ============================================================
-- 3. Appuntamenti totali
-- ============================================================

SELECT
    COUNT(*) AS visite_totali
FROM appointments;


-- ============================================================
-- 4. Visite medie per paziente
-- ============================================================

SELECT
    COUNT(*) * 1.0
    / COUNT(DISTINCT patient_id) AS visite_medie_per_paziente
FROM appointments;


-- ============================================================
-- 5. No-show rate
--
-- IMPORTANT:
-- status value = 'no-show'
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate_percent
FROM appointments;


-- ============================================================
-- 6. Reminder coverage
-- ============================================================

SELECT
    SUM(
        CASE
            WHEN reminder_sent = 1 THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS reminder_rate_percent
FROM appointments;


-- ============================================================
-- 7. Fatturato perso per no-show
--
-- This is the theoretical economic value of missed appointments.
-- It is NOT the same as unpaid invoices.
-- ============================================================

SELECT
    SUM(price_eur) AS fatturato_perso_no_show
FROM appointments
WHERE status = 'no-show';


-- ============================================================
-- 8. Revenue media delle visite completate
-- ============================================================

SELECT
    AVG(price_eur) AS revenue_media_visita_completata
FROM appointments
WHERE status = 'completed';


-- ============================================================
-- 9. Revenue media delle visite effettivamente pagate
-- ============================================================
-- Join billing + appointments to keep the financial metric
-- linked to the appointment data.

SELECT
    AVG(b.total_amount_eur) AS revenue_media_visita_pagata
FROM billing b
WHERE b.paid_flag = 1;


-- ============================================================
-- END OF KPI ANALYSIS
-- ============================================================