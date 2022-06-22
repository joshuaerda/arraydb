select * from customer_import

select * from client

insert into client (
client_name,
logo,
active,
dateactive,
dateinactive)
values
('bankybank', null, 1, getdate(), null),
('thebankybunch', null, 1, getdate(), null),
('banktwo', null, 1, getdate(), null),
('the bank formerly known as bank', null, 1, getdate(), null),
('zoomerbank', null, 1, getdate(), null),
('wellsfargo', null, 1, getdate(), null),
('bankiapolis, bankianda', null, 1, getdate(), null),
('unionizewalmartcreditunion', null, 1, getdate(), null),
('Bruce Wayne (NOT BATMAN) Bank', null, 1, getdate(), null),
('bank two point oh', null, 1, getdate(), null)

insert into bureaus (bureau_name) values
('transunion'),('equifax'),('experian')

alter table customer add cust_first_name nvarchar(255), cust_last_name nvarchar(255)

alter table customer add cust_email nvarchar(255)

insert into customer (
client_id,
cust_first_name,
cust_last_name,
cust_email,
acct_create_datetime,
passwordexpired)
select 
	client_id,
	cust_first_name,
	cust_last_name,
	cust_email,
	acct_create_datetime,
	password_expired
	
from customer_import

select * from bankybank_customers

--drop table orders_import
select * from orders_import

--update orders_import
--set queued = 0 where processed = 1

insert into orders (
	cust_id,
	bureau_id,
	orderdatetime,
	queued,
	processed,
	processeddatetime)
select 
	cust_id,
	bureau_id,
	orderdatetime,
	queued,
	processed,
	case when processed = 1 then processeddatetime else null end
from orders_import

select * from orders