/* PURPOSE: To create schema for the silver Layer */

-- 1. Customers
CREATE TABLE silver.olist_customers (
    customer_id             VARCHAR(50),
    customer_unique_id      VARCHAR(50), 
    customer_zip_code_prefix VARCHAR(10),
    customer_city           VARCHAR(100),
    customer_state          VARCHAR(2)
);

-- 2. Orders

CREATE TABLE silver.olist_orders (
    order_id                       VARCHAR(50),
    customer_id                    VARCHAR(50),
    order_status                   VARCHAR(20),
    order_purchase_timestamp       DATETIME,
    order_approved_at              DATETIME,
    order_delivered_carrier_date   DATETIME,
    order_delivered_customer_date  DATETIME,
    order_estimated_delivery_date  DATETIME,
    flag_approval_after_delivery_carrier bit,
    flag_carrier_after_delivery bit,
    delivered_missing_customer_date bit
);


-- 3. Order Items 

CREATE TABLE silver.olist_order_items (
    order_id            VARCHAR(50),
    order_item_id        INTEGER ,
    product_id           VARCHAR(50),
    seller_id             VARCHAR(50),
    shipping_limit_date   DATETIME,
    price                 NUMERIC(10,2),
    freight_value          NUMERIC(10,2)
);

-- 4. Order Reviews
CREATE TABLE silver.olist_order_reviews (
    review_id                VARCHAR(50),
    order_id                  VARCHAR(50),
    review_score              INTEGER,
    review_comment_title      VARCHAR(255),
    review_comment_message    TEXT,
    review_creation_date      DATETIME,
    review_answer_timestamp   DATETIME
);

-- 5. Products 
CREATE TABLE silver.olist_products (
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

CREATE TABLE silver.olist_product_category_translation (
    product_category_name          VARCHAR(100),
    product_category_name_english   VARCHAR(100)
);