/*
PURPOSE: To test hypotheses formulated around the business problem and create analytical views
for customer repeat status, first-order price bands, delivery performance, and other retention factors.
*/


use olist_analytics;

SELECT COUNT(*) FROM gold.dim_customers c
WHERE NOT EXISTS (SELECT 1 FROM gold.dim_orders o WHERE o.customer_id = c.customer_id);

select *  from gold.dim_customers;
select * from gold.dim_orders;
select * from gold.customer_repeat_status;
select * from gold.fact_order_items

/* KPI's */
--Total customers
select count(distinct customer_unique_id) from gold.dim_customers;

--Total customers with delivered orders
select
count(distinct c.customer_unique_id)
from gold.dim_customers c 
left join gold.dim_orders o 
on c.customer_id = o.customer_id 
where order_status = 'delivered'

--repeat cust count 
select count(*) 
from gold.customer_repeat_status where order_descript = 'repeated'
--one-time cust
select count(*) 
from gold.customer_repeat_status where order_descript = 'ordered_once'

--aov
with price_cte as(
select oi.order_id, sum(oi.price) as total_price from 
gold.fact_order_items oi 
join gold.dim_orders o
on oi.order_id = o.order_id 
where o.order_status = 'delivered'
group by oi.order_id
)
select avg(total_price) from price_cte;

--seg by order_status
select order_status, count(order_id) from gold.dim_orders group by order_status;

--total delivered orders
select count(order_id) from gold.dim_orders where order_status = 'delivered'

--seg by order_descript
select 
order_descript,
count(*) as total_customers,
min(order_count) as min_orders,
max(order_count) as max_orders
from gold.customer_repeat_status 
group by order_descript;

--view as per repeat_status
CREATE VIEW gold.customer_repeat_status AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS order_count,
        CASE WHEN COUNT(o.order_id) > 1 THEN 'repeated' ELSE 'ordered_once' END AS order_descript
    FROM gold.dim_customers c
    JOIN gold.dim_orders o 
        ON c.customer_id = o.customer_id 
        AND o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

--all orders by order status n descript
with cte1 as(
select 
c.customer_unique_id,
count(o.order_id) as order_count,
o.order_status,
case when count(o.order_id) > 1 then 'repeated'
	else 'ordered_once'
	end as order_descript
from gold.dim_customers c
left join gold.dim_orders o 
on c.customer_id = o.customer_id 
--and o.order_status = 'delivered'
group by c.customer_unique_id, o.order_status 
)
select
order_status,
order_descript,
count(*) as cnt
from cte1 group by order_status, order_descript
order by order_status, order_descript

--customer repeat percentage
select 
order_descript,
count(*) as customer_count,
round(count(*) * 100.0/ sum(count(*)) over(),2) as percent_customer
from gold.customer_repeat_status
group by order_descript;

--frequency of repetition by customer count
select 
order_count,
count(customer_unique_id) as cust_count,
round(count(*) * 100.0 /sum(count(*)) over(),2) as percent_repetition
from gold.customer_repeat_status 
where order_descript = 'repeated'
group by order_count order by cust_count desc;

/* cohort analysis */
create view gold.cohort_retention as
with cust_order_month as(
select 
c.customer_unique_id,
datefromparts(year(o.order_purchase_timestamp), month(o.order_purchase_timestamp),1) as order_month,
crs.order_descript
 from gold.dim_orders o
 join gold.dim_customers c
on o.customer_id = c.customer_id
join gold.customer_repeat_status crs 
on c.customer_unique_id = crs.customer_unique_id
where o.order_status = 'delivered'
),
cohort_month_cte as(
select
customer_unique_id,
min(order_month) as cohort_month
from cust_order_month
group by customer_unique_id
),
cohort_size as( --No. of customers started in particular month
select count(*) as cust_count,
cohort_month
from cohort_month_cte
group by cohort_month
),
cohort_order_month as(
select 
cm.customer_unique_id,
cm.cohort_month,
om.order_month,
datediff(month,cm.cohort_month, om.order_month) as month_number
from cohort_month_cte cm 
join cust_order_month om 
on cm.customer_unique_id = om.customer_unique_id
),
activity as(
select 
cohort_month,
month_number,
count(distinct customer_unique_id) as cust_cnt
from cohort_order_month 
group by cohort_month, month_number
)
SELECT 
    a.cohort_month,
    a.month_number,
    a.cust_cnt,
    cs.cust_count AS total,

    ROUND(a.cust_cnt * 100.0 / cs.cust_count, 2) AS retention_pct
FROM activity a 
JOIN cohort_size cs
    ON a.cohort_month = cs.cohort_month
