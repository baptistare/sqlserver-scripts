set statistics profile on 
--configurar na sessão que for executar o rebuild index

select node_id, physical_operator_name, sum(row_count) row_count, sum(estimate_row_count) estimate_row_count, cast(sum(row_count)*100 as float)/sum(estimate_row_count) percent_completed
from sys.dm_exec_query_profiles
where session_id = 58
group by node_id, physical_operator_name
order by node_id

