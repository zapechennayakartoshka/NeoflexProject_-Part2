select * from dm.account_balance_turnover --витрина

select * from rd.account -- информация по счетам клиентов

select * from rd.account_balance -- информация с номер счета клиента и суммами на начало и конец дня

select * from dm.dict_currency -- справочник валют

 
select count(*) from dm.account_balance_turnover ;
 
CREATE TABLE dm.account_balance_turnover_backup as select * from  dm.account_balance_turnover;
 
CREATE TABLE rd.account_backup as select * from rd.account;
 
CREATE TABLE rd.account_balance_backup as select * from rd.account_balance;
 
CREATE TABLE dm.dict_currency_backup as select * from dm.dict_currency;

--отсутсвующие данные
select* from  dm.account_balance_turnover
where currency_name = 'KZT'; 

select * from rd.account where currency_cd='500'


SELECT a.account_rk,
	   COALESCE(dc.currency_name, '-1'::TEXT) AS currency_name,
	   a.department_rk,
	   ab.effective_date,
	   ab.account_in_sum,
	   ab.account_out_sum
FROM rd.account a
LEFT JOIN rd.account_balance ab ON a.account_rk = ab.account_rk
LEFT JOIN dm.dict_currency dc ON a.currency_cd = dc.currency_cd
where a.currency_cd='500'

--п.1 Подготовить запрос, который определит корректное значение поля account_in_sum. Если значения полей account_in_sum
-- одного дня и account_out_sum предыдущего дня отличаются, то корректным выбирается значение account_out_sum предыдущего дня.
select
	account_rk,
	effective_date,
	account_in_sum,
	account_out_sum,
	LAG(account_out_sum) OVER (PARTITION BY account_rk  ORDER BY effective_date) as prev_account_out_sum,
	case
		when account_in_sum != LAG(account_out_sum) OVER (PARTITION BY account_rk ORDER BY effective_date)
		then LAG(account_out_sum) OVER (PARTITION BY account_rk ORDER BY effective_date )
		else account_in_sum
	end as correct_account_in_sum 
from rd.account_balance;

--пример
select * from rd.account_balance where account_rk=2943625;

select
	account_rk,
	effective_date,
	account_in_sum,
	account_out_sum,
	LAG(account_out_sum) OVER (PARTITION BY account_rk  ORDER BY effective_date) as prev_account_out_sum,
	case
		when account_in_sum != LAG(account_out_sum) OVER (PARTITION BY account_rk ORDER BY effective_date)
		then LAG(account_out_sum) OVER (PARTITION BY account_rk ORDER BY effective_date )
		else account_in_sum
	end as correct_account_in_sum 
from rd.account_balance
where account_rk=2943625;

--п.2 Подготовить такой же запрос, только проблема теперь в том, что account_in_sum одного дня правильная, а account_out_sum предыдущего дня некорректна. Это означает, что если эти значения отличаются, 
--то корректным значением для account_out_sum предыдущего дня выбирается значение account_in_sum текущего дня.


select
	account_rk,
	effective_date,
	account_in_sum,
	account_out_sum,
	LEAD(account_in_sum) OVER (PARTITION BY account_rk ORDER BY effective_date) as next_account_in_sum,
	CASE
		when account_out_sum != LEAD(account_in_sum) OVER (PARTITION BY account_rk ORDER BY effective_date)
		then LEAD(account_in_sum) OVER (PARTITION BY account_rk ORDER BY effective_date)
		else account_out_sum
	end as correct_account_out_sum
from rd.account_balance;

--пример
select * from rd.account_balance where account_rk=2943625;

select
	account_rk,
	effective_date,
	account_in_sum,
	account_out_sum,
	LEAD(account_in_sum) OVER (PARTITION BY account_rk ORDER BY effective_date) as next_account_in_sum,
	CASE
		when account_out_sum != LEAD(account_in_sum) OVER (PARTITION BY account_rk ORDER BY effective_date)
		then LEAD(account_in_sum) OVER (PARTITION BY account_rk ORDER BY effective_date)
		else account_out_sum
	end as correct_account_out_sum
from rd.account_balance
where account_rk=2943625;


--Обновление

UPDATE rd.account_balance ab
SET account_in_sum = a.correct_account_in_sum
from (
	select
		account_rk,
		effective_date, 
		case
			when account_in_sum != LAG(account_out_sum) OVER (PARTITION BY account_rk ORDER BY effective_date)
			then LAG(account_out_sum) OVER (PARTITION BY account_rk ORDER BY effective_date )
			else account_in_sum
		end as correct_account_in_sum 
	from rd.account_balance) a
where 1=1
	and ab.account_rk = a.account_rk
	and ab.effective_date = a.effective_date
	and ab.account_in_sum != a.correct_account_in_sum;
 
select * from rd.account_balance where account_rk=2943625; 

--проверка

select *
from (
	select
	account_rk,
	effective_date,
	account_in_sum,
	LAG(account_out_sum) OVER (PARTITION BY account_rk ORDER BY effective_date) as prev_out_sum
    from rd.account_balance) a
where account_in_sum != prev_out_sum and prev_out_sum is not null;


--загрузка недостающих

select * from dm.dict_currency; 


--процедура

CALL dm.refresh_account_balance_turnover();

select* from dm.account_balance_turnover 
where account_rk = 2943625 
order by effective_date;
 

select* from  dm.account_balance_turnover
where currency_name = 'KZT'; 

 
select count(*) from dm.account_balance_turnover ;