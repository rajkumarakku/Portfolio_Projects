-- 31. Calculate the total sales revenue for each month in 2023.
SELECT MONTH(o.order_date) AS month_, 
       SUM(oi.total_price) AS total_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE YEAR(o.order_date) = 2023
GROUP BY MONTH(o.order_date)
ORDER BY MONTH(o.order_date);

-- 32. Find the top 5 best-selling products by quantity sold.
SELECT p.product_id, p.product_name, 
       SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;

-- 33. Calculate the average order value (AOV) for each customer.
SELECT c.customer_id, 
       CONCAT(c.first_name, ' ', c.last_name) AS full_name, 
       ROUND(AVG(oi.total_price), 2) AS AOV
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, CONCAT(c.first_name, ' ', c.last_name);

-- 34. Show the monthly growth rate (%) in revenue for 2024.
WITH cte AS (
    SELECT 
        MONTH(o.order_date) AS month_,
        SUM(oi.total_price) AS current_revenue
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY MONTH(o.order_date)
    ORDER BY MONTH(o.order_date)
),
prev_revenue AS (
    SELECT 
        month_,
        current_revenue,
        LAG(current_revenue, 1) OVER (ORDER BY month_) AS previous_revenue
    FROM cte
)
SELECT 
    month_,
    current_revenue,
    previous_revenue,
    ROUND(((current_revenue - previous_revenue) / previous_revenue) * 100, 2) AS growth_ratio_percent
FROM prev_revenue;

