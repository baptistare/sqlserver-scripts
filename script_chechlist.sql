set nocount on;

select '########################################################################################################################################################################################################
# INFORMACOES SOBRE A INSTANCIA 
########################################################################################################################################################################################################'

select	@@SERVERNAME as InstanceName
	      ,(select sqlserver_start_time from sys.dm_os_sys_info) as sqlserver_start_time
		  ,(select role_desc from sys.dm_hadr_availability_replica_states where is_local = 1) as Alwayson
		  ,SERVERPROPERTY('productversion') RTM
		  ,case SUBSTRING (cast(SERVERPROPERTY('productversion') as varchar(20)),1,4 )
			  when '6.00' then 'SQL Server 6.0'
			  when '6.50' then 'SQL Server 6.5'
			  when '7.0.' then 'SQL Server 7.0'
			  when '8.0.' then 'SQL Server 2000'
			  when '9.0.' then 'SQL Server 2005'
			  when '10.0' then 'SQL Server 2008'
			  when '10.5' then 'SQL Server 2008 R2'
			  when '11.0' then 'SQL Server 2012'
			  when '12.0' then 'SQL Server 2014'
			  when '13.0' then 'SQL Server 2016'
			  when '14.0' then 'SQL Server 2017'
		  end as VERSION
		  ,SERVERPROPERTY ('productlevel') Service_Pack
		  ,SERVERPROPERTY('ProductUpdateLevel') AS ProductUpdateLevel
		  ,SERVERPROPERTY ('edition') Edition; 

select '
########################################################################################################################################################################################################
#CONFIGURACOES INSTANCIA
########################################################################################################################################################################################################
'

select	name, value, description, is_dynamic, is_advanced
          from	    sys.configurations with (nolock)
          where	    configuration_id in (101,103,117,503,542,1535,1538,1539,1540,1541,1543,1544,1550,1568,1569,1576,1579,1581,16390);

select '
########################################################################################################################################################################################################
# INFORMACOES SOBRE ALWAYSON
########################################################################################################################################################################################################
'

select		ar.replica_server_name, 
			        ag.name AS ag_name, 
			        adc.database_name, 
			        drs.is_primary_replica, 
			        drs.synchronization_state_desc, 
			        drs.synchronization_health_desc, 
			        getdate() as [current_time],
			        drs.last_commit_time,
			        right('00' + cast(datediff(s,drs.last_commit_time,getdate()) / 60 / 60 as varchar(2)),2) + ':' + right('00' + cast(datediff(s,drs.last_commit_time,getdate()) / 60 % 60 as varchar(2)),2) + ':' + right('00' + cast(datediff(s,drs.last_commit_time,getdate()) % 60 as varchar(2)),2) as lag, --time_behind_primary,
			        drs.log_send_queue_size, 
			        drs.log_send_rate, 
			        drs.redo_queue_size, 
			        drs.redo_rate,
			        dateadd(mi,(drs.redo_queue_size/redo_rate/60.0),getdate()) as estimated_completion_time,
			        cast((drs.redo_queue_size/drs.redo_rate/60.0) as decimal(10,2)) as estimated_recovery_time_minutes,
			        (drs.redo_queue_size/drs.redo_rate) as estimated_recovery_time_seconds
        from		sys.dm_hadr_database_replica_states AS drs with (nolock)
        inner join	sys.availability_databases_cluster AS adc with (nolock)
	        on		drs.group_id = adc.group_id 
	        and 	drs.group_database_id = adc.group_database_id
        inner join	sys.availability_groups AS ag with (nolock)
	        on		ag.group_id = drs.group_id
        inner join	sys.availability_replicas AS ar with (nolock)
	        on		drs.group_id = ar.group_id 
	        and		drs.replica_id = ar.replica_id
        order by	ag.name, ar.replica_server_name, adc.database_name;

select '
########################################################################################################################################################################################################
# INFORMACOES SOBRE OS PROCESSOS EM EXECUÇÃO
########################################################################################################################################################################################################
'

  select		
			            des.session_id, der.blocking_session_id, db_name(der.database_id) as database_name, des.login_name, des.host_name, der.start_time, der.status, der.wait_resource, der.wait_time, der.wait_type, der.last_wait_type, des.program_name, dec.client_net_address,
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
			            der.percent_complete
            from		sys.dm_exec_sessions des with (nolock)
            inner join	sys.dm_exec_requests der with (nolock)
	            on		des.session_id = der.session_id
            inner join	sys.dm_exec_connections dec with (nolock)
	            on		des.session_id = dec.session_id
            cross apply sys.dm_exec_sql_text (der.sql_handle) dest 
            cross apply sys.dm_exec_query_plan (der.plan_handle) deqp  
            where       des.session_id <> @@SPID 
            order by	der.start_time;

