CREATE OR REPLACE PROCEDURE dm.refresh_account_balance_turnover()
LANGUAGE plpgsql
as $$
declare 
	v_start_time TIMESTAMP;
	v_end_time TIMESTAMP;
	v_duration_sec INTEGER;
	v_rows INTEGER;
	v_error_message TEXT;
	v_process_name VARCHAR(255) := 'refresh_account_balance_turnover';
    v_source_table VARCHAR(255) := 'dm.account_balance_turnover';
BEGIN
	-- Запоминаем время начала
	v_start_time := NOW();
    
	-- Логируем начало выполнения
    insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, status, source, user_name)
	values (v_process_name, CURRENT_DATE, v_start_time, 'RUNNING', v_source_table, CURRENT_USER);
    
	-- Очищаем витрину 
	truncate table dm.account_balance_turnover;
    
	-- Заполняем витрину по прототипу
		insert into dm.account_balance_turnover (account_rk, currency_name, department_rk, effective_date, account_in_sum, account_out_sum)
    SELECT a.account_rk,
	   COALESCE(dc.currency_name, '-1'::TEXT) AS currency_name,
	   a.department_rk,
	   ab.effective_date,
	   ab.account_in_sum,
	   ab.account_out_sum
	FROM rd.account a
	LEFT JOIN rd.account_balance ab ON a.account_rk = ab.account_rk
	LEFT JOIN dm.dict_currency dc ON a.currency_cd = dc.currency_cd ;
    
	-- Получаем количество вставленных строк
	GET DIAGNOSTICS v_rows = ROW_COUNT;
    
	-- Завершаем логирование
	v_end_time := NOW();
	v_duration_sec := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
    
  	-- Логируем успешное завершение
	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, end_time, duration_sec, status, rows_written, source, user_name)
	values (v_process_name, CURRENT_DATE, v_start_time, v_end_time, v_duration_sec, 'SUCCESS', v_rows, v_source_table, CURRENT_USER);
    
	raise notice 'Витрина dm.account_balance_turnover перезагружена. Добавлено строк: %', v_rows;
    
	EXCEPTION
	WHEN OTHERS THEN
		GET STACKED DIAGNOSTICS v_error_message = MESSAGE_TEXT;
		v_end_time := CURRENT_TIMESTAMP;
		v_duration_sec := EXTRACT(EPOCH FROM (v_end_time - v_start_time));
        
	insert into "LOGS"."ETL_LOG" (process_name, cur_date, start_time, end_time, duration_sec, status, error_message, rows_error, source, user_name)
	values (v_process_name, CURRENT_DATE, v_start_time, v_end_time, v_duration_sec, 'ERROR', v_error_message, 1, v_source_table, CURRENT_USER);
        
	raise notice 'Ошибка при перезагрузке витрины dm.account_balance_turnover: %', v_error_message;
END;
$$;