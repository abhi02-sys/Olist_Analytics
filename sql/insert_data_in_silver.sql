/* PURPOSE: To insert data into silver layer after data quality check, transformations and
standardization done */

use olist_analytics;

--Table customers

insert into silver.olist_customers (
customer_id,
customer_unique_id,
customer_zip_code_prefix,
customer_city,
customer_state
)
select 
customer_id,
customer_unique_id,
customer_zip_code_prefix,
customer_city,
customer_state
from bronze.olist_customers;

select count(*) from bronze.olist_customers;
select count(*) from bronze.olist_customers;

--Table products
INSERT INTO silver.olist_products
(
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM bronze.olist_products;

select count(*) from bronze.olist_products;
select count(*) from silver.olist_products;

--Table product_category_translation
insert into silver.olist_product_category_translation (
product_category_name,
product_category_name_english
)
select product_category_name,
product_category_name_english
from bronze.olist_product_category_translation;

select count(*) from bronze.olist_product_category_translation;
select count(*) from silver.olist_product_category_translation;

--Table orders

insert into silver.olist_orders (
order_id ,
customer_id,
order_status,
order_purchase_timestamp,
order_approved_at,
order_delivered_carrier_date,
order_delivered_customer_date,
order_estimated_delivery_date,
flag_approval_after_delivery_carrier,
flag_carrier_after_delivery,
delivered_missing_customer_date
)
select 
order_id ,
customer_id,
order_status,
order_purchase_timestamp,
order_approved_at,
order_delivered_carrier_date,
order_delivered_customer_date,
order_estimated_delivery_date,
case when order_approved_at > order_delivered_carrier_date then 1 
else 0 
end flag_approval_after_delivery_carrier,
case when order_delivered_carrier_date > order_delivered_customer_date then 1 
else 0 
end flag_carrier_after_delivery,
case 
when order_status = 'delivered' and order_delivered_customer_date is null 
then 1
else 0 
end delivered_missing_customer_date
from bronze.olist_orders;

select count(*) from silver.olist_orders;
select * from silver.olist_orders;

--Table order_items
insert into silver.olist_order_items(
order_id,
order_item_id,
product_id,
seller_id,
shipping_limit_date,
price,
freight_value 
)
select
order_id,
order_item_id,
product_id,
seller_id,
shipping_limit_date,
price,
freight_value 
from bronze.olist_order_items;

select count(*) from bronze.olist_order_items;
select count(*) from silver.olist_order_items;

--Table order_reviews
insert into silver.olist_order_reviews(
review_id,
order_id,
review_score,
review_comment_title,
review_comment_message,
review_creation_date,
review_answer_timestamp
)
select 
review_id,
order_id,
review_score,
review_comment_title,
review_comment_message,
review_creation_date,
review_answer_timestamp
from bronze.olist_order_reviews;

select count(*) from bronze.olist_order_reviews;
select count(*) from silver.olist_order_reviews;