-- 35. Identify customers who have made more than 10 orders.
SELECT CONCAT(c.first_name, ' ', c.last_name) AS full_name, 
       COUNT(o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY CONCAT(c.first_name, ' ', c.last_name)
HAVING COUNT(o.order_id) > 10;

-- 36. Find the category that generates the highest total revenue.
SELECT c.category_id, c.category_name, 
       SUM(oi.total_price) AS total_revenue 
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN category c ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY total_revenue DESC
LIMIT 1;

-- 37. Calculate the average time between order date and shipping date for each shipping provider.
SELECT s.shipping_id, s.shipping_provider, 
       ROUND(AVG(DATEDIFF(s.shipping_date, o.order_date)), 0) AS avg_time
FROM orders o
JOIN shipping s ON o.order_id = s.order_id
GROUP BY s.shipping_id, s.shipping_provider;

-- 38. Show the top 3 states that generate the highest revenue.
SELECT c.state, SUM(oi.total_price) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.state
ORDER BY total_revenue DESC
LIMIT 3;

-- 39. Identify products that have never been ordered.
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- 40. Find the seller with the highest total sales revenue.
SELECT s.seller_id, s.seller_name, 
       SUM(oi.total_price) AS total_revenue
FROM orders o 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN seller s ON o.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_name
ORDER BY total_revenue DESC
LIMIT 1;

-- 41. Calculate the percentage of orders that were returned.
SELECT 
    SUM(CASE WHEN order_status = 'Returned' THEN 1 ELSE 0 END) AS total_returned_orders,
    ROUND(SUM(CASE WHEN order_status = 'Returned' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS returned_orders_percentage
FROM orders;

-- 42. Show the customer retention rate month-over-month.
WITH monthly_customers AS (
    SELECT 
        MONTH(o.order_date) AS month_,
        YEAR(o.order_date) AS year_,
        COUNT(DISTINCT o.customer_id) AS unique_customers
    FROM orders o
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
),
previous_customers AS (
    SELECT 
        year_,
        month_,
        unique_customers AS current_customers,
        LAG(unique_customers, 1) OVER (ORDER BY year_, month_) AS previous_customers
    FROM monthly_customers
)
SELECT 
    year_,
    month_,
    current_customers,
    previous_customers,
    ROUND((current_customers / previous_customers) * 100, 2) AS retention_rate
FROM previous_customers
ORDER BY year_, month_;

-- 43. Find the day of the week with the highest number of orders.
WITH daywise_orders AS (
    SELECT 
        YEAR(o.order_date) AS year_,
        DAYNAME(o.order_date) AS day_name,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    GROUP BY YEAR(o.order_date), DAYNAME(o.order_date)
),
ranked_orders AS (
    SELECT 
        year_,
        day_name,
        total_orders,
        RANK() OVER (PARTITION BY year_ ORDER BY total_orders DESC) AS rnk
    FROM daywise_orders
)
SELECT year_, day_name, total_orders
FROM ranked_orders
WHERE rnk = 1;

-- 44. Identify orders where the payment was made after the order was shipped.
WITH order_payment AS (
    SELECT 
        o.order_id,
        o.order_date,
        s.shipping_date,
        p.payment_date,
        p.payment_mode,
        p.payment_status
    FROM orders o
    JOIN shipping s ON o.order_id = s.order_id
    JOIN payments p ON o.order_id = p.order_id
)
SELECT 
    order_id,
    order_date,
    shipping_date,
    payment_date,
    payment_mode,
    payment_status
FROM order_payment
WHERE payment_date > shipping_date;

-- 45. Calculate the profit margin for each product and categorize it.
WITH margin AS (
    SELECT 
        p.product_id,
        p.product_name,
        ROUND(((oi.price_per_unit - p.cogs) / oi.price_per_unit) * 100, 2) AS profit_margin
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
)
SELECT 
    product_id,
    product_name,
    profit_margin,
    CASE 
        WHEN profit_margin > 50 THEN 'High'
        WHEN profit_margin BETWEEN 20 AND 50 THEN 'Medium'
        ELSE 'Low'
    END AS profit_margin_category
FROM margin;

-- 46. Show the running total of revenue for each month in 2023.
SELECT YEAR(o.order_date) AS year_,
       MONTH(o.order_date) AS month_,
       SUM(oi.total_price) AS monthly_revenue,
       SUM(SUM(oi.total_price)) OVER (ORDER BY MONTH(o.order_date)) AS running_total
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE YEAR(o.order_date) = 2023
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY YEAR(o.order_date), MONTH(o.order_date);

-- 47. Identify the most valuable customer (by total spend) for each state.
WITH customer_revenue AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        c.state,
        SUM(oi.total_price) AS total_revenue
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, CONCAT(c.first_name, ' ', c.last_name), c.state
),
ranked AS (
    SELECT 
        customer_id,
        full_name,
        state,
        total_revenue,
        DENSE_RANK() OVER (PARTITION BY state ORDER BY total_revenue DESC) AS rnk
    FROM customer_revenue
)
SELECT 
    customer_id,
    full_name,
    state,
    total_revenue
FROM ranked
WHERE rnk = 1;

-- 48. Calculate the average shipping time for delivered orders.
SELECT 
    ROUND(AVG(DATEDIFF(s.shipping_date, o.order_date)), 2) AS avg_shipping_time
FROM orders o
JOIN shipping s ON o.order_id = s.order_id
WHERE s.delivery_status = 'Delivered';

-- 49. Show the top 5 customers with the highest average order value.
SELECT c.customer_id,
       CONCAT(c.first_name, ' ', c.last_name) AS full_name,
       ROUND(AVG(oi.total_price), 2) AS avg_revenue
FROM orders o 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, CONCAT(c.first_name, ' ', c.last_name)
ORDER BY avg_revenue DESC
LIMIT 5;

-- 50. Find sellers who sell products in more than 3 different categories.
SELECT 
    s.seller_id,
    s.seller_name,
    COUNT(DISTINCT c.category_id) AS total_categories
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN seller s ON o.seller_id = s.seller_id
JOIN products p ON oi.product_id = p.product_id
JOIN category c ON p.category_id = c.category_id
GROUP BY s.seller_id, s.seller_name
HAVING COUNT(DISTINCT c.category_id) > 3;

-- 51. Calculate the refund rate by payment mode.
SELECT 
    p.payment_mode,
    ROUND(
        (SUM(CASE WHEN p.payment_status = 'Failed' THEN 1 ELSE 0 END) 
        + SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)) 
        * 100.0 / COUNT(*), 2
    ) AS refund_rate_percentage
FROM payments p
JOIN orders o ON p.order_id = o.order_id
GROUP BY p.payment_mode;

-- 52. Identify the peak sales hour of the day.
SELECT 
    HOUR(order_time) AS hour_,
    COUNT(*) AS total_orders
FROM orders
GROUP BY HOUR(order_time)
ORDER BY total_orders DESC
LIMIT 1;

-- 53. Show the revenue generated by each category for each quarter of 2023.
SELECT c.category_name,
       QUARTER(o.order_date) AS quarter_,
       SUM(oi.total_price) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN category c ON p.category_id = c.category_id
WHERE YEAR(o.order_date) = 2023
GROUP BY c.category_name, QUARTER(o.order_date)
ORDER BY c.category_name, QUARTER(o.order_date);

-- 54. Find customers who haven't placed an order in the last 6 months.
WITH max_date AS (
    SELECT MAX(order_date) AS latest_order_date
    FROM orders
),
customer_last_order AS (
    SELECT 
        o.customer_id,
        MAX(o.order_date) AS last_order_date
    FROM orders o
    GROUP BY o.customer_id
)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    clo.last_order_date
FROM customers c
JOIN customer_last_order clo ON c.customer_id = clo.customer_id
JOIN max_date m ON 1=1
WHERE clo.last_order_date < DATE_SUB(m.latest_order_date, INTERVAL 6 MONTH);

-- 55. Calculate the stock turnover ratio for each product.
WITH sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_units_sold
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
),
inventory_avg AS (
    SELECT 
        i.product_id,
        AVG(i.stock) AS avg_inventory
    FROM inventory i
    GROUP BY i.product_id
)
SELECT 
    s.product_id,
    s.product_name,
    s.total_units_sold,
    ia.avg_inventory,
    ROUND(s.total_units_sold / NULLIF(ia.avg_inventory, 0), 2) AS stock_turnover_ratio