--ORDER BY 
    --a.cohort_month,
    --a.month_number;

/*Difference between first and second delivered order */
CREATE VIEW gold.customer_second_order_summary AS
WITH order_time_diff AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp AS first_order,
        LEAD(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS next_order,
        DATEDIFF(day, o.order_purchase_timestamp, 
            LEAD(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp)
        ) AS diff_between_orders,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC) AS rn
    FROM gold.dim_orders o
    JOIN gold.dim_customers c ON o.customer_id = c.customer_id
    JOIN gold.customer_repeat_status crs ON c.customer_unique_id = crs.customer_unique_id
    WHERE crs.order_descript = 'repeated' AND o.order_status = 'delivered'
),
filtered AS (
    SELECT diff_between_orders
    FROM order_time_diff
    WHERE next_order IS NOT NULL AND rn = 1
)
SELECT DISTINCT
    AVG(diff_between_orders) OVER () AS avg_diff_bw_2_orders,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY diff_between_orders) OVER () AS median_days
FROM filtered;

--Time-bucket to second order having 2+ orders
create view gold.second_order_timing as
WITH order_time_diff AS (
    SELECT 
        c.customer_unique_id,
        o.order_purchase_timestamp AS first_order,
        LEAD(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp) AS next_order,
        DATEDIFF(day, o.order_purchase_timestamp, 
            LEAD(o.order_purchase_timestamp) OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp)
        ) AS diff_between_orders,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC) AS rn
    FROM gold.dim_orders o
    JOIN gold.dim_customers c ON o.customer_id = c.customer_id
    JOIN gold.customer_repeat_status crs ON c.customer_unique_id = crs.customer_unique_id
    WHERE crs.order_descript = 'repeated' AND o.order_status = 'delivered'
),
filtered AS (
    SELECT diff_between_orders,
    case when diff_between_orders <=30 then '0-30 days'
         when diff_between_orders <=60 then '31-60 days'
         when diff_between_orders <= 90 then '61-90 days'
         when diff_between_orders <= 180 then '91-180 days'
         else '181+ days'
    end as time_bucket
    FROM order_time_diff
    WHERE next_order IS NOT NULL AND rn = 1
)
SELECT 
    time_bucket,
    count(*) as customer_count,
      ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM filtered group by time_bucket 
--order by 
--case when time_bucket = '0-30 days' then 1
         --when time_bucket = '31-60 days' then 2
         --when time_bucket =  '61-90 days' then 3
         --when time_bucket ='91-180 days' then 4
         --else 5
         --end;

/* Delivery timeline Analysis */
--1. avg delivery time
WITH first_delivered_order AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.delivery_days,
        o.delivery_delay_days,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS rn
    FROM gold.dim_customers c
    JOIN gold.dim_orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
)
SELECT
    crs.order_descript,
    AVG(fdo.delivery_days) AS avg_delivery_days,
    AVG(fdo.delivery_delay_days) AS avg_delivery_delay_days,
    COUNT(*) AS customer_count
FROM gold.customer_repeat_status crs
JOIN first_delivered_order fdo 
    ON crs.customer_unique_id = fdo.customer_unique_id 
    AND fdo.rn = 1
GROUP BY crs.order_descript;


-- 2. Categorizing delivery timeline
create view gold.delivery_category_retention as
with first_order_cte as(
select 
c.customer_unique_id,
crs.order_descript,
o.order_purchase_timestamp,
o.order_delivered_customer_date,
o.delivery_days,
o.delivery_delay_days,
--o.delivery_delay_days,
case when o.delivery_delay_days = 0 then 'on-time'
     when o.delivery_delay_days < 0 then 'delivered-early'
     when o.delivery_delay_days > 0 then 'delivered-late' 
     else null
     end as delivery_category,
     row_number() over(partition by c.customer_unique_id order by order_purchase_timestamp asc) as rn
from gold.dim_orders o 
join gold.dim_customers c 
on o.customer_id = c.customer_id
join gold.customer_repeat_status crs
on c.customer_unique_id = crs.customer_unique_id
where order_status = 'delivered'
)
select 
delivery_category,

count(*) as cust_cnt,
sum(case 
    when order_descript = 'repeated' then 1 
    else 0
    end) as repeat_customers,
round(100.0 * sum(case 
    when  order_descript = 'repeated' then 1 
    else 0 end) / COUNT(*), 2) as repeat_rate
from first_order_cte 
where rn = 1 
group by delivery_category;

/* Review Score Analysis */
--avg review score by order descript

