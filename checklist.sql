--ok
select	configuration_id,name, value, description, is_dynamic, is_advanced
from	sys.configurations
where	configuration_id in (101,103,117,503,542,1535,1538,1539,1540,1541,1543,1544,1550,1568,1569,1576,1579,1581,16390)

--OK
select	total_physical_memory_kb / 1024 / 1024.  as total_physical_memory_gb, 
		available_physical_memory_kb / 1024 / 1024. as available_physical_memory_gb, 
		(total_page_file_kb - total_physical_memory_kb) / 1024 / 1024. as total_page_file,
		total_page_file_kb / 1024 / 1024. as total_virtual_memory_in_gb, 
		available_page_file_kb / 1024 / 1024. as available_virtual_memory_in_gb , 
		system_memory_state_desc 
from	sys.dm_os_sys_memory with (nolock);


select *
from	sys.dm_os_performance_counters
where	object_name like '%buffer manager%'
and		counter_name = 'page life expectancy'

--ja tem verificar
select		db_name(database_id) as database_name ,
			count(*) * 8 / 1024.0 as cached_size_mb
from		sys.dm_os_buffer_descriptors
where		database_id > 4 -- exclude system databases
	and		database_id <> 32767 -- exclude resourcedb
group by	db_name(database_id)
order by	cached_size_mb desc;

--por base
select		top 10 object_name(p.object_id) as objectname ,
			p.index_id ,
			count(*) / 128 as buffer_size_mb ,
			count(*) as buffer_count
from		sys.allocation_units as a
inner join	sys.dm_os_buffer_descriptors as b 
	on		a.allocation_unit_id = b.allocation_unit_id
inner join	sys.partitions as p 
	on		a.container_id = p.hobt_id
where		b.database_id = db_id()
	and		p.object_id > 100 
group by	p.object_id ,p.index_id
order by	buffer_count desc;

select		objtype, count(*)
from		sys.dm_exec_cached_plans
where		cacheobjtype = 'Compiled Plan'
group by	objtype
order by	count(*) desc

--incrementar
select		db_name(st.dbid) as database_name, mg.requested_memory_kb , mg.ideal_memory_kb , mg.request_time , mg.grant_time , mg.query_cost , mg.dop , st.[text] 
from		sys.dm_exec_query_memory_grants as mg
cross apply sys.dm_exec_sql_text(plan_handle) as st
--where		mg.request_time < coalesce(grant_time, '99991231')
order by	mg.requested_memory_kb desc ;

--exibição processos ativos
exec master..sp_WhoIsActive;
exec master..sp_WhoIsActive @output_column_list = '[dd hh:mm:ss.mss],[session_id],[blocking_session_id],[percent_complete],[sql_text],[login_name],[host_name],[database_name],[program_name],[wait_info],[CPU],[reads],[writes],[physical_reads],[used_memory],[tempdb_allocations],tempdb_current],[status],[open_tran_count],[percent_complete],[start_time],[login_time],[request_id],[collection_time]'

--exibição processos ativos e plano de execução
exec master..sp_WhoIsActive @get_plans = 1, @get_outer_command = 1
exec master..sp_WhoIsActive @get_plans = 1, @get_outer_command = 1, @output_column_list = '[dd hh:mm:ss.mss],[session_id],[blocking_session_id],[sql_text],[sql_command],[query_plan],[login_name],[host_name],[database_name],[program_name],[wait_info],[CPU],[reads],[writes],[physical_reads],[used_memory],[tempdb_allocations],tempdb_current],[status],[open_tran_count],[percent_complete],[start_time],[login_time],[request_id],[collection_time]'

select		@@servername as server_name, login_name, count(session_id) as session_count
from		sys.dm_exec_sessions
group by	login_name
order by	count(session_id) desc ;

--ok
select cpu_ticks, ms_ticks, cpu_count as cpu_logical, hyperthread_ratio, cpu_count / hyperthread_ratio as cpu_physical, os_quantum, max_workers_count, scheduler_count, affinity_type, affinity_type_desc  
from sys.dm_os_sys_info;

