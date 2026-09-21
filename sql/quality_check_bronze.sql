/*PURPOSE: To do Quality Check for all tables before inserting the data into silver layer */


/*Table 1: customers */
use olist_analytics;

--Check for duplicate customer_id
select customer_id, count(*) from bronze.olist_customers 
group by customer_id having count(*) >1 or customer_id is null;

select customer_id from bronze.olist_customers where len(customer_id)!= 32;

select customer_unique_id from bronze.olist_customers where len(customer_unique_id) !=32;

select customer_city from bronze.olist_customers where len(trim(customer_city)) != len(customer_city);

select * from bronze.olist_customers where customer_state is null;
select distinct customer_state from bronze.olist_customers;

/* Table 2: products */

SELECT product_id,
       product_category_name,
       product_name_length,
       product_description_length,
       product_photos_qty,
       product_weight_g,
       product_length_cm,
       product_height_cm,
       product_width_cm
  FROM bronze.olist_products where product_name_length is null 
  and product_description_length is null 
  and product_category_name is null;

--check for duplicate product_id
select product_id, count(*) from bronze.olist_products 
group by product_id having count(*) >1 or product_id is null;

select len(product_id) from bronze.olist_products;
SELECT COUNT(*) AS null_product_name_length
FROM bronze.olist_products
WHERE product_name_length IS NULL;
 select product_id from bronze.olist_products where len(product_id)!= 32;

  select distinct product_category_name from bronze.olist_products;

  select distinct product_category_name from bronze.olist_product_category_translation;

  select count(distinct product_category_name) from bronze.olist_products;

  select count(distinct product_category_name) from bronze.olist_product_category_translation;

SELECT DISTINCT p.product_category_name as pcat, t.product_category_name as tcat
FROM bronze.olist_products p
LEFT JOIN bronze.olist_product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name IS NULL; 

select product_id, product_name_length from bronze.olist_products 
where product_name_length <0 or product_name_length is null; 

select product_id, product_description_length from bronze.olist_products 
where product_description_length <0 or product_description_length is null; 

select * from bronze.olist_products
where product_weight_g <0 or product_weight_g is null or 
product_length_cm <0 or product_length_cm is null
or product_height_cm <0 or product_height_cm is null
or product_width_cm <0 or product_width_cm is null;

/*Table 3 product_category_translation */

select * from bronze.olist_product_category_translation 
where product_category_name_english is null;

/*Table 4: orders */
select * from bronze.olist_orders;

select distinct order_status from bronze.olist_orders;

select order_id, count(*) from bronze.olist_orders group by order_id
having count(*) >1 or order_id is null;

--Fk integrity check
select customer_id from bronze.olist_orders 
where customer_id not in (select customer_id from bronze.olist_customers);

--date sequence check
select order_id ,
order_status,
order_purchase_timestamp,
order_approved_at,
order_delivered_carrier_date,
order_delivered_customer_date,
order_estimated_delivery_date from bronze.olist_orders 
where (order_purchase_timestamp > order_approved_at and order_approved_at is not null)
(order_approved_at > order_delivered_carrier_date and order_approved_at is not null)
or (order_delivered_carrier_date >  order_delivered_customer_date and order_delivered_carrier_date is not null);

select order_id from bronze.olist_orders where 
order_purchase_timestamp > order_delivered_customer_date;

--flag 1 when order is wrong 
select order_id, 
order_approved_at,
order_delivered_carrier_date,
case 
when order_approved_at is not null 
and order_delivered_carrier_date is not null 
and order_approved_at > order_delivered_carrier_date then 1
else 0 
end flag
from bronze.olist_orders;

--null values
select order_id from bronze.olist_orders where 
order_purchase_timestamp is null;

select order_id,order_status from bronze.olist_orders where 
order_delivered_customer_date is null or order_purchase_timestamp is null;

/* Table 5: order_items */

select * from bronze.olist_order_items;

select order_id from bronze.olist_order_items 
where order_id not in (select order_id from bronze.olist_orders);

select len(order_id) from bronze.olist_order_items;
select  product_id from bronze.olist_order_items where len(product_id) !=32;

select order_id from bronze.olist_order_items where order_item_id <0;

select order_id, price from bronze.olist_order_items where price is null or price <0;
select order_id, freight_value from bronze.olist_order_items where 
freight_value is null or freight_value <0;

/*Table 6 order_reviews */
select * from bronze.olist_order_reviews;

select * from bronze.olist_order_reviews where review_id = '4219a80ab469e3fc9901437b73da3f75';

select review_id,
    count(*) AS row_count,
    count(DISTINCT order_id) AS distinct_orders
from bronze.olist_order_reviews group by review_id having COUNT(*) > 1;

select order_id from bronze.olist_order_reviews where order_id 
not in (select order_id from bronze.olist_orders);

select order_id from bronze.olist_order_reviews where order_id 
not in (select order_id from bronze.olist_order_items);

select min(review_score), max(review_score) from bronze.olist_order_reviews;

select * from bronze.olist_order_reviews where 
review_creation_date > review_answer_timestamp 
or review_creation_date  is null
or review_answer_timestamp is null;