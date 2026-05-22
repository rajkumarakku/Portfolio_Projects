## SQL PROJECT - PIZZA SALES ANALYSIS
![piiza restaurant](https://thumbs.dreamstime.com/b/delicious-pizza-table-restaurant-ai-generative-design-background-instagram-facebook-wall-painting-wallpaper-photo-324132045.jpg)

### Topics that are covered
- Fetching data from tables
- JOINS
- CTE (Common Table Expressions)
- Aggregate Functions 
- Group by , Order by , LIMIT
- Window Functions

### Practise Questions :-

### 1.Retrieve the total number of orders placed.
```sql
SELECT COUNT(order_id) AS total_orders 
FROM orders;

```

### 2.Calculate the total revenue generated from pizza sales
```sql
SELECT ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id;

```

### 3.Identify the highest-priced pizza
```sql
SELECT pt.name, p.price
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

```

### 4.Identify the most common pizza size ordered
```sql
SELECT p.size, COUNT(od.order_detail_id) AS total_count
FROM pizzas p 
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY total_count DESC
LIMIT 1;

```

### 5.List the top 5 most ordered pizza types along with their quantities
```sql
SELECT pt.name, SUM(od.quantity) AS total_quantity
FROM pizzas p 
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;

```

### 6.Find the total quantity of each pizza category ordered
```sql
SELECT pt.category, SUM(od.quantity) AS total_quantity
FROM pizzas p 
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.category
ORDER BY total_quantity;

```

### 7.Determine the distribution of orders by hour of the day
```sql
SELECT HOUR(order_time) AS hour, COUNT(order_id) AS total_orders
FROM orders
GROUP BY hour
ORDER BY hour;

```

### 8.Find the category-wise distribution of pizzas
```sql
SELECT category, COUNT(name) AS pizza_count
FROM pizza_types
GROUP BY category;

```

### 9.Calculate the average number of pizzas ordered per day
```sql
WITH cte AS (
    SELECT o.order_date, SUM(od.quantity) AS quantity
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.order_date
)
SELECT ROUND(AVG(quantity), 0) AS average_quantity
FROM cte;

```

### 10.Determine the top 3 most ordered pizza types based on revenue
```sql
SELECT pt.name, ROUND(SUM(p.price * od.quantity), 1) AS total_revenue
FROM pizzas p
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY total_revenue DESC
LIMIT 3;

```

### 11.Calculate the percentage contribution of each pizza type to total revenue
```sql
WITH type_wise_revenue AS (
    SELECT pt.name, SUM(p.price * od.quantity) AS revenue
    FROM pizzas p 
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    JOIN order_details od ON p.pizza_id = od.pizza_id
    GROUP BY pt.name
)
SELECT name, ROUND((revenue / (SELECT SUM(revenue) FROM type_wise_revenue)) * 100, 2) AS total_percentage
FROM type_wise_revenue
GROUP BY name;

```

### 12.Analyze the cumulative revenue generated over time
```sql
WITH cte AS (
    SELECT 
        o.order_date,
        ROUND(SUM(p.price * od.quantity), 2) AS total_sum
    FROM order_details od
    JOIN orders o ON od.order_id = o.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY o.order_date
)
SELECT 
    order_date,
    total_sum,
    ROUND(SUM(total_sum) OVER (ORDER BY order_date), 2) AS cumulative_sum
FROM cte
ORDER BY order_date;

```

### 13.Determine the top 3 most ordered pizza types based on revenue for each pizza category
```sql
WITH cte AS (
    SELECT pt.category, pt.name, SUM(p.price * od.quantity) AS revenue
    FROM pizzas p
    JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    JOIN order_details od ON p.pizza_id = p.pizza_id
    GROUP BY pt.name, pt.category
),
cte2 AS (
    SELECT *, DENSE_RANK() OVER(PARTITION BY category ORDER BY revenue DESC) AS rnk
    FROM cte
)
SELECT category, name 
FROM cte2
WHERE rnk <= 3;

```
