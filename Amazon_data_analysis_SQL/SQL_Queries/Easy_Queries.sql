-- 1. List all customers from California.
SELECT * 
FROM customers
WHERE state = 'California';

-- 2. Show all products in the 'electronics' category.
SELECT c.category_name, p.product_name
FROM category c
JOIN products p ON c.category_id = p.category_id
WHERE c.category_name = 'electronics';

-- 3. Find all orders with a 'Cancelled' status.
SELECT * 
FROM orders
WHERE order_status = 'Cancelled';

-- 4. Count the total number of sellers from the 'USA'.
SELECT COUNT(*) 
FROM seller
WHERE origin = 'USA';

-- 5. Display the top 5 most expensive products.
SELECT * 
FROM products
ORDER BY price DESC
LIMIT 5;

-- 6. Find all payments made via 'PayPal'.
SELECT * 
FROM payments
WHERE payment_mode = 'PayPal';

-- 7. List all orders placed in the year 2023.
SELECT * 
FROM orders
WHERE YEAR(order_date) = 2023;

-- 8. Show the product names and their categories.
SELECT p.product_name, c.category_name
FROM products p 
JOIN category c ON p.category_id = c.category_id;

-- 9. Find customers whose first name starts with 'A'.
SELECT * 
FROM customers
WHERE first_name LIKE 'A%';

-- 10. Count how many orders each customer has placed.
SELECT customer_id, COUNT(*) AS total_orders
FROM orders
GROUP BY customer_id;

-- 11. Show all shipping records where the delivery status is 'Delivered'.
SELECT * 
FROM shipping
WHERE delivery_status = 'Delivered';

-- 12. Find the average price of all products.
SELECT ROUND(AVG(price), 2) AS avg_price
FROM products;

-- 13. List all orders along with the customer's first and last name.
SELECT o.*, c.first_name, c.last_name
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id;

-- 14. Show products with a price between $50 and $100.
SELECT * 
FROM products
WHERE price BETWEEN 50 AND 100;
  
-- 15. Find the total number of items sold for each product.
SELECT p.product_id, p.product_name, SUM(oi.quantity) AS total_items
FROM order_items oi 
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name;
  
-- 16. List all sellers and their origin, ordered by origin alphabetically.
SELECT * 
FROM seller 
ORDER BY origin;
  
-- 17. Show the earliest and latest order dates in the dataset.
SELECT MIN(order_date) AS earliest_order, MAX(order_date) AS last_order_date
FROM orders;
  
-- 18. Find all orders that were shipped by 'FedEx'.
SELECT o.*
FROM orders o
JOIN shipping s ON o.order_id = s.order_id
WHERE shipping_provider = 'FedEx';
  
-- 19. Count the number of products in each category.
SELECT c.category_name, COUNT(*) AS total_products
FROM products p 
JOIN category c ON p.category_id = c.category_id
GROUP BY c.category_name;
  
-- 20. Show the total revenue generated from each order (from order_items).
SELECT order_id, SUM(total_price) AS total_revenue
FROM order_items
GROUP BY order_id;
  
-- 21. List all orders that have a payment status of 'Failed'.
SELECT * 
FROM payments
WHERE payment_status = 'Failed';
  
-- 22. Find the customer who has placed the most orders.
SELECT CONCAT(c.first_name, ' ', c.last_name) AS customer_name, 
       COUNT(o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY CONCAT(c.first_name, ' ', c.last_name)
ORDER BY total_orders DESC
LIMIT 1;
  
-- 23. Show all products that are out of stock (stock = 0).
SELECT p.product_id, p.product_name
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock = 0;
  
-- 24. List the names of all shipping providers used.
SELECT DISTINCT shipping_provider 
FROM shipping;
  
-- 25. Find the average quantity of items ordered per order.
SELECT ROUND(AVG(quantity), 0) AS avg_quantity
FROM order_items;
  
-- 26. Show all orders that are still 'Processing'.
SELECT * 
FROM orders 
WHERE order_status = 'Processing';
  
-- 27. Count how many orders were delivered to each state.
SELECT c.state, COUNT(*) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.state
ORDER BY total_orders DESC;
  
-- 28. Find the most common payment mode.
SELECT payment_mode, COUNT(*) AS total_payments
FROM payments
GROUP BY payment_mode
ORDER BY total_payments DESC
LIMIT 1;
  
-- 29. List all products with their seller's name.
SELECT p.product_id, p.product_name, s.seller_name
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN seller s ON s.seller_id = o.seller_id;

-- 30. Show the total value of inventory in each warehouse.
SELECT i.warehouse_id, 
       COUNT(stock) AS total_stock, 
       SUM(p.price * i.stock) AS total_value
FROM products p
LEFT JOIN inventory i ON i.product_id = p.product_id
GROUP BY i.warehouse_id;
