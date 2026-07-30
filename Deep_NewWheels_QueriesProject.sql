SELECT 
	COUNT(DISTINCT customer_id) AS customers_who_ordered
FROM order_t;

SELECT 
    c.state,
    COUNT(DISTINCT c.customer_id) AS no_of_customers 
FROM customer_t c  
JOIN order_t o 
ON c.customer_id = o.customer_id 
GROUP BY c.state
ORDER BY no_of_customers DESC;

/* Q2 */

SELECT 
	p.vehicle_maker,
    COUNT(DISTINCT o.customer_id) AS customer_count
FROM order_t o 
JOIN product_t p USING(product_id) 
GROUP BY p.vehicle_maker 
ORDER BY customer_count DESC
LIMIT 5;

/* Q3 */
WITH StateMakerCounts AS (
    --  Count orders per state and vehicle maker
    SELECT 
        c.STATE, 
        p.VEHICLE_MAKER, 
        COUNT(o.ORDER_ID) AS order_count
    FROM customer_t c
    JOIN order_t o ON c.CUSTOMER_ID = o.CUSTOMER_ID
    JOIN product_t p ON o.PRODUCT_ID = p.PRODUCT_ID
    GROUP BY c.STATE, p.VEHICLE_MAKER
),
RankedMakers AS (
    -- Rank the makers within each state by order count
    SELECT 
        STATE, 
        VEHICLE_MAKER, 
        order_count,
        RANK() OVER (PARTITION BY STATE ORDER BY order_count DESC) as rnk
    FROM StateMakerCounts
)
--  Select only the top-ranked maker for each state
SELECT 
    STATE, 
    VEHICLE_MAKER, 
    order_count
FROM RankedMakers
WHERE rnk = 1
ORDER BY STATE ASC;

/* Q3 --playground --*/
 SELECT 
    state, 
    vehicle_maker, 
    order_count
FROM (
    SELECT 
        c.state, 
        p.vehicle_maker, 
        COUNT(o.order_id) AS order_count,
        RANK() OVER (
            PARTITION BY c.state 
            ORDER BY COUNT(o.order_id) DESC
        ) AS rnk
    FROM customer_t c
    JOIN order_t o ON c.customer_id = o.customer_id
    JOIN product_t p ON o.product_id = p.product_id
    GROUP BY 
        c.state, 
        p.vehicle_maker
) AS ranked_data
WHERE rnk = 1;
 
 /* Q4  */

SELECT 
	ROUND(AVG(feedback_cat) ,2) As overall_avg_rating
    FROM (
		SELECT 
			customer_id,
            quarter_number,
			CASE 
				WHEN customer_feedback = 'Very Bad' THEN 1
				WHEN customer_feedback = 'Bad' THEN 2
				WHEN customer_feedback = 'Okay' THEN 3
				WHEN customer_feedback = 'Good' THEN 4
				WHEN customer_feedback = 'Very Good' THEN 5
				ELSE NULL
			END AS feedback_cat
		FROM order_t
	) AS overall_rating_tbl;

SELECT 
	quarter_number,
    ROUND(AVG(feedback_cat), 2) AS avg_rating 
FROM (
    SELECT 
    customer_id,
    quarter_number,
    CASE 
        WHEN customer_feedback = 'Very Bad' THEN 1
        WHEN customer_feedback = 'Bad' THEN 2
        WHEN customer_feedback = 'Okay' THEN 3
        WHEN customer_feedback = 'Good' THEN 4
        WHEN customer_feedback = 'Very Good' THEN 5
        ELSE NULL
    END AS feedback_cat
    FROM order_t
) AS rating_tbl 
GROUP BY quarter_number
ORDER BY quarter_number;
---------
SELECT 
	ROUND(AVG(CASE 
				WHEN customer_feedback = 'Very Bad' THEN 1
				WHEN customer_feedback = 'Bad' THEN 2
				WHEN customer_feedback = 'Okay' THEN 3
				WHEN customer_feedback = 'Good' THEN 4
				WHEN customer_feedback = 'Very Good' THEN 5
				ELSE NULL
			END) ,2) As overall_avg_rating
    FROM order_t;


SELECT 
	quarter_number,
    ROUND(AVG(CASE 
        WHEN customer_feedback = 'Very Bad' THEN 1
        WHEN customer_feedback = 'Bad' THEN 2
        WHEN customer_feedback = 'Okay' THEN 3
        WHEN customer_feedback = 'Good' THEN 4
        WHEN customer_feedback = 'Very Good' THEN 5
        ELSE NULL
    END), 2) AS avg_rating 
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

