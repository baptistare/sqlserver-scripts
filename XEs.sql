-----------------------------------------------------------------------------------------------------------------------------------------------
MAX_MEMORY =size [ KB | MB ]
-----------------------------------------------------------------------------------------------------------------------------------------------
Especifica a quantidade máxima de memória a ser alocada à sessão para buffer de evento. 
O padrão é 4 MB. 

size é um número inteiro e pode ser um valor kilobyte (KB) ou megabyte (MB). 

A quantidade máxima não pode exceder 2 GB (menos de 2048 MB). No entanto, não é recomendável usar valores de memória na faixa de GB.

-----------------------------------------------------------------------------------------------------------------------------------------------
EVENT_RETENTION_MODE = { ALLOW_SINGLE_EVENT_LOSS | ALLOW_MULTIPLE_EVENT_LOSS | NO_EVENT_LOSS }
-----------------------------------------------------------------------------------------------------------------------------------------------
Especifica o modo de retenção do evento para usar em tratamento de perda de evento.

ALLOW_SINGLE_EVENT_LOSS Um evento pode ser perdido da sessão. Um único evento será descartado somente quando todos os buffers de evento estiverem cheios. 
A perda de um único evento quando os buffers de evento estão cheios permite características de desempenho do SQL Server aceitáveis, enquanto minimiza a perda 
de dados no fluxo de evento processado.

ALLOW_MULTIPLE_EVENT_LOSS Buffers de evento cheios que contêm vários eventos podem ser perdidos da sessão. O número de eventos perdidos depende do tamanho de 
memória alocado à sessão, do particionamento da memória e do tamanho dos eventos no buffer. 

Essa opção minimiza o impacto do desempenho no servidor quando buffers de evento são rapidamente enchidos, mas grandes números de eventos podem ser perdidos 
da sessão.

NO_EVENT_LOSS Nenhuma perda de evento é permitida. Essa opção assegura que todos os eventos gerados sejam retidos. 
O uso dessa opção força todas as tarefas que acionam eventos a esperar até que haja espaço disponível em um buffer de evento. 
Isso pode causar problemas de desempenho detectáveis enquanto a sessão de evento está ativa. 
As conexões de usuário poderão parar enquanto esperam a liberação de eventos do buffer.

-----------------------------------------------------------------------------------------------------------------------------------------------
MAX_DISPATCH_LATENCY = { seconds SECONDS | INFINITE }
-----------------------------------------------------------------------------------------------------------------------------------------------
Especifica a quantidade de tempo em que haverá buffer de eventos na memória antes que sejam enviados para destinos de sessão de evento. 
Por padrão, este valor é definido como 30 segundos.

segundos SECONDS O tempo, em segundos, a esperar antes de liberar buffers para os destinos. seconds é um número inteiro. 
O valor mínimo de latência é 1 segundo. No entanto, o valor 0 pode ser usado para especificar a latência INFINITE.

INFINITE Libera buffers para os destinos somente quando estiverem cheios ou quando a sessão de evento for fechada.

 Observação

MAX_DISPATCH_LATENCY = 0 SECONDS é equivalente a MAX_DISPATCH_LATENCY = INFINITE.

-----------------------------------------------------------------------------------------------------------------------------------------------
MAX_EVENT_SIZE =size [ KB | MB ]
-----------------------------------------------------------------------------------------------------------------------------------------------
Especifica o tamanho máximo permitido para eventos. MAX_EVENT_SIZE deverá ser definido apenas para permitir eventos únicos maiores que MAX_MEMORY; 
sua definição como menos que MAX_MEMORY irá gerar um erro. 

size é um número inteiro e pode ser um valor de KB (kilobyte) ou MB (megabyte). 
Se size for especificado em kilobytes, o tamanho mínimo permitido será de 64 KB. 

Quando MAX_EVENT_SIZE é definido, dois buffers de size são criados, além de MAX_MEMORY. 
Isso significa que a memória total usada para buffer de evento é MAX_MEMORY + 2 * MAX_EVENT_SIZE.

-----------------------------------------------------------------------------------------------------------------------------------------------
MEMORY_PARTITION_MODE = { NONE | PER_NODE | PER_CPU }
-----------------------------------------------------------------------------------------------------------------------------------------------
Especifica o local onde buffers de evento são criados.

