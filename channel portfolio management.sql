USE mavenfuzzyfactory;

-- Calculate gsearch_sessions and bsearch_sessions for each week
SELECT
    MIN(DATE(created_at)) AS week_start,
    SUM(IF(utm_source = 'gsearch', 1, 0)) AS gsearch_sessions,
    SUM(IF(utm_source = 'bsearch', 1, 0)) AS bsearch_sessions
FROM
    (
        SELECT
            created_at,
            utm_source,
            website_session_id
        FROM
            website_sessions
        WHERE
            DATE_FORMAT(created_at, '%Y-%m-%d') BETWEEN '2012-08-22' AND '2012-11-29'
            AND utm_source IS NOT NULL
            AND utm_campaign = 'nonbrand'
    ) a
GROUP BY
    YEARWEEK(created_at);


-- Calculate sessions and percentages based on device type and utm_source
SELECT
    DATE_FORMAT(MIN(created_at), '%Y-%m-%d') AS week_start_date,
    SUM(IF(utm_source = 'gsearch' AND device_type = 'desktop', 1, 0)) AS b_dtop_sessions,
    SUM(IF(utm_source = 'bsearch' AND device_type = 'desktop', 1, 0)) AS b_dtop_sessions,
    ROUND(SUM(IF(utm_source = 'bsearch' AND device_type = 'desktop', 1, 0)) / SUM(IF(utm_source = 'gsearch' AND device_type = 'desktop', 1, 0)), 4) * 100 AS b_pct_of_g_dtop,
    SUM(IF(utm_source = 'gsearch' AND device_type = 'mobile', 1, 0)) AS g_dtop_sessions,
    SUM(IF(utm_source = 'bsearch' AND device_type = 'mobile', 1, 0)) AS g_dtop_sessions,
    ROUND(SUM(IF(utm_source = 'bsearch' AND device_type = 'mobile', 1, 0)) / SUM(IF(utm_source = 'gsearch' AND device_type = 'mobile', 1, 0)), 4) * 100 AS b_pct_of_g_mob
FROM
    website_sessions
WHERE
    created_at BETWEEN '2012-11-4' AND '2012-12-22'
    AND utm_campaign = 'nonbrand'
GROUP BY
    WEEK(created_at);


-- Analysis of paid traffic volume
SELECT
    yr,
    mo,
    nonbrand,
    brand,
    ROUND(brand / nonbrand, 4) AS brand_pct_of_nonbrand,
    direct,
    ROUND(direct / nonbrand, 4) AS direct_pct_of_nonbrand,
    organic,
    ROUND(organic / nonbrand, 4) AS organic_pct_of_nonbrand
FROM
    (
        SELECT
            YEAR(created_at) AS yr,
            MONTH(created_at) AS mo,
            SUM(IF(utm_campaign = 'nonbrand', 1, 0)) AS nonbrand,
            SUM(IF(utm_campaign = 'brand', 1, 0)) AS brand,
            SUM(IF(utm_source IS NULL AND http_referer IS NULL, 1, 0)) AS direct,
            SUM(IF(utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com'), 1, 0)) AS Organic
        FROM
            website_sessions
        WHERE
            created_at <= '2012-12-23'
        GROUP BY
            DATE_FORMAT(created_at, '%Y-%m')
    ) a;


-- Count sessions by hour and weekday
SELECT
    hr,
    SUM(IF(wk = 0, 1, 0)) AS Monday,
    SUM(IF(wk = 1, 1, 0)) AS Tuesday,
    SUM(IF(wk = 2, 1, 0)) AS Wednesday,
    SUM(IF(wk = 3, 1, 0)) AS Thursday,
    SUM(IF(wk = 4, 1, 0)) AS Friday,
    SUM(IF(wk = 5, 1, 0)) AS Saturday,
    SUM(IF(wk = 6, 1, 0)) AS Sunday
FROM
    (
        SELECT
            HOUR(created_at) AS hr,
            WEEKDAY(created_at) AS wk,
            website_session_id
        FROM
            website_sessions
        WHERE
            created_at BETWEEN '2012-09-15' AND '2012-11-15'
    ) a
GROUP BY
    hr
ORDER BY
    hr;
