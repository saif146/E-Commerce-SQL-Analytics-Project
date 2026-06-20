-- ============================================================
-- 03 · Product Analysis — Performance, Ratings & Market Basket
-- Dataset: 30 products across 6 categories
-- ============================================================

-- ── 3.1  Product Leaderboard (units, revenue, margin rank) ───



with product_stats as (
	select p.product_id,
	       p.name as product,
		   c.name as category,
		   p.price as list_price,
		   p.stock as current_stock,
		   sum(oi.quantity) as units_sold,
		   sum(oi.quantity * oi.unit_price) as revenue,
		   round(avg(oi.unit_price),1) as avg_sell_price,
		   count(distinct oi.order_id) as times_ordered
	from products as p 
	join order_items as oi 
		on oi.product_id = p.product_id 
	join orders as o 
		on o.order_id = oi.order_id 
	join categories as c 
		on c.category_id = p.category_id
	WHERE o.status NOT IN ('cancelled','refunded')
	group by 1,2,3,4
)

select product,
       category,
	   list_price,
	   units_sold,
	   revenue,
	   avg_sell_price,
	   -- price varience avg vs list_price
	   round((avg_sell_price - list_price)/list_price *100,1) as price_varience_pct,
	   current_stock,
	   rank() over(order by revenue desc) as revenue_rank,
	   rank() over(order by units_sold) as units_rank,
	   ntile(4) over(order by revenue desc) as revenue_quartile
from product_stats
order by revenue desc;
	   


-- ── 3.2  Category-Level Product Performance Benchmarks ───────

with product_rev as (
	select p.product_id,
	       p.name as product,
		   c.name as category,
		   sum(oi.quantity) as units_sold,
		   sum(oi.quantity * oi.unit_price) as revenue
		
	from products as p 
	join order_items as oi 
		on oi.product_id = p.product_id 
	join orders as o 
		on o.order_id = oi.order_id 
	join categories as c 
		on c.category_id = p.category_id
	WHERE o.status NOT IN ('cancelled','refunded')
	group by 1,2,3
)


select product,
       category,
	   revenue,
	   units_sold,
	   round(avg(revenue) over(partition by category),2) as catgeory_avg_revenue,
	   round(revenue-avg(revenue) over(partition by category),2) as vs_category_avg,
	   rank() over(partition by category order by revenue desc) as rank_in_catgory
	  
from product_rev
order by category,revenue desc;



-- ── 3.3  Product Ratings & Review Analysis ───────────────────
select * from reviews;

select p.name as product,
       c.name as category,
	   count(r.review_id) as review_count,
	   round(avg(r.rating),2) as avg_rating,
	   sum(case when r.rating=5  then 1 else 0 end) as five_star,
	   sum(case when r.rating=4  then 1 else 0 end) as four_star,
	   sum(case when r.rating=3  then 1 else 0 end) as three_star,
	   sum(case when r.rating<=2  then 1 else 0 end) as low_rating,
	   count(distinct o.order_id) as times_ordered,
	   round(count(r.review_id)::numeric /nullif( count(distinct oi.order_id),0)*100,1) as review_pct
from products as p 
join categories as c 
	on p.category_id=c.category_id
left join order_items as oi 
	on oi.product_id = p.product_id 
left join orders as o 
	on o.order_id = oi.order_id and o.status not in ('cancelled','refunded')
left join reviews as r 
	on r.product_id = p.product_id
group by p.product_id,p.name,c.name
order by avg_rating desc,review_count desc;


-- ── 3.4  Low-Stock Alert with Velocity (days of stock remaining) ─
with sales_velocity as (
select oi.product_id,
       sum(oi.quantity) as units_sold_90d,
	   sum(oi.quantity)/90.0 as daily_velocity
from order_items as oi 
join orders as o 
on oi.order_id =o.order_id 
where  o.status NOT IN ('cancelled','refunded') 
       and 
	   o.created_at> current_date -interval '90 days'
group by oi.product_id )



select p.product_id,
       p.name,
	   c.name as category,
	   p.stock,
	   p.price,
	   round(sv.daily_velocity,2) as units_per_day,
	   round(p.stock /nullif(sv.daily_velocity,0)) as days_of_stock_remaining,
	   case 
	       when p.stock/nullif(sv.daily_velocity,0) <14 then '🔴 Critical'
		   WHEN p.stock / NULLIF(sv.daily_velocity, 0) < 30 THEN '🟡 Low'
		   ELSE '🟢 OK'
	  end as stock_status
		   
from products as p 
join categories as c 
	on p.category_id=c.category_id 
left join sales_velocity as sv 
	on sv.product_id=p.product_id
where p.stock<100 
order by days_of_stock_remaining nulls last;



-- ── 3.5  Market Basket Analysis (Products Bought Together) ───
-- Finds the most commonly co-purchased product pairs



select * from orders;
with baskets as (
select a.order_id,
       a.product_id as product_a,
	   b.product_id as product_b
from order_items as a 
join order_items as b 
	on a.order_id=b.order_id 
	and b.product_id>a.product_id --avoid duplicates
join orders as o 
	on o.order_id=a.order_id
WHERE o.status NOT IN ('cancelled','refunded')
),
pair_count as (
select product_a,
       product_b,
	   count(*) as co_purchase 
from baskets group by 1,2
),
product_order_counts as (
select oi.product_id as product_id ,
       count(distinct oi.order_id) as order_count
	   from order_items as oi 
	   join orders as o 
	       on o.order_id = oi.order_id
	   where o.status NOT IN ('cancelled','refunded')
	   group by oi.product_id
)

select pa.name as product_a,
       pb.name as product_b,
	   pc.co_purchase,
	   round(pc.co_purchase *100 / (oa.order_count +ob.order_count),1) as support_pct
	   
from pair_count as pc 
join products as pa 
	on pc.product_a=pa.product_id 
join products as pb 
	on pc.product_b=pb.product_id
join product_order_counts as oa 
	on oa.product_id=pc.product_a
join product_order_counts as ob 
	on ob.product_id=pc.product_b
order by 3 desc limit 15;





















































































