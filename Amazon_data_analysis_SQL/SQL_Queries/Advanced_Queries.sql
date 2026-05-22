-- 77. Top 5 Customers by Sales (per State)
WITH cte AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name,' ',c.last_name) AS full_name,
        c.state,
        COUNT(o.order_id) AS total_orders,
        SUM(oi.total_price) AS total_price
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, full_name, c.state
),
ranked AS (
    SELECT 
        customer_id,
        full_name,
        state,
        total_orders,
        total_price,
        DENSE_RANK() OVER(PARTITION BY state ORDER BY total_price DESC) AS rnk
    FROM cte
)
SELECT 
    customer_id,
    full_name,
    state,
    total_orders,
    total_price
FROM ranked 
WHERE rnk <= 5   
ORDER BY state, rnk, total_price DESC;

-- 78. Top 5 Customers by Orders (per State)
WITH cte AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name,' ',c.last_name) AS full_name,
        c.state,
        COUNT(o.order_id) AS total_orders
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, full_name, c.state
),
ranked AS (
    SELECT 
        customer_id,
        full_name,
        state,
        total_orders,
        DENSE_RANK() OVER(PARTITION BY state ORDER BY total_orders DESC) AS rnk
    FROM cte
)
SELECT 
    customer_id,
    full_name,
    state,
    total_orders
FROM ranked 
WHERE rnk <= 5   
ORDER BY state, rnk, total_orders DESC;

-- 79. Revenue by Shipping Provider
Calculate total revenue, total orders, and average delivery time per shipping provider.
SELECT 
    s.shipping_provider,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.total_price), 2) AS total_revenue,
    ROUND(AVG(DATEDIFF(s.shipping_date, o.order_date)), 0) AS avg_delivery_time_days
FROM orders o 
JOIN shipping s ON o.order_id = s.order_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY s.shipping_provider
ORDER BY total_revenue DESC;

-- 80. Top 10 Products by Growth (2023 → 2024)
WITH cte AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        YEAR(o.order_date) AS year,
        SUM(oi.total_price) AS total_revenue
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN category c ON p.category_id = c.category_id
    WHERE YEAR(o.order_date) IN (2023, 2024)
    GROUP BY p.product_id, p.product_name, c.category_name, YEAR(o.order_date)
),
year_wise_revenue AS (
    SELECT 
        product_id,
        product_name,
        category_name,
        SUM(CASE WHEN year = 2023 THEN total_revenue ELSE 0 END) AS 2023_revenue,
        SUM(CASE WHEN year = 2024 THEN total_revenue ELSE 0 END) AS 2024_revenue
    FROM cte
    GROUP BY product_id, product_name, category_name
),
growth_ratio AS (
    SELECT 
        product_id,
        product_name,
        category_name,
        2023_revenue,
        2024_revenue,
        (2024_revenue - 2023_revenue) AS revenue_diff,
        ROUND(((2024_revenue - 2023_revenue) / 2023_revenue), 2) AS growth_pattern
    FROM year_wise_revenue
),
ranked_ratio AS (
    SELECT 
        product_id,
        product_name,
        category_name,
        2023_revenue,
        2024_revenue,
        revenue_diff,
        growth_pattern,
        DENSE_RANK() OVER(ORDER BY growth_pattern DESC) AS rnk
    FROM growth_ratio
)
SELECT 
    product_id,
    product_name,
    category_name,
    2023_revenue,
    2024_revenue,
    revenue_diff,
    CONCAT(growth_pattern, '%') AS growth_percent
FROM ranked_ratio
WHERE rnk <= 10;

-- 82.Perform a cohort analysis to calculate the retention rate of customers based on the month of their
--  first purchase.
WITH first_purchase AS (
    -- Find each customer's first purchase month
    SELECT 
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS first_purchase_month
    FROM orders
    GROUP BY customer_id
),
cohort_activity AS (
    -- Track each customer's activity month
    SELECT 
        o.customer_id,
        DATE_FORMAT(fp.first_purchase_month, '%Y-%m') AS cohort_month,
        DATE_FORMAT(o.order_date, '%Y-%m') AS activity_month
    FROM orders o
    JOIN first_purchase fp 
        ON o.customer_id = fp.customer_id
),
retention AS (
    -- Count unique customers in each cohort and activity month
    SELECT 
        cohort_month,
        activity_month,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM cohort_activity
    GROUP BY cohort_month, activity_month
),
cohort_size AS (
    -- Total customers in each cohort (denominator for retention rate)
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_customers
    FROM first_purchase
    GROUP BY cohort_month
)
SELECT 
    r.cohort_month,
    r.activity_month,
    r.active_customers,
    c.cohort_customers,
    ROUND((r.active_customers * 100.0 / c.cohort_customers), 2) AS retention_rate
