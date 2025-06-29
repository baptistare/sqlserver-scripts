-- Script 1
-- Get a count of SQL connections by IP address
SELECT  ec.client_net_address ,
        es.[program_name] ,
        es.[host_name] ,
        es.login_name ,
        COUNT(ec.session_id) AS [connection count]
FROM    sys.dm_exec_sessions AS es
        INNER JOIN sys.dm_exec_connections AS ec
                                   ON es.session_id = ec.session_id
GROUP BY ec.client_net_address ,
        es.[program_name] ,
        es.[host_name] ,
        es.login_name
ORDER BY ec.client_net_address ,
        es.[program_name] ;


-- Script 2
--  Get SQL users that are connected and how many sessions they have 
SELECT  login_name ,
        COUNT(session_id) AS [session_count]
FROM    sys.dm_exec_sessions
GROUP BY login_name
ORDER BY COUNT(session_id) DESC ;


-- Script 3
-- Look at current expensive or blocked requests
SELECT  r.session_id ,
        r.[status] ,
        r.wait_type ,
        r.scheduler_id ,
        SUBSTRING(qt.[text], r.statement_start_offset / 2,
            ( CASE WHEN r.statement_end_offset = -1
                   THEN LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2
                   ELSE r.statement_end_offset
              END - r.statement_start_offset ) / 2) AS [statement_executing] ,
        DB_NAME(qt.[dbid]) AS [DatabaseName] ,
        OBJECT_NAME(qt.objectid) AS [ObjectName] ,
        r.cpu_time ,
        r.total_elapsed_time ,
        r.reads ,
        r.writes ,
        r.logical_reads ,
        r.plan_handle
FROM    sys.dm_exec_requests AS r
        CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS qt
WHERE   r.session_id > 50
ORDER BY r.scheduler_id ,
        r.[status] ,
        r.session_id ;

-- Script 4        
-- Top 3 CPU-sapping queries for which plans exist in the cache        
SELECT TOP 3
        total_worker_time ,
        execution_count ,
        total_worker_time / execution_count AS [Avg CPU Time] ,
        CASE WHEN deqs.statement_start_offset = 0
                  AND deqs.statement_end_offset = -1
             THEN '-- see objectText column--'
             ELSE '-- query --' + CHAR(13) + CHAR(10)
                  + SUBSTRING(execText.text, deqs.statement_start_offset / 2,
                              ( ( CASE WHEN deqs.statement_end_offset = -1
                                       THEN DATALENGTH(execText.text)
                                       ELSE deqs.statement_end_offset
                                  END ) - deqs.statement_start_offset ) / 2)
        END AS queryText
FROM    sys.dm_exec_query_stats deqs
        CROSS APPLY sys.dm_exec_sql_text(deqs.plan_handle) AS execText
ORDER BY deqs.total_worker_time DESC ;


-- Script 5
-- Use Counts and # of plans for compiled plans
SELECT  objtype ,
        usecounts ,
        COUNT(*) AS [no_of_plans]
FROM    sys.dm_exec_cached_plans
WHERE   cacheobjtype = 'Compiled Plan'
GROUP BY objtype ,
        usecounts
ORDER BY objtype ,
        usecounts ;
        
        
-- Script 6
SELECT  top (100)
		text,
		cp.size_in_bytes
FROM		sys.dm_exec_cached_plans as cp
cross apply	sys.dm_exec_sql_text (cp.plan_handle) 
WHERE		cp.cacheobjtype = 'Compiled Plan'
	and		cp.objtype = 'Adhoc'
	and		cp.usecounts = 1
ORDER BY	cp.size_in_bytes desc

		
objtype ,
        usecounts ,
        COUNT(*) AS [no_of_plans]


-- Script 7
-- Top Cached SPs By Total Logical Reads (SQL 2008 only).
-- Logical reads relate to memory pressure
SELECT TOP ( 25 )
        p.name AS [SP Name] ,
        qs.total_logical_reads AS [TotalLogicalReads] ,
        qs.total_logical_reads / qs.execution_count AS [AvgLogicalReads] ,
        qs.execution_count ,
        ISNULL(qs.execution_count / 
                 DATEDIFF(Second, qs.cached_time, GETDATE()),
               0) AS [Calls/Second] ,
        qs.total_elapsed_time ,
        qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time] ,
        qs.cached_time
FROM    sys.procedures AS p
        INNER JOIN sys.dm_exec_procedure_stats AS qs
                              ON p.[object_id] = qs.[object_id]
WHERE   qs.database_id = DB_ID()
ORDER BY qs.total_logical_reads DESC ;

-- Script 8
-- Top Cached SPs By Total Physical Reads (SQL 2008 only) 
-- Physical reads relate to disk I/O pressure
SELECT TOP ( 25 )
        p.name AS [SP Name] ,
        qs.total_physical_reads AS [TotalPhysicalReads] ,
        qs.total_physical_reads / qs.execution_count AS [AvgPhysicalReads] ,
        qs.execution_count ,
        ISNULL(qs.execution_count / 
                 DATEDIFF(Second, qs.cached_time, GETDATE()),
               0) AS [Calls/Second] ,
        qs.total_elapsed_time ,
        qs.total_elapsed_time / qs.execution_count AS [avg_elapsed_time] ,
        qs.cached_time
FROM    sys.procedures AS p
        INNER JOIN sys.dm_exec_procedure_stats AS qs
                              ON p.[object_id] = qs.[object_id]
WHERE   qs.database_id = DB_ID()
ORDER BY qs.total_physical_reads DESC ;


-- Script 9
-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2008 version
SELECT  DB_NAME(st.dbid) AS [DatabaseName] ,
        mg.requested_memory_kb ,
        mg.ideal_memory_kb ,
        mg.request_time ,
        mg.grant_time ,
        mg.query_cost ,
        mg.dop ,
        st.[text]
FROM    sys.dm_exec_query_memory_grants AS mg
        CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE   mg.request_time < COALESCE(grant_time, '99991231')
ORDER BY mg.requested_memory_kb DESC ;

-- Shows the memory required by both running (non-null grant_time) 
-- and waiting queries (null grant_time)
-- SQL Server 2005 version
SELECT  DB_NAME(st.dbid) AS [DatabaseName] ,
        mg.requested_memory_kb ,
        mg.request_time ,
        mg.grant_time ,
        mg.query_cost ,
        mg.dop ,
        st.[text]
FROM    sys.dm_exec_query_memory_grants AS mg
        CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st
WHERE   mg.request_time < COALESCE(grant_time, '99991231')
ORDER BY mg.requested_memory_kb DESC ;


-- Script 10
-- Monitoring transaction activity
SELECT  st.session_id ,
        DB_NAME(dt.database_id) AS database_name ,
        CASE WHEN dt.database_transaction_begin_time IS NULL THEN 'read-only'
             ELSE 'read-write'
        END AS transaction_state ,
        dt.database_transaction_begin_time AS read_write_start_time ,
        dt.database_transaction_log_record_count ,
        dt.database_transaction_log_bytes_used
FROM    sys.dm_tran_session_transactions AS st
        INNER JOIN sys.dm_tran_database_transactions AS dt
            ON st.transaction_id = dt.transaction_id
ORDER BY st.session_id ,
        database_name

-- Script 11
-- Look at active Lock Manager resources for current database
SELECT  request_session_id ,
        DB_NAME(resource_database_id) AS [Database] ,
        resource_type ,
        resource_subtype ,
        request_type ,
        request_mode ,
        resource_description ,
        request_mode ,
        request_owner_type
FROM    sys.dm_tran_locks
WHERE   request_session_id > 50
        AND resource_database_id = DB_ID()
        AND request_session_id <> @@SPID
ORDER BY request_session_id ;

-- Look for blocking
SELECT  tl.resource_type ,
        tl.resource_database_id ,
        tl.resource_associated_entity_id ,
        tl.request_mode ,
        tl.request_session_id ,
        wt.blocking_session_id ,
        wt.wait_type ,
        wt.wait_duration_ms
FROM    sys.dm_tran_locks AS tl
        INNER JOIN sys.dm_os_waiting_tasks AS wt
           ON tl.lock_owner_address = wt.resource_address
ORDER BY wait_duration_ms DESC ;


