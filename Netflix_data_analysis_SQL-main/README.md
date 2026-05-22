## SQL Project - Netflix Data Analysis

![netflix image](https://miro.medium.com/0*mU6H5xdRepR0yCcp)


- This project analyzes Netflix's content catalog to understand viewer preferences, content distribution patterns, and popularity trends across different countries and genres. Using SQL, I explored what types of content (movies vs. TV shows) dominate the platform, which ratings are most common, and how content production has evolved over time.

#### Key Objectives :-
- Analyze the distribution of Movies vs. TV Shows
- Identify the most common content ratings by type
- Find the longest movies and TV shows with most seasons
- Discover top content-producing countries
- Analyze content addition trends over time
- Explore actor popularity and genre preferences
- Categorize content based on description keywords

#### Concepts Covered :-
- Database & Table Creation 
- Data Filtering (WHERE, LIKE, IN, BETWEEN) 
- Aggregation & Grouping (GROUP BY, HAVING) 
- Joining Tables (INNER JOIN, LEFT JOIN) 
- Window Functions (ROW_NUMBER(), RANK(), DENSE_RANK())
- Date Functions (str_to_date, year, month)
- Conditional Formatting (CASE...WHEN, IF...ELSE)

#### New concept that i learned about through this project :-
- how to create regexp expresssion for the certain pattern match that we can not perform through wildcard operators in mysql
  
- REGEXP_SUBSTR(expression, pattern [, position [, occurrence [, match_type]]])

- expression → The string/column to search in (example: country column).
- pattern → The regular expression pattern to match (example: '[^,]+').
- position (optional) → Where to start searching (default = 1). 
- occurrence (optional) → Which match to return (1st, 2nd, etc.).
- match_type (optional) → Matching behavior (like case sensitivity, multi-line).

#### 1. Count the number of Movies vs TV Shows
```sql
SELECT 
    type,
    COUNT(*) AS total_count
FROM 
    netflix_data
GROUP BY 
    type;
```

#### 2. Find the most common rating for movies and TV shows
```sql
WITH cte AS (
    SELECT 
        type,
        rating,
        COUNT(*) AS total_rating_count,
        DENSE_RANK() OVER (PARTITION BY type ORDER BY COUNT(*) DESC) AS rnk
    FROM 
        netflix_data
    WHERE 
        rating IS NOT NULL
    GROUP BY 
        type, rating
)
SELECT 
    type, 
    rating, 
    total_rating_count 
FROM 
    cte 
WHERE 
    rnk = 1;
```

#### 3. List all movies released in a specific year (e.g., 2020)
```sql
SELECT 
    *
FROM 
    netflix_data
WHERE 
    type = 'Movie' 
    AND release_year = 2020;
```

#### 4. Find the top 5 countries with the most content on Netflix
```sql
WITH RECURSIVE country_split AS (
    SELECT 
        show_id,
        country,
        REGEXP_SUBSTR(country, '[^,]+', 1, 1) AS single_country,
        1 AS pos
    FROM 
        netflix_data

    UNION ALL

    SELECT 
        show_id,
        country,
        REGEXP_SUBSTR(country, '[^,]+', 1, pos + 1) AS single_country,
        pos + 1
    FROM 
        country_split
    WHERE 
        REGEXP_SUBSTR(country, '[^,]+', 1, pos + 1) IS NOT NULL
)
SELECT 
    TRIM(single_country) AS country,
    COUNT(show_id) AS total_content
FROM 
    country_split
WHERE 
    single_country IS NOT NULL
GROUP BY 
    TRIM(single_country)
ORDER BY 
    total_content DESC
LIMIT 5;
```

#### 5. Identify the longest movie
```sql
SELECT 
    *
FROM 
    netflix_data
WHERE 
    type = 'Movie' 
    AND duration = (SELECT MAX(duration) FROM netflix_data WHERE type = 'Movie');
```

#### 6. Find content added in the last 5 years(If date_added is in DATE format)
```sql
SELECT 
    *
FROM 
    netflix_data
WHERE 
    date_added >= CURDATE() - INTERVAL 5 YEAR;

SELECT 
    *
FROM 
    netflix_data
WHERE 
    STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 5 YEAR;
```

#### 7. Find all the movies/TV shows by director 'Rajiv Chilaka'
```sql
SELECT 
    *
FROM 
    netflix_data 
WHERE 
    director LIKE '%Rajiv Chilaka%';
```

#### 8. List all TV shows with more than 5 seasons
```sql
SELECT 
    *
FROM 
    netflix_data
WHERE 
    type = 'TV Show'
    AND CAST(REGEXP_SUBSTR(duration, '^[0-9]+') AS UNSIGNED) > 5;
```

#### 9. Count the number of content items in each genre
```sql
WITH RECURSIVE genre_cte AS (
    SELECT 
        show_id,
        TRIM(REGEXP_SUBSTR(listed_in, '[^,]+', 1, 1)) AS genre,
        1 AS pos,
        listed_in
    FROM 
        netflix_data

    UNION ALL

    SELECT 
        show_id,
        TRIM(REGEXP_SUBSTR(listed_in, '[^,]+', 1, pos + 1)) AS genre,
        pos + 1,
        listed_in
    FROM 
        genre_cte
    WHERE 
        REGEXP_SUBSTR(listed_in, '[^,]+', 1, pos + 1) IS NOT NULL
)
SELECT 
    genre, 
    COUNT(*) AS total_content
FROM 
    genre_cte
WHERE 
    genre <> ''
GROUP BY 
    genre
ORDER BY 
    total_content DESC;
```

#### 10. Find each year and the average numbers of content release in India on Netflix Return top 5 year with highest avg content release
```sql
WITH yearly_content AS (
    SELECT 
        YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year,
        COUNT(*) AS total_content
    FROM 
        netflix_data
    WHERE 
        country LIKE '%India%'
    GROUP BY 
        YEAR(STR_TO_DATE(date_added, '%M %d, %Y'))
)
SELECT 
    year, 
    total_content
FROM 
    yearly_content
ORDER BY 
    total_content DESC
LIMIT 5;
```

#### 11. List all movies that are documentaries
```sql
SELECT 
    title 
FROM 
    netflix_data
WHERE 
    listed_in LIKE '%Documentaries%';
```

#### 12. Find all content without a director
```sql
SELECT 
    *
FROM 
    netflix_data
WHERE 
    director IS NULL;
```

#### 13. Find how many movies actor 'Salman Khan' appeared in last 10 years
```sql
SELECT 
    COUNT(*) AS total_movies
FROM 
    netflix_data
WHERE 
    casts LIKE '%Salman Khan%' 
    AND STR_TO_DATE(date_added, '%M %d, %Y') >= CURDATE() - INTERVAL 10 YEAR
    AND type = 'Movie';
```

#### 14. Find the top 10 actors who have appeared in the highest number of movies produced in India
```sql
WITH RECURSIVE actor_cte AS (
    SELECT 
        show_id,
        TRIM(REGEXP_SUBSTR(casts, '[^,]+', 1, 1)) AS actor,
        1 AS pos,
        casts
    FROM 
        netflix_data
    WHERE 
        type = 'Movie' 
        AND country LIKE '%India%'

    UNION ALL

    SELECT 
        show_id,
        TRIM(REGEXP_SUBSTR(casts, '[^,]+', 1, pos + 1)) AS actor,
        pos + 1,
        casts
    FROM 
        actor_cte
    WHERE 
        REGEXP_SUBSTR(casts, '[^,]+', 1, pos + 1) IS NOT NULL
)
SELECT 
    actor, 
    COUNT(DISTINCT show_id) AS total_movies
FROM 
    actor_cte
WHERE 
    actor <> '' 
    AND actor IS NOT NULL
GROUP BY 
    actor
ORDER BY 
    total_movies DESC
LIMIT 10;
```

#### 15. Categorize content based on keywords 'kill' and 'violence' in description Label content containing these keywords as 'Bad' and others as 'Good'Count items in each category
```sql
WITH cte AS (
    SELECT 
        *,
        CASE 
            WHEN description LIKE '%kill%' OR description LIKE '%violence%' 
            THEN 'Bad Content' 
            ELSE 'Good Content' 
        END AS category
    FROM 
        netflix_data
)
SELECT 
    category,
    COUNT(*) AS total_count
FROM 
    cte
GROUP BY 
    category;
```
