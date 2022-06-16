-- MID COURSE PROJECT

-- QUESTIONS:

-- 1. Gsearch seems to be the biggest driver of our business. Could you pull Monthly trends for Gsearch Sessions and Orders so that we can showcase the growth here?
-- 2. It would be great to see a similar monthly trend for Gsearch, but this time splitting out Nonbrand and Brand campaigns separately.
-- 3. While we're on Gsearch, could you dive into Nonbrand, and pull monthly sesssions and orders split by device type? 
-- 4. Can you pull Monthly trends for Gsearch, alongside motnhly trends for each of our other channels?
-- 5. Could you pull session to order conversion rates, by month?
-- 6. For the Gsearch lander test, please estimate the revenue that test earned us (Hint: look at the increase in CVR from the test (Jun19-Jul28) and use the Nonbrand
-- sessions to calculate incremental value)
-- 7. For the previous landing page test, show a full conversion funnel from each of the two pages to order. You can use the same time period as last time.
-- 8. Quantify the impact of our billing test, analyze the lift generated from the test (Sep10-Nov10), in terms of revenue per billing page session and pull the number
-- of billing page sessions for the past motnh to understand monthly impact. 

-- Q1: 

SELECT
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
	COUNT(DISTINCT ws.website_session_id),
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) as conv_rate
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.created_at < '2012-11-27'
GROUP BY 1,2;

-- Q2:
 
 SELECT
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions,
	COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) AS nonbrand_orders,
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions,
	COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS nonbrand_orders
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.created_at < '2012-11-17'
GROUP BY
	1,
	2
ORDER BY 1,2 ;

-- Q3: While we're on Gsearch, could you dive into Nonbrand, and pull monthly sesssions and orders split by device type? 

SELECT
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN ws.device_type = 'mobile' THEN o.order_id ELSE NULL END) AS mobile_orders,
    COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN ws.device_type = 'desktop' THEN o.order_id ELSE NULL END) AS desktop_orders
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand'
    AND ws.created_at < '2012-11-17' 
GROUP BY 
	1,2
ORDER BY
	1,2;
    
-- Q4: Can you pull Monthly trends for Gsearch, alongside monthly trends for each of our other channels?

	-- first, finding the various utm sources and referers to see the traffic we're getting
    
SELECT DISTINCT
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions AS ws
WHERE ws.created_at < '2012-11-27';

	-- now let's CASE WHEN pivot

SELECT
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
    COUNT(DISTINCT CASE WHEN ws.utm_source = 'gsearch' THEN ws.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
	COUNT(DISTINCT CASE WHEN ws.utm_source = 'bsearch' THEN ws.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NOT NULL THEN ws.website_session_id ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND ws.http_referer IS NULL THEN ws.website_session_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-17'
GROUP BY
	1,2;
    
-- Q5: Could you pull session to order conversion rates, by month?

SELECT
	YEAR(ws.created_at) AS yr,
    MONTH(ws.created_at) AS mo,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id) AS conversion_rate
FROM website_sessions AS ws
	LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-17'
GROUP BY
	1,2;

-- Q6: For the Gsearch lander test, please estimate the revenue that test earned us (Hint: look at the increase in CVR from the test (Jun19-Jul28) and use the Nonbrand
-- sessions to calculate incremental value)

	-- We have to find out when the test started
SELECT
	MIN(website_pageview_id) AS first_test_pv
FROM website_pageviews
WHERE pageview_url = '/lander-1';    

	-- Let's find out the sessions and the min_pageviews for the Test period
SELECT
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews as wp
	JOIN website_sessions as ws
		ON ws.website_session_id = wp.website_session_id
        AND ws.created_at < '2012-07-28' -- UNTIL THIS DATE, prescribed by the assignment
        AND wp.website_pageview_id >= 23504 -- starting from a website pageview bigger or equal than this
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY wp.website_session_id;

	-- Creating a temporary table
CREATE TEMPORARY TABLE test_min_pageviews
SELECT
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews as wp
	JOIN website_sessions as ws
		ON ws.website_session_id = wp.website_session_id
        AND ws.created_at < '2012-07-28' -- UNTIL THIS DATE, prescribed by the assignment
        AND wp.website_pageview_id >= 23504 -- starting from a website pageview bigger or equal than this
        AND utm_source = 'gsearch'
        AND utm_campaign = 'nonbrand'
GROUP BY wp.website_session_id;

	-- Bringing the landing page to each session
    -- Creating temp table
    
CREATE TEMPORARY TABLE test_w_landingpages
SELECT
	tmp.website_session_id,
    wp.pageview_url AS landing_page
FROM test_min_pageviews AS tmp
	LEFT JOIN website_pageviews as wp
		ON wp.website_pageview_id = tmp.min_pageview_id -- this way we get only the Landing page
WHERE wp.pageview_url IN ('/home', '/lander-1');

SELECT * FROM test_w_landingpages;

	-- Adding the orders to the table
    -- Creating temp table

CREATE TEMPORARY TABLE  test_w_landingpages_orders
SELECT
	tlp.website_session_id,
    tlp.landing_page,
    o.order_id
FROM test_w_landingpages as tlp
	LEFT JOIN orders as o
		ON o.website_session_id = tlp.website_session_id;

	-- Finding differences with conversion rates

SELECT
	landing_page,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id) AS conversion_rate