FROM sales s
JOIN inventory_avg ia ON s.product_id = ia.product_id;

-- 56. Show the YoY growth in customer acquisition.
WITH yearly_customers AS (
    SELECT 
        YEAR(order_date) AS year_,
        COUNT(DISTINCT customer_id) AS new_customers
    FROM orders
    GROUP BY year_
),
growth AS (
    SELECT 
        year_,
        new_customers,
        LAG(new_customers, 1) OVER (ORDER BY year_) AS prev_year_customers
    FROM yearly_customers
)
SELECT 
    year_,
    new_customers,
    prev_year_customers,
    ROUND(((new_customers - prev_year_customers) / prev_year_customers) * 100, 2) AS yoy_growth_percentage
FROM growth
ORDER BY year_;

-- 57. Identify orders where the item quantity is greater than 3.
SELECT o.*, oi.quantity
FROM orders o 
JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.quantity > 3;

-- 58. Find the most common product category purchased by customers in each state.
WITH category_count AS (
    SELECT 
        c.state,
        ca.category_name,
        COUNT(*) AS total_orders
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN category ca ON p.category_id = ca.category_id
    GROUP BY c.state, ca.category_name
),
ranked AS (
    SELECT 
        state,
        category_name,
        total_orders,
        DENSE_RANK() OVER (PARTITION BY state ORDER BY total_orders DESC) AS rnk
    FROM category_count
)
SELECT state, category_name, total_orders
FROM ranked
WHERE rnk = 1;

-- 59. Rank sellers within each category based on their total revenue.
WITH category_wise_revenue AS (
    SELECT s.seller_name, c.category_name, 
           SUM(oi.total_price) AS total_revenue
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN seller s ON o.seller_id = s.seller_id
    JOIN products p ON p.product_id = oi.product_id
    JOIN category c ON p.category_id = c.category_id
    GROUP BY s.seller_name, c.category_name
),
ranked AS (
    SELECT seller_name, category_name, total_revenue,
           DENSE_RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS rnk
    FROM category_wise_revenue
)
SELECT seller_name, category_name, total_revenue
FROM ranked
WHERE rnk = 1
ORDER BY category_name;

-- 60. Revenue by Category
-- Find the revenue generated by each category and calculate its percentage contribution to total revenue.
WITH cte AS (
    SELECT 
        c.category_id,
        c.category_name,
        SUM(ot.total_price) AS total_category_revenue
    FROM order_items ot
    JOIN products p ON ot.product_id = p.product_id
    JOIN category c ON p.category_id = c.category_id
    GROUP BY c.category_id, c.category_name
)
SELECT 
    category_id,
    category_name,
    total_category_revenue,
    ROUND(
        total_category_revenue / (SELECT SUM(total_price) FROM order_items) * 100, 
        2
    ) AS contribute_percent
FROM cte;

