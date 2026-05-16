-- =========================================================
-- HR WORKFORCE ATTRITION & RETENTION ANALYSIS
-- 02_HR_BUSINESS_ANALYSIS.SQL
-- PostgreSQL · Silver Layer
-- =========================================================

-- =========================================================
-- SALARY NORMALIZATION NOTE (applies to all salary queries)
-- =========================================================
-- The raw data contains four pay_frequency labels: Annual, Yearly, Monthly, Biweekly.
-- Investigation confirmed that salary_amount stores the annual-equivalent value
-- regardless of the pay_frequency label — medians are nearly identical across all
-- frequency groups (~$33K-$37K). pay_frequency is a payroll delivery cadence label,
-- not a unit multiplier for salary_amount.
--
-- The cleaning notebook normalizes all labels to Annual / Monthly / Hourly,
-- mapping Biweekly -> Annual. annual_salary_usd is the explicit primary field
-- used throughout this file (same value as salary_amount_usd, clearer intent).
--
-- If this were a live payroll system storing per-period pay amounts, the fix would be:
--   annual_salary_usd = salary_amount_usd * CASE pay_frequency
--                           WHEN 'Biweekly' THEN 26
--                           WHEN 'Monthly'  THEN 12
--                           ELSE 1 END
-- =========================================================


-- =========================================================
-- SECTION 1 — WORKFORCE OVERVIEW
-- =========================================================


-- =========================================================
-- Q1. What is the current workforce snapshot?
-- Business purpose:
-- Establish the baseline number of employees, active employees,
-- left employees, attrition rate, and retention rate.
-- =========================================================

SELECT
    COUNT(DISTINCT employee_id) AS total_employees,
    COUNT(DISTINCT employee_id) FILTER (WHERE employee_status = 'Active') AS active_employees,
    COUNT(DISTINCT employee_id) FILTER (WHERE employee_status = 'Left') AS left_employees,
    ROUND(COUNT(DISTINCT employee_id) FILTER (WHERE employee_status = 'Active') * 100.0 / COUNT(DISTINCT employee_id), 2) AS retention_rate_pct,
    ROUND(COUNT(DISTINCT employee_id) FILTER (WHERE employee_status = 'Left') * 100.0 / COUNT(DISTINCT employee_id), 2) AS attrition_rate_pct
FROM silver.dim_employees;

/*
Insight:
The company has 1,850 employees. 1,496 are active and 354 have left,
resulting in an 80.86% retention rate and a 19.14% attrition rate.

This shows that attrition is a meaningful HR issue. Nearly 1 in every 5 employees
has left the company, so leadership should investigate which departments, roles,
and employee groups are driving turnover.
*/


-- =========================================================
-- Q2. How has hiring and termination changed over time?
-- Business purpose:
-- Understand whether the company is growing, shrinking,
-- or replacing employees due to turnover.
-- Note:
-- Final reporting filters out the historical 1900 row because it appears
-- to be a data-quality artifact.
-- =========================================================

WITH hires AS (
    SELECT
        EXTRACT(YEAR FROM hire_date)::INT AS YEAR,
        COUNT(DISTINCT employee_id) AS hires
    FROM silver.dim_employees
    WHERE hire_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM hire_date)
),

terminations AS (
    SELECT
        EXTRACT(YEAR FROM exit_date)::INT AS YEAR,
        COUNT(DISTINCT employee_id) AS terminations
    FROM silver.fact_attrition_exit_interviews
    WHERE exit_date IS NOT NULL
    GROUP BY EXTRACT(YEAR FROM exit_date)
)

SELECT
    COALESCE(h.year, t.year) AS YEAR,
    COALESCE(h.hires, 0) AS hires,
    COALESCE(t.terminations, 0) AS terminations,
    COALESCE(h.hires, 0) - COALESCE(t.terminations, 0) AS net_headcount_change
FROM hires h
FULL JOIN terminations t
    ON h.year = t.year
WHERE COALESCE(h.year, t.year) BETWEEN 2014 AND 2026
ORDER BY YEAR;

/*
Insight:
The company showed strong workforce growth from 2014 to 2024, with hires consistently
higher than terminations. However, terminations increased noticeably in recent years,
especially in 2023, 2024, and 2025.

In 2025, the company hired 146 employees but lost 88 employees, reducing net growth
to only 58 employees. In 2026, the trend became negative, with 28 hires and 54
terminations, creating a net headcount change of -26.

This suggests that retention pressure has increased recently. HR should investigate
whether the rise in exits is linked to compensation, workload, career growth,
manager relationships, or department-specific issues.
*/


-- =========================================================
-- SECTION 2 — ATTRITION DRIVERS
-- =========================================================


-- =========================================================
-- Q3. Which departments have the highest attrition rate?
-- Business purpose:
-- Identify departments with the biggest retention problems
-- so HR can prioritize intervention.
-- =========================================================

