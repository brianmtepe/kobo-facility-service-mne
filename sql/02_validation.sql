/* =========================================================
   KOBOTOOLBOX FACILITY SERVICE & M&E
   MYSQL DATA QUALITY + ANALYTICAL VALIDATION
   ========================================================= */

USE kobo_facility_mne;

/* 1. RECORD COUNT */
SELECT
    COUNT(*) AS total_records
FROM facility_mne_reporting;

/* 2. DUPLICATE FACILITY-PERIOD RECORDS */
SELECT
    facility_name,
    reporting_period,
    COUNT(*) AS record_count
FROM facility_mne_reporting
GROUP BY facility_name, reporting_period
HAVING COUNT(*) > 1;

/* 3. MISSING CRITICAL FIELDS */
SELECT
    COUNT(*) AS missing_critical_records
FROM facility_mne_reporting
WHERE facility_name IS NULL
   OR facility_level IS NULL
   OR county IS NULL
   OR reporting_period IS NULL;

/* 4. NEGATIVE SERVICE VALUES */
SELECT
    COUNT(*) AS invalid_numeric_records
FROM facility_mne_reporting
WHERE opd_visits < 0
   OR anc_visits < 0
   OR pnc_visits < 0
   OR immunization_visits < 0
   OR referrals < 0;

/* 5. REFERRALS GREATER THAN OPD */
SELECT
    COUNT(*) AS invalid_referral_records
FROM facility_mne_reporting
WHERE referrals > opd_visits;

/* 6. INVALID STOCKOUT DAYS */
SELECT
    COUNT(*) AS invalid_stockout_records
FROM facility_mne_reporting
WHERE stockout_occurred = 'Yes'
  AND (
      stockout_days IS NULL
      OR stockout_days < 1
      OR stockout_days > 31
  );

/* 7. TOTAL SERVICE CONTACTS CHECK */
SELECT
    COUNT(*) AS incorrect_total_contacts
FROM facility_mne_reporting
WHERE total_service_contacts <>
      (
          opd_visits
          + anc_visits
          + pnc_visits
          + immunization_visits
      );

/* 8. REFERRAL RATE CHECK */
SELECT
    COUNT(*) AS incorrect_referral_rates
FROM facility_mne_reporting
WHERE ABS(
    referral_rate -
    (
        referrals / NULLIF(opd_visits, 0) * 100
    )
) > 0.01;

/* 9. STOCKOUT FLAG CHECK */
SELECT
    COUNT(*) AS incorrect_stockout_flags
FROM facility_mne_reporting
WHERE stockout_flag <>
      CASE
          WHEN stockout_occurred = 'Yes'
          THEN 1
          ELSE 0
      END;

/* 10. FUTURE REPORTING DATES */
SELECT
    COUNT(*) AS future_reporting_dates
FROM facility_mne_reporting
WHERE reporting_period > CURRENT_DATE;

/* 11. OVERALL SERVICE SUMMARY */
SELECT
    COUNT(*) AS facilities_reporting,
    SUM(opd_visits) AS total_opd,
    SUM(anc_visits) AS total_anc,
    SUM(pnc_visits) AS total_pnc,
    SUM(immunization_visits) AS total_immunization,
    SUM(referrals) AS total_referrals,
    SUM(total_service_contacts) AS total_service_contacts,
    ROUND(
        SUM(referrals) /
        NULLIF(SUM(opd_visits), 0) * 100,
        2
    ) AS overall_referral_rate
FROM facility_mne_reporting;

/* 12. COUNTY SUMMARY */
SELECT
    county,
    COUNT(*) AS facilities_reporting,
    SUM(opd_visits) AS opd_visits,
    SUM(anc_visits) AS anc_visits,
    SUM(pnc_visits) AS pnc_visits,
    SUM(immunization_visits) AS immunization_visits,
    SUM(referrals) AS referrals,
    SUM(total_service_contacts) AS total_service_contacts
FROM facility_mne_reporting
GROUP BY county
ORDER BY total_service_contacts DESC;

/* 13. STOCKOUT DETAILS */
SELECT
    facility_name,
    facility_level,
    county,
    reporting_period,
    product_affected,
    stockout_days
FROM facility_mne_reporting
WHERE stockout_flag = 1
ORDER BY stockout_days DESC;

/* 14. DATA QUALITY EXCEPTIONS */
SELECT
    facility_name,
    facility_level,
    county,
    reporting_period,
    reporting_completed,
    missing_registers,
    missing_register_types,
    verification_completed
FROM facility_mne_reporting
WHERE reporting_completed = 'No'
   OR missing_registers = 'Yes'
   OR verification_completed = 'No'
ORDER BY reporting_period;

/* 15. MONTHLY M&E TRENDS */
SELECT *
FROM vw_monthly_mne_trends
ORDER BY reporting_period;

/* 16. FINAL QA SCORECARD */
SELECT
    'Total records' AS check_name,
    COUNT(*) AS result
FROM facility_mne_reporting

UNION ALL

SELECT
    'Duplicate facility-period records',
    COUNT(*)
FROM (
    SELECT facility_name, reporting_period
    FROM facility_mne_reporting
    GROUP BY facility_name, reporting_period
    HAVING COUNT(*) > 1
) AS duplicates

UNION ALL

SELECT
    'Missing critical records',
    COUNT(*)
FROM facility_mne_reporting
WHERE facility_name IS NULL
   OR facility_level IS NULL
   OR county IS NULL
   OR reporting_period IS NULL

UNION ALL

SELECT
    'Negative service values',
    COUNT(*)
FROM facility_mne_reporting
WHERE opd_visits < 0
   OR anc_visits < 0
   OR pnc_visits < 0
   OR immunization_visits < 0
   OR referrals < 0

UNION ALL

SELECT
    'Referrals greater than OPD',
    COUNT(*)
FROM facility_mne_reporting
WHERE referrals > opd_visits

UNION ALL

SELECT
    'Invalid stockout days',
    COUNT(*)
FROM facility_mne_reporting
WHERE stockout_occurred = 'Yes'
  AND (
      stockout_days IS NULL
      OR stockout_days < 1
      OR stockout_days > 31
  )

UNION ALL

SELECT
    'Incorrect total contacts',
    COUNT(*)
FROM facility_mne_reporting
WHERE total_service_contacts <>
      opd_visits
      + anc_visits
      + pnc_visits
      + immunization_visits

UNION ALL

SELECT
    'Incorrect referral rates',
    COUNT(*)
FROM facility_mne_reporting
WHERE ABS(
    referral_rate -
    (
        referrals / NULLIF(opd_visits, 0) * 100
    )
) > 0.01

UNION ALL

SELECT
    'Incorrect stockout flags',
    COUNT(*)
FROM facility_mne_reporting
WHERE stockout_flag <>
      CASE
          WHEN stockout_occurred = 'Yes'
          THEN 1
          ELSE 0
      END;