/* =========================================================
   KOBOTOOLBOX FACILITY SERVICE & M&E
   MYSQL DATABASE + ANALYTICAL VIEWS
   Workflow: Kobo → Python/Pandas → MySQL → Power BI
   ========================================================= */

CREATE DATABASE IF NOT EXISTS kobo_facility_mne;
USE kobo_facility_mne;


CREATE TABLE facility_mne_reporting (
    record_id INT AUTO_INCREMENT PRIMARY KEY,

    facility_name VARCHAR(150) NOT NULL,
    facility_level VARCHAR(20) NOT NULL,
    county VARCHAR(50) NOT NULL,
    reporting_period DATE NOT NULL,

    opd_visits INT NOT NULL,
    anc_visits INT NOT NULL,
    pnc_visits INT NOT NULL,
    immunization_visits INT NOT NULL,
    referrals INT NOT NULL,

    stockout_occurred VARCHAR(10),
    product_affected VARCHAR(100),
    stockout_days INT,

    reporting_completed VARCHAR(10),
    missing_registers VARCHAR(10),
    missing_register_types VARCHAR(255),
    verification_completed VARCHAR(10),

    total_service_contacts INT,
    referral_rate DECIMAL(8,2),
    stockout_flag TINYINT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_facility_period
        (facility_name, reporting_period)
);

/* ---------------------------------------------------------
   ANALYTICAL VIEW 1: Facility service performance
   --------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_facility_service_summary AS
SELECT
    facility_name,
    facility_level,
    county,
    reporting_period,
    opd_visits,
    anc_visits,
    pnc_visits,
    immunization_visits,
    referrals,
    total_service_contacts,
    referral_rate
FROM facility_mne_reporting;

/* ---------------------------------------------------------
   ANALYTICAL VIEW 2: County service performance
   --------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_county_service_summary AS
SELECT
    county,
    COUNT(*) AS facilities_reporting,
    SUM(opd_visits) AS opd_visits,
    SUM(anc_visits) AS anc_visits,
    SUM(pnc_visits) AS pnc_visits,
    SUM(immunization_visits) AS immunization_visits,
    SUM(referrals) AS referrals,
    SUM(total_service_contacts) AS total_service_contacts,
    ROUND(
        SUM(referrals) / NULLIF(SUM(opd_visits), 0) * 100,
        2
    ) AS referral_rate
FROM facility_mne_reporting
GROUP BY county;

/* ---------------------------------------------------------
   ANALYTICAL VIEW 3: Pharmaceutical stockouts
   --------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_pharmaceutical_stockouts AS
SELECT
    facility_name,
    facility_level,
    county,
    reporting_period,
    stockout_occurred,
    product_affected,
    stockout_days,
    stockout_flag
FROM facility_mne_reporting
WHERE stockout_flag = 1;

/* ---------------------------------------------------------
   ANALYTICAL VIEW 4: Reporting/data quality
   --------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_reporting_quality AS
SELECT
    facility_name,
    facility_level,
    county,
    reporting_period,
    reporting_completed,
    missing_registers,
    missing_register_types,
    verification_completed
FROM facility_mne_reporting;

/* ---------------------------------------------------------
   ANALYTICAL VIEW 5: Monthly M&E trends
   --------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_monthly_mne_trends AS
SELECT
    reporting_period,
    COUNT(*) AS facilities_reporting,
    SUM(total_service_contacts) AS total_service_contacts,
    SUM(opd_visits) AS opd_visits,
    SUM(anc_visits) AS anc_visits,
    SUM(pnc_visits) AS pnc_visits,
    SUM(immunization_visits) AS immunization_visits,
    SUM(referrals) AS referrals,
    SUM(stockout_flag) AS facilities_with_stockouts,
    ROUND(AVG(referral_rate), 2) AS average_referral_rate
FROM facility_mne_reporting
GROUP BY reporting_period
ORDER BY reporting_period;

/* ---------------------------------------------------------
   ANALYTICAL VIEW 6: Power BI master view
   --------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_facility_mne_master AS
SELECT
    record_id,
    facility_name,
    facility_level,
    county,
    reporting_period,
    opd_visits,
    anc_visits,
    pnc_visits,
    immunization_visits,
    referrals,
    total_service_contacts,
    referral_rate,
    stockout_occurred,
    product_affected,
    stockout_days,
    stockout_flag,
    reporting_completed,
    missing_registers,
    missing_register_types,
    verification_completed
FROM facility_mne_reporting;

/* ---------------------------------------------------------
   CHECK VIEWS
   --------------------------------------------------------- */
SHOW FULL TABLES
WHERE Table_type = 'VIEW';

USE kobo_facility_mne;

LOAD DATA LOCAL INFILE
'C:/Users/USER/Desktop/kobo-facility-service-mne/data/processed/kobo_mysql_import.csv'
INTO TABLE facility_mne_reporting
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    facility_name,
    facility_level,
    county,
    reporting_period,
    opd_visits,
    anc_visits,
    pnc_visits,
    immunization_visits,
    referrals,
    stockout_occurred,
    product_affected,
    stockout_days,
    reporting_completed,
    missing_registers,
    missing_register_types,
    verification_completed,
    total_service_contacts,
    referral_rate,
    stockout_flag
);