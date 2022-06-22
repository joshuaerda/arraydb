/*
Assignment 5

You discover the SQL database performance is being impacted by many concurrent long running queries.
Describe your approach in how you'd diagnose, test and resolve the issue. Detail the tools and SQL statements you'd execute.
*/

/*
So I have the unique experience of being on all the sides of this issue. 

That is, the business unit experiencing the impact, the dba responsible for the database, the application developer, the
app admin who has to somehow duct tape a fix around inefficient or straight up bad code, and the poor support person who really
has no power to fix anything, but still has to empathize.

My first question is did I write the code. If so, how long ago? That gives me an idea of some of the simple mistakes I might
have inadvertently pushed to prod in my youth, or maybe things I've just learned how to do better since then. Maybe I just 
got back from a conference on SQL and learned something new about in-memory columnstores or something and I'm trying to
isolate all the places I can put this new knowledge into legacy code - is this a candidate for that?

While I'm figuring that out, my first stop is activity monitor.
I know, I know. but listen, as a production dba it is STILL the quickest
way for me to drill into what's happening on my sql server at any given time. 
It's a bird's eye view, but it at least gives me an area of the map to zoom in on. What are my recent expensive queries?

From that I'm probably dabbling a little in some top DMVs, specifically dm_os_wait_stats, query exec stats, db stats, thinks that Brent will do better later,
but we all have a couple of snippets we run because it worked that one time, this is where I do those, and they're usually my self-written dmv CTEs and views.
I don't rely on them much, but I'd be remiss not to mention them.

We should probably jump out a level and talk about what sort of logging we have turned on here. Do we have querystore enabled? What's the status on that?
If this query is running often enough that it's concurrent AND long, something ain't right. In my experience, 4.5 times out of 10, activity monitor will point
me in the right direction. If it does, I'm going to start by looking at the execution plan for my long running queries. 

What's the optimizer think? Is it missing an index it would like? Speaking of, what's the status of my indexes? When was the last time they were rebuilt? At least weekly,
if not nightly, right? I don't expect to be smarter than the query engine, but I at least like to not leave it wanting for indexes, so these are all low hanging fruit that 
might result in a quick fix. Let's say none of these pan out.

My next step is going to be some Brent Ozar scripts from his First Responder Kit. I don't name drop much when it comes to SQL, but Brent Ozar and Ola Hallengren
are the bronze calves I choose to honor. They have eached saved my butt more times than I can count. So I'm using the sp_whoisactive in there, I'm especially interested 
in the ones related to indexes and cache, what does Brent think about those? He's not right all the time, but if Brent thinks you're wrong, generally you gotta have a
really good reason to be the exception. If his scripts don't nail it down, I'm looking further into the code that's running. Can I isolate the before and after? Am I waiting
for a return from something and holding the database hostage while some foreign API takes its sweet time? Can I run a trace on it and identify other key factors - are all these
requests coming from one app pool, one machine, one load balancer, some geographic similarity, something to tie them together in a way I haven't considered yet. 

A couple of ways this has played out in my career:
The one with the deadlocks - 
Running billing for ~3500 water billing customers at a time results in a deadlock that takes the application down. I'm the application admin and the de facto dba, and I am new to this app.
It's old. Like .net 2 and crystal reports old. Like commented out Vbasic and winforms code old. So I have no control over the garabge dynamic sql coming out of the app.

I can see the query, it's ugly, it has 100 different moving parts, 30 thousand joins, none of it is commented, it looks like someone wrote it on the side of a cave. Huge letters, massive indents.
It's practically unfathomable. The query engine HATES this thing. Every time the optimizer fails to optimize, and ships the 'good enough' plan. The problem with the 'good enough' plan, is it makes a
lot of assumptions about the code it's running. In this case, while the execution plan was 'good enough' in that if everyone else got out of the app, looked directly into the sun and chanted at exactly
440hz, the query would complete 4 hours and 47 minutes later. But what would more often happen is the database would cascade fail because of a bunch of deadlocks, and the entire app would come down
for 15 minutes while it's infrastructure rebooted itself. 

After looking at the execution plan for the 100th time, it occurs to me that paralellism is nowhere considered in this plan. But surely if it made that big of a difference the optimizer would have
figured that out, right? Well, no. Turns out if the optimizer can't parse the whole query it stops about halfway through. I finally understood why when I right clicked from activity monitor,
the query was massively truncated. I finally isolate it with a trace, replace all the variables with data values, and run it with and without the trace flag for paralellism enabled. 

The one that was forced parallell finished instantly. Like 200ms. Vs the 5 hours the other one was taking. I nearly cried. Now how do I convince the optimizer to do this every time.
Query plan guides. Ever heard of them? I hadn't until that moment. Basically I had to feed it every variation of the query the app would produce - properly paramaterized - and pop it into a query plan
guide that basically says to the optimizer 'HEY ON JUST THIS ONE I AM SMARTER THAN YOU DO THIS TRUST ME'. It worked, billing was thrilled, I had a great story to write into my first review.

The one with the shameful fix - 
Budgeting application that integrates with an ERP. Compiles actuals vs budgets for reporting. Query takes forever to put together actuals and budgets, huge joins, terrible matching between the apps,
lots of bad code for reports half written by me, half written by the offshore integration team at the app's HQ. I basically need the data static for about a month, at which point it's written to
stone more or less and I can report off it from a fixed location. In the meantime, I need something of a functional SSAS cube that I can setup instantly and let run overnight when my users won't notice.

Ugly and shameful solution - instead of running the view that does the joins each time the report runs, I dump that data to a fixed table with good indexes on it daily. Report times dropped
from 1-2 minutes to less than a second consistently.

From that how do I test. I'm assuming I have a dev environment I can nuke for fun, a test enviornment that's refreshed daily that we all use and try our best not to break,
a UAT environment for dogfooding new features and potentially a/b testing, though that's outside my wheelhouse, and a production environment. I'm going to refresh dev and toss my fix in there.
if I can only see the issue at scale, there are ways of emulating scale on sql boxes. I'd have to google the best one, to be honest. but generally a query that runs slow at scale will run slow 
not at scale, at least in the majority of my experience.

Resolving comes down to your dev/ops practices. For me currently, I am the one who knocks, so I push fixes when I have time, and when I can either support the volume of calls from the downtime, or 
when there will be no downtime felt by the users. This results in some after COB changes, which is why working from home is so great. But you already know that.
*/