FROM retention r
JOIN cohort_size c 
    ON r.cohort_month = c.cohort_month
ORDER BY r.cohort_month, r.activity_month;

-- 83.Identify products that are frequently bought together (using order_id).
SELECT 
    oi1.product_id AS product_id_1,
    p1.product_name AS product_name_1,
    oi2.product_id AS product_id_2,
    p2.product_name AS product_name_2,
    COUNT(*) AS frequency
FROM order_items oi1
JOIN order_items oi2 
    ON oi1.order_id = oi2.order_id 
   AND oi1.product_id < oi2.product_id  
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY oi1.product_id, p1.product_name, oi2.product_id, p2.product_name
HAVING COUNT(*) > 1 
ORDER BY frequency DESC
LIMIT 10;

-- 84.Calculate the customer lifetime value (CLV) for each customer (total spend / tenure in months).
WITH customer_summary AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,
        SUM(oi.total_price) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, CONCAT(c.first_name, ' ', c.last_name)
),
clv_calc AS (
    SELECT 
        customer_id,
        full_name,
        total_spend,
        TIMESTAMPDIFF(MONTH, first_order_date, last_order_date) AS tenure_months
    FROM customer_summary
)
SELECT 
    customer_id,
    full_name,
    total_spend,
    CASE 
        WHEN tenure_months = 0 THEN ROUND(total_spend / 1, 2)
        ELSE ROUND(total_spend / tenure_months, 2)
    END AS clv
FROM clv_calc
ORDER BY clv DESC;