FROM test_w_landingpages_orders
GROUP BY 1;
	-- .0318 home vs .0406 lander-1
    
	-- Finding the most recent session for gsearch where the traffic was sent to /home
    
SELECT
	MAX(ws.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview
FROM website_sessions as ws
	LEFT JOIN website_pageviews wp
		ON wp.website_session_id = ws.website_session_id
	WHERE ws.utm_source = 'gsearch'
		AND ws.utm_campaign = 'nonbrand'
        AND wp.pageview_url = '/home'
        AND ws.created_at < '2012-11-27';
        
-- most recent website_session_id = 17145
    
	-- Checking amount of sessions we have got since that test
    
SELECT
	COUNT(website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145 -- last '/home' session
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand';
    
-- 22,972 website sessions since the test
    
-- X. 0087 incremental conversion = 202 incremental orders since 7/29
	-- roughly 4 months, so roughy 50 extra orders per month.


-- Q7: For the previous landing page test, show a full conversion funnel from each of the two pages to order. You can use the same time period as last time.
	-- Extracting the relevant pages for the conversion funnel
    
SELECT
    DISTINCT(wp.pageview_url)
FROM website_pageviews AS wp
	JOIN website_sessions AS ws
		ON wp.website_session_id = ws.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand'
    AND ws.created_at BETWEEN '2012-06-19' AND '2012-07-28';
    
-- funnel: '/home', '/lander', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing' '/thank-you-for-your-order'      

	-- Getting the min pageview per session

SELECT
	MIN(DATE (ws.created_at)) AS starting_date,
	ws.website_session_id,
    MIN(wp.website_pageview_id) AS min_page_id
FROM website_sessions AS ws
	LEFT JOIN website_pageviews AS wp
		ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand'
    AND ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
GROUP BY
	MONTH(ws.created_at),
    ws.website_session_id;
    
    -- Create temp table
    
CREATE TEMPORARY TABLE min_pageview1
SELECT
	MIN(DATE (ws.created_at)) AS starting_date,
	ws.website_session_id,
    MIN(wp.website_pageview_id) min_page_id
FROM website_sessions AS ws
	LEFT JOIN website_pageviews AS wp
		ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand'
    AND ws.created_at BETWEEN '2012-06-19' AND '2012-07-28'
GROUP BY
	MONTH(ws.created_at),
    ws.website_session_id;
    
    -- Getting landing page per min pageview

SELECT
	mp.starting_date,
    mp.website_session_id,
    mp.min_page_id,
    wp.pageview_url AS landing_page
FROM min_pageview1 as mp
	LEFT JOIN website_pageviews as wp
		ON mp.min_page_id = wp.website_pageview_id;

	-- Creating a temp table

CREATE TEMPORARY TABLE landing_pages
SELECT
	mp.starting_date,
    mp.website_session_id,
    mp.min_page_id,
    wp.pageview_url AS landing_page
FROM min_pageview1 as mp
	LEFT JOIN website_pageviews as wp
		ON mp.min_page_id = wp.website_pageview_id;
    
    -- Using CASE WHEN combined with MAX to see how far a Session has made it in the funnel
    
SELECT
    lp.website_session_id,
    MAX(CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END) AS saw_homepage,
    MAX(CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END) AS saw_custom_lander,
    MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END) AS product_page,
    MAX(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mrfuzzy_page,
    MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page,
    MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page,
    MAX(CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END) AS billing_page,
    MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thankyou_page
FROM landing_pages AS lp
	LEFT JOIN website_pageviews AS wp
		ON lp.website_session_id = wp.website_session_id
	LEFT JOIN website_sessions AS ws
		ON wp.website_session_id = ws.website_session_id
GROUP BY
    website_session_id;

    -- Getting temp table

CREATE TEMPORARY TABLE session_funnel_final
SELECT
    lp.website_session_id,
    MAX(CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END) AS saw_homepage,
    MAX(CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END) AS saw_custom_lander,
    MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END) AS product_page,
    MAX(CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END) AS mrfuzzy_page,
    MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END) AS cart_page,
    MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END) AS shipping_page,
    MAX(CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END) AS billing_page,
    MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END) AS thankyou_page