select '
########################################################################################################################################################################################################
# INFORMACOES SOBRE TOP 10 QUERIES POR TEMPO DE EXECUCOES
########################################################################################################################################################################################################
'

SELECT TOP 10 SUBSTRING(qt.TEXT, (qs.statement_start_offset/2)+1,
((CASE qs.statement_end_offset
WHEN -1 THEN DATALENGTH(qt.TEXT)
ELSE qs.statement_end_offset
END - qs.statement_start_offset)/2)+1) as CMD,
qs.execution_count,
qs.total_logical_reads, qs.last_logical_reads,
qs.total_logical_writes, qs.last_logical_writes,
qs.total_worker_time,
qs.last_worker_time,
qs.total_elapsed_time/1000000 total_elapsed_time_in_S,
qs.last_elapsed_time/1000000 last_elapsed_time_in_S,
qs.last_execution_time,
qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
ORDER BY qs.last_elapsed_time DESC;

select '
########################################################################################################################################################################################################
# INFORMACOES SOBRE SESSÕES ABERTAS
########################################################################################################################################################################################################
'

Select top 20 db_name(database_id) as dbname,login_name,status,count(1) qtde 
from sys.dm_exec_sessions with (nolock) where session_id > 54
group by db_name(database_id),login_name,status
order by 1,2,3,4 ;

select '
########################################################################################################################################################################################################
# INFORMACOES CPU
########################################################################################################################################################################################################
'

select	cpu_count as cpu_logical, hyperthread_ratio, cpu_count / hyperthread_ratio as cpu_physical, os_quantum, max_workers_count, scheduler_count, affinity_type, affinity_type_desc  
          from      sys.dm_os_sys_info with (nolock);

select '
########################################################################################################################################################################################################
# INFORMACOES HISTÓRICO CPU (30min)
########################################################################################################################################################################################################
'

declare @ts_now bigint = (select cpu_ticks/(cpu_ticks/ms_ticks) from sys.dm_os_sys_info); 
        select	top(30) sqlprocessutilization as sql_server_process_cpu_utilization, systemidle as system_idle_process, 100 - systemidle - sqlprocessutilization as other_process_cpu_utilization, dateadd(ms, -1 * (@ts_now - timestamp), getdate()) as event_time
        from 
        ( 
	        select	record.value('(./Record/@id)[1]', 'int') as record_id, 
			        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as systemidle, 
			        record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as sqlprocessutilization, timestamp 
	        from	
	        ( 
		        select	timestamp, convert(xml, record) as record 
		        from	sys.dm_os_ring_buffers with (nolock)
		        where	ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			        and record like N'%<SystemHealth>%'
	        ) as x 
        ) as y 
        order by record_id desc;

select '
########################################################################################################################################################################################################
# INFORMACOES ESPERAS CPU
########################################################################################################################################################################################################
'

select  cast(100.0 * sum(signal_wait_time_ms) / sum(wait_time_ms) as numeric(20,2)) as percent_signal_cpu_waits ,
                cast(100.0 * sum(wait_time_ms - signal_wait_time_ms) / sum(wait_time_ms) as numeric(20, 2)) as percent_resource_waits
        from    sys.dm_os_wait_stats with (nolock);


select '
########################################################################################################################################################################################################
# INFORMACOES SCHEDULERS, TASKS, WORKERS
########################################################################################################################################################################################################
'

select  is_idle, current_tasks_count, runnable_tasks_count, current_workers_count,active_workers_count, work_queue_count, pending_disk_io_count, load_factor
        from    sys.dm_os_schedulers with (nolock)
        where   scheduler_id < 255
        and     status = 'VISIBLE ONLINE';

select '
########################################################################################################################################################################################################
# INFORMACOES MEMORIA
########################################################################################################################################################################################################
'

select	total_physical_memory_kb / 1024 / 1024.  as total_physical_memory_gb, 
		            available_physical_memory_kb / 1024 / 1024. as available_physical_memory_gb, 
		            (total_page_file_kb - total_physical_memory_kb) / 1024 / 1024. as total_page_file,
		            total_page_file_kb / 1024 / 1024. as total_virtual_memory_in_gb, 
		            available_page_file_kb / 1024 / 1024. as available_virtual_memory_in_gb , 
		            system_memory_state_desc 
         from	    sys.dm_os_sys_memory with (nolock);