SELECT
    d.department_name,
    COUNT(DISTINCT e.employee_id) AS total_employees,
    COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') AS employees_left,
    ROUND(COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') * 100.0 / NULLIF(COUNT(DISTINCT e.employee_id), 0), 2) AS attrition_rate_pct
FROM silver.dim_employees e
JOIN silver.dim_departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY attrition_rate_pct DESC;

/*
Insight:
Customer Support has the highest attrition rate at 29.20%, with 153 employees leaving
out of 524 total employees. Sales is the second-highest department at 22.18%,
followed by Operations at 18.78%.

These three departments should be the first priority for HR intervention because
they combine high attrition with meaningful employee volume. Customer Support is
especially important because it has both the largest headcount and the highest
attrition rate.

Data & Analytics has the lowest attrition rate at 6.45%, which makes it a potential
positive benchmark for retention practices.

Recommendation:
Prioritize retention programs in Customer Support, Sales, and Operations.
HR should review workload, manager effectiveness, compensation competitiveness,
and career progression in these departments.
*/


-- =========================================================
-- Q4. Which job roles are most affected by attrition?
-- Business purpose:
-- Identify specific roles where employee turnover is concentrated.
-- This helps HR design targeted retention actions.
-- =========================================================

SELECT
    d.department_name,
    j.job_title,
    j.job_level,
    COUNT(DISTINCT e.employee_id) AS total_employees,
    COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') AS employees_left,
    ROUND(COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') * 100.0 / NULLIF(COUNT(DISTINCT e.employee_id), 0), 2) AS attrition_rate_pct
FROM silver.dim_employees e
JOIN silver.dim_departments d
    ON e.department_id = d.department_id
JOIN silver.dim_job_roles j
    ON e.job_role_id = j.job_role_id
GROUP BY d.department_name, j.job_title, j.job_level
HAVING COUNT(DISTINCT e.employee_id) >= 10
ORDER BY attrition_rate_pct DESC;

/*
Insight:
Attrition is highly concentrated in customer-facing and operational roles.

The highest attrition rates are:
- Senior Support Specialist: 31.15%
- Support Team Lead: 29.69%
- Customer Support Associate: 29.25%
- Sales Representative: 26.17%
- Operations Coordinator: 25.32%

Customer Support Associate is the most important role to investigate because it has
both a high attrition rate and a very large employee base: 105 employees left out
of 359. This means the role is not only high-risk by percentage, but also high-impact
in terms of total employee loss.

This suggests that frontline support and sales roles may be facing pressure from
workload, compensation, career growth, or manager-related issues.

Recommendation:
Create targeted retention actions for Customer Support and Sales roles, especially
Customer Support Associates, Senior Support Specialists, Support Team Leads, and
Sales Representatives. HR should investigate workload, promotion paths, manager
support, and salary competitiveness for these roles.
*/


-- =========================================================
-- Q5. Is attrition mostly voluntary or involuntary?
-- Business purpose:
-- Understand whether turnover is mainly a retention problem
-- or a performance/workforce management problem.
-- =========================================================

SELECT
    exit_type,
    COUNT(DISTINCT employee_id) AS exit_count,
    ROUND(COUNT(DISTINCT employee_id) * 100.0 / SUM(COUNT(DISTINCT employee_id)) OVER (), 2) AS exit_pct
FROM silver.fact_attrition_exit_interviews
GROUP BY exit_type
ORDER BY exit_count DESC;

/*
Insight:
Attrition is mostly voluntary. Out of 354 exits, 319 were voluntary,
representing 90.11% of all exits. Only 35 exits were involuntary, representing 9.89%.

This means the company’s attrition problem is mainly a retention issue, not primarily
a performance termination issue. HR should focus on why employees choose to leave,
especially compensation, career growth, workload, and manager-related factors.
*/


-- =========================================================
-- Q6. What are the top exit reasons?
-- Business purpose:
-- Identify why employees are leaving so HR can focus on
-- the most actionable root causes.
-- =========================================================

SELECT
    exit_reason,
    COUNT(DISTINCT employee_id) AS exit_count,
    ROUND(COUNT(DISTINCT employee_id) * 100.0 / SUM(COUNT(DISTINCT employee_id)) OVER (), 2) AS exit_pct
FROM silver.fact_attrition_exit_interviews
GROUP BY exit_reason
ORDER BY exit_count DESC;

/*
Insight:
The top exit reasons are Better Compensation, Career Growth, Personal Reasons,
Workload, and Manager Relationship.

Better Compensation is the leading reason with 66 exits, representing 18.64% of all exits.
Career Growth follows closely with 65 exits, representing 18.36%.

Together, compensation and career growth account for 37.00% of exits.
When workload and manager relationship are added, these controllable HR factors explain
a large share of employee turnover.

This suggests that many exits may be preventable through better salary competitiveness,
clearer promotion paths, workload balancing, and manager effectiveness programs.
*/


-- =========================================================
-- SECTION 3 — TENURE AND EARLY ATTRITION
-- =========================================================


-- =========================================================
-- Q7. Which tenure groups have the highest attrition rate?
-- Business purpose:
-- Identify whether employees are leaving early in their journey,
-- especially within the first 0–2 years.
-- Fix:
-- Invalid date records where exit_date/reporting_date is before hire_date
-- are excluded from the analysis.
-- =========================================================

WITH exit_dates AS (
    SELECT
        employee_id,
        MAX(exit_date) AS exit_date
    FROM silver.fact_attrition_exit_interviews
    GROUP BY employee_id
),

employee_tenure AS (
    SELECT
        e.employee_id,
        ROUND(((COALESCE(x.exit_date, DATE '2026-05-01') - e.hire_date)::NUMERIC / 365.25), 2) AS tenure_years,

        CASE
            WHEN ((COALESCE(x.exit_date, DATE '2026-05-01') - e.hire_date)::NUMERIC / 365.25) < 1 THEN '< 1 Year'
            WHEN ((COALESCE(x.exit_date, DATE '2026-05-01') - e.hire_date)::NUMERIC / 365.25) < 2 THEN '1-2 Years'
            WHEN ((COALESCE(x.exit_date, DATE '2026-05-01') - e.hire_date)::NUMERIC / 365.25) < 5 THEN '2-5 Years'
            WHEN ((COALESCE(x.exit_date, DATE '2026-05-01') - e.hire_date)::NUMERIC / 365.25) < 10 THEN '5-10 Years'
            ELSE '10+ Years'
        END AS tenure_group,

        CASE
            WHEN x.employee_id IS NOT NULL THEN 1
            ELSE 0
        END AS attrition_flag

    FROM silver.dim_employees e
    LEFT JOIN exit_dates x
        ON e.employee_id = x.employee_id
    WHERE e.hire_date IS NOT NULL
      AND COALESCE(x.exit_date, DATE '2026-05-01') >= e.hire_date
)

SELECT
    tenure_group,
    COUNT(DISTINCT employee_id) AS total_employees,
    SUM(attrition_flag) AS employees_left,
    ROUND(SUM(attrition_flag) * 100.0 / NULLIF(COUNT(DISTINCT employee_id), 0), 2) AS attrition_rate_pct,
    ROUND(AVG(tenure_years), 2) AS avg_tenure_years
FROM employee_tenure
GROUP BY tenure_group
ORDER BY
    CASE tenure_group
        WHEN '< 1 Year' THEN 1
        WHEN '1-2 Years' THEN 2
        WHEN '2-5 Years' THEN 3
        WHEN '5-10 Years' THEN 4
        WHEN '10+ Years' THEN 5
    END;

/*
Insight:
Attrition is highest among employees with 1–2 years of tenure, where 92 out of 194
employees left, resulting in a 47.42% attrition rate. Employees with 2–5 years of tenure
also show elevated attrition at 27.51%, followed by employees with less than 1 year
at 25.66%.

This suggests the company has a major early-tenure retention problem. Employees are
most likely to leave before becoming long-tenured, especially between years 1 and 2.

Attrition drops sharply for employees with 5–10 years of tenure and 10+ years,
which shows that employees who stay beyond the early years are much more likely
to remain with the company.

Recommendation:
HR should focus retention actions on the first 24 months of employment. This could include
stronger onboarding, clearer career paths, manager check-ins, workload monitoring,
and early compensation reviews for new and developing employees.
*/


-- =========================================================
-- SECTION 4 — COMPENSATION AND FAIRNESS
-- =========================================================


-- =========================================================
-- Q8. Does attrition differ by salary band?
-- Business purpose:
-- Test whether lower-paid employees are more likely to leave.
-- Salary note:
-- Uses annual_salary_usd (annual-equivalent USD after currency conversion).
-- Salary bands: Low < $30K | Medium < $70K | High < $120K | Executive $120K+
-- =========================================================

WITH latest_salary AS (
    SELECT
        employee_id,
        annual_salary_usd,
        salary_band,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY effective_date DESC NULLS LAST, salary_id DESC
        ) AS rn
    FROM silver.fact_salaries
    WHERE annual_salary_usd IS NOT NULL
)

SELECT
    s.salary_band,
    COUNT(DISTINCT e.employee_id) AS total_employees,
    COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') AS employees_left,
    ROUND(COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') * 100.0 / NULLIF(COUNT(DISTINCT e.employee_id), 0), 2) AS attrition_rate_pct,
    ROUND(AVG(s.annual_salary_usd), 2) AS avg_annual_salary_usd
FROM silver.dim_employees e
JOIN latest_salary s
    ON e.employee_id = s.employee_id
   AND s.rn = 1
GROUP BY s.salary_band
ORDER BY attrition_rate_pct DESC;

/*
Insight:
Attrition is highest among employees in the Low salary band.

The Low salary band has the highest attrition rate at 25.57%.
This is significantly higher than the Medium salary band at 16.24%, the Executive band
at 13.13%, and the High salary band at 12.37%.

This suggests a clear relationship between lower compensation and higher attrition.
Salary competitiveness is likely one of the strongest retention drivers in this company,
which aligns with Better Compensation being the top exit reason.
*/


-- =========================================================
-- Q9. How does salary vary by department, gender, and role?
-- Business purpose:
-- Identify salary differences by department, gender, and official job role.
-- This supports compensation fairness review.
-- Fix:
-- Uses dim_job_roles.job_title as the official role title.
-- Uses annual_salary_usd (annual-equivalent USD) for all salary calculations.
-- =========================================================

WITH latest_salary AS (
    SELECT
        employee_id,
        annual_salary_usd,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY effective_date DESC NULLS LAST, salary_id DESC
        ) AS rn
    FROM silver.fact_salaries
    WHERE annual_salary_usd IS NOT NULL
)

SELECT
    d.department_name,
    j.job_title,
    COUNT(DISTINCT e.employee_id) AS employee_count,
    ROUND(AVG(s.annual_salary_usd), 2) AS avg_annual_salary_usd,
    ROUND(AVG(s.annual_salary_usd) FILTER (WHERE e.gender = 'Male'), 2) AS avg_male_salary_usd,
    ROUND(AVG(s.annual_salary_usd) FILTER (WHERE e.gender = 'Female'), 2) AS avg_female_salary_usd,
    ROUND(
        AVG(s.annual_salary_usd) FILTER (WHERE e.gender = 'Male')
        - AVG(s.annual_salary_usd) FILTER (WHERE e.gender = 'Female'),
        2
    ) AS gender_salary_gap_usd
FROM silver.dim_employees e
JOIN silver.dim_departments d
    ON e.department_id = d.department_id
JOIN silver.dim_job_roles j
    ON e.job_role_id = j.job_role_id
JOIN latest_salary s
    ON e.employee_id = s.employee_id
   AND s.rn = 1
GROUP BY d.department_name, j.job_title
HAVING COUNT(DISTINCT e.employee_id) >= 5
ORDER BY
    d.department_name,
    ABS(
        AVG(s.annual_salary_usd) FILTER (WHERE e.gender = 'Male')
        - AVG(s.annual_salary_usd) FILTER (WHERE e.gender = 'Female')
    ) DESC NULLS LAST;

/*
Insight:
Salary varies heavily by department and official job role. Technical, analytics, product,
and management roles generally show higher average salaries, while frontline
customer support and sales roles tend to sit at lower salary levels.

The gender salary gap also varies by role. Some roles show higher average male salary,
while others show higher average female salary. This means the result should be treated
as a compensation fairness flag, not proof of discrimination.

Because salary is affected by role, seniority, tenure, performance, and location,
HR should review the largest pay gaps after controlling for job level and experience.

Recommendation:
Use this analysis as a compensation audit starting point. Focus first on roles with
large salary gaps and enough employee count, then compare employees within the same
job level, department, tenure range, and performance category.
*/


-- =========================================================
-- Q10. How has salary progressed per employee over time?
-- Business purpose:
-- Analyze salary movement and identify employees with limited
-- salary growth over time.
-- Note: annual_salary_usd (annual-equivalent USD) used throughout.
-- =========================================================

WITH salary_progression AS (
    SELECT
        e.employee_id,
        d.department_name,
        j.job_title,
        s.effective_date,
        s.annual_salary_usd,
        LAG(s.annual_salary_usd) OVER (
            PARTITION BY e.employee_id
            ORDER BY s.effective_date
        ) AS previous_annual_salary_usd
    FROM silver.fact_salaries s
    JOIN silver.dim_employees e
        ON s.employee_id = e.employee_id
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    JOIN silver.dim_job_roles j
        ON e.job_role_id = j.job_role_id
    WHERE s.annual_salary_usd IS NOT NULL
      AND s.effective_date IS NOT NULL
)

SELECT
    employee_id,
    department_name,
    job_title,
    effective_date,
    annual_salary_usd,
    previous_annual_salary_usd,
    ROUND(annual_salary_usd - previous_annual_salary_usd, 2) AS salary_change_usd,
    ROUND((annual_salary_usd - previous_annual_salary_usd) / NULLIF(previous_annual_salary_usd, 0) * 100, 2) AS salary_change_pct
FROM salary_progression
WHERE previous_annual_salary_usd IS NOT NULL
ORDER BY employee_id, effective_date;

/*
Insight:
This query tracks salary progression for each employee over time using the LAG window function.
Because the result is employee-level and contains thousands of rows, it is best used as a
drill-through or supporting analysis rather than a main executive finding.

The main business value of this query is that it helps HR identify employees with limited
salary growth, salary freezes, or unusual salary changes. This becomes especially important
when combined with high performance, low compensation satisfaction, or high attrition-risk
departments.

Recommendation:
Use this analysis to flag employees who have strong performance but limited salary growth.
These employees may require compensation review, career progression planning, or retention
action before they become attrition risks.

Portfolio note:
This query demonstrates advanced SQL skills by using the LAG window function to compare
each salary record with the employee’s previous salary record.
*/


-- =========================================================
-- Q10 Summary. What is the typical salary growth by department?
-- Business purpose:
-- Summarize salary progression using median growth and remove extreme outliers.
-- Note: annual_salary_usd (annual-equivalent USD) used throughout.
-- =========================================================

WITH salary_progression AS (
    SELECT
        e.employee_id,
        d.department_name,
        s.effective_date,
        s.annual_salary_usd,
        LAG(s.annual_salary_usd) OVER (
            PARTITION BY e.employee_id
            ORDER BY s.effective_date
        ) AS previous_annual_salary_usd
    FROM silver.fact_salaries s
    JOIN silver.dim_employees e
        ON s.employee_id = e.employee_id
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    WHERE s.annual_salary_usd IS NOT NULL
      AND s.effective_date IS NOT NULL
),

salary_changes AS (
    SELECT
        employee_id,
        department_name,
        ROUND((annual_salary_usd - previous_annual_salary_usd) / NULLIF(previous_annual_salary_usd, 0) * 100, 2) AS salary_change_pct
    FROM salary_progression
    WHERE previous_annual_salary_usd IS NOT NULL
),

filtered_salary_changes AS (
    SELECT *
    FROM salary_changes
    WHERE salary_change_pct BETWEEN -30 AND 50
)

SELECT
    department_name,
    COUNT(*) AS salary_change_records,
    ROUND(AVG(salary_change_pct), 2) AS avg_salary_growth_pct,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary_change_pct)::NUMERIC, 2) AS median_salary_growth_pct,
    ROUND(MIN(salary_change_pct), 2) AS min_salary_growth_pct,
    ROUND(MAX(salary_change_pct), 2) AS max_salary_growth_pct
