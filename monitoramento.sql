
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

--###############################################################################################################################################################################################################################
--SESSIONS
--###############################################################################################################################################################################################################################

select		ec.client_net_address, es.program_name, es.host_name, es.login_name, count(ec.session_id) as connection_count
from		sys.dm_exec_sessions as es
inner join	sys.dm_exec_connections as ec
			on es.session_id = ec.session_id
group by	ec.client_net_address, es.program_name, es.host_name, es.login_name
order by	ec.client_net_address, es.program_name;

select		@@servername as server_name, login_name, count(session_id) as session_count
from		sys.dm_exec_sessions
group by	login_name
order by	count(session_id) desc ;

select		@@servername as server_name, login_name, count(session_id) as session_count, status
from		sys.dm_exec_sessions
where		login_name = 'user_gtc'
group by	login_name, status
order by	count(session_id) desc ;

select		r.session_id ,
			r.status ,
			r.wait_type ,
			r.scheduler_id ,
			substring(qt.text, r.statement_start_offset / 2, ( case when r.statement_end_offset = -1 then len(convert(nvarchar(max), qt.[text])) * 2 else r.statement_end_offset end - r.statement_start_offset ) / 2) as statement_executing ,
			db_name(qt.dbid) as databasename ,
			object_name(qt.objectid) as objectname ,
			r.cpu_time ,
			r.total_elapsed_time ,
			r.reads ,
			r.writes ,
			r.logical_reads ,
			r.plan_handle
from		sys.dm_exec_requests as r
cross apply	sys.dm_exec_sql_text(sql_handle) as qt
where		r.session_id > 50
order by	r.scheduler_id, r.status, r.session_id;

--###############################################################################################################################################################################################################################
--CPU
--###############################################################################################################################################################################################################################
select cpu_ticks, ms_ticks, cpu_count as cpu_logical, hyperthread_ratio, cpu_count / hyperthread_ratio as cpu_physical, os_quantum, max_workers_count, scheduler_count, affinity_type, affinity_type_desc  from sys.dm_os_sys_info;

select  cast(100.0 * sum(signal_wait_time_ms) / sum(wait_time_ms) as numeric(20,2)) as [%signal (cpu) waits] ,
        cast(100.0 * sum(wait_time_ms - signal_wait_time_ms) / sum(wait_time_ms) as numeric(20, 2)) as [%resource waits]
from    sys.dm_os_wait_stats;

declare @ts_now bigint = (select cpu_ticks/(cpu_ticks/ms_ticks)from sys.dm_os_sys_info); 

select	top(60) sqlprocessutilization as sql_server_process_cpu_utilization, systemidle as system_idle_process, 100 - systemidle - sqlprocessutilization as other_process_cpu_utilization, dateadd(ms, -1 * (@ts_now - timestamp), getdate()) as event_time
from 
( 
	select	record.value('(./Record/@id)[1]', 'int') as record_id, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as systemidle, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as sqlprocessutilization, timestamp 
	from	
	( 
		select	timestamp, convert(xml, record) as record 
		from	sys.dm_os_ring_buffers 
		where	ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			and record like N'%<SystemHealth>%'
	) as x 
) as y 
order by record_id desc;

-- Get Avg task count and Avg runnable task count
select  avg(current_tasks_count) as avg_task_count, avg(runnable_tasks_count) as avg_runnable_task_count
from    sys.dm_os_schedulers
where   scheduler_id < 255
	and status = 'VISIBLE ONLINE' ;

select  is_idle, current_tasks_count, runnable_tasks_count, current_workers_count,active_workers_count, work_queue_count, pending_disk_io_count, load_factor
from    sys.dm_os_schedulers
where   scheduler_id < 255


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

select	dos.current_tasks_count,dos.runnable_tasks_count,dos.current_workers_count,dos.active_workers_count,dos.work_queue_count,dos.pending_disk_io_count,dos.load_factor,dos.yield_count,dos.quantum_length_us,dos.is_idle,dos.preemptive_switches_count,dos.context_switches_count,dos.idle_switches_count
from	sys.dm_os_schedulers dos	
where   dos.scheduler_id < 255
	and dos.status = 'VISIBLE ONLINE' ;	

--###############################################################################################################################################################################################################################
--MEMORY
--###############################################################################################################################################################################################################################

select physical_memory_in_bytes / 1024 / 1024 / 1024. as physical_memory_in_gb, virtual_memory_in_bytes , bpool_committed / 1024 / 1024. as bpool_committed_in_gb, bpool_commit_target /1024. as bpool_commit_target_in_gb , bpool_visible from sys.dm_os_sys_info;
select total_physical_memory_kb / 1024 / 1024.  as total_physical_memory_gb, available_physical_memory_kb / 1024 / 1024. as available_physical_memory_gb, total_page_file_kb / 1024 / 1024. as total_page_file_gb, available_page_file_kb / 1024 / 1024. as available_page_file_gb , system_memory_state_desc from sys.dm_os_sys_memory ;

--select physical_memory_in_bytes , virtual_memory_in_bytes , bpool_committed , bpool_commit_target , bpool_visible from sys.dm_os_sys_info;
--select total_physical_memory_kb , available_physical_memory_kb, total_page_file_kb , available_page_file_kb , system_memory_state_desc from sys.dm_os_sys_memory ;

select	physical_memory_kb / 1024 / 1024. as physical_memory_in_gb, 
		committed_kb  / 1024 / 1024. as bpool_committed_in_gb,
		committed_target_kb /1024 /1024. as bpool_commit_target_in_gb , 
		visible_target_kb /1024 /1024. as visible_target_kb
from	sys.dm_os_sys_info;