-- Script 12
-- Missing Indexes in current database by Index Advantage
SELECT  user_seeks * avg_total_user_cost * ( avg_user_impact * 0.01 )
                                                       AS [index_advantage] ,
        migs.last_user_seek ,
        mid.[statement] AS [Database.Schema.Table] ,
        mid.equality_columns ,
        mid.inequality_columns ,
        mid.included_columns ,
        migs.unique_compiles ,
        migs.user_seeks ,
        migs.avg_total_user_cost ,
        migs.avg_user_impact
FROM    sys.dm_db_missing_index_group_stats AS migs WITH ( NOLOCK )
        INNER JOIN sys.dm_db_missing_index_groups AS mig WITH ( NOLOCK )
           ON migs.group_handle = mig.index_group_handle
        INNER JOIN sys.dm_db_missing_index_details AS mid WITH ( NOLOCK )
           ON mig.index_handle = mid.index_handle
WHERE   mid.database_id = DB_ID()
ORDER BY index_advantage DESC ;


-- Script 13
--- Index Read/Write stats (all tables in current DB)
SELECT  OBJECT_NAME(s.[object_id]) AS [ObjectName] ,
        i.name AS [IndexName] ,
        i.index_id ,
        user_seeks + user_scans + user_lookups AS [Reads] ,
        user_updates AS [Writes] ,
        i.type_desc AS [IndexType] ,
        i.fill_factor AS [FillFactor]
FROM    sys.dm_db_index_usage_stats AS s
        INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND i.index_id = s.index_id
        AND s.database_id = DB_ID()
ORDER BY OBJECT_NAME(s.[object_id]) ,
        writes DESC ,
        reads DESC ;

-- Script 14
-- List unused indexes
SELECT  OBJECT_NAME(i.[object_id]) AS [Table Name] ,
        i.name
FROM    sys.indexes AS i
        INNER JOIN sys.objects AS o ON i.[object_id] = o.[object_id]
WHERE   i.index_id NOT IN ( SELECT  s.index_id
                            FROM    sys.dm_db_index_usage_stats AS s
                            WHERE   s.[object_id] = i.[object_id]
                                    AND i.index_id = s.index_id
                                    AND database_id = DB_ID() )
        AND o.[type] = 'U'
ORDER BY OBJECT_NAME(i.[object_id]) ASC ;

-- Script 15
-- Possible Bad NC Indexes (writes > reads)
SELECT  OBJECT_NAME(s.[object_id]) AS [Table Name] ,
        i.name AS [Index Name] ,
        i.index_id ,
        user_updates AS [Total Writes] ,
        user_seeks + user_scans + user_lookups AS [Total Reads] ,
        user_updates - ( user_seeks + user_scans + user_lookups )
            AS [Difference]
FROM    sys.dm_db_index_usage_stats AS s WITH ( NOLOCK )
        INNER JOIN sys.indexes AS i WITH ( NOLOCK )
            ON s.[object_id] = i.[object_id]
            AND i.index_id = s.index_id
WHERE   OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1
        AND s.database_id = DB_ID()
        AND user_updates > ( user_seeks + user_scans + user_lookups )
        AND i.index_id > 1
ORDER BY [Difference] DESC ,
        [Total Writes] DESC ,
        [Total Reads] ASC ;

-- Script 16
-- Table and row count information   
SELECT  OBJECT_NAME(ps.[object_id]) AS [TableName] ,
        i.name AS [IndexName] ,
        SUM(ps.row_count) AS [RowCount]
FROM    sys.dm_db_partition_stats AS ps
        INNER JOIN sys.indexes AS i ON i.[object_id] = ps.[object_id]
                                       AND i.index_id = ps.index_id
WHERE   i.type_desc IN ( 'CLUSTERED', 'HEAP' )
        AND i.[object_id] > 100
        AND OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys'
GROUP BY ps.[object_id] ,
        i.name
ORDER BY SUM(ps.row_count) DESC ;


-- Script 17
-- Get Free Space in TempDB
SELECT  SUM(unallocated_extent_page_count) AS [free pages] ,
        ( SUM(unallocated_extent_page_count) * 1.0 / 128 ) AS [free space in MB]
FROM    sys.dm_db_file_space_usage ;
      
-- Quick TempDB Summary
SELECT SUM(user_object_reserved_page_count) * 8.192 AS [UserObjectsKB] ,
      SUM(internal_object_reserved_page_count) * 8.192 AS [InternalObjectsKB] ,
      SUM(version_store_reserved_page_count) * 8.192 AS [VersonStoreKB] ,
      SUM(unallocated_extent_page_count) * 8.192 AS [FreeSpaceKB]
FROM    sys.dm_db_file_space_usage ;

-- Script 18
-- Calculates average stalls per read, per write, and per total input/output
-- for each database file. 
SELECT  DB_NAME(database_id) AS [Database Name] ,
        file_id ,
        io_stall_read_ms ,
        num_of_reads ,
        CAST(io_stall_read_ms / ( 1.0 + num_of_reads ) AS NUMERIC(10, 1))
            AS [avg_read_stall_ms] ,
        io_stall_write_ms ,
        num_of_writes ,
        CAST(io_stall_write_ms / ( 1.0 + num_of_writes ) AS NUMERIC(10, 1))
            AS [avg_write_stall_ms] ,
        io_stall_read_ms + io_stall_write_ms AS [io_stalls] ,
        num_of_reads + num_of_writes AS [total_io] ,
        CAST(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads
                                                          + num_of_writes)
           AS NUMERIC(10,1)) AS [avg_io_stall_ms]
FROM    sys.dm_io_virtual_file_stats(NULL, NULL)
ORDER BY avg_io_stall_ms DESC ;

-- Script 19
-- Look at pending I/O requests by file
SELECT  DB_NAME(mf.database_id) AS [Database] ,
        mf.physical_name ,
        r.io_pending ,
        r.io_pending_ms_ticks ,
        r.io_type ,
        fs.num_of_reads ,
        fs.num_of_writes
FROM    sys.dm_io_pending_io_requests AS r
        INNER JOIN sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
                                          ON r.io_handle = fs.file_handle
        INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                             AND fs.file_id = mf.file_id
ORDER BY r.io_pending ,
        r.io_pending_ms_ticks DESC ;
        
-- Script 20        
-- Total waits are wait_time_ms (high signal waits indicates CPU pressure)
SELECT  CAST(100.0 * SUM(signal_wait_time_ms) / SUM(wait_time_ms)
                              AS NUMERIC(20,2)) AS [%signal (cpu) waits] ,
        CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms)
        / SUM(wait_time_ms) AS NUMERIC(20, 2)) AS [%resource waits]
FROM    sys.dm_os_wait_stats ;


-- Script 21
-- Isolate top waits for server instance since last restart 
-- or statistics clear
WITH    Waits
      AS ( SELECT   wait_type ,
                    wait_time_ms / 1000. AS wait_time_s ,
                    100. * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS pct ,
                    ROW_NUMBER() OVER ( ORDER BY wait_time_ms DESC ) AS rn
           FROM     sys.dm_os_wait_stats
           WHERE    wait_type NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP',
                                       'RESOURCE_QUEUE', 'SLEEP_TASK',
                                       'SLEEP_SYSTEMTASK',
                                       'SQLTRACE_BUFFER_FLUSH', 'WAITFOR',
                                       'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE',
                                       'REQUEST_FOR_DEADLOCK_SEARCH',
                                       'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
                                       'BROKER_TASK_STOP',
                                       'CLR_MANUAL_EVENT',
                                       'CLR_AUTO_EVENT',
                                       'DISPATCHER_QUEUE_SEMAPHORE',
                                       'FT_IFTS_SCHEDULER_IDLE_WAIT',
                                       'XE_DISPATCHER_WAIT',
                                       'XE_DISPATCHER_JOIN' )
         )
    SELECT  W1.wait_type ,
            CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s ,
            CAST(W1.pct AS DECIMAL(12, 2)) AS pct ,
            CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
    FROM    Waits AS W1
            INNER JOIN Waits AS W2 ON W2.rn <= W1.rn
    GROUP BY W1.rn ,
            W1.wait_type ,
            W1.wait_time_s ,
            W1.pct
    HAVING  SUM(W2.pct) - W1.pct < 95 ; -- percentage threshold