FROM filtered_salary_changes
GROUP BY department_name
ORDER BY median_salary_growth_pct DESC;

/*
Insight:
After filtering extreme salary-change outliers, typical salary growth appears relatively
consistent across departments.

Median salary growth ranges from 5.28% in Marketing to 6.37% in Product. Product has the
highest median salary growth at 6.37%, followed by Sales at 6.13%, Customer Support at 6.10%,
and Engineering at 6.03%.

The important business finding is that Customer Support still has high attrition despite
having a median salary growth rate of 6.10%, which is close to the company’s higher-growth
departments. This suggests that salary progression alone may not explain Customer Support
attrition. Other factors such as base salary level, workload, manager relationship,
career growth, or job stress may also be driving turnover.

Recommendation:
Use salary progression as a supporting retention metric, not as the only explanation for
attrition. HR should combine salary growth with base salary band, satisfaction, career growth,
and manager relationship scores when identifying employees or departments at risk.
*/


-- =========================================================
-- SECTION 5 — PERFORMANCE AND HIGH-VALUE TALENT
-- =========================================================


-- =========================================================
-- Q11. Are performance levels linked to attrition?
-- Business purpose:
-- Understand whether the company is losing low performers
-- or valuable high performers.
-- =========================================================

WITH latest_performance AS (
    SELECT
        employee_id,
        performance_score,
        performance_category,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY review_date DESC NULLS LAST, review_id DESC
        ) AS rn
    FROM silver.fact_performance_reviews
)

