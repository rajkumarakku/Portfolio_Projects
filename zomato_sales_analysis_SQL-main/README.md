## SQL PROJECT - ZOMATO SALES ANALYSIS

![image](https://miro.medium.com/v2/resize:fit:1400/1*YpjmY2thJ-Oes_T1al5FhA.jpeg)

#### Concepts that are learned from this project :-
- Database creation and Table Design 
- Data Retrieval and Filtering
- Aggregation and Grouping
- Joining Tables (Left Join, Inner Join)
- Window Functions (Rank, Dense Rank, LAG, LEAD)
- Create CTE, Joining multiple CTEs By using Inner Join
- Date and Time Functions
- Conditional Logic, Data Segmentation(CASE Statement)

#### Solve Questions on :-
- Customer Behaviour and Insights
- Order and Sales Analysis 
- Restaurant Performance
- Rider Efficiency

### ER Diagram:-
![ER_Diagram](https://github.com/parthpatoliya97/zomato_sales_analysis_SQL/blob/main/ER-Diagram.png?raw=true)

#### Table: customers

- customer_id: A unique identifier for each customer. (Crucial for linking orders to a specific person)

- customer_name: The full name of the customer. (Essential for identification and communication)

- reg_date: The date the customer signed up. (Important for tracking user growth and calculating customer lifetime value)
-------------------------------------------------------------------------------------------------------------------------------------

#### Table: restaurants

- restaurant_id: A unique identifier for each restaurant. (Crucial for linking orders and knowing where food is from)

- restaurant_name: The name of the restaurant. (Essential for display and selection by customers)

- city: The location of the restaurant. (Vital for determining availability based on customer's delivery address)

- opening_time / closing_time: The daily operating hours. (Critical for defining when orders can be placed)

- total_opening_hours: The pre-calculated number of hours open. (Important for analytics and reporting on restaurant performance)
---------------------------------------------------------------------------------------------------------------------------------------

#### Table: riders

- rider_id: A unique identifier for each rider. (Essential for assigning and tracking deliveries)

- rider_name: The full name of the rider. (Needed for management and support purposes)

- signup_date: The date the rider joined the platform. (Important for analytics on rider retention and growth)
--------------------------------------------------------------------------------------------------------------------------------------

#### Table: orders

- order_id: A unique identifier for each order. (The most important key for tracking an order's entire lifecycle)

- customer_id: Links to the customer who placed the order. (Essential for customer history and personalization)

- restaurant_id: Links to the restaurant fulfilling the order. (Key for restaurant sales reports)

- order_item: A description of what was ordered. (The fundamental detail of the transaction)

- order_date / order_time: The timestamp of when the order was placed. (Vital for sales trends, reporting, and operational analysis)

- order_status: The current state of the order (e.g., preparing, cancelled). (Critical for real-time tracking and workflow management)

- total_amount: The monetary value of the order. (Fundamental for financial reporting and revenue calculation)
-------------------------------------------------------------------------------------------------------------------------------------------

#### Table: delivery

- delivery_id: A unique identifier for each delivery event. (Important for tracking individual delivery performance)

- order_id: Links to the specific order being delivered. (Creates the connection between the sale and its fulfillment)

- delivery_status: The current state of the delivery (e.g., dispatched, delivered). (Crucial for real-time customer tracking and rider management)

- delivery_time: The timestamp of the delivery status update. (Key for measuring delivery speed and rider performance metrics)

- rider_id: Links to the rider assigned to the delivery. (Essential for assigning work and calculating rider pay/scores)
----------------------------------------------------------------------------------------------------------------------------------------------------

#### 1.Top 5 Most Frequently Ordered Dishes (by a Specific Customer in Last 1 Year)

- Find the top 5 most ordered dishes by customer Erik Dawson in the last one year.
```sql
WITH cte AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        o.order_item AS dishes,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM orders o 
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_date > CURDATE() - INTERVAL 1 YEAR 
      AND c.customer_name = 'Erik Dawson'
    GROUP BY c.customer_id, c.customer_name, o.order_item
)
SELECT customer_name, dishes, total_orders
FROM cte
WHERE rnk <= 5;
```

#### 2.Popular Time Slots (2-Hour Buckets)

- Identify peak order times by grouping orders into 2-hour slots.
---
- Manual Sloting
```sql
SELECT 
    CASE 
        WHEN HOUR(order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN HOUR(order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN HOUR(order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN HOUR(order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN HOUR(order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN HOUR(order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN HOUR(order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN HOUR(order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN HOUR(order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN HOUR(order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN HOUR(order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        WHEN HOUR(order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
    END AS time_slots,
    COUNT(order_id) AS total_orders
FROM orders 
GROUP BY time_slots
ORDER BY total_orders DESC;

```
- Optimal Dynamic Slotting:
```sql
SELECT 
    FLOOR(HOUR(order_time) / 2) * 2 AS start_time,
    FLOOR(HOUR(order_time) / 2) * 2 + 2 AS end_time,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY start_time, end_time
ORDER BY total_orders DESC;

```

#### 3.Average Order Value (AOV) of Frequent Customers
- Find customers who have placed more than 750 orders and calculate their average order value (AOV).
- This identifies super-loyal customers.
```sql
SELECT 
    c.customer_id,
    c.customer_name,
    AVG(o.total_amount) AS average_order_value,
    COUNT(o.order_id) AS total_orders
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(order_id) > 750;

```
#### 4.High Value Customers
- List customers who have spent over 100K in total on food orders.
- These are premium customers that need loyalty programs.
```sql
SELECT 
    c.customer_id,
    c.customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 100000;

```

#### 5.Orders Without Delivery
- Find orders that were placed but not delivered, grouped by restaurant & city.
- This helps track service failures.
```sql
SELECT 
    r.restaurant_name,
    r.city,
    COUNT(o.order_id) AS total_undelivered_orders
FROM orders o 
LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
LEFT JOIN delivery d ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY r.restaurant_name, r.city
ORDER BY total_undelivered_orders DESC;

```
#### 6.Restaurant Revenue Ranking
- rank restaurants based on their total revenue from the last year 
```sql
WITH cte AS (
    SELECT 
        r.restaurant_name,
        r.city,
        SUM(o.total_amount) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rnk
    FROM orders o 
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    WHERE o.order_date >= CURDATE() - INTERVAL 1 YEAR
    GROUP BY r.restaurant_name, r.city
)
SELECT *
FROM cte
WHERE rnk = 1;
```

#### 7.most popular dish by city
- identify teh most popular dish in each city based on number of orders
```sql
WITH cte AS (
    SELECT 
        r.city,
        o.order_item AS dish,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS rnk
    FROM orders o 
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.city, o.order_item
)
SELECT city, dish, total_orders
FROM cte
WHERE rnk = 1
ORDER BY city;
```
#### 8.customer churn
- find the cusotmer who have ot placed any order in 2025 but did in 2024
```sql
SELECT DISTINCT customer_id
FROM orders
WHERE YEAR(order_date) = 2024
  AND customer_id NOT IN (
      SELECT customer_id FROM orders WHERE YEAR(order_date) = 2025
  );
```

#### 9.cancellation rate comparison
- calculate and compare the cancellation rate for each restaurant between previous and current year
```sql
WITH cancellation_24 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        SUM(CASE WHEN d.delivery_id IS NULL AND o.order_status = 'cancelled' THEN 1 ELSE 0 END) AS not_delivered
    FROM orders o 
    LEFT JOIN delivery d ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY o.restaurant_id
),
py_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        (not_delivered / total_orders) * 100 AS cancellation_ratio
    FROM cancellation_24
),
cancellation_25 AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS total_orders,
        SUM(CASE WHEN d.delivery_id IS NULL AND o.order_status = 'cancelled' THEN 1 ELSE 0 END) AS not_delivered
    FROM orders o 
    LEFT JOIN delivery d ON o.order_id = d.order_id
    WHERE YEAR(o.order_date) = 2025
    GROUP BY o.restaurant_id
),
cy_data AS (
    SELECT 
        restaurant_id,
        total_orders,
        not_delivered,
        (not_delivered / total_orders) * 100 AS cancellation_ratio
    FROM cancellation_25
)
SELECT 
    pyd.restaurant_id,
    pyd.cancellation_ratio AS prev_year_cancellation_ratio,
    cyd.cancellation_ratio AS curr_year_cancellation_ratio,
    (cyd.cancellation_ratio - pyd.cancellation_ratio) AS ratio_change,
    CASE 
        WHEN cyd.cancellation_ratio > pyd.cancellation_ratio THEN 'Increased'
        WHEN cyd.cancellation_ratio < pyd.cancellation_ratio THEN 'Decreased'
        ELSE 'No Change'
    END AS trend
FROM py_data pyd
JOIN cy_data cyd ON pyd.restaurant_id = cyd.restaurant_id
ORDER BY ratio_change DESC;

```

#### 10. rider average delivery time
- determine each rider's delivery time
```sql
SELECT 
    d.rider_id,
    o.order_id,
    o.order_time,
    d.delivery_time,
    TIMESTAMPDIFF(SECOND, o.order_time, d.delivery_time) AS duration_seconds,
    TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) AS duration_minutes
FROM orders o
JOIN delivery d ON o.order_id = d.order_id
WHERE TIMESTAMPDIFF(SECOND, o.order_time, d.delivery_time) > 0  
  AND d.delivery_status = 'delivered';
```

#### 11.monthly restaurant growth ratio
- calculate each restaurant's growth ratio based on total numbers of delivered orders since its joining
```sql
WITH cte AS (
    SELECT 
        o.restaurant_id,
        COUNT(o.order_id) AS current_month_orders,
        DATE_FORMAT(o.order_date, '%m/%y') AS month_year,
        LAG(COUNT(o.order_id), 1) OVER (PARTITION BY o.restaurant_id ORDER BY DATE_FORMAT(o.order_date, '%m/%y')) AS prev_month_orders
    FROM orders o
    JOIN delivery d ON o.order_id = d.order_id 
    GROUP BY o.restaurant_id, DATE_FORMAT(o.order_date, '%m/%y')
)
SELECT 
    restaurant_id,
    month_year,
    current_month_orders,
    prev_month_orders,
    ROUND(((current_month_orders - prev_month_orders) / prev_month_orders) * 100, 2) AS growth_ratio
FROM cte;
```

#### 12.customer segmentation
- segment customer into 'gold' , 'silver' based on their total spending by compating it with average order value
- total number of orders and total number of revenue
```sql
WITH customer_categories AS (
    SELECT 
        customer_id,
        SUM(total_amount) AS total_spending,
        COUNT(order_id) AS total_orders,
        CASE 
            WHEN SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold'
            ELSE 'Silver'
        END AS customer_category
    FROM orders 
    GROUP BY customer_id
)
SELECT 
    customer_category,
    SUM(total_spending) AS total_amount_spent,
    SUM(total_orders) AS total_orders_placed,
    COUNT(customer_id) AS number_of_customers,
    ROUND(AVG(total_spending), 2) AS avg_spending_per_customer
FROM customer_categories
GROUP BY customer_category
ORDER BY total_amount_spent DESC;
```

#### 13. rider's monthly earnings
- calculate each rider's monthly earnings assume that rider earns 8% of the order_amount
```sql
SELECT 
    d.rider_id,
    DATE_FORMAT(o.order_date, '%m/%y') AS months,
    SUM(o.total_amount) AS total_revenue,
    ROUND(SUM(o.total_amount) * 0.08, 0) AS rider_earning
FROM orders o
JOIN delivery d ON o.order_id = d.order_id
GROUP BY d.rider_id, DATE_FORMAT(o.order_date, '%m/%y')
ORDER BY d.rider_id, months;
```

#### 14.rider rating analysis
- find the number of 5 star,4 star,3 star ratings of each rider has
- rider recieved this rating based on delivery time
- if order deliver in less than 15 minutes then rider gets 5 star rating
- if it delivered between 15 and 20 minutes then rider gets 4 star rating
- above the 20 minutes it gets 3 star rating
```sql
WITH cte AS (
    SELECT 
        d.rider_id,
        r.rider_name,
        CASE 
            WHEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) < 15 THEN '5-star Rating'
            WHEN TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) BETWEEN 15 AND 20 THEN '4-star Rating'
            ELSE '3-star Rating'
        END AS Rating
    FROM orders o 
    JOIN delivery d ON o.order_id = d.order_id
    JOIN riders r ON d.rider_id = r.rider_id
    WHERE d.delivery_status = 'delivered'
)
SELECT 
    rider_id,
    rider_name,
    SUM(CASE WHEN rating = '5-star Rating' THEN 1 ELSE 0 END) AS five_star_ratings,
    SUM(CASE WHEN rating = '4-star Rating' THEN 1 ELSE 0 END) AS four_star_ratings,
    SUM(CASE WHEN rating = '3-star Rating' THEN 1 ELSE 0 END) AS three_star_ratings,
    COUNT(*) AS total_deliveries
FROM cte
GROUP BY rider_id, rider_name
ORDER BY five_star_ratings DESC;
```

#### 15.Order frequency by day (peak day per restaurant)
- analyze order per day of the week and identify peak day for each restaurant
```sql
WITH cte AS (
    SELECT 
        r.restaurant_name,
        DAYNAME(o.order_date) AS day_,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) AS rnk
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY r.restaurant_name, DAYNAME(o.order_date)
)
SELECT *
FROM cte
WHERE rnk = 1;
```

#### 16.customer lifetime value
- calculate total revenue generated by each customer over all their orders
```sql
SELECT 
    c.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS clv_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name;
```

#### 17.monthly sales trends
- identify monthly sales trends by comapring current month total sales to previous month total sales
```sql
SELECT 
    YEAR(order_date) AS year_,
    MONTH(order_date) AS month_,
    SUM(total_amount) AS current_month_sales,
    LAG(SUM(total_amount), 1) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) AS previous_month_sales
FROM orders 
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY year_, month_;
```

#### 18.rider efficiency
- evaluate rider efficiency by determining average delivery time identify those with lowest and highest average
```sql
WITH cte AS (
    SELECT 
        d.rider_id,
        r.rider_name,
        TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) AS delivery_time_minutes
    FROM orders o 
    JOIN delivery d ON o.order_id = d.order_id
    JOIN riders r ON d.rider_id = r.rider_id
    WHERE d.delivery_status = 'delivered'
)
SELECT 
    rider_id,
    rider_name,
    ROUND(AVG(delivery_time_minutes), 2) AS avg_delivery_time,
    CASE 
        WHEN AVG(delivery_time_minutes) < (SELECT AVG(delivery_time_minutes) FROM cte) THEN 'Efficient'
        ELSE 'Not Efficient'
    END AS efficiency
FROM cte
GROUP BY rider_id, rider_name
ORDER BY avg_delivery_time ASC;
```

#### 19.order item popularity
- track the popularity of specific products over time and identified seasonal demand spikes
```sql
WITH cte AS (
    SELECT 
        *,
        CASE 
            WHEN MONTH(order_date) IN (1, 2, 3, 4) THEN 'Winter'
            WHEN MONTH(order_date) IN (5, 6, 7, 8) THEN 'Summer'
            ELSE 'Monsoon'
        END AS seasons
    FROM orders
)
SELECT 
    order_item,
    seasons,
    COUNT(order_id) AS total_orders
FROM cte
GROUP BY order_item, seasons
ORDER BY order_item, total_orders DESC;
```

#### 20.rank each city based on total revenue
```sql
SELECT 
    r.city,
    SUM(o.total_amount) AS revenue,
    DENSE_RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS rnk
FROM orders o 
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
GROUP BY r.city
ORDER BY r.city;
```
