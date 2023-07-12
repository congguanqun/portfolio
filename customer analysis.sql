USE mavenfuzzyfactory;
-- Part 1:
-- Calculate repeated visit times of customers.
-- Drop the temporary table if it already exists
DROP TEMPORARY TABLE IF EXISTS session_repeats;

-- Create a temporary table named session_repeats
CREATE TEMPORARY TABLE session_repeats
SELECT
    first_time.user_id,
    first_time.website_session_id,
    ws.website_session_id AS repeat_session_id
FROM
    (
        SELECT
            user_id,
            website_session_id
        FROM
            website_sessions
        WHERE
            created_at < '2014-11-01'
            AND created_at >= '2014-01-01'
            AND is_repeat_session = 0
    ) AS first_time
    LEFT JOIN website_sessions ws
        ON first_time.user_id = ws.user_id
        AND ws.is_repeat_session = 1
        AND ws.website_session_id > first_time.website_session_id
        AND ws.created_at < '2014-11-01'
        AND ws.created_at >= '2014-01-01';

-- Select the number of repeat sessions and the count of distinct users for each number of repeat sessions
SELECT
    num_repeat_session,
    COUNT(DISTINCT user_id) AS users
FROM
    (
        SELECT
            user_id,
            COUNT(DISTINCT repeat_session_id) AS num_repeat_session
        FROM
            session_repeats
        GROUP BY
            user_id
    ) a
GROUP BY
    num_repeat_session;

-- The number of repeat customers is not promising, which means the company should pay attention to attracting repeat customers.

-- Part 2:
-- Average, Min, Max time period between first and second log_in
-- Create a temporary table "temp" to store the relevant data
WITH temp AS
(
    -- Retrieve necessary data from the website_sessions table and perform filtering
    SELECT
        first_time.user_id,
        first_time.website_session_id,
        first_time.dt,
        ws.website_session_id AS repeat_session_id,
        DATE(ws.created_at) AS repeat_date
    FROM
        (
            -- Select initial sessions and extract the date
            SELECT
                user_id,
                website_session_id,
                DATE(created_at) AS dt
            FROM
                website_sessions
            WHERE
                created_at < '2014-11-03'
                AND created_at >= '2014-01-01'
                AND is_repeat_session = 0
        ) AS first_time
        -- Join with website_sessions to find repeat sessions
        LEFT JOIN website_sessions ws
            ON first_time.user_id = ws.user_id
            AND ws.is_repeat_session = 1
            AND ws.website_session_id > first_time.website_session_id
            AND ws.created_at < '2014-11-03'
            AND ws.created_at >= '2014-01-01'
)

-- Calculate average, minimum, and maximum time differences between first and second sessions
SELECT
    AVG(dt_diff) AS avg_days_first_to_second,
    MIN(dt_diff) AS min_days_first_to_second,
    MAX(dt_diff) AS max_days_first_to_second
FROM
    (
        -- Calculate time difference (in days) between first and second sessions for each user
        SELECT
            user_id,
            DATEDIFF(dt2, dt) AS dt_diff
        FROM
            (
                -- Find the minimum repeat date for each user and their corresponding first session date
                SELECT
                    user_id,
                    website_session_id,
                    dt,
                    MIN(repeat_date) AS dt2
                FROM
                    temp
                WHERE
                    repeat_session_id IS NOT NULL
                GROUP BY
                    user_id
            ) a
    ) b;

-- Part 3
-- The source of repeated customers

-- Select and categorize sessions based on different channel groups
SELECT
    CASE
        WHEN utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN 'Organic_search'
        WHEN utm_source = 'non-brand' THEN 'paid_nonbrand'
        WHEN utm_source = 'brand' THEN 'paid_brand'
        WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
    END AS channel_group,
    COUNT(IF(is_repeat_session = 0, website_session_id, NULL)) AS new_sessions,
    COUNT(IF(is_repeat_session = 1, website_session_id, NULL)) AS repeat_sessions
FROM
    website_sessions
WHERE
    created_at < '2014-11-05'
    AND created_at >= '2014-01-01'
GROUP BY
    channel_group
ORDER BY
    repeat_sessions DESC;

-- Part 4
-- Conversion rate and revenue per session for new and repoeat session.
-- Select and aggregate session data based on repeat session status
SELECT
    is_repeat_session,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS orders,
    SUM(price_usd) / COUNT(DISTINCT website_sessions.website_session_id) AS total_revenue
FROM
    website_sessions
LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at < '2014-11-08' AND website_sessions.created_at >= '2014-01-01'
GROUP BY
    is_repeat_session