select	total_physical_memory_kb / 1024 / 1024.  as total_physical_memory_gb, 
		available_physical_memory_kb / 1024 / 1024. as available_physical_memory_gb, 
		(total_page_file_kb - total_physical_memory_kb) / 1024 / 1024. as total_page_file,
		total_page_file_kb / 1024 / 1024. as total_virtual_memory_in_gb, 
		available_page_file_kb / 1024 / 1024. as available_virtual_memory_in_gb , 
		system_memory_state_desc 
from	sys.dm_os_sys_memory ;

SELECT  physical_memory_in_use_kb ,
        locked_page_allocations_kb ,
        page_fault_count ,
        memory_utilization_percentage ,
        available_commit_limit_kb ,
        process_physical_memory_low ,
        process_virtual_memory_low
FROM    sys.dm_os_process_memory ;

SELECT  physical_memory_in_use_kb / 1024. as Phy_Mem_In_MB ,
		virtual_address_space_committed_kb / 1024. as Total_Mem_Used_MB,
		(virtual_address_space_committed_kb - physical_memory_in_use_kb) / 1024. as Mem_as_PageFile_MB
FROM    sys.dm_os_process_memory ;

select *
from	sys.dm_os_performance_counters
where	object_name like '%buffer manager%'
and		counter_name = 'page life expectancy'

use master
go
select		name ,
			type ,
			entries_count ,
			single_pages_kb ,
			single_pages_in_use_kb ,
			multi_pages_kb ,
			multi_pages_in_use_kb
from		sys.dm_os_memory_cache_counters
where		type = 'CACHESTORE_SQLCP' 
	or		type = 'CACHESTORE_OBJCP'
order by	multi_pages_kb desc ;

select		name ,
			type ,
			entries_count ,
			pages_kb ,
			pages_in_use_kb 
from		sys.dm_os_memory_cache_counters
where		type = 'CACHESTORE_SQLCP' 
	or		type = 'CACHESTORE_OBJCP'
order by	pages_kb desc ;

use master
go
select		db_name(database_id) as database_name ,
			count(*) * 8 / 1024.0 as cached_size_mb
from		sys.dm_os_buffer_descriptors
where		database_id > 4 -- exclude system databases
	and		database_id <> 32767 -- exclude resourcedb
	and		database_id <> db_id('distribution')
group by	db_name(database_id)
order by	cached_size_mb desc;

use dbAuditoria
go
select		object_name(p.object_id) as objectname ,
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

select		top (100) 
			dest.text,*
from		sys.dm_exec_cached_plans as cp
cross apply	sys.dm_exec_sql_text (cp.plan_handle)  dest
where		cp.cacheobjtype = 'Compiled Plan'
	and		cp.objtype = 'Adhoc'
order by	cp.usecounts desc

select		sum(cast(cp.size_in_bytes as bigint)) / 1024 / 1024 / 1024.
from		sys.dm_exec_cached_plans as cp
where		cp.cacheobjtype = 'Compiled Plan'
	and		cp.objtype = 'Adhoc'


select	* from sys.dm_exec_query_memory_grants

-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2008 version
select		db_name(st.dbid) as database_name, mg.requested_memory_kb , mg.ideal_memory_kb , mg.request_time , mg.grant_time , mg.query_cost , mg.dop , st.[text] 
from		sys.dm_exec_query_memory_grants as mg
cross apply sys.dm_exec_sql_text(plan_handle) as st
--where		mg.request_time < coalesce(grant_time, '99991231')
order by	mg.requested_memory_kb desc ;

-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2005 version
select		db_name(st.dbid) as database_name, mg.requested_memory_kb, mg.request_time, mg.grant_time, mg.query_cost, mg.dop, st.text
from		sys.dm_exec_query_memory_grants as mg
cross apply	sys.dm_exec_sql_text(plan_handle) as st
where		mg.request_time < coalesce(grant_time, '99991231')
order by	mg.requested_memory_kb desc ;

select		convert (varchar(30), getdate(), 121) as [runtime],
			dateadd (ms, (rbf.[timestamp] - tme.ms_ticks), getdate()) as [notification_time],
			cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') as [notification_type],
			cast(record as xml).value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') as [memoryutilization %],
			cast(record as xml).value('(//Record/MemoryNode/@id)[1]', 'bigint') as [node id],
			cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') as [process_indicator],
			cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') as [system_indicator],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect/@type)[1]', 'varchar(30)') as [type],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect/@state)[1]', 'varchar(30)') as [state],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect/@reversed)[1]', 'int') as [reserved],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect)[1]', 'bigint') as [effect],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@type)[1]', 'varchar(30)') as [type],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@state)[1]', 'varchar(30)') as [state],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect[2]/@reversed)[1]', 'int') as [reserved],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect)[2]', 'bigint') as [effect],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@type)[1]', 'varchar(30)') as [type],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@state)[1]', 'varchar(30)') as [state],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect[3]/@reversed)[1]', 'int') as [reserved],
			cast(record as xml).value('(//Record/ResourceMonitor/Effect)[3]', 'bigint') as [effect],
			cast(record as xml).value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') as [sql_reserved_memory_kb],
			cast(record as xml).value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') as [sql_committed_memory_kb],
			cast(record as xml).value('(//Record/MemoryNode/AWEMemory)[1]', 'bigint') as [sql_awe_memory],
			cast(record as xml).value('(//Record/MemoryNode/PagesMemory)[1]', 'bigint') as [pages_memory], -- 2012
			--cast(record as xml).value('(//Record/MemoryNode/SinglePagesMemory)[1]', 'bigint') as [single_pages_memory], --2008
			--cast(record as xml).value('(//Record/MemoryNode/MultiplePagesMemory)[1]', 'bigint') as [multiple_pages_memory], --2008
			cast(record as xml).value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') as [total_physical_memory_kb],
			cast(record as xml).value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') as [available_physical_memory_kb],
			cast(record as xml).value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') as [total_pagefile_kb],
			cast(record as xml).value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') as [available_pagefile_kb],
			cast(record as xml).value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') as [total_virtual_address_space_kb],
			cast(record as xml).value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') as [available_virtual_address_space_kb],
			cast(record as xml).value('(//Record/@id)[1]', 'bigint') as [record id],
			cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') as [type],
			cast(record as xml).value('(//Record/@time)[1]', 'bigint') as [record time],
			tme.ms_ticks as [current time]