select '
########################################################################################################################################################################################################
# INFORMACOES TAMANHO BUFFER CACHE
########################################################################################################################################################################################################
'

select	count(*) as buffer_cache_pages,
		        count(*) * 8 / 1024. as buffer_cache_used_mb,
		        count(*) * 8 / 1024 / 1024. as buffer_cache_used_gb
        from	sys.dm_os_buffer_descriptors with (nolock);

select '
########################################################################################################################################################################################################
# INFORMACOES TAMANHO BUFFER CACHE POR BASE DE DADOS
########################################################################################################################################################################################################
'

select		databases.name as database_name,
			        count(*) * 8 / 1024. as mb_used,
			        count(*) * 8 / 1024 / 1024. as gb_used
        from		sys.dm_os_buffer_descriptors with (nolock)
        inner join	sys.databases with (nolock)
	        on		databases.database_id = dm_os_buffer_descriptors.database_id
        group by	databases.name
        order by	count(*) desc;

select '
########################################################################################################################################################################################################
# INFORMACOES SOBRE OS DISCOS (SIZE)
########################################################################################################################################################################################################
'

SELECT distinct
    substring(A.physical_name,1,3) Drives,
    CAST(C.total_bytes / 1073741824.0 AS NUMERIC(18, 2)) AS disk_total_size_GB,
    CAST(C.available_bytes / 1073741824.0 AS NUMERIC(18, 2)) AS disk_free_size_GB,
	cast(((CAST(C.available_bytes / 1073741824.0 AS NUMERIC(18, 2)) *100)/
	(CAST(C.total_bytes / 1073741824.0 AS NUMERIC(18, 2)))) as numeric(18,2)) AS disk_free_percent
FROM
    sys.master_files        A   WITH(NOLOCK)
    CROSS APPLY sys.dm_os_volume_stats(A.database_id, A.[file_id]) C

select '
########################################################################################################################################################################################################
# INFORMACOES ESTATISTICAS DISCO - HISTORICO
########################################################################################################################################################################################################
'

select		db_name(vfs.database_id) as database_name, io_stall_read_ms ,
			        num_of_reads ,
			        cast(io_stall_read_ms / ( 1.0 + num_of_reads ) as numeric(10, 1)) as avg_read_stall_ms , 
			        io_stall_write_ms ,
			        num_of_writes ,
			        cast(io_stall_write_ms / ( 1.0 + num_of_writes ) as numeric(10, 1)) as avg_write_stall_ms ,
			        io_stall_read_ms + io_stall_write_ms as io_stalls ,
			        num_of_reads + num_of_writes as total_io ,
			        cast(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads + num_of_writes) as numeric(10,1)) as avg_io_stall_ms,
			        mf.physical_name
        from		sys.dm_io_virtual_file_stats(null, null) vfs
        inner join	sys.master_files as mf with (nolock)
            on		vfs.database_id = mf.database_id
            and		vfs.file_id = mf.file_id
        order by	avg_read_stall_ms desc;

select '
########################################################################################################################################################################################################
# INFORMACOES ESTATISTICAS DISCO - (30s)
########################################################################################################################################################################################################
'

