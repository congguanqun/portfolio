-- Query 1: Sales and revenue statistics
USE mavenfuzzyfactory;

SELECT
  YEAR(created_at) AS yr,
  MONTH(created_at) AS mo,
  COUNT(DISTINCT order_id) AS number_of_sales,
  SUM(price_usd * items_purchased) AS total_revenue,
  SUM((price_usd - cogs_usd) * items_purchased) AS total_margin
FROM
  orders
WHERE
  created_at < '2013-01-04'
GROUP BY
  YEAR(created_at),
  MONTH(created_at)
ORDER BY
  yr,
  mo;

-- Query 2: Website session and conversion statistics
SELECT
  YEAR(ws.created_at) AS yr,
  MONTH(ws.created_at) AS mo,
  COUNT(DISTINCT order_id) AS orders,
  COUNT(DISTINCT order_id) / COUNT(DISTINCT ws.website_session_id) AS conversion_rate,
  SUM(price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session,
  SUM(IF(primary_product_id = 1, 1, 0)) AS product_one_orders,
  SUM(IF(primary_product_id = 2, 1, 0)) AS product_two_orders
FROM
  website_sessions ws
  LEFT JOIN orders o USING(website_session_id)
WHERE
  DATE_FORMAT(ws.created_at, '%Y-%m-%d') BETWEEN '2012-04-01' AND '2013-04-01'
GROUP BY
  YEAR(ws.created_at),
  MONTH(ws.created_at);

-- Query 3: Analysis of website pageviews and sessions
WITH temp AS (
  SELECT
    wp.created_at,
    pageview_url,
    wp.website_session_id,
    IF(DATE_FORMAT(wp.created_at, '%Y-%m-%d') < '2013-01-06', 'A.Pre_Product_2', 'B.Post_Product_2') AS time_period
  FROM
    website_pageviews wp
    LEFT JOIN website_sessions ws USING(website_session_id)
  WHERE
    DATE_FORMAT(wp.created_at, '%Y-%m-%d') BETWEEN DATE_SUB('2013-01-06', INTERVAL 3 MONTH) AND DATE_ADD('2013-01-06', INTERVAL 3 MONTH)
)
SELECT
  time_period,
  COUNT(DISTINCT website_session_id) AS sessions,
  SUM(IF(pageview_url IS NOT NULL, 1, 0)) AS w_next_page,
  SUM(IF(pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear'), 1, 0)) / COUNT(DISTINCT website_session_id) AS pct_w_next_pg,
  SUM(IF(pageview_url = '/the-original-mr-fuzzy', 1, 0)) AS to_mrfuzzy,
  SUM(IF(pageview_url = '/the-original-mr-fuzzy', 1, 0)) / COUNT(DISTINCT website_session_id) AS pct_to_mrfuzzy,
  SUM(IF(pageview_url = '/the-forever-love-bear', 1, 0)) AS to_love_bear,
  SUM(IF(pageview_url = '/the-forever-love-bear', 1, 0)) / COUNT(DISTINCT website_session_id) AS pct_to_lovebear
FROM
  temp
GROUP BY
  time_period;

-- Query 4: Conversion funnel from each product page to conversion
SELECT
  product_seen,
  COUNT(DISTINCT website_session_id) AS sessions
FROM
  (
    SELECT
      *,
      CASE
        WHEN pageview_url = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN pageview_url = '/the-forever-love-bear' THEN 'lovebear'
        ELSE NULL
      END AS product_seen
    FROM
      website_pageviews
    WHERE
      (pageview_url LIKE '/the-original-mr-fuzzy' OR pageview_url LIKE '/the-forever-love-bear')
      AND DATE(created_at) BETWEEN '2013-01-06' AND '2013-04-10'
  ) a
GROUP BY
  product_seen;
