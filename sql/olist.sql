---Which top 10 sellers generated the highest revenue — and how many orders did each fulfill?

SELECT
  oi.seller_id,
  '$' |- freight_value
  | TO_CHAR(SUM(oi.price + oi.freight_value), 'FM999,999,999,990.00') AS total_revenue,
  COUNT(DISTINCT oi.order_id) AS total_orders
FROM olist.order_items oi
GROUP BY oi.seller_id
ORDER BY SUM(oi.price + oi.freight_value) DESC
LIMIT 10;


--- What are the top 5 product categories by total revenue — and what is their average order value?
Select 
  p.product_category_name,
  '$' || TO_CHAR(SUM(oi.price + oi.freight_value), 'FM999,999,999,990.00') AS total_revenue,
  '$' || TO_CHAR(AVG(oi.price + oi.freight_value), 'FM999,999,999,990.00') AS avg_order_value
FROM olist.order_items oi
JOIN olist.products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY SUM(oi.price + oi.freight_value) DESC
LIMIT 5;

-- What are the bottom 5 product categories by total revenue — and what is their average order value?
Select 
  p.product_category_name,
  '$' || TO_CHAR(SUM(oi.price + oi.freight_value), 'FM999,999,999,990.00') AS total_revenue,
  '$' || TO_CHAR(AVG(oi.price + oi.freight_value), 'FM999,999,999,990.00') AS avg_order_value
FROM olist.order_items oi
JOIN olist.products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY SUM(oi.price + oi.freight_value) ASC
LIMIT 5;

----Which month had the highest sales in 2017 vs 2018 — is the business growing year over year?
WITH monthly AS (
  SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month_num,
    TO_CHAR(o.order_purchase_timestamp, 'Mon') AS month_name,
    SUM(oi.price + oi.freight_value) AS total_revenue
  FROM olist.orders o
  JOIN olist.order_items oi ON o.order_id = oi.order_id
  WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
  GROUP BY year, month_num, month_name
)
SELECT year, month_num, month_name, total_revenue
FROM monthly
ORDER BY year, month_num;


WITH monthly AS (
  SELECT
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month_num,
    TO_CHAR(o.order_purchase_timestamp, 'Mon') AS month_name,
    SUM(oi.price + oi.freight_value) AS total_revenue
  FROM olist.orders o
  JOIN olist.order_items oi ON o.order_id = oi.order_id
  WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
  GROUP BY year, month_num, month_name
)
SELECT year, month_name, total_revenue
FROM monthly
ORDER BY total_revenue DESC
LIMIT 1;


WITH monthly AS (
  SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month_start,
    SUM(oi.price + oi.freight_value) AS total_revenue
  FROM olist.orders o
  JOIN olist.order_items oi ON o.order_id = oi.order_id
  WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017, 2018)
  GROUP BY month_start
),
mom AS (
  SELECT
    month_start,
    total_revenue,
    total_revenue - LAG(total_revenue) OVER (ORDER BY month_start) AS mom_change,
    (total_revenue / NULLIF(LAG(total_revenue) OVER (ORDER BY month_start), 0) - 1) * 100 AS mom_growth_pct
  FROM monthly
)
SELECT
  TO_CHAR(month_start, 'YYYY-Mon') AS month,
  total_revenue,
  mom_change,
  (mom_growth_pct) AS mom_growth_pct,
  RANK() OVER (ORDER BY mom_growth_pct DESC NULLS LAST) AS growth_rank
FROM mom
ORDER BY month_start;


---What is the total revenue generated per state — which state is our biggest market?
SELECT
  c.customer_state,
  '$' || TO_CHAR(SUM(oi.price + oi.freight_value), 'FM999,999,999,990.00') AS total_revenue
FROM olist.customers c
JOIN olist.orders o ON c.customer_id = o.customer_id
JOIN olist.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY SUM(oi.price + oi.freight_value) DESC; 

----- Which day of the week gets the most orders — are weekends busier than weekdays?

