-- ============================================================
-- 07_ANALISI_NO_SHOW
-- Analysis of missed appointments
-- ============================================================

USE medical_lazio_db;


-- ============================================================
-- 1. No-show rate by age group
-- ============================================================

SELECT
    CASE
        WHEN p.age < 30 THEN 'Under 30'
        WHEN p.age BETWEEN 30 AND 44 THEN '30-44'
        WHEN p.age BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+'
    END AS fascia_eta,

    SUM(
        CASE
            WHEN a.status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate

FROM appointments a

JOIN patients p
    ON a.patient_id = p.patient_id

GROUP BY fascia_eta
ORDER BY no_show_rate DESC;


-- ============================================================
-- 2. No-show rate by specialty
-- ============================================================

SELECT
    pr.specialty,

    SUM(
        CASE
            WHEN a.status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate

FROM appointments a

JOIN providers pr
    ON a.provider_id = pr.provider_id

GROUP BY pr.specialty
ORDER BY no_show_rate DESC;


-- ============================================================
-- 3. No-show rate by weekday
-- ============================================================

SELECT
    DAYNAME(scheduled_datetime) AS giorno,

    SUM(
        CASE
            WHEN status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate

FROM appointments

GROUP BY giorno
ORDER BY no_show_rate DESC;


-- ============================================================
-- 4. Reminder effectiveness
-- ============================================================

SELECT
    reminder_sent,

    SUM(
        CASE
            WHEN status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate

FROM appointments

GROUP BY reminder_sent;


-- ============================================================
-- 5. No-show by reminder + age group
-- Key analysis used in the report.
-- ============================================================

SELECT
    CASE
        WHEN p.age < 30 THEN 'Under 30'
        WHEN p.age BETWEEN 30 AND 44 THEN '30-44'
        WHEN p.age BETWEEN 45 AND 59 THEN '45-59'
        ELSE '60+'
    END AS fascia_eta,

    a.reminder_sent,

    SUM(
        CASE
            WHEN a.status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate

FROM appointments a

JOIN patients p
    ON a.patient_id = p.patient_id

GROUP BY
    fascia_eta,
    a.reminder_sent

ORDER BY fascia_eta, a.reminder_sent;


-- ============================================================
-- 6. No-show by lead time
-- ============================================================

SELECT

    CASE
        WHEN lead_time_days <= 3 THEN '0-3 giorni'
        WHEN lead_time_days BETWEEN 4 AND 7 THEN '4-7 giorni'
        WHEN lead_time_days BETWEEN 8 AND 14 THEN '8-14 giorni'
        ELSE '15+ giorni'
    END AS fascia_attesa,

    SUM(
        CASE
            WHEN status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate

FROM appointments

GROUP BY fascia_attesa
ORDER BY no_show_rate DESC;


-- ============================================================
-- 7. Potential revenue lost by no-show
-- ============================================================

SELECT
    SUM(price_eur) AS fatturato_perso_no_show
FROM appointments
WHERE status = 'no-show';


-- ============================================================
-- 8. No-show by reminder and specialty
-- Useful for identifying high-risk operational combinations.
-- ============================================================

SELECT
    p.specialty,
    a.reminder_sent,

    SUM(
        CASE
            WHEN a.status = 'no-show' THEN 1
            ELSE 0
        END
    ) * 100.0 / COUNT(*) AS no_show_rate

FROM appointments a

JOIN providers p
    ON a.provider_id = p.provider_id

GROUP BY
    p.specialty,
    a.reminder_sent

ORDER BY
    no_show_rate DESC;


-- ============================================================
-- END OF NO-SHOW ANALYSIS
-- ============================================================