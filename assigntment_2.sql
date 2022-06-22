/*
Assignment 2

Not long after the initial launch, the CTO comes to you and asks to build a report showing the number of 3B TransUnion reports ordered per month, for each client.
Using the schema you designed above, what would be the query you'd use to retrieve this information?

I assume '3B' means 3-bureau, but then I'm confused about TransUnion with that - this shows a lack of business understanding on my part, but a cursory google
didn't get me a clear answer, so this is something I'd ask in slack[/teams/aol instant messenger/yahoo chat]. 
I would feel dumb about it, because humans feel dumb when they don't know things sometimes, but I'd rather feel dumb than be dumb. 

*/


--if I'm grabbing the data for further TL
select 
	client_id,
	count(report_id) as reports,  
	month(reportdate) as month,
	year(reportdate) as year
from reports 
where reportdate >= @startdate and reportdate <= @enddate
group by client_id, month(reportdate), year(reportdate)

--if I'm delivering the data to the CTO in excel, csv, etc.

;with monthclient as (
select 
	client_id,
	count(report_id) as reports,  
	month(reportdate) as month,
	year(reportdate) as year
from reports 
where reportdate >= @startdate and reportdate <= @enddate
group by client_id, month(reportdate), year(reportdate)
)

select 
	m.client_id, 
	client_name, 
	m.reports,
	m.month,
	m.year
from monthclient m
inner join client c on m.client_id = c.client_id