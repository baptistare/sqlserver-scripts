select * from sys.dm_server_memory_dumps

C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\LOG\SQLDump0001.mdmp

--#########################################################################################################################################################################
--TOTAL_WORKER_TIME
--#########################################################################################################################################################################

select		db_name(deqp.dbid) dbName, q.avg_workertime, q.execution_count, q.statement_text, deqp.query_plan
from		(
				SELECT		TOP 10 qs.query_hash AS query_hash,   
							SUM(qs.total_worker_time) / SUM(qs.execution_count) AS avg_workertime,  
							MIN(qs.execution_count) AS execution_count,
							MIN(qs.statement_text) AS statement_text,
							min(qs.plan_handle) AS plan_handle
				FROM		(
 


































							)	as qs  
				GROUP BY	qs.query_hash  
				ORDER BY	2 DESC
) q
cross apply		sys.dm_exec_query_plan(q.plan_handle) deqp

/*
SELECT		TOP 10 qs.query_hash AS query_hash,   
			SUM(qs.total_worker_time) / SUM(qs.execution_count) AS avg_workertime,  
			MIN(qs.execution_count) AS execution_count,
			MIN(qs.statement_text) AS statementtext,
			min(qs.plan_handle) AS plan_handle
FROM		(
				SELECT		deqs.*,
							SUBSTRING(dest.text,	(deqs.statement_start_offset/2) + 1,  
												(
								(
									CASE statement_end_offset   
								WHEN -1 THEN DATALENGTH(dest.text)  
								ELSE deqs.statement_end_offset 
							END   
							- deqs.statement_start_offset)/2) + 1) AS statement_text  
				FROM		sys.dm_exec_query_stats AS deqs  
				CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) as dest
				CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) as deqp
				where		1 = 1
				and			DATEDIFF(mi, deqs.last_execution_time,GETDATE()) <= 60
			)	as qs  
GROUP BY	qs.query_hash  
ORDER BY	2 DESC
*/

--#########################################################################################################################################################################
--TOTAL_ELAPSED_TIME
--#########################################################################################################################################################################

select		db_name(deqp.dbid) dbName, q.avg_elapsed_time, q.execution_count, q.statement_text, deqp.query_plan
from		(
				SELECT		TOP 10 qs.query_hash AS query_hash,   
							SUM(qs.total_elapsed_time) / SUM(qs.execution_count) AS avg_elapsed_time,  
							MIN(qs.execution_count) AS execution_count,
							MIN(qs.statement_text) AS statement_text,
							min(qs.plan_handle) AS plan_handle
				FROM		(
								SELECT		deqs.*,
											SUBSTRING(dest.text,	(
																		deqs.statement_start_offset/2) + 1,  
																		(
																			(
																				CASE statement_end_offset   
																				WHEN -1 THEN DATALENGTH(dest.text)  
																				ELSE deqs.statement_end_offset 
																				END   
																				- deqs.statement_start_offset
																			)/2
																		) + 1
																	) AS statement_text 
								FROM		sys.dm_exec_query_stats AS deqs  
								CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) as dest
								CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) as deqp
								where		1 = 1
								and			DATEDIFF(mi, deqs.last_execution_time,GETDATE()) <= 60
							)	as qs  
				GROUP BY	qs.query_hash  
				ORDER BY	2 DESC
) q
cross apply		sys.dm_exec_query_plan(q.plan_handle) deqp


--#########################################################################################################################################################################
--TOTAL_LOGICAL_READS
--#########################################################################################################################################################################

select		db_name(deqp.dbid) dbName, q.avg_logical_reads, q.execution_count, q.statement_text, deqp.query_plan
from		(
				SELECT		TOP 10 qs.query_hash AS query_hash,   
							SUM(qs.total_logical_reads) / SUM(qs.execution_count) AS avg_logical_reads,  
							MIN(qs.execution_count) AS execution_count,
							MIN(qs.statement_text) AS statement_text,
							min(qs.plan_handle) AS plan_handle
				FROM		(
								SELECT		deqs.*,
											SUBSTRING(dest.text,	(
																		deqs.statement_start_offset/2) + 1,  
																		(
																			(
																				CASE statement_end_offset   
																				WHEN -1 THEN DATALENGTH(dest.text)  
																				ELSE deqs.statement_end_offset 
																				END   
																				- deqs.statement_start_offset
																			)/2
																		) + 1
																	) AS statement_text 
								FROM		sys.dm_exec_query_stats AS deqs  
								CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) as dest
								CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) as deqp
								where		1 = 1
								and			DATEDIFF(mi, deqs.last_execution_time,GETDATE()) <= 60
							)	as qs  
				GROUP BY	qs.query_hash  
				ORDER BY	2 DESC
) q
cross apply		sys.dm_exec_query_plan(q.plan_handle) deqp

--#########################################################################################################################################################################
--TOTAL_PHYSICAL_READS
--#########################################################################################################################################################################

select		db_name(deqp.dbid) dbName, q.avg_physical_reads, q.execution_count, q.statement_text, deqp.query_plan
from		(
				SELECT		TOP 10 qs.query_hash AS query_hash,   
							SUM(qs.total_physical_reads) / SUM(qs.execution_count) AS avg_physical_reads,  
							MIN(qs.execution_count) AS execution_count,
							MIN(qs.statement_text) AS statement_text,
							min(qs.plan_handle) AS plan_handle
				FROM		(
								SELECT		deqs.*,
											SUBSTRING(dest.text,	(
																		deqs.statement_start_offset/2) + 1,  
																		(
																			(
																				CASE statement_end_offset   
																				WHEN -1 THEN DATALENGTH(dest.text)  
																				ELSE deqs.statement_end_offset 
																				END   
																				- deqs.statement_start_offset
																			)/2
																		) + 1
																	) AS statement_text 
								FROM		sys.dm_exec_query_stats AS deqs  
								CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) as dest
								CROSS APPLY sys.dm_exec_query_plan(deqs.plan_handle) as deqp
								where		1 = 1
								and			DATEDIFF(mi, deqs.last_execution_time,GETDATE()) <= 60
							)	as qs  
				GROUP BY	qs.query_hash  
				ORDER BY	2 DESC
) q
cross apply		sys.dm_exec_query_plan(q.plan_handle) deqp

