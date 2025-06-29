-----------------------------------------------------------------------------------------------------------------------------------------------
--Verificar se o Lock Escalation esta ativado em uma determinada tabela 
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT name, lock_escalation, lock_escalation_desc, * FROM sys.tables WHERE name = 'ENVIO_EMAIL'

/*
lock_escalation 
The value of the LOCK_ESCALATION option for the table:
0 = TABLE
1 = DISABLE
2 = AUTO
*/

SELECT  s.name as schemaname, object_name (t.object_id) as table_name, t.lock_escalation_desc
FROM    sys.tables t, sys.schemas s
WHERE   object_name(t.object_id) = 'ENVIO_EMAIL' 
and     s.name = 'dbo' 
and     s.schema_id = t.schema_id 

SELECT  s.name as schemaname, object_name (t.object_id) as table_name, t.lock_escalation_desc
FROM    sys.tables t
JOIN    sys.schemas s on t.schema_id = s.schema_id
WHERE   object_name(t.object_id) = 'ENVIO_EMAIL' 
and     s.name = 'dbo' 
and     s.schema_id = t.schema_id 

-----------------------------------------------------------------------------------------------------------------------------------------------
--Desabilitar o Lock Escalation de uma tabela (SQL gasta 86 bytes por lock/linha) - (LOCK_ESCALATION = { AUTO | TABLE | DISABLE })
-----------------------------------------------------------------------------------------------------------------------------------------------
ALTER TABLE ENVIO_EMAIL SET ( LOCK_ESCALATION = DISABLE )

-----------------------------------------------------------------------------------------------------------------------------------------------
--Script para montar os comandos de rebuild do índice de uma determinada tabela, alterando a opção ALLOW_PAGE_LOCKS
-----------------------------------------------------------------------------------------------------------------------------------------------

SELECT  so.name AS TableName,
        si.name AS IndexName,
        si.type_desc AS IndexType,
        si.is_disabled,
        si.allow_row_locks,
        si.allow_page_locks,
        CAST((sum(a.used_pages)*8) / 1024.00 / 1024.00 AS NUMERIC (4, 2)) IndexSizeGB,
        'ALTER INDEX [' + si.name + '] ON [dbo].[' + so.name + '] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )' AS Command
FROM    sys.indexes si
JOIN    sys.objects so ON si.[object_id] = so.[object_id]
JOIN    sys.partitions AS p ON p.OBJECT_ID = si.OBJECT_ID AND p.index_id = si.index_id
JOIN    sys.allocation_units AS a ON a.container_id = p.partition_id
WHERE   so.name = 'Orders'
GROUP BY so.name, si.name, si.type_desc, si.type, si.is_disabled, si.allow_row_locks, si.allow_page_locks
ORDER BY IndexSizeGB, so.name, si.type

-----------------------------------------------------------------------------------------------------------------------------------------------
--Validar se os indices estão com ALLOW_PAGE_LOCKS desativados e demais informações
-----------------------------------------------------------------------------------------------------------------------------------------------

SELECT    SCHEMA_NAME(o.SCHEMA_ID) SchemaName,
      o.name ObjectName,
      i.name IndexName,
      i.type_desc,
      i.allow_row_locks,
      i.allow_page_locks,
      LEFT(list, ISNULL(splitter-1, LEN(list)))Columns,
      SUBSTRING(list, indCol.splitter+1, 1000) includedColumns, --len(name) - splitter-1) columns
      script_create_suggested = 'CREATE ' + i.type_desc + ' INDEX ' + i.name + ' ON [' + DB_NAME() + '].' + SCHEMA_NAME (o.schema_id) + '.' + o.name +
        '( ' + LEFT(list, ISNULL(splitter-1, LEN(list))) + ' )' + ISNULL(' INCLUDE ( ' + SUBSTRING(list, indCol.splitter+1, 1000) + ' )','') +
        ' WITH (DROP_EXISTING = ON, FILLFACTOR = 97 )' COLLATE Latin1_General_CI_AI
