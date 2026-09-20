-- ============================================================
-- 08_VISTE_POWERBI
-- SQL views prepared for Power BI
-- ============================================================

USE medical_lazio_db;


-- ============================================================
-- 1. General KPI view
-- ============================================================

CREATE OR REPLACE VIEW vw_kpi_generali AS

SELECT

    -- Total appointments
    COUNT(a.appointment_id) AS totale_appuntamenti,

    -- Completed appointments
    SUM(
        CASE
            WHEN a.status = 'completed' THEN 1
            ELSE 0
        END
    ) AS visite_completate,

    -- No-show rate
    SUM(
        CASE
            WHEN a.status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate,

    -- Reminder coverage
    SUM(
        CASE
            WHEN a.reminder_sent = 1 THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS reminder_rate,

    -- Collected revenue
    (
        SELECT SUM(b.total_amount_eur)
        FROM billing b
        WHERE b.paid_flag = 1
    ) AS fatturato_incassato,

    -- Potential value lost through no-shows
    SUM(
        CASE
            WHEN a.status = 'no-show'
            THEN a.price_eur
            ELSE 0
        END
    ) AS fatturato_perso_no_show

FROM appointments a;


-- ============================================================
-- 2. Revenue by specialty
-- Only paid invoices are considered.
-- ============================================================

CREATE OR REPLACE VIEW vw_revenue_specialty AS

SELECT
    p.specialty,
    COUNT(DISTINCT b.appointment_id) AS visite_pagata,
    SUM(b.total_amount_eur) AS fatturato_incassato,
    AVG(b.total_amount_eur) AS revenue_media

FROM billing b

JOIN appointments a
    ON b.appointment_id = a.appointment_id

JOIN providers p
    ON a.provider_id = p.provider_id

WHERE b.paid_flag = 1

GROUP BY p.specialty;


-- ============================================================
-- 3. No-show by age group
-- ============================================================

CREATE OR REPLACE VIEW vw_no_show_eta AS

SELECT

    CASE
        WHEN p.age < 30 THEN 'Under 30'
        WHEN p.age BETWEEN 30 AND 44 THEN '30-44'
        WHEN p.age BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+'
    END AS fascia_eta,

    COUNT(a.appointment_id) AS numero_appuntamenti,

    SUM(
        CASE
            WHEN a.status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate

FROM appointments a

JOIN patients p
    ON a.patient_id = p.patient_id

GROUP BY fascia_eta;


-- ============================================================
-- 4. Revenue by city
-- ============================================================

CREATE OR REPLACE VIEW vw_revenue_city AS

SELECT
    c.city,
    SUM(b.total_amount_eur) AS fatturato_incassato

FROM billing b

JOIN appointments a
    ON b.appointment_id = a.appointment_id

JOIN clinics c
    ON a.location_id = c.location_id

WHERE b.paid_flag = 1

GROUP BY c.city;


-- ============================================================
-- 5. Revenue by specialty and city
-- Useful for matrix/drill-down analyses in Power BI.
-- ============================================================

CREATE OR REPLACE VIEW vw_revenue_specialty_city AS

SELECT
    p.specialty,
    c.city,
    SUM(b.total_amount_eur) AS fatturato_incassato,
    COUNT(DISTINCT b.appointment_id) AS visite_pagata

FROM billing b

JOIN appointments a
    ON b.appointment_id = a.appointment_id

JOIN providers p
    ON a.provider_id = p.provider_id

JOIN clinics c
    ON a.location_id = c.location_id

WHERE b.paid_flag = 1

GROUP BY
    p.specialty,
    c.city;


-- ============================================================
-- END OF POWER BI VIEWS
-- ============================================================