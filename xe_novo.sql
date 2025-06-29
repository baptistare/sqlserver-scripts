-- Apaga a sessão, caso ela já exista
IF ((SELECT COUNT(*) FROM sys.dm_xe_sessions WHERE [name] = 'querys') > 0) DROP EVENT SESSION [querys] ON SERVER 
GO

-- Cria o Extended Event no servidor, configurado para iniciar automaticamente quando o serviço do SQL é iniciado
CREATE EVENT SESSION [querys] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed (
    ACTION (
        sqlserver.session_id,
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.database_id,
        sqlserver.session_nt_username,
        sqlserver.sql_text,
		sqlserver.plan_handle
    )
    WHERE
	      duration > (100000) -- 100 ms
		and	sqlserver.session_id > 50
),
ADD EVENT sqlserver.sql_statement_completed (
    ACTION (
        sqlserver.session_id,
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.database_id,
        sqlserver.session_nt_username,
        sqlserver.sql_text,
		sqlserver.plan_handle
    )
    WHERE
			duration > (100000) -- 100 ms
		and	sqlserver.session_id > 50
)
ADD TARGET package0.asynchronous_file_target (
    SET filename=N'C:\temp\XE\querys.xel',
    max_file_size=(100),
    max_rollover_files=(10)
)
--WITH (STARTUP_STATE=ON)
GO

-- Ativa o Extended Event
ALTER EVENT SESSION [querys] ON SERVER STATE = START
GO


DROP EVENT SESSION [querys] ON SERVER 
GO

--#################################################################################


/*

SELECT
     obj1.name as [XEvent-name],
     col2.name as [XEvent-column],
     obj1.description as [Descr-name],
     col2.description as [Descr-column]
  FROM
               sys.dm_xe_objects        as obj1
      JOIN sys.dm_xe_object_columns as col2 on col2.object_name = obj1.name
  ORDER BY
    obj1.name,
    col2.nameDDB02

select count(*)
select top 3 *

SELECT CONVERT(XML, event_data) AS event_data
FROM	sys.fn_xe_file_target_read_file(N'C:\temp\XE\querys*.xel', NULL, NULL, NULL)
*/
    
DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())


IF (OBJECT_ID('tempdb..#Eventos') IS NOT NULL) DROP TABLE #Eventos
;WITH CTE AS (
    SELECT CONVERT(XML, event_data) AS event_data
    FROM sys.fn_xe_file_target_read_file(N'C:\temp\XE\querys*.xel', NULL, NULL, NULL)
)
SELECT
    DATEADD(HOUR, @TimeZone, CTE.event_data.value('(//event/@timestamp)[1]', 'datetime')) AS Dt_Evento,
    CTE.event_data
INTO
    #Eventos
FROM
    CTE
   

SELECT top 10
    A.Dt_Evento,
	cast(A.event_data as xml) AS event_data,
