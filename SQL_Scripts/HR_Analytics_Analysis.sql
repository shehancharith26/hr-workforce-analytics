-- IBM HR Workforce Analytics | PostgreSQL Analysis
-- Dataset: IBM HR Analytics Employee Attrition & Performance (synthetic example data)
-- Database: hr_analytics | Table: public.hr_employees
-- Prepared as a consolidated, read-only SQL analysis script.
-- Run each numbered query separately in pgAdmin by highlighting it and clicking Execute/F5.
-- These queries do NOT change or delete data.

-- ============================================================
-- 01 | Workforce overview and attrition rate
-- Business question: What proportion of employees left?
-- ============================================================
SELECT
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS employees_left,
    COUNT(*) FILTER (WHERE attrition = 'No') AS employees_stayed,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE attrition = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS attrition_rate_pct
FROM public.hr_employees;

-- ============================================================
-- 02 | Attrition breakdown
-- Business question: How many employees left vs stayed?
-- ============================================================
SELECT
    attrition,
    COUNT(*) AS employee_count
FROM public.hr_employees
GROUP BY attrition
ORDER BY attrition;

-- ============================================================
-- 03 | Department-wise attrition
-- Business question: Which department has the highest attrition rate?
-- ============================================================
SELECT
    department,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS employees_left,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE attrition = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS attrition_rate_pct
FROM public.hr_employees
GROUP BY department
ORDER BY attrition_rate_pct DESC;

-- ============================================================
-- 04 | Job role-wise attrition
-- Business question: Which job roles have the highest attrition rates?
-- ============================================================
SELECT
    job_role,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS employees_left,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE attrition = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS attrition_rate_pct
FROM public.hr_employees
GROUP BY job_role
ORDER BY attrition_rate_pct DESC;

-- ============================================================
-- 05 | Overtime and attrition
-- Business question: Is attrition higher among overtime employees?
-- ============================================================
SELECT
    over_time,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS employees_left,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE attrition = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS attrition_rate_pct
FROM public.hr_employees
GROUP BY over_time
ORDER BY attrition_rate_pct DESC;

-- ============================================================
-- 06 | Overtime and attrition by department
-- Business question: Does the overtime/attrition pattern occur across departments?
-- ============================================================
SELECT
    department,
    over_time,
    COUNT(*) AS total_employees,
    COUNT(*) FILTER (WHERE attrition = 'Yes') AS employees_left,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE attrition = 'Yes')
        / NULLIF(COUNT(*), 0), 2
    ) AS attrition_rate_pct
FROM public.hr_employees
GROUP BY department, over_time
ORDER BY department, over_time DESC;

-- ============================================================
-- 07 | Work-life balance and attrition (CTE)
-- Business question: How does attrition differ by work-life balance rating?
-- Rating scale: 1=Bad, 2=Good, 3=Better, 4=Best
-- ============================================================
WITH work_life_summary AS (
    SELECT
        work_life_balance,
        COUNT(*) AS total_employees,
        COUNT(*) FILTER (WHERE attrition = 'Yes') AS employees_left
    FROM public.hr_employees
    GROUP BY work_life_balance
)
SELECT
    work_life_balance,
    total_employees,
    employees_left,
    ROUND(
        100.0 * employees_left / NULLIF(total_employees, 0), 2
    ) AS attrition_rate_pct
FROM work_life_summary
ORDER BY attrition_rate_pct DESC;

-- ============================================================
-- 08 | Rank job roles by attrition rate (window function)
-- Business question: Which roles rank highest company-wide?
-- ============================================================
WITH role_summary AS (
    SELECT
        job_role,
        COUNT(*) AS total_employees,
        COUNT(*) FILTER (WHERE attrition = 'Yes') AS employees_left
    FROM public.hr_employees
    GROUP BY job_role
)
SELECT
    RANK() OVER (
        ORDER BY 100.0 * employees_left / NULLIF(total_employees, 0) DESC
    ) AS attrition_rank,
    job_role,
    total_employees,
    employees_left,
    ROUND(
        100.0 * employees_left / NULLIF(total_employees, 0), 2
    ) AS attrition_rate_pct
FROM role_summary
ORDER BY attrition_rank;

-- ============================================================
-- 09 | Rank job roles within each department (PARTITION BY)
-- Business question: Which role ranks highest within each department?
-- ============================================================
WITH role_summary AS (
    SELECT
        department,
        job_role,
        COUNT(*) AS total_employees,
        COUNT(*) FILTER (WHERE attrition = 'Yes') AS employees_left,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE attrition = 'Yes')
            / NULLIF(COUNT(*), 0), 2
        ) AS attrition_rate_pct
    FROM public.hr_employees
    GROUP BY department, job_role
)
SELECT
    department,
    job_role,
    total_employees,
    employees_left,
    attrition_rate_pct,
    DENSE_RANK() OVER (
        PARTITION BY department
        ORDER BY attrition_rate_pct DESC
    ) AS department_rank
FROM role_summary
ORDER BY department, department_rank;

-- NOTE: Observed associations in this fictional dataset do not establish causation.