-- 85.Calculate the 7-day rolling average of daily revenue for December 2023.
WITH cte AS (
    SELECT 
        o.order_date,
        SUM(oi.total_price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE YEAR(o.order_date) = 2023 
      AND MONTH(o.order_date) = 12
    GROUP BY o.order_date
    ORDER BY o.order_date
)
SELECT 
    order_date,
    revenue,
    ROUND(AVG(revenue) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS rolling_7day_avg
FROM cte;

-- 86.Identify customers who upgraded their average order value from one year to the next (e.g., 2022 vs 2023).
WITH cte AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        YEAR(o.order_date) AS year_,
        ROUND(AVG(oi.total_price), 2) AS avg_order_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE YEAR(o.order_date) IN (2022, 2023)
    GROUP BY c.customer_id, full_name, YEAR(o.order_date)
),
pivot AS (
    SELECT 
        customer_id,
        full_name,
        MAX(CASE WHEN year_ = 2022 THEN avg_order_value END) AS `2022_revenue`,
        MAX(CASE WHEN year_ = 2023 THEN avg_order_value END) AS `2023_revenue`
    FROM cte
    GROUP BY customer_id, full_name
)
SELECT 
    customer_id,
    full_name,
    `2022_revenue`,
    `2023_revenue`
FROM pivot
WHERE `2023_revenue` > `2022_revenue`;

-- 87.For each product, calculate the days when it was the top-selling product in its category.
WITH daily_sales AS (
    SELECT 
        ca.category_name,
        p.product_name,
        o.order_date,
        SUM(oi.quantity) AS total_units
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN category ca ON p.category_id = ca.category_id
    GROUP BY ca.category_name, p.product_name, o.order_date
),
ranked AS (
    SELECT 
        category_name,
        product_name,
        order_date,
        total_units,
        DENSE_RANK() OVER (
            PARTITION BY category_name, order_date 
            ORDER BY total_units DESC
        ) AS rnk
    FROM daily_sales
)
SELECT 
    category_name,
    product_name,
    order_date,
    total_units
FROM ranked
WHERE rnk = 1
ORDER BY category_name, order_date, product_name;

-- 88.Use a recursive CTE to create a date dimension table and join it to analyze daily sales, even for days with no orders.Recursive CTE to generate a date dimension
SET SESSION cte_max_recursion_depth = 5000;

WITH RECURSIVE calender AS (
    SELECT MIN(order_date) AS date_
    FROM orders
    UNION ALL
    SELECT DATE_ADD(date_, INTERVAL 1 DAY)
    FROM calender
    WHERE date_ < (SELECT MAX(order_date) FROM orders)
),
daily_sales AS (
    SELECT 
        o.order_date,
        SUM(oi.total_price) AS total_sales
    FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.order_date
)
SELECT 
    c.date_ AS order_date,
    COALESCE(ds.total_sales, 0) AS total_sales
FROM calender c
LEFT JOIN daily_sales ds 
    ON c.date_ = ds.order_date
ORDER BY order_date;

-- 89.Identify the "next product" a customer buys after purchasing a specific product (e.g., 'Wireless Earbuds')
  SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        p.product_name,
        LEAD(p.product_name, 1) OVER (
            PARTITION BY c.customer_id ORDER BY o.order_date
        ) AS next_product
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN customers c ON o.customer_id = c.customer_id
    
-- 90.Predict potential stock-outs: Identify products where the current stock is less than the average weekly sales volume.
WITH weekly_sales AS (
    SELECT 
        oi.product_id,
        SUM(oi.quantity) / COUNT(DISTINCT YEARWEEK(o.order_date)) AS avg_weekly_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY oi.product_id
)
SELECT 
    p.product_id,
    p.product_name,
    i.stock,
    ROUND(w.avg_weekly_sales, 2) AS avg_weekly_sales
FROM products p
JOIN inventory i ON p.product_id = i.product_id
JOIN weekly_sales w ON p.product_id = w.product_id
WHERE i.stock < w.avg_weekly_sales;

-- 91.Calculate the median order value for the entire dataset (without using MEDIAN() if not available).
with cte as (
    select 
        o.order_id,
        o.order_date,
        oi.total_price,
        row_number() over(order by oi.total_price) as row_num_asc,
        row_number() over(order by oi.total_price desc) as row_num_desc
    from orders o
    join order_items oi on o.order_id=oi.order_id
)
select avg(total_price)
from cte
where abs(cast(row_num_asc as signed) - cast(row_num_desc as signed)) <= 1;

-- 92.Find customers who have purchased from at least 3 different categories but have never purchased from the 'electronics' category.
select 
    concat(c.first_name, ' ', c.last_name) as full_name,
    count(distinct ca.category_id) as category_count
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on p.product_id = oi.product_id
join category ca on p.category_id = ca.category_id
join customers c on o.customer_id = c.customer_id
where ca.category_name != 'Electronics' 
group by concat(c.first_name, ' ', c.last_name)
having count(distinct ca.category_id) >= 3;

-- 93.Identify the most significant drop (≥20%) in monthly sales for any product compared to the previous month.
WITH cte AS (
    SELECT 
        p.product_name,
        YEAR(o.order_date) AS year_,
        MONTH(o.order_date) AS month_,
        SUM(oi.total_price) AS current_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.product_name, YEAR(o.order_date), MONTH(o.order_date)
),
cte2 AS (
    SELECT 
        product_name,
        year_,
        month_,
        current_sales,
        LAG(current_sales, 1) OVER (PARTITION BY product_name ORDER BY year_, month_) AS previous_sales
    FROM cte
),
cte3 AS (
    SELECT  
        product_name,
        year_,
        month_,
        current_sales,
        previous_sales,
        ROUND(((current_sales - previous_sales) / previous_sales) * 100, 2) AS growth_ratio
    FROM cte2
    WHERE previous_sales IS NOT NULL
)
SELECT 
    product_name,
    year_,
    month_,
    current_sales,
    previous_sales,
    growth_ratio
FROM cte3
WHERE growth_ratio <= -20  
ORDER BY product_name, year_, month_;

-- 94.Create a complete sales report with a single query that aggregates revenue, units sold, average order value, and number of customers by category, state, and month.
SELECT 
    ca.category_name,
    c.state,
    YEAR(o.order_date) AS year_,
    MONTH(o.order_date) AS month_,
    SUM(oi.total_price) AS total_revenue,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.total_price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
    COUNT(DISTINCT c.customer_id) AS num_customers

FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN category ca ON p.category_id = ca.category_id
JOIN customers c ON o.customer_id = c.customer_id

GROUP BY 
    ca.category_name,c.state,YEAR(o.order_date),MONTH(o.order_date)

ORDER BY 
    year_, month_, ca.category_name, c.state;

-- 95.Find sellers whose sales in the last quarter are down by more than 15% compared to the previous quarter.
WITH seller_quarterly_sales AS (
    SELECT 
        s.seller_id,
        s.seller_name,
        YEAR(o.order_date) AS year_,
        QUARTER(o.order_date) AS quarter_,
        SUM(oi.total_price) AS total_sales
    FROM seller s
    JOIN orders o ON s.seller_id = o.seller_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY s.seller_id, s.seller_name, YEAR(o.order_date), QUARTER(o.order_date)
),
sales_comparison AS (
    SELECT 
        seller_id,
        seller_name,
        year_,
        quarter_,
        total_sales AS current_sales,
        LAG(total_sales, 1) OVER (
            PARTITION BY seller_id ORDER BY year_, quarter_
        ) AS prev_sales
    FROM seller_quarterly_sales
)
SELECT 
    seller_name,
    year_,
    quarter_,
    current_sales,
    prev_sales,
    ROUND(((prev_sales - current_sales) / prev_sales) * 100, 2) AS growth_percentage
FROM sales_comparison
WHERE prev_sales IS NOT NULL
  AND ((prev_sales - current_sales) / prev_sales) * 100 > 15
ORDER BY year_, quarter_, seller_name;

-- 96.Assign each customer to a tier ('Platinum', 'Gold', 'Silver') based on their total spending percentile (Top 5%, Next 15%, Next 30%).
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        SUM(oi.total_price) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_id, full_name
),
ranked AS (
    SELECT 
        customer_id,
        full_name,
        total_spent,
        NTILE(100) OVER (ORDER BY total_spent DESC) AS percentile_rank
    FROM customer_spending
)
SELECT 
    customer_id,
    full_name,
    total_spent,
    CASE 
        WHEN percentile_rank <= 5 THEN 'Platinum'   
        WHEN percentile_rank <= 20 THEN 'Gold'      
        WHEN percentile_rank <= 50 THEN 'Silver'
        ELSE 'Others'                            
    END AS customer_tier
