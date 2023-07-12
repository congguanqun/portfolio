USE mavenfuzzyfactory;
SELECT 
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(DISTINCT website_session_id) AS sessions
FROM
    website_sessions
WHERE
    created_at < '2012-04-12'
GROUP BY utm_source , utm_campaign , http_referer
ORDER BY sessions DESC;

# Conversion rate
SELECT 
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id),2) * 100 AS session_to_order_conv_rate
FROM
    website_sessions ws
        LEFT JOIN
    orders o USING (website_session_id)
WHERE
    ws.created_at < '2012-04-14'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand';

# Gsearch nonbrand volume trend
SELECT MIN(DATE(created_at)) AS week_start_date,
COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE created_at < '2012-05-12'
AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at);
        
#Conversion rate by platform
SELECT
	device_type,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(COUNT(DISTINCT order_id) / COUNT(DISTINCT website_session_id),4) * 100 AS session_to_order_conv_rate
FROM
    website_sessions ws
        LEFT JOIN
    orders o USING (website_session_id)
WHERE
    ws.created_at < '2012-05-19'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY device_type;


#Weekly trends by device
SELECT
	device_type,
	MIN(DATE(ws.created_at)) AS week_start_date,
	ROUND(COUNT(CASE WHEN device_type='desktop' THEN order_id ELSE NULL END) /
    COUNT(CASE WHEN device_type='desktop' THEN ws.website_session_id ELSE NULL END),4)*100 AS dtop_sessions,
    ROUND(COUNT(CASE WHEN device_type='mobile' THEN order_id ELSE NULL END) /
    COUNT(CASE WHEN device_type='mobile' THEN ws.website_session_id ELSE NULL END),4)*100 AS mob_sessions
FROM
    website_sessions ws
        LEFT JOIN
    orders o USING (website_session_id)
WHERE
    ws.created_at < '2012-06-09'
    AND ws.created_at > '2012-04-15'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY device_type,WEEK(ws.created_at);

SELECT
	device_type,
	MIN(DATE(ws.created_at)) AS week_start_date,
    COUNT(CASE WHEN device_type='desktop' THEN ws.website_session_id ELSE NULL END ) AS dtop_sessions,

    COUNT(CASE WHEN device_type='mobile' THEN ws.website_session_id ELSE NULL END) AS mob_sessions
FROM
    website_sessions ws
        LEFT JOIN
    orders o USING (website_session_id)
WHERE
    ws.created_at < '2012-06-09'
    AND ws.created_at > '2012-04-15'
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY WEEK(ws.created_at);

        

        