-- 61. Average Order Value (AOV) per Customer
-- Calculate the average order value for each customer who has placed more than 10 orders.
-- Method 1: Based on Total Value / Total Orders
WITH cte AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(ot.total_price) AS total_value,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items ot ON o.order_id = ot.order_id
    GROUP BY c.customer_id, c.first_name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    ROUND((total_value / total_orders), 2) AS AOV,
    total_orders
FROM cte 
WHERE total_orders >= 10;

-- Method 2: Based on Average Order Items
WITH cte AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        ROUND(AVG(ot.total_price), 2) AS AOV,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items ot ON o.order_id = ot.order_id
    GROUP BY c.customer_id, c.first_name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    AOV,
    total_orders
FROM cte 
WHERE total_orders >= 10;

-- 62. Monthly Sales Trend
-- Show monthly total sales and calculate growth compared to the previous month.
WITH monthly_sales AS (
    SELECT 
        YEAR(o.order_date) AS year_,
        MONTH(o.order_date) AS month_,
        SUM(ot.quantity) AS total_units,
        SUM(ot.total_price) AS current_sale
    FROM orders o
    JOIN order_items ot ON o.order_id = ot.order_id
    GROUP BY YEAR(o.order_date), MONTH(o.order_date)
),
cte AS (
    SELECT 
        year_,
        month_,
        total_units,
        current_sale,
        LAG(current_sale, 1) OVER (ORDER BY year_, month_) AS previous_sale
    FROM monthly_sales
)
SELECT 
    year_,
    month_,
    current_sale,
    previous_sale,
    ROUND(
        ((current_sale - previous_sale) / NULLIF(previous_sale, 0)) * 100, 
        2
    ) AS monthly_growth
FROM cte
ORDER BY year_, month_;

-- 63. Customers Without Orders
-- List customers who registered but never placed an order.
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- 64.Best-Selling Categories by State
-- Identify the best-selling product category in each state.
WITH state_category_sales AS (
    SELECT 
        c.state,
        ca.category_name,
        SUM(ot.quantity) AS total_units
    FROM orders o
    JOIN order_items ot ON o.order_id = ot.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN products p ON ot.product_id = p.product_id
    JOIN category ca ON p.category_id = ca.category_id
    GROUP BY c.state, ca.category_name
),
ranked AS (
    SELECT 
        state,
        category_name,
        total_units,
        DENSE_RANK() OVER (PARTITION BY state ORDER BY total_units DESC) AS rnk
    FROM state_category_sales
)
SELECT 
    state,
    category_name AS best_selling_category,
    total_units
FROM ranked
WHERE rnk = 1
ORDER BY state;

-- 65. Customer Lifetime Value
-- Calculate total units and revenue generated by each customer across their lifetime.
SELECT 
    c.customer_id,
    CONCAT(c.first_name,' ',c.last_name) AS full_name,
    SUM(ot.quantity) AS total_units,
    SUM(ot.total_price) AS total_price
FROM orders o 
JOIN order_items ot ON o.order_id = ot.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, full_name
ORDER BY c.customer_id;

-- 66. Inventory Stock Alerts
-- List products with stock level below 300 units.
SELECT 
    p.product_id,
    p.product_name,
    i.stock,
    i.warehouse_id,
    i.last_stock_date
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock < 300;

-- 67. Shipping Delays
-- Identify orders where shipping took more than 7 days after order date.
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    o.customer_id,
    o.order_date,
    s.shipping_date,
    s.shipping_provider
FROM orders o
JOIN shipping s ON o.order_id = s.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE DATEDIFF(s.shipping_date, o.order_date) > 7;

-- 68. Top Performing Sellers
-- Find the top 5 sellers based on total sales value.
SELECT 
    s.seller_id,
    s.seller_name,
    s.origin,
    SUM(oi.total_price) AS total_sales_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN seller s ON o.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_name, s.origin
ORDER BY total_sales_value DESC
LIMIT 5;

-- 69.Payment Success Rate
-- Question - 1
-- Calculate percentage of successful payments across all orders.
SELECT 
    p.payment_status,
    COUNT(*) AS total_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM payments) * 100, 2) AS payment_rate
FROM payments p 
JOIN orders o ON p.order_id = o.order_id 
GROUP BY p.payment_status;

-- Question - 2
-- Success rate by payment mode.
SELECT 
    p.payment_mode,
    p.payment_status,
    COUNT(*) AS total_payments,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM payments), 
        2
    ) AS payment_rate_percent