from		sys.dm_os_ring_buffers rbf
cross join	sys.dm_os_sys_info tme
where		rbf.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
order by	rbf.timestamp asc



--###############################################################################################################################################################################################################################
--DISK
--###############################################################################################################################################################################################################################

if object_id('tempdb..#temp1') is not null
	drop table #temp1;--##sqlskillsstats1

if object_id('tempdb..#temp2') is not null
	drop table #temp2;--##sqlskillsstats2

select  database_id, file_id, num_of_reads, io_stall_read_ms, num_of_writes, io_stall_write_ms, io_stall, num_of_bytes_read, num_of_bytes_written, file_handle
into	#temp1
from	sys.dm_io_virtual_file_stats (null, null)
--where	database_id = 25
go

waitfor delay '00:00:30';
go
 
select  database_id, file_id, num_of_reads, io_stall_read_ms, num_of_writes, io_stall_write_ms, io_stall, num_of_bytes_read, num_of_bytes_written, file_handle
into	#temp2
from	sys.dm_io_virtual_file_stats (null, null)
--where	database_id = 25
go
 
with diff_latencies as
(
	-- files that weren't in the first snapshot
	select
		        t2.database_id, t2.file_id, t2.num_of_reads, t2.io_stall_read_ms, t2.num_of_writes, t2.io_stall_write_ms, t2.io_stall, t2.num_of_bytes_read, t2.num_of_bytes_written
    from		#temp2 as t2
    left join	#temp1 as t1
        on		t2.file_handle = t1.file_handle
    where		t1.file_handle is null
	union
	-- diff of latencies in both snapshots
	select
				t2.database_id, t2.file_id, t2.num_of_reads - t1.num_of_reads as num_of_reads, t2.io_stall_read_ms - t1.io_stall_read_ms as io_stall_read_ms, t2.num_of_writes - t1.num_of_writes as num_of_writes, t2.io_stall_write_ms - t1.io_stall_write_ms as io_stall_write_ms, t2.io_stall - t1.io_stall as io_stall, t2.num_of_bytes_read - t1.num_of_bytes_read as num_of_bytes_read, t2.num_of_bytes_written - t1.num_of_bytes_written as num_of_bytes_written
    from		#temp2 as t2
    left join	#temp1 as t1
        on		t2.file_handle = t1.file_handle
    where		t1.file_handle is not null
)
select
			db_name (vfs.database_id) as db,
			left (mf.physical_name, 2) as drive,
			mf.type_desc,
			num_of_reads as reads,
			num_of_writes as writes,
			readlatency_ms = case when num_of_reads = 0 then 0 else (io_stall_read_ms / num_of_reads) end,
			writelatency_ms = case when num_of_writes = 0 then 0 else (io_stall_write_ms / num_of_writes) end,
			--latency = case when (num_of_reads = 0 and num_of_writes = 0) then 0 else (io_stall / (num_of_reads + num_of_writes)) end,
			avgbperread = case when num_of_reads = 0 then 0 else (num_of_bytes_read / num_of_reads) end, 
			avgbperwrite = case when num_of_writes = 0 then 0 else (num_of_bytes_written / num_of_writes) end,
			--avgbpertransfer = case when (num_of_reads = 0 and num_of_writes = 0) then 0 else ((num_of_bytes_read + num_of_bytes_written) / (num_of_reads + num_of_writes)) end,
			mf.physical_name
from		diff_latencies as vfs
inner join	sys.master_files as mf
    on		vfs.database_id = mf.database_id
    and		vfs.file_id = mf.file_id
order by	readlatency_ms desc
--order by	writelatency_ms desc;
go
 
if object_id('tempdb..#temp1') is not null
	drop table #temp1;--##sqlskillsstats1

if object_id('tempdb..#temp2') is not null
	drop table #temp2;--##sqlskillsstats2

-- Calculates average stalls per read, per write, and per total input/output for each database file. 
select		db_name(database_id) as database_name, file_id, io_stall_read_ms ,
			num_of_reads ,
			cast(io_stall_read_ms / ( 1.0 + num_of_reads ) as numeric(10, 1)) as avg_read_stall_ms ,
			io_stall_write_ms ,
			num_of_writes ,
			cast(io_stall_write_ms / ( 1.0 + num_of_writes ) as numeric(10, 1)) as avg_write_stall_ms ,
			io_stall_read_ms + io_stall_write_ms as io_stalls ,
			num_of_reads + num_of_writes as total_io ,
			cast(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads + num_of_writes) as numeric(10,1)) as avg_io_stall_ms
from		sys.dm_io_virtual_file_stats(null, null)
--order by	avg_io_stall_ms desc;
--order by	avg_read_stall_ms desc;
order by	avg_write_stall_ms desc;

-- Look at pending I/O requests by file
select		db_name(mf.database_id) as database_name, mf.physical_name, r.io_pending, r.io_pending_ms_ticks, r.io_type, fs.num_of_reads, fs.num_of_writes
from		sys.dm_io_pending_io_requests as r
inner join	sys.dm_io_virtual_file_stats(null, null) as fs
	on		r.io_handle = fs.file_handle
inner join	sys.master_files as mf 
	on		fs.database_id = mf.database_id
	and		fs.file_id = mf.file_id
order by	r.io_pending, r.io_pending_ms_ticks desc;