with order_review_cte as(
select 
c.customer_unique_id,
o.order_status,
orv.review_score,
crs.order_descript,
o.order_purchase_timestamp,
row_number() over(partition by c.customer_unique_id order by o.order_purchase_timestamp asc) as rn
from gold.fact_order_reviews orv
join gold.dim_orders o on orv.order_id = o.order_id
join gold.dim_customers c on o.customer_id = c.customer_id
join gold.customer_repeat_status crs on c.customer_unique_id = crs.customer_unique_id
where o.order_status = 'delivered'
)
select 
order_descript,
ROUND(AVG(CAST(review_score AS DECIMAL(10,4))), 2) AS avg_review,
count(*) as customer_count
from order_review_cte
where rn = 1
group by order_descript;

--review score distribution

create view gold.review_score_retention as

with order_review_cte as(
select 
c.customer_unique_id,
o.order_status,
orv.review_score,
crs.order_descript,
o.order_purchase_timestamp,
row_number() over(partition by c.customer_unique_id order by o.order_purchase_timestamp asc) as rn
from gold.fact_order_reviews orv
join gold.dim_orders o on orv.order_id = o.order_id
join gold.dim_customers c on o.customer_id = c.customer_id
join gold.customer_repeat_status crs on c.customer_unique_id = crs.customer_unique_id
where o.order_status = 'delivered'
)
SELECT
    review_score,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_descript = 'repeated' THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
        SUM(CASE WHEN order_descript = 'repeated' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS repeat_rate
FROM order_review_cte
WHERE rn = 1
GROUP BY review_score
--ORDER BY review_score;


/* Price & Freight Analysis */
--Min,Max price n freight 

select min(price) as min_price,
max(price) as max_price,
min(freight_value) as min_freight,
max(freight_value) as max_freight
from gold.fact_order_items

--avg price n freight 
WITH first_order_cte AS (
    SELECT 
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(CAST(oi.price AS DECIMAL(10,2))) AS order_price,
        SUM(CAST(oi.freight_value AS DECIMAL(10,2))) AS order_freight,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS rn
    FROM gold.fact_order_items oi
    JOIN gold.dim_orders o 
        ON oi.order_id = o.order_id
    JOIN gold.dim_customers c 
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY 
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
)
SELECT 
    crs.order_descript,
    ROUND(AVG(foc.order_price), 2) AS avg_price,
    ROUND(AVG(foc.order_freight), 2) AS avg_freight,
    COUNT(*) AS customer_count
FROM gold.customer_repeat_status crs
JOIN first_order_cte foc 
    ON crs.customer_unique_id = foc.customer_unique_id
WHERE foc.rn = 1
GROUP BY crs.order_descript;

-- first order price band n repeat_rate

CREATE VIEW gold.price_band_retention AS

WITH first_order_cte AS (
    SELECT 
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,

        SUM(CAST(oi.price AS DECIMAL(10,2))) AS order_price,

        SUM(CAST(oi.freight_value AS DECIMAL(10,2))) AS order_freight,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id 
            ORDER BY o.order_purchase_timestamp ASC
        ) AS rn

    FROM gold.fact_order_items oi

    JOIN gold.dim_orders o 
        ON oi.order_id = o.order_id

    JOIN gold.dim_customers c 
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY 
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp
),

price_bands AS (
    SELECT
        customer_unique_id,
        order_price,

        CASE
            WHEN order_price < 100 THEN '< 100'
            WHEN order_price < 250 THEN '100–249'
            WHEN order_price < 500 THEN '250–499'
            WHEN order_price < 1000 THEN '500–999'
            WHEN order_price < 2000 THEN '1000–1999'
            ELSE '2000+'
        END AS price_band,

        CASE
            WHEN order_price < 100 THEN 1
            WHEN order_price < 250 THEN 2
            WHEN order_price < 500 THEN 3
            WHEN order_price < 1000 THEN 4
            WHEN order_price < 2000 THEN 5
            ELSE 6
        END AS price_band_order

    FROM first_order_cte

    WHERE rn = 1
)

