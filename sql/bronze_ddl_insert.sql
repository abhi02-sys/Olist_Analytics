/* 
PURPOSE: To Load the dataset into bronze layer using bulk insert
*/

use master;
create database olist_analytics;

use olist_analytics;
create schema bronze;
create schema silver;
create schema gold;


-- 1. Customers
CREATE TABLE bronze.olist_customers (
    customer_id             VARCHAR(50),
    customer_unique_id      VARCHAR(50), 
    customer_zip_code_prefix VARCHAR(10),
    customer_city           VARCHAR(100),
    customer_state          VARCHAR(2)
);

-- 2. Orders
CREATE TABLE bronze.olist_orders (
    order_id                       VARCHAR(50),
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME
);

-- 3. Order Items 
drop table bronze.olist_order_items;
CREATE TABLE bronze.olist_order_items (
    order_id            VARCHAR(50),
    order_item_id        INTEGER ,
    product_id           VARCHAR(50),
    seller_id             VARCHAR(50),
    shipping_limit_date   DATETIME,
    price                 NUMERIC(10,2),
    freight_value          NUMERIC(10,2)
);

-- 4. Order Reviews
CREATE TABLE bronze.olist_order_reviews (
    review_id                VARCHAR(50),
    order_id                  VARCHAR(50),
    review_score              INTEGER,
    review_comment_title      VARCHAR(255),
    review_comment_message    TEXT,
    review_creation_date      DATETIME,
    review_answer_timestamp   DATETIME
);

-- 5. Products 
CREATE TABLE bronze.olist_products (
    product_id                  VARCHAR(50),
    product_category_name        VARCHAR(100),
    product_name_length          INTEGER,
    product_description_length   INTEGER,
    product_photos_qty           INTEGER,
    product_weight_g              INTEGER,
    product_length_cm             INTEGER,
    product_height_cm             INTEGER,
    product_width_cm              INTEGER
);

CREATE TABLE bronze.olist_product_category_translation (
    product_category_name          VARCHAR(100),
    product_category_name_english   VARCHAR(100)
);

--Bulk Insert Data
--Table 1: customers
truncate table bronze.olist_customers;

bulk insert bronze.olist_customers
from 'D:\Data-Analytics\SQL-Course\Datasets\olist_customers_dataset.csv'
with(
    firstrow = 2,
    fieldterminator = ','
)

select * from bronze.olist_customers;

--Table 2: order_items
truncate table bronze.olist_order_items;

bulk insert bronze.olist_order_items
from 'D:\Data-Analytics\SQL-Course\Datasets\olist_order_items_dataset.csv'
with(
    format = 'csv',
    firstrow = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
)

select count(*) from bronze.olist_order_items;

--Table 3: order_reviews
truncate table bronze.olist_order_reviews;

BULK INSERT bronze.olist_order_reviews
FROM 'D:\Data-Analytics\SQL-Course\Datasets\olist_order_reviews_dataset.csv'
WITH (
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIRSTROW = 2
);

select * from bronze.olist_order_reviews;
select count(*) from bronze.olist_order_reviews;

--Table 4: orders
TRUNCATE TABLE bronze.olist_orders;
GO

BULK INSERT bronze.olist_orders
FROM 'D:\Data-Analytics\SQL-Course\Datasets\olist_orders_dataset.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001'
);
select * from bronze.olist_orders;
select count(*) from bronze.olist_orders;

--Table 5: products
truncate table bronze.olist_products;

bulk insert bronze.olist_products
from 'D:\Data-Analytics\SQL-Course\Datasets\olist_products_dataset.csv'
with(
    firstrow = 2,
    fieldterminator = ','
)

select count(*) from bronze.olist_products;
select * from bronze.olist_products;

--Table 6: product_category_translation
truncate table bronze.olist_product_category_translation;

bulk insert bronze.olist_product_category_translation
from 'D:\Data-Analytics\SQL-Course\Datasets\product_category_name_translation.csv'
with(
    firstrow = 2,
    fieldterminator = ','
)

select count(*) from bronze.olist_product_category_translation;
select * from bronze.olist_product_category_translation;