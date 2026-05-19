## Удаление дубликатов в витрине dm.client

---

## О проекте
Имеется витрина dm.client, в которой содержится различная информация по клиентам банка. Заказчик сообщил, что в таблице имеются дубли, которые нужно устранить.

Необходимо подготовить запрос, по которому можно обнаружить все дубли в витрине и удалить их.

Схема витрины:

У данной таблицы имеется составной ключ, который состоит из двух полей, по которым можно выявить уникальную строку:

- client_rk – уникальный код клиента

- effective_from_date – дата начала действия записи

---

## Принцип удаления

- Уникальность строки определяется парой (client_rk, effective_from_date)
- При наличии дублей оставляется запись с максимальным (наиболее актуальным) значением effective_to_date
- Если effective_to_date одинаков, оставляется одна любая запись (используется `ctid` для определенности)

---

## Поиск дубликатов

select c.client_rk, c.effective_from_date , count(*)
from dm.client c 
group by c.client_rk, c.effective_from_date 
having count(*)>1

---

## Удаление дубликатов

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