---------


/*Q5 */
SELECT 
    quarter_number,
    COUNT(customer_feedback) AS count_feedback,
    ROUND(SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS verybad_percentage,
    ROUND(SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS bad_percentage,
    ROUND(SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS okay_percentage,
    ROUND(SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS good_percentage,
    ROUND(SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS verygood_percentage
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

/* Q6 */
SELECT 
    quarter_number, 
    COUNT(order_id) AS count_orders
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;

/* Q7*/
SELECT 
    quarter_number,
    current_quarter_revenue,
    CASE 
        WHEN prev_quarter_revenue > 0 THEN
            ROUND(((current_quarter_revenue - prev_quarter_revenue) / prev_quarter_revenue) * 100, 2)
        ELSE NULL -- Changed from 100 to NULL, as there is no data to compare against for Q1
    END AS change_percent
FROM (
    SELECT 
        quarter_number,
        ROUND(SUM((quantity * vehicle_price) - discount), 2) AS current_quarter_revenue,
        LAG(ROUND(SUM((quantity * vehicle_price) - discount), 2)) 
            OVER (ORDER BY quarter_number) AS prev_quarter_revenue
    FROM order_t
    GROUP BY quarter_number
) AS revenue_tbl
ORDER BY quarter_number;

/* Q8 */
SELECT 
	quarter_number,
    current_quarter_total_orders,
    prev_quarter_total_orders,
    CASE 
        WHEN prev_quarter_total_orders > 0 THEN
            ROUND(((current_quarter_total_orders - prev_quarter_total_orders) / prev_quarter_total_orders) * 100, 2)
        ELSE NULL
    END AS order_change,
    net_revenue,
    prev_quarter_revenue,
     CASE 
        WHEN prev_quarter_revenue > 0 THEN
            ROUND(((net_revenue - prev_quarter_revenue) / prev_quarter_revenue) * 100, 2)
        ELSE NULL
    END AS revenue_change
    FROM (
		SELECT 
			quarter_number, 
			ROUND(SUM((quantity * vehicle_price) - discount), 2) AS net_revenue, 
			LAG( ROUND(SUM(((quantity * vehicle_price) - discount)),2) ) OVER (ORDER BY quarter_number ) AS prev_quarter_revenue, 
			COUNT(order_id) AS current_quarter_total_orders,
			LAG ( COUNT(order_id) ) OVER (ORDER BY quarter_number ) AS prev_quarter_total_orders
		FROM order_t
		GROUP BY quarter_number
		ORDER BY quarter_number
	) AS tmp_table
    ORDER BY quarter_number;

/*Q9 */
SELECT 
    credit_card_type, 
    ROUND(AVG(discount), 2) AS avg_discount
FROM customer_t
JOIN order_t ON customer_t.customer_id = order_t.customer_id
GROUP BY credit_card_type
ORDER BY avg_discount DESC;
              
/*Q10*/      
SELECT quarter_number,
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS avg_ship_time
FROM order_t
GROUP BY quarter_number
ORDER BY quarter_number;
    
        
    /* Business Metrics */
SELECT 
		ROUND(SUM((quantity * vehicle_price) - discount), 2) AS net_revenue, 
        COUNT(order_id) AS total_orders
FROM order_t;

SELECT 
    COUNT(DISTINCT customer_id) AS total_customers 
FROM customer_t;

SELECT 
    ROUND(AVG(DATEDIFF(ship_date, order_date)), 2) AS average_shipping_time
FROM order_t;

SELECT 
    SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) AS very_bad_count,
    SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) AS bad_count,
    SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) AS okay_count,
    SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) AS good_count,
    SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) AS very_good_count
FROM order_t;

SELECT 
    COUNT(customer_feedback) AS total_feedback_count,
    ROUND(SUM(CASE WHEN customer_feedback = 'Very Bad' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS very_bad_percent,
    ROUND(SUM(CASE WHEN customer_feedback = 'Bad' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS bad_percent,
    ROUND(SUM(CASE WHEN customer_feedback = 'Okay' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS okay_percent,
    ROUND(SUM(CASE WHEN customer_feedback = 'Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS good_percent,
    ROUND(SUM(CASE WHEN customer_feedback = 'Very Good' THEN 1 ELSE 0 END) * 100.0 / COUNT(customer_feedback), 2) AS very_good_percent
FROM order_t;


