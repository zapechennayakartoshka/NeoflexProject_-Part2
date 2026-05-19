select * from dm.client c 

select count(*) from dm.client c 

--подсчет дубликатов
select c.client_rk, c.effective_from_date , count(*)
from dm.client c 
group by c.client_rk, c.effective_from_date 
having count(*)>1

--примеры
select * from dm.client c 
where client_rk=5686329 and c.effective_from_date ='2023-04-19'

select * from dm.client c 
where client_rk=2000166 and c.effective_from_date ='2023-03-15'

--создаю дубликаты
CREATE TABLE dm.client_backup as SELECT * FROM dm.client;
 
CREATE TABLE dm.client_backup_v2 as SELECT * FROM dm.client;

CREATE TABLE dm.client_backup_v3 as SELECT * FROM dm.client;

--проверка количества
SELECT COUNT(*) as backup_count FROM dm.client_backup;
SELECT COUNT(*) as backup_count_v2 FROM dm.client_backup_v2; --здесь уже удалены записи
SELECT COUNT(*) as backup_count_v2 FROM dm.client_backup_v3; 
SELECT COUNT(*) as original_count FROM dm.client;

--вывожу только дубли
select *
from (
	select
		c.*,
		ROW_NUMBER() OVER (PARTITION BY client_rk, effective_from_date ORDER BY effective_to_date DESC) as rn
	from dm.client c) t
where rn > 1;


-- Общее количество записей до и после очистки
select 
'Всего записей' as str_metric,
count(*) as value
from dm.client

UNION ALL

select 
'Уникальные' as str_metric,
count(DISTINCT client_rk || '|' || effective_from_date) as value
from dm.client

UNION ALL

select 
'Будет удалено дублей' as str_metric,
count(*) - count(DISTINCT client_rk || '|' || effective_from_date) as value
from dm.client;


--Пример 
select 
	client_rk,
    effective_from_date,
	count(DISTINCT effective_to_date) as distinct_to_dates_count,
	MIN(effective_to_date) as min_to_date,
	MAX(effective_to_date) as max_to_date,
	count(*) as total_records
from dm.client
group by client_rk, effective_from_date
having count(DISTINCT effective_to_date) > 1
order by distinct_to_dates_count DESC, total_records DESC;

select * from dm.client c where client_rk=3055149  

--Удаление
with delete_duplicates as (
select
	ctid,   
	ROW_NUMBER() OVER (PARTITION BY client_rk, effective_from_date ORDER BY effective_to_date DESC) as rn
from dm.client)

delete from dm.client
where ctid in (
select ctid 
from delete_duplicates where rn > 1
);

select * from dm.client c where client_rk=3055149  
select count(*) from dm.client --10019

 