-- =========================================================
-- HR WORKFORCE ATTRITION & RETENTION ANALYSIS
-- 01_CREATE_IMPORT_VALIDATE.SQL
-- PostgreSQL · Python Cleaning + SQL Analysis Architecture
--
-- Clean CSV Path:
-- D:/hr_analytics_project/data/clean
--
-- Project flow:
-- Raw CSVs -> Python Profiling -> Python Cleaning -> Clean CSVs -> PostgreSQL -> SQL Analysis
-- =========================================================


-- =========================================================
-- 0) CLEAN START
-- =========================================================

DROP SCHEMA IF EXISTS silver CASCADE;
CREATE SCHEMA silver;


-- =========================================================
-- 1) CREATE CLEAN DIMENSION TABLES
-- =========================================================

CREATE TABLE silver.dim_departments (
    department_id   INT PRIMARY KEY,
    department_name TEXT NOT NULL,
    business_unit   TEXT,
    department_head TEXT,
    region          TEXT,
    active_flag     BOOLEAN
);

CREATE TABLE silver.dim_job_roles (
    job_role_id         INT PRIMARY KEY,
    job_title           TEXT NOT NULL,
    job_level           TEXT,
    department_id       INT,
    role_family         TEXT,
    salary_band_min_usd NUMERIC(12,2),
    salary_band_max_usd NUMERIC(12,2)
);

CREATE TABLE silver.dim_employees (
    employee_id     INT PRIMARY KEY,
    first_name      TEXT,
    last_name       TEXT,
    gender          TEXT,
    date_of_birth   DATE,
    hire_date       DATE,
    department_id   INT,
    job_role_id     INT,
    manager_id      INT,
    employment_type TEXT,
    LOCATION        TEXT,
    marital_status  TEXT,
    education_level TEXT,
    remote_status   TEXT,
    full_name       TEXT,
    age             INT,
    age_group       TEXT,
    department_name TEXT,
    job_title       TEXT,
    employee_status TEXT
);


-- =========================================================
-- 2) CREATE CLEAN FACT TABLES
-- =========================================================

-- Pay frequency normalization note:
-- Investigation of salary_amount distributions confirmed that all pay_frequency
-- groups (Annual, Monthly, Biweekly) carry salary_amount on the same scale
-- (annual-equivalent in local currency). pay_frequency describes payroll delivery
-- cadence, not the period unit of salary_amount.
-- The cleaning notebook normalizes Biweekly -> Annual to make this explicit.
-- salary_amount_usd and annual_salary_usd are therefore both annual-equivalent USD.
-- annual_salary_usd is used as the primary field in all analysis queries.
CREATE TABLE silver.fact_salaries (
    salary_id            INT PRIMARY KEY,
    employee_id          INT NOT NULL,
    salary_amount        NUMERIC(12,2),
    currency             TEXT,
    effective_date       DATE,
    bonus_amount         NUMERIC(12,2),
    pay_frequency        TEXT,
    exchange_rate_to_usd NUMERIC(10,4),
    salary_amount_usd    NUMERIC(12,2),
    annual_salary_usd    NUMERIC(12,2),  -- explicit annual-equivalent alias; primary field for analysis
    bonus_amount_usd     NUMERIC(12,2),
    salary_band          TEXT
);

CREATE TABLE silver.fact_performance_reviews (
    review_id             INT PRIMARY KEY,
    employee_id           INT NOT NULL,
    review_date           DATE,
    performance_score     NUMERIC(4,2),
    manager_score         NUMERIC(4,2),
    goals_met_percentage  NUMERIC(5,2),
    promotion_recommended BOOLEAN,
    reviewer_id           INT,
    performance_category  TEXT
);

CREATE TABLE silver.fact_satisfaction_surveys (
    survey_id                       INT PRIMARY KEY,
    employee_id                     INT NOT NULL,
    survey_date                     DATE,
    satisfaction_score              NUMERIC(4,2),
    engagement_score                NUMERIC(4,2),
    work_life_balance_score         NUMERIC(4,2),
    manager_relationship_score      NUMERIC(4,2),
    career_growth_score             NUMERIC(4,2),
    compensation_satisfaction_score NUMERIC(4,2),
    overall_satisfaction_score      NUMERIC(4,2),
    satisfaction_category           TEXT
);

CREATE TABLE silver.fact_training_records (
    training_id       INT PRIMARY KEY,
    employee_id       INT NOT NULL,
    program_name      TEXT,
    training_category TEXT,
    start_date        DATE,
    completion_date   DATE,
    completion_status TEXT,
    training_score    NUMERIC(5,2),
    training_hours    NUMERIC(6,2),
    completed_flag    BOOLEAN
);