select		db_name(mf.database_id) as database_name, r.io_type, count(r.io_pending) io_pending_count, sum(r.io_pending_ms_ticks) io_pending_ms_sum
from		sys.dm_io_pending_io_requests as r
inner join	sys.dm_io_virtual_file_stats(null, null) as fs
	on		r.io_handle = fs.file_handle
inner join	sys.master_files as mf 
	on		fs.database_id = mf.database_id
	and		fs.file_id = mf.file_id
group by	db_name(mf.database_id) , r.io_type


--###############################################################################################################################################################################################################################
--BLOCK
--###############################################################################################################################################################################################################################

use master
go

select count(*) from sys.sysprocesses where blocked <> 0 and spid <> blocked

select * from master.sys.dm_exec_sessions where session_id = 165
select * from master.sys.dm_exec_requests where session_id = 169
select * from master.sys.dm_os_waiting_tasks where session_id = 165

dbcc inputbuffer (165)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
select @database_name = db_name(database_id) from master.sys.dm_exec_requests with (nolock) where blocking_session_id <> 0;

if object_id('tempdb..#blocks','U') is not null
	drop table #blocks;

create table #blocks (session_id smallint not null);

insert #blocks (session_id)
select session_id from master.sys.dm_exec_requests with (nolock) where blocking_session_id <> 0
union 
select blocking_session_id from master.sys.dm_exec_requests with (nolock) where blocking_session_id <> 0;

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
select	@sql += N'from		#blocks b with (nolock) '
select	@sql += N'join		sys.dm_tran_locks dtl with (nolock) '
select	@sql += N'  on		b.session_id = dtl.request_session_id '
select	@sql += N'left join	sys.partitions p with (nolock) '
select	@sql += N'	on		dtl.resource_associated_entity_id = p.hobt_id '
select	@sql += N'	or		dtl.resource_associated_entity_id = p.object_id '
select	@sql += N'left join	sys.tables t with (nolock) '
select	@sql += N'	on		p.object_id = t.object_id '
select	@sql += N'left join	sys.indexes i with (nolock) '
select	@sql += N'	on		p.object_id = i.object_id '
select	@sql += N'	and		p.index_id = i.index_id '
select	@sql += N'left join	sys.dm_exec_requests der with (nolock) '
select	@sql += N'	on		dtl.request_session_id = der.session_id '
select	@sql += N'where		dtl.request_session_id <> @@spid '
select	@sql += N'	and		dtl.resource_type <> ''DATABASE'' '
select	@sql += N'	and		dtl.resource_database_id not in (1,2,3,4)'
select	@sql += N'order by	dtl.request_status desc, dtl.request_session_id; '
execute sp_executesql @sql

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select		db_name(dtl.resource_database_id) as database_name,
			object_name(p.object_id, dtl.resource_database_id) as object_name,
			dtl.resource_description,
			dtl.request_mode,
			dtl.request_type,
			dtl.request_status,
			dtl.request_session_id
from		sys.dm_tran_locks dtl
left join	sys.partitions p
	on		dtl.resource_associated_entity_id = p.hobt_id
	or		dtl.resource_associated_entity_id = p.object_id
where		1=1
	--and		dtl.request_status = 'WAIT'
	and		request_mode = 'X'
	and		request_type = 'LOCK'
	and		request_status = 'GRANT'
	--and		request_session_id = 69	

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select		
			dec.session_id as blocking_session
			,der.session_id as blocked_session
			,des.status as blocking_status
			,des2.status as blocked_status
			,dowt1.wait_duration_ms as blocking_wait_duration
			,dowt2.wait_duration_ms as blocked_wait_duration
			,dowt1.wait_type as blocking_wait_type
			,dowt2.wait_type as blocked_wait_type
			,dowt1.resource_description as blocking_resource_description
			,dowt2.resource_description as blocked_resource_description
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
			,j.name job_name
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
left join	sys.dm_os_waiting_tasks dowt1
	on		dec.session_id = dowt1.session_id
left join	sys.dm_os_waiting_tasks dowt2
	on		der.session_id = dowt2.session_id
cross apply sys.dm_exec_sql_text(dec.most_recent_sql_handle) blocking
cross apply sys.dm_exec_sql_text(der.sql_handle) blocked
left join	msdb..sysjobs j
	on		substring(des2.program_name,30,34) = convert(varchar(34), convert(varbinary(32), j.job_id), 1) 
	and		des2.program_name like 'sqlagent%'
left join	sys.dm_tran_session_transactions dtst
	on		dec.session_id = dtst.session_id
left join	sys.dm_tran_active_transactions dtat
	on		dtat.transaction_id = dtst.transaction_id
order by	blocking_status desc

--###############################################################################################################################################################################################################################
--TEMPDB
--###############################################################################################################################################################################################################################

select	sum(unallocated_extent_page_count) as free_pages, (sum(unallocated_extent_page_count) * 1.0 / 128) as free_space_in_mb, (sum(unallocated_extent_page_count) * 1.0 / 128) / 1024. as free_space_in_gb
from	sys.dm_db_file_space_usage ;
      
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
from sys.dm_db_file_space_usage;

--sessão com mais alocações
select * from sys.dm_db_session_space_usage where session_id > 50 order by 3 desc
select * from sys.dm_exec_sessions where session_id in (167,145)

select		dssu.session_id
			,dssu.user_objects_alloc_page_count
			,dssu.user_objects_dealloc_page_count
			,dssu.internal_objects_alloc_page_count
			,dssu.internal_objects_dealloc_page_count
			,des.login_name
			,des.host_name
			,des.program_name
			,des.login_time
			,des.status
			--* 
from		sys.dm_db_session_space_usage dssu
inner join	sys.dm_exec_sessions des
	on		dssu.session_id = des.session_id 
where		dssu.session_id > 50 
order by	2 desc