FROM    sys.indexes AS i
JOIN    sys.objects AS o ON i.object_id= o.object_id
CROSS APPLY (
        SELECT NULLIF(CHARINDEX('|',indexCols.list),0) splitter , list
        FROM (
            SELECT CAST((SELECT CASE WHEN sc.is_included_column = 1 AND sc.ColPos= 1 THEN '|' ELSE '' END + CASE WHEN sc.ColPos > 1 THEN ', ' ELSE '' END + name
            FROM (
                SELECT  sc.is_included_column, index_column_id, name, ROW_NUMBER() OVER (PARTITION BY sc.is_included_column ORDER BY sc.index_column_id) ColPos
                FROM  sys.index_columns AS sc
                JOIN  sys.columns AS c ON sc.object_id= c.object_id AND sc.column_id = c.column_id
                WHERE 1 = 1
                and   sc.index_id= i.index_id
                AND   sc.object_id= i.object_id
                ) sc
            ORDER BY sc.is_included_column, ColPos
            FOR XML PATH (''), TYPE) AS VARCHAR(MAX)) list) indexCols
      ) indCol
WHERE 1=1
--AND indCol.splitter is not null -- defina se vai trazer os indices com ou sem include
AND o.name = 'SL1010'--tabela
ORDER BY SchemaName, ObjectName, IndexName

--FALTA COLOCAR AS PROPRIEDADES DOS INDECES COMO LOCK_ROW

-----------------------------------------------------------------------------------------------------------------------------------------------
--analise Log_Whoisactive
-----------------------------------------------------------------------------------------------------------------------------------------------
use master
go
select * from sys.databases

use dts_tools
go
select * from sys.tables where name like '%who%'

select top 3 * from Log_Whoisactive
select min(dt_log) from Log_Whoisactive
sp_spaceused Log_Whoisactive--55502               

--verificar horários blocks
select    top 100 *
from      Log_Whoisactive with (nolock)
where     1 = 1
  and     Dt_Log >= '20221010' and Dt_Log < '20221011'
  and     blocking_session_id is not null
  and     database_name not in ('dts_tools')
order by  Dt_Log

--verificar período específico de blocks
select    Dt_Log,[dd hh:mm:ss.mss],database_name,session_id,blocking_session_id,sql_text, query_plan,locks,additional_info, open_tran_count,wait_info,login_name,status,percent_complete,sql_command,CPU,CPU_delta,reads,reads_delta,writes,used_memory,host_name,program_name 
from      Log_Whoisactive with (nolock)
where     1 = 1
  and     Dt_Log >= '20221010 12:30' and Dt_Log < '20221010 12:31'
  --and   blocking_session_id is not null
  --and   database_name not in ('dts_tools')
order by  Dt_Log

-----------------------------------------------------------------------------------------------------------------------------------------------
--links
-----------------------------------------------------------------------------------------------------------------------------------------------
--https://learn.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms184286(v=sql.105)?redirectedfrom=MSDN
--https://sqlmaestros.com/sql-server-lock-escalation-explained/
--https://learn.microsoft.com/en-us/troubleshoot/sql/performance/resolve-blocking-problems-caused-lock-escalation
--https://social.technet.microsoft.com/wiki/contents/articles/19870.sql-server-understanding-lock-escalation.aspx

-----------------------------------------------------------------------------------------------------------------------------------------------
--check index stats
-----------------------------------------------------------------------------------------------------------------------------------------------
dbcc show_statistics ('PERFIL_JOGO_TRILHA', 'IX_PerfilJogoTrilha_TrilhaID_ClienteID_UsuarioID_PerfilJogoIdDESC')

-----------------------------------------------------------------------------------------------------------------------------------------------
--check index fragmentation
-----------------------------------------------------------------------------------------------------------------------------------------------
--database_id, object_id, index_id, partition_number, mode
select    object_name(a.object_id),b.name,a.avg_fragmentation_in_percent,a.*
from    sys.dm_db_index_physical_stats(db_id(),1876201734,7,null,null) a
join    sys.indexes b 
  on    a.object_id = b.object_id 
  and   a.index_id = b.index_id
  and   a.page_count > 20
  and   a.index_id > 0  