CREATE TABLE silver.fact_attendance (
    attendance_id     INT PRIMARY KEY,
    employee_id       INT NOT NULL,
    attendance_date   DATE,
    scheduled_hours   NUMERIC(5,2),
    worked_hours      NUMERIC(5,2),
    absence_flag      BOOLEAN,
    absence_type      TEXT,
    late_minutes      NUMERIC(8,2),
    absence_day_count INT,
    missed_hours      NUMERIC(5,2)
);

CREATE TABLE silver.fact_attrition_exit_interviews (
    exit_id              INT PRIMARY KEY,
    employee_id          INT NOT NULL,
    exit_date            DATE,
    exit_type            TEXT,
    exit_reason          TEXT,
    rehire_eligible      BOOLEAN,
    exit_interview_score NUMERIC(4,2),
    COMMENTS             TEXT
);

CREATE TABLE silver.fact_department_history (
    history_id    INT PRIMARY KEY,
    employee_id   INT NOT NULL,
    department_id INT,
    job_role_id   INT,
    start_date    DATE,
    end_date      DATE,
    change_reason TEXT
);


-- =========================================================
-- 3) IMPORT CLEAN CSV FILES
-- Valentina Studio / pgAdmin version uses COPY.
-- If COPY fails because of permissions, use psql with \copy instead.
-- =========================================================

COPY silver.dim_departments
FROM 'D:/hr_analytics_project/data/clean/dim_departments.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.dim_job_roles
FROM 'D:/hr_analytics_project/data/clean/dim_job_roles.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.dim_employees
FROM 'D:/hr_analytics_project/data/clean/dim_employees.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.fact_salaries
FROM 'D:/hr_analytics_project/data/clean/fact_salaries.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.fact_performance_reviews
FROM 'D:/hr_analytics_project/data/clean/fact_performance_reviews.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.fact_satisfaction_surveys
FROM 'D:/hr_analytics_project/data/clean/fact_satisfaction_surveys.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.fact_training_records
FROM 'D:/hr_analytics_project/data/clean/fact_training_records.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.fact_attendance
FROM 'D:/hr_analytics_project/data/clean/fact_attendance.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.fact_attrition_exit_interviews
FROM 'D:/hr_analytics_project/data/clean/fact_attrition_exit_interviews.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');

COPY silver.fact_department_history
FROM 'D:/hr_analytics_project/data/clean/fact_department_history.csv'
WITH (FORMAT CSV, HEADER TRUE, NULL '', ENCODING 'UTF8');
UPDATE silver.fact_salaries
SET annual_salary_usd = salary_amount_usd;
-- =========================================================
-- 4) ADD FOREIGN KEY RELATIONSHIPS
-- Added after import and post-import fixes.
-- =========================================================

ALTER TABLE silver.dim_job_roles
ADD CONSTRAINT fk_job_roles_department
FOREIGN KEY (department_id)
REFERENCES silver.dim_departments(department_id);

ALTER TABLE silver.dim_employees
ADD CONSTRAINT fk_employees_department
FOREIGN KEY (department_id)
REFERENCES silver.dim_departments(department_id);

ALTER TABLE silver.dim_employees
ADD CONSTRAINT fk_employees_job_role
FOREIGN KEY (job_role_id)
REFERENCES silver.dim_job_roles(job_role_id);

ALTER TABLE silver.fact_salaries
ADD CONSTRAINT fk_salaries_employee
FOREIGN KEY (employee_id)
REFERENCES silver.dim_employees(employee_id);

ALTER TABLE silver.fact_performance_reviews
ADD CONSTRAINT fk_performance_employee
FOREIGN KEY (employee_id)
REFERENCES silver.dim_employees(employee_id);

ALTER TABLE silver.fact_satisfaction_surveys
ADD CONSTRAINT fk_satisfaction_employee
FOREIGN KEY (employee_id)
REFERENCES silver.dim_employees(employee_id);

ALTER TABLE silver.fact_training_records
ADD CONSTRAINT fk_training_employee
FOREIGN KEY (employee_id)
REFERENCES silver.dim_employees(employee_id);

ALTER TABLE silver.fact_attendance
ADD CONSTRAINT fk_attendance_employee
FOREIGN KEY (employee_id)
REFERENCES silver.dim_employees(employee_id);

ALTER TABLE silver.fact_attrition_exit_interviews
ADD CONSTRAINT fk_attrition_employee
FOREIGN KEY (employee_id)
REFERENCES silver.dim_employees(employee_id);

ALTER TABLE silver.fact_department_history
ADD CONSTRAINT fk_department_history_employee
FOREIGN KEY (employee_id)
REFERENCES silver.dim_employees(employee_id);

ALTER TABLE silver.fact_department_history
ADD CONSTRAINT fk_department_history_department
FOREIGN KEY (department_id)
REFERENCES silver.dim_departments(department_id);

