-- 1.Coffee Consumer Count
-- Select the top 5 cities based on coffee consumers to decide where to open new coffee stores.
SELECT 
    city_name,
    ROUND((population / 1000000), 2) AS population_in_millions,
    ROUND((population * 0.25) / 1000000, 2) AS coffee_population_in_millions,
    city_rank
FROM city
ORDER BY population DESC;

-- 2.Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
    c.city_name,
    SUM(total) AS total_revenue
FROM sales s 
JOIN customers cus ON s.customer_id = cus.customer_id
JOIN city c ON cus.city_id = c.city_id 
WHERE YEAR(sale_date) = 2023 
  AND QUARTER(sale_date) = 4
GROUP BY c.city_name
ORDER BY SUM(total) DESC;

-- 3.Sales Count for Each Product
-- How many units of each coffee product have been sold?
SELECT 
    p.product_name,
    COUNT(s.product_id) AS total_sold
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY COUNT(s.product_id) DESC;

-- 4.Average Sales Amount per City
-- What is the average sales amount per customer in each city?
-- Method 1: Customer-level average.
SELECT 
    cus.customer_name,
    c.city_name,
    ROUND(AVG(s.total), 2) AS avg_amount
FROM sales s 
JOIN customers cus ON s.customer_id = cus.customer_id
JOIN city c ON cus.city_id = c.city_id 
GROUP BY cus.customer_name, c.city_name
ORDER BY AVG(s.total) DESC;

-- Method 2: City-level average.
WITH cte AS (
    SELECT 
        c.city_name,
        SUM(total) AS total_sales,
        COUNT(DISTINCT s.customer_id) AS total_customers
    FROM sales s 
    JOIN customers cus ON s.customer_id = cus.customer_id
    JOIN city c ON cus.city_id = c.city_id 
    GROUP BY c.city_name
)
SELECT 
    *,
    ROUND((total_sales / total_customers), 2) AS sales_per_customer
FROM cte
ORDER BY sales_per_customer DESC;

-- 5.City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
WITH coffee_cus_in_city AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT s.customer_id) AS total_customers
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name
),
coffee_populated_in_city AS (
    SELECT 
        city_name,
        ROUND((population * 0.25) / 1000000, 2) AS coffee_population_in_millions
    FROM city
)
SELECT 
    cc.city_name,
    cc.total_customers,
    cip.coffee_population_in_millions
FROM coffee_cus_in_city cc
JOIN coffee_populated_in_city cip 
    ON cc.city_name = cip.city_name;

-- 6.Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
WITH cte AS (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.product_id) AS total_volume,
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name 
            ORDER BY COUNT(s.product_id) DESC
        ) AS rnk
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name, p.product_name
)
SELECT 
    city_name,
    product_name,
    total_volume
FROM cte
WHERE rnk <= 3
ORDER BY city_name;

-- 7.Customer Segmentation by City
-- How many unique customers are there in each city who purchased coffee products?
SELECT 
    ci.city_name,
    COUNT(DISTINCT s.customer_id) AS unique_customers
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON c.city_id = ci.city_id
WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY ci.city_name;

-- 8.Average Sale vs Rent
-- Find each city’s average sale per customer and average rent per customer.
WITH cte AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_sales,
        COUNT(DISTINCT s.customer_id) AS unique_customers
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name
),
cte2 AS (
    SELECT 
        city_name,
        estimated_rent 
    FROM city
)
SELECT 
    cte.city_name,
    ROUND((total_sales / unique_customers), 2) AS avg_sales_per_customer,
    ROUND((estimated_rent / unique_customers), 2) AS avg_rent_per_customer
FROM cte
JOIN cte2 
    ON cte.city_name = cte2.city_name;

-- 9.Monthly Sales Growth
-- Calculate the percentage growth (or decline) in sales over different time periods (monthly).
WITH cte AS (
    SELECT 
        ci.city_name,
        MONTH(s.sale_date) AS month_,
        YEAR(s.sale_date) AS year_,
        SUM(s.total) AS total_sales
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name, MONTH(s.sale_date), YEAR(s.sale_date)
),
cte2 AS (
    SELECT 
        city_name,
        month_,
        year_,
        total_sales AS cr_month_sales,
        LAG(total_sales, 1) OVER (
            PARTITION BY city_name 
            ORDER BY year_, month_
        ) AS prev_month_sales
    FROM cte
)
SELECT 
    city_name,
    month_,
    year_,
    ROUND(
        (cr_month_sales - prev_month_sales) / NULLIF(prev_month_sales, 0) * 100.0,
        2
    ) AS growth_percent
FROM cte2
WHERE prev_month_sales IS NOT NULL;

-- 10.Market Potential Analysis
-- Identify the top 3 cities with the highest sales. Return city name, total sales, total rent, total customers, and estimated coffee consumers.
WITH cte AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_sales,
        COUNT(DISTINCT s.customer_id) AS total_customers
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON c.city_id = ci.city_id
    GROUP BY ci.city_name
),
cte2 AS (
    SELECT 
        city_name,
        estimated_rent,
        (population * 0.25) AS coffee_populated_percent
    FROM city
)
SELECT 
    cte.city_name,
    cte.total_sales,
    cte.total_customers,
    cte2.coffee_populated_percent,
    ROUND((cte.total_sales / cte.total_customers), 2) AS avg_total_sales,
    cte2.estimated_rent,
    ROUND((cte2.estimated_rent / cte.total_customers), 2) AS avg_rent
FROM cte
JOIN cte2 
    ON cte.city_name = cte2.city_name
ORDER BY total_sales DESC
LIMIT 3;