SELECT
    p.performance_category,
    COUNT(DISTINCT e.employee_id) AS total_employees,
    COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') AS employees_left,
    ROUND(COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') * 100.0 / NULLIF(COUNT(DISTINCT e.employee_id), 0), 2) AS attrition_rate_pct,
    ROUND(AVG(p.performance_score), 2) AS avg_performance_score
FROM silver.dim_employees e
JOIN latest_performance p
    ON e.employee_id = p.employee_id
   AND p.rn = 1
WHERE performance_category <> 'Unknown' 
GROUP BY p.performance_category
ORDER BY attrition_rate_pct DESC;

/*
Insight:
High performers have the highest attrition rate at 33.78%. Out of 148 high performers,
50 have left the company. This is a serious talent retention risk.

This means attrition is not only concentrated among low performers. The company is
also losing valuable employees who likely contribute strongly to business outcomes.

Low performers also show elevated attrition at 19.42%, but the biggest concern is
high-performer attrition because losing top talent can damage productivity,
team performance, customer experience, and leadership pipeline strength.

Recommendation:
HR should prioritize high-performer retention through compensation reviews,
career progression plans, manager check-ins, recognition programs, and workload review.
*/


-- =========================================================
-- Q12. Which high performers are at retention risk?
-- Business purpose:
-- Identify active high performers who may leave due to low satisfaction,
-- weak manager relationship, low compensation satisfaction, below-median salary,
-- or limited salary growth.
-- Note:
-- Employee names are excluded from the final output to keep the analysis portfolio-safe.
-- =========================================================

WITH latest_performance AS (
    SELECT
        employee_id,
        performance_score,
        performance_category,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY review_date DESC NULLS LAST, review_id DESC
        ) AS rn
    FROM silver.fact_performance_reviews
),

latest_satisfaction AS (
    SELECT
        employee_id,
        satisfaction_score,
        manager_relationship_score,
        compensation_satisfaction_score,
        career_growth_score,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY survey_date DESC NULLS LAST, survey_id DESC
        ) AS rn
    FROM silver.fact_satisfaction_surveys
),

salary_progression AS (
    SELECT
        employee_id,
        annual_salary_usd,
        salary_band,
        effective_date,
        LAG(annual_salary_usd) OVER (
            PARTITION BY employee_id
            ORDER BY effective_date
        ) AS previous_annual_salary_usd,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY effective_date DESC NULLS LAST, salary_id DESC
        ) AS rn
    FROM silver.fact_salaries
    WHERE annual_salary_usd IS NOT NULL
),

