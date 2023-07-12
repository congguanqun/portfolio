USE mavenfuzzyfactory;

-- 1. Overall session and order volume by quarter.

SELECT
    YEAR(ws.created_at) AS 'Year',
    QUARTER(ws.created_at) AS 'Quarter',
    COUNT(DISTINCT ws.website_session_id) AS overall_sessions,
    COUNT(DISTINCT order_id) AS overall_orders
FROM
    website_sessions ws
    LEFT JOIN orders o USING (website_session_id)
GROUP BY
    YEAR(ws.created_at),
    QUARTER(ws.created_at)
ORDER BY
    'Year', 'Quarter';

-- 2.Session-to-order conversion rate, revenue per order, revenue per session by Quarter.

SELECT
    YEAR(ws.created_at) AS 'Year',
    QUARTER(ws.created_at) AS 'Quarter',
    ROUND(COUNT(DISTINCT order_id)/COUNT(DISTINCT ws.website_session_id)*100,2) AS conversion_rate,
	ROUND(SUM(price_usd)/COUNT(DISTINCT order_id),2) AS revenue_per_order,
    ROUND(SUM(price_usd)/COUNT(DISTINCT ws.website_session_id),2) AS revenue_per_session
FROM
    website_sessions ws
    LEFT JOIN orders o USING (website_session_id)
GROUP BY
    YEAR(ws.created_at),
    QUARTER(ws.created_at)
ORDER BY
    'Year', 'Quarter';

-- 3. Quarterly view of orders from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search, direct type in. 

SELECT
    YEAR(ws.created_at) AS 'Year',
    QUARTER(ws.created_at) AS 'Quarter',
    COUNT(DISTINCT IF(utm_source='gsearch' AND utm_campaign='nonbrand', order_id,NULL)) AS gsearch_nonbrand,
    COUNT(DISTINCT IF(utm_source='bsearch' AND utm_campaign='nonbrand', order_id,NULL)) AS bsearch_nonbrand,
    COUNT(DISTINCT IF(utm_campaign='brand', order_id,NULL)) AS brand_search,
    COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NOT NULL, order_id,NULL)) AS organic_search,
    COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NULL, order_id,NULL)) AS direct_typein
FROM
    website_sessions ws
    LEFT JOIN orders o USING (website_session_id)
GROUP BY
    YEAR(ws.created_at),
    QUARTER(ws.created_at)
ORDER BY
    'Year', 'Quarter';

-- 4. Overall session-to-order conversion rate trends for channels by quarter.

SELECT
    YEAR(ws.created_at) AS 'Year',
    QUARTER(ws.created_at) AS 'Quarter',
    ROUND(
        COUNT(DISTINCT IF(utm_source='gsearch' AND utm_campaign='nonbrand', order_id, NULL)) /
        COUNT(DISTINCT IF(utm_source='gsearch' AND utm_campaign='nonbrand', ws.website_session_id, NULL)) * 100,
        2
    ) AS conversion_rate_gsearch_nonbrand,
    ROUND(
        COUNT(DISTINCT IF(utm_source='bsearch' AND utm_campaign='nonbrand', order_id, NULL)) /
        COUNT(DISTINCT IF(utm_source='bsearch' AND utm_campaign='nonbrand', ws.website_session_id, NULL)) * 100,
        2
    ) AS conversion_rate_bsearch_nonbrand,
    ROUND(
        COUNT(DISTINCT IF(utm_campaign='brand', order_id, NULL)) /
        COUNT(DISTINCT IF(utm_campaign='brand', ws.website_session_id, NULL)) * 100,
        2
    ) AS conversion_rate_brand_search,
    ROUND(
        COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NOT NULL, order_id, NULL)) /
        COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NOT NULL, ws.website_session_id, NULL)) * 100,
        2
    ) AS conversion_rate_organic_search,
    ROUND(
        COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NULL, order_id, NULL)) /
        COUNT(DISTINCT IF(utm_source IS NULL AND http_referer IS NULL, ws.website_session_id, NULL)) * 100,
        2
    ) AS conversion_rate_direct_typein