order by  object_name(b.object_id), b.index_id

--localizar nome job
select * from msdb..sysjobs where job_id = 0xFFAF821A9D0F25449F786562AA4FA3E8
select js.* from msdb..sysjobs j join msdb..sysjobsteps js on j.job_id = js.job_id where j.job_id = 0xFFAF821A9D0F25449F786562AA4FA3E8

--localizar index_id
select i.index_id, * from sys.tables t join sys.indexes i on t.object_id = i.object_id where t.name ='PERFIL_JOGO_TRILHA' and i.name ='IX_PerfilJogoTrilha_TrilhaID_ClienteID_UsuarioID_PerfilJogoIdDESC'

sp_helptext engagesp_ProcessAutomaticEmails

-----------------------------------------------------------------------------------------------------------------------------------------------
--DM_OS_MEMORY_CLERKS (OBJECTSTORE_LOCK_MANAGER)
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP (50) mc.[type] AS [Memory Clerk Type], CAST((SUM(mc.pages_kb) / 1024.0) AS DECIMAL(15, 2)) AS [Memory Usage (MB)]
FROM sys.dm_os_memory_clerks AS mc WITH (NOLOCK)
GROUP BY mc.[type]
ORDER BY SUM(mc.pages_kb) DESC;

obs.: Antes de desabilitar o lock_escalation da tabela, verificar o consumo atual do Lock Manager, assim como utilização de memória no geral (PLE,)

-----------------------------------------------------------------------------------------------------------------------------------------------
--XE
-----------------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS ( SELECT 1 FROM sys.server_event_sessions WHERE name = 'lock_scalation_XE' )
DROP EVENT SESSION [lock_scalation_XE] ON SERVER;
GO
CREATE EVENT SESSION [lock_scalation_XE] ON SERVER 
ADD EVENT sqlserver.lock_escalation(SET collect_database_name=(1),collect_statement=(1)
    ACTION(package0.event_sequence,sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.execution_plan_guid,sqlserver.query_hash,sqlserver.query_hash_signed,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
ADD TARGET package0.event_file(SET filename=N'C:\Temp\XE\lock_scalation_XE')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_MULTIPLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)
GO


--object lock exclusive 
select * from sys.dm_tran_locks
select * from sys.dm_tran_locks where request_session_id = 67


DELETE FROM LogMessages WHERE LogDate < '20020102';

--change by

DECLARE @done bit = 0;
WHILE (@done = 0)
BEGIN
    DELETE TOP(1000) FROM LogMessages WHERE LogDate < '20020102';
    IF @@rowcount < 1000 SET @done = 1;
END;









-----------------------------------------------------------------------------------------------------------------------------------------------
--ações após validação cliente
-----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE ENVIO_EMAIL SET ( LOCK_ESCALATION = DISABLE )

ALTER INDEX [ix_dts_envio_email_14092022] ON [dbo].[ENVIO_EMAIL] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )
ALTER INDEX [IX_ENVIOEMAIL_DTS220984] ON [dbo].[ENVIO_EMAIL] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )
ALTER INDEX [DTS_ENVIO_EMAIL] ON [dbo].[ENVIO_EMAIL] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )
ALTER INDEX [IDX_ENVIO_EMAIL_20220804] ON [dbo].[ENVIO_EMAIL] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )
ALTER INDEX [IX_EnvioEmail_TentativaId_ClienteId_DTS215811] ON [dbo].[ENVIO_EMAIL] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )
ALTER INDEX [DTS_ENVIO_EMAIL_ID_CLIENTE_ID_STATUS_C6D8D] ON [dbo].[ENVIO_EMAIL] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )
ALTER INDEX [IX_EnvioEmail_UsuarioId_ClienteId] ON [dbo].[ENVIO_EMAIL] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )
ALTER INDEX [PK_ENVIOEMAIL] ON [dbo].[ENVIO_EMAIL] REBUILD WITH (ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, FILLFACTOR=97 )