latest_salary AS (
    SELECT
        employee_id,
        annual_salary_usd,
        salary_band,
        ROUND((annual_salary_usd - previous_annual_salary_usd) / NULLIF(previous_annual_salary_usd, 0) * 100, 2) AS latest_salary_growth_pct
    FROM salary_progression
    WHERE rn = 1
),

department_salary_median AS (
    SELECT
        e.department_id,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY s.annual_salary_usd) AS department_median_salary
    FROM silver.dim_employees e
    JOIN latest_salary s
        ON e.employee_id = s.employee_id
    GROUP BY e.department_id
),

risk_base AS (
    SELECT
        e.employee_id,
        d.department_name,
        j.job_title,
        p.performance_score,
        p.performance_category,
        s.annual_salary_usd,
        s.salary_band,
        ROUND(dsm.department_median_salary::NUMERIC, 2) AS department_median_salary,
        s.latest_salary_growth_pct,
        sat.satisfaction_score,
        sat.manager_relationship_score,
        sat.compensation_satisfaction_score,
        sat.career_growth_score,

        CASE WHEN sat.satisfaction_score <= 2 THEN 1 ELSE 0 END AS low_satisfaction_flag,
        CASE WHEN sat.manager_relationship_score <= 2 THEN 1 ELSE 0 END AS low_manager_score_flag,
        CASE WHEN sat.compensation_satisfaction_score <= 2 THEN 1 ELSE 0 END AS low_compensation_satisfaction_flag,
        CASE WHEN s.annual_salary_usd < dsm.department_median_salary THEN 1 ELSE 0 END AS below_department_median_salary_flag,
        CASE WHEN s.latest_salary_growth_pct IS NOT NULL AND s.latest_salary_growth_pct < 3 THEN 1 ELSE 0 END AS limited_salary_growth_flag

    FROM silver.dim_employees e
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    JOIN silver.dim_job_roles j
        ON e.job_role_id = j.job_role_id
    JOIN latest_performance p
        ON e.employee_id = p.employee_id
       AND p.rn = 1
    LEFT JOIN latest_salary s
        ON e.employee_id = s.employee_id
    LEFT JOIN latest_satisfaction sat
        ON e.employee_id = sat.employee_id
       AND sat.rn = 1
    LEFT JOIN department_salary_median dsm
        ON e.department_id = dsm.department_id
    LEFT JOIN silver.fact_attrition_exit_interviews x
        ON e.employee_id = x.employee_id
    WHERE x.employee_id IS NULL
      AND p.performance_score >= 4.5
)

SELECT
    employee_id,
    department_name,
    job_title,
    performance_score,
    performance_category,
    annual_salary_usd,
    department_median_salary,
    latest_salary_growth_pct,
    satisfaction_score,
    manager_relationship_score,
    compensation_satisfaction_score,
    career_growth_score,

    (
        low_satisfaction_flag
        + low_manager_score_flag
        + low_compensation_satisfaction_flag
        + below_department_median_salary_flag
        + limited_salary_growth_flag
    ) AS retention_risk_score,

    CASE
        WHEN (
            low_satisfaction_flag
            + low_manager_score_flag
            + low_compensation_satisfaction_flag
            + below_department_median_salary_flag
            + limited_salary_growth_flag
        ) >= 3 THEN 'High Risk'

        WHEN (
            low_satisfaction_flag
            + low_manager_score_flag
            + low_compensation_satisfaction_flag
            + below_department_median_salary_flag
            + limited_salary_growth_flag
        ) = 2 THEN 'Medium Risk'

        WHEN (
            low_satisfaction_flag
            + low_manager_score_flag
            + low_compensation_satisfaction_flag
            + below_department_median_salary_flag
            + limited_salary_growth_flag
        ) = 1 THEN 'Low Risk'

        ELSE 'Low Concern'
    END AS retention_risk_level
FROM risk_base
ORDER BY retention_risk_score DESC, performance_score DESC;

/*
Insight:
Among 98 active high performers analyzed, 11 employees are classified as High Risk
and another 11 are classified as Medium Risk. This means 22 high-performing employees
may need retention attention.

The biggest risk drivers among high performers are:
- Below department median salary: 40 employees
- Limited salary growth: 21 employees
- Low compensation satisfaction: 20 employees
- Low manager relationship score: 16 employees
- Low overall satisfaction: 9 employees

Customer Support and IT Support have the highest number of high-risk high performers,
with 3 high-risk employees each. Sales also has 2 high-risk high performers.

This is important because the company is not only losing general employees; it also has
active high performers who show warning signs related to satisfaction, compensation,
manager relationship, below-median salary, or limited salary growth.

Recommendation:
HR should create a high-performer retention review process. The first priority should be
high performers with multiple risk factors, especially those in Customer Support, IT Support,
and Sales. Recommended actions include compensation review, manager check-ins, career growth
planning, workload review, and recognition plans.

Portfolio note:
This is one of the strongest advanced analyses in the project because it combines performance,
salary, salary growth, satisfaction, and retention risk into one employee-level risk model.
*/


-- =========================================================
-- SECTION 6 — EMPLOYEE EXPERIENCE, TRAINING, AND ABSENTEEISM
-- =========================================================


-- =========================================================
-- Q13. Do employees who left have lower satisfaction than active employees?
-- Business purpose:
-- Test whether satisfaction, engagement, manager relationship,
-- and compensation satisfaction are linked to retention.
-- =========================================================

WITH latest_satisfaction AS (
    SELECT
        employee_id,
        satisfaction_score,
        engagement_score,
        manager_relationship_score,
        compensation_satisfaction_score,
        career_growth_score,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY survey_date DESC NULLS LAST, survey_id DESC
        ) AS rn
    FROM silver.fact_satisfaction_surveys
)

SELECT
    CASE
        WHEN e.employee_status = 'Left' THEN 'Left Employees'
        ELSE 'Active Employees'
    END AS employee_group,
    COUNT(DISTINCT e.employee_id) AS employee_count,
    ROUND(AVG(s.satisfaction_score), 2) AS avg_satisfaction_score,
    ROUND(AVG(s.engagement_score), 2) AS avg_engagement_score,
    ROUND(AVG(s.manager_relationship_score), 2) AS avg_manager_relationship_score,
    ROUND(AVG(s.compensation_satisfaction_score), 2) AS avg_compensation_satisfaction_score,
    ROUND(AVG(s.career_growth_score), 2) AS avg_career_growth_score