-- Script 22
-- Recovery model, log reuse wait description, log file size, 
-- log usage size and compatibility level for all databases on instance
SELECT  db.[name] AS [Database Name] ,
        db.recovery_model_desc AS [Recovery Model] ,
        db.log_reuse_wait_desc AS [Log Reuse Wait Description] ,
        ls.cntr_value AS [Log Size (KB)] ,
        lu.cntr_value AS [Log Used (KB)] ,
        CAST(CAST(lu.cntr_value AS FLOAT) / CAST(ls.cntr_value AS FLOAT)
                    AS DECIMAL(18,2)) * 100 AS [Log Used %] ,
        db.[compatibility_level] AS [DB Compatibility Level] ,
        db.page_verify_option_desc AS [Page Verify Option]
FROM    sys.databases AS db
        INNER JOIN sys.dm_os_performance_counters AS lu
                    ON db.name = lu.instance_name
        INNER JOIN sys.dm_os_performance_counters AS ls
                    ON db.name = ls.instance_name
WHERE   lu.counter_name LIKE 'Log File(s) Used Size (KB)%'
        AND ls.counter_name LIKE 'Log File(s) Size (KB)%' ;
        
        
-- Script 23
-- Hardware information from SQL Server 2008 
-- (Cannot distinguish between HT and multi-core)
SELECT  cpu_count AS [Logical CPU Count] ,
        hyperthread_ratio AS [Hyperthread Ratio] ,
        cpu_count / hyperthread_ratio AS [Physical CPU Count] ,
        physical_memory_in_bytes / 1048576 AS [Physical Memory (MB)] ,
        sqlserver_start_time
FROM    sys.dm_os_sys_info ;

-- Hardware information from SQL Server 2005 
-- (Cannot distinguish between HT and multi-core)
SELECT  cpu_count AS [Logical CPU Count] ,
        hyperthread_ratio AS [Hyperthread Ratio] ,
        cpu_count / hyperthread_ratio AS [Physical CPU Count] ,
        physical_memory_in_bytes / 1048576 AS [Physical Memory (MB)]
FROM    sys.dm_os_sys_info ;


-- Script 24
-- Get CPU Utilization History for last 30 minutes (in one minute intervals)
-- This version works with SQL Server 2008 and SQL Server 2008 R2 only
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks)FROM sys.dm_os_sys_info); 

SELECT TOP(30) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM ( 
	  SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
			AS [SystemIdle], 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 
			'int') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM ( 
			SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers 
			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			AND record LIKE N'%<SystemHealth>%') AS x 
	  ) AS y 
ORDER BY record_id DESC;

-- Script 25
-- Get Avg task count and Avg runnable task count
SELECT  AVG(current_tasks_count) AS [Avg Task Count] ,
        AVG(runnable_tasks_count) AS [Avg Runnable Task Count]
FROM    sys.dm_os_schedulers
WHERE   scheduler_id < 255
        AND [status] = 'VISIBLE ONLINE' ;
        
        
-- Script 26
-- Is NUMA enabled
SELECT  CASE COUNT(DISTINCT parent_node_id)
          WHEN 1 THEN 'NUMA disabled'
          ELSE 'NUMA enabled'
        END
FROM    sys.dm_os_schedulers
WHERE   parent_node_id <> 32 ;


-- Script 27
-- Good basic information about memory amounts and state
-- SQL Server 2008 and 2008 R2 only
SELECT  total_physical_memory_kb ,
        available_physical_memory_kb ,
        total_page_file_kb ,
        available_page_file_kb ,
        system_memory_state_desc
FROM    sys.dm_os_sys_memory ;


-- Script 28
-- SQL Server Process Address space info (SQL 2008 and 2008 R2 only)
--(shows whether locked pages is enabled, among other things)
SELECT  physical_memory_in_use_kb ,
        locked_page_allocations_kb ,
        page_fault_count ,
        memory_utilization_percentage ,
        available_commit_limit_kb ,
        process_physical_memory_low ,
        process_virtual_memory_low
FROM    sys.dm_os_process_memory ;

-- Script 29
-- Look at the number of items in different parts of the cache
SELECT  name ,
        [type] ,
        entries_count ,
        single_pages_kb ,
        single_pages_in_use_kb ,
        multi_pages_kb ,
        multi_pages_in_use_kb
FROM    sys.dm_os_memory_cache_counters
WHERE   [type] = 'CACHESTORE_SQLCP'
        OR [type] = 'CACHESTORE_OBJCP'
ORDER BY multi_pages_kb DESC ;

-- Script 30
-- Get total buffer usage by database
SELECT  DB_NAME(database_id) AS [Database Name] ,
        COUNT(*) * 8 / 1024.0 AS [Cached Size (MB)]
FROM    sys.dm_os_buffer_descriptors
WHERE   database_id > 4 -- exclude system databases
        AND database_id <> 32767 -- exclude ResourceDB
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC ;

-- Breaks down buffers by object (table, index) in the buffer pool
SELECT  OBJECT_NAME(p.[object_id]) AS [ObjectName] ,
        p.index_id ,
        COUNT(*) / 128 AS [Buffer size(MB)] ,
        COUNT(*) AS [Buffer_count]
FROM    sys.allocation_units AS a
        INNER JOIN sys.dm_os_buffer_descriptors
                 AS b ON a.allocation_unit_id = b.allocation_unit_id
        INNER JOIN sys.partitions AS p ON a.container_id = p.hobt_id
WHERE   b.database_id = DB_ID()
        AND p.[object_id] > 100 
GROUP BY p.[object_id] ,
        p.index_id
ORDER BY buffer_count DESC ;


-- Script 31
-- Find long running SQL/CLR tasks
SELECT  os.task_address ,
        os.[state] ,
        os.last_wait_type ,
        clr.[state] ,
        clr.forced_yield_count
FROM    sys.dm_os_workers AS os
        INNER JOIN sys.dm_clr_tasks AS clr
                     ON ( os.task_address = clr.sos_task_address )
WHERE   clr.[type] = 'E_TYPE_USER' ;

-- Script 32
-- Get population status for all FT catalogs in the current database
SELECT  c.name ,
        c.[status] ,
        c.status_description ,
        OBJECT_NAME(p.table_id) AS [table_name] ,
        p.population_type_description ,
        p.is_clustered_index_scan ,
        p.status_description ,
        p.completion_type_description ,
        p.queued_population_type_description ,
        p.start_time ,
        p.range_count
FROM    sys.dm_fts_active_catalogs AS c
        INNER JOIN sys.dm_fts_index_population AS p
                       ON c.database_id = p.database_id
                        AND c.catalog_id = p.catalog_id
WHERE   c.database_id = DB_ID()
ORDER BY c.name ;

-- Script 33
-- Check auto page repair history (New in SQL 2008)
SELECT  DB_NAME(database_id) AS [database_name] ,
        database_id ,
        file_id ,
        page_id ,
        error_type ,
        page_status ,
        modification_time
FROM    sys.dm_db_mirroring_auto_page_repair ; 


--#######################################################################################################################################################################################################

SELECT TOP 5 total_worker_time/execution_count AS [Avg CPU Time],
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1, 
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
         ELSE qs.statement_end_offset
         END - qs.statement_start_offset)/2) + 1) AS statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
ORDER BY total_worker_time/execution_count DESC;

-- Isolate top waits for server instance since last restart or statistics clear
WITH Waits AS ( 
				SELECT	wait_type , 
						wait_time_ms / 1000. AS wait_time_s , 
						100. * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS pct ,
						ROW_NUMBER() OVER ( ORDER BY wait_time_ms DESC ) AS rn 
				FROM	sys.dm_os_wait_stats 
				WHERE	wait_type NOT IN ( 'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK', 'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT', 'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN' ) 
				) 
SELECT		W1.wait_type , 
			CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s , 
			CAST(W1.pct AS DECIMAL(12, 2)) AS pct , 
			CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct 
FROM		Waits AS W1 
INNER JOIN	Waits AS W2 
	ON		W2.rn <= W1.rn 
GROUP BY	W1.rn , W1.wait_type , W1.wait_time_s , W1.pct 
HAVING SUM(W2.pct) - W1.pct < 95 ; -- percentage threshold

