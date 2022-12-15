-- events
truncate table events;
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/events.csv' into table events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES ;




-- items
truncate table items;
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/items.csv' into table items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES ;

-- orders
truncate table orders;
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/orders.csv' into table orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES ;

-- users
truncate table users;
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/users.csv' into table users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES ;

# create view_item_events table
drop table if exists view_item_events;
create table view_item_events as
	(select
		event_id,
		event_time,
		user_id,
		platform,
		max(case 
			when parameter_name = 'item_id'
			then parameter_value
			else null
			end) as item_id,
		max(case
			when parameter_name = 'referrer'
			then parameter_value
			else null
			end) as referrer
	from
		events
	where
		event_name = 'view_item'
	group by
		event_id,
		event_time,
		user_id,
		platform);
select count(*) as total_views from view_item_events;
select count(distinct event_id) as total_views from events where event_name = 'view_item'; -- -> OK
