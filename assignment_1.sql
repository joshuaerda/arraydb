/*
Assignment 1

Imagine for a moment you're helping to design the initial schema for our white label portal product that we offer to clients.
Customers log into the portal, branded to a particular client and are able to order credit reports. A total of 6 products are offered: 
Partial and Full reports for each of the three credit bureaus (Equifax, Experian, and TransUnion). 
We then bill our clients based on the number of each report their customers order.
Describe the data schema for these entities. Include entity names, properties, data types, relationships and any relevant indexes, keys and constraints.

I do not present this code as error free. I've gone over it several times now, but I'm sure I fudged some syntax or used something wrong. 
Since my first days in IT my motto has been 'it never works the first time.' These days it usually DOES work the first time, but that attitude
kept me climing that hill, so I don't lose sight of working for perfect. I try not to make silly, repeated errors, but this is the third time in my
life I've grown my hair out, so sometimes I make them anyway. I think I'm a good fit for the job, but I do not think I will be the smartest or best 
writer of perfect sql on your team. So I don't want to claim that from the outset. Correction is growth, and I enjoy growing more than I enjoy...not growing.

--General Design Considerations
You'll notice I've opted for nvarchar over varchar, and I've limited most of my nvarchar fields to a length of 255.

I've chosen nvarchar because I know I'm going to be dealing with a lot of front end developers whose applications
are likely going to be speaking unicode anyway, and I do not want to have to deal with codepages at this point
in time. APIs are likely to speak unicode as well. The immediate tradeoff is disk space, but for these core tables I believe the use is warranted.

For internal only tables that maybe are used as part of processes or whatnot, I would consider building 
those tables with varchar columns instead, but even then I'm going to have to be told to really
lean out the database for disk space considerations. If I'm not looking out for it, that's a step I'm not likely to take.

Why 255? A couple of reasons. Number 1 this is a pretty recognizable limit, it harkens back to the old SQL days,
but it's also likely a field limit on some of the front end pieces. I would verify this with the devs, but I never want to allow
something more than what the app allows into a given column, to be mindful of sql injection and such. Unlikely someone would get that far
in the first place, but I like to design like I'm Kevin McAllister and hackers are the Wet Bandits. (320 on email because 64 (local limit) + 255 (domain limit) + @ is 320)

You could also argue that I should either escape or just plain not use reserved keywords for column names, even in CTEs and such. That would be a fair argument to make
and I'd default to SOP on that. In my day-to-day I'm not writing a huge amount of code that's going to run over and over again, and if I am I'm going to take that into consideration specifically.

--Indexes/Keys
I've kept them simple and clustered on the primary keys. For the most part I'm going to ask for devs to be sending queries with keys, and places they have to send other things
I will code indexes for at the time. I think a lot of people jump to indexes as a fix all, and they certainly can be. But I have also seen databases so bogged down with indexes
that things are just ugly and slow all the time. clustered primary key gives you a covering index tied to that ID.

--Constraints
Again I've kept these pretty simple, to the basic that I'd have. There may be some merit to additional constraints around duplicate name and email address values together with a bureau_id
or something like that, but for quick and dirty 'build the schema' that's where I landed. Walking that edge between CI and CD. You can always add constraints later when there's a stronger 
call for them programatically or from the business, imo, anyway.

--Limitations of sample data
I don't think there are any duplicate cust_ids for orders in the order data. I used mockaroo, and I didn't mess with the formulas enough to ensure I got data
that would match what specifically assignment 4 asked, but the code assumes that there could be more than one order per customer per datetime with a different bureau_id

--Orders table
I went back and forth on this, but ultimately settled on using a foreign key relationship to the bureau table.
I think there's a strong argument to be made for three bit columns, one for each bureau. I think it's at least
somewhat unlikely that another credit bureau will jump on the scene that we'll need to code for
and worst case we have to tack a column on. it's ugly, but let's talk about the advantages.

with three bit columns, searching for 3 bureau reports or even just having that granularity accessible quickly is valuable. 
the orders table is going to be pretty big and unwieldly before too long, so I'm looking for any edge I can get
to shorten the distance between questions and answers. ultimately I didn't do it this way because looking back at it
I just couldn't stomach it. I can see both sides, but the stickler for normalization and reliable schema in me (I guess that's the DBA)
couldn't let it pass.

Moving on from there, I added a queued and processed column to that table as well. 
My reasoning for that stems mainly from the fact that the concept of an 'order' and a 'report'
are sort of decoupled in this model. That is to say, you'll have one order for each report
but you might not get a report from every bureau every order. That's an assumption I'm making,
that the end-user can choose to run one at a time. This design also allows for timing differences
in the various methods we're pulling these reports. It's much easier to write a watchdog that checks a queue
than it is to check the payload of a json response once a second or something. At least, that's how it would seem
to me, but this is another hill I would not die on, this is merely an idea, the best of which will win. 

The advantage to this is that we have an easy metric to pull some KPIs on if we so desire. 
If we write some logging on that table, to say fire a trigger on insert/update that inserts
a row in the logging table with the action performed and a timestamp. We then have some time intelligence
on how long things are sitting in the queue, and we have a way to sanity check the numbers we're getting out of 
K8's/AWS/Azure/GCP/localhost? - whatever it might be. 

Again the main implications or arguments against this would be disk space related (and probably a consideration on the int/bigint situation
dicussed in a previous episode), but if we're bootstrapping I don't have a lot of time to read the 450 pages of stackoverflow on the considerations of int/bigint
in [current year] on modern hardware, so I'm going with what works for now and isn't completely braindead or ignorant of other processes.

*/

/*
drop database array
create database array
*/
use array

create table client (
client_id int primary key clustered identity not null,
client_name nvarchar(255),
logo binary,
active bit,
dateactive datetime,
dateinactive datetime


)

create table customer (
cust_id int primary key clustered identity not null,
client_id int foreign key references client(client_id),
cust_first_name nvarchar(255),
cust_last_name nvarchar(255),
cust_email nvarchar(320),
acct_create_datetime datetime,
last_login datetime,
passwordexpired bit,


	

)

create table ext_customer_data (
ecd_id int primary key clustered identity not null,


)

create table bureaus (
bureau_id int primary key identity not null,
bureau_name nvarchar(255) not null,

)

create table reports (
report_id int primary key clustered identity not null,
client_id int foreign key references client(client_id),
cust_id int foreign key references customer(cust_id),
bureau_id int foreign key references bureaus(bureau_id),
report_code nvarchar(4),
partial_report bit,
reportdate datetime,
report xml, 

)
--drop table orders
create table orders (
order_id int primary key clustered identity not null,
cust_id int foreign key references customer(cust_id),
bureau_id int foreign key references bureaus(bureau_id),
orderdatetime datetime,
queued bit,
processed bit,
processeddatetime datetime


)

create table logins (
cust_id int foreign key references customer(cust_id),
attempttime datetime,
success bit,
ip_address nvarchar(15)

)

