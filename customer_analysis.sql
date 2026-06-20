-- ============================================================
-- 02 · Customer Analysis — LTV, RFM, Retention Cohorts
-- Dataset: 200 customers | 18-month window
-- ============================================================


--2.1  Top 10 Customers by Lifetime Value ──────────────────
select * from customers;
select * from orders;
select * from order_items;

select c.customer_id,
       c.first_name || ' '||c.last_name    as customer_name,
	   count(distinct o.order_id)          as total_orders,
	   sum(oi.quantity)                    as total_units,
	   sum(oi.unit_price * oi.quantity)    as lifetime_value,
	   round(avg(order_totals.order_value))as avg_order_value,
	   min(o.created_at)::date             as first_order,
	   max(o.created_at)::date             as last_order
	 
	   
from orders as o 
join order_items as oi 
     on oi.order_id = o.order_id 
join customers as c 
     on o.customer_id = c.customer_id 
join(
      select order_id,
	          sum(quantity * unit_price) as order_value 
      from order_items 
      group by order_id
) as order_totals on order_totals.order_id = o.order_id
WHERE o.status NOT IN ('cancelled','refunded')
group by 
1,2,c.country order by 5 
desc limit 10;



-- ── 2.2  RFM Segmentation ─────────────────────────────────────
-- Recency · Frequency · Monetary — score each customer 1–5
-- then bucket into actionable segments

with rfm_base as (
     select o.customer_id,
        max(o.created_at)                                as last_order_date,
	    count(distinct o.order_id)                       as frequency,
	    round(sum(oi.quantity * oi.unit_price),2)        as monetary
    from orders as o 
    join order_items as oi 
        on o.order_id=oi.order_id 
	WHERE o.status NOT IN ('cancelled','refunded')
    group by o.customer_id
),
rfm_score as (
select customer_id,
       last_order_date,
	   frequency,
	   monetary,
       ntile(5) over(order by last_order_date desc)  as r_score,
	   ntile(5) over(order by frequency asc)         as f_score,
	   ntile(5) over(order by monetary asc)          as m_score
	   from rfm_base
),
rfm_segments as(
select customer_id,
       r_score,
	   f_score,
	   m_score,
	   (r_score+f_score+m_score) as rfm_total,
	   case 
	       when r_score>=4 and f_score>=4 and m_score>=4 then 'champions'
		   when r_score>=3 and f_score>=3                then 'Loyal Customers'
		   when r_score>=4 and f_score <=2               then 'recent customers'
		   when r_score<=2 and f_score>=3                then 'At-risk'
		   when r_score=1                                then 'Lost'
		   else 'potential Loyalities'
	  end as segment

	  from rfm_score
)



select segment,
       count(*) as customers,
       round(avg(rfm_total),1) as avg_rfm_score,
	   round(count(*) * 100/sum(count(*)) over(),1) as pct_of_base
from rfm_segments 
group by segment
order by avg_rfm_score desc;



-- ── 2.3  Revenue by Country with Avg LTV ─────────────────────

select c.country,
      count(distinct c.customer_id) as customers,
	  count(distinct o.order_id) as orders,
	  round(sum(oi.quantity * oi.unit_price),2) as total_revenue,
	  round(sum(oi.quantity * oi.unit_price) / count(distinct c.customer_id),2) as avg_ltv_per_customers,
	  round(avg(order_val.order_value),2) as avg_order_value
      
from customers as c 
join orders as o 
     on o.customer_id = c.customer_id 
join order_items as oi 
     on o.order_id = oi.order_id 
join(
select order_id,sum(quantity * unit_price) as order_value from order_items group by order_id
) as order_val 
  on order_val.order_id=o.order_id
WHERE o.status NOT IN ('cancelled','refunded')
group by c.country
order by total_revenue desc;


-- ── 2.4  Repeat vs One-Time Buyers with Revenue Share ────────
with customer_orders as (
		select customer_id,
		       count(order_id) as order_count,
			   sum(order_value) as total_spend
		from (
		select o.customer_id,
		       o.order_id,
			   sum(oi.quantity * oi.unit_price) as order_value 
		from orders as o 
		join order_items as oi 
		     on o.order_id=oi.order_id 
		WHERE o.status NOT IN ('cancelled','refunded')
		group by o.customer_id,o.order_id
) t
		group by customer_id
),

segments as (
		select * ,
		case 
		    when order_count=1 then 'one_time_buyer'
			when order_count between 2 and 3 then 'Repeat Buyer'
			else 'Loyal Customers(4+)'
		end as segment
		from customer_orders
)

select segment,
       count(*) as customers,
	   round(avg(order_count),1) as avg_orders,
	   round(avg(total_spend),1) as avg_spend,
	   round(sum(total_spend),2) as segment_revenue,
	   round(sum(total_spend)*100 /sum(sum(total_spend)) over(),1) as revenue_pct
from segments 
group by segment
order by avg_orders;


-- ── 2.5  Monthly Cohort Retention (signup month → subsequent orders) ─

with cohorts as (
		select customer_id,
		       date_trunc('month',created_at) as cohort_month 
		from customers
),

purchase as (
		  select distinct o.customer_id,
		                  date_trunc('month',o.created_at) as purchase_month
		  from orders as o
		  WHERE o.status NOT IN ('cancelled','refunded')
),

cohort_data as (
		select  c.cohort_month,
		        extract(month from age(p.purchase_month,c.cohort_month))::int  as months_since_signup,
				count(distinct c.customer_id) as active_customers
		from cohorts as c 
		left join purchase as p 
		     on c.customer_id=p.customer_id 
			 and p.purchase_month>= c.cohort_month
		group by c.cohort_month,months_since_signup
),

cohort_size as (
		select cohort_month,count(*) as cohort_size
		from cohorts 
		group by cohort_month
)

select to_char(cd.cohort_month,'YYYY-MM') as cohort,
       cs.cohort_size,
	   cd.months_since_signup as month_number,
	   cd.active_customers,
	   round(cd.active_customers *100.0 /cs.cohort_size,1) as retention_pct from 
cohort_data as cd join cohort_size as cs on cd.cohort_month=cs.cohort_month 
where cd.months_since_signup between 0 and 5 
order by cd.cohort_month,cd.months_since_signup;




-- ── 2.6  Customer Purchase Frequency Distribution ─────────────

with order_counts as (
select o.customer_id,
       count(o.order_id) as n_orders 
from orders as o
WHERE o.status NOT IN ('cancelled','refunded') 
group by  1)

select n_orders,
       count(*) as customers,
	   round(count(*) * 100.0 /sum(count(*)) over(),1) as pct,
	   sum(count(*)) over(order by n_orders) as cumulative_customers
from order_counts group by n_orders order by n_orders;