select		est.text,* 
from		sys.dm_exec_requests r
cross apply sys.dm_exec_sql_text(r.plan_handle) AS est
left join	sys.dm_exec_sessions s
	on		r.session_id = s.session_id
inner join	sys.dm_exec_connections c
	on		s.session_id = c.session_id	
where		est.text = 'select * from "SGF_REC"."DBO"."MREC_VOLUMES_TRANSF_LOJAS_DET"'	

--DBCC SQLPERF (N'sys.dm_os_wait_stats', CLEAR);
--GO

WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER',             N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP',                N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER',              N'CHECKPOINT_QUEUE',
        N'CHKPT',                           N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT',                N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT',              N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE',           N'DBMIRRORING_CMD',
        N'DIRTY_PAGE_POLL',                 N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC',                        N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT',     N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL',               N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT',            N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK',                 N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP',                  N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE',                    N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'REQUEST_FOR_DEADLOCK_SEARCH',     N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK',               N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP',                 N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY',             N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED',            N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK',                N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP',             N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP',     N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES',           N'WAIT_FOR_RESULTS',
        N'WAITFOR',                         N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_HOST_WAIT',              N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE',             N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT',              N'XE_TIMER_EVENT')
    AND [waiting_tasks_count] > 0
 )
SELECT
    MAX ([W1].[wait_type]) AS [WaitType],
    CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
    CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
    CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
    MAX ([W1].[WaitCount]) AS [WaitCount],
    CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
    CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
    CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
    CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S]
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2]
    ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum]
HAVING SUM ([W2].[Percentage]) - MAX ([W1].[Percentage]) < 95; -- percentage threshold
GO

select		
			ec.session_id
			,es.login_name			
			,ec.connect_time
			,ec.client_net_address
			,es.[host_name]
			,es.[program_name]
			,es.[status]
			,tat.transaction_id
			,tat.transaction_begin_time
			--,tat.transaction_type
			,case 
				when tat.transaction_type = 1 then 'Transação de leitura/gravação'
				when tat.transaction_type = 2 then 'Transação somente leitura'
				when tat.transaction_type = 3 then 'Transação do sistema'
				when tat.transaction_type = 4 then 'Transação distribuída'
			end as transaction_type_desc
			--,tat.transaction_state
			,case
				when tat.transaction_state = 0 then 'transação não foi completamente inicializada ainda'
				when tat.transaction_state = 1 then 'transação foi inicializada mas não foi iniciada'
				when tat.transaction_state = 2 then 'transação está ativa'
				when tat.transaction_state = 3 then 'transação foi encerrada,somente leitura'
				when tat.transaction_state = 4 then 'processo de confirmação foi iniciado na transação distribuída'
				when tat.transaction_state = 5 then 'transação está em um estado preparado e aguardando resolução'
				when tat.transaction_state = 6 then 'transação foi confirmada'
				when tat.transaction_state = 7 then 'transação está sendo revertida'
				when tat.transaction_state = 8 then 'transação foi revertida'
			end as transaction_state_desc
			--,tat.dtc_state (azure)
			,tat.transaction_uow
			,tst.is_user_transaction
			,tst.is_local
			,er.*
from		sys.dm_tran_active_transactions tat
inner join	sys.dm_tran_session_transactions tst
	on		tat.transaction_id = tst.transaction_id
inner join	sys.dm_exec_sessions es
	on		tst.session_id = es.session_id	
inner join	sys.dm_exec_connections ec
	on		es.session_id = ec.session_id
left join	sys.dm_exec_requests er
	on		es.session_id = er.session_id
	


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

--#######################################################################################################################################################################################################

SELECT  
			er.session_id ,
			er.start_time,
			er.[status] ,			
			er.blocking_session_id,
			er.wait_type,
			er.wait_time,
			er.wait_resource,
			er.cpu_time ,
			er.total_elapsed_time ,
			es.memory_usage,			
			er.writes ,			
			er.reads ,
			er.logical_reads ,
			er.command,
			SUBSTRING(qt.[text], er.statement_start_offset / 2,
				( CASE WHEN er.statement_end_offset = -1
					   THEN LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2
					   ELSE er.statement_end_offset
				  END - er.statement_start_offset ) / 2) AS [statement_executing] ,
			DB_NAME(qt.[dbid]) AS [DatabaseName] ,
			OBJECT_NAME(qt.objectid) AS [ObjectName] ,
			OBJECT_NAME(eps.[object_id]) AS ProcedureName,	
			er.scheduler_id ,		
			er.transaction_isolation_level,
			er.[lock_timeout],
			er.[deadlock_priority],
			er.granted_query_memory,
			es.login_name,
			es.login_time,
			es.host_name,
			es.[program_name],
			ec.client_net_address,			
			er.[plan_handle],
			eqp.[query_plan]
FROM		sys.dm_exec_requests AS er
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
OUTER APPLY	sys.dm_exec_query_plan (er.plan_handle) eqp
inner join  sys.dm_exec_sessions es
	on		er.session_id = es.session_id
inner join	sys.dm_exec_connections ec
	on		er.session_id = ec.session_id
left join	sys.dm_exec_procedure_stats eps
	on		er.sql_handle = eps.sql_handle      
WHERE		er.session_id > 50

/*

dbcc inputbuffer ()

select * from sys.sysprocesses where blocked <> 0 

select * from sys.dm_exec_requests
select * from sys.dm_os_waiting_tasks
select * from sys.dm_exec_sessions
select * from sys.dm_exec_connections
*/

--#######################################################################################################################################################################################################