FROM silver.dim_employees e
JOIN latest_satisfaction s
    ON e.employee_id = s.employee_id
   AND s.rn = 1
GROUP BY employee_group
ORDER BY employee_group;

/*
Insight:
Employees who left had lower satisfaction scores across every major employee experience
dimension.

Active employees had an average satisfaction score of 3.46, while left employees averaged
2.87. Left employees also had lower engagement, manager relationship, compensation
satisfaction, and career growth scores.

The biggest gaps appear in satisfaction, manager relationship, compensation satisfaction,
and career growth. This suggests attrition is linked to employee experience, not just
random turnover.

Recommendation:
HR should focus on improving manager effectiveness, compensation satisfaction,
career development, and engagement for employees in high-attrition departments.
*/


-- =========================================================
-- Q14A. Does training completion improve employee performance?
-- Business purpose:
-- Compare employee performance before and after training completion
-- for the same employees.
-- This gives a better view of training effectiveness than simply
-- comparing employees who completed training vs employees who did not.
-- =========================================================

WITH completed_training AS (
    SELECT
        employee_id,
        program_name,
        training_category,
        completion_date,

        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY completion_date
        ) AS rn

    FROM silver.fact_training_records

    WHERE completed_flag = TRUE
      AND completion_date IS NOT NULL
),

first_completed_training AS (
    SELECT
        employee_id,
        program_name,
        training_category,
        completion_date
    FROM completed_training
    WHERE rn = 1
),

performance_before AS (
    SELECT
        t.employee_id,
        p.review_date,
        p.performance_score,
        p.goals_met_percentage,

        ROW_NUMBER() OVER (
            PARTITION BY t.employee_id
            ORDER BY p.review_date DESC
        ) AS rn

    FROM first_completed_training t
    JOIN silver.fact_performance_reviews p
        ON t.employee_id = p.employee_id
       AND p.review_date < t.completion_date
),

performance_after AS (
    SELECT
        t.employee_id,
        p.review_date,
        p.performance_score,
        p.goals_met_percentage,

        ROW_NUMBER() OVER (
            PARTITION BY t.employee_id
            ORDER BY p.review_date ASC
        ) AS rn

    FROM first_completed_training t
    JOIN silver.fact_performance_reviews p
        ON t.employee_id = p.employee_id
       AND p.review_date > t.completion_date
),

training_impact AS (
    SELECT
        e.employee_id,
        d.department_name,
        e.job_title,
        t.program_name,
        t.training_category,
        t.completion_date,

        b.performance_score AS performance_before_training,
        a.performance_score AS performance_after_training,

        ROUND(
            a.performance_score - b.performance_score,
            2
        ) AS performance_score_change,

        b.goals_met_percentage AS goals_before_training,
        a.goals_met_percentage AS goals_after_training,

        ROUND(
            a.goals_met_percentage - b.goals_met_percentage,
            2
        ) AS goals_met_change

    FROM first_completed_training t
    JOIN silver.dim_employees e
        ON t.employee_id = e.employee_id
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    JOIN performance_before b
        ON t.employee_id = b.employee_id
       AND b.rn = 1
    JOIN performance_after a
        ON t.employee_id = a.employee_id
       AND a.rn = 1
)

SELECT
    training_category,
    COUNT(DISTINCT employee_id) AS employees_analyzed,

    ROUND(AVG(performance_before_training), 2) AS avg_performance_before,
    ROUND(AVG(performance_after_training), 2) AS avg_performance_after,
    ROUND(AVG(performance_score_change), 2) AS avg_performance_change,

    ROUND(AVG(goals_before_training), 2) AS avg_goals_before,
    ROUND(AVG(goals_after_training), 2) AS avg_goals_after,
    ROUND(AVG(goals_met_change), 2) AS avg_goals_change

FROM training_impact

GROUP BY training_category
ORDER BY avg_performance_change DESC;

/*
Insight:
The before-and-after training analysis shows that training impact varies by category.

Product training shows the strongest improvement. Employees who completed Product training
improved from an average performance score of 3.49 before training to 3.68 after training,
an increase of 0.19 points. Product training also had the highest goals-met improvement,
increasing by 5.54 percentage points.

Compliance and Onboarding also show small positive performance improvements, while Leadership
shows a slight performance increase but a small decline in goals-met percentage.

However, not all training categories appear effective. Soft Skills, Sales, Technical, and
Customer Experience training show negative average performance changes after completion.
Soft Skills has the largest decline, with performance decreasing by 0.25 points.

This means training effectiveness is not consistent across the company. Some programs may be
contributing to better outcomes, especially Product training, while others may need review.

Recommendation:
HR should investigate why Product training appears more effective and use it as a benchmark
for improving other programs. Training categories with negative performance change, especially
Soft Skills, Sales, and Technical training, should be reviewed for content quality, relevance,
timing, employee targeting, and manager follow-up after training.

Important limitation:
This analysis compares performance before and after training for the same employees, which is
stronger than comparing trained vs untrained employees. However, it does not prove causation.
Other factors may also affect performance changes, such as role changes, manager changes,
workload, or review timing.
*/


-- =========================================================
-- Q14B. Which training programs improve or decline after completion?
-- Business purpose:
-- Identify specific training programs that are associated with
-- performance improvement or decline after completion.
-- This helps HR decide which programs to keep, improve, or review.
-- =========================================================

WITH completed_training AS (
    SELECT
        employee_id,
        program_name,
        training_category,
        completion_date,

        ROW_NUMBER() OVER (
            PARTITION BY employee_id, program_name
            ORDER BY completion_date
        ) AS rn

    FROM silver.fact_training_records

    WHERE completed_flag = TRUE
      AND completion_date IS NOT NULL
),

first_completed_training AS (
    SELECT
        employee_id,
        program_name,
        training_category,
        completion_date
    FROM completed_training
    WHERE rn = 1
),

