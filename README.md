# HR Workforce Attrition & Retention Analysis

## Project Overview

This project is an end-to-end HR analytics case study focused on employee attrition, retention risk, satisfaction, compensation, performance, and training effectiveness.

The goal was to answer a realistic business question:

> Where is attrition happening, why are employees leaving, and what should HR do next?

The project uses **Python** for data profiling and cleaning, **PostgreSQL / SQL** for validation and business analysis, and **Power BI** for dashboard storytelling and executive reporting.

---

## Dashboard Preview

> **Add screenshots here before publishing.** Export each Power BI page as a PNG (File → Export → Export to PNG) and place the files in the `images/` folder. Then replace these placeholders with the actual image paths.

| Page | Preview |
|---|---|
| HR Workforce Overview | ![HR Workforce Overview](images/dashboard_overview.png) |
| Attrition Hotspots | ![Attrition Hotspots](images/attrition_hotspots.png) |
| Retention Drivers | ![Retention Drivers](images/retention_drivers.png) |
| Talent & Training Effectiveness | ![Talent & Training](images/talent_training.png) |
| HR Action Plan | ![HR Action Plan](images/hr_action_plan.png) |

> Tip: GitHub renders images inline if they are committed to the repo. Aim for screenshots at 1920×1080 or higher.

---

## Business Problem

The company is experiencing employee turnover, but leadership needs to understand whether attrition is isolated or part of a broader retention problem.

HR leadership wants to know:

- How serious is the attrition problem?
- Which departments, roles, and employee groups are most affected?
- Are employees leaving voluntarily or involuntarily?
- What are the main reasons employees leave?
- Are high performers at risk?
- Are training programs improving employee performance?
- What actions should HR prioritize?

---

## Tools Used

| Tool | Purpose |
|---|---|
| Python / Jupyter Notebook | Data profiling, cleaning, standardization, missing value handling |
| PostgreSQL | Data modeling, validation, SQL business analysis |
| SQL | Attrition, compensation, satisfaction, performance, training, and HR priority analysis |
| Power BI | Data modeling, DAX measures, dashboard design, business storytelling |
| PowerPoint | Executive findings presentation |

---

## Dataset Scope

The dataset includes HR records across multiple business areas:

- Employees
- Departments
- Job roles
- Salaries
- Performance reviews
- Satisfaction surveys
- Attendance records
- Training records
- Exit interviews

The final cleaned model includes dimension and fact tables such as:

```text
dim_employees
dim_departments
dim_job_roles
fact_salaries
fact_performance_reviews
fact_satisfaction_surveys
fact_training_records
fact_attendance
fact_attrition_exit_interviews
```

---

## Analytics Workflow

### 1. Data Profiling and Cleaning

Data was first profiled in Python to identify:

- Missing values
- Duplicate records
- Invalid dates
- Inconsistent department and job title names
- Data type issues
- Outlier salary and training records

Cleaning steps included:

- Standardizing department names
- Fixing inconsistent job titles
- Handling missing values
- Correcting date fields
- Validating employee, department, and job role relationships
- Preparing clean data for PostgreSQL analysis

---

### 2. PostgreSQL Silver Layer

A cleaned **silver layer** was created in PostgreSQL.

The database was modeled using an HR analytics schema with employee-level dimensions and multiple fact tables.

Validation checks included:

- Row count checks
- Duplicate key checks
- Missing foreign key checks
- Department matching validation
- Job role matching validation
- Attrition record validation
- Salary quality checks
- Training data quality checks

---

### 3. SQL Business Analysis

SQL was used to answer 16 business questions across:

- Workforce overview
- Attrition analysis
- Tenure and early attrition
- Compensation analysis
- Satisfaction and engagement
- Performance and high-value talent
- Training effectiveness
- HR action prioritization

Examples of business questions answered:

- What is the overall attrition rate?
- Which departments have the highest attrition?
- Which job roles are most affected?
- Is attrition mostly voluntary or involuntary?
- What are the top exit reasons?
- Which tenure groups are most at risk?
- Does salary band relate to attrition?
- Do employees who left have lower satisfaction scores?
- Are high performers leaving?
- Which training categories improve or reduce performance?
- Which departments require urgent HR action?

---

## Power BI Dashboard

