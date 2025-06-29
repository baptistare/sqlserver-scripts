--###############################################################################################################################################################
--BLOCKS, LOCKS
--###############################################################################################################################################################

use master
go

select * from sys.sysprocesses where blocked <> 0;
select * from sys.dm_exec_sessions where session_id = 57;
select * from sys.dm_exec_requests where session_id = 57;
select * from sys.dm_os_waiting_tasks where session_id = 57;
select * from sys.dm_tran_locks where request_session_id = 57;

--dbcc inpubuffer(57)

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

use master
go

select db_name(38),* from sys.dm_tran_locks where request_session_id = 114;
select db_name(38),* from sys.dm_tran_locks where request_session_id = 122;
go

use dbTestes
go
select 
			db_name(dtl.resource_database_id) as database_name,
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
inner join	sys.partitions p
	on		p.hobt_id = dtl.resource_associated_entity_id
	or		p.object_id = dtl.resource_associated_entity_id
inner join	sys.indexes i
	on		i.object_id = p.object_id 
	and		i.index_id = p.index_id
--where		db_name(dtl.resource_database_id)='dbName'
where		dtl.request_session_id in (114,122)
order by	dtl.request_session_id	


--###############################################################################################################################################################
--LATENCIA DE DISCO
--###############################################################################################################################################################

use master
go

SELECT		DB_NAME(vfs.database_id) AS databaseName,
			vfs.file_id,
			CAST(vfs.io_stall_read_ms / (1.0 + vfs.num_of_reads) AS NUMERIC(5,2)) AS avg_read_latency_ms,
			CAST(vfs.io_stall_write_ms / (1.0 + vfs.num_of_writes ) AS NUMERIC(5,2)) AS avg_write_latency_ms,
			CAST((vfs.io_stall_read_ms + vfs.io_stall_write_ms ) / (1.0 + vfs.num_of_reads + vfs.num_of_writes) AS NUMERIC(5,2)) AS avg_io_latency_ms,
			CASE WHEN vfs.num_of_reads = 0 THEN 0 ELSE vfs.num_of_bytes_read / vfs.num_of_reads END AS avg_bytes_per_read,
			CASE WHEN vfs.num_of_writes = 0 THEN 0 ELSE vfs.num_of_bytes_written / vfs.num_of_writes END AS avg_bytes_per_write,
			CASE WHEN vfs.num_of_reads = 0 AND vfs.num_of_writes = 0 THEN 0 ELSE ((vfs.num_of_bytes_read + vfs.num_of_bytes_written) / (vfs.num_of_reads + vfs.num_of_writes)) END AS avg_bytes_per_io,
			vfs.io_stall_read_ms,
			vfs.num_of_reads,
			vfs.io_stall_write_ms,
			vfs.num_of_writes,
			vfs.io_stall_read_ms + vfs.io_stall_write_ms AS total_io_stalls,
			vfs.num_of_reads + vfs.num_of_writes AS total_io,
			mf.physical_name
FROM		sys.dm_io_virtual_file_stats (null,null) AS vfs
JOIN		sys.master_files AS mf
    ON		vfs.database_id = mf.database_id
    AND		vfs.file_id = mf.file_id
--WHERE		vfs.file_id = 1
--WHERE		vfs.file_id = 2
ORDER BY	avg_read_latency_ms DESC;
--ORDER BY	avg_write_latency_ms DESC;
--ORDER BY	avg_io_latency_ms DESC;
--ORDER BY	avg_bytes_per_read DESC;
--ORDER BY	avg_bytes_per_write DESC;
--ORDER BY	avg_bytes_per_io DESC;


--###############################################################################################################################################################
--BLOCKS, LOCKS
--###############################################################################################################################################################