xed.event_data.value('(//action[@name="sql_text"]/value)[1]', 'varchar(max)')  AS sql_text,	
    xed.event_data.value('(action[@name="session_id"]/value)[1]', 'int') AS session_id,
    --xed.event_data.value('(action[@name="database_name"]/value)[1]', 'varchar(128)') AS [database_name],
    xed.event_data.value('(action[@name="username"]/value)[1]', 'varchar(128)') AS username,
    --xed.event_data.value('(action[@name="session_server_principal_name"]/value)[1]', 'varchar(128)') AS session_server_principal_name,
    --xed.event_data.value('(action[@name="session_nt_username"]/value)[1]', 'varchar(128)') AS [session_nt_username],
    xed.event_data.value('(action[@name="client_hostname"]/value)[1]', 'varchar(128)') AS [client_hostname],
    xed.event_data.value('(action[@name="client_app_name"]/value)[1]', 'varchar(128)') AS [client_app_name],
    CAST(xed.event_data.value('(//data[@name="duration"]/value)[1]', 'bigint') / 1000.0 AS NUMERIC(18, 2)) AS duration_in_ms,
    CAST(xed.event_data.value('(//data[@name="duration"]/value)[1]', 'bigint') / 1000000.0 AS NUMERIC(18, 2)) AS duration_in_sec,
    CAST(xed.event_data.value('(//data[@name="cpu_time"]/value)[1]', 'bigint') / 1000000.0 AS NUMERIC(18, 2)) AS cpu_time,
    xed.event_data.value('(//data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads,
    xed.event_data.value('(//data[@name="physical_reads"]/value)[1]', 'bigint') AS physical_reads,
    xed.event_data.value('(//data[@name="writes"]/value)[1]', 'bigint') AS writes,
    xed.event_data.value('(//data[@name="row_count"]/value)[1]', 'bigint') AS row_count,
	--xed.event_data.value('(//action[@name="sql_text"]/value)[1]', 'varchar(max)')  AS sql_text,	
	xed.event_data.value('(//action[@name="plan_handle"]/value)[1]', 'varchar(max)')  AS plan_handle,	
	xed.event_data.value('(//data[@name="offset"]/value)[1]', 'bigint') AS offset,
	xed.event_data.value('(//data[@name="offset_end"]/value)[1]', 'bigint') AS offset_end
	--xed.event_data.value('(//action[@name="statement"]/value)[1]', 'varchar(max)') AS statement,
	--xed.event_data.value('(//data[@name="statement"]/value)[1]', 'varchar(max)') AS statement,
    --TRY_CAST(xed.event_data.value('(//action[@name="sql_text"]/value)[1]', 'varchar(max)') AS XML) AS sql_text,
    --TRY_CAST(xed.event_data.value('(//data[@name="batch_text"]/value)[1]', 'varchar(max)') AS XML) AS batch_text,
    --xed.event_data.value('(//data[@name="result"]/text)[1]', 'varchar(100)') AS result
FROM
    #Eventos A
    CROSS APPLY A.event_data.nodes('//event') AS xed (event_data)



--############################################################################
--############################################################################

	create event session waits
on server
add event sqlos.wait_info
            (action 
(sqlserver.session_id,  package0.collect_system_time, package0.collect_cpu_cycle_time, sqlos.task_address, sqlos.worker_address)
       where sqlserver.session_id > 50)
--
--          async file, read with: sys.fn_xe_file_target_read_file
--
 ADD TARGET package0.asynchronous_file_target
(SET filename = N'C:\temp\XE\wait.etx', metadatafile = N'C:\temp\XE\wait.mta',
                        max_file_size = 100, max_rollover_files = 10) 
            WITH (max_dispatch_latency = 2 seconds)
go

alter event session waits on server state = start
go

DROP EVENT SESSION waits ON SERVER 
GO
--------------------------------------------

drop table #xTable

CREATE TABLE #xTable 
    ( 
      xTable_ID INT IDENTITY 
                    PRIMARY KEY, 
      xCol XML 
    ) ; 
 
INSERT  INTO #xTable ( xCol ) 
select cast(event_data as xml) waitinfo from sys.fn_xe_file_target_read_file
('c:\temp\XE\wait_*.etx',
'c:\temp\XE\wait_*.mta',
null,null)

-------
drop table #mywaits

SELECT  
-- for some reason wait type name is not logged with synch target. bug?
(select map_value from sys.dm_xe_map_values 
    where name = 'wait_types' 
        and map_key = xCol.value('(event/data/value)[1]', 'int') 
)AS wtype,
     xCol.value('(event/data/value)[3]', 'int')  --wait time
                                    AS tottime,
     xCol.value('(event/data/value)[6]', 'int') --sig wait time
                                    AS sigtime	
     into #mywaits    
FROM    #xTable 
where xCol.value('(/event/@name)[1]', 'varchar(30)') = 'wait_info'      
 and xCol.value('(event/data/value)[2]', 'int') = 1 --opcode end          
 
select  
		wtype, 
        count(*) as wcount, 
        sum(tottime) as total_time, 
        sum(sigtime) as signal_time 
        from #mywaits group by wtype
go