NONE Um único conjunto de buffers é criado na instância SQL Server.

PER NODE Um conjunto de buffers é criado para cada nó NUMA.

PER CPU Um conjunto de buffers é criado para cada CPU.

-----------------------------------------------------------------------------------------------------------------------------------------------
TRACK_CAUSALITY = { ON | OFF }
-----------------------------------------------------------------------------------------------------------------------------------------------
Especifica se a causalidade deve ou não ser controlada. Se habilitada, a causalidade permitirá que eventos relacionados em conexões de servidor diferentes 
sejam correlacionados.

-----------------------------------------------------------------------------------------------------------------------------------------------
Links
-----------------------------------------------------------------------------------------------------------------------------------------------
--https://learn.microsoft.com/pt-br/sql/t-sql/statements/create-event-session-transact-sql?view=sql-server-ver16
--https://www.red-gate.com/simple-talk/databases/sql-server/database-administration-sql-server/extended-events-data-collection/

-----------------------------------------------------------------------------------------------------------------------------------------------
DMVs
-----------------------------------------------------------------------------------------------------------------------------------------------

select * from sys.dm_xe_map_values
select * from sys.dm_xe_object_columns
select * from sys.dm_xe_objects
select * from sys.dm_xe_packages
select * from sys.dm_xe_session_event_actions
select * from sys.dm_xe_session_events
select * from sys.dm_xe_session_object_columns
select * from sys.dm_xe_session_targets
select * from sys.dm_xe_sessions

-----------------------------------------------------------------------------------------------------------------------------------------------
slow_queries_XE
-----------------------------------------------------------------------------------------------------------------------------------------------

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='slow_queries_XE')
    DROP EVENT session [slow_queries_XE] ON SERVER;
