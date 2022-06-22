/*
Assignment 4

You've been asked to demonstrate to a junior engineer the use of CTEs. 
Write a query that would identify clients that have done over 100 reports in the last 30 days. 
The query should return the client's name and the number of reports within the last 30 days.
*/


/*
I like to describe CTEs as - what you would say after 'hey google' if you were feeding this query to a google home, or your android phone.

So for instance, if I had everything in my house tracked and atomized and catalogued (I know someone reading this has read that blog of the guy that did that
and ended up getting tons of insurance money because of it. Reddit post maybe?), and google had access to this database, I could say something like:
hey google, show me the top 10 most often worn socks in my collection over the last 5 months, and in the future when I ask for my sock rank, show me that chart.

That analogy doesn't jive for everyone, so here's another one. 

Imagine your walls had no windows, but instead you had a window you could carry around and hold up to the wall wherever you wanted, and it would show you the view
from right there. So then you could say, start a window at the beginning of the south side of the house, and carry it all the way north so you see the whole street out front.
Or you can move it so it's on the other side so you have a clear view of the cedar trees in your backyard. 
Or maybe you want to split it up, and have two smaller windows, one at the front and one at the back, so you can keep an eye on both.

Each of those windows is a CTE, the house is the data you're looking at. In the case of our data, instead of a window to the outside, we're interested
in a window in time. But that window is relative. Meaning we want to see the last 30 days. Not the last month, the last 30 days. Which means 30 minus today's
date (dateadd(dd, -30, getdate()) because I know you wanted to see me write it) so if we want to write something that always gives us that relative window, we use a CTE!

I also call them 'informal views' sometimes. Because it's like a view, but it's ephemeral rather than written to disk. 

Anyway here's how we'd get that given our schema. I'm going to present two options, because I'm extra and I want the job. A view, and a sproc.
*/

--<view>
create view report_whales_last30 
as

--isolate cust_ids with more than 100 orders per window
with whales as (
select
	cust_id,
	count(order_id) as reports
from orders
where orderdatetime >= (dateadd(dd, -30, getdate()))
group by cust_id having (count(order_id) > 100)
),

--grab only that data from the customer table
whale_names as (
select
	cust_id,
	cust_first_name,
	cust_last_name
from customer
where cust_id in(select cust_id from whales))

--don't select * in production code, this is a view, which I assume is for reporting, and I will therefore allow a select * in
--mostly because I write a lot of reports right now and I'm the dba so there's no one to stop me, and it's my own problem.
--as an end user I always assume the app will break my custom views anyway, so I keep them on a dbadmin database
select * from whalenames
;
--</view>

--<sproc>
create procedure usp_whales30 

as

--lets do the same thing as last time, but add a ranking in
--isolate cust_ids with more than 100 orders per window
with whales as (
select
	cust_id,
	count(order_id) as reports,
	row_number() over (order by count(order_id)) orderrank
from orders
where orderdatetime >= (dateadd(dd, -30, getdate()))
group by cust_id having (count(order_id) > 100)
),

--grab only that data from the customer table
whale_names as (
select
	orderrank,
	c.cust_id,
	cust_first_name,
	cust_last_name
from customer c
inner join whales w on c.cust_id = w.cust_id
where c.cust_id in(select cust_id from whales))

--don't select * in production code, this is a view, which I assume is for reporting, and I will therefore allow a select * in
--mostly because I write a lot of reports right now and I'm the dba so there's no one to stop me, and it's my own problem.
--as an end user I always assume the app will break my custom views anyway, so I keep them on a dbadmin database
select * from whale_names
order by orderrank desc
--</sproc>