ALTER TABLE silver.fact_department_history
ADD CONSTRAINT fk_department_history_job_role
FOREIGN KEY (job_role_id)
REFERENCES silver.dim_job_roles(job_role_id);


-- =========================================================
-- 5) CREATE INDEXES
-- =========================================================

CREATE INDEX idx_employees_department_id ON silver.dim_employees(department_id);
CREATE INDEX idx_employees_job_role_id ON silver.dim_employees(job_role_id);
CREATE INDEX idx_employees_status ON silver.dim_employees(employee_status);
CREATE INDEX idx_salaries_employee_id ON silver.fact_salaries(employee_id);
CREATE INDEX idx_salaries_effective_date ON silver.fact_salaries(effective_date);
CREATE INDEX idx_performance_employee_id ON silver.fact_performance_reviews(employee_id);
CREATE INDEX idx_performance_review_date ON silver.fact_performance_reviews(review_date);
CREATE INDEX idx_satisfaction_employee_id ON silver.fact_satisfaction_surveys(employee_id);
CREATE INDEX idx_satisfaction_survey_date ON silver.fact_satisfaction_surveys(survey_date);
CREATE INDEX idx_training_employee_id ON silver.fact_training_records(employee_id);
CREATE INDEX idx_training_start_date ON silver.fact_training_records(start_date);
CREATE INDEX idx_attendance_employee_id ON silver.fact_attendance(employee_id);
CREATE INDEX idx_attendance_date ON silver.fact_attendance(attendance_date);
CREATE INDEX idx_attrition_employee_id ON silver.fact_attrition_exit_interviews(employee_id);
CREATE INDEX idx_attrition_exit_date ON silver.fact_attrition_exit_interviews(exit_date);
CREATE INDEX idx_department_history_employee_id ON silver.fact_department_history(employee_id);


-- =========================================================
-- 6) FINAL VALIDATION CHECKS
-- Run these before starting business analysis.
-- =========================================================

-- 6.1) Row count checks
SELECT 'silver.dim_departments' AS table_name, COUNT(*) AS row_count FROM silver.dim_departments
UNION ALL
SELECT 'silver.dim_job_roles', COUNT(*) FROM silver.dim_job_roles
UNION ALL
SELECT 'silver.dim_employees', COUNT(*) FROM silver.dim_employees
UNION ALL
SELECT 'silver.fact_salaries', COUNT(*) FROM silver.fact_salaries
UNION ALL
SELECT 'silver.fact_performance_reviews', COUNT(*) FROM silver.fact_performance_reviews
UNION ALL
SELECT 'silver.fact_satisfaction_surveys', COUNT(*) FROM silver.fact_satisfaction_surveys
UNION ALL
SELECT 'silver.fact_training_records', COUNT(*) FROM silver.fact_training_records
UNION ALL
SELECT 'silver.fact_attendance', COUNT(*) FROM silver.fact_attendance
UNION ALL
SELECT 'silver.fact_attrition_exit_interviews', COUNT(*) FROM silver.fact_attrition_exit_interviews
UNION ALL
SELECT 'silver.fact_department_history', COUNT(*) FROM silver.fact_department_history
ORDER BY table_name;