SELECT
    pb.price_band,
    pb.price_band_order,

    COUNT(*) AS customer_count,

    SUM(
        CASE 
            WHEN crs.order_descript = 'repeated' THEN 1
            ELSE 0
        END
    ) AS repeat_customers,

    ROUND(
        SUM(
            CASE 
                WHEN crs.order_descript = 'repeated' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS repeat_rate

FROM price_bands pb

JOIN gold.customer_repeat_status crs
    ON pb.customer_unique_id = crs.customer_unique_id

GROUP BY 
    pb.price_band,
    pb.price_band_order;


-- avg freight %age 
WITH first_order_cte AS (
    SELECT 
        o.order_id,
        c.customer_unique_id,
        o.order_purchase_timestamp,
        SUM(CAST(oi.price AS DECIMAL(10,2))) AS order_price,
        SUM(CAST(oi.freight_value AS DECIMAL(10,2))) AS order_freight,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC) AS rn
    FROM gold.fact_order_items oi
    JOIN gold.dim_orders o ON oi.order_id = o.order_id
    JOIN gold.dim_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_unique_id, o.order_purchase_timestamp
),
first_order_freight_pct AS (
    SELECT 
        customer_unique_id,
        order_price,
        order_freight,
        ROUND(order_freight / order_price * 100, 2) AS freight_percentage
    FROM first_order_cte
    WHERE rn = 1 AND order_price > 0
)
SELECT 
    crs.order_descript,
    ROUND(AVG(fofp.freight_percentage), 2) AS avg_freight_pct,
    COUNT(*) AS customer_count
FROM gold.customer_repeat_status crs
JOIN first_order_freight_pct fofp ON crs.customer_unique_id = fofp.customer_unique_id
GROUP BY crs.order_descript;

--freight band effect on repeat percent
--freight as percentage of order value 

create view gold.freight_band_retention as 
WITH first_order_cte AS (
    SELECT 
        o.order_id,
        c.customer_unique_id,
        SUM(CAST(oi.price AS DECIMAL(10,2))) AS order_price,
        SUM(CAST(oi.freight_value AS DECIMAL(10,2))) AS order_freight,
        ROW_NUMBER() OVER (PARTITION BY c.customer_unique_id ORDER BY o.order_purchase_timestamp ASC) AS rn
    FROM gold.fact_order_items oi
    JOIN gold.dim_orders o ON oi.order_id = o.order_id
    JOIN gold.dim_customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.order_id, c.customer_unique_id, o.order_purchase_timestamp
),
freight_bands AS (
    SELECT 
        customer_unique_id,
        ROUND(order_freight / order_price * 100, 2) AS freight_percentage,
        CASE 
            WHEN order_freight / order_price * 100 < 5 THEN '<5%'
            WHEN order_freight / order_price * 100 < 10 THEN '5-10%'
            WHEN order_freight / order_price * 100 < 20 THEN '10-20%'
            WHEN order_freight / order_price * 100 < 30 THEN '20-30%'
            WHEN order_freight / order_price * 100 < 50 THEN '30-50%'
            ELSE '50%+'
        END AS freight_band
    FROM first_order_cte
    WHERE rn = 1 AND order_price > 0
)
SELECT 
    fb.freight_band,
    COUNT(*) AS customer_count,
    SUM(CASE WHEN crs.order_descript = 'repeated' THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(SUM(CASE WHEN crs.order_descript = 'repeated' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS repeat_rate
FROM freight_bands fb
JOIN gold.customer_repeat_status crs ON fb.customer_unique_id = crs.customer_unique_id
GROUP BY fb.freight_band
/*ORDER BY 
    CASE fb.freight_band
        WHEN '<5%' THEN 1 WHEN '5-10%' THEN 2 WHEN '10-20%' THEN 3
        WHEN '20-30%' THEN 4 WHEN '30-50%' THEN 5 ELSE 6
    END;*/

/* Product Category */

CREATE VIEW gold.first_order_category_retention AS

WITH first_order AS (
    SELECT
        c.customer_unique_id,
        o.order_id,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp ASC
        ) AS rn

    FROM gold.dim_orders o

    JOIN gold.dim_customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'
),

first_order_categories AS (
    SELECT DISTINCT
        fo.customer_unique_id,
        p.category

    FROM first_order fo

    JOIN gold.fact_order_items oi
        ON fo.order_id = oi.order_id

    JOIN gold.dim_products p
        ON oi.product_id = p.product_id

    WHERE fo.rn = 1
)

SELECT
    foc.category,

    COUNT(DISTINCT foc.customer_unique_id) AS customer_count,

    COUNT(DISTINCT CASE
        WHEN crs.order_descript = 'repeated'
        THEN foc.customer_unique_id
    END) AS repeat_customers,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN crs.order_descript = 'repeated'
            THEN foc.customer_unique_id
        END) * 100.0
        / COUNT(DISTINCT foc.customer_unique_id),
        2
    ) AS repeat_rate

FROM first_order_categories foc

JOIN gold.customer_repeat_status crs
    ON foc.customer_unique_id = crs.customer_unique_id

WHERE foc.category IS NOT NULL

GROUP BY foc.category;
