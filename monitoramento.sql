
--###############################################################################################################################################################################################################################
--sp_WhoIsActive
--###############################################################################################################################################################################################################################

--exibicao processos ativos
exec master..sp_WhoIsActive;
exec master..sp_WhoIsActive @output_column_list = '[dd hh:mm:ss.mss],[session_id],[blocking_session_id],[percent_complete],[sql_text],[login_name],[host_name],[database_name],[program_name],[wait_info],[CPU],[reads],[writes],[physical_reads],[used_memory],[tempdb_allocations],tempdb_current],[status],[open_tran_count],[percent_complete],[start_time],[login_time],[request_id],[collection_time]'

--exibicao processos ativos e plano de execucao
exec master..sp_WhoIsActive @get_plans = 1, @get_outer_command = 1
exec master..sp_WhoIsActive @get_plans = 1, @get_outer_command = 1, @get_locks = 1, @get_additional_info = 1, @find_block_leaders = 1, @output_column_list = '[collection_time],[dd hh:mm:ss.mss],[session_id],[blocking_session_id],[blocked_session_count],[locks],[additional_info],[sql_text],[sql_command],[query_plan],[login_name],[host_name],[database_name],[program_name],[wait_info],[CPU],[reads],[writes],[physical_reads],[used_memory],[tempdb_allocations],[tempdb_current],[status],[open_tran_count],[percent_complete],[start_time],[login_time],[request_id]'
--@delta_interval = 1
--sp_WhoIsActive @help = 1

--@delta_interval 
-- exibe informacoes de utilizacao de recursos ([cpu_delta], [reads_delta], [writes_delta], [physical_reads_delta], [used_memory_delta], [tempdb_allocations_delta], [tempdb_current_delta])
-- durante o periodo de tempo escolhido
exec master..sp_WhoIsActive @delta_interval = 1
exec master..sp_WhoIsActive @get_plans = 1, @get_outer_command = 1, @get_locks = 1, @get_additional_info = 1, @find_block_leaders = 1, @delta_interval = 1, @output_column_list = '[collection_time],[dd hh:mm:ss.mss],[session_id],[blocking_session_id],[blocked_session_count],[locks],[additional_info],[sql_text],[sql_command],[query_plan],[login_name],[host_name],[database_name],[program_name],[wait_info],[CPU],[CPU_delta],[reads],[reads_delta],[writes],[writes_delta],[physical_reads],[physical_reads_delta],[used_memory],[used_memory_delta],[tempdb_allocations],[tempdb_allocations_delta],[tempdb_current],[tempdb_current_delta],[status],[open_tran_count],[percent_complete],[start_time],[login_time],[request_id]'


select		
			des.session_id, der.blocking_session_id, des.login_name, des.host_name, der.start_time, der.status, der.wait_resource, der.wait_time, der.wait_type, der.last_wait_type, des.program_name, dec.client_net_address,
			dest.text, 
			substring	(
							dest.text, 
							der.statement_start_offset / 2,
							( 
								case 
									when der.statement_end_offset = -1
									then len(convert(nvarchar(max), dest.[text])) * 2
									else der.statement_end_offset
								end - der.statement_start_offset 
							) / 2
						) as statement_executing,
			deqp.query_plan,
			des.session_id, des.login_time, des.host_name, des.program_name, des.login_name, des.status, des.cpu_time, des.memory_usage, des.total_scheduled_time, des.total_elapsed_time, des.last_request_start_time, des.last_request_end_time,
			der.start_time, der.status, der.command, der.sql_handle, der.statement_start_offset, der.statement_end_offset, der.plan_handle, der.database_id, der.blocking_session_id, der.wait_type, der.wait_time, der.last_wait_type, der.wait_resource, der.percent_complete, der.estimated_completion_time, der.cpu_time, der.total_elapsed_time, der.scheduler_id, der.reads, der.writes, der.logical_reads, der.granted_query_memory,
			--dowt.wait_duration_ms, dowt.wait_type, dowt.blocking_session_id, dowt.resource_description,
			dec.connect_time, dec.net_transport, dec.protocol_type, dec.client_net_address, dec.local_tcp_port
from		sys.dm_exec_sessions des with (nolock)
inner join	sys.dm_exec_requests der with (nolock)
	on		des.session_id = der.session_id
inner join	sys.dm_exec_connections dec with (nolock)
	on		des.session_id = dec.session_id
--left join	sys.dm_os_waiting_tasks dowt with (nolock)
--	on		des.session_id = dowt.session_id
cross apply sys.dm_exec_sql_text (der.sql_handle) dest 
cross apply sys.dm_exec_query_plan (der.plan_handle) deqp  
where		1=1
	and		des.is_user_process = 1
	and		des.session_id <> @@SPID 
	--and des.session_id <> 83

select		count(*)
from		sys.dm_exec_sessions des with (nolock)
inner join	sys.dm_exec_requests der with (nolock)
	on		des.session_id = der.session_id
inner join	sys.dm_exec_connections dec with (nolock)
	on		des.session_id = dec.session_id
cross apply sys.dm_exec_sql_text (der.sql_handle) dest 
cross apply sys.dm_exec_query_plan (der.plan_handle) deqp  
where		1=1
	and		des.is_user_process = 1
	and		des.session_id <> @@SPID 

select		
			der.wait_type, count(der.wait_type)
from		sys.dm_exec_sessions des with (nolock)
inner join	sys.dm_exec_requests der with (nolock)
	on		des.session_id = der.session_id
inner join	sys.dm_exec_connections dec with (nolock)
	on		des.session_id = dec.session_id
cross apply sys.dm_exec_sql_text (der.sql_handle) dest 
cross apply sys.dm_exec_query_plan (der.plan_handle) deqp  
where		1=1
	and		des.is_user_process = 1
	and		des.session_id <> @@SPID 
group by	der.wait_type