select  cast(100.0 * sum(signal_wait_time_ms) / sum(wait_time_ms) as numeric(20,2)) as [%signal (cpu) waits] ,
        cast(100.0 * sum(wait_time_ms - signal_wait_time_ms) / sum(wait_time_ms) as numeric(20, 2)) as [%resource waits]
from    sys.dm_os_wait_stats;

select  is_idle, current_tasks_count, runnable_tasks_count, current_workers_count,active_workers_count, work_queue_count, pending_disk_io_count, load_factor
from    sys.dm_os_schedulers
where   scheduler_id < 255

--verificar
select		des.session_id, des.login_name, des.host_name
			,dow.status, dow.is_preemptive,dow.context_switch_count,dow.pending_io_count,dow.pending_io_byte_count,dow.pending_io_byte_average,dow.wait_started_ms_ticks,dow.wait_resumed_ms_ticks,dow.task_bound_ms_ticks,dow.worker_created_ms_ticks,dow.affinity,dow.state,dow.start_quantum,dow.end_quantum,dow.last_wait_type,dow.quantum_used,dow.max_quantum,dow.boost_count
			,dos.is_idle,dos.preemptive_switches_count,dos.context_switches_count,dos.idle_switches_count,dos.current_tasks_count,dos.runnable_tasks_count,dos.current_workers_count,dos.active_workers_count,dos.work_queue_count,dos.pending_disk_io_count,dos.load_factor,dos.yield_count,dos.quantum_length_us
			,doth.os_thread_id, doth.kernel_time, doth.usermode_time, doth.stack_bytes_committed, doth.stack_bytes_used, doth.affinity, doth.priority
			,dot.task_state, dot.context_switches_count, dot.pending_io_count, dot.pending_io_byte_count, dot.pending_io_byte_average
from		sys.dm_exec_requests der
inner join	sys.dm_exec_sessions des
	on		der.session_id = des.session_id
inner join	sys.dm_os_tasks dot
	on		der.task_address = dot.task_address
inner join	sys.dm_os_workers dow
	on		dot.worker_address = dow.worker_address
inner join	sys.dm_os_schedulers dos
	on		dow.scheduler_address = dos.scheduler_address
inner join	sys.dm_os_threads doth
	on		dow.thread_address = doth.thread_address
where		des.is_user_process = 1


------

select		 s1.spid blocker
			,s2.spid blocked
			,s1.blocked [blocker blocker]
			,dest1.text command_blocker
			,s1.hostname host_blocker
			,s1.program_name program_blocker
			,s1.loginame login_bloker
			,s1.net_address address_bloker
			,dest2.text command_blocked
			,s2.hostname host_blocked
			,s2.program_name program_blocked
			,s2.loginame login_blocked
			,s2.net_address address_blocked
			,s1.waittime
			,s1.login_time
			,s1.last_batch
			,s1.open_tran
			,s1.status status_blocker
			,s2.status status_blocked
			,case 
				when s1.program_name not like 'sqlagent - tsql jobstep (job %' 
				then s1.program_name
				else	 (	select	name 
                            from	msdb..sysjobs 
                            where	job_id in	(
													select	substring(program_name,38,2) 
															+ substring(program_name,36,2) 
															+ substring(program_name,34,2) 
															+ substring(program_name,32,2) 
															+ '-' + substring(program_name,42,2) 
															+ substring(program_name,40,2) 
															+ '-' + substring(program_name,46,2) 
															+ substring(program_name,44,2) 
															+ '-' + substring(program_name,48,4) 
															+ '-' + substring(program_name,52,12) 
                                                    from	sysprocesses 
													where	spid   = s1.spid 
													and		program_name like 'sqlagent - tsql jobstep (job %'
												)
						)
			end as [program_name]
from		master.dbo.sysprocesses s1
inner join	master.dbo.sysprocesses s2
	on		s1.spid = s2.blocked
