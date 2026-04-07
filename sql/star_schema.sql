SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name = 'customers';

ALTER TABLE olist.customers
  ADD CONSTRAINT customers_pk PRIMARY KEY (customer_id);


SELECT conname
FROM pg_constraint
WHERE conrelid = 'olist.customers'::regclass
  AND contype = 'p';


ALTER TABLE olist.orders
  ADD CONSTRAINT orders_customer_fk
  FOREIGN KEY (customer_id) REFERENCES olist.customers(customer_id) NOT VALID;

ALTER TABLE olist.order_items
  ADD CONSTRAINT order_items_order_fk
  FOREIGN KEY (order_id) REFERENCES olist.orders(order_id) NOT VALID;

ALTER TABLE olist.order_items
  ADD CONSTRAINT order_items_product_fk
  FOREIGN KEY (product_id) REFERENCES olist.products(product_id) NOT VALID;

ALTER TABLE olist.order_items
  ADD CONSTRAINT order_items_seller_fk
  FOREIGN KEY (seller_id) REFERENCES olist.sellers(seller_id) NOT VALID;

ALTER TABLE olist.payments
  ADD CONSTRAINT payments_order_fk
  FOREIGN KEY (order_id) REFERENCES olist.orders(order_id) NOT VALID;

ALTER TABLE olist.reviews
  ADD CONSTRAINT reviews_order_fk
  FOREIGN KEY (order_id) REFERENCES olist.orders(order_id) NOT VALID;

ALTER TABLE olist.products
  ADD CONSTRAINT products_category_fk
  FOREIGN KEY (product_category_name) REFERENCES olist.product_category(product_category_name) NOT VALID;


-- make sure the referenced column is unique
ALTER TABLE olist.product_category
  ADD CONSTRAINT product_category_name_uk UNIQUE (product_category_name);

-- add the FK from products to product_category
ALTER TABLE olist.products
  ADD CONSTRAINT products_category_fk
  FOREIGN KEY (product_category_name)
  REFERENCES olist.product_category(product_category_name) NOT VALID;


SELECT c.customer_id, c.customer_zip_code_prefix, g.geolocation_lat, g.geolocation_lng
FROM olist.customers c
JOIN olist.geolocation g
  ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;


ALTER TABLE olist.orders
  ALTER COLUMN order_purchase_timestamp TYPE DATE USING order_purchase_timestamp::date,
  ALTER COLUMN order_approved_at TYPE DATE USING order_approved_at::date,
  ALTER COLUMN order_estimated_delivery_date TYPE DATE USING order_estimated_delivery_date::date,
  ALTER COLUMN order_delivered_carrier_date TYPE DATE USING order_delivered_carrier_date::date,
  ALTER COLUMN order_delivered_customer_date TYPE DATE USING order_delivered_customer_date::date;


ALTER TABLE olist.order_items
  ALTER COLUMN price TYPE NUMERIC USING price::numeric,
  ALTER COLUMN freight_value TYPE NUMERIC USING freight_value::numeric;