The Power BI dashboard contains 5 decision-focused pages:

### 1. HR Workforce Overview

Purpose:

> Show the overall workforce situation and whether attrition is a serious business issue.

Key metrics:

- Total employees: **1,850**
- Active employees: **1,496**
- Employees left: **354**
- Attrition rate: **19.14%**
- Retention rate: **80.86%**
- Voluntary exit rate: **90.37%**

---

### 2. Attrition Hotspots

Purpose:

> Identify where attrition is concentrated across departments, roles, tenure groups, and salary bands.

Key findings:

- Customer Support has the highest department attrition rate at **29.20%**
- Sales attrition rate is **22.18%**
- Operations attrition rate is **18.78%**
- Employees with **1–2 years** of tenure have the highest attrition rate at **47.42%**
- Low latest-salary-band employees have the highest salary-band attrition rate at **25.44%**

---

### 3. Retention Drivers

Purpose:

> Understand why employees are leaving.

Key findings:

- Most exits are voluntary, showing the company has a retention problem rather than mainly performance-based removals.
- The top exit reasons are:
  - Better Compensation
  - Career Growth
  - Personal Reasons
  - Workload
  - Manager Relationship
- Better Compensation and Career Growth explain approximately **37%** of exits.
- Employees who left had lower satisfaction, engagement, manager relationship, compensation satisfaction, and career growth scores than active employees.

---

### 4. Talent & Training Effectiveness

Purpose:

> Evaluate whether the company is losing valuable employees and whether training is improving performance.

Key findings:

- High performers have the highest attrition rate at **33.78%**
- **50** high performers have left
- Below-department-median salary is the most common risk driver among active high performers
- Product training showed the strongest performance improvement at **+0.19**
- Soft Skills training showed the weakest performance movement at **-0.25**

---

### 5. HR Action Plan

Purpose:

> Turn analysis into department-level HR priorities and recommended actions.

Top HR priority departments:

| Department | Attrition Rate | High Performer Attrition | Priority |
|---|---:|---:|---|
| Customer Support | 29.20% | 55.77% | Urgent Action |
| Sales | 22.18% | 20.00% | Needs Attention |
| Operations | 18.78% | 33.33% | Needs Attention |

---

## Key Business Findings

### 1. Attrition is a meaningful business issue

The company has an attrition rate of **19.14%**, meaning nearly 1 in 5 employees has left.

### 2. Attrition is mostly voluntary

**90.37%** of exits are voluntary, which means employees are choosing to leave. This makes retention strategy the main focus.

### 3. Attrition is concentrated in specific departments

Customer Support, Sales, and Operations are the main attrition hotspots.

### 4. Early-tenure employees are most at risk

Employees with **1–2 years** of tenure have the highest attrition rate at **47.42%**.

### 5. Compensation and career growth are major drivers

Better Compensation and Career Growth are the top two exit reasons.

### 6. Low salary band employees leave more often

Low latest-salary-band employees have an attrition rate of **25.44%**, higher than all other salary bands.

### 7. High performers are at risk

High performers have an attrition rate of **33.78%**, making talent retention a strategic issue.

### 8. Training impact is mixed

Some training categories improve performance, while others show weak or negative movement. Training should be evaluated by actual performance impact, not only completion rates.

---

## Recommendations

### 1. Prioritize Customer Support, Sales, and Operations

These departments have the strongest combination of high attrition, business impact, and talent risk.

### 2. Review compensation competitiveness

Compensation is the top exit reason and low salary band employees have the highest attrition rate.

### 3. Build clearer career growth paths

Career Growth is the second-largest exit reason. HR should improve internal mobility, promotion paths, and role progression.

### 4. Strengthen manager effectiveness

Manager Relationship is one of the top exit reasons and appears as a risk signal for high performers.

### 5. Monitor early-tenure employees

Employees in the 1–2 year tenure group are the highest-risk group. HR should improve onboarding, career check-ins, and early engagement programs.

### 6. Create high-performer retention plans

Active high performers with risk signals such as below-median salary, low compensation satisfaction, or weak manager relationship should be reviewed proactively.

### 7. Evaluate training by impact

Training programs should be assessed using before-and-after performance movement, not only completion rates.

---

## Suggested 90-Day HR Roadmap

### 0–30 Days: Retention Triage