cross apply sys.dm_exec_sql_text (s1.sql_handle) dest1
cross apply sys.dm_exec_sql_text (s2.sql_handle) dest2
where		1=1
	and		s1.spid in (	select	blocked
							from	master.dbo.sysprocesses 
							where	1=1
							and		blocked > 0
						)
order by	s1.blocked,s1.spid


select		
			dec.session_id as blocking_session
			,der.session_id as blocked_session
			,des.status as blocking_status
			,des2.status as blocked_status
			,der.wait_resource as blocked_resource_description
			,der.wait_time as blocked_wait_duration
			,der.wait_type as blocked_wait_type
			--,dowt1.wait_duration_ms as blocking_wait_duration
			--,dowt2.wait_duration_ms as blocked_wait_duration
			--,dowt1.wait_type as blocking_wait_type
			--,dowt2.wait_type as blocked_wait_type
			--,dowt1.resource_description as blocking_resource_description
			--,dowt2.resource_description as blocked_resource_description
			,des.login_name as blocking_login_name
			,des2.login_name as blocked_login_name
			,des.host_name as blocking_hostname
			,des2.host_name as blocked_hostname
			,des.program_name as blocking_program_name
			,des2.program_name as blocking_program_name
			,blocking.text as blocking_command
			,blocked.text as blocked_command
			,dec.connect_time as blocking_connect_time
			,dec2.connect_time as blocked_connect_time
			,dec.client_net_address as blocking_client_net_address
			,dec2.client_net_address as blocked_client_net_address
			,db_name(der.database_id) as database_name
			,dec.net_transport as blocking_net_transport
			,dec2.net_transport as blocked_net_transport
			,der.open_transaction_count as open_transaction_count
			,j.name blocking_job_name
			,j2.name blocked_job_name
			,der.scheduler_id as blocked_scheduler_id
			,des.transaction_isolation_level as blocking_transaction_isolation_level
			,des2.transaction_isolation_level as blocked_transaction_isolation_level
			,dtat.transaction_begin_time blocking_transaction_begin_time
			,case 
				when dtat.transaction_type = 1 then 'Transação de leitura/gravação'
				when dtat.transaction_type = 2 then 'Transação somente leitura'
				when dtat.transaction_type = 3 then 'Transação do sistema'
				when dtat.transaction_type = 4 then 'Transação distribuída'
			end as blocking_transaction_type_desc
			,case
				when dtat.transaction_state = 0 then 'transação não foi completamente inicializada ainda'
				when dtat.transaction_state = 1 then 'transação foi inicializada mas não foi iniciada'
				when dtat.transaction_state = 2 then 'transação está ativa'
				when dtat.transaction_state = 3 then 'transação foi encerrada,somente leitura'
				when dtat.transaction_state = 4 then 'processo de confirmação foi iniciado na transação distribuída'
				when dtat.transaction_state = 5 then 'transação está em um estado preparado e aguardando resolução'
				when dtat.transaction_state = 6 then 'transação foi confirmada'
				when dtat.transaction_state = 7 then 'transação está sendo revertida'
				when dtat.transaction_state = 8 then 'transação foi revertida'
			end as blocking_transaction_state_desc
			,dec.most_recent_sql_handle
			,dec.net_transport
			,dec.protocol_type 
			,dec.auth_scheme
			,des.client_interface_name
			,dtat.transaction_uow
			,dtst.is_user_transaction
			,dtst.is_local
from		sys.dm_exec_connections dec
inner join	sys.dm_exec_sessions des
	on		dec.session_id = des.session_id
inner join	sys.dm_exec_requests der
	on		dec.session_id = der.blocking_session_id
inner join	sys.dm_exec_sessions des2
	on		der.session_id = des2.session_id
inner join	sys.dm_exec_connections dec2
	on		der.session_id = dec2.session_id