select --top(10)
	qs.plan_handle,
  PlanCreated       = qs.creation_time,
  ObjectName        = object_name(st.objectid),
  QueryPlan         = cast(qp.query_plan as xml),
  QueryText         = substring(st.text, 1 + (qs.statement_start_offset / 2), 1 + ((isnull(nullif(qs.statement_end_offset, -1), datalength(st.text)) - qs.statement_start_offset) / 2)),
  ExecutionCount    = qs.execution_count,
  TotalRW           = qs.total_logical_reads + qs.total_logical_writes,
  AvgRW             = (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count,
  TotalDurationMS   = qs.total_elapsed_time / 1000,
  AvgDurationMS     = qs.total_elapsed_time / qs.execution_count / 1000,
  TotalCPUMS        = qs.total_worker_time / 1000,
  AvgCPUMS          = qs.total_worker_time / qs.execution_count / 1000,
  TotalCLRMS        = qs.total_clr_time / 1000,
  AvgCLRMS          = qs.total_clr_time / qs.execution_count / 1000
  --TotalRows         = qs.total_rows,
  --AvgRows           = qs.total_rows / qs.execution_count
from		sys.dm_exec_query_stats as qs
inner join	sys.dm_exec_cached_plans cp
	on		qs.plan_handle = cp.plan_handle
cross apply sys.dm_exec_sql_text(qs.sql_handle) as st
cross apply sys.dm_exec_text_query_plan(qs.plan_handle, qs.statement_start_offset, qs.statement_end_offset) as qp
where		qp.objectid = OBJECT_ID('my_AddressSP')
--order by ExecutionCount desc
--order by TotalRW desc
--order by TotalDurationMS desc
--order by AvgDurationMS desc

--verificação de planos de execução em cache
SELECT		QT.text,
            QP.query_plan,
			--QS.sql_handle,
			QS.creation_time,
			QS.last_execution_time,
			QS.execution_count,
			QS.total_worker_time,
			QS.total_physical_reads,
			QS.total_logical_reads,
			QS.total_logical_writes,
			QS.total_elapsed_time,
			QS.total_rows
FROM sys.dm_exec_query_stats as QS
 CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as QT
 CROSS APPLY sys.dm_exec_query_plan (QS.plan_handle) as QP
ORDER BY QS.execution_count DESC


SELECT QT.text,
             QP.query_plan,
             QS.execution_count,
             QS.total_elapsed_time,
             QS.last_elapsed_time,
             QS.total_logical_reads
FROM sys.dm_exec_query_stats as QS
 CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as QT
 CROSS APPLY sys.dm_exec_query_plan (QS.plan_handle) as QP
ORDER BY QS.execution_count DESC

--verificação utilização tempdb
SELECT 
		FreePages = SUM(unallocated_extent_page_count),
		FreeSpaceMB = SUM(unallocated_extent_page_count)/128.0,
		VersionStorePages = SUM(version_store_reserved_page_count),
		VersionStoreMB = SUM(version_store_reserved_page_count)/128.0,
		InternalObjectPages = SUM(internal_object_reserved_page_count),
		InternalObjectsMB = SUM(internal_object_reserved_page_count)/128.0,
		UserObjectPages = SUM(user_object_reserved_page_count),
		UserObjectsMB = SUM(user_object_reserved_page_count)/128.0
FROM sys.dm_db_file_space_usage;

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

--qtd reg tabela tempdb
select
    object_name(p.object_id) as tabela, rows as linhas,
    sum(total_pages * 8) as reservado,
    sum(case when index_id > 1 then 0 else data_pages * 8 end) as dados,
        sum(used_pages * 8) -
        sum(case when index_id > 1 then 0 else data_pages * 8 end) as indice,
    sum((total_pages - used_pages) * 8) as naoutilizado
from
    sys.partitions as p
    inner join sys.allocation_units as a on p.hobt_id = a.container_id
	inner join sys.tables t on p.object_id = t.object_id	    
group by object_name(p.object_id), rows
order by 2 desc

--verificação locks, blocks
select 
			blocking.session_id as blocking_session_id ,
			blocked.session_id as blocked_session_id ,
			waitstats.wait_type as blocking_resource ,
			waitstats.wait_duration_ms ,
			waitstats.resource_description ,
			blocked_cache.text as blocked_text ,
			blocking_cache.text as blocking_text
from		sys.dm_exec_connections blocking
inner join	sys.dm_exec_requests blocked
	on		blocking.session_id = blocked.blocking_session_id
cross apply sys.dm_exec_sql_text(blocked.sql_handle) blocked_cache
cross apply sys.dm_exec_sql_text(blocking.most_recent_sql_handle) blocking_cache
inner join	sys.dm_os_waiting_tasks waitstats
	on		waitstats.session_id = blocked.session_id

--#######################################################################################################################################################################################################

----querys/adhocs

--SELECT TOP 25 db_name(eST.[dbid]) AS [database]
--		,eST.[dbid]
--        , eQS.execution_count

--        -- CPU
--        , eQS.min_worker_time AS [min_cpu]
--        , eQS.max_worker_time AS [max_cpu]
--        , eQS.total_worker_time/ISNULL(eQS.execution_count, 1) AS [avg_cpu]
--        , eQS.last_elapsed_time AS [last_cpu]
--        , eQS.total_worker_time AS [total_cpu]

--        -- ELAPSED TIME
--        , eQS.min_elapsed_time AS [min_duration]
--        , eQS.max_elapsed_time AS [max_duration]
--        , eQS.total_elapsed_time/ISNULL(eQS.execution_count, 1) AS [avg_duration]
--        , eQS.last_elapsed_time AS [last_duration]
--        , eQS.total_elapsed_time AS [total_duration]  

--        -- LOGICAL READS
--        , eQS.min_logical_reads AS [min_logical_reads]
--        , eQS.max_logical_reads AS [max_logical_reads]
--        , eQS.total_logical_reads/ISNULL(eQS.execution_count, 1) AS [avg_logical_reads]
--        , eQS.last_logical_reads AS [last_logical_reads]
--        , eQS.total_logical_reads 

--        -- PHYSICAL READS
--        , eQS.min_physical_reads AS [min_physical_reads]
--        , eQS.max_physical_reads AS [max_physical_reads]
--        , eQS.total_physical_reads/ISNULL(eQS.execution_count, 1) AS [avg_physical_reads]
--        , eQS.last_physical_reads AS [last_physical_reads]
--        , eQS.total_physical_reads 

--        -- LOGICAL WRITES
--        , eQS.min_logical_writes AS [min_writes]
--        , eQS.max_logical_writes AS [max_writes]
--        , eQS.total_logical_writes/ISNULL(eQS.execution_count, 1) AS [avg_writes]
--        , eQS.last_logical_writes AS [last_writes]
--        , eQS.total_logical_writes AS [total_writes]

--        ----ROW COUNTS
--        --, eQS.min_rows AS [min_rows]
--        --, eQS.max_rows AS [max_rows]
--        --, eQS.total_rows/ISNULL(eQS.execution_count, 1) AS [avg_rows]
--        --, eQS.last_rows AS [last_rows]
--        --, eQS.total_rows 


--        -- CACHE & EXEC TIMES
--        , eQS.last_execution_time
--        , eQS.creation_time
--        , DATEDIFF(Minute, eQS.creation_time, GetDate()) AS 'minutes_in_cache'
--        , eQS.execution_count/ISNULL(DATEDIFF(Minute, NULLIF(eQS.creation_time,0), GetDate()), 1) AS [calls/minute]
--        , eQS.execution_count/ISNULL(DATEDIFF(Second, NULLIF(eQS.creation_time,0), GetDate()), 1) AS [calls/second]

--        --STATEMENTS AND QUERY TEXT DETAILS
--        , eST.text AS [batch_text]
--        , SUBSTRING
--                (
--                        eST.text, (eQS.statement_start_offset/2) + 1
--                                , 
--                                        (
--                                                (
--                                                        CASE eQS.statement_end_offset  
--                                                                WHEN -1 THEN DATALENGTH(eST.text)  
--                                                                ELSE eQS.statement_end_offset  
--                                                        END 
--                                                                - eQS.statement_start_offset
--                                                )/2
--                                        ) + 1
--                ) AS [statement_executing]  
--        , eQP.[query_plan]
--        , eQS.[plan_handle]
--FROM sys.dm_exec_query_stats AS eQS  
--        CROSS APPLY sys.dm_exec_sql_text(eQS.sql_handle) AS eST  
--        CROSS APPLY sys.dm_exec_query_plan (eQS.plan_handle) AS eQP 
--WHERE	eST.[dbid] <> 32767
----WHERE db_name(eST.[dbid]) = 'SGF_FAT'
----ORDER BY eQS.total_logical_reads/ISNULL(eQS.execution_count, 1) DESC;         -- [avg_logical_reads]
----ORDER BY eQS.total_physical_reads/ISNULL(eQS.execution_count, 1) DESC;        -- [avg_physical_reads]
----ORDER BY eQS.total_logical_writes/ISNULL(eQS.execution_count, 1) DESC;        -- [avg_logical_writes]
----ORDER BY eQS.total_worker_time/ISNULL(eQS.execution_count, 1) DESC;           -- [avg_cpu]
----ORDER BY eQS.total_elapsed_time/ISNULL(eQS.execution_count, 1) DESC;          -- [avg_duration]
----ORDER BY eQS.total_rows/ISNULL(eQS.execution_count, 1) DESC;                          -- [avg_rows]

----procs

--SELECT TOP 25 db_name(eST.[dbid]) AS [database]
--        , OBJECT_SCHEMA_NAME(ePS.[object_id], ePS.database_id) AS [schema_name]
--        , OBJECT_NAME(ePS.[object_id], ePS.database_id) AS [procedure_name]
--        , ePS.execution_count

--        -- CPU
--        , ePS.min_worker_time AS [min_cpu]
--        , ePS.max_worker_time AS [max_cpu]
--        , ePS.total_worker_time/ISNULL(ePS.execution_count, 1) AS [avg_cpu]
--        , ePS.last_elapsed_time AS [last_cpu]
--        , ePS.total_worker_time AS [total_cpu]

--        -- ELAPSED TIME
--        , ePS.min_elapsed_time AS [min_duration]
--        , ePS.max_elapsed_time AS [max_duration]
--        , ePS.total_elapsed_time/ISNULL(ePS.execution_count, 1) AS [avg_duration]
--        , ePS.last_elapsed_time AS [last_duration]
--        , ePS.total_elapsed_time AS [total_duration]  

--        -- LOGICAL READS
--        , ePS.min_logical_reads AS [min_logical_reads]
--        , ePS.max_logical_reads AS [max_logical_reads]
--        , ePS.total_logical_reads/ISNULL(ePS.execution_count, 1) AS [avg_logical_reads]
--        , ePS.last_logical_reads AS [last_logical_reads]
--        , ePS.total_logical_reads 

--        -- PHYSICAL READS
--        , ePS.min_physical_reads AS [min_physical_reads]
--        , ePS.max_physical_reads AS [max_physical_reads]
--        , ePS.total_physical_reads/ISNULL(ePS.execution_count, 1) AS [avg_physical_reads]
--        , ePS.last_physical_reads AS [last_physical_reads]
--        , ePS.total_physical_reads 

--        -- LOGICAL WRITES
--        , ePS.min_logical_writes AS [min_writes]
--        , ePS.max_logical_writes AS [max_writes]
--        , ePS.total_logical_writes/ISNULL(ePS.execution_count, 1) AS [avg_writes]
--        , ePS.last_logical_writes AS [last_writes]
--        , ePS.total_logical_writes AS [total_writes]

--        -- CACHE & EXEC TIMES
--        , ePS.last_execution_time

--        --STATEMENTS AND QUERY TEXT DETAILS
--        , eST.text AS [procedure_code]
--        , ePS.[plan_handle]

--FROM sys.dm_exec_procedure_stats AS ePS  
--        CROSS APPLY sys.dm_exec_sql_text(ePS.sql_handle) AS eST  
--        CROSS APPLY sys.dm_exec_query_plan (ePS.plan_handle) AS eQP 
--WHERE db_name(eST.[dbid]) = '<database_name,,>'
--ORDER BY ePS.total_logical_reads/ISNULL(ePS.execution_count, 1) DESC;           -- [avg_logical_reads]
----ORDER BY ePS.total_physical_reads/ISNULL(ePS.execution_count, 1) DESC;        -- [avg_physical_reads]
----ORDER BY ePS.total_logical_writes/ISNULL(ePS.execution_count, 1) DESC;        -- [avg_logical_writes]
----ORDER BY ePS.total_worker_time/ISNULL(ePS.execution_count, 1) DESC;           -- [avg_cpu]
----ORDER BY ePS.total_elapsed_time/ISNULL(ePS.execution_count, 1) DESC;          -- [avg_duration]
----ORDER BY ePS.total_rows/ISNULL(ePS.execution_count, 1) DESC;                          -- [avg_rows]

--#######################################################################################################################################################################################################

--PROCS
select		--top 1
			db_name(eps.database_id) as database_name,
			object_schema_name(eps.[object_id], eps.database_id) as [schema_name],
			object_name(eps.[object_id], eps.database_id) AS [procedure_name],
			eps.cached_time,
			eps.last_execution_time,
			eps.execution_count,
			--cpu
			eps.min_worker_time,
			eps.max_worker_time,
			eps.total_worker_time / isnull(eps.execution_count, 1) as avg_cpu,
			eps.last_worker_time,
			eps.total_worker_time,
			--elapsed time
			eps.min_elapsed_time,
			eps.max_elapsed_time,
			eps.total_elapsed_time / isnull(eps.execution_count, 1) as avg_duration,
			eps.last_elapsed_time,
			eps.total_elapsed_time,
			--physical reads	
			eps.total_physical_reads,
			eps.last_physical_reads,
			eps.min_physical_reads,
			eps.max_physical_reads,
			eps.total_physical_reads / isnull(eps.execution_count, 1) as avg_physical_reads,
			--logical reads	
			eps.min_logical_reads,
			eps.max_logical_reads,
			eps.total_logical_reads / isnull(eps.execution_count, 1) as avg_logical_reads,
			eps.last_logical_reads,
			eps.total_logical_reads,
			--logical writes	
			eps.min_logical_writes,
			eps.max_logical_writes,
			eps.total_logical_writes / isnull(eps.execution_count, 1) as avg_logical_writes,
			eps.last_logical_writes,
			eps.total_logical_writes,
			--
			ecp.refcounts,
			ecp.size_in_bytes,
			ecp.cacheobjtype,
			ecp.objtype,
			eqp.query_plan,
			est.text,
			ecp.plan_handle
	        --,SUBSTRING(est.[text], r.statement_start_offset / 2, ( CASE WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), est.[text])) * 2 ELSE r.statement_end_offset END - r.statement_start_offset ) / 2) AS [statement_executing]