select		des.login_name
			,sum(dssu.user_objects_alloc_page_count) as user_objects_alloc_page_count
			,sum(dssu.user_objects_dealloc_page_count) as user_objects_dealloc_page_count
			,sum(dssu.user_objects_alloc_page_count) - sum(dssu.user_objects_dealloc_page_count) as current_user_objects_alloc_page_count
			,sum(dssu.internal_objects_alloc_page_count) as internal_objects_alloc_page_count
			,sum(dssu.internal_objects_dealloc_page_count) as internal_objects_dealloc_page_count
			,(sum(dssu.internal_objects_alloc_page_count) - sum(dssu.internal_objects_dealloc_page_count)) * 8 / 1024. as current_internal_objects_alloc_page_count_in_MB
from		sys.dm_db_session_space_usage dssu
inner join	sys.dm_exec_sessions des
	on		dssu.session_id = des.session_id 
where		des.is_user_process = 1
group by	des.login_name

--###############################################################################################################################################################################################################################
--JOB
--###############################################################################################################################################################################################################################

select s.step_id,s.last_run_date, s.last_run_time, s.last_run_duration, s.last_run_outcome,* from msdb..sysjobs j inner join msdb..sysjobsteps s on j.job_id = s.job_id where j.name ='Atualiza tabelas de Seguro' 

select h.step_id,h.run_date, h.run_time, h.run_duration, h.run_status, * from msdb..sysjobs j inner join msdb..sysjobhistory h on j.job_id = h.job_id where j.name ='Dev - Startar Contingencia Repl MSSDFISC Novo'  order by 1 desc

select * from msdb..sysjobs j inner join msdb..sysjobsteps s on j.job_id = s.job_id where s.command like '%teste%'

select		j.name, t.text, s.session_id
from		sys.dm_exec_sessions s 
inner join	sys.dm_exec_requests r 
	on		s.session_id = r.session_id
cross apply	sys.dm_exec_sql_text (r.sql_handle) t
inner join	msdb..sysjobsteps js 
	on		substring(s.program_name,30,34) = convert(varchar(34), convert(varbinary(32), js.job_id), 1) 
inner join	msdb..sysjobs j 
	on		js.job_id = j.job_id
where		s.program_name like 'SQLAgent%'
	and		js.step_id = 1


--
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

--###############################################################################################################################################################################################################################
--OTHERS
--###############################################################################################################################################################################################################################

select		db.[name] as [database name] ,
			db.recovery_model_desc as [recovery model] ,
			db.log_reuse_wait_desc as [log reuse wait description] ,
			ls.cntr_value as [log size (kb)] ,
			lu.cntr_value as [log used (kb)] ,
			case when lu.cntr_value > 0 and ls.cntr_value > 0 then cast(cast(lu.cntr_value as float) / cast(ls.cntr_value as float) as decimal(18,2)) * 100 else 0 end as [log used %],
			db.compatibility_level,
			db.page_verify_option_desc as page_verify_option
from		sys.databases as db
inner join	sys.dm_os_performance_counters as lu
	on		db.name = lu.instance_name
inner join sys.dm_os_performance_counters as ls
	on		db.name = ls.instance_name
where		lu.counter_name like 'Log File(s) Used Size (KB)%'
    and		ls.counter_name like 'Log File(s) Size (KB)%' ;