performance_before AS (
    SELECT
        t.employee_id,
        t.program_name,
        p.review_date,
        p.performance_score,
        p.goals_met_percentage,

        ROW_NUMBER() OVER (
            PARTITION BY t.employee_id, t.program_name
            ORDER BY p.review_date DESC
        ) AS rn

    FROM first_completed_training t
    JOIN silver.fact_performance_reviews p
        ON t.employee_id = p.employee_id
       AND p.review_date < t.completion_date
),

performance_after AS (
    SELECT
        t.employee_id,
        t.program_name,
        p.review_date,
        p.performance_score,
        p.goals_met_percentage,

        ROW_NUMBER() OVER (
            PARTITION BY t.employee_id, t.program_name
            ORDER BY p.review_date ASC
        ) AS rn

    FROM first_completed_training t
    JOIN silver.fact_performance_reviews p
        ON t.employee_id = p.employee_id
       AND p.review_date > t.completion_date
),

training_impact AS (
    SELECT
        t.employee_id,
        t.program_name,
        t.training_category,

        b.performance_score AS performance_before_training,
        a.performance_score AS performance_after_training,

        ROUND(
            a.performance_score - b.performance_score,
            2
        ) AS performance_score_change,

        b.goals_met_percentage AS goals_before_training,
        a.goals_met_percentage AS goals_after_training,

        ROUND(
            a.goals_met_percentage - b.goals_met_percentage,
            2
        ) AS goals_met_change

    FROM first_completed_training t
    JOIN performance_before b
        ON t.employee_id = b.employee_id
       AND t.program_name = b.program_name
       AND b.rn = 1
    JOIN performance_after a
        ON t.employee_id = a.employee_id
       AND t.program_name = a.program_name
       AND a.rn = 1
)

SELECT
    training_category,
    program_name,
    COUNT(DISTINCT employee_id) AS employees_analyzed,

    ROUND(AVG(performance_before_training), 2) AS avg_performance_before,
    ROUND(AVG(performance_after_training), 2) AS avg_performance_after,
    ROUND(AVG(performance_score_change), 2) AS avg_performance_change,

    ROUND(AVG(goals_before_training), 2) AS avg_goals_before,
    ROUND(AVG(goals_after_training), 2) AS avg_goals_after,
    ROUND(AVG(goals_met_change), 2) AS avg_goals_change,

    CASE
        WHEN AVG(performance_score_change) > 0 THEN 'Improved'
        WHEN AVG(performance_score_change) < 0 THEN 'Declined'
        ELSE 'No Change'
    END AS performance_impact_status

FROM training_impact

GROUP BY training_category, program_name

HAVING COUNT(DISTINCT employee_id) >= 5

ORDER BY avg_performance_change DESC;

/*
Insight:
At the program level, training impact is mixed. Some programs show small positive
performance improvements after completion, while others show performance decline.

The strongest improving programs are:
- Secure Coding Basics: +0.05 performance change and +3.32 goals-met change
- Manager Coaching Skills: +0.04 performance change and +3.18 goals-met change
- Product Discovery Basics: +0.03 performance change
- Power BI Fundamentals: +0.02 performance change and +1.88 goals-met change
- Data Privacy And GDPR: +0.02 performance change and +2.16 goals-met change

The weakest programs are:
- Conflict Resolution: -0.14 performance change and -1.51 goals-met change
- SQL For Business Analysts: -0.08 performance change and -1.70 goals-met change
- Leadership Essentials: -0.05 performance change
- Advanced Customer Handling: -0.04 performance change

This suggests that training effectiveness differs by program. Technical and product-related
programs show some positive movement, while soft skills, leadership, and some customer-facing
programs may need review.

Recommendation:
HR should not evaluate training only by completion rate. Programs should be reviewed based on
post-training performance movement. Programs with positive results can be used as benchmarks,
while declining programs should be reviewed for content quality, employee targeting, timing,
and manager follow-up.

Important limitation:
The performance changes are small, so this should be treated as a directional signal rather
than proof that training directly caused the change.
*/


-- =========================================================
-- Q15. Do employees with higher absenteeism leave more often?
-- Business purpose:
-- Test whether absenteeism is an early warning sign for attrition,
-- burnout, or disengagement.
-- =========================================================

WITH employee_attendance AS (
    SELECT
        employee_id,
        COUNT(attendance_id) AS attendance_records,
        SUM(absence_day_count) AS absence_days,
        ROUND(AVG(late_minutes), 2) AS avg_late_minutes,
        ROUND(SUM(missed_hours), 2) AS total_missed_hours
    FROM silver.fact_attendance
    GROUP BY employee_id
)

SELECT
    CASE
        WHEN e.employee_status = 'Left' THEN 'Left Employees'
        ELSE 'Active Employees'
    END AS employee_group,
    COUNT(DISTINCT e.employee_id) AS employee_count,
    ROUND(AVG(a.absence_days), 2) AS avg_absence_days,
    ROUND(AVG(a.avg_late_minutes), 2) AS avg_late_minutes,
    ROUND(AVG(a.total_missed_hours), 2) AS avg_missed_hours
FROM silver.dim_employees e
JOIN employee_attendance a
    ON e.employee_id = a.employee_id
GROUP BY employee_group
ORDER BY employee_group;

/*
Insight:
Absenteeism does not appear to be a strong warning sign for attrition in this dataset.

Active employees had slightly higher average absence days and missed hours than left
employees. Active employees averaged 1.40 absence days and 18.69 missed hours, while
left employees averaged 1.18 absence days and 13.58 missed hours.

This suggests absenteeism is not a major driver of turnover in the current data.

Important limitation:
Only 91 left employees appear in the attendance comparison, while the full attrition
population is 354 employees. This means attendance coverage for former employees may
be incomplete, so this finding should be treated carefully.

Recommendation:
Do not prioritize absenteeism as the main attrition driver. Focus more on compensation,
career growth, satisfaction, manager relationship, and high-risk departments.
*/


-- =========================================================
-- SECTION 7 — HR ACTION PRIORITY
-- =========================================================


-- =========================================================
-- Q16. Which departments require urgent HR action?
-- Business purpose:
-- Build a department-level HR priority view using attrition,
-- satisfaction, absenteeism, training completion, and high-performer attrition.
-- =========================================================

WITH department_attrition AS (
    SELECT
        d.department_name,
        COUNT(DISTINCT e.employee_id) AS total_employees,
        COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') AS employees_left,
        ROUND(COUNT(DISTINCT e.employee_id) FILTER (WHERE e.employee_status = 'Left') * 100.0 / NULLIF(COUNT(DISTINCT e.employee_id), 0), 2) AS attrition_rate_pct
    FROM silver.dim_employees e
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    GROUP BY d.department_name
),