from		sys.dm_exec_procedure_stats eps
inner join	sys.dm_exec_cached_plans ecp
	on		eps.plan_handle = ecp.plan_handle
cross apply	sys.dm_exec_query_plan (eps.plan_handle) eqp
cross apply	sys.dm_exec_sql_text(eps.plan_handle) est
where		db_name(eps.database_id) = 'dbAuditoria'
	--and		eps.object_id = 709577566
order by	avg_cpu desc
--order by	avg_duration desc
--order by	avg_physical_reads desc
--order by	avg_logical_reads desc
--order by	avg_logical_writes desc
--order by	avg_rows desc

--QUERYS
select		--top 1
			db_name(etqp.dbid) as database_name,
			object_schema_name(etqp.objectid, etqp.dbid) as [schema_name],
			object_name(etqp.objectid, etqp.dbid) AS [procedure_name],
			eqs.creation_time,
			datediff(minute, eqs.creation_time, getdate()) as 'minutes_in_cache',
			--eqs.execution_count / isnull(datediff(minute, nullif(eqs.creation_time,0), getdate()), 1) as [calls/minute],
			--eqs.execution_count / isnull(datediff(second, nullif(eqs.creation_time,0), getdate()), 1) as [calls/second],
			cast(eqs.execution_count as numeric(9,2)) / isnull(datediff(minute, nullif(eqs.creation_time,0), getdate()), 1) as [calls/minute],
			cast(eqs.execution_count as numeric(9,2)) / isnull(datediff(second, nullif(eqs.creation_time,0), getdate()), 1) as [calls/second],
			eqs.last_execution_time,
			eqs.execution_count,
			--cpu
			eqs.min_worker_time,
			eqs.max_worker_time,
			eqs.total_worker_time / isnull(eqs.execution_count, 1) as avg_cpu,
			eqs.last_worker_time,
			eqs.total_worker_time,
			--elapsed time
			eqs.min_elapsed_time,
			eqs.max_elapsed_time,
			eqs.total_elapsed_time / isnull(eqs.execution_count, 1) as avg_duration,
			eqs.last_elapsed_time,
			eqs.total_elapsed_time,
			--physical reads	
			eqs.min_physical_reads,
			eqs.max_physical_reads,
			eqs.total_physical_reads / isnull(eqs.execution_count, 1) as avg_physical_reads,
			eqs.last_physical_reads,
			eqs.total_physical_reads,
			--logical reads	
			eqs.min_logical_reads,
			eqs.max_logical_reads,
			eqs.total_logical_reads / isnull(eqs.execution_count, 1) as avg_logical_reads,
			eqs.last_logical_reads,
			eqs.total_logical_reads,
			--logical writes	
			eqs.min_logical_writes,
			eqs.max_logical_writes,
			eqs.total_logical_writes / isnull(eqs.execution_count, 1) as avg_logical_writes,
			eqs.last_logical_writes,
			eqs.total_logical_writes,
			--clr
			--eqs.min_clr_time,
			--eqs.max_clr_time,
			--eqs.total_clr_time / isnull(eqs.execution_count, 1) as avg_clr,
			--eqs.last_clr_time,
			--eqs.total_clr_time,
			--
			eqs.statement_start_offset,
			eqs.statement_end_offset,
			eqs.plan_generation_num,
			ecp.refcounts,
			ecp.size_in_bytes,
			ecp.cacheobjtype,
			ecp.objtype,
			--eqp.query_plan,
			cast(etqp.query_plan as xml),
			SUBSTRING(est.[text], eqs.statement_start_offset / 2, ( CASE WHEN eqs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), est.[text])) * 2 ELSE eqs.statement_end_offset END - eqs.statement_start_offset ) / 2) AS [statement_executing],
			est.text
from		sys.dm_exec_query_stats eqs
inner join	sys.dm_exec_cached_plans ecp
	on		eqs.plan_handle = ecp.plan_handle
cross apply	sys.dm_exec_sql_text(eqs.plan_handle) est
cross apply sys.dm_exec_text_query_plan(eqs.plan_handle, eqs.statement_start_offset, eqs.statement_end_offset) as etqp
--cross apply	sys.dm_exec_query_plan (eps.plan_handle) eqp
where		db_name(etqp.dbid) = 'dbAuditoria'
--where		etqp.dbid <> 32767
--	and		eqp.objectid = 709577566
--where		est.objectid = object_id('dbAuditoria..usp_teste2')
order by	avg_cpu desc
--order by	avg_duration desc
--order by	avg_physical_reads desc
--order by	avg_logical_reads desc
--order by	avg_logical_writes desc
--order by	avg_rows desc