SELECT
  TO_CHAR(order_purchase_timestamp, 'Day') AS day_name,
  COUNT(*) AS total_orders,
  CASE 
    WHEN EXTRACT(DOW FROM order_purchase_timestamp) IN (0,6) THEN 'Weekend'
    ELSE 'Weekday'
  END AS day_type
FROM olist.orders
GROUP BY day_name, day_type, EXTRACT(DOW FROM order_purchase_timestamp)
ORDER BY COUNT(*) DESC;

---What percentage of total orders were delivered late — and which seller had the worst late delivery rate?

SELECT
  o.order_id,
  oi.seller_id,
  oi.shipping_limit_date,
  o.order_delivered_customer_date,
  CASE 
    WHEN o.order_delivered_customer_date > oi.shipping_limit_date THEN 'Late'
    ELSE 'On Time'
  END AS delivery_status,
  o.order_delivered_customer_date - oi.shipping_limit_date AS days_late
FROM olist.orders o
JOIN olist.order_items oi ON o.order_id = oi.order_id
WHERE o.order_delivered_customer_date IS NOT NULL;

SELECT
  ROUND(
    100.0 * SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0), 2
  ) AS late_delivery_pct
FROM olist.orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


SELECT
  oi.seller_id,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
  ROUND(
    100.0 * SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0), 2
  ) AS late_rate_pct
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY oi.seller_id
ORDER BY late_rate_pct DESC, total_orders DESC
LIMIT 1;


--What is the average delivery time in days by state — which state waits the longest?

SELECT
  c.customer_state,
  Round(AVG(o.order_delivered_customer_date - o.order_purchase_timestamp), 2) AS avg_delivery_time_days --AVG(o.order_delivered_customer_date - o.order_purchase_timestamp) AS avg_delivery_time_days
FROM olist.customers c      
JOIN olist.orders o ON c.customer_id = o.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_time_days DESC;

----Which product category takes the longest to deliver on average?
SELECT
  p.product_category_name,
  Round(AVG(o.order_delivered_customer_date - o.order_purchase_timestamp), 2) AS avg_delivery_time_days
FROM olist.products p
JOIN olist.order_items oi ON p.product_id = oi.product_id
JOIN olist.orders o ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY p.product_category_name
ORDER BY avg_delivery_time_days DESC;

---Is delivery getting faster or slower over the months — show the trend?
WITH monthly_delivery AS (
  SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month_start,
    Round(AVG(o.order_delivered_customer_date - o.order_purchase_timestamp), 2) AS avg_delivery_time_days
  FROM olist.orders o
  WHERE o.order_delivered_customer_date IS NOT NULL
  GROUP BY month_start
)
SELECT
  TO_CHAR(month_start, 'YYYY-Mon') AS month,
  avg_delivery_time_days
FROM monthly_delivery
ORDER BY month_start ASC;

---Which sellers consistently deliver before the estimated date — who are our most reliable sellers?
SELECT
  oi.seller_id,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS on_time_orders,
  ROUND(
    100.0 * SUM(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END)
    / NULLIF(COUNT(*), 0), 2) AS on_time_rate_pct
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY oi.seller_id
ORDER BY on_time_rate_pct DESC, total_orders DESC;

----- How many sellers delivers before the estimated date more than 90% of the time?
SELECT
  COUNT(DISTINCT oi.seller_id) AS reliable_sellers_count
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date <= o.order_estimated_delivery_date;


