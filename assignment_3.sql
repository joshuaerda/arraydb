/*
Assignment 3

One of our clients provides a data dump of customers they'd like us to add to our system. The format is a .csv file with 1,345 lines.
Describe your approach in validating, formatting and importing the data into your data storage. Detail the tools and SQL statements you'd execute.

*/

/*
So first thing I'm going to do is stage the data.

If I'm getting this from a CSV, I've built an SSIS package that pulls the file from ftp and drops it into a staging table.
I could also use bcp to import the files once they're local, but I'm not going to assume I have the option to reconfigure
the sql server for use of xpcmd, and I'm not going to assume that's our SOP anyway. I could also write a powershell script on 
a scheduled task that does the same things the SSIS package would accomplish, or a batch file, etc etc. For this exercise,
as I would if I were developing a new integration with a client, I'm using the flat file import wizard, because it's pretty slick
these days, and it eats CSVs with ease.
*/

select * from bankybank_customers

/*
In terms of MY customer table, I don't need too much of this.
However, it might be nice to keep on hand, or to maybe run some analytics on.
Because of this, I added a table to the schema called ext_customer_data
where I can deposit data I get in files that I don't have a spot for.
Part of my sanitization process will be to examine the file for columns I don't already have.
Eventually this could be written into the platform, but for now I'm probably doing most of the linking up by hand.
I learned two things in boy scouts, be prepared, and you'd rather have it and not need it than need it and not have it, and finally 
don't leave your can of beans unopened on the fire, you will scar one of your scoutmasters for life, literally on his face with hot beans. That's three things.
So let's keep the data, and vent our cans.

I don't know enough about our ecosystem or structure to say whether this is a good use of disk space.
I think I'm a good enough salesperson that I can sell the value of the data vs disk space,
but I am also totally willing to give it up if the business doesn't want to hang onto it.

From this table, all I need to incorporate are the first name, last name, and email.
These are all bankybank customers, so I know the client_id already.

This code makes a few assumptions, some of which might be too big to glance over,
so I'd like to discuss those now. 

My first instinct is to use a merge, but there's a problem with this. I may have
an account at bankybank, but I pay my mortgage out of the bank formerly known as bank because
I get a .05% discount on my payment if I do it that way. so I might be in your customer table
already, but I have different email addresses for them on purpose. I'd consider it a) a violation of my
privacy and b) gross, if you updated my email address from one to the other. I like to keep them separate.

This makes a merge a bad choice here, so we're going to opt for a set of inserts instead.
This is more of an app wide decision than a database one, but I'm going to make the assumption
that we treat each customer-bank relationship as one discrete 'customer' in terms of the portal.
We could spend some time developing some logic to decide which bank is most recent, and ditch the other one
or some other business rule that the business comes up with, but for this exercise, I'm using the aforementioned 
assumption that one customer-bank = one discrete array 'customer.'

*/


--quick and dirty first pass, no clear matches, gives us a good indication on the quality of the data
--in this case I'm not expecting any matches.
select * from customer
where cust_first_name + ' ' + cust_last_name in (select first_name + ' ' + last_name from bankybank_customers)
--(0 rows affected)

--a little more granular, chances are if we already have them
--we'd probably have their email
select * from customer 
where cust_email in (select email from bankybank_customers)
--(0 rows affected)

--let's see if we are doing to be dealing with any truncation
--I'm writing it once, but I'm doing it for all my hard limited fields
--in this case since I wrote the data file, there are no truncation issues
--'okay but what would you do if there were'
--well it depends. in the name? wow. okay, I guess I'm just taking the first 255 characters, sorry [I couldn't find a name with 256 characters, but pretend that's what's here, because that's the punchline to this setup]
--in the email? theoretically the maximum limit for an email address is 320, if I've got longer than 320 there's an issue with the data, not necessarily with the records themselves.
--in the last name? see firstname. 
--ultimately the limits I picked for this exercise are somewhat arbitrary, and your SOP may work around this without me having to make terrible jokes for 6 lines
select * from bankybank_customers
where (len(first_name) > 255)



--now I'm reasonably certain there are no matches in my database
--if there are, we probably don't want to update them anyway,
--but at least I know I'm not handling any edge cases with this file, it's a straight insert.
--The format of this question leads me to assume this is a one time dump
--but if this is to be a regular file, we'd want to develop a merge process
--that updates records tied to that customer AND that bank
--but again my assumption here is that this is a one time dump

begin tran
insert into customer (
client_id,
cust_first_name,
cust_last_name,
cust_email)
select
	1, --I happen to know bankybank is client_id 1, but I wrote the sample data so that jives. this could also be done with a join to the client table, and if I wasn't rock solid on the data, I'd opt for that.
	first_name,
	last_name,
	email
from bankybank_customers

-- rollback tran - right there easy to highlight. I've been known to have this little snippet tied to an autohotkey shortcut.
-- (1000 rows affected) right on target

commit tran --double tap to be sure

/*

At this point I'd go back to the file and see what other data I could put in my extended data table.
In this particular case it's highly sensitive data that they shouldn't have even sent us, so I'm burning
the file and the servers it touched. 

There is a case for holding onto either a portion of the account number, or a hashed version of the value they sent us.
This could be really valuable for linking up customers down the line, but also comes with some storage implications we
can't really take lightly, so I'm making recommendations here, but leaving the decision to the group (CTO/lead engineer/guru, what have you).

I'm assuming the data is well-formatted. What I need from them is pretty standard, so I don't see any huge hiccups
beyond truncation, which we covered.

/*