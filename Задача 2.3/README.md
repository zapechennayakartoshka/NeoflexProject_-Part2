## Восстановление целостности данных баланса счетов

---

## О проекте

Имеется витрина dm.account_balance_turnover, которая отражает изменение баланса счетов по дням. Заказчик очень требователен в части заполнения всех полей этой витрины, например суммы на начало и конец дня, наименование валюты. Во время проверки качества данных обнаружили, что у счетов иногда отличается account_out_sum - сумма на конец одного дня и account_in_sum - сумма на начало следующего.

Витрина dm.account_balance_turnover строится на основе 3 источников:

- rd.account – информация по счетам клиентов

- rd.account_balance – информация с номер счета клиента и суммами на начало и конец дня

- dm.dict_currency – справочник валют

Для витрина имеется прототип account_balance_turnover_prototype.sql.

Необходимо:

1)    Подготовить запрос, который определит корректное значение поля account_in_sum. Если значения полей account_in_sum одного дня и account_out_sum предыдущего дня отличаются, то корректным выбирается значение account_out_sum предыдущего дня.

2)    Подготовить такой же запрос, только проблема теперь в том, что account_in_sum одного дня правильная, а account_out_sum предыдущего дня некорректна. Это означает, что если эти значения отличаются, то корректным значением для account_out_sum предыдущего дня выбирается значение account_in_sum текущего дня.

3)    Подготовить запрос, который поправит данные в таблице rd.account_balance используя уже имеющийся запрос из п.1

4)    Написать процедуру по аналогии с задание 2.2 для перезагрузки данных в витрину

---

## Для загрузки данных был создан джоб в Talend Open Studio:

dm_dict_currency_Loader_0.1.zip, который:

- Очищает таблицу dm.dict_currency (TRUNCATE)

- Загружает данные из CSV-файла dict_currency.csv

<img width="1064" height="441" alt="image" src="https://github.com/user-attachments/assets/470e291d-a49f-494d-9855-1f273c1b8279" />

---

## Исправление account_in_sum (пункт 1):

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

---

## Исправление account_out_sum (пункт 2):

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

---

## Исправление данных в rd.account_balance (пункт 3)

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

---

## Процедура перезагрузки витрины

Разработана хранимая процедура dm.refresh_account_balance_turnover() с логированием в LOGS.ETL_LOG
