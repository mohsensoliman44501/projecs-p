

-- ----------------------------------------------------------------------------

-- Task 1: Pull a list of user email addresses, but only for non-deleted users.
SELECT
	email_address 
FROM
	users
WHERE
	deleted_at IS NULL; 
-- ----------------------------------------------------------------------------

-- Task 2: Use the items table to count the number of items for sale in each category.
SELECT 
    category, COUNT(id)
FROM
    items
GROUP BY category;
-- ----------------------------------------------------------------------------

-- TASK 3: Select all of the columns from the result when you JOIN the users table to the orders
-- table
SELECT 
    *
FROM
    users
        JOIN
    orders ON users.id = orders.user_id;
-- ----------------------------------------------------------------------------

-- Task 4: Count the number of viewed_item events.
SELECT 
    COUNT(DISTINCT event_id) AS events
FROM
    events
WHERE
    event_name = 'view_item';
-- ----------------------------------------------------------------------------

-- Task 5: Compute the number of items in the items table which have been ordered.
SELECT 
    COUNT(DISTINCT i.id) AS ordered_items_count
FROM
    items i
        INNER JOIN
    orders o ON i.id = o.item_id;
SELECT 
    COUNT(DISTINCT id) AS items_count
FROM
    items; -- -> Each item has been ordered at least once
-- ----------------------------------------------------------------------------

-- Task 6: For each user figure out if a user has ordered something, and when their first purchase was.
SELECT 
    user_id,
    CASE
        WHEN first_order_date IS NULL THEN 0
        ELSE 1
    END AS has_ordered,
    first_order_date
FROM
    (SELECT 
        u.id AS user_id, MIN(o.created_at) AS first_order_date
    FROM
        users u
    LEFT JOIN orders o ON u.id = o.user_id
    GROUP BY u.id) t
;
-- ----------------------------------------------------------------------------

-- Task 7: Figure out what percent of users have ever viewed the user profile page.
SELECT 
    SUM(CASE
        WHEN e.user_id IS NULL THEN 0
        ELSE 1
    END) / COUNT(u.id) * 100 AS percentage
FROM
    users u
        LEFT JOIN
    (SELECT 
        user_id
    FROM
        events
    WHERE
        event_name = 'view_user_profile') e ON u.id = e.user_id
;
-- ----------------------------------------------------------------------------

-- Task 8: How many new users are added each day?

SELECT 
    DATE(created_at) AS date,
    COUNT(*) AS users
FROM
    users
WHERE
    (parent_user_id IS NULL
        OR id <> parent_user_id)
        AND deleted_at IS NULL
GROUP BY date
ORDER BY date DESC
; 
-- ----------------------------------------------------------------------------

-- Task 9: Count the number of users deleted each day. Then count the number of users
-- removed due to merging in a similar way.
SELECT 
    DATE(deleted_at) AS deleted_at_date, COUNT(*) AS total
FROM
    users
GROUP BY deleted_at_date
HAVING deleted_at_date IS NOT NULL
ORDER BY deleted_at_date;

SELECT
	DATE(merged_at) 	AS merged_at_date,
    COUNT(*)			AS total
FROM
	users
WHERE
	id = parent_user_id	-- TO AVOID DUPLICATES
GROUP BY
	merged_at_date
HAVING
	merged_at_date IS NOT NULL
ORDER BY
	merged_at_date;
-- ----------------------------------------------------------------------------

-- Task 10: Create a subtable of orders per day.
SELECT 
    date(created_at) 	AS day,
	COUNT(distinct invoice_id)	AS orders,
    COUNT(line_item_id)	AS items_orders
FROM
    orders
GROUP BY
	day
order by
	day desc;
-- ----------------------------------------------------------------------------

-- Task 11: Create a subtable of orders per week.
SELECT 
    dates_rollup.date,
    SUM(daily_orders.orders) AS orders,
    SUM(daily_orders.item_orders) AS item_orders
FROM
    (SELECT 
        DATE(created_at) AS day,
		COUNT(DISTINCT invoice_id) AS orders,
		COUNT(line_item_id) AS item_orders
    FROM
        orders
    GROUP BY day) daily_orders
        JOIN
    dates_rollup ON dates_rollup.date >= daily_orders.day
        AND dates_rollup.d7_ago < daily_orders.day
WHERE
    DAYOFWEEK(dates_rollup.date) = 1
GROUP BY dates_rollup.date
ORDER BY dates_rollup.date DESC
;
-- ----------------------------------------------------------------------------

-- Task 12: create a subtable to send users an email about the item they viewed more recently.
-- note: get the last item that was viewed by a user BUT not ordered by that user.
SELECT 
    user_id,
    first_name,
    last_name,
    email_address,
    item_id,
    item_name,
    item_category
FROM
    (SELECT 
        users.id AS user_id,
            users.first_name,
            users.last_name,
            users.email_address,
            items.id AS item_id,
            items.name AS item_name,
            items.category AS item_category,
            CASE
                WHEN orders.created_at IS NULL THEN 0
                ELSE 1
            END AS not_ordered
    FROM
        (SELECT 
        user_id, item_id, MAX(event_time)
    FROM
        view_item_events
    WHERE
        event_time > '2018-1-1'
    GROUP BY user_id) recent_views
    LEFT JOIN users ON recent_views.user_id = users.id
    LEFT JOIN items ON recent_views.item_id = items.id
    LEFT JOIN orders ON recent_views.item_id = orders.item_id
        AND recent_views.user_id = orders.user_id) promo_email
WHERE
    not_ordered = 1
;
-- ----------------------------------------------------------------------------

-- Task 13: Find the average time between orders
drop temporary table if exists orders_mod_1;
drop temporary table if exists orders_mod_2;
-- --------------------------
create temporary table orders_mod_1 -- for users with more than 2 orders
as
select
	user_id,
    invoice_id,
    date(max(created_at)) as order_date,
    rank() over(partition by user_id order by created_at asc) as ranking
from orders
where user_id in ( select user_id from (select user_id, count(distinct invoice_id)
					from orders
                    group by user_id
                    having count(distinct invoice_id) > 2) table_1)
group by user_id, invoice_id
order by user_id;
-- --------------------------
create temporary table orders_mod_2
as
select
	user_id,
    invoice_id,
    date(max(created_at)) as order_date,
    rank() over(partition by user_id order by created_at asc) as ranking
from orders
where user_id in ( select user_id from (select user_id, count(distinct invoice_id)
					from orders
                    group by user_id
                    having count(distinct invoice_id) > 2) table_1)
group by user_id, invoice_id
order by user_id;
-- --------------------------
-- --------------------------
SELECT 
    user_id,
    SUM(diff_date) / COUNT(diff_date) AS avg_time_between_orders
FROM
    (SELECT 
        user_id, DATEDIFF(second_date, first_date) AS diff_date
    FROM
        (SELECT 
        orders_mod_1.user_id,
            orders_mod_1.order_date AS first_date,
            orders_mod_2.order_date AS second_date
    FROM
        orders_mod_1
    JOIN orders_mod_2 ON orders_mod_1.user_id = orders_mod_2.user_id
        AND orders_mod_2.ranking = orders_mod_1.ranking + 1
    ORDER BY orders_mod_1.user_id) table_1) table_2
GROUP BY user_id
;