FROM payments p
JOIN orders o ON p.order_id = o.order_id
GROUP BY p.payment_mode, p.payment_status
ORDER BY p.payment_mode;

-- 70. Seller Orders by Status
-- Count seller orders by different statuses (Delivered, Cancelled, etc.).
SELECT 
    s.seller_id,
    s.seller_name,
    s.origin,
    o.order_status,
    SUM(oi.quantity) AS total_count
FROM orders o 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN seller s ON o.seller_id = s.seller_id
GROUP BY s.seller_id, s.seller_name, s.origin, o.order_status
ORDER BY s.seller_id, total_count DESC;

-- 71. Seller Order Status Ratio
-- Show the ratio of each order status compared to seller’s total orders.
WITH seller_status AS (
    SELECT 
        s.seller_id,
        s.seller_name,
        s.origin,
        o.order_status,
        COUNT(o.order_id) AS status_count
    FROM orders o
    JOIN seller s ON o.seller_id = s.seller_id
    GROUP BY s.seller_id, s.seller_name, s.origin, o.order_status
),
seller_totals AS (
    SELECT 
        seller_id,
        SUM(status_count) AS total_orders
    FROM seller_status
    GROUP BY seller_id
)
SELECT 
    ss.seller_id,
    ss.seller_name,
    ss.origin,
    ss.order_status,
    ss.status_count,
    ROUND((ss.status_count / st.total_orders) * 100, 2) AS status_ratio_percent
FROM seller_status ss
JOIN seller_totals st ON ss.seller_id = st.seller_id
ORDER BY ss.seller_id, status_ratio_percent DESC;

-- 72. Pivot Orders by Status
-- Show seller orders pivoted by status.
SELECT 
    s.seller_id,
    s.seller_name,
    SUM(CASE WHEN o.order_status = 'Delivered' THEN oi.quantity ELSE 0 END) AS successful_orders,
    SUM(CASE WHEN o.order_status = 'Cancelled' THEN oi.quantity ELSE 0 END) AS cancelled_orders,
    SUM(CASE WHEN o.order_status = 'Returned'  THEN oi.quantity ELSE 0 END) AS returned_orders,
    SUM(CASE WHEN o.order_status = 'Shipped' THEN oi.quantity ELSE 0 END) AS shipped_orders,
    SUM(CASE WHEN o.order_status = 'Processing' THEN oi.quantity ELSE 0 END) AS processing_orders,
    SUM(CASE WHEN o.order_status = 'Pending'  THEN oi.quantity ELSE 0 END) AS pending_orders,
    SUM(oi.quantity) AS total_orders
FROM seller s
JOIN orders o ON s.seller_id = o.seller_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY s.seller_id, s.seller_name;

-- 73. Product Profit Margin
-- Calculate profit margin for each product.
SELECT 
    p.product_name,
    SUM(oi.quantity * oi.price_per_unit) AS total_revenue,
    SUM(oi.quantity * p.cogs) AS total_cost,
    SUM(oi.quantity * oi.price_per_unit) - SUM(oi.quantity * p.cogs) AS profit_margin
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY profit_margin DESC;

-- 74. Most Returned Products
-- Find the top 10 most returned products.
WITH cte AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(CASE WHEN o.order_status = 'Returned' THEN oi.quantity ELSE 0 END) AS returned_units
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
    ORDER BY returned_units DESC
    LIMIT 10
)
SELECT 
    product_id,
    product_name,
    total_units_sold,
    returned_units,
    ROUND((returned_units / total_units_sold) * 100, 2) AS return_percent
FROM cte;

-- 75. Inactive Sellers
-- Find sellers with no sales in the last 2 years.
SELECT *
FROM seller s
WHERE NOT EXISTS (
    SELECT 1 
    FROM orders o
    WHERE o.seller_id = s.seller_id
      AND o.order_date >= CURDATE() - INTERVAL 2 YEAR
);

-- 76. Returning Customers
-- Identify customers who returned more than 5 orders.
WITH cte AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        COUNT(o.order_id) AS total_orders,
        SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS returned_orders
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, full_name
    ORDER BY returned_orders DESC
)
SELECT 
    customer_id,
    full_name,
    total_orders,
    returned_orders,
    CASE 
        WHEN returned_orders > 5 THEN 'Returning_customer' 
        ELSE 'Normal_Customer' 
    END AS customer_category
FROM cte;
