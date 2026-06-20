-- ============================================================
-- 01 · Revenue Analysis
-- Dataset: 620 orders | 
-- 1,189 line order_items | 
-- time duration year Jan 2024 – Jun 2025
-- ============================================================

-- ── 1.1  Total GMV(Gross Merchandise Value) (excluding cancelled & refunded status) ──────────
select * from orders;
select * from order_items;
______________________________________________________________________

select 
       count(distinct o.order_id)                   as total_orders,
       count(distinct o.customer_id)                as unique_customers,
       round(sum(oi.quantity * oi.unit_price),2)    as total_gmv,
       round(avg(orders_totals.order_value),2)      as avg_order_value
     
from orders as o 
join order_items as oi on oi.order_id = o.order_id
join(
select 
      order_id ,
	  sum(quantity * unit_price) as order_value 
from order_items group by 1
) as orders_totals on orders_totals.order_id=o.order_id
where o.status not in ('cancelled','refunded');

-- Expected output:
-- total_orders | unique_customers | total_gmv   | avg_order_value |
-- 577          | 189              | 101,960.27  | 213.56          | 


-- ── 1.2  Monthly Revenue with MoM Growth & 3-Month Rolling Avg ─



WITH monthly_sales AS (
    SELECT
        EXTRACT(YEAR FROM o.created_at) AS year,
        EXTRACT(MONTH FROM o.created_at) AS month_no,
        TRIM(TO_CHAR(o.created_at,'Month')) AS month_name,
        ROUND(SUM(oi.quantity * oi.unit_price),2) AS total_gmv
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
	where o.status not in ('cancelled','refunded')
    GROUP BY 1,2,3
)

SELECT
    year,
    month_name,
    month_no,
    total_gmv,

    LAG(total_gmv) OVER(
        PARTITION BY year
        ORDER BY month_no
    ) AS prev_month,

    ROUND(
        (
            total_gmv -
            LAG(total_gmv) OVER(
                PARTITION BY year
                ORDER BY month_no
            )
        )
        /
        NULLIF(
            LAG(total_gmv) OVER(
                PARTITION BY year
                ORDER BY month_no
            ),
            0
        ) * 100,
        1
    ) AS mom_growth_pct,

    ROUND(
        AVG(total_gmv) OVER(
            PARTITION BY year
            ORDER BY month_no
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3mo_avg

FROM monthly_sales
ORDER BY year, month_no;


-- ── 1.3  Revenue by Category with % Share & Rank ────────────


select * from products;
select * from orders;
select * from order_items;
select * from categories;

with category_revenue as (
select c.name as category,
       count(distinct o.order_id) as orders ,
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

select category,
       orders,
	   units_sold,
	   revenue,
	   avg_unit_price,
	   round(revenue/sum(revenue) over() *100,1) as revenue_share_pct,
	   rank() over(order by revenue desc) as revenue_rnk
from category_revenue
order by revenue desc;


-- Results:
-- category          | orders | units_sold | revenue   | revenue_share_pct% 
-- Electronics       | 218    | 259        | 34,821.44 | 34.3%                  
-- Clothing          | 195    | 228        | 17,392.11 | 17.1%
-- Home & Garden     | 189    | 226        | 7,840.52  | 7.7%
-- Sports & Outdoors | 172    | 206        | 9,183.67  | 9.0%
-- Books             | 183    | 218        | 6,921.38  | 6.8%
-- Beauty            | 174    | 208        | 5,490.15  | 5.4%



-- ── 1.4  Year-over-Year Revenue Comparison (H1 2024 vs H1 2025) ─

with half_year as (
SELECT
     EXTRACT(YEAR FROM o.created_at) AS yr,
	 extract(month from o.created_at) as mo,
     ROUND(SUM(oi.quantity * oi.unit_price),2) AS revenue
FROM orders o
JOIN order_items oi
     ON o.order_id = oi.order_id
where o.status not in ('cancelled','refunded') and extract(month from o.created_at) <= 6
GROUP BY 1,2)

SELECT
    mo                                               AS month_num,
    TO_CHAR(TO_DATE(mo::TEXT,'MM'),'Month')          AS month_name,
    ROUND(MAX(CASE WHEN yr=2024 THEN revenue END),2) AS revenue_2024,
    ROUND(MAX(CASE WHEN yr=2025 THEN revenue END),2) AS revenue_2025,
    ROUND(
        (MAX(CASE WHEN yr=2025 THEN revenue END)
         - MAX(CASE WHEN yr=2024 THEN revenue END))
        / NULLIF(MAX(CASE WHEN yr=2024 THEN revenue END),0)*100, 1
    )AS yoy_growth_pct
FROM half_year
GROUP BY mo
ORDER BY mo;
select * from half_year;


-- ── 1.5  Revenue Percentile Buckets (order value distribution) ─

with order_values as (
select o.order_id,sum(oi.quantity * oi.unit_price) as order_value from orders as o join order_items as oi on o.order_id=oi.order_id 
where o.status not in ('cancelled','refunded') group by 1)

select 
    CASE
        WHEN order_value <  50  THEN '< $50'
        WHEN order_value <  100 THEN '$50–$99'
        WHEN order_value <  200 THEN '$100–$199'
        WHEN order_value <  350 THEN '$200–$349'
        ELSE                         '$350+'
    END as order_bucket,
	count(*) as order_count,
	round(count(*)*100/sum(count(*)) over(),1) as pct_of_orders,
	round(sum(order_value)) as bucket_revenue,
	round(sum(order_value)*100.0/sum(sum(order_value)) over(),1) as pct_of_revenue
	from order_values
	group by order_bucket
	order by min(order_value);



-- ── 1.6  Rolling 7-Day Revenue (for trend smoothing) ─────────
with daily as (
select date(o.created_at) as order_date,
       count(distinct o.order_id) as orders,
	   sum(oi.quantity * oi.unit_price) as daily_revenue
	   from orders as o join order_items as oi on o.order_id = oi.order_id WHERE o.status NOT IN ('cancelled','refunded')
group by order_date)


select order_date,orders,daily_revenue ,
       round(avg(daily_revenue) over(order by order_date rows between 6 PRECEDING and current row),2) as rolling_7d_avg,
	   round(sum(daily_revenue) over(order by order_date rows between 6 preceding and current row),2) as rolling_7d_revenue
	   
from daily order by order_date;


















