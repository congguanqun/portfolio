USE mavenfuzzyfactory;

-- Analyze the trend of gsearch-related orders
SELECT 
    order_time, 
    COUNT(DISTINCT order_id) AS order_cnt
FROM
    (
        SELECT 
            ws.website_session_id,
            ws.created_at AS web_time,
            order_id,
            MONTH(o.created_at) AS order_time
        FROM
            website_sessions ws
        LEFT JOIN orders o USING (website_session_id)
        WHERE
            utm_source = 'gsearch'
            AND order_id IS NOT NULL
            AND ws.created_at < '2012-11-27'
    ) a
GROUP BY order_time;
-- The general trend of gsearch-related orders is increasing.


-- Separate utm_campaign
SELECT 
    order_time, 
    SUM(IF(utm_campaign = 'brand', 1, 0)) AS branded_order_cnt,
    SUM(IF(utm_campaign = 'nonbrand', 1, 0)) AS non_branded_order_cnt
FROM
    (
        SELECT 
            ws.website_session_id,
            ws.created_at AS web_time,
            order_id,
            utm_campaign,
            MONTH(o.created_at) AS order_time
        FROM
            website_sessions ws
        LEFT JOIN orders o USING (website_session_id)
        WHERE
            utm_source = 'gsearch'
            AND order_id IS NOT NULL
            AND ws.created_at < '2012-11-27'
    ) a
GROUP BY order_time;
-- Brand campaign-related orders increased slowly.


CREATE TEMPORARY TABLE gs_nb
SELECT * 
FROM website_sessions 
WHERE utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
    AND created_at < '2012-11-27';


-- Orders by device type
SELECT 
    MONTH(o.created_at) AS month,
    SUM(IF(device_type = 'desktop', 1, 0)) AS desktop_cnt,
    SUM(IF(device_type = 'mobile', 1, 0)) AS mobile_cnt
FROM gs_nb gn
LEFT JOIN Orders o USING (website_session_id)
WHERE order_id IS NOT NULL
GROUP BY month;
-- Both desktop and mobile sections have been increasing while desktop has higher volume and increase rate.


-- Analyze gsearch and other channels
SELECT 
    order_time, 
    SUM(IF(utm_source = 'gsearch', 1, 0)) AS gsearch_paid_sessions,
    SUM(IF(utm_source = 'bsearch', 1, 0)) AS bsearch_paid_sessions,
    SUM(IF(utm_source IS NULL AND http_referer IS NOT NULL, 1, 0)) AS organic_search_sessions,
    SUM(IF(utm_source IS NULL AND http_referer IS NULL, 1, 0)) AS direct_type_in_sessions
FROM
    (
        SELECT 
            ws.website_session_id,
            ws.created_at AS web_time,
            order_id,
            utm_source,
            http_referer,
            MONTH(o.created_at) AS order_time
        FROM
            website_sessions ws
        LEFT JOIN orders o USING (website_session_id)
        WHERE
            order_id IS NOT NULL
            AND ws.created_at < '2012-11-27'
    ) a
GROUP BY order_time;


-- Calculate conversion rate by month
SELECT 
    MONTH(ws.created_at) AS month,
    COUNT(DISTINCT website_session_id) AS website_session_cnt,
    COUNT(DISTINCT order_id) AS order_cnt,
    ROUND(COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id), 4) * 100 AS Conversion_rate
FROM
    website_sessions ws
LEFT JOIN Orders o USING (website_session_id)
WHERE 
    ws.created_at < '2012-11-27' 
GROUP BY MONTH(ws.created_at);


-- Calculate CVR during the gsearch lander test from '2012-06-19' to '2012-07-28'
SELECT 
    wp.pageview_url,
    COUNT(DISTINCT website_session_id) AS website_session_cnt,
    COUNT(DISTINCT order_id) AS order_cnt,
    ROUND(COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id), 4) * 100 AS Conversion_rate
FROM
    website_sessions ws
LEFT JOIN Orders o USING (website_session_id)
LEFT JOIN website_pageviews wp USING (website_session_id)
WHERE 
    ws.created_at < '2012-07-28' 
    AND ws.created_at > '2012-06-19' 
    AND (wp.pageview_url = '/home' OR wp.pageview_url = '/lander-1')
GROUP BY wp.pageview_url;
-- The conversion rate of the new lander page was slightly better than the old homepage.