latest_satisfaction AS (
    SELECT
        employee_id,
        satisfaction_score,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY survey_date DESC NULLS LAST, survey_id DESC
        ) AS rn
    FROM silver.fact_satisfaction_surveys
),

department_satisfaction AS (
    SELECT
        d.department_name,
        ROUND(AVG(s.satisfaction_score), 2) AS avg_satisfaction_score
    FROM silver.dim_employees e
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    JOIN latest_satisfaction s
        ON e.employee_id = s.employee_id
       AND s.rn = 1
    GROUP BY d.department_name
),

department_absenteeism AS (
    SELECT
        d.department_name,
        ROUND(SUM(a.absence_day_count) * 100.0 / NULLIF(COUNT(a.attendance_id), 0), 2) AS absenteeism_rate_pct
    FROM silver.fact_attendance a
    JOIN silver.dim_employees e
        ON a.employee_id = e.employee_id
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    GROUP BY d.department_name
),

department_training AS (
    SELECT
        d.department_name,
        ROUND(COUNT(t.training_id) FILTER (WHERE t.completed_flag = TRUE) * 100.0 / NULLIF(COUNT(t.training_id), 0), 2) AS training_completion_rate_pct
    FROM silver.fact_training_records t
    JOIN silver.dim_employees e
        ON t.employee_id = e.employee_id
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    GROUP BY d.department_name
),

latest_performance AS (
    SELECT
        employee_id,
        performance_score,
        ROW_NUMBER() OVER (
            PARTITION BY employee_id
            ORDER BY review_date DESC NULLS LAST, review_id DESC
        ) AS rn
    FROM silver.fact_performance_reviews
),

department_high_performer_attrition AS (
    SELECT
        d.department_name,
        COUNT(DISTINCT e.employee_id) FILTER (WHERE p.performance_score >= 4.5) AS high_performers,
        COUNT(DISTINCT e.employee_id) FILTER (WHERE p.performance_score >= 4.5 AND e.employee_status = 'Left') AS high_performers_left,
        ROUND(
            COUNT(DISTINCT e.employee_id) FILTER (WHERE p.performance_score >= 4.5 AND e.employee_status = 'Left') * 100.0
            / NULLIF(COUNT(DISTINCT e.employee_id) FILTER (WHERE p.performance_score >= 4.5), 0),
            2
        ) AS high_performer_attrition_rate_pct
    FROM silver.dim_employees e
    JOIN silver.dim_departments d
        ON e.department_id = d.department_id
    JOIN latest_performance p
        ON e.employee_id = p.employee_id
       AND p.rn = 1
    GROUP BY d.department_name
),

priority_base AS (
    SELECT
        a.department_name,
        a.total_employees,
        a.employees_left,
        a.attrition_rate_pct,
        s.avg_satisfaction_score,
        ab.absenteeism_rate_pct,
        tr.training_completion_rate_pct,
        hp.high_performers,
        hp.high_performers_left,
        hp.high_performer_attrition_rate_pct,

        CASE
            WHEN a.attrition_rate_pct >= 25 THEN 2
            WHEN a.attrition_rate_pct >= 15 THEN 1
            ELSE 0
        END AS attrition_risk_points,

        CASE
            WHEN s.avg_satisfaction_score <= 2.8 THEN 2
            WHEN s.avg_satisfaction_score <= 3.2 THEN 1
            ELSE 0
        END AS satisfaction_risk_points,

        CASE
            WHEN ab.absenteeism_rate_pct >= 10 THEN 2
            WHEN ab.absenteeism_rate_pct >= 5 THEN 1
            ELSE 0
        END AS absenteeism_risk_points,

        CASE
            WHEN tr.training_completion_rate_pct < 60 THEN 1
            ELSE 0
        END AS training_risk_points,

        CASE
            WHEN hp.high_performer_attrition_rate_pct >= 20 THEN 2
            WHEN hp.high_performer_attrition_rate_pct >= 10 THEN 1
            ELSE 0
        END AS high_performer_risk_points

    FROM department_attrition a
    LEFT JOIN department_satisfaction s
        ON a.department_name = s.department_name
    LEFT JOIN department_absenteeism ab
        ON a.department_name = ab.department_name
    LEFT JOIN department_training tr
        ON a.department_name = tr.department_name
    LEFT JOIN department_high_performer_attrition hp
        ON a.department_name = hp.department_name
)

SELECT
    department_name,
    total_employees,
    employees_left,
    attrition_rate_pct,
    avg_satisfaction_score,
    absenteeism_rate_pct,
    training_completion_rate_pct,
    high_performers,
    high_performers_left,
    high_performer_attrition_rate_pct,

    (
        attrition_risk_points
        + satisfaction_risk_points
        + absenteeism_risk_points
        + training_risk_points
        + high_performer_risk_points
    ) AS hr_priority_score,

    CASE
        WHEN (
            attrition_risk_points
            + satisfaction_risk_points
            + absenteeism_risk_points
            + training_risk_points
            + high_performer_risk_points
        ) >= 6 THEN 'Urgent Action'

        WHEN (
            attrition_risk_points
            + satisfaction_risk_points
            + absenteeism_risk_points
            + training_risk_points
            + high_performer_risk_points
        ) >= 3 THEN 'Needs Attention'

        ELSE 'Monitor'
    END AS hr_action_priority
FROM priority_base
ORDER BY hr_priority_score DESC, attrition_rate_pct DESC;

/*
Insight:
Customer Support is the highest-priority department for HR action. It has the highest
attrition rate at 29.20%, the highest absenteeism rate at 5.54%, and the highest
high-performer attrition rate at 55.77%.

Sales and Operations also require attention. Sales has a 22.18% attrition rate and
20.00% high-performer attrition, while Operations has an 18.78% attrition rate and
33.33% high-performer attrition.

Data & Analytics appears to be the strongest retention benchmark. It has the lowest
attrition rate at 6.45% and no high-performer attrition in this result.

Recommendation:
HR should prioritize Customer Support first, followed by Sales and Operations.
The action plan should focus on compensation review, career growth paths,
manager effectiveness, workload balance, and high-performer retention.
*/
