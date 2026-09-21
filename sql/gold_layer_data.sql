/* PURPOSE: Transform cleaned Silver data into business-ready Gold fact and dimension tables.*/

select * from silver.olist_customers;

/* Customers */
create view gold.dim_customers as
select 
row_number() over(order by customer_id) as customer_key,
customer_id,
customer_unique_id,
customer_city,
customer_state as customer_state_code,
CASE customer_state
    WHEN 'AC' THEN 'Acre'
    WHEN 'AL' THEN 'Alagoas'
    WHEN 'AP' THEN 'Amapá'
    WHEN 'AM' THEN 'Amazonas'
    WHEN 'BA' THEN 'Bahia'
    WHEN 'CE' THEN 'Ceará'
    WHEN 'DF' THEN 'Distrito Federal'
    WHEN 'ES' THEN 'Espírito Santo'
    WHEN 'GO' THEN 'Goiás'
    WHEN 'MA' THEN 'Maranhão'
    WHEN 'MT' THEN 'Mato Grosso'
    WHEN 'MS' THEN 'Mato Grosso do Sul'
    WHEN 'MG' THEN 'Minas Gerais'
    WHEN 'PA' THEN 'Pará'
    WHEN 'PB' THEN 'Paraíba'
    WHEN 'PR' THEN 'Paraná'
    WHEN 'PE' THEN 'Pernambuco'
    WHEN 'PI' THEN 'Piauí'
    WHEN 'RJ' THEN 'Rio de Janeiro'
    WHEN 'RN' THEN 'Rio Grande do Norte'
    WHEN 'RS' THEN 'Rio Grande do Sul'
    WHEN 'RO' THEN 'Rondônia'
    WHEN 'RR' THEN 'Roraima'
    WHEN 'SC' THEN 'Santa Catarina'
    WHEN 'SP' THEN 'São Paulo'
    WHEN 'SE' THEN 'Sergipe'
    WHEN 'TO' THEN 'Tocantins'
END AS customer_state
from silver.olist_customers;

/* Products */
create view gold.dim_products as 
select
    row_number() over(order by p.product_id) as product_key,
    p.product_id,
    --p.product_category_name as product_category_original,
    --pc.product_category_name_english as product_category_english,
    coalesce(pc.product_category_name_english,p.product_category_name,'unknown') as category, 
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm  
from silver.olist_products as p
left join silver.olist_product_category_translation as pc
on p.product_category_name = pc.product_category_name;

/* Orders */
create view gold.dim_orders as
select
row_number() over(order by order_id) as order_key,
order_id ,
customer_id,
order_status,
order_purchase_timestamp,
order_delivered_customer_date,
order_estimated_delivery_date,
datediff(day,order_purchase_timestamp,order_delivered_customer_date) as delivery_days,
datediff(day,order_estimated_delivery_date,order_delivered_customer_date) as delivery_delay_days
from silver.olist_orders ;

select * from gold.dim_orders;

/* order_items */
create view gold.fact_order_items as 
select order_id,
order_item_id,
product_id,
seller_id,
price,
freight_value from silver.olist_order_items;

/* order_reviews */
create view gold.fact_order_reviews as
select 
review_id,
order_id,
review_score,
review_creation_date,
review_answer_timestamp from(
select 
review_id,
order_id,
review_score,
review_creation_date,
review_answer_timestamp,
  ROW_NUMBER() OVER (
            PARTITION BY order_id 
            ORDER BY 
                review_creation_date DESC,
                review_answer_timestamp DESC
        ) AS rn
    FROM silver.olist_order_reviews
    WHERE order_id IS NOT NULL
) t
WHERE rn = 1;