--left join	sys.dm_os_waiting_tasks dowt1
--	on		dec.session_id = dowt1.session_id
--left join	sys.dm_os_waiting_tasks dowt2
--	on		der.session_id = dowt2.session_id
cross apply sys.dm_exec_sql_text(dec.most_recent_sql_handle) blocking
cross apply sys.dm_exec_sql_text(der.sql_handle) blocked
left join	msdb..sysjobs j
	on		substring(des.program_name,30,34) = convert(varchar(34), convert(varbinary(32), j.job_id), 1) 
	and		des.program_name like 'sqlagent%'
left join	msdb..sysjobs j2
	on		substring(des2.program_name,30,34) = convert(varchar(34), convert(varbinary(32), j2.job_id), 1) 
	and		des2.program_name like 'sqlagent%'
left join	sys.dm_tran_session_transactions dtst
	on		dec.session_id = dtst.session_id
left join	sys.dm_tran_active_transactions dtat
	on		dtat.transaction_id = dtst.transaction_id
order by	blocking_status desc

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

declare @sql nvarchar(4000)
declare @database_name varchar(64);
select @database_name = db_name(database_id) from master.sys.dm_exec_requests where blocking_session_id <> 0;

if object_id('tempdb..#blocks','U') is not null
	drop table #blocks;

create table #blocks (session_id smallint not null);

insert #blocks (session_id)
select session_id from master.sys.dm_exec_requests where blocking_session_id <> 0
union 
select blocking_session_id from master.sys.dm_exec_requests where blocking_session_id <> 0;