GO
CREATE EVENT SESSION [slow_queries_XE] ON SERVER 
ADD EVENT sqlserver.rpc_completed
(	SET collect_data_stream=(1),collect_output_parameters=(1)
    ACTION	(sqlos.scheduler_id,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.num_response_rows,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed,sqlserver.server_principal_name,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE	(
					([package0].[greater_than_uint64]([sqlserver].[database_id],(4)))
				AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))
			)
),
ADD EVENT sqlserver.sp_statement_completed
(
	SET collect_object_name=(1),collect_statement=(1)
    ACTION	(sqlos.scheduler_id,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.num_response_rows,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed,sqlserver.server_principal_name,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE	(
					([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) 
				AND ([duration]>=(3000000))
			)
),
ADD EVENT sqlserver.sql_batch_completed
(
    ACTION	(sqlos.scheduler_id,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.num_response_rows,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed,sqlserver.server_principal_name,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE	(
					([package0].[greater_than_uint64]([sqlserver].[database_id],(4))) 
				AND ([package0].[equal_boolean]([sqlserver].[is_system],(0)))
			)
)
ADD TARGET package0.event_file (SET filename=N'C:\temp\XE\slow_queries_XE')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO


-----------------------------------------------------------------------------------------------------------------------------------------------
errors_XE
-----------------------------------------------------------------------------------------------------------------------------------------------

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='errors_XE')
    DROP EVENT session [errors_XE] ON SERVER;
GO
CREATE EVENT SESSION [errors_XE] ON SERVER 
ADD EVENT sqlserver.attention
(
    ACTION	(package0.event_sequence,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE	(
					([sqlserver].[client_hostname] like N'%WIN%') 
				AND ([sqlserver].[username]=N'usr_teste')
			)
),
ADD EVENT sqlserver.error_reported(
    ACTION	(package0.event_sequence,sqlos.task_time,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.nt_username,sqlserver.plan_handle,sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed,sqlserver.session_nt_username,sqlserver.sql_text,sqlserver.username)
    WHERE	(
					([sqlserver].[client_hostname] like N'%WIN%') 
				AND ([sqlserver].[username]=N'usr_teste'))
			)
ADD TARGET package0.event_file (SET filename=N'C:\temp\XE\errors_XE.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO




-----------------------------------------------------------------------------------------------------------------------------------------------
blocks
-----------------------------------------------------------------------------------------------------------------------------------------------

EXECUTE sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
EXECUTE sp_configure 'blocked process threshold', 15;
GO
RECONFIGURE;
GO
EXECUTE sp_configure 'show advanced options', 0;
GO
RECONFIGURE;
GO

IF EXISTS ( SELECT 1 FROM sys.server_event_sessions WHERE name = 'blocks_XE' )
DROP EVENT SESSION [blocks_XE] ON SERVER;
GO
 
CREATE EVENT SESSION [blocks_XE] ON SERVER 
ADD EVENT sqlserver.blocked_process_report(
    ACTION(package0.event_sequence,sqlserver.database_name))
ADD TARGET package0.event_file(SET filename=N'C:\Temp\XE\blocks_XE')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO
--WITH (EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,TRACK_CAUSALITY=OFF)

--
ALTER EVENT SESSION [blocks_XE] ON SERVER 
DROP EVENT sqlserver.blocked_process_report
ALTER EVENT SESSION [blocks_XE] ON SERVER 
ADD EVENT sqlserver.blocked_process_report(
    ACTION(package0.event_sequence,sqlos.task_time,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.sql_text,sqlserver.username))
GO


/*
stop the event session
*/
ALTER EVENT SESSION [blocks_XE]
ON SERVER
STATE = STOP;
GO
 
/*
drop the event session
*/
DROP EVENT SESSION [blocks_XE]
ON SERVER;
GO


-----------------------------------------------------------------------------------------------------------------------------------------------
deadlocks
-----------------------------------------------------------------------------------------------------------------------------------------------

IF EXISTS ( SELECT 1 FROM sys.server_event_sessions WHERE name = 'deadlock_XE' )
DROP EVENT SESSION [deadlock_XE] ON SERVER;
GO
CREATE EVENT SESSION [deadlock_XE] ON SERVER 
ADD EVENT sqlserver.lock_deadlock
(
	SET collect_database_name=(1),collect_resource_description=(1)
    ACTION 	(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.plan_handle,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed,sqlserver.sql_text,sqlserver.username)
)
ADD TARGET package0.event_file (SET filename=N'C:\Temp\XE\deadlock_XE')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO
--WITH (EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,TRACK_CAUSALITY=ON)

--read
DECLARE  @xel_filename varchar(256)
        ,@mta_filename varchar(256)
SET @xel_filename = N'C:\Temp\XE\deadlock_XE*.xel'
--SET @mta_filename = N'C:\Temp\XE\deadlock_XE*.mta'
SELECT CONVERT (xml, [event_data]) AS [Event Data]
FROM [sys].[fn_xe_file_target_read_file](@xel_filename
                                        ,@mta_filename
                                        ,NULL
                                        ,NULL)


-----------------------------------------------------------------------------------------------------------------------------------------------
quantidade execucao query
-----------------------------------------------------------------------------------------------------------------------------------------------

CREATE EVENT SESSION [qtd_exec_query] ON SERVER 
ADD EVENT sqlserver.sp_statement_completed(SET collect_statement=(1)
    ACTION(sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed,sqlserver.sql_text)
    WHERE ([package0].[equal_int64]([sqlserver].[query_hash_signed],(-5029595812300407934.)))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed)
    WHERE ([package0].[equal_int64]([sqlserver].[query_hash_signed],(-5029595812300407934.)))),
ADD EVENT sqlserver.sql_statement_completed(SET collect_statement=(1)
    ACTION(sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.query_plan_hash,sqlserver.query_plan_hash_signed)
    WHERE ([package0].[equal_int64]([sqlserver].[query_hash_signed],(-5029595812300407934.))))
ADD TARGET package0.event_file(SET filename=N'C:\temp\query_qtd.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)

-----------------------------------------------------------------------------------------------------------------------------------------------
Exemplos
-----------------------------------------------------------------------------------------------------------------------------------------------

-- Start the event session ( STATE = { START | STOP } )
ALTER EVENT SESSION test_session ON SERVER  
STATE = start;  
GO  

--Delete event session
DROP EVENT SESSION test_session ON SERVER;
GO

-- Obtain live session statistics   
SELECT * FROM sys.dm_xe_sessions;  
SELECT * FROM sys.dm_xe_session_events;  
GO  
  
-- Add new events to the session  
ALTER EVENT SESSION test_session ON SERVER  
ADD EVENT sqlserver.database_transaction_begin,  
ADD EVENT sqlserver.database_transaction_end;  
GO  

-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
