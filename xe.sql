-- Apaga a sessão, caso ela já exista
IF ((SELECT COUNT(*) FROM sys.dm_xe_sessions WHERE [name] = 'query_lenta') > 0) DROP EVENT SESSION [query_lenta] ON SERVER 
GO

-- Cria o Extended Event no servidor, configurado para iniciar automaticamente quando o serviço do SQL é iniciado
CREATE EVENT SESSION [query_lenta] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed (
    ACTION (
        sqlserver.session_id,
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.database_id,
        sqlserver.session_nt_username,
        sqlserver.sql_text
    )
    WHERE
	      duration > (3000000) -- 3 segundos
		and	username <> 'VISANET\SRV_SQLAGT'
),
ADD EVENT sqlserver.sql_statement_completed (
    ACTION (
        sqlserver.session_id,
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.username,
        sqlserver.database_id,
        sqlserver.session_nt_username,
        sqlserver.sql_text
    )
    WHERE
			duration > (3000000) -- 3 segundos
		and	username <> 'VISANET\SRV_SQLAGT'
)
ADD TARGET package0.asynchronous_file_target (
    SET filename=N'B:\temp\XE\query_lenta.xel',
    max_file_size=(100),
    max_rollover_files=(1)
)
WITH (STARTUP_STATE=ON)
GO

-- Ativa o Extended Event
ALTER EVENT SESSION [query_lenta] ON SERVER STATE = START
GO


DROP EVENT SESSION [query_lenta] ON SERVER 
GO

------------------

/*
SELECT CONVERT(XML, event_data) AS event_data
FROM	sys.fn_xe_file_target_read_file(N'B:\temp\XE\query_lenta*.xel', NULL, NULL, NULL)
*/
    
DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())


IF (OBJECT_ID('tempdb..#Eventos') IS NOT NULL) DROP TABLE #Eventos
;WITH CTE AS (
    SELECT CONVERT(XML, event_data) AS event_data
    FROM sys.fn_xe_file_target_read_file(N'B:\temp\XE\query_lenta*.xel', NULL, NULL, NULL)
)
SELECT
    DATEADD(HOUR, @TimeZone, CTE.event_data.value('(//event/@timestamp)[1]', 'datetime')) AS Dt_Evento,
    CTE.event_data
INTO
    #Eventos
FROM
    CTE

    

SELECT
    A.Dt_Evento,
xed.event_data.value('(//action[@name="sql_text"]/value)[1]', 'varchar(max)')  AS sql_text,	
    xed.event_data.value('(action[@name="session_id"]/value)[1]', 'int') AS session_id,
    --xed.event_data.value('(action[@name="database_name"]/value)[1]', 'varchar(128)') AS [database_name],
    xed.event_data.value('(action[@name="username"]/value)[1]', 'varchar(128)') AS username,
    --xed.event_data.value('(action[@name="session_server_principal_name"]/value)[1]', 'varchar(128)') AS session_server_principal_name,
    --xed.event_data.value('(action[@name="session_nt_username"]/value)[1]', 'varchar(128)') AS [session_nt_username],
    xed.event_data.value('(action[@name="client_hostname"]/value)[1]', 'varchar(128)') AS [client_hostname],
    --xed.event_data.value('(action[@name="client_app_name"]/value)[1]', 'varchar(128)') AS [client_app_name],
    CAST(xed.event_data.value('(//data[@name="duration"]/value)[1]', 'bigint') / 1000000.0 AS NUMERIC(18, 2)) AS duration,
    CAST(xed.event_data.value('(//data[@name="cpu_time"]/value)[1]', 'bigint') / 1000000.0 AS NUMERIC(18, 2)) AS cpu_time,
    xed.event_data.value('(//data[@name="logical_reads"]/value)[1]', 'bigint') AS logical_reads,
    xed.event_data.value('(//data[@name="physical_reads"]/value)[1]', 'bigint') AS physical_reads,
    xed.event_data.value('(//data[@name="writes"]/value)[1]', 'bigint') AS writes,
    xed.event_data.value('(//data[@name="row_count"]/value)[1]', 'bigint') AS row_count,
	xed.event_data.value('(//action[@name="sql_text"]/value)[1]', 'varchar(max)')  AS sql_text,	
	xed.event_data.value('(//action[@name="statement"]/value)[1]', 'varchar(max)') AS statement,
    TRY_CAST(xed.event_data.value('(//action[@name="sql_text"]/value)[1]', 'varchar(max)') AS XML) AS sql_text,
    TRY_CAST(xed.event_data.value('(//data[@name="batch_text"]/value)[1]', 'varchar(max)') AS XML) AS batch_text,
    xed.event_data.value('(//data[@name="result"]/text)[1]', 'varchar(100)') AS result
FROM
    #Eventos A
    CROSS APPLY A.event_data.nodes('//event') AS xed (event_data)