select	@sql = N''
select	@sql += N'use ' + @database_name + ';'
select	@sql += N'select		dtl.request_session_id, '
select	@sql += N'			db_name(dtl.resource_database_id) as database_name, '
select	@sql += N'			case ' 
select	@sql += N'				when dtl.resource_type = ''OBJECT'' then OBJECT_NAME(dtl.resource_associated_entity_id) '
select	@sql += N'				when dtl.resource_associated_entity_id = 0 then '''' '
select	@sql += N'				else OBJECT_NAME(p.object_id) '
select	@sql += N'			end as objectname, '
select	@sql += N'			p.rows, '
select	@sql += N'			dtl.resource_type, '
select	@sql += N'			dtl.request_mode, '
select	@sql += N'			dtl.resource_description, '
select	@sql += N'			dtl.request_status, '
select	@sql += N'			i.name index_name, '
select	@sql += N'			i.index_id '
select	@sql += N'from		#blocks b '
select	@sql += N'join		sys.dm_tran_locks dtl '
select	@sql += N'  on		b.session_id = dtl.request_session_id '
select	@sql += N'left join	sys.partitions p '
select	@sql += N'	on		dtl.resource_associated_entity_id = p.hobt_id '
select	@sql += N'	or		dtl.resource_associated_entity_id = p.object_id '
select	@sql += N'left join	sys.tables t '
select	@sql += N'	on		p.object_id = t.object_id '
select	@sql += N'left join	sys.indexes i '
select	@sql += N'	on		p.object_id = i.object_id '
select	@sql += N'	and		p.index_id = i.index_id '
select	@sql += N'left join	sys.dm_exec_requests der '
select	@sql += N'	on		dtl.request_session_id = der.session_id '
select	@sql += N'where		dtl.request_session_id <> @@spid '
select	@sql += N'	and		dtl.resource_type <> ''DATABASE'' '
select	@sql += N'	and		dtl.resource_database_id not in (1,2,3,4)'
select	@sql += N'order by	dtl.request_status desc, dtl.request_session_id; '
execute sp_executesql @sql

--verificação utilização tempdb
select 
		sum(unallocated_extent_page_count) as FreePages,
		sum(unallocated_extent_page_count) * 8 / 1024. as FreeSpaceMB,
		sum(version_store_reserved_page_count) as VersionStorePages ,
		sum(version_store_reserved_page_count)* 8 / 1024. as VersionStoreMB,
		sum(internal_object_reserved_page_count) as InternalObjectPages,
		sum(internal_object_reserved_page_count)* 8 / 1024. as InternalObjectsMB,
		sum(user_object_reserved_page_count) as UserObjectPages,
		sum(user_object_reserved_page_count)* 8 / 1024. as UserObjectsMB 
from	tempdb.sys.dm_db_file_space_usage;


--incrementar
select * from sys.dm_db_session_space_usage where session_id > 50 order by 3 desc

select		j.name, t.text, s.session_id
from		sys.dm_exec_sessions s with (nolock)
inner join	sys.dm_exec_requests r with (nolock)
	on		s.session_id = r.session_id
cross apply	sys.dm_exec_sql_text (r.sql_handle) t 
inner join	msdb..sysjobsteps js with (nolock)
	on		substring(s.program_name,30,34) = convert(varchar(34), convert(varbinary(32), js.job_id), 1) 
inner join	msdb..sysjobs j with (nolock)
	on		js.job_id = j.job_id
where		s.program_name like 'SQLAgent%'
	and		js.step_id = 1

use msdb
go
select		
			j.name, j.enabled, j.start_step_id, j.date_created, j.date_modified, j.version_number,
			js.step_id, js.step_name, js.subsystem, js.command, js.last_run_date, js.last_run_time, js.last_run_duration, js.last_run_outcome,
			jsc.next_run_date, jsc.next_run_time
from		sysjobs j
inner join	sysjobsteps js
	on		j.job_id = js.job_id
inner join	sysjobschedules jsc
	on		j.job_id = jsc.job_id
where		j.enabled = 1

select		@@servername as instance,
			db_name(dfsu.database_id) as [database_name],
			dovs.volume_mount_point as mount,
			dovs.logical_volume_name as volume,
			mf.physical_name,

			--sum(dfsu.total_page_count * 8) / 1024. as total_file_size_in_MB,
			--sum(dfsu.allocated_extent_page_count * 8) / 1024.  as file_size_used_in_MB,
			--sum(dfsu.unallocated_extent_page_count* 8) / 1024. as file_size_unused_in_MB,
			--dovs.total_bytes / 1024 / 1024. as total_disk_size_in_MB,
			--dovs.available_bytes / 1024 / 1024. as free_space_in_MB,

			sum(dfsu.total_page_count * 8) / 1024 / 1024. as total_file_size_in_GB,
			sum(dfsu.allocated_extent_page_count * 8) / 1024 / 1024.  as file_size_used_in_GB,
			sum(dfsu.unallocated_extent_page_count* 8) / 1024 / 1024. as file_size_unused_in_GB,
			dovs.total_bytes / 1024 / 1024 / 1024. as total_disk_size_in_GB,
			dovs.available_bytes / 1024 / 1024 / 1024. as free_space_in_GB,

			convert(varchar,getdate(),103) as dtProcessamento
from		sys.dm_db_file_space_usage dfsu with (nolock)
inner join	sys.master_files mf with (nolock) 
	on		dfsu.file_id=mf.file_id 
	and		dfsu.database_id=mf.database_id
cross apply sys.dm_os_volume_stats (mf.database_id, mf.file_id) as dovs
group by	db_name(dfsu.database_id), mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, dovs.total_bytes / 1024 / 1024., dovs.available_bytes / 1024 / 1024., dovs.total_bytes / 1024 / 1024 / 1024., dovs.available_bytes / 1024 / 1024 / 1024.
union
select		@@servername as instance,
			db_name(dfsu.database_id) as [database_name],
			dovs.volume_mount_point as mount,
			dovs.logical_volume_name as volume,
			mf.physical_name,

			--sum(dfsu.total_log_size_in_bytes) / 1024 / 1024. as total_file_size_in_MB,
			--sum(dfsu.used_log_space_in_bytes) / 1024 / 1024. as file_size_used_in_MB,
			--sum(dfsu.total_log_size_in_bytes - dfsu.used_log_space_in_bytes) / 1024 / 1024. as file_size_unused_in_MB,
			--dovs.total_bytes /1024 /1024. as total_disk_size_in_MB,
			--dovs.available_bytes /1024 /1024. as free_space_in_MB,

			sum(dfsu.total_log_size_in_bytes) / 1024 / 1024 / 1024. as total_file_size_in_GB,
			sum(dfsu.used_log_space_in_bytes) / 1024 / 1024 / 1024. as file_size_used_in_GB,
			sum(dfsu.total_log_size_in_bytes - dfsu.used_log_space_in_bytes) / 1024 / 1024 / 1024. as file_size_unused_in_GB,
			dovs.total_bytes / 1024 / 1024 / 1024. as total_disk_size_in_GB,
			dovs.available_bytes / 1024 / 1024 / 1024. as free_space_in_GB,

			convert(varchar,getdate(),103) as dtProcessamento
from		sys.dm_db_log_space_usage dfsu with (nolock)
inner join	sys.master_files mf with (nolock) 
	on		dfsu.database_id=mf.database_id
	and		mf.type = 1
cross apply sys.dm_os_volume_stats (mf.database_id, mf.file_id) as dovs
group by	db_name(dfsu.database_id), mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, dovs.total_bytes /1024 /1024., dovs.available_bytes /1024 /1024., dovs.total_bytes / 1024 / 1024 / 1024., dovs.available_bytes / 1024 / 1024 / 1024. 
order by	physical_name

--


--exec master..sp_WhoIsActive;

dbcc sqlperf(logspace)--99.52225
go
use master
go
select 	db_name(database_id) as database_name,
		cast(total_log_size_in_bytes / 1024 / 1024. as numeric(10,2)) as total_log_size_in_MB,
		cast(used_log_space_in_bytes / 1024 / 1024. as numeric(10,2)) as used_log_space_in_MB,
		cast((total_log_size_in_bytes - used_log_space_in_bytes) / 1024 / 1024. as numeric(10,2)) as unused_log_space_in_MB,
		cast(used_log_space_in_percent as numeric(5,2)) as used_log_space_in_percent,
		(100 - cast(used_log_space_in_percent as numeric(5,2))) as unused_log_space_in_percent
from	BDTPEDI.sys.dm_db_log_space_usage with (nolock)

use DBA_Admin
go
create table dbo.tb_utilizacao_espaco_log
(
	id	int identity(1,1) primary key,
	database_name varchar(64),
	total_log_size_in_MB numeric(10,2),
	used_log_space_in_MB numeric(10,2),
	unused_log_space_in_MB numeric(10,2),
	used_log_space_in_percent numeric(5,2),
	unused_log_space_in_percent numeric(5,2),
	dt_processamento datetime default getdate()
);

select * from DBA_Admin.dbo.tb_utilizacao_espaco_log

select * from DBA_Admin.dbo.tb_utilizacao_espaco_log
used_log_space_in_percent

begin try
	if exists (select 1 from BDTPEDI.sys.dm_db_log_space_usage where used_log_space_in_percent >  0.04)
	begin
		insert	tb_utilizacao_espaco_log (database_name,total_log_size_in_MB,used_log_space_in_MB,unused_log_space_in_MB,used_log_space_in_percent,unused_log_space_in_percent)
		select 	db_name(database_id) as database_name,
				cast(total_log_size_in_bytes / 1024 / 1024. as numeric(10,2)) as total_log_size_in_MB,
				cast(used_log_space_in_bytes / 1024 / 1024. as numeric(10,2)) as used_log_space_in_MB,
				cast((total_log_size_in_bytes - used_log_space_in_bytes) / 1024 / 1024. as numeric(10,2)) as unused_log_space_in_MB,
				cast(used_log_space_in_percent as numeric(5,2)) as used_log_space_in_percent,
				(100 - cast(used_log_space_in_percent as numeric(5,2))) as unused_log_space_in_percent
		from	BDTPEDI.sys.dm_db_log_space_usage with (nolock)	
	end
	end try
begin catch

end catch