--#######################################################################################################################################################################################################
--identificar nome job em execução

--SELECT program_name, '|' + SUBSTRING(program_name,30,34) + '|' AS JobIDSubstring, t.text
select		j.name, t.text, s.session_id
from		sys.dm_exec_sessions s 
inner join	sys.dm_exec_requests r 
	on		s.session_id = r.session_id
cross apply	sys.dm_exec_sql_text (r.sql_handle) t
inner join	msdb..sysjobsteps js 
	on		substring(s.program_name,30,34) = convert(varchar(34), convert(varbinary(32), js.job_id), 1) 
inner join	msdb..sysjobs j 
	on		js.job_id = j.job_id
where		s.program_name like 'sqlagent%'
	and		js.step_id = 1

--#######################################################################################################################################################################################################
--verificacao locks

--select		
--			l.request_session_id as spid
--			,db_name(l.resource_database_id) as dbname
--			,case 
--				when l.resource_type = 'OBJECT' then OBJECT_NAME(l.resource_associated_entity_id)
--				when l.resource_associated_entity_id = 0 then ''
--				else OBJECT_NAME(p.object_id)
--			end as objectname
--			,p.index_id
--			,l.resource_type
--			,l.resource_description
--			,l.request_mode
--			,l.request_status
--			,*	
--from		sys.dm_tran_locks l
--left join	sys.partitions p
--	on		l.resource_associated_entity_id = p.partition_id
--where		l.resource_type <> 'DATABASE'
--	--and		l.resource_database_id = db_id()
--	and		l.request_session_id = 99
--	and		l.request_mode = 'X'

--para identificar tabela bloqueada
use dbName
go

select 
			db_name(dtl.resource_database_id) as database_name,
			--object_name(p.object_id) as object_name,
			case 
				when dtl.resource_type = 'OBJECT' then OBJECT_NAME(dtl.resource_associated_entity_id)
				when dtl.resource_associated_entity_id = 0 then ''
				else OBJECT_NAME(p.object_id)
			end as objectname,
			p.rows,
			dtl.resource_type,
			dtl.request_mode,
			dtl.resource_description,
			dtl.request_session_id, 
			dtl.request_status, 
			--dtl.request_lifetime,
			--dtl.resource_associated_entity_id, 
			i.name index_name,
			i.index_id
from		sys.dm_tran_locks dtl
left join	sys.partitions p
	on		p.hobt_id = dtl.resource_associated_entity_id
	--on		p.partition_id = dtl.resource_associated_entity_id
inner join	sys.indexes i
	on		i.object_id = p.object_id 
	and		i.index_id = p.index_id
--where		db_name(dtl.resource_database_id)='dbName'
order by	dtl.request_session_id	

select		*
from		sys.dm_tran_locks dtl
where		request_status = 'wait'

--#######################################################################################################################################################################################################

--utilizacao indices

select   
			
			db_name(ddius.database_id) as database_name,
			object_name(ddius.[object_id]) as [object_name],
			i.index_id,
			i.[name] as index_name,
			ddius.user_seeks,
			ddius.user_scans,
			ddius.user_lookups,
			ddius.user_updates,
			ddius.last_user_seek,
			ddius.last_user_scan,
			ddius.last_user_update
from	    sys.dm_db_index_usage_stats as ddius
inner join	sys.indexes as i
	on		i.[object_id] = ddius.[object_id]
	and		i.index_id = ddius.index_id
--where   object_name(ddius.[object_id])='bigproduct'


--########################################################################################################################################################		
--USER_SCAN - PLAN CACHE
--########################################################################################################################################################		

--identificar as bases de dados com mais user_scans
select		db_name(database_id),
			max(user_scans) max_user_scan,
			avg(user_scans) avg_user_scan
from		sys.dm_db_index_usage_stats
group by	db_name(database_id)
order by	avg_user_scan desc

use Piciking
go

--verificar informacoes dos scans/indices
select		object_name(c.object_id) as [table],
			c.name  as [index],
			user_scans,
			user_seeks,
			case a.index_id
				when 1 then 'CLUSTERED'
				else 'NONCLUSTERED'
			end as type
from		sys.dm_db_index_usage_stats a
inner join	sys.indexes c
	on		c.object_id = a.object_id 
	and		c.index_id = a.index_id
	and		database_id = DB_ID('Picking')
order by	user_scans desc

--consutar planos no cache que fazem table scan, clustered index ou index scan
select		deqp.query_plan,
			dest.text
from		sys.dm_exec_query_stats deqs
cross apply sys.dm_exec_sql_text(deqs.sql_handle) dest
cross apply sys.dm_exec_query_plan(deqs.plan_handle) deqp
where		deqp.query_plan.exist('	declare namespace 
									qplan="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
									//qplan:RelOp[@LogicalOp="Index Scan"
									or @LogicalOp="Clustered Index Scan"
									or @LogicalOp="Table Scan"]')=1

--filtrar planos para um indice especifico, listado acima
select		deqp.query_plan,
			dest.text
from		sys.dm_exec_query_stats deqs
cross apply sys.dm_exec_sql_text(deqs.sql_handle) dest
cross apply sys.dm_exec_query_plan(deqs.plan_handle) deqp
where		deqp.query_plan.exist('	declare namespace 
									qplan="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
									//qplan:RelOp/qplan:IndexScan/qplan:Object[@Index="[PK__tb_bdcomum_pedid__693CA210]"]')=1

--filtrar planos para um indice especifico, listado acima, com informações de tempo de execução
select		deqp.query_plan,
			dest.text, 
			deqs.statement_start_offset, 
			deqs.statement_end_offset,
			deqs.creation_time, 
			deqs.last_execution_time,
			deqs.execution_count, 
			deqs.total_worker_time,
			deqs.last_worker_time, 
			deqs.min_worker_time,
			deqs.max_worker_time, 
			deqs.total_physical_reads,
			deqs.last_physical_reads, 
			deqs.min_physical_reads,
			deqs.max_physical_reads, 
			deqs.total_logical_writes,
			deqs.last_logical_writes, 
			deqs.min_logical_writes,
			deqs.max_logical_writes, 
			deqs.total_logical_reads,
			deqs.last_logical_reads, 
			deqs.min_logical_reads,
			deqs.max_logical_reads, 
			deqs.total_elapsed_time,
			deqs.last_elapsed_time, 
			deqs.min_elapsed_time,
			deqs.max_elapsed_time--, 
			--deqs.total_rows,
			--deqs.last_rows, 
			--deqs.min_rows,
			--deqs.max_rows
from		sys.dm_exec_query_stats deqs
cross apply sys.dm_exec_sql_text(deqs.sql_handle) dest
cross apply sys.dm_exec_query_plan(deqs.plan_handle) deqp
where		deqp.query_plan.exist('	declare namespace 
									qplan="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
									//qplan:RelOp[@LogicalOp="Index Scan"
									or @LogicalOp="Clustered Index Scan"
									or @LogicalOp="Table Scan"]/qplan:IndexScan/qplan:Object[@Index="[PK__tb_bdcomum_pedid__693CA210]"]')=1
order by	deqs.total_worker_time desc


--########################################################################################################################################################		
--USER_LOOKUPS
--########################################################################################################################################################		


--identificar as bases de dados com mais user_lookups
select		db_name(database_id),
			max(user_lookups) max_user_lookups,
			avg(user_lookups) avg_user_lookups
from		sys.dm_db_index_usage_stats
group by	db_name(database_id)
order by	avg_user_lookups desc


use Picking
go

--verificar informacoes dos lookups/indices
select		object_name(c.object_id) as [table],
			c.name  as [index],
			user_lookups,
			case a.index_id
				when 1 then 'CLUSTERED'
				else 'NONCLUSTERED'
			end as type
from		sys.dm_db_index_usage_stats a
inner join	sys.indexes c
	on		c.object_id = a.object_id 
	and		c.index_id = a.index_id
	and		database_id = DB_ID('Picking')
order by	user_lookups desc

--consutar planos no cache que fazem user_lookups
select		deqp.query_plan,
			dest.text, 
			deqs.statement_start_offset, 
			deqs.statement_end_offset,
			deqs.creation_time, 
			deqs.last_execution_time,
			deqs.execution_count, 
			deqs.total_worker_time,
			deqs.last_worker_time, 
			deqs.min_worker_time,
			deqs.max_worker_time, 
			deqs.total_physical_reads,
			deqs.last_physical_reads, 
			deqs.min_physical_reads,
			deqs.max_physical_reads, 
			deqs.total_logical_writes,
			deqs.last_logical_writes, 
			deqs.min_logical_writes,
			deqs.max_logical_writes, 
			deqs.total_logical_reads,
			deqs.last_logical_reads, 
			deqs.min_logical_reads,
			deqs.max_logical_reads, 
			deqs.total_elapsed_time,
			deqs.last_elapsed_time, 
			deqs.min_elapsed_time,
			deqs.max_elapsed_time--, 
			--deqs.total_rows,
			--deqs.last_rows, 
			--deqs.min_rows,
			--deqs.max_rows
from		sys.dm_exec_query_stats deqs
cross apply sys.dm_exec_sql_text(deqs.sql_handle) dest
cross apply sys.dm_exec_query_plan(deqs.plan_handle) deqp
where		deqp.query_plan.exist('	declare namespace 
									AWMI="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
									//AWMI:IndexScan[@Lookup]/AWMI:Object[@Index="[PK_T_PCK_PECA]"]')=1

use bdcomum_econect
go

--funcão para localização de scans de um indice específico
create function [dbo].[FindScans] 
(	
	@Index varchar(50)
)
returns table 
as
return 
(
	select 
				deqp.query_plan,
				dest.text,
				deqs.total_worker_time
	from		sys.dm_exec_query_stats deqs
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) dest
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) deqp
	where		deqp.query_plan.exist('	declare namespace 
										qplan="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
										//qplan:RelOp[@LogicalOp="Index Scan"
										or @LogicalOp="Clustered Index Scan"
										or @LogicalOp="Table Scan"]/qplan:IndexScan/qplan:Object[fn:lower-case(@Index)=fn:lower-case(sql:variable("@Index"))]')=1
)