FROM landing_pages AS lp
	LEFT JOIN website_pageviews AS wp
		ON lp.website_session_id = wp.website_session_id
	LEFT JOIN website_sessions AS ws
		ON wp.website_session_id = ws.website_session_id
GROUP BY
    website_session_id;
    
SELECT * FROM session_funnel_final;
    
	-- Counting the results per landing page

CREATE TEMPORARY TABLE session_funnel_totals
SELECT
	CASE
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh... check logic'
	END AS segment,
	COUNT(DISTINCT sf.website_session_id) AS sessions,
    SUM(sf.product_page) AS madeto_products,
	SUM(sf.mrfuzzy_page) AS madeto_mrfuzzy,
    SUM(sf.cart_page) AS madeto_cart,
    SUM(sf.shipping_page) AS madeto_shipping,
    SUM(sf.billing_page) AS madeto_billing,
    SUM(sf.thankyou_page) AS madeto_thankyou
FROM session_funnel_final AS sf
	LEFT JOIN website_sessions AS ws
		ON sf.website_session_id = ws.website_session_id
GROUP BY 1;

SELECT * FROM session_funnel_totals;

	-- Now let's get the conversion rate per page
    
SELECT
	CASE
		WHEN saw_homepage = 1 THEN 'saw_homepage'
        WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
        ELSE 'uh oh... check logic'
	END AS segment,
	COUNT(DISTINCT sf.website_session_id) AS sessions,
    SUM(sf.product_page)/COUNT(DISTINCT sf.website_session_id) AS lander_click_rt,
	SUM(sf.mrfuzzy_page)/SUM(sf.product_page) AS products_click_rt,
    SUM(sf.cart_page)/SUM(sf.mrfuzzy_page) AS mrfuzzy_click_rt,
    SUM(sf.shipping_page)/SUM(sf.cart_page) AS cart_click_rt,
    SUM(sf.billing_page)/SUM(sf.shipping_page) AS shipping_click_rt,
    SUM(sf.thankyou_page)/SUM(sf.billing_page) AS billing_click_rt
FROM session_funnel_final AS sf
	LEFT JOIN website_sessions AS ws
		ON sf.website_session_id = ws.website_session_id
GROUP BY 1;

-- Q8: Quantify the impact of our billing test, analyze the lift generated from the test (Sep10-Nov10), in terms of revenue per billing page session and pull the number
-- of billing page sessions for the past motnh to understand monthly impact. 

	-- Getting sessions, pageviews and filter by pageview_url = '/billing'
    -- Counting sessions

SELECT
	billing_version_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
FROM
(

SELECT
	wp.website_session_id,
	wp.pageview_url AS billing_version_seen,
    o.order_id,
    o.price_usd
FROM website_pageviews AS wp
	LEFT JOIN orders as o
		ON wp.website_session_id = o.website_session_id
WHERE wp.created_at BETWEEN '2012-09-10' AND '2012-11-10'
	AND wp.pageview_url IN ('/billing', '/billing-2')
    
) AS billing_pageviews_order_data
GROUP BY 1;

-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- LIFT: $8.51 per billing page view

SELECT
	COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews
WHERE website_pageviews.pageview_url IN ('/billing', '/billing-2')
	AND created_at BETWEEN '2012-10-27'AND '2012-11-27'-- past month

-- 1,194 billing sessions past month
-- LIFT: $8.51 per billing session
-- VALUE OF BULLING TEST: $10,160 over the past month
    

    

    

    






    