if object_id('tempdb..#temp1') is not null
	        drop table #temp1;

        if object_id('tempdb..#temp2') is not null
	        drop table #temp2;

        select  database_id, file_id, io_stall_read_ms, num_of_reads, io_stall_write_ms, num_of_writes, io_stall, num_of_bytes_read, num_of_bytes_written, file_handle
        into	#temp1
        from	sys.dm_io_virtual_file_stats (null, null)

        waitfor delay '00:00:30';
 
        select  database_id, file_id, io_stall_read_ms, num_of_reads, io_stall_write_ms, num_of_writes, io_stall, num_of_bytes_read, num_of_bytes_written, file_handle
        into	#temp2
        from	sys.dm_io_virtual_file_stats (null, null)
 
        ;with diff_latencies as
        (
	        select
		                t2.database_id, t2.file_id, t2.num_of_reads, t2.io_stall_read_ms, t2.num_of_writes, t2.io_stall_write_ms, t2.io_stall, t2.num_of_bytes_read, t2.num_of_bytes_written
            from		#temp2 as t2
            left join	#temp1 as t1
                on		t2.file_handle = t1.file_handle
            where		t1.file_handle is null
	        union
	        select
				        t2.database_id, t2.file_id, t2.num_of_reads - t1.num_of_reads as num_of_reads, t2.io_stall_read_ms - t1.io_stall_read_ms as io_stall_read_ms, t2.num_of_writes - t1.num_of_writes as num_of_writes, t2.io_stall_write_ms - t1.io_stall_write_ms as io_stall_write_ms, t2.io_stall - t1.io_stall as io_stall, t2.num_of_bytes_read - t1.num_of_bytes_read as num_of_bytes_read, t2.num_of_bytes_written - t1.num_of_bytes_written as num_of_bytes_written
            from		#temp2 as t2
            left join	#temp1 as t1
                on		t2.file_handle = t1.file_handle
            where		t1.file_handle is not null
        )
        select
			        db_name (vfs.database_id) as database_name,
			        io_stall_read_ms,
			        num_of_reads,
			        cast(io_stall_read_ms / ( 1.0 + num_of_reads ) as numeric(10, 1)) as avg_read_stall_ms ,
			        io_stall_write_ms,
			        num_of_writes,
			        cast(io_stall_write_ms / ( 1.0 + num_of_writes ) as numeric(10, 1)) as avg_write_stall_ms ,
			        io_stall_read_ms + io_stall_write_ms as io_stalls ,
			        num_of_reads + num_of_writes as total_io ,
			        cast(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads + num_of_writes) as numeric(10,1)) as avg_io_stall_ms,
			        mf.physical_name
        from		diff_latencies as vfs
        inner join	sys.master_files as mf with (nolock)
            on		vfs.database_id = mf.database_id
            and		vfs.file_id = mf.file_id
        order by	avg_read_stall_ms desc

        if object_id('tempdb..#temp1') is not null
	        drop table #temp1;

        if object_id('tempdb..#temp2') is not null
	        drop table #temp2;


select '
########################################################################################################################################################################################################
# INFORMACOES WAITS
########################################################################################################################################################################################################
'

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
		FROM	sys.dm_os_wait_stats with (nolock)
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
			CAST ((MAX ([W1].[signal_s]) / MAX ([W1].[waiting_tasks_count])) AS DECIMAL (16,4)) AS [avg_signal_s]
FROM		[Waits] AS [W1]
INNER JOIN	[Waits] AS [W2]
    ON		[W2].[RowNum] <= [W1].[RowNum]
GROUP BY	[W1].[RowNum]
HAVING		SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95;

select '
########################################################################################################################################################################################################
# INFORMACOES WAITS (30s)
########################################################################################################################################################################################################
'

if object_id('tempdb..#temp1') is not null
	drop table #temp1_w;

if object_id('tempdb..#temp2') is not null
	drop table #temp2_w;