-- 6.2) Duplicate primary key checks
-- Expected: all duplicate_count values should be 0.
SELECT 'dim_departments.department_id' AS check_name, COUNT(*) AS duplicate_count
FROM (SELECT department_id FROM silver.dim_departments GROUP BY department_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_job_roles.job_role_id', COUNT(*)
FROM (SELECT job_role_id FROM silver.dim_job_roles GROUP BY job_role_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'dim_employees.employee_id', COUNT(*)
FROM (SELECT employee_id FROM silver.dim_employees GROUP BY employee_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_salaries.salary_id', COUNT(*)
FROM (SELECT salary_id FROM silver.fact_salaries GROUP BY salary_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_performance_reviews.review_id', COUNT(*)
FROM (SELECT review_id FROM silver.fact_performance_reviews GROUP BY review_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_satisfaction_surveys.survey_id', COUNT(*)
FROM (SELECT survey_id FROM silver.fact_satisfaction_surveys GROUP BY survey_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_training_records.training_id', COUNT(*)
FROM (SELECT training_id FROM silver.fact_training_records GROUP BY training_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_attendance.attendance_id', COUNT(*)
FROM (SELECT attendance_id FROM silver.fact_attendance GROUP BY attendance_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_attrition_exit_interviews.exit_id', COUNT(*)
FROM (SELECT exit_id FROM silver.fact_attrition_exit_interviews GROUP BY exit_id HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'fact_department_history.history_id', COUNT(*)
FROM (SELECT history_id FROM silver.fact_department_history GROUP BY history_id HAVING COUNT(*) > 1) x;


-- 6.3) Department match check
-- Expected: 0 rows.
SELECT
    e.department_id,
    e.department_name,
    COUNT(*) AS employees
FROM silver.dim_employees e
LEFT JOIN silver.dim_departments d
    ON e.department_id = d.department_id
WHERE d.department_id IS NULL
GROUP BY e.department_id, e.department_name
ORDER BY employees DESC;


-- 6.4) Job role match check
-- Expected: 0 rows.
SELECT
    e.department_name,
    e.job_title,
    COUNT(*) AS employees
FROM silver.dim_employees e
LEFT JOIN silver.dim_job_roles j
    ON e.job_role_id = j.job_role_id
WHERE j.job_role_id IS NULL
GROUP BY e.department_name, e.job_title
ORDER BY employees DESC;


-- 6.5) Employee status check
SELECT
    employee_status,
    COUNT(*) AS employee_count
FROM silver.dim_employees
GROUP BY employee_status
ORDER BY employee_count DESC;


-- 6.6) Attrition record check
SELECT
    COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') AS employees_marked_left,
    COUNT(DISTINCT x.employee_id) AS employees_with_exit_records
FROM silver.dim_employees e
LEFT JOIN silver.fact_attrition_exit_interviews x
    ON e.employee_id = x.employee_id;

-- 6.7) Salary quality check
-- Validates salary_amount_usd and annual_salary_usd per pay_frequency group.
-- After normalization, avg_annual_salary_usd should be similar across all groups
-- (confirming salary_amount stores annual-equivalent regardless of frequency label).
-- If Biweekly avg is ~26x or ~12x higher than Annual avg, normalization is broken.
SELECT
    pay_frequency,
    COUNT(*) AS salary_records,
    COUNT(*) FILTER (WHERE annual_salary_usd IS NULL) AS missing_annual_salary_usd,
    ROUND(MIN(annual_salary_usd), 2) AS min_annual_salary_usd,
    ROUND(AVG(annual_salary_usd), 2) AS avg_annual_salary_usd,
    ROUND(MAX(annual_salary_usd), 2) AS max_annual_salary_usd
FROM silver.fact_salaries
GROUP BY pay_frequency
ORDER BY pay_frequency;
-- Expected: avg_annual_salary_usd should be ~$30K-$65K across ALL pay_frequency groups.


-- 6.8) Performance score quality check
SELECT
    COUNT(*) AS review_records,
    COUNT(*) FILTER (WHERE performance_score IS NULL) AS missing_performance_score,
    MIN(performance_score) AS min_performance_score,
    ROUND(AVG(performance_score), 2) AS avg_performance_score,
    MAX(performance_score) AS max_performance_score
FROM silver.fact_performance_reviews;


-- 6.9) Satisfaction score quality check
SELECT
    COUNT(*) AS survey_records,
    COUNT(*) FILTER (WHERE satisfaction_score IS NULL) AS missing_satisfaction_score,
    MIN(satisfaction_score) AS min_satisfaction_score,
    ROUND(AVG(satisfaction_score), 2) AS avg_satisfaction_score,
    MAX(satisfaction_score) AS max_satisfaction_score
FROM silver.fact_satisfaction_surveys;


-- 6.10) Training quality check
SELECT
    completion_status,
    COUNT(*) AS training_records,
    ROUND(AVG(training_score), 2) AS avg_training_score,
    ROUND(AVG(training_hours), 2) AS avg_training_hours
FROM silver.fact_training_records
GROUP BY completion_status
ORDER BY training_records DESC;


-- 6.11) Attendance quality check
SELECT
    COUNT(*) AS attendance_records,
    COUNT(*) FILTER (WHERE attendance_date IS NULL) AS missing_attendance_dates,
    SUM(absence_day_count) AS total_absence_days,
    ROUND(AVG(late_minutes), 2) AS avg_late_minutes,
    ROUND(SUM(missed_hours), 2) AS total_missed_hours
FROM silver.fact_attendance;


-- 6.12) First business readiness test
SELECT
    d.department_id,
    d.department_name,
    COUNT(DISTINCT e.employee_id) AS total_employees,
    COUNT(DISTINCT x.employee_id) AS employees_left,
    ROUND(COUNT(DISTINCT x.employee_id)::NUMERIC/ NULLIF(COUNT(DISTINCT e.employee_id), 0) * 100, 2) AS attrition_rate_pct
FROM silver.dim_employees e
LEFT JOIN silver.dim_departments d
    ON e.department_id = d.department_id
LEFT JOIN silver.fact_attrition_exit_interviews x
    ON e.employee_id = x.employee_id
GROUP BY d.department_id, d.department_name
ORDER BY attrition_rate_pct DESC;