WITH seller_rates AS (
  SELECT
    oi.seller_id,
    AVG(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS ontime_rate
  FROM olist.order_items oi
  JOIN olist.orders o ON oi.order_id = o.order_id
  WHERE o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
  GROUP BY oi.seller_id
)
SELECT COUNT(*) AS sellers_above_90
FROM seller_rates
WHERE ontime_rate > 0.90;

---Are review scores improving or declining month by month — show the full trend?
SELECT  
  EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
  EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,
  ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist.orders o
JOIN olist.reviews r ON o.order_id = r.order_id
WHERE r.review_score IS NOT NULL  
GROUP BY year, month
ORDER BY year, month;


SELECT
  EXTRACT(YEAR FROM review_creation_date) AS year,
  EXTRACT(MONTH FROM review_creation_date) AS month_num,
  TO_CHAR(review_creation_date, 'Mon') AS month_name,
  ROUND(AVG(review_score), 2) AS avg_review_score
FROM olist.reviews
WHERE review_creation_date IS NOT NULL
GROUP BY year, month_num, month_name
ORDER BY year, month_num;

----Which product category has the lowest average review score — and how many reviews did it receive?
SELECT
  p.product_category_name,
  ROUND(AVG(r.review_score), 2) AS avg_review_score,
  COUNT(r.review_id) AS total_reviews
FROM olist.products p
JOIN olist.order_items oi ON p.product_id = oi.product_id
JOIN olist.reviews r ON oi.order_id = r.order_id
GROUP BY p.product_category_name
ORDER BY avg_review_score ASC
LIMIT 1;

--- Which sellers have the most 1-star reviews — and what is their total order count?
SELECT
  oi.seller_id,
  COUNT(DISTINCT o.order_id) AS total_orders,
  COUNT(DISTINCT r.review_id) AS total_1_star_reviews
FROM olist.order_items oi
JOIN olist.orders o ON oi.order_id = o.order_id
JOIN olist.reviews r ON o.order_id = r.order_id
WHERE r.review_score = 1
GROUP BY oi.seller_id
ORDER BY total_1_star_reviews DESC
LIMIT 10;

---- Is there a connection between late delivery and low review scores — do late orders get bad reviews?
SELECT
  o.order_id, 
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,
  r.review_score,
  CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'Late' ELSE 'On Time' END AS delivery_status
FROM olist.orders o
JOIN olist.reviews r ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND r.review_score IS NOT NULL;   

----Which states have the most unhappy customers based on average review score?

SELECT
  c.customer_state,
  ROUND(AVG(r.review_score), 2) AS avg_review_score,
  COUNT(r.review_id) AS total_reviews
FROM olist.customers c
JOIN olist.orders o ON c.customer_id = o.customer_id
JOIN olist.reviews r ON o.order_id = r.order_id
GROUP BY c.customer_state
ORDER BY avg_review_score ASC;

---- How many customers bought more than once — what is our repeat purchase rate percentage?
WITH customer_orders AS (
  SELECT
    customer_unique_id,
    COUNT(DISTINCT o.order_id) AS orders_count
  FROM olist.customers c
  JOIN olist.orders o ON c.customer_id = o.customer_id
  GROUP BY customer_unique_id
),
repeaters AS (
  SELECT COUNT(*) AS repeat_customers
  FROM customer_orders
  WHERE orders_count > 1
),
totals AS (
  SELECT COUNT(*) AS total_customers
  FROM customer_orders
)
SELECT
  repeat_customers,
  total_customers,
  ROUND(100.0 * repeat_customers / NULLIF(total_customers, 0), 2) AS repeat_rate_pct
FROM repeaters, totals;

----What is our monthly new customer growth rate — are we acquiring more customers each month?
WITH monthly AS (
  SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month_start,
    COUNT(DISTINCT c.customer_id) AS new_customers
  FROM olist.orders o
  JOIN olist.customers c ON o.customer_id = c.customer_id
  GROUP BY month_start
),
mom AS (
  SELECT
    month_start,
    new_customers,
    new_customers - LAG(new_customers) OVER (ORDER BY month_start) AS mom_change,
    (new_customers / NULLIF(LAG(new_customers) OVER (ORDER BY month_start), 0) - 1) * 100 AS mom_growth_pct
  FROM monthly  
)
SELECT
  TO_CHAR(month_start, 'YYYY-Mon') AS month,
  new_customers,
  mom_change,
  mom_growth_pct      
FROM mom
ORDER BY month_start;

---Which city has the highest number of customers?
SELECT
  c.customer_city,
  COUNT(DISTINCT c.customer_id) AS total_customers
FROM olist.customers c
GROUP BY c.customer_city
ORDER BY total_customers DESC
LIMIT 1;  

----What is the average order value per customer — who are our highest value customers?
SELECT        
  c.customer_id,
  '$' || TO_CHAR(AVG(oi.price + oi.freight_value), 'FM999,999,999,990.00') AS avg_order_value
FROM olist.customers c
JOIN olist.orders o ON c.customer_id = o.customer_id
JOIN olist.order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id
ORDER BY avg_order_value DESC
LIMIT 10;

----How long does it take on average between a customer's first and second purchase?
WITH first_purchase AS (
  SELECT
    customer_id,
    MIN(order_purchase_timestamp) AS first_purchase_date
  FROM olist.orders
  GROUP BY customer_id
),
second_purchase AS (
  SELECT
    customer_id,
    MAx(order_purchase_timestamp) AS second_purchase_date
  FROM olist.orders
  GROUP BY customer_id
  HAVING Max(order_purchase_timestamp) > (SELECT MIN(order_purchase_timestamp) FROM olist.orders o2 WHERE o2.customer_id = customer_id)
)
SELECT
  ROUND(AVG(second_purchase_date - first_purchase_date), 2) AS avg_days_between_purchases
FROM first_purchase fp
JOIN second_purchase sp ON fp.customer_id = sp.customer_id; 

---What is the most popular payment method — and how much revenue does each method generate?
SELECT
  payment_type,
  COUNT(*) AS total_payments,
  COUNT(DISTINCT order_id) AS total_orders,
  SUM(payment_value) AS total_revenue
FROM olist.payments
GROUP BY payment_type
ORDER BY total_revenue DESC;

-----Do customers who pay in installments spend more on average than single payment customers?
WITH order_payments AS (
  SELECT
    order_id,
    MAX(payment_installments) AS installments,
    SUM(payment_value) AS order_total
  FROM olist.payments
  GROUP BY order_id
)
SELECT
  CASE WHEN installments > 1 THEN 'Installments' ELSE 'Single Payment' END AS payment_group,
  ROUND(AVG(order_total)::numeric, 2) AS avg_order_value,
  COUNT(*) AS total_orders
FROM order_payments
GROUP BY payment_group
ORDER BY avg_order_value DESC;

---- What is the average number of installments chosen by customers — does it vary by product category?
WITH order_installments AS (
  SELECT
    order_id,
    MAX(payment_installments) AS installments
  FROM olist.payments
  GROUP BY order_id
)
SELECT
  p.product_category_name,
  ROUND(AVG(oii.installments)::numeric, 2) AS avg_installments,
  ROUND(AVG(oi.price)::numeric, 2) AS avg_product_value,
  COUNT(DISTINCT oi.order_id) AS total_orders
FROM olist.order_items oi
JOIN olist.products p ON oi.product_id = p.product_id
JOIN order_installments oii ON oi.order_id = oii.order_id
GROUP BY p.product_category_name
ORDER BY avg_installments DESC;

---- Rank all sellers by a performance score combining — revenue + review score + on-time delivery rate. Who is the overall best seller?
WITH seller_metrics AS (
  SELECT
    oi.seller_id,
    SUM(oi.price + oi.freight_value) AS revenue,
    AVG(r.review_score) AS avg_review,
    AVG(CASE WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS ontime_rate
  FROM olist.order_items oi
  JOIN olist.reviews r ON oi.order_id = r.order_id
  JOIN olist.orders o ON oi.order_id = o.order_id
  WHERE o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
  GROUP BY oi.seller_id
)
SELECT seller_id, revenue, avg_review, ontime_rate
FROM seller_metrics
WHERE avg_review > 4
  AND ontime_rate > 0.90
ORDER BY revenue DESC
LIMIT 10;

-----

SELECT COUNT(*) AS total_items_sold
FROM olist.order_items;

SELECT COUNT(*) AS total_rows
FROM olist.order_items;


SELECT COUNT(*) AS total_delivered_orders
FROM olist.orders
WHERE order_status = 'Delivered';


SELECT COUNT(*) AS total_cancelled_orders
FROM olist.orders
WHERE order_status = 'Canceled';


SELECT COUNT(DISTINCT customer_city) AS total_unique_cities
FROM olist.customers;

SELECT COUNT(DISTINCT LOWER(TRIM(customer_city))) AS total_unique_cities_clean
FROM olist.customers;
