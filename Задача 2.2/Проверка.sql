-- Проверка: какие периоды есть в каждой из таблиц-источников
-- Для rd.deal_info
select MIN(effective_from_date) as min_date, 
	MAX(effective_to_date) as max_date,
	COUNT(DISTINCT effective_from_date) as unique_dates
from rd.deal_info;

-- Для rd.loan_holiday  
select MIN(effective_from_date) as min_date,
	MAX(effective_to_date) as max_date, 
	COUNT(DISTINCT effective_from_date) as unique_dates
from rd.loan_holiday;

-- Для rd.product
select MIN(effective_from_date) as min_date,
	MAX(effective_to_date) as max_date,
	COUNT(DISTINCT effective_from_date) as unique_dates  
from rd.product;

-- Какие даты есть в витрине
select MIN(effective_from_date) as min_date,
	MAX(effective_to_date) as max_date,
	COUNT(DISTINCT effective_from_date) as unique_dates
from dm.loan_holiday_info;

select * from rd.deal_info
select * from rd.loan_holiday
select * from rd.product

--Общая проверка
select 
	'rd.deal' as table_name,
	effective_from_date,
	effective_to_date,
	count(*) as cnt
from rd.deal_info
group by effective_from_date, effective_to_date

union all

select 
	'rd.loan_holiday' as table_name,
	effective_from_date,
	effective_to_date,
	count(*) as cnt
from rd.loan_holiday
group by effective_from_date, effective_to_date

union all

select 
	'rd.product' as table_name,
	effective_from_date,
	effective_to_date,
	count(*) as cnt
from rd.product
group by effective_from_date, effective_to_date

union all

select 
	'dm.loan_holiday_info' as table_name,
	effective_from_date,
	effective_to_date,
	count(*) as cnt
from dm.loan_holiday_info
group by effective_from_date, effective_to_date

order by 1, 2, 3;


select count(*) from rd.deal_info;
select count(*) from rd.product;

select *from rd.deal_info;



-- Бэкап витрины
CREATE TABLE dm.loan_holiday_info_backup as 
select * from dm.loan_holiday_info;

-- Бэкап deal_info
CREATE TABLE rd.deal_info_backup as 
select * from rd.deal_info;

-- Бэкап loan_holiday
CREATE TABLE rd.loan_holiday_backup as 
select * from rd.loan_holiday;

-- Бэкап product
CREATE TABLE rd.product_backup as 
select * from rd.product;



 
--ЗАГРУЗКА

select count(*) from rd.deal_info;
select count(*) from rd.deal_info_backup;

select *from rd.deal_info;

select count(*) from rd.product;
select count(*) from rd.product_backup;

select *from rd.product;

select * from "LOGS"."ETL_LOG" order by ctid DESC;

--пересчет витрины

select count(*) from dm.loan_holiday_info;
select count(*) from dm.loan_holiday_info_backup;

select *from dm.loan_holiday_info_backup;


--запуск
CALL dm.refresh_loan_holiday_info();

--Проверка количество записей
select effective_from_date, COUNT(*) 
from dm.loan_holiday_info 
group by effective_from_date 
order by effective_from_date;

--Проверка deal_info по датам
select effective_from_date, COUNT(*) as cnt
from rd.deal_info
group by effective_from_date
order by effective_from_date;

--Проверка loan_holiday по датам  
select effective_from_date, COUNT(*) as cnt
from rd.loan_holiday
group by effective_from_date
order by effective_from_date;

--Проверка product по датам
select effective_from_date, COUNT(*) as cnt
from rd.product
group by effective_from_date
order by effective_from_date;


--Проверка дубликатов в deal_info
select deal_rk, effective_from_date, COUNT(*)
from rd.deal_info 
group by deal_rk, effective_from_date
HAVING COUNT(*) > 1;

--Проверка дубликатов в loan_holiday
select deal_rk, effective_from_date, COUNT(*)
from rd.loan_holiday
group by deal_rk, effective_from_date
HAVING COUNT(*) > 1;

--Проверка дубликатов в product
select product_rk, effective_from_date, COUNT(*)
from rd.product 
group by product_rk, effective_from_date
HAVING COUNT(*) > 1;

select * from rd.product where product_rk=1607713 and  effective_from_date ='2023-01-01'