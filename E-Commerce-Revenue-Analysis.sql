CREATE DATABASE FoodieHubAnalytics;
USE FoodieHubAnalytics;
CREATE TABLE customers (
    customer_id     INT PRIMARY KEY,
    customer_name   VARCHAR(100),
    city            VARCHAR(50),
    email           VARCHAR(100),
    signup_date     DATE
);
SELECT * FROM customers;

CREATE TABLE restaurants (
    restaurant_id   INT PRIMARY KEY,
    restaurant_name VARCHAR(100),
    cuisine         VARCHAR(50),
    city            VARCHAR(50),
    onboard_date    DATE
);
SELECT * FROM restaurants;

CREATE TABLE delivery_partners (
    partner_id      INT PRIMARY KEY,
    partner_name    VARCHAR(100),
    city            VARCHAR(50),
    vehicle_type    VARCHAR(20),
    joined_date     DATE
);
SELECT * FROM delivery_partners;

CREATE TABLE menu_items (
    menu_id         INT PRIMARY KEY,
    restaurant_id   INT NOT NULL,
    item_name       VARCHAR(100),
    category        VARCHAR(50),
    price           DECIMAL(10,2),
    is_veg          BIT,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);
ALTER TABLE menu_items
MODIFY COLUMN is_veg VARCHAR(20);
SELECT * FROM menu_items;

CREATE TABLE orders (
    order_id        INT PRIMARY KEY,
    customer_id     INT NOT NULL,
    restaurant_id   INT NOT NULL,
    partner_id      INT NOT NULL,
    order_time      DATETIME,
    status          VARCHAR(20),
    item_total      DECIMAL(10,2),
    delivery_fee    DECIMAL(10,2),
    discount        DECIMAL(10,2),
    order_total     DECIMAL(10,2),
    payment_method  VARCHAR(30),
    delivery_mins   INT NULL,
    FOREIGN KEY (customer_id)   REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (partner_id)    REFERENCES delivery_partners(partner_id)
);
SELECT * FROM orders;

CREATE TABLE order_items (
    order_item_id   INT PRIMARY KEY,
    order_id        INT NOT NULL,
    menu_id         INT NOT NULL,
    quantity        INT,
    item_price      DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (menu_id)  REFERENCES menu_items(menu_id)
);
SELECT * FROM order_items;