FROM
    website_sessions ws
    LEFT JOIN orders o USING (website_session_id)
GROUP BY
    YEAR(ws.created_at),
    QUARTER(ws.created_at)
ORDER BY
    'Year', 'Quarter';
    
-- 5. Monthly trending for revenue and margin and total sales by prodcut.

SELECT
YEAR(created_at) AS 'Year',
MONTH(created_at) AS 'Month',
SUM(CASE WHEN product_id THEN price_usd ELSE NULL END) AS mrfuzzy_rev,
SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_marg,
SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev,
SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS lovebear_marg,
SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS birthdaybear_rev,
SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS birthdaybear_marg,
SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS minibear_rev,
SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS minibear_marg,
SUM(price_usd) AS total_revenue,
SUM(price_usd - cogs_usd) AS total_margin
FROM order_items
GROUP BY YEAR(created_at),MONTH(created_at)
ORDER BY YEAR(created_at),MONTH(created_at);

-- 6. Monthly sessions to the 'product' page and conversion from product to order.

WITH temp AS
(
    -- Create a temporary table to store website session and pageview data
    SELECT
        website_session_id,
        website_pageview_id,
        DATE(created_at) AS dt
    FROM
        website_pageviews
    WHERE
        pageview_url = '/products'
)

-- Select relevant data from the temporary table and perform calculations
SELECT
    YEAR(dt) AS 'Year',
    MONTH(dt) AS 'Month',
    COUNT(DISTINCT t.website_pageview_id) AS sessions_to_product_page,
    COUNT(DISTINCT wp.website_session_id) AS next_page,
    ROUND(COUNT(DISTINCT wp.website_session_id) / COUNT(DISTINCT t.website_pageview_id) * 100, 2) AS next_page_rate,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(COUNT(DISTINCT order_id) / COUNT(DISTINCT t.website_pageview_id) * 100, 2) AS product_to_order_rate
FROM
    temp t
    LEFT JOIN website_pageviews wp ON t.website_session_id = wp.website_session_id AND t.website_pageview_id < wp.website_pageview_id
    LEFT JOIN orders o ON o.website_session_id = t.website_session_id
GROUP BY
    YEAR(dt),
    MONTH(dt);

-- 7. THE cross sold situations after 2014-12-05. 
WITH temp1 AS
(
    -- Create a temporary table to store order data based on specified criteria
    SELECT
        order_id,
        primary_product_id,
        created_at AS order_date
    FROM
        orders
    WHERE
        created_at > '2014-12-05'
),
temp2 AS
(
    -- Join the temporary table with order_items table to retrieve additional data
    SELECT *
    FROM
        temp1
        LEFT JOIN (
            SELECT * FROM order_items WHERE is_primary_item = 0
        ) a USING (order_id)
)

-- Select relevant data and perform calculations based on product IDs and order counts
SELECT
    primary_product_id,
    COUNT(DISTINCT IF(product_id = 1, order_id, NULL)) AS cross_1,
    COUNT(DISTINCT IF(product_id = 2, order_id, NULL)) AS cross_2,
    COUNT(DISTINCT IF(product_id = 3, order_id, NULL)) AS cross_3,
    COUNT(DISTINCT IF(product_id = 4, order_id, NULL)) AS cross_4,
    ROUND(COUNT(DISTINCT IF(product_id = 1, order_id, NULL)) / COUNT(DISTINCT order_id) * 100, 2) AS cross_rate_1,
    ROUND(COUNT(DISTINCT IF(product_id = 2, order_id, NULL)) / COUNT(DISTINCT order_id) * 100, 2) AS cross_rate_2,
    ROUND(COUNT(DISTINCT IF(product_id = 3, order_id, NULL)) / COUNT(DISTINCT order_id) * 100, 2) AS cross_rate_3,
    ROUND(COUNT(DISTINCT IF(product_id = 4, order_id, NULL)) / COUNT(DISTINCT order_id) * 100, 2) AS cross_rate_4
FROM
    temp2
GROUP BY
    primary_product_id;