--plan cache
select	
			cp.objType
			,cp.useCounts
			,st.text as query
			,qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/Showplan";
								 (//StmtSimple/@StatementOptmLevel)[1]','varchar(20)') as StatementOptmLevel
			,qp.query_plan
from		sys.dm_exec_cached_plans cp
cross apply	sys.dm_exec_sql_text(cp.plan_handle) st
cross apply	sys.dm_exec_query_plan(cp.plan_handle) qp
where		st.text like '%%'			
	and		st.text not like '%sys.%'
	and		cp.objtype = 'Prepared'
order by	cp.useCounts desc--223

--###############################################################################################################################################################################################################################
--OTHERS
--###############################################################################################################################################################################################################################

select
			ec.session_id,
			es.login_name,
			es.host_name,
			er.status,
			er.command,
			qt.text,
			SUBSTRING(qt.[text], er.statement_start_offset / 2,
				( CASE WHEN er.statement_end_offset = -1
					   THEN LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2
					   ELSE er.statement_end_offset
				  END - er.statement_start_offset ) / 2) AS [statement_executing], 
			er.blocking_session_id,
			er.wait_type,
			er.wait_time,
			er.last_wait_type,
			er.wait_resource,
			er.open_transaction_count,
			er.reads reads_request,
			er.writes writes_request,
			er.logical_reads logical_reads_request,
			er.cpu_time cpu_time_request,
			ec.num_reads reads_connection,
			es.reads reads_session,
			es.logical_reads logical_reads_session,
			ec.num_writes writes_connection,
			es.writes writes_session,
			es.is_user_process,
			er.transaction_isolation_level,
			er.granted_query_memory,
			es.memory_usage,
			er.total_elapsed_time,
			DB_NAME(er.database_id) AS [DatabaseName] ,
			qt.objectid,
			eps.object_id,
			OBJECT_NAME(qt.objectid) AS [ObjectName] ,
			OBJECT_NAME(eps.[object_id]) AS ProcedureName,	
			es.program_name,
			ec.client_net_address,
			ec.connect_time,
			es.login_time,
			es.last_request_start_time,
			es.last_request_end_time,
			ec.last_read,
			ec.last_write,
			ec.most_recent_sql_handle,
			eqp.query_plan
FROM		sys.dm_exec_requests AS er
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY	sys.dm_exec_query_plan (er.plan_handle) eqp
inner join  sys.dm_exec_sessions es
	on		er.session_id = es.session_id
inner join	sys.dm_exec_connections ec
	on		er.session_id = ec.session_id
left join	sys.dm_exec_procedure_stats eps
	on		er.sql_handle = eps.sql_handle      
--WHERE		er.session_id != @@SPID
WHERE		er.session_id = 57
go

--###############################################################################################################################################################################################################################
--info data and log files
--###############################################################################################################################################################################################################################

select 		db_name(dfsu.database_id) as database_name,
			df.[name] as data_file_name,
			df.physical_name,
			dfsu.[file_id],
			dfsu.[filegroup_id],
			dfsu.total_page_count * 8 / 1024. as total_data_file_size_in_MB,
			dfsu.allocated_extent_page_count * 8 / 1024. as used_data_file_size_in_MB,
			dfsu.unallocated_extent_page_count * 8 / 1024. as unused_data_file_size_in_MB,
			dfsu.total_page_count * 8 / 1024 / 1024. as total_data_file_size_in_GB,
			dfsu.allocated_extent_page_count * 8 / 1024 / 1024. as used_data_file_size_in_GB,
			dfsu.unallocated_extent_page_count * 8 / 1024 / 1024. as unused_data_file_size_in_GB,
			dfsu.total_page_count * 8 / 1024 / 1024 / 1024. as total_data_file_size_in_TB,
			dfsu.allocated_extent_page_count * 8 / 1024 / 1024 / 1024. as used_data_file_size_in_TB,
			dfsu.unallocated_extent_page_count * 8 / 1024 / 1024 / 1024. as unused_data_file_size_in_TB
from		sys.dm_db_file_space_usage dfsu with (nolock)
inner join	sys.database_files df with (nolock)
	on		dfsu.[filegroup_id] = df.data_space_id
	and		dfsu.[file_id] = df.[file_id]

--

select		df.file_id, db_name(dovs.database_id) as database_name, dovs.file_id, df.name as logical_name, df.physical_name, dovs.logical_volume_name, dovs.volume_mount_point ,dovs.total_bytes / 1024 / 1024 / 1024. as total_size_in_GB, dovs.total_bytes / 1024 / 1024 / 1024. - dovs.available_bytes / 1024 / 1024 / 1024. as used_size_in_GB, dovs.available_bytes / 1024 / 1024 / 1024. as available_size_in_GB
from		sys.database_files df
cross apply	sys.dm_os_volume_stats(db_id(),df.file_id) dovs

select		df.file_id, db_name(dovs.database_id) as database_name, dovs.file_id, df.name as logical_name, df.physical_name, dovs.logical_volume_name, dovs.volume_mount_point, dovs.total_bytes / 1024 / 1024. as total_size_in_MB, dovs.total_bytes / 1024 / 1024 / 1024. as total_size_in_GB, dovs.total_bytes / 1024 / 1024. - dovs.available_bytes / 1024 / 1024. as used_size_in_MB, dovs.total_bytes / 1024 / 1024 / 1024. - dovs.available_bytes / 1024 / 1024 / 1024. as used_size_in_GB, dovs.available_bytes / 1024 / 1024. as available_size_in_MB, dovs.available_bytes / 1024 / 1024 / 1024. as available_size_in_GB
from		sys.database_files df
cross apply	sys.dm_os_volume_stats(db_id(),df.file_id) dovs

--
select	db_name() as database_name,
		df.[name] as log_file_name,
		df.physical_name,
		df.[file_id],
		df.data_space_id,
		df.size * 8 / 1024. as total_log_file_size_in_MB,
		df.size * 8 / 1024 / 1024. as total_log_file_size_in_GB
from	sys.database_files df with (nolock)
where	type = 1

select 	db_name() as database_name,
		total_log_size_in_bytes / 1024 / 1024. as total_log_size_in_MB,
		used_log_space_in_bytes / 1024 / 1024. as used_log_space_in_MB,
		(total_log_size_in_bytes - used_log_space_in_bytes) / 1024 / 1024. as unused_log_space_in_MB,
		total_log_size_in_bytes / 1024 / 1024 / 1024. as total_log_size_in_GB,
		used_log_space_in_bytes / 1024 / 1024 / 1024. as used_log_space_in_GB,
		(total_log_size_in_bytes - used_log_space_in_bytes) / 1024 / 1024 / 1024. as unused_log_space_in_GB,
		used_log_space_in_percent,
		(100 - used_log_space_in_percent) as unused_log_space_in_percent
from	sys.dm_db_log_space_usage with (nolock)

--

select		@@servername as instance,
			db_name(dfsu.database_id) as [database_name],
			dovs.volume_mount_point as mount,
			dovs.logical_volume_name as volume,
			mf.file_id,
			mf.physical_name,
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
group by	db_name(dfsu.database_id), mf.file_id, mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, dovs.total_bytes / 1024 / 1024., dovs.available_bytes / 1024 / 1024., dovs.total_bytes / 1024 / 1024 / 1024., dovs.available_bytes / 1024 / 1024 / 1024.
union
select		@@servername as instance,
			db_name(dfsu.database_id) as [database_name],
			dovs.volume_mount_point as mount,
			dovs.logical_volume_name as volume,
			mf.file_id,
			mf.physical_name,
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
group by	db_name(dfsu.database_id), mf.file_id, mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, dovs.total_bytes /1024 /1024., dovs.available_bytes /1024 /1024., dovs.total_bytes / 1024 / 1024 / 1024., dovs.available_bytes / 1024 / 1024 / 1024. 
order by	physical_name

--select		convert(varchar,getdate(),103) as [date],
--			@@servername as instance,
--			db_name(dfsu.database_id) as [database_name],
--			dovs.volume_mount_point as mount,
--			dovs.logical_volume_name as volume,
--			mf.physical_name,
--			sum((dfsu.total_page_count)*1.0/128) as total_file_size_in_MB,
--			sum((dfsu.allocated_extent_page_count)*1.0/128 ) as file_size_used_in_MB,
--			sum(dfsu.unallocated_extent_page_count)*1.0/128 as file_size_unused_in_MB,
--			cast(cast(dovs.total_bytes as decimal(19,2))/1024 /1024  as decimal (10,2)) as total_disk_size_in_MB,
--			cast(cast(dovs.available_bytes as decimal(19,2))/1024 /1024  as decimal (10,2)) as free_space_in_MB
--from		sys.dm_db_file_space_usage dfsu with (nolock)
--inner join	sys.master_files mf with (nolock) 
--	on		dfsu.file_id=mf.file_id 
--	and		dfsu.database_id=mf.database_id
--cross apply sys.dm_os_volume_stats (mf.database_id, mf.file_id) as dovs
--group by	db_name(dfsu.database_id), mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, cast(cast(dovs.total_bytes as decimal(19,2))/1024 /1024  as decimal (10,2)), cast(cast(dovs.available_bytes as decimal(19,2))/1024 /1024 as decimal (10,2))
--union
--select		convert(varchar,getdate(),103) as [date],
--			@@servername as instance,
--			db_name(dfsu.database_id) as [database_name],
--			dovs.volume_mount_point as mount,
--			dovs.logical_volume_name as volume,
--			mf.physical_name,
--			sum(dfsu.total_log_size_in_bytes) / 1024 / 1024. as total_file_size_in_MB,
--			sum(dfsu.used_log_space_in_bytes) / 1024 / 1024. as file_size_used_in_MB,
--			sum(dfsu.total_log_size_in_bytes - dfsu.used_log_space_in_bytes) / 1024 / 1024. as file_size_unused_in_MB,
--			cast(cast(dovs.total_bytes as decimal(19,2))/1024 /1024  as decimal (10,2)) as total_disk_size_in_MB,
--			cast(cast(dovs.available_bytes as decimal(19,2))/1024 /1024  as decimal (10,2)) as free_space_in_MB
--from		sys.dm_db_log_space_usage dfsu with (nolock)
--inner join	sys.master_files mf with (nolock) 
--	on		dfsu.database_id=mf.database_id
--	and		mf.type = 1
--cross apply sys.dm_os_volume_stats (mf.database_id, mf.file_id) as dovs
--group by	db_name(dfsu.database_id), mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, cast(cast(dovs.total_bytes as decimal(19,2))/1024 /1024  as decimal (10,2)), cast(cast(dovs.available_bytes as decimal(19,2))/1024 /1024 as decimal (10,2))
--order by	volume

--###############################################################################################################################################################################################################################
--stats
--###############################################################################################################################################################################################################################

--estatisticas acumuladas
;WITH [Waits] AS
    (
		SELECT
				[wait_type],
				[wait_time_ms] / 1000.0 AS [wait_time_s],
				([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [resource_s],
				[signal_wait_time_ms] / 1000.0 AS [signal_s],
				[waiting_tasks_count],
				100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
				ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
		FROM	sys.dm_os_wait_stats
		WHERE	[wait_type] NOT IN (N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
									N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
									N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
									N'CHKPT', N'CLR_AUTO_EVENT',
									N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
 
									-- Maybe uncomment these four if you have mirroring issues
									N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
									N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
 
									N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
									N'EXECSYNC', N'FSAGENT',
									N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
 
									-- Maybe uncomment these six if you have AG issues
									N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
									N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
									N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
 
									N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
									N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
									N'ONDEMAND_TASK_QUEUE',
									N'PREEMPTIVE_XE_GETTARGETSTATE',
									N'PWAIT_ALL_COMPONENTS_INITIALIZED',
									N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
									N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
									N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
									N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
									N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
									N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
									N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
									N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
									N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
									N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
									N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
									N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
									N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
									N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
									N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
									N'WAIT_XTP_RECOVERY',
									N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
									N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
									N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
		AND		[waiting_tasks_count] > 0
    )
SELECT
			MAX ([W1].[wait_type]) AS [wait_type],
			CAST (MAX ([W1].[wait_time_s]) AS DECIMAL (16,2)) AS [wait_time_s],
			CAST (MAX ([W1].[resource_s]) AS DECIMAL (16,2)) AS [resource_s],
			CAST (MAX ([W1].[signal_s]) AS DECIMAL (16,2)) AS [signal_s],
			MAX ([W1].[waiting_tasks_count]) AS [waiting_tasks_count],
			CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [percentage],
			CAST ((MAX ([W1].[wait_time_s]) / MAX ([W1].[waiting_tasks_count])) AS DECIMAL (16,4)) AS [avg_wait_time_s],
			CAST ((MAX ([W1].[resource_s]) / MAX ([W1].[waiting_tasks_count])) AS DECIMAL (16,4)) AS [avg_resource_s],
			CAST ((MAX ([W1].[signal_s]) / MAX ([W1].[waiting_tasks_count])) AS DECIMAL (16,4)) AS [avg_signal_s],
			CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
FROM		[Waits] AS [W1]
INNER JOIN	[Waits] AS [W2]
    ON		[W2].[RowNum] <= [W1].[RowNum]
GROUP BY	[W1].[RowNum]
HAVING		SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold
GO

--difference

if object_id('tempdb..#temp1') is not null
	drop table #temp1;

if object_id('tempdb..#temp2') is not null
	drop table #temp2;

SELECT
		[wait_type],
		[wait_time_ms] / 1000.0 AS [wait_time_s],
		([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [resource_s],
		[signal_wait_time_ms] / 1000.0 AS [signal_s],
		[waiting_tasks_count],
		100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage]
into	#temp1
FROM	sys.dm_os_wait_stats
WHERE	[wait_type] NOT IN (N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
							N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
							N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
							N'CHKPT', N'CLR_AUTO_EVENT',
							N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
 
							-- Maybe uncomment these four if you have mirroring issues
							N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
							N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
 
							N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
							N'EXECSYNC', N'FSAGENT',
							N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
 
							-- Maybe uncomment these six if you have AG issues
							N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
							N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
							N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
 
							N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
							N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
							N'ONDEMAND_TASK_QUEUE',
							N'PREEMPTIVE_XE_GETTARGETSTATE',
							N'PWAIT_ALL_COMPONENTS_INITIALIZED',
							N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
							N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
							N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
							N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
							N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
							N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
							N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
							N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
							N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
							N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
							N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
							N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
							N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
							N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
							N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
							N'WAIT_XTP_RECOVERY',
							N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
							N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
							N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
AND		[waiting_tasks_count] > 0
go

waitfor delay '00:00:30';
go

SELECT
		[wait_type],
		[wait_time_ms] / 1000.0 AS [wait_time_s],
		([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [resource_s],
		[signal_wait_time_ms] / 1000.0 AS [signal_s],
		[waiting_tasks_count],
		100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage]
into	#temp2
FROM	sys.dm_os_wait_stats
WHERE	[wait_type] NOT IN (N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
							N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
							N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
							N'CHKPT', N'CLR_AUTO_EVENT',
							N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
 
							-- Maybe uncomment these four if you have mirroring issues
							N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
							N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
 
							N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
							N'EXECSYNC', N'FSAGENT',
							N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
 
							-- Maybe uncomment these six if you have AG issues
							N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
							N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
							N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
 
							N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
							N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
							N'ONDEMAND_TASK_QUEUE',
							N'PREEMPTIVE_XE_GETTARGETSTATE',
							N'PWAIT_ALL_COMPONENTS_INITIALIZED',
							N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
							N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
							N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
							N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
							N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
							N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
							N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
							N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
							N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
							N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
							N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
							N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
							N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
							N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
							N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
							N'WAIT_XTP_RECOVERY',
							N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
							N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
							N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
AND		[waiting_tasks_count] > 0
go


with diff_waits as
(
	-- waits that weren't in the first snapshot
	select
		        t2.wait_type, t2.wait_time_s, t2.resource_s, t2.signal_s, t2.waiting_tasks_count
    from		#temp2 as t2
    left join	#temp1 as t1
        on		t2.wait_type = t1.wait_type
    where		t1.wait_type is null
	union
	-- diff of waits in both snapshots
	select
				t2.wait_type, t2.wait_time_s - t1.wait_time_s as wait_time_s, t2.resource_s - t1.resource_s as resource_s, t2.signal_s - t1.signal_s as signal_s, t2.waiting_tasks_count - t1.waiting_tasks_count as waiting_tasks_count
    from		#temp2 as t2
    left join	#temp1 as t1
        on		t2.wait_type = t1.wait_type
    where		t1.wait_type is not null
)
select		wait_type, wait_time_s, resource_s, signal_s, waiting_tasks_count
			,100.0 * (wait_time_s) / SUM (wait_time_s) OVER() AS [Percentage]
from		diff_waits as w
where		w.waiting_tasks_count > 0
order by	w.wait_time_s desc
go

if object_id('tempdb..#temp1') is not null
	drop table #temp1;

if object_id('tempdb..#temp2') is not null
	drop table #temp2;

--###############################################################################################################################################################################################################################
--DIVERSOS
--###############################################################################################################################################################################################################################

--is_read_only
select DatabasePropertyEx('BDTPEDI','Updateability')

--table x file
select		t.object_id, t.name as object_name, t.type_desc, case when i.index_id = 0 then 'Heap Table' else i.name end as index_name, p.rows, f.name as filegroup_name, df.name as file_name, df.physical_name, df.size, au.total_pages, au.used_pages, au.data_pages
from		sys.tables t with (nolock)
inner join	sys.partitions p with (nolock)
	on		t.object_id = p.object_id
inner join	sys.indexes i with (nolock)
	on		p.object_id = i.object_id
	and		p.index_id = i.index_id
inner join	sys.allocation_units au with (nolock)
	on		p.partition_id = au.container_id
inner join	sys.filegroups f with (nolock)
	on		au.data_space_id = f.data_space_id 
inner join	sys.database_files df
	on		f.data_space_id = df.data_space_id
where		1 = 1
	and		t.object_id = object_id('cicsTransactions')

--###############################################################################################################################################################################################################################
--verificar fragmentação índice parametrizado
--###############################################################################################################################################################################################################################

use master
go
declare @db_name varchar(32) = 'BDTGTC'
declare @schema_name varchar(32) = 'dbo'
declare @table_name varchar(32) = 'TBGTR_CHAMADO'
declare @index_name varchar(64) = 'XPK_TBGTR_CHAMADO'
declare @object_id varchar(64) 
declare @index_id int
declare @sql nvarchar(1000) 
declare @param nvarchar(1000)

select @object_id = '' + @db_name + '.' + @schema_name + '.' + @table_name

select @sql = N'select @index_id_out = index_id from ' + @db_name + '.sys.indexes where name = @indexname'

select @param = N'@indexname varchar(64), @index_id_out int output'

exec sp_executesql @sql, @param, @indexname = @index_name, @index_id_out=@index_id output

--database_id, object_id, index_id, partition_number, mode
select @sql =   'select		b.name,a.avg_fragmentation_in_percent,a.*
			    from		sys.dm_db_index_physical_stats(db_id(''' + @db_name + '''),object_id(''' + @object_id + '''),' + cast(@index_id as varchar(10)) + ',null,null) a
				join		' + @db_name + '.sys.indexes b 
					on		a.object_id = b.object_id 
					and		a.index_id = b.index_id
					and		a.page_count > 20
					and		a.index_id > 0	
				order by	object_name(b.object_id), b.index_id'
exec sp_executesql @sql