SELECT
		[wait_type],
		[wait_time_ms] / 1000.0 AS [wait_time_s],
		([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [resource_s],
		[signal_wait_time_ms] / 1000.0 AS [signal_s],
		[waiting_tasks_count],
		100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage]
into	#temp1_w
FROM	sys.dm_os_wait_stats with (nolock)
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

waitfor delay '00:00:30';

SELECT
		[wait_type],
		[wait_time_ms] / 1000.0 AS [wait_time_s],
		([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [resource_s],
		[signal_wait_time_ms] / 1000.0 AS [signal_s],
		[waiting_tasks_count],
		100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage]
into	#temp2_w
FROM	sys.dm_os_wait_stats with (nolock)
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

;with diff_waits as
(
	-- waits that weren't in the first snapshot
	select
		        t2.wait_type, t2.wait_time_s, t2.resource_s, t2.signal_s, t2.waiting_tasks_count
    from		#temp2_w as t2
    left join	#temp1_w as t1
        on		t2.wait_type = t1.wait_type
    where		t1.wait_type is null
	union
	-- diff of waits in both snapshots
	select
				t2.wait_type, t2.wait_time_s - t1.wait_time_s as wait_time_s, t2.resource_s - t1.resource_s as resource_s, t2.signal_s - t1.signal_s as signal_s, t2.waiting_tasks_count - t1.waiting_tasks_count as waiting_tasks_count
    from		#temp2_w as t2
    left join	#temp1_w as t1
        on		t2.wait_type = t1.wait_type
    where		t1.wait_type is not null
)
select		wait_type, wait_time_s, resource_s, signal_s, waiting_tasks_count
			,100.0 * (wait_time_s) / SUM (wait_time_s) OVER() AS [Percentage]
from		diff_waits as w
where		w.waiting_tasks_count > 0
order by	w.wait_time_s desc

if object_id('tempdb..#temp1') is not null
	drop table #temp1_w;

if object_id('tempdb..#temp2') is not null
	drop table #temp2_w;

select '
########################################################################################################################################################################################################
# INFORMACOES CURRENT WAITS
########################################################################################################################################################################################################
'

SELECT db_name(database_id) dbname, 
wait_type,count(1) as qtde
from sys.dm_exec_requests with (nolock) where session_id>50
group by db_name(database_id),wait_type
order by 1,2 asc,3 desc;

select '
########################################################################################################################################################################################################
# INFORMACOES SOBRE OS BANCOS DE DADOS DE USUARIOS
########################################################################################################################################################################################################
'

select		d.database_id as database_id,
			            d.[name] as database_name,
			            mf.state_desc,
			            d.user_access_desc,
			            databasepropertyex(db_name(d.database_id),'Updateability') as mode,
			            d.recovery_model_desc,
			            d.log_reuse_wait_desc,
			            mf.[type_desc],
			            mf.physical_name,
			            cast(mf.size / 128 as numeric(18, 2)) as size_db_mb,
			            cast(mf.max_size / 128 as numeric(18, 2)) as max_size_db_mb,
			            (case when mf.is_percent_growth = 1 then mf.growth else cast(mf.growth / 128 as numeric(18, 2)) end) as growth_mb,
			            mf.is_percent_growth,
			            (case when mf.growth <= 0 then 0 else 1 end) as is_autogrowth_enabled,
			            d.compatibility_level,
			            d.page_verify_option_desc,
			            d.is_auto_close_on,
			            d.is_auto_shrink_on,
			            d.is_auto_create_stats_on,
			            d.is_auto_update_stats_on,
			            d.is_auto_update_stats_async_on
            from		sys.master_files mf with (nolock)
            inner join	sys.databases d with (nolock)    
	            on		mf.database_id = d.database_id
            cross apply	sys.dm_os_volume_stats(mf.database_id, mf.[file_id]) dovs
            where		d.[name] not in ('master','tempdb','model','msdb','distribution') 
            order by	database_name;

select '
########################################################################################################################################################################################################
# INFORMACOES ULTIMOS BACKUPS REALIZADOS (3)
########################################################################################################################################################################################################
'

; with bkp as
(
	select	database_name, type, user_name, backup_start_date, backup_finish_date, rank() over (partition by database_name, type order by backup_start_date desc) as rnk
	from	msdb..backupset with (nolock)
	where	database_name not in ( 'master','msdb','tempdb','model','distribution')
) 
select	database_name, type, user_name, backup_start_date, backup_finish_date, datediff(ss,bkp.backup_start_date, bkp.backup_finish_date) as diff_in_Sec, datediff(mi,bkp.backup_start_date, bkp.backup_finish_date) as diff_in_Min
from	bkp
where	rnk < 4

select '
########################################################################################################################################################################################################
# JOBS EM EXECUÇÃO
########################################################################################################################################################################################################
'

select		j.name as job_name, t.text as command_job, s.session_id
from		sys.dm_exec_sessions s with (nolock)
inner join	sys.dm_exec_requests r with (nolock)
	on		s.session_id = r.session_id
cross apply	sys.dm_exec_sql_text (r.sql_handle) t
inner join	msdb..sysjobsteps js with (nolock)
	on		substring(s.program_name,30,34) = convert(varchar(34), convert(varbinary(32), js.job_id), 1) 
inner join	msdb..sysjobs j with (nolock)
	on		js.job_id = j.job_id
where		s.program_name like 'SQLAgent%'
	and		js.step_id = 1;

select '
########################################################################################################################################################################################################
# ALOCAÇÕES TEMPDB
########################################################################################################################################################################################################
'

select 
		sum(unallocated_extent_page_count) as FreePages,
		sum(unallocated_extent_page_count) * 8 / 1024. as FreeSpaceMB,
		sum(version_store_reserved_page_count) as VersionStorePages ,
		sum(version_store_reserved_page_count)* 8 / 1024. as VersionStoreMB,
		sum(internal_object_reserved_page_count) as InternalObjectPages,
		sum(internal_object_reserved_page_count)* 8 / 1024. as InternalObjectsMB,
		sum(user_object_reserved_page_count) as UserObjectPages,
		sum(user_object_reserved_page_count)* 8 / 1024. as UserObjectsMB 
from	tempdb.sys.dm_db_file_space_usage with (nolock);