FROM ranked
ORDER BY total_spent DESC;

-- 97.Calculate the correlation between the day of the week and the average order value.
WITH cte AS (
    SELECT 
        DAYNAME(o.order_date) AS day_of_week,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.total_price) AS total_day_sales
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY DAYNAME(o.order_date)
)
SELECT 
    day_of_week,
    total_orders,
    total_day_sales,
    ROUND(total_day_sales / total_orders, 2) AS avg_order_value
FROM cte;

-- 98.Executive Summary Query: Create a single, comprehensive query that provides a high-level dashboard with: Total Revenue, Total Orders, Average Order Value, Top Selling Category, Top Performing State,and Customer Count for the current year (2024).
WITH base AS (
    SELECT 
        o.order_id,
        o.customer_id,
        c.state,
        oi.total_price,
        oi.quantity,
        ca.category_name
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN category ca ON p.category_id = ca.category_id
    WHERE YEAR(o.order_date) = 2024
),
agg AS (
    SELECT 
        SUM(total_price) AS total_revenue,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(DISTINCT customer_id) AS customer_count,
        ROUND(SUM(total_price) / COUNT(DISTINCT order_id), 2) AS avg_order_value
    FROM base
),
top_category AS (
    SELECT category_name
    FROM base
    GROUP BY category_name
    ORDER BY SUM(total_price) DESC
    LIMIT 1
),
top_state AS (
    SELECT state
    FROM base
    GROUP BY state
    ORDER BY SUM(total_price) DESC
    LIMIT 1
)
SELECT 
    a.total_revenue,
    a.total_orders,
    a.customer_count,
    a.avg_order_value,
    tc.category_name AS top_selling_category,
    ts.state AS top_performing_state
FROM agg a
CROSS JOIN top_category tc
CROSS JOIN top_state ts;
