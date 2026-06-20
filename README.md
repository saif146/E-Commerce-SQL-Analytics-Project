# 🛒 E-Commerce SQL Analytics Project

End-to-end SQL analysis of a simulated e-commerce business — from raw relational schema to revenue, customer, product, and operations insights — written entirely in **PostgreSQL**.

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791?logo=postgresql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Complete-success)
![Queries](https://img.shields.io/badge/Analytical_Queries-24-blue)
![Tables](https://img.shields.io/badge/Tables-6-orange)

---

## 📌 Project Overview

This project simulates a mid-size online store and answers the kind of questions a real e-commerce business asks its data team:

- How much are we actually earning, and is it growing month over month?
- Who are our best customers, and which ones are at risk of churning?
- Which products and categories drive revenue — and which are about to stock out?
- Where does the order pipeline leak value (cancellations, refunds, slow shipping)?

The work is organized as **one schema file, one seed-data file, and four numbered analysis files**, each focused on a different business domain. Every query is written from scratch in raw SQL (no ORM, no BI tool) to demonstrate hands-on relational modeling and analytical SQL.

## 📂 Repository Structure

```
.
├── table_create.sql        # DDL — creates all 6 tables, keys & constraints
├── data.sql                 # Seed data — 200 customers, 30 products, 620 orders...
├── erd.png                  # Entity Relationship Diagram
├── revenue_analysis.sql     # 01 · Revenue Analysis        (6 queries)
├── customer_analysis.sql    # 02 · Customer Analysis       (6 queries)
├── product_analysis.sql     # 03 · Product Analysis        (5 queries)
├── order_analysis.sql       # 04 · Order & Operations      (7 queries)
└── README.md
```

> 💡 The leading numbers (`01`–`04`) in each file's header comment indicate the intended reading order: start broad with **revenue**, drill into **who** is buying (customers), **what** is selling (products), then **how well the pipeline runs** (orders/ops).

## 🗺️ Table of Contents

1. [Entity Relationship Diagram](#-entity-relationship-diagram)
2. [Database Schema](#-database-schema)
3. [Dataset Summary](#-dataset-summary)
4. [How to Run This Project](#-how-to-run-this-project)
5. [Analysis Walkthrough](#-analysis-walkthrough)
   - [01 · Revenue Analysis](#01--revenue-analysis-revenue_analysissql)
   - [02 · Customer Analysis](#02--customer-analysis-customer_analysissql)
   - [03 · Product Analysis](#03--product-analysis-product_analysissql)
   - [04 · Order & Operations Analysis](#04--order--operations-analysis-order_analysissql)
6. [Key Business Insights](#-key-business-insights)
7. [SQL Skills Demonstrated](#-sql-skills-demonstrated)
8. [Notes & Caveats](#-notes--caveats)

---

## 🧬 Entity Relationship Diagram

![Entity Relationship Diagram]([erd.png](https://github.com/saif146/E-Commerce-SQL-Analytics-Project/blob/main/erd))

**Relationships:**
- `customers` 1 → N `orders` — a customer can place many orders
- `orders` 1 → N `order_items` — an order can contain many line items
- `products` 1 → N `order_items` — a product appears across many line items
- `categories` 1 → N `products` — a category groups many products
- `customers` 1 → N `reviews` and `products` 1 → N `reviews` — reviews link a customer to a product they may have purchased

`order_items` is the fact table at the center of the model (an order × product bridge), which is why almost every analytical query in this project joins through it.

## 🗄️ Database Schema

Defined in [`table_create.sql`](./table_create.sql). Six tables, fully normalized, with foreign keys enforcing referential integrity.

<details>
<summary><b>customers</b></summary>

| Column | Type | Notes |
|---|---|---|
| customer_id | SERIAL | PK |
| first_name | VARCHAR(100) | NOT NULL |
| last_name | VARCHAR(100) | |
| email | VARCHAR(255) | UNIQUE, NOT NULL |
| country | VARCHAR(100) | |
| city | VARCHAR(100) | |
| created_at | TIMESTAMP | signup date, defaults to current timestamp |
</details>

<details>
<summary><b>orders</b></summary>

| Column | Type | Notes |
|---|---|---|
| order_id | SERIAL | PK |
| customer_id | INT | FK → customers |
| status | VARCHAR(50) | `completed`, `shipped`, `processing`, `cancelled`, `refunded` |
| created_at | TIMESTAMP | order placed date |
| shiped_at | TIMESTAMP | ship date (nullable) |
| delivered_at | TIMESTAMP | delivery date (nullable) |
</details>

<details>
<summary><b>categories</b></summary>

| Column | Type | Notes |
|---|---|---|
| category_id | SERIAL | PK |
| name | VARCHAR(100) | NOT NULL |
| description | VARCHAR(500) | NOT NULL |
</details>

<details>
<summary><b>products</b></summary>

| Column | Type | Notes |
|---|---|---|
| product_id | SERIAL | PK |
| name | VARCHAR(255) | NOT NULL |
| category_id | INT | FK → categories |
| price | NUMERIC(10,2) | list price |
| stock | INT | current inventory, default 0 |
</details>

<details>
<summary><b>order_items</b></summary>

| Column | Type | Notes |
|---|---|---|
| order_item_id | SERIAL | PK |
| order_id | INT | FK → orders |
| product_id | INT | FK → products |
| quantity | INT | CHECK quantity > 0 |
| unit_price | NUMERIC(10,2) | price actually paid (can differ from list price) |
</details>

<details>
<summary><b>reviews</b></summary>

| Column | Type | Notes |
|---|---|---|
| review_id | SERIAL | PK |
| product_id | INT | FK → products |
| customer_id | INT | FK → customers |
| rating | INT | CHECK between 1–5 |
| created_at | TIMESTAMP | review date |
</details>

## 📦 Dataset Summary

Seed data lives in [`data.sql`](./data.sql) and spans **Jan 2024 – Jul 2025 (~18 months)**.

| Table | Rows | Notes |
|---|---|---|
| customers | 200 | across multiple countries/cities |
| categories | 6 | Electronics, Clothing, Home & Garden, Sports & Outdoors, Books, Beauty & Personal Care |
| products | 30 | 5 products per category |
| orders | 620 | 5 statuses: 461 completed · 79 shipped · 37 processing · 31 cancelled · 12 refunded |
| order_items | 1,189 | order × product line items |
| reviews | 270 | 1–5 star ratings |

Every analytical query in this project filters orders with `WHERE status NOT IN ('cancelled', 'refunded')` first, so reported revenue always reflects **realized**, not gross-attempted, sales.

## ▶️ How to Run This Project

1. Spin up a PostgreSQL instance (locally, Docker, or a hosted instance).
2. Build the schema:
   ```bash
   psql -d your_database -f table_create.sql
   ```
3. Load the seed data:
   ```bash
   psql -d your_database -f data.sql
   ```
4. Run any analysis file — they're independent of each other and can be run in any order:
   ```bash
   psql -d your_database -f revenue_analysis.sql
   psql -d your_database -f customer_analysis.sql
   psql -d your_database -f product_analysis.sql
   psql -d your_database -f order_analysis.sql
   ```
5. Or open the `.sql` files in DBeaver / pgAdmin / TablePlus and run section-by-section — each query block is separated with a numbered comment header (e.g. `── 1.1 ──`) so you can run them one at a time and inspect results.

---

## 🔍 Analysis Walkthrough

Each file below is broken into its numbered sub-queries: the **business question** it answers, the **SQL techniques** used, and the core query itself. Workflow note: every script starts with a few quick `SELECT * FROM …` sanity checks on the raw tables before writing the real aggregation — a habit of confirming what the data actually looks like before trusting any join.

### 01 · Revenue Analysis (`revenue_analysis.sql`)

High-level financial health: total sales, trend over time, category mix, and order-value distribution.

<details>
<summary><b>1.1 — Total GMV (Gross Merchandise Value)</b></summary>

**Question:** What's our realized revenue, order count, unique buyers, and average order value?
**Skills:** multi-table `JOIN`, derived table (subquery) to pre-aggregate order totals, `COUNT(DISTINCT …)`, status filtering.

```sql
select 
       count(distinct o.order_id)                   as total_orders,
       count(distinct o.customer_id)                as unique_customers,
       round(sum(oi.quantity * oi.unit_price),2)    as total_gmv,
       round(avg(orders_totals.order_value),2)      as avg_order_value
from orders as o 
join order_items as oi on oi.order_id = o.order_id
join (
    select order_id, sum(quantity * unit_price) as order_value 
    from order_items group by 1
) as orders_totals on orders_totals.order_id = o.order_id
where o.status not in ('cancelled','refunded');
```

**Result:** 577 orders · 189 unique customers · **$101,960.27 GMV** · **$213.56 AOV**
</details>

<details>
<summary><b>1.2 — Monthly Revenue with MoM Growth & 3-Month Rolling Average</b></summary>

**Question:** Is revenue trending up or down month over month, and what does the smoothed trend look like?
**Skills:** CTE, `LAG()` for period-over-period comparison, `AVG() OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` for a rolling average, `NULLIF` to avoid divide-by-zero.

```sql
WITH monthly_sales AS (
    SELECT
        EXTRACT(YEAR FROM o.created_at) AS year,
        EXTRACT(MONTH FROM o.created_at) AS month_no,
        TRIM(TO_CHAR(o.created_at,'Month')) AS month_name,
        ROUND(SUM(oi.quantity * oi.unit_price),2) AS total_gmv
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled','refunded')
    GROUP BY 1,2,3
)
SELECT
    year, month_name, month_no, total_gmv,
    LAG(total_gmv) OVER (PARTITION BY year ORDER BY month_no) AS prev_month,
    ROUND((total_gmv - LAG(total_gmv) OVER (PARTITION BY year ORDER BY month_no))
        / NULLIF(LAG(total_gmv) OVER (PARTITION BY year ORDER BY month_no), 0) * 100, 1) AS mom_growth_pct,
    ROUND(AVG(total_gmv) OVER (PARTITION BY year ORDER BY month_no
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_3mo_avg
FROM monthly_sales
ORDER BY year, month_no;
```
</details>

<details>
<summary><b>1.3 — Revenue by Category with % Share & Rank</b></summary>

**Question:** Which product categories drive the most revenue, and what's each one's share of the total?
**Skills:** 4-table join (`order_items` → `orders` → `products` → `categories`), window `SUM() OVER ()` for a grand total without collapsing rows, `RANK()`.

```sql
with category_revenue as (
    select c.name as category,
           count(distinct o.order_id) as orders,
           sum(oi.quantity) as units_sold,
           round(sum(oi.quantity * oi.unit_price),2) as revenue,
           round(avg(oi.unit_price),2) as avg_unit_price
    from order_items as oi 
    join orders as o      on oi.order_id = o.order_id 
    join products as p    on oi.product_id = p.product_id 
    join categories as c  on c.category_id = p.category_id
    WHERE o.status NOT IN ('cancelled','refunded')
    group by c.name
)
select category, orders, units_sold, revenue, avg_unit_price,
       round(revenue / sum(revenue) over() * 100, 1) as revenue_share_pct,
       rank() over(order by revenue desc) as revenue_rnk
from category_revenue
order by revenue desc;
```

**Result:** Electronics leads at **34.3%** of revenue, followed by Clothing (17.1%), Sports & Outdoors (9.0%), Home & Garden (7.7%), Books (6.8%), and Beauty (5.4%).
</details>

<details>
<summary><b>1.4 — Year-over-Year Comparison (H1 2024 vs H1 2025)</b></summary>

**Question:** How does the first half of 2025 compare to the first half of 2024, month by month?
**Skills:** CTE, conditional aggregation (`MAX(CASE WHEN year = … THEN revenue END)`) to pivot two years into side-by-side columns, YoY % growth calc.

```sql
with half_year as (
    SELECT EXTRACT(YEAR FROM o.created_at) AS yr,
           extract(month from o.created_at) as mo,
           ROUND(SUM(oi.quantity * oi.unit_price),2) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    where o.status not in ('cancelled','refunded') and extract(month from o.created_at) <= 6
    GROUP BY 1,2
)
SELECT mo AS month_num,
       TO_CHAR(TO_DATE(mo::TEXT,'MM'),'Month') AS month_name,
       ROUND(MAX(CASE WHEN yr=2024 THEN revenue END),2) AS revenue_2024,
       ROUND(MAX(CASE WHEN yr=2025 THEN revenue END),2) AS revenue_2025,
       ROUND((MAX(CASE WHEN yr=2025 THEN revenue END) - MAX(CASE WHEN yr=2024 THEN revenue END))
           / NULLIF(MAX(CASE WHEN yr=2024 THEN revenue END),0) * 100, 1) AS yoy_growth_pct
FROM half_year
GROUP BY mo
ORDER BY mo;
```
</details>

<details>
<summary><b>1.5 — Revenue Percentile Buckets (Order Value Distribution)</b></summary>

**Question:** What does the spread of order sizes look like — are we driven by many small orders or a few big ones?
**Skills:** CTE, manual bucketing with `CASE WHEN`, window `SUM() OVER()` for percent-of-total.

```sql
with order_values as (
    select o.order_id, sum(oi.quantity * oi.unit_price) as order_value 
    from orders as o join order_items as oi on o.order_id = oi.order_id 
    where o.status not in ('cancelled','refunded') group by 1
)
select 
    CASE
        WHEN order_value < 50  THEN '< $50'
        WHEN order_value < 100 THEN '$50–$99'
        WHEN order_value < 200 THEN '$100–$199'
        WHEN order_value < 350 THEN '$200–$349'
        ELSE '$350+'
    END as order_bucket,
    count(*) as order_count,
    round(count(*) * 100 / sum(count(*)) over(), 1) as pct_of_orders,
    round(sum(order_value)) as bucket_revenue,
    round(sum(order_value) * 100.0 / sum(sum(order_value)) over(), 1) as pct_of_revenue
from order_values
group by order_bucket
order by min(order_value);
```
</details>

<details>
<summary><b>1.6 — Rolling 7-Day Revenue</b></summary>

**Question:** What does daily revenue look like once smoothed over a trailing week (removes day-to-day noise)?
**Skills:** CTE, window frame `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` for both a rolling average and rolling sum.

```sql
with daily as (
    select date(o.created_at) as order_date,
           count(distinct o.order_id) as orders,
           sum(oi.quantity * oi.unit_price) as daily_revenue
    from orders as o join order_items as oi on o.order_id = oi.order_id 
    WHERE o.status NOT IN ('cancelled','refunded')
    group by order_date
)
select order_date, orders, daily_revenue,
       round(avg(daily_revenue) over(order by order_date rows between 6 PRECEDING and current row),2) as rolling_7d_avg,
       round(sum(daily_revenue) over(order by order_date rows between 6 preceding and current row),2) as rolling_7d_revenue
from daily order by order_date;
```
</details>

---

### 02 · Customer Analysis (`customer_analysis.sql`)

Who is buying, how valuable they are, and how well the business retains them.

<details>
<summary><b>2.1 — Top 10 Customers by Lifetime Value</b></summary>

**Question:** Who are our highest-value customers, and what's their order history?
**Skills:** 3-table join + derived table, string concatenation for full name, `MIN`/`MAX` for first/last order dates, `ORDER BY … DESC LIMIT`.

```sql
select c.customer_id,
       c.first_name || ' ' || c.last_name   as customer_name,
       count(distinct o.order_id)           as total_orders,
       sum(oi.quantity)                     as total_units,
       sum(oi.unit_price * oi.quantity)     as lifetime_value,
       round(avg(order_totals.order_value)) as avg_order_value,
       min(o.created_at)::date              as first_order,
       max(o.created_at)::date              as last_order
from orders as o 
join order_items as oi on oi.order_id = o.order_id 
join customers as c on o.customer_id = c.customer_id 
join (
    select order_id, sum(quantity * unit_price) as order_value 
    from order_items group by order_id
) as order_totals on order_totals.order_id = o.order_id
WHERE o.status NOT IN ('cancelled','refunded')
group by 1, 2, c.country
order by 5 desc limit 10;
```
</details>

<details>
<summary><b>2.2 — RFM Segmentation (Recency · Frequency · Monetary)</b></summary>

**Question:** Which customers are champions, loyal, at-risk, or lost, based on how recently/often/how much they buy?
**Skills:** 3 chained CTEs, `NTILE(5)` to score each dimension 1–5, multi-condition `CASE` for segment labeling, classic RFM marketing-analytics framework.

```sql
with rfm_base as (
     select o.customer_id,
            max(o.created_at) as last_order_date,
            count(distinct o.order_id) as frequency,
            round(sum(oi.quantity * oi.unit_price),2) as monetary
     from orders as o 
     join order_items as oi on o.order_id = oi.order_id 
     WHERE o.status NOT IN ('cancelled','refunded')
     group by o.customer_id
),
rfm_score as (
     select customer_id, last_order_date, frequency, monetary,
            ntile(5) over(order by last_order_date desc) as r_score,
            ntile(5) over(order by frequency asc)        as f_score,
            ntile(5) over(order by monetary asc)         as m_score
     from rfm_base
),
rfm_segments as (
     select customer_id, r_score, f_score, m_score,
            (r_score + f_score + m_score) as rfm_total,
            case 
                when r_score>=4 and f_score>=4 and m_score>=4 then 'Champions'
                when r_score>=3 and f_score>=3                then 'Loyal Customers'
                when r_score>=4 and f_score<=2                then 'Recent Customers'
                when r_score<=2 and f_score>=3                then 'At-risk'
                when r_score=1                                then 'Lost'
                else 'Potential Loyalists'
           end as segment
     from rfm_score
)
select segment, count(*) as customers,
       round(avg(rfm_total),1) as avg_rfm_score,
       round(count(*) * 100 / sum(count(*)) over(), 1) as pct_of_base
from rfm_segments 
group by segment
order by avg_rfm_score desc;
```
</details>

<details>
<summary><b>2.3 — Revenue by Country with Avg LTV</b></summary>

**Question:** Which markets (countries) generate the most revenue and the highest value per customer?
**Skills:** join + derived table, per-customer LTV normalization (`revenue / distinct customers`).

```sql
select c.country,
       count(distinct c.customer_id) as customers,
       count(distinct o.order_id) as orders,
       round(sum(oi.quantity * oi.unit_price),2) as total_revenue,
       round(sum(oi.quantity * oi.unit_price) / count(distinct c.customer_id),2) as avg_ltv_per_customers,
       round(avg(order_val.order_value),2) as avg_order_value
from customers as c 
join orders as o on o.customer_id = c.customer_id 
join order_items as oi on o.order_id = oi.order_id 
join (
    select order_id, sum(quantity * unit_price) as order_value from order_items group by order_id
) as order_val on order_val.order_id = o.order_id
WHERE o.status NOT IN ('cancelled','refunded')
group by c.country
order by total_revenue desc;
```
</details>

<details>
<summary><b>2.4 — Repeat vs. One-Time Buyers with Revenue Share</b></summary>

**Question:** How much revenue comes from repeat buyers vs. one-and-done customers?
**Skills:** nested subquery inside a CTE, behavioral segmentation via `CASE`, revenue-share window calc.

```sql
with customer_orders as (
    select customer_id, count(order_id) as order_count, sum(order_value) as total_spend
    from (
        select o.customer_id, o.order_id,
               sum(oi.quantity * oi.unit_price) as order_value 
        from orders as o 
        join order_items as oi on o.order_id = oi.order_id 
        WHERE o.status NOT IN ('cancelled','refunded')
        group by o.customer_id, o.order_id
    ) t
    group by customer_id
),
segments as (
    select *,
        case 
            when order_count=1 then 'One-Time Buyer'
            when order_count between 2 and 3 then 'Repeat Buyer'
            else 'Loyal Customer (4+)'
        end as segment
    from customer_orders
)
select segment, count(*) as customers,
       round(avg(order_count),1) as avg_orders,
       round(avg(total_spend),1) as avg_spend,
       round(sum(total_spend),2) as segment_revenue,
       round(sum(total_spend) * 100 / sum(sum(total_spend)) over(), 1) as revenue_pct
from segments 
group by segment
order by avg_orders;
```
</details>

<details>
<summary><b>2.5 — Monthly Cohort Retention</b></summary>

**Question:** Of customers who signed up in a given month, what % are still ordering 1, 2, 3… months later?
**Skills:** signup cohorts via `DATE_TRUNC`, `LEFT JOIN` to keep non-returning customers in the denominator, `AGE()` + `EXTRACT(MONTH FROM …)` to compute months-since-signup, classic cohort retention table pattern.

```sql
with cohorts as (
    select customer_id, date_trunc('month', created_at) as cohort_month 
    from customers
),
purchase as (
    select distinct o.customer_id, date_trunc('month', o.created_at) as purchase_month
    from orders as o
    WHERE o.status NOT IN ('cancelled','refunded')
),
cohort_data as (
    select c.cohort_month,
           extract(month from age(p.purchase_month, c.cohort_month))::int as months_since_signup,
           count(distinct c.customer_id) as active_customers
    from cohorts as c 
    left join purchase as p 
        on c.customer_id = p.customer_id 
        and p.purchase_month >= c.cohort_month
    group by c.cohort_month, months_since_signup
),
cohort_size as (
    select cohort_month, count(*) as cohort_size
    from cohorts 
    group by cohort_month
)
select to_char(cd.cohort_month,'YYYY-MM') as cohort,
       cs.cohort_size,
       cd.months_since_signup as month_number,
       cd.active_customers,
       round(cd.active_customers * 100.0 / cs.cohort_size, 1) as retention_pct 
from cohort_data as cd 
join cohort_size as cs on cd.cohort_month = cs.cohort_month 
where cd.months_since_signup between 0 and 5 
order by cd.cohort_month, cd.months_since_signup;
```
</details>

<details>
<summary><b>2.6 — Customer Purchase Frequency Distribution</b></summary>

**Question:** What's the distribution of "how many orders has a customer placed" across the whole base?
**Skills:** CTE, window `SUM() OVER (ORDER BY …)` to build a cumulative count alongside the per-bucket count.

```sql
with order_counts as (
    select o.customer_id, count(o.order_id) as n_orders 
    from orders as o
    WHERE o.status NOT IN ('cancelled','refunded') 
    group by 1
)
select n_orders, count(*) as customers,
       round(count(*) * 100.0 / sum(count(*)) over(), 1) as pct,
       sum(count(*)) over(order by n_orders) as cumulative_customers
from order_counts group by n_orders order by n_orders;
```
</details>

---

### 03 · Product Analysis (`product_analysis.sql`)

Performance, ratings, inventory risk, and cross-sell relationships at the product level.

<details>
<summary><b>3.1 — Product Leaderboard (Units, Revenue, Margin Rank)</b></summary>

**Question:** Which products sell the most, generate the most revenue, and how does actual selling price compare to list price?
**Skills:** CTE, `RANK()` and `NTILE(4)` for performance tiers, price-variance calc (actual vs. list price).

```sql
with product_stats as (
    select p.product_id, p.name as product, c.name as category,
           p.price as list_price, p.stock as current_stock,
           sum(oi.quantity) as units_sold,
           sum(oi.quantity * oi.unit_price) as revenue,
           round(avg(oi.unit_price),1) as avg_sell_price,
           count(distinct oi.order_id) as times_ordered
    from products as p 
    join order_items as oi on oi.product_id = p.product_id 
    join orders as o on o.order_id = oi.order_id 
    join categories as c on c.category_id = p.category_id
    WHERE o.status NOT IN ('cancelled','refunded')
    group by 1,2,3,4
)
select product, category, list_price, units_sold, revenue, avg_sell_price,
       round((avg_sell_price - list_price) / list_price * 100, 1) as price_variance_pct,
       current_stock,
       rank() over(order by revenue desc) as revenue_rank,
       rank() over(order by units_sold) as units_rank,
       ntile(4) over(order by revenue desc) as revenue_quartile
from product_stats
order by revenue desc;
```
</details>

<details>
<summary><b>3.2 — Category-Level Product Performance Benchmarks</b></summary>

**Question:** How does each product compare to the average product in its own category?
**Skills:** `AVG() OVER (PARTITION BY category)` to get an in-category benchmark, `RANK() OVER (PARTITION BY category ORDER BY revenue DESC)` for within-category leaderboards.

```sql
with product_rev as (
    select p.product_id, p.name as product, c.name as category,
           sum(oi.quantity) as units_sold,
           sum(oi.quantity * oi.unit_price) as revenue
    from products as p 
    join order_items as oi on oi.product_id = p.product_id 
    join orders as o on o.order_id = oi.order_id 
    join categories as c on c.category_id = p.category_id
    WHERE o.status NOT IN ('cancelled','refunded')
    group by 1,2,3
)
select product, category, revenue, units_sold,
       round(avg(revenue) over(partition by category),2) as category_avg_revenue,
       round(revenue - avg(revenue) over(partition by category),2) as vs_category_avg,
       rank() over(partition by category order by revenue desc) as rank_in_category
from product_rev
order by category, revenue desc;
```
</details>

<details>
<summary><b>3.3 — Product Ratings & Review Analysis</b></summary>

**Question:** Which products are rated highest, and what % of buyers actually leave a review?
**Skills:** `LEFT JOIN` chain so products with zero orders/reviews still appear, conditional aggregation for the 1–5 star breakdown, review-rate calc with `NULLIF` guarding the denominator.

```sql
select p.name as product, c.name as category,
       count(r.review_id) as review_count,
       round(avg(r.rating),2) as avg_rating,
       sum(case when r.rating=5 then 1 else 0 end) as five_star,
       sum(case when r.rating=4 then 1 else 0 end) as four_star,
       sum(case when r.rating=3 then 1 else 0 end) as three_star,
       sum(case when r.rating<=2 then 1 else 0 end) as low_rating,
       count(distinct o.order_id) as times_ordered,
       round(count(r.review_id)::numeric / nullif(count(distinct oi.order_id),0) * 100, 1) as review_pct
from products as p 
join categories as c on p.category_id = c.category_id
left join order_items as oi on oi.product_id = p.product_id 
left join orders as o on o.order_id = oi.order_id and o.status not in ('cancelled','refunded')
left join reviews as r on r.product_id = p.product_id
group by p.product_id, p.name, c.name
order by avg_rating desc, review_count desc;
```
</details>

<details>
<summary><b>3.4 — Low-Stock Alert with Velocity (Days of Stock Remaining)</b></summary>

**Question:** Given recent sales pace, which low-stock products will run out soonest?
**Skills:** CTE limited to a 90-day rolling window, daily sales-velocity calc, `LEFT JOIN` so products with no recent sales still show as "OK", a tiered `CASE` for 🔴/🟡/🟢 stock status.

```sql
with sales_velocity as (
    select oi.product_id,
           sum(oi.quantity) as units_sold_90d,
           sum(oi.quantity) / 90.0 as daily_velocity
    from order_items as oi 
    join orders as o on oi.order_id = o.order_id 
    where o.status NOT IN ('cancelled','refunded') 
      and o.created_at > current_date - interval '90 days'
    group by oi.product_id 
)
select p.product_id, p.name, c.name as category, p.stock, p.price,
       round(sv.daily_velocity,2) as units_per_day,
       round(p.stock / nullif(sv.daily_velocity,0)) as days_of_stock_remaining,
       case 
           when p.stock / nullif(sv.daily_velocity,0) < 14 then '🔴 Critical'
           when p.stock / nullif(sv.daily_velocity,0) < 30 then '🟡 Low'
           else '🟢 OK'
       end as stock_status
from products as p 
join categories as c on p.category_id = c.category_id 
left join sales_velocity as sv on sv.product_id = p.product_id
where p.stock < 100 
order by days_of_stock_remaining nulls last;
```
</details>

<details>
<summary><b>3.5 — Market Basket Analysis (Products Bought Together)</b></summary>

**Question:** Which two products most often appear in the same order — a candidate for "frequently bought together"?
**Skills:** self-join on `order_items` with `b.product_id > a.product_id` to count each pair once, co-purchase counts, a basic support-style affinity metric.

```sql
with baskets as (
    select a.order_id, a.product_id as product_a, b.product_id as product_b
    from order_items as a 
    join order_items as b on a.order_id = b.order_id and b.product_id > a.product_id
    join orders as o on o.order_id = a.order_id
    WHERE o.status NOT IN ('cancelled','refunded')
),
pair_count as (
    select product_a, product_b, count(*) as co_purchase 
    from baskets group by 1,2
),
product_order_counts as (
    select oi.product_id, count(distinct oi.order_id) as order_count
    from order_items as oi 
    join orders as o on o.order_id = oi.order_id
    where o.status NOT IN ('cancelled','refunded')
    group by oi.product_id
)
select pa.name as product_a, pb.name as product_b, pc.co_purchase,
       round(pc.co_purchase * 100 / (oa.order_count + ob.order_count), 1) as support_pct
from pair_count as pc 
join products as pa on pc.product_a = pa.product_id 
join products as pb on pc.product_b = pb.product_id
join product_order_counts as oa on oa.product_id = pc.product_a
join product_order_counts as ob on ob.product_id = pc.product_b
order by 3 desc limit 15;
```
</details>

---

### 04 · Order & Operations Analysis (`order_analysis.sql`)

The order pipeline: status mix, fulfillment speed, ordering patterns, and revenue anomalies.

<details>
<summary><b>4.1 — Order Status Funnel with Revenue Impact</b></summary>

**Question:** How many orders land in each status, and how much revenue is tied up in each stage?
**Skills:** CTE to pre-aggregate order value, window `SUM() OVER()` for % of total orders.

```sql
with order_totals as (
    select order_id, sum(unit_price * quantity) as order_value 
    from order_items 
    group by order_id
)
select o.status,
       count(o.order_id) as order_count,
       round(count(o.order_id) * 100.0 / sum(count(o.order_id)) over(), 1) as pct_of_orders,
       round(sum(ot.order_value),2) as gross_value,
       round(avg(ot.order_value),2) as avg_order_value
from orders as o 
join order_totals as ot on o.order_id = ot.order_id 
group by o.status 
order by order_count desc;
```
</details>

<details>
<summary><b>4.2 — Monthly Cancellation & Refund Rate Trend</b></summary>

**Question:** Are cancellations/refunds getting better or worse over time?
**Skills:** conditional aggregation for rate calculation, a window `AVG()` wrapped around a `CASE`-based aggregate to produce a rolling 3-month cancellation rate.

```sql
select to_char(created_at,'YYYY-MM') as month,
       count(*) as total_orders,
       sum(case when status='cancelled' then 1 else 0 end) as cancelled,
       sum(case when status='refunded' then 1 else 0 end) as refunded,
       round(sum(case when status='cancelled' then 1 else 0 end) * 100.0 / count(*), 1) as cancel_rate_pct,
       round(sum(case when status='refunded' then 1 else 0 end) * 100.0 / count(*), 1) as refund_rate_pct,
       round(avg(sum(case when status='cancelled' then 1 else 0 end) * 100.0 / count(*)) 
           over(order by to_char(created_at,'YYYY-MM') rows between 2 PRECEDING and current row), 1) as rolling_3mo_cancel_pct
from orders group by month;
```
</details>

<details>
<summary><b>4.3 — Fulfillment SLA Analysis</b></summary>

**Question:** How long does it take to ship and deliver, and how often do we breach a 5-day SLA?
**Skills:** timestamp arithmetic via `EXTRACT(EPOCH FROM …)`, `percentile_cont(0.5)` for true median (more robust than average), SLA breach flagging.

```sql
select 
    round(avg(extract(epoch from(shiped_at - created_at)) / 3600 / 24), 1) as avg_days_to_ship,
    round(percentile_cont(0.5) within group (order by extract(epoch from(shiped_at - created_at)) / 3600 / 24)) as median_days_to_ship,
    round(avg(extract(epoch from(delivered_at - shiped_at)) / 3600 / 24), 1) as avg_days_to_deliver,
    round(percentile_cont(0.5) within group (order by extract(epoch from(delivered_at - shiped_at)) / 3600 / 24)) as median_days_to_deliver,
    round(avg(extract(epoch from(delivered_at - created_at)) / 3600 / 24), 1) as avg_end_to_end_days,
    sum(case when extract(epoch from(delivered_at - created_at)) / 3600 / 24 > 5 then 1 else 0 end) as sla_breaches,
    round(sum(case when extract(epoch from(delivered_at - created_at)) / 3600 / 24 > 5 then 1 else 0 end) * 100.0 / count(*), 1) as breach_rate_pct
from orders 
where status = 'completed' and shiped_at is not null and delivered_at is not null;
```
</details>

<details>
<summary><b>4.4 — Multi-Item Order Analysis</b></summary>

**Question:** Do orders with more line items actually generate disproportionately more revenue?
**Skills:** CTE, `COUNT()` of line items per order as a basket-size proxy, window % share calcs.

```sql
with order_summary as (
    select o.order_id, c.first_name || ' ' || c.last_name as customer,
           count(oi.order_item_id) as item_count,
           sum(oi.quantity) as total_units,
           round(sum(oi.quantity * oi.unit_price)) as order_total
    from orders as o join customers as c on o.customer_id = c.customer_id
    join order_items as oi on oi.order_id = o.order_id
    WHERE o.status NOT IN ('cancelled','refunded')
    group by o.order_id, customer
)
select item_count as distinct_products,
       count(order_id) as orders,
       round(count(order_id) * 100.0 / sum(count(*)) over(), 1) as pct_orders,
       round(avg(order_total),1) as avg_order_value,
       round(sum(order_total)) as total_revenue,
       round(sum(order_total) * 100.0 / sum(sum(order_total)) over(), 1) as pct_revenue
from order_summary
group by item_count
order by item_count;
```

**Insight:** 2-item orders make up **~37.4%** of all orders and generate **~37%** of revenue — value scales close to linearly with basket size in this dataset.
</details>

<details>
<summary><b>4.5 — Day-of-Week & Hour-of-Day Order Patterns</b></summary>

**Question:** Which days drive the most orders and the highest average order value?
**Skills:** `TO_CHAR(…, 'day')` + `EXTRACT(DOW FROM …)` for both a readable label and a sortable numeric key, join to a pre-aggregated order-value subquery.

```sql
select to_char(created_at,'day') as day_of_week,
       extract(dow from created_at) as dow_num,
       count(*) as orders,
       round(count(*) * 100 / sum(count(*)) over(), 1) as pct,
       round(avg(ot.order_value),1) as avg_order_value
from orders as o join (
    select order_id, sum(quantity * unit_price) as order_value from order_items group by order_id
) as ot on ot.order_id = o.order_id
WHERE o.status NOT IN ('cancelled','refunded')
group by 1,2
order by 2;
```
</details>

<details>
<summary><b>4.6 — Rolling 7-Day Revenue with Anomaly Detection</b></summary>

**Question:** Which days were unusually high or low — i.e., spikes or dips relative to a recent trailing average?
**Skills:** chained CTEs, rolling `AVG()`/`STDDEV()`/`SUM()` over a 7-day window, a z-score-style deviation metric used to flag 📈 Spike / 📉 Dip / Normal days.

```sql
with daily_rev as (
    select date(o.created_at) as order_date,
           sum(quantity * unit_price) as daily_revenue
    from orders as o 
    join order_items as oi on o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled','refunded')
    group by date(o.created_at)
),
rolling as (
    select order_date, daily_revenue,
           round(avg(daily_revenue) over(order by order_date rows between 6 preceding and current row),2) as rolling_7d_avg,
           round(stddev(daily_revenue) over(order by order_date rows between 6 preceding and current row),2) as rolling_7d_stddev,
           round(sum(daily_revenue) over(order by order_date rows between 6 preceding and current row),2) as cumulative_revenue
    from daily_rev
)
select order_date, daily_revenue, rolling_7d_avg,
       round((daily_revenue - rolling_7d_avg) / nullif(rolling_7d_avg,0), 2) as z_score,
       case when (daily_revenue - rolling_7d_avg) / nullif(rolling_7d_avg,0) > 2  THEN '📈 Spike'
            when (daily_revenue - rolling_7d_avg) / nullif(rolling_7d_avg,0) < -2 THEN '📉 Dip'
            else 'Normal'
       end as anomaly_flag,
       cumulative_revenue
from rolling
order by order_date;
```
</details>

<details>
<summary><b>4.7 — Customer Reorder Gap (Avg Days Between Purchases)</b></summary>

**Question:** On average, how many days pass between a customer's orders?
**Skills:** `LAG() OVER (PARTITION BY customer_id ORDER BY created_at)` to find each customer's previous order, `percentile_cont` for P25/P50/P75 gap distribution.

```sql
with ordered as (
    select customer_id, created_at,
           lag(created_at) over(partition by customer_id order by created_at) as prev_order_date 
    from orders WHERE status NOT IN ('cancelled','refunded')
),
gaps as (
    select customer_id,
           round(extract(epoch from(created_at - prev_order_date)) / 3600 / 24, 1) as days_between
    from ordered
    where prev_order_date is not null
)
select round(avg(days_between),1) as average_days_between_orders,
       round(percentile_cont(0.25) within group(order by days_between)) as p25_days,
       round(percentile_cont(0.5) within group(order by days_between)) as p50_days,
       round(percentile_cont(0.75) within group(order by days_between)) as p75_days,
       count(*) as repeat_purchase_events
from gaps;
```
</details>

---

## 💡 Key Business Insights

- **Realized GMV is $101,960.27** across 577 valid orders (189 unique buyers) at a **$213.56 average order value**.
- **Electronics is the revenue engine**, contributing 34.3% of total revenue — more than 2× the next category (Clothing, 17.1%).
- **Basket size scales almost linearly with revenue**: 2-item orders represent ~37.4% of orders and ~37% of revenue.
- RFM segmentation separates the base into actionable tiers (**Champions, Loyal, At-risk, Lost, Recent, Potential Loyalists**) for targeted retention campaigns.
- Cohort retention, reorder-gap percentiles, and the 7-day anomaly detector together give a full picture of *when* customers come back and *which* days break the normal pattern.

## 🧠 SQL Skills Demonstrated

- **Core SQL:** multi-table `JOIN`s, `LEFT JOIN` for null-safe completeness, derived tables/subqueries, `GROUP BY`, string concatenation
- **CTEs:** single and multi-step chained CTEs to keep complex logic readable
- **Window functions:** `RANK()`, `NTILE()`, `LAG()`, and `SUM()/AVG()/STDDEV() OVER (PARTITION BY … ORDER BY … ROWS BETWEEN …)`
- **Conditional aggregation:** `CASE WHEN` inside `SUM()`/`COUNT()` to pivot categorical data into columns
- **Date/time analysis:** `DATE_TRUNC`, `EXTRACT`, `AGE()`, `TO_CHAR`, epoch-based duration math
- **Statistical functions:** `PERCENTILE_CONT` for medians/quartiles, `STDDEV` for anomaly detection
- **Analytics frameworks:** RFM segmentation, cohort retention analysis, market basket / affinity analysis, funnel analysis, SLA breach analysis, rolling-window trend smoothing
- **Defensive SQL:** `NULLIF` to guard divide-by-zero, consistent exclusion of `cancelled`/`refunded` orders to avoid overstating revenue
- **Relational database design:** normalized 6-table schema with primary/foreign keys and `CHECK` constraints, documented with an ERD

## 📝 Notes & Caveats

- This is a **simulated dataset** generated for portfolio purposes — figures are illustrative, not real business data.
- `shiped_at` is spelled as it appears in the original schema/seed data; kept as-is in all queries for consistency with the live column name.
- Each `.sql` file is meant to be read/run top-to-bottom but the individual numbered query blocks are fully independent — feel free to run just one at a time.

---

## Author:: Saiful Islam
- **LinkedIn**: [Connect with me professionally](https://www.linkedin.com/in/saiful-islam-7b7a64268/)
