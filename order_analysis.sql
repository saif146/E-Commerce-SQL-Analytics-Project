-- ============================================================
-- 04 · Order Funnel, Fulfillment & Operations
-- Dataset: 620 orders | 5 status types
-- ============================================================

-- ── 4.1  Order Status Funnel with Revenue Impact ─────────────
with order_totals as (
	select order_id ,
	       sum(unit_price * quantity) as order_value 
	from order_items 
	group by order_id
)


select o.status,
       count(o.order_id) as order_count,
	   round(count(o.order_id) *100.0/sum(count(o.order_id)) over(),1) as pct_of_orders,
	   round(sum(ot.order_value),2) as gross_value,
	   round(avg(ot.order_value),2) as avg_order_value
from orders as o 
join order_totals as ot 
	on o.order_id=ot.order_id 
group by o.status 
order by order_count desc;


-- ── 4.2  Monthly Cancellation & Refund Rate Trend ────────────

select to_char(created_at,'YYYY-MM') as month ,
       count(*) as total_orders,
	   sum(case when status='cancelled' then 1 else 0 end ) as cancelled,
	   sum(case when status='refunded' then 1 else 0 end ) as refunded,
	   round(sum(case when status='cancelled' then 1 else 0 end )*100.0/count(*),1) as cancel_rate_pct,
	   round(sum(case when status='refunded' then 1 else 0 end )*100.0/count(*),1) as refund_rate_pct,
	   round(avg(sum(case when status='cancelled' then 1 else 0 end )*100.0/count(*)) 
	   over(order by to_char(created_at,'YYYY-MM') rows between 2 PRECEDING and current row),1) as rolling_3mo_cancel_pct
	   
from orders group by month;


-- ── 4.3  Fulfillment SLA (service lavel agreement)Analysis ────────────────────────────
-- How long does it take to ship and deliver?
select * from orders
select 
      round(avg(extract(epoch from(shiped_at-created_at))/3600/24),1) as avg_days_to_ship,
	  round(percentile_cont(0.5) within group (order by extract(epoch from(shiped_at - created_at))/3600/24)) as median_days_to_ship,
	  round(avg(extract(epoch from(delivered_at-shiped_at))/3600/24),1) as avg_days_to_deliver,
	  round(percentile_cont(0.5) within group (order by extract(epoch from(delivered_at-shiped_at))/3600/24)) as median_days_to_deliver,
	  round(avg(extract(epoch from(delivered_at-created_at))/3600/24),1) as avg_end_to_end_days,
	  sum(case when extract(epoch from(delivered_at-created_at))/3600/24 >5 then 1 else 0 end) as sla_breaches,
	  round(sum(case when extract(epoch from(delivered_at-created_at))/3600/24 >5 then 1 else 0 end) *100.0/count(*),1) as breaches_rate_pct
from orders 
where status ='completed' and shiped_at is not null and delivered_at is not null;

-- ── 4.4  Multi-Item Order Analysis ───────────────────────────
-- Orders with 2+ items tend to have higher value; quantify this

select * from order_items


with order_summary as (
select o.order_id,
       c.first_name||' '||c.last_name as customer,
	   count(oi.order_item_id) as item_count,
	   sum(oi.quantity) as total_units,
	   round(sum(oi.quantity * oi.unit_price)) as order_total
	   
from orders as o join customers as c on o.customer_id=c.customer_id
join order_items as oi on oi.order_id =o.order_id
WHERE o.status NOT IN ('cancelled','refunded')
group by o.order_id,customer
)


select  item_count as distinct_product,
        count(order_id) as orders,
		round(count(order_id) * 100.0/sum(count(*)) over(),1) as pct_orders,
		round(avg(order_total),1) as avg_order_value,
		round(sum(order_total)) as total_revenue,
		round(sum(order_total)*100.0/sum(sum(order_total)) over(),1) as pct_revenue
        
from order_summary
group by item_count
order by item_count;
-- Key insight: 2-item orders = 37.4% of orders but 37% of revenue


-- ── 4.5  Day-of-Week & Hour-of-Day Order Patterns ────────────

select to_char(created_at,'day') as day_of_week,
       extract(dow from created_at) as dow_num,
	   count(*) as orders,
	   round(count(*)*100/sum(count(*))over(),1) as pct,
	   round(avg(ot.order_value),1) as avg_order_value
from orders as o join(
select order_id,sum(quantity * unit_price) as order_value from order_items group by order_id
) as ot on ot.order_id=o.order_id
WHERE o.status NOT IN ('cancelled','refunded')
group by 1,2
order by 2;



-- ── 4.6  Rolling 7-Day Revenue with Anomaly Detection ────────

with daily_rev as (
select date(o.created_at) as order_date,
       sum(quantity * unit_price) as daily_revenue
from orders as o 
join order_items as oi 
	on o.order_id=oi.order_id
WHERE o.status NOT IN ('cancelled','refunded')
group by date(o.created_at)
),
rolling as (
select
	order_date,
	daily_revenue,
	round(avg(daily_revenue) over(order by order_date rows between 6 preceding and current row),2) as rolling_7d_avg,
	round(stddev(daily_revenue) over(order by order_date rows between 6 preceding and current row),2) as rolling_7d_stddev,
	round(sum(daily_revenue) over(order by order_date rows between 6 preceding and current row),2) as cumulative_revenue
from daily_rev
 
)

select order_date,
       daily_revenue,
	   rolling_7d_avg,
	   round((daily_revenue -rolling_7d_avg)/nullif(rolling_7d_avg,0),2) as z_score,
	   case when (daily_revenue -rolling_7d_avg)/nullif(rolling_7d_avg,0)>2  THEN '📈 Spike'
	        when (daily_revenue -rolling_7d_avg)/nullif(rolling_7d_avg,0)<-2  THEN '📉 Dip'
			else 'Normal'
	   end as anomaly_flag,
	   cumulative_revenue
from rolling
order by order_date;
				
-- ── 4.7  Customer Reorder Gap (avg days between purchases) ───            
with ordered as (
select customer_id,
       created_at,
	   lag(created_at) over(partition by customer_id order by created_at) as prev_order_date 
from orders WHERE status NOT IN ('cancelled','refunded')
),
gaps as (
select customer_id,
       round(extract(epoch from(created_at - prev_order_date))/3600/24,1) as days_between
from ordered
where prev_order_date is not null
)

select round(avg(days_between),1) as average_days_between_orders,
       round(percentile_cont(0.25) within group(order by days_between)) as p25_days,
	   round(percentile_cont(0.5) within group(order by days_between)) as p50_days,
	   round(percentile_cont(0.75) within group(order by days_between)) as p75_days,
	   count(*) as repeat_purchase_events
	   from gaps;





















































