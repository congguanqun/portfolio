-- Query 1: Count pageviews by URL
USE mavenfuzzyfactory;

SELECT
  pageview_url,
  COUNT(DISTINCT website_pageview_id) AS page_view
FROM
  website_pageviews
WHERE
  created_at < '2012-06-09'
GROUP BY
  pageview_url
ORDER BY
  page_view DESC;

-- Query 2: Landing page using CTE
WITH temp AS (
  SELECT
    MIN(website_pageview_id) AS first,
    website_session_id,
    pageview_url
  FROM
    website_pageviews
  WHERE
    created_at < '2012-06-12'
  GROUP BY
    website_session_id
)
SELECT
  first AS landing_page,
  pageview_url,
  COUNT(DISTINCT website_session_id) AS sessions_hitting_this_landing_page
FROM
  temp;

-- Query 3: Landing page using temporary table
DROP TEMPORARY TABLE IF EXISTS first_view;

CREATE TEMPORARY TABLE first_view AS
SELECT
  MIN(website_pageview_id) AS first,
  pageview_url,
  website_session_id
FROM
  website_pageviews
GROUP BY
  website_session_id;

SELECT
  first AS landing_page,
  pageview_url,
  COUNT(DISTINCT website_session_id) AS sessions_hitting_this_landing_page
FROM
  first_view;

-- Query 4: Bounce Rate
WITH temp AS (
  SELECT *
  FROM website_pageviews
  GROUP BY website_session_id
  HAVING COUNT(*) = 1
)
SELECT COUNT(*) FROM temp WHERE created_at < '2012-06-14';

-- Query 5: Full conversion funnel
SELECT *
FROM website_pageviews
WHERE pageview_url = '/lander-1'
ORDER BY created_at;

-- Set starting date for lander-1 as '2012-06-19'
CREATE TEMPORARY TABLE Ld1_cnt AS (
  SELECT
    wp.created_at,
    wp.website_session_id,
    wp.website_pageview_id,
    wp.pageview_url
  FROM
    website_pageviews wp
    LEFT JOIN website_sessions ws USING(website_session_id)
  WHERE
    wp.created_at >= '2012-08-05'
    AND wp.created_at < '2012-09-05'
    AND website_session_id IN (SELECT website_session_id FROM website_pageviews WHERE pageview_url = '/lander-1')
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
);

SELECT
  SUM(ifLd1) AS sessions,
  SUM(ifProduct) AS to_products,
  SUM(ifFz) AS to_mrfuzzy,
  SUM(ifCart) AS to_cart,
  SUM(ifSp) AS to_shipping,
  SUM(ifBl) AS to_billing,
  SUM(ifTk) AS to_thankyou
FROM
  (
    SELECT
      website_pageview_id,
      website_session_id,
      IF(pageview_url = '/lander-1', 1, 0) AS ifLd1,
      IF(pageview_url = '/products', 1, 0) AS ifProduct,
      IF(pageview_url = '/the-original-mr-fuzzy', 1, 0) AS ifFz,
      IF(pageview_url = '/shipping', 1, 0) AS ifSp,
      IF(pageview_url = '/cart', 1, 0) AS ifCart,
      IF(pageview_url = '/billing', 1, 0) AS ifBl,
      IF(pageview_url = '/thank-you-for-your-order', 1, 0) AS ifTk
    FROM
      Ld1_cnt
  ) a;

SELECT * FROM Ld1_cnt;

SELECT
  ROUND(to_products / sessions, 4) * 100 AS to_product_rate,
  ROUND(to_mrfuzzy / to_products, 4) * 100 AS to_mrfuzzy_rate,
  ROUND(to_cart / to_mrfuzzy, 4) * 100 AS to_cart_rate,
  ROUND(to_shipping / to_cart, 4) * 100 AS to_shipping_rate,
  ROUND(to_billing / to_shipping, 4) * 100 AS to_billing_rate,
  ROUND(to_thankyou / to_billing, 4) * 100 AS to_thankyou_rate
FROM
  Ld1_cnt;

-- Query 6: AB testing for new billing page
SELECT
  website_pageview_id,
  created_at AS first_created_at
FROM
  website_pageviews
WHERE
  pageview_url = '/billing-2'
ORDER BY
  created_at
LIMIT 1;

-- '2012-09-10' is the first date when the billing page was seen
WITH temp AS (
  SELECT
    wp.created_at,
    wp.pageview_url,
    wp.website_pageview_id,
    wp.website_session_id
  FROM
    website_pageviews wp
    LEFT JOIN website_sessions ws USING(website_session_id)
  WHERE
    wp.created_at > '2012-09-10'
    AND wp.created_at < '2012-11-10'
), temp1 AS (
  SELECT
    *,
    IF(pageview_url = '/billing', 1, 0) AS ifBl,
    IF(pageview_url = '/billing-2', 1, 0) AS ifBl2,
    IF(pageview_url = '/thank-you-for-your-order', 1, 0) AS ifTk
  FROM
    temp
)
SELECT
  '/billing' AS billing_version_seen,
  SUM(ifBl) AS session,
  (
    SELECT SUM(ifTk)
    FROM temp1
    WHERE website_session_id IN (SELECT website_session_id FROM temp1 WHERE ifBl = 1)
  ) AS orders,
  ROUND((
    SELECT SUM(ifTk)
    FROM temp1
    WHERE website_session_id IN (SELECT website_session_id FROM temp1 WHERE ifBl = 1)
  ) / SUM(IF(ifBl, 1, 0)), 4) * 100 AS billing_to_order_rt
FROM
  temp1
UNION ALL
SELECT
  '/billing-2' AS billing_version_seen,
  SUM(ifBl2) AS session,
  (
    SELECT SUM(ifTk)
    FROM temp1
    WHERE website_session_id IN (SELECT website_session_id FROM temp1 WHERE ifBl2 = 1)
  ) AS orders,
  ROUND((
    SELECT SUM(ifTk)
    FROM temp1
    WHERE website_session_id IN (SELECT website_session_id FROM temp1 WHERE ifBl2 = 1)
  ) / SUM(IF(ifBl2, 1, 0)), 4) * 100 AS billing_to_order_rt
FROM
  temp1;