--consultar um indice espefico que faz scan
select * from dbo.FindScans('[PK__tb_bdcomum_pedid__693CA210]')

use Picking
go

--funcão para localização de lookups de um indice específico
create function FindLookups 
(	
	@Index varchar(50) 
)
returns table 
as
return 
(
	select 
				deqp.query_plan,
				dest.text,
				deqs.total_worker_time
	from		sys.dm_exec_query_stats deqs
	CROSS APPLY sys.dm_exec_sql_text(sql_handle) dest
	CROSS APPLY sys.dm_exec_query_plan(plan_handle) deqp
	where		deqp.query_plan.exist('	declare namespace 
										AWMI="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
										//AWMI:IndexScan[@Lookup]/AWMI:Object[fn:lower-case(@Index)=fn:lower-case(sql:variable("@Index"))]')=1
)
GO

--consultar um indice espefico que faz lookup
select * from dbo.FindLookups('[PK_T_PCK_PECA]')

--#######################################################################################################################################################################################################

;WITH RingBuffer AS 
(	SELECT	CAST(dorb.record AS XML) AS xRecord, dorb.timestamp
	FROM sys.dm_os_ring_buffers AS dorb
	WHERE dorb.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR'
)
SELECT		xr.value('(ResourceMonitor/Notification)[1]', 'varchar(75)') AS RmNotification,
			xr.value('(ResourceMonitor/IndicatorsProcess)[1]','tinyint') AS IndicatorsProcess,
			xr.value('(ResourceMonitor/IndicatorsSystem)[1]','tinyint') AS IndicatorsSystem,
			DATEADD(ms, -1 * (dosi.ms_ticks - rb.timestamp), GETDATE()) AS RmDateTime,
			xr.value('(MemoryNode/TargetMemory)[1]','bigint') AS TargetMemory,
			xr.value('(MemoryNode/ReserveMemory)[1]','bigint') AS ReserveMemory,
			xr.value('(MemoryNode/CommittedMemory)[1]','bigint') AS CommitedMemory,
			xr.value('(MemoryNode/SharedMemory)[1]','bigint') AS SharedMemory,
			xr.value('(MemoryNode/PagesMemory)[1]','bigint') AS PagesMemory,
			xr.value('(MemoryRecord/MemoryUtilization)[1]','bigint') AS MemoryUtilization,
			xr.value('(MemoryRecord/TotalPhysicalMemory)[1]','bigint') AS TotalPhysicalMemory,
			xr.value('(MemoryRecord/AvailablePhysicalMemory)[1]','bigint') AS AvailablePhysicalMemory,
			xr.value('(MemoryRecord/TotalPageFile)[1]','bigint') AS TotalPageFile,
			xr.value('(MemoryRecord/AvailablePageFile)[1]','bigint') AS AvailablePageFile,
			xr.value('(MemoryRecord/TotalVirtualAddressSpace)[1]','bigint') AS TotalVirtualAddressSpace,
			xr.value('(MemoryRecord/AvailableVirtualAddressSpace)[1]','bigint') AS AvailableVirtualAddressSpace,
			xr.value('(MemoryRecord/AvailableExtendedVirtualAddressSpace)[1]','bigint') AS AvailableExtendedVirtualAddressSpace
FROM		RingBuffer AS rb
CROSS APPLY rb.xRecord.nodes('Record') record (xr)
CROSS JOIN	sys.dm_os_sys_info AS dosi
ORDER BY	RmDateTime DESC;

;with RingBuffer as 
(
	select	cast(dorb.record as xml) as xRecord, dorb.timestamp
	from	sys.dm_os_ring_buffers as dorb
	where	dorb.ring_buffer_type = 'RING_BUFFER_SCHEDULER_MONITOR'
)
select		
			xr.value('(SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]','tinyint') as ProcessUtilization,
			xr.value('(SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]','tinyint') as SystemIdle,
			xr.value('(SchedulerMonitorEvent/SystemHealth/UserModeTime)[1]','int') as UserModeTime,
			xr.value('(SchedulerMonitorEvent/SystemHealth/KernelModeTime)[1]','int') as KernelModeTime,
			xr.value('(SchedulerMonitorEvent/SystemHealth/PageFaults)[1]','smallint') as PageFaults,
			xr.value('(SchedulerMonitorEvent/SystemHealth/WorkingSetDelta)[1]','int') as WorkingSetDelta,
			xr.value('(SchedulerMonitorEvent/SystemHealth/MemoryUtilization)[1]','int') as MemoryUtilization,
			DATEADD(ms, -1 * (dosi.ms_ticks - rb.timestamp), GETDATE()) AS DateTime
from		RingBuffer as rb
cross apply	rb.xRecord.nodes('Record') record (xr)
cross join	sys.dm_os_sys_info dosi
order by	DateTime desc;

--#######################################################################################################################################################################################################

use master

select * from sys.sysprocesses where blocked <> 0
select * from sys.dm_tran_locks where session_id = 57
select * from sys.dm_exec_requests where session_id = 57
select * from sys.dm_os_waiting_tasks where session_id = 57

select		
			SUBSTRING(dest.[text], der.statement_start_offset / 2,
				( CASE WHEN der.statement_end_offset = -1
					   THEN LEN(CONVERT(NVARCHAR(MAX), dest.[text])) * 2
					   ELSE der.statement_end_offset
				  END - der.statement_start_offset ) / 2) AS [statement_executing]
				,*
from		sys.dm_exec_requests der
cross apply sys.dm_exec_sql_text (der.sql_handle) dest
cross apply sys.dm_exec_query_plan (der.plan_handle)
where		der.session_id = 57


--dbcc inpubuffer(190)
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
WHERE		er.session_id != @@SPID

--#######################################################################################################################################################################################################

use distribution
go

select		*
from		MSpublications p
inner join	MSarticles a
	on		p.publication_id = a.publication_id
where		a.article = ''

-- alterar caminho pasta default do snapshot
use distribution
go
exec	sp_changedistpublisher	@publisher = 'MSSDFISC', 
								@property = 'working_directory', 
								@value = 'E:\MSSQL\repldata'

--T:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\ReplData