CREATE TABLE ratings (
    rating_id        INT PRIMARY KEY,
    order_id         INT NOT NULL,
    food_rating      INT,
    delivery_rating  INT,
    rating_date      DATE,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
SELECT * FROM ratings;
SELECT * FROM customers;
SELECT * FROM order_items;
SELECT * FROM orders;
SELECT * FROM restaurants;
SELECT * FROM menu_items;
SELECT * FROM delivery_partners;

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL SELECT 'restaurants',        COUNT(*) FROM restaurants
UNION ALL SELECT 'menu_items',         COUNT(*) FROM menu_items
UNION ALL SELECT 'delivery_partners',  COUNT(*) FROM delivery_partners
UNION ALL SELECT 'orders',             COUNT(*) FROM orders
UNION ALL SELECT 'order_items',        COUNT(*) FROM order_items
UNION ALL SELECT 'ratings',            COUNT(*) FROM ratings;

SELECT *
FROM orders
ORDER BY order_id
LIMIT 5;

-- Ms. Kapoor wants a quick look at the data. Show the first 10 orders.
select * from orders
order by order_id
limit 10;

-- List all restaurants in Bangalore. Show only name and cuisine.
 SELECT restaurant_name, cuisine
 FROM restaurants
 WHERE city = 'Bangalore';

-- How many different cuisines does FoodieHub offer? List them (no duplicates).
SELECT DISTINCT cuisine
FROM restaurants
ORDER BY cuisine;

-- The marketing team wants all customers whose email is on Gmail. Show name, city, email.
select customer_name, city, email
from customers
WHERE email LIKE '%@gmail.com';

-- how all menu items that cost more than ₹300, most expensive first.
SELECT item_name, price
 FROM menu_items
 WHERE price > 300
 ORDER BY price DESC;
 
 -- Find all orders placed on 1st January 2026 (New Year hangover analysis!).
 SELECT *
 FROM orders
 WHERE CAST(order_time AS DATE) = '2026-01-01';
 
 -- List all vegetarian items in the "Biryani" category.
 SELECT item_name, category, price
 FROM menu_items
WHERE category = 'Biryani' AND is_veg = 1;

-- Show the 5 most recent orders that were Cancelled.
 SELECT  order_id, order_time, status
 FROM orders
 WHERE status = 'Cancelled'
 ORDER BY order_time DESC
 limit 5; 
 
 -- Find all delivery partners who ride a Bicycle. Which cities are they in?
SELECT DISTINCT city
 FROM delivery_partners
 WHERE vehicle_type = 'Bicycle';
 
 -- Show all orders where the customer got a discount of ₹100 or more.
 SELECT order_id, discount
 FROM orders
 WHERE discount = 100;
 
 -- Revenue by city: Total revenue (order_total) from delivered orders, per restaurant city. Which city makes the most money? 
 SELECT r.city, SUM(o.order_total) AS revenue
 FROM orders o
 JOIN restaurants r ON o.restaurant_id = r.restaurant_id
 WHERE o.status = 'Delivered'
 GROUP BY r.city
 ORDER BY revenue DESC;
 
 -- Cuisine popularity: How many orders did each cuisine receive? Sort highest first.
SELECT r.cuisine, COUNT(*) AS order_count
 FROM orders o
 JOIN restaurants r ON o.restaurant_id = r.restaurant_id
 GROUP BY r.cuisine
 ORDER BY order_count DESC;
 
 -- Average order value (AOV): What is the average order_total for delivered orders? Now break it
-- down by payment method — do Card users spend more than Cash users?
SELECT AVG(order_total) AS overall_aov
 FROM orders
 WHERE status = 'Delivered';

 -- by payment method
SELECT payment_method, AVG(order_total) AS avg_order_value, COUNT(*) AS orders
 FROM orders
 WHERE status = 'Delivered'
 GROUP BY payment_method
 ORDER BY avg_order_value DESC;

-- Top 10 restaurants by revenue. Show restaurant name, city, total revenue.
SELECT r.restaurant_name, r.city, SUM(o.order_total) AS revenue
FROM orders o
JOIN restaurants r
ON o.restaurant_id = r.restaurant_id
WHERE o.status = 'Delivered'
GROUP BY r.restaurant_id, r.restaurant_name, r.city
ORDER BY revenue DESC
LIMIT 10;

-- The cancellation problem: Which restaurants have more than 10 cancelled orders? (Ms.Kapoor wants to call them.) 
SELECT r.restaurant_name, COUNT(*) AS cancelled_orders
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.status = 'Cancelled'
GROUP BY r.restaurant_id, r.restaurant_name
HAVING COUNT(*) > 10
ORDER BY cancelled_orders DESC;

-- Busiest delivery partners: Top 10 partners by number of delivered orders. Show partner name, city, and count. 
 SELECT p.partner_name, p.city, COUNT(*) AS delivered_orders
 FROM orders o
 JOIN delivery_partners p ON o.partner_id = p.partner_id
 WHERE o.status = 'Delivered'
 GROUP BY p.partner_id, p.partner_name, p.city
 ORDER BY delivered_orders DESC
 LIMIT 10;

-- Silent customers: Using LEFT JOIN, find delivered orders that were never rated. How many are there? Why can't a normal (INNER) JOIN answer this? 
SELECT COUNT(*) AS unrated_delivered_orders
FROM orders o
 LEFT JOIN ratings rt ON o.order_id = rt.order_id
 WHERE o.status = 'Delivered' AND rt.rating_id IS NULL;

-- Monthly trend: Number of orders and total revenue per month. Is FoodieHub growing?
SELECT FORMAT(order_time, 'yyyy-MM') AS order_month,
COUNT(*) AS order_count,
SUM(order_total) AS revenue
FROM orders
WHERE status = 'Delivered'
GROUP BY FORMAT(order_time, 'yyyy-MM')
ORDER BY order_month;

-- Weekend effect: Compare average number of daily orders on weekends vs weekdays. (Hint: DAYOFWEEK / WEEKDAY function.)  
WITH daily_orders AS (SELECT CAST(order_time AS DATE) AS order_date,
CASE
WHEN DAYOFWEEK(order_time) IN (1, 7)
THEN 'Weekend'
ELSE 'Weekday'
END AS day_type,COUNT(*) AS orders_that_day FROM orders
GROUP BY
CAST(order_time AS DATE),CASE
WHEN DAYOFWEEK(order_time) IN (1, 7)THEN 'Weekend'ELSE 'Weekday'
END)
SELECT
day_type,
AVG(orders_that_day * 1.0) AS avg_daily_orders
FROM daily_orders
GROUP BY day_type;

--  Menu audit: Average item price per cuisine. Which cuisine is the most expensive on average?
SELECT r.cuisine, AVG(m.price) AS avg_price
FROM menu_items m
JOIN restaurants r ON m.restaurant_id = r.restaurant_id
GROUP BY r.cuisine
ORDER BY avg_price DESC;

--  

 
 
 


 
 