- Focus on Customer Support, Sales, and Operations first
- Review exit interview responses and current salary bands
- Identify active high performers with multiple risk signals
- Brief department heads on attrition findings

### 31–60 Days: Targeted Interventions

- Conduct compensation review for high-risk roles and low-band employees
- Launch career path and internal mobility workshops
- Start manager coaching for departments with weak manager relationship scores
- Review workload and staffing pressure in frontline teams

### 61–90 Days: Measure Impact

- Track attrition rate and voluntary exit ratio monthly
- Monitor satisfaction and high-performer risk signals
- Evaluate training effectiveness using before-and-after performance
- Report progress to HR leadership using the dashboard

---

## Dashboard Pages

```text
1. HR Workforce Overview
2. Attrition Hotspots
3. Retention Drivers
4. Talent & Training Effectiveness
5. HR Action Plan
```

---

## Project Files

```text
HR-Workforce-Attrition-Analysis/
│
├── data/
│   ├── raw/
│   └── cleaned/
│
├── notebooks/
│   ├── 01_data_profiling.ipynb
│   └── 02_data_cleaning.ipynb
│
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_validation_checks.sql
│   └── 03_business_analysis_queries.sql
│
├── powerbi/
│   └── HR_Dashboard.pbix
│
│
├── images/
│   ├── dashboard_overview.png
│   ├── attrition_hotspots.png
│   ├── retention_drivers.png
│   ├── talent_training.png
│   └── hr_action_plan.png
│
└── README.md
```

---

## Skills Demonstrated

### What made this project technically challenging

- **Multi-table star schema design** — modeled 3 dimension tables and 7 fact tables with FK constraints, indexes, and post-import standardization in PostgreSQL
- **Python data cleaning pipeline** — fixed dirty department names (10+ variants), nullified implausible ages and salary records, corrected exit dates before hire dates, and added a post-cleaning validation gate
- **Window functions in SQL** — used `ROW_NUMBER()` to get the latest salary, performance, and satisfaction record per employee; `LAG()` to compute salary change over time; `PERCENTILE_CONT()` for department median salary
- **Composite retention risk model** — built a 5-signal scoring model in SQL combining below-median salary, limited salary growth, low compensation satisfaction, low manager score, and low overall satisfaction to flag at-risk high performers
- **Before-and-after training analysis** — compared each employee's performance score before and after their first completed training, by category and program, to measure real impact rather than just completion rates
- **DAX in Power BI** — wrote dynamic KPI measures including Highest Attrition Department, Highest Attrition Role, Highest Risk Tenure Group, and Top Exit Reason using `ADDCOLUMNS`, `MAXX`, `FILTER`, and `SELECTEDVALUE` patterns
- **HR priority scoring** — built a department-level risk index combining attrition rate, satisfaction score, absenteeism, training completion, and high-performer attrition into a single weighted priority score

---

## Important HR Metrics Used

| Metric | Meaning |
|---|---|
| Attrition Rate | Percentage of employees who left |
| Retention Rate | Percentage of employees still active |
| Voluntary Exit Rate | Percentage of exits initiated by employees |
| High Performer Attrition | Attrition rate among high-performing employees |
| Salary Band Attrition | Attrition rate by latest salary band |
| Satisfaction Gap | Difference in satisfaction scores between active and left employees |
| Training Impact | Performance change before and after training completion |
| HR Priority Score | Department-level risk score based on attrition, satisfaction, absenteeism, training, and talent risk |

---

## Limitations

- The dataset is used for portfolio and learning purposes.
- Some HR outcomes may require additional context such as market salary benchmarks, manager feedback, workload measures, and employee survey comments.
- Salary-band analysis uses each employee's latest salary band.
- Training impact is based on available before-and-after performance records and should be interpreted as directional, not fully causal.
- Attrition analysis is descriptive and should be supplemented with future predictive modeling for stronger forecasting.

---

## Final Summary

This project found that the company's attrition problem is mainly a retention issue driven by voluntary exits.

The highest-risk areas are Customer Support, Sales, Operations, early-tenure employees, low salary band employees, and high performers.

The recommended HR focus areas are:

- Compensation review
- Career growth paths
- Manager effectiveness
- Workload balance
- Targeted high-performer retention plans
