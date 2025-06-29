
-----------------------------------------------------------------------------------------------------------------------------------------------
Parâmetros da procedure:
-----------------------------------------------------------------------------------------------------------------------------------------------

@Top = Até quantas queries irá trazer;

@TopBy = As Top queries serão por qual tipo de recurso? As opções são:

Duration;
CPU;
Logical Reads;
Physical Reads;
Memory Grant;
Possible Timeouts;

@DataInicio = Qual a data início? Este campo é do tipo Date.

@DataFim = Qual a data fim? Este campo é do tipo Date.

@TimeInicio = Qual o horário permitido? Por exemplo queries que começaram a executar a partir de 09 da manhã. @TimeInicio = '09:00'

@TimeFim = Qual o horário permitido? Por exemplo queries que terminaram de executar até 22:00 da noite. @TimeFim = '22:00'

@DatabasesSeparadasPorVirgula = 'ALL' para todas as bases, caso seja necessário passar mais de uma, adicionar por virgula. Ex: 'Traces,DTS_TOOLS'

@OutputTable = Para salvar o output em uma tabela

-----------------------------------------------------------------------------------------------------------------------------------------------


EXEC SP_TOP_QUERY_STORE     @Top = 10
                        ,   @TopBy = 'CPU'
                        ,   @DataInicio = '20221017'
                        ,   @DataFim = '20221017'
                        ,   @TimeInicio = '09:00'
                        ,   @TimeFim = '18:00'
                        ,   @DatabasesSeparadasPorVirgula = 'ALL'
                        --,   @OutputTable = 'QsTopQueries'

SELECT * FROM QsTopQueries

    
-----------------------------------------------------------------------------------------------------------------------------------------------

--- Executar sempre na master
USE master
GO


CREATE OR ALTER PROC SP_TOP_QUERY_STORE
(
    @Top BIGINT
,   @TopBy VARCHAR (100)
,   @DataInicio DATE
,   @DataFim DATE
,   @TimeInicio varchar(100) = '00:00'
,   @TimeFim varchar(100) = '23:59:59'
,   @DatabasesSeparadasPorVirgula VARCHAR(MAX) = 'ALL'
,   @OutputTable VARCHAR(100) = NULL
)
AS

--DECLARE
--    @Top                          BIGINT
--,   @TopBy                        VARCHAR (100)
--,   @DataInicio                  DATETIME
--,   @DataFim                     DATETIME
--,   @DatabasesSeparadasPorVirgula VARCHAR (MAX) = 'ALL'
--,   @OutputTable                  VARCHAR (100) = NULL;

--SELECT
--    @Top = 10
--,   @TopBy = 'Possible Timeouts'
--, @DataInicio = '20221017 00:00'
--, @DataFim = '20221017 21:45'
--,   @DatabasesSeparadasPorVirgula = 'dbpcpfri'
--,   @OutputTable = 'QsTopQueries';

--DECLARE  @DatabasesSeparadasPorVirgula VARCHAR(MAX) = 'dbpcpfri'



DROP TABLE IF EXISTS #DBS;

SELECT
    [value] AS db
INTO
    #DBS
FROM
    STRING_SPLIT(@DatabasesSeparadasPorVirgula, ',');

DECLARE @Info VARCHAR (4000) = '';

SELECT
    @Info = 'O Querystore está desabilitado na(s) base(s): ' + STUFF(DBS, 1, 1, '')
FROM
(
    SELECT
        ',' + name
    FROM
        sys.databases a
    WHERE
        is_query_store_on = 0
        AND database_id > 4
        AND
        (
            EXISTS
    (
        SELECT
            *
        FROM
            #DBS b
        WHERE
            a.name = b.db
    )
            OR @DatabasesSeparadasPorVirgula = 'ALL'
        )
    FOR XML PATH('')
) TAB1(DBS);

IF @Info <> ''
    BEGIN
        SELECT
            Info = @Info;
    END;

IF @TopBy NOT IN ( 'Duration', 'CPU', 'Logical Reads', 'Physical Reads', 'Memory Grant', 'Possible Timeouts' )
    BEGIN
        RAISERROR(
                     'As opções de agregação são: Duration, CPU, Logical Reads, Physical Reads, Memory Grant, Possible Timeouts'
                 ,   16
                 ,   1
                 );

        RETURN;
    END;

EXEC ( '
CREATE OR ALTER FUNCTION dbo.fn_QueryTextToXML(@Query VARCHAR(MAX))
RETURNS XML
AS
BEGIN
  DECLARE @XML XML
  SELECT @XML = TRY_CONVERT(XML, ISNULL(TRY_CONVERT(XML, 
                                        ''<?query --'' +
                                        REPLACE
                                                        (
                                                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                                            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                                                CONVERT
                                                                (
                                                                    VARCHAR(MAX),
                                                                    N''--'' + NCHAR(13) + NCHAR(10) + @Query + NCHAR(13) + NCHAR(10) + N''--'' COLLATE Latin1_General_Bin2
                                                                ),
                                                                NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
                                                                NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
                                                                NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
                                                            NCHAR(0),
                                                            N'''')
                                            + ''--?>''),
                                ''<?query --'' + NCHAR(13) + NCHAR(10) +
                                ''Could not render the query due to XML data type limitations.'' + NCHAR(13) + NCHAR(10) +
                                ''--?>''))
  RETURN @XML
END
'    );

DROP TABLE IF EXISTS #QShistory;

CREATE TABLE #QShistory
(
    [DB] VARCHAR (100)
,   [query_hash] [BINARY] (8) NOT NULL
,   [InicioExecucaoRange] DATETIME
,   [FimExecucaoRange] DATETIME
,   [NumberOfDistinctPlans] [INT] NULL
,   [PlanIDSample] [BIGINT] NULL
,   [QueryPlanSample] [XML] NULL
,   [HasMissingIndex] [INT] NOT NULL
,   [MinQueryTextId] [BIGINT] NULL
,   [MinQueryId] [BIGINT] NULL
,   [ListOfQueryIDs] [VARCHAR] (MAX) NULL
,   [QuerySample] [XML] NULL
,   [QuerySampleText] [VARCHAR] (MAX)
,   [ObjId] [BIGINT] NULL
,   [ObjName] [VARCHAR] (800) NULL
,   [ExecutionRegularCount] [BIGINT]
,   [ExecutionAbortedCount] [BIGINT]
,   [ExecutionExceptionCount] [BIGINT]
,   [TotalExecutions] [BIGINT] NULL
,   [TotalDuration_Sec] [NUMERIC] (18, 4) NULL
,   [AvgDuration_Sec] [NUMERIC] (18, 4) NULL
,   [MinDuration_Sec] [NUMERIC] (18, 4) NULL
,   [MaxDuration_Sec] [NUMERIC] (18, 4) NULL
,   [LastDuration_Sec] [NUMERIC] (18, 4) NULL
,   [TotalCPU_Sec] [NUMERIC] (18, 4) NULL
,   [AvgCPUTime_Sec] [NUMERIC] (18, 4) NULL
,   [MinCPUTime_Sec] [NUMERIC] (18, 4) NULL
,   [MaxCPUTime_Sec] [NUMERIC] (18, 4) NULL
,   [LastCPUTime_Sec] [NUMERIC] (18, 4) NULL
,   [TotalLogicalPageReads] [FLOAT] NULL
,   [AvgLogicalPageReads] [BIGINT] NULL
,   [MinLogicalPageReads] [BIGINT] NULL
,   [MaxLogicalPageReads] [BIGINT] NULL
,   [LastLogicalPageReads] [BIGINT] NULL
,   [TotalLogicalReadsGB] [NUMERIC] (18, 4) NULL
,   [AvgLogicalReadsGB] [NUMERIC] (18, 4) NULL
,   [MinLogicalReadsGB] [NUMERIC] (18, 4) NULL
,   [MaxLogicalReadsGB] [NUMERIC] (18, 4) NULL
,   [LastLogicalReadsGB] [NUMERIC] (18, 4) NULL
,   [TotalPhysicalPageReads] [FLOAT] NULL
,   [AvgPhysicalPageReads] [BIGINT] NULL
,   [MinPhysicalPageReads] [BIGINT] NULL
,   [MaxPhysicalPageReads] [BIGINT] NULL
,   [LastPhysicalPageReads] [BIGINT] NULL
,   [TotalPhysicalReadsGB] [NUMERIC] (18, 4) NULL
,   [AvgPhysicalReadsGB] [NUMERIC] (18, 4) NULL
,   [MinPhysicalReadsGB] [NUMERIC] (18, 4) NULL
,   [MaxPhysicalReadsGB] [NUMERIC] (18, 4) NULL
,   [LastPhysicalReadsGB] [NUMERIC] (18, 4) NULL
,   [TotalLogicalPageWrites] [FLOAT] NULL
,   [AvgLogicalPageWrites] [BIGINT] NULL
,   [MinLogicalPageWrites] [BIGINT] NULL
,   [MaxLogicalPageWrites] [BIGINT] NULL
,   [LastLogicalPageWrites] [BIGINT] NULL
,   [TotalLogicalWritesGB] [NUMERIC] (18, 4) NULL
,   [AvgLogicalWritesGB] [NUMERIC] (18, 4) NULL
,   [MinLogicalWritesGB] [NUMERIC] (18, 4) NULL
,   [MaxLogicalWritesGB] [NUMERIC] (18, 4) NULL
,   [LastLogicalWritesGB] [NUMERIC] (18, 4) NULL
,   [AvgDOP] [BIGINT] NULL
,   [MinDOP] [BIGINT] NULL
,   [MaxDOP] [BIGINT] NULL
,   [LastDOP] [BIGINT] NULL
,   [AvgMemoryGrantMB] [BIGINT] NULL
,   [MinMemoryGrantMB] [BIGINT] NULL
,   [MaxMemoryGrantMB] [BIGINT] NULL
,   [LastMemoryGrantMB] [BIGINT] NULL
,   [AvgRowCount] [BIGINT] NULL
,   [MinRowCount] [BIGINT] NULL
,   [MaxRowCount] [BIGINT] NULL
,   [LastRowCount] [BIGINT] NULL
,   [AvgCompileDuration_Sec] [NUMERIC] (18, 4) NULL
,   [LastCompileDuration_Sec] [NUMERIC] (18, 4) NULL
);

DECLARE @db VARCHAR (100);
DECLARE @QUERY NVARCHAR (MAX) = N'';

-- Cursor para percorrer os registros
DECLARE cursor1 CURSOR FOR --FAST_FORWARD--FOR
SELECT
    name
FROM
    sys.databases a
WHERE
    is_query_store_on = 1
    AND state_desc = 'online'
    AND
    (
        EXISTS
(
    SELECT
        *
    FROM
        #DBS b
    WHERE
        a.name = b.db
)
        OR @DatabasesSeparadasPorVirgula = 'ALL'
    );

--  AND name = 'dbpcpfri';

--Abrindo Cursor
OPEN cursor1;

-- Lendo a próxima linha
FETCH NEXT FROM cursor1
INTO
    @db;

-- Percorrendo linhas do cursor (enquanto houverem)
WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT
            @QUERY =
            N'USE [' + @db + N']' + CHAR(10)
            + N' ;WITH CTE
         AS
         (
             SELECT
                 DB_NAME() AS DB
             ,   q.query_hash
             ,   InicioExecucaoRange = MIN(DATEADD(HOUR,-3,rs.first_execution_time))
             ,   FimExecucaoRange = MAX(DATEADD(HOUR,-3,rs.last_execution_time))
             ,   COUNT(DISTINCT p.plan_id) AS NumberOfDistinctPlans
             ,   MIN(p.plan_id) AS PlanIDSample
             ,   TRY_CONVERT(XML, MIN(p.query_plan)) AS QueryPlanSample
             ,   CASE
                     WHEN MIN(p.query_plan COLLATE Latin1_General_BIN2) LIKE N''%<MissingIndexes>%'' THEN 1
                 ELSE 0
                 END AS HasMissingIndex
             ,   MIN(q.query_text_id) AS MinQueryTextId
             ,   MIN(q.query_id) AS MinQueryId
             ,   CONVERT(VARCHAR (MAX), '''') AS ListOfQueryIDs
             ,   CONVERT(XML, '''') AS QuerySample
             ,   '''' as QuerySampleText
             ,   MIN(q.object_id) AS ObjId
             ,   CONVERT(VARCHAR (800), '''') AS ObjName
             ,   ExecutionRegularCount = SUM(   CASE
                                                    WHEN execution_type_desc = ''Regular'' THEN rs.count_executions
                                                ELSE 0
                                                END
                                            )
             ,   ExecutionAbortedCount = SUM(   CASE
                                                    WHEN execution_type_desc = ''Aborted'' THEN rs.count_executions
                                                ELSE 0
                                                END
                                            )
             ,   ExecutionExceptionCount = SUM(   CASE
                                                      WHEN execution_type_desc = ''Exception'' THEN rs.count_executions
                                                  ELSE 0
                                                  END
                                              )
             ,   SUM(rs.count_executions) AS TotalExecutions
             ,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_duration)/ 1000. / 1000.) AS TotalDuration_Sec
             ,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_duration / 1000. / 1000.)) AS AvgDuration_Sec
             ,   CONVERT(NUMERIC (18, 4), MIN(rs.min_duration / 1000. / 1000.)) AS MinDuration_Sec
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.max_duration / 1000. / 1000.)) AS MaxDuration_Sec
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.last_duration / 1000. / 1000.)) AS LastDuration_Sec
             ,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_cpu_time)/ 1000. / 1000.) AS TotalCPU_Sec
             ,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_cpu_time / 1000. / 1000.)) AS AvgCPUTime_Sec
             ,   CONVERT(NUMERIC (18, 4), MIN(rs.min_cpu_time / 1000. / 1000.)) AS MinCPUTime_Sec
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.max_cpu_time / 1000. / 1000.)) AS MaxCPUTime_Sec
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.last_cpu_time / 1000. / 1000.)) AS LastCPUTime_Sec
             ,   SUM(rs.count_executions * rs.avg_logical_io_reads) AS TotalLogicalPageReads
             ,   CONVERT(BIGINT, AVG(rs.avg_logical_io_reads)) AS AvgLogicalPageReads
             ,   CONVERT(BIGINT, MIN(rs.min_logical_io_reads)) AS MinLogicalPageReads
             ,   CONVERT(BIGINT, MAX(rs.max_logical_io_reads)) AS MaxLogicalPageReads
             ,   CONVERT(BIGINT, MAX(rs.last_logical_io_reads)) AS LastLogicalPageReads
             ,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_logical_io_reads) * 8 / 1024. / 1024.) AS TotalLogicalReadsGB
             ,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_logical_io_reads * 8 / 1024. / 1024.)) AS AvgLogicalReadsGB
             ,   CONVERT(NUMERIC (18, 4), MIN(rs.min_logical_io_reads * 8 / 1024. / 1024.)) AS MinLogicalReadsGB
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.max_logical_io_reads * 8 / 1024. / 1024.)) AS MaxLogicalReadsGB
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.last_logical_io_reads * 8 / 1024. / 1024.)) AS LastLogicalReadsGB
             ,   SUM(rs.count_executions * rs.avg_physical_io_reads) AS TotalPhysicalPageReads
             ,   CONVERT(BIGINT, AVG(rs.avg_physical_io_reads)) AS AvgPhysicalPageReads
             ,   CONVERT(BIGINT, MIN(rs.min_physical_io_reads)) AS MinPhysicalPageReads
             ,   CONVERT(BIGINT, MAX(rs.max_physical_io_reads)) AS MaxPhysicalPageReads
             ,   CONVERT(BIGINT, MAX(rs.last_physical_io_reads)) AS LastPhysicalPageReads
             ,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_physical_io_reads) * 8 / 1024. / 1024.) AS TotalPhysicalReadsGB
             ,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_physical_io_reads * 8 / 1024. / 1024.)) AS AvgPhysicalReadsGB
             ,   CONVERT(NUMERIC (18, 4), MIN(rs.min_physical_io_reads * 8 / 1024. / 1024.)) AS MinPhysicalReadsGB
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.max_physical_io_reads * 8 / 1024. / 1024.)) AS MaxPhysicalReadsGB
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.last_physical_io_reads * 8 / 1024. / 1024.)) AS LastPhysicalReadsGB
             ,   SUM(rs.count_executions * rs.avg_logical_io_writes) AS TotalLogicalPageWrites
             ,   CONVERT(BIGINT, AVG(avg_logical_io_reads)) AS AvgLogicalPageWrites
             ,   CONVERT(BIGINT, MIN(min_logical_io_reads)) AS MinLogicalPageWrites
             ,   CONVERT(BIGINT, MAX(max_logical_io_reads)) AS MaxLogicalPageWrites
             ,   CONVERT(BIGINT, MAX(last_logical_io_reads)) AS LastLogicalPageWrites
             ,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_logical_io_writes) * 8 / 1024. / 1024.) AS TotalLogicalWritesGB
             ,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_logical_io_writes * 8 / 1024. / 1024.)) AS AvgLogicalWritesGB
             ,   CONVERT(NUMERIC (18, 4), MIN(rs.min_logical_io_writes * 8 / 1024. / 1024.)) AS MinLogicalWritesGB
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.max_logical_io_writes * 8 / 1024. / 1024.)) AS MaxLogicalWritesGB
             ,   CONVERT(NUMERIC (18, 4), MAX(rs.last_logical_io_writes * 8 / 1024. / 1024.)) AS LastLogicalWritesGB
             ,   CONVERT(BIGINT, AVG(rs.avg_dop)) AS AvgDOP
             ,   CONVERT(BIGINT, MIN(rs.min_dop)) AS MinDOP
             ,   CONVERT(BIGINT, MAX(rs.max_dop)) AS MaxDOP
             ,   CONVERT(BIGINT, MAX(rs.last_dop)) AS LastDOP
             ,   CONVERT(BIGINT, AVG(rs.avg_query_max_used_memory) * 8 / 1024) AS AvgMemoryGrantMB
             ,   CONVERT(BIGINT, MIN(rs.min_query_max_used_memory) * 8 / 1024) AS MinMemoryGrantMB
             ,   CONVERT(BIGINT, MAX(rs.max_query_max_used_memory) * 8 / 1024) AS MaxMemoryGrantMB
             ,   CONVERT(BIGINT, MAX(rs.last_query_max_used_memory) * 8 / 1024) AS LastMemoryGrantMB
             ,   CONVERT(BIGINT, AVG(rs.avg_rowcount)) AS AvgRowCount
             ,   CONVERT(BIGINT, MIN(rs.min_rowcount)) AS MinRowCount
             ,   CONVERT(BIGINT, MAX(rs.max_rowcount)) AS MaxRowCount
             ,   CONVERT(BIGINT, MAX(rs.last_rowcount)) AS LastRowCount
             ,   CONVERT(NUMERIC (18, 4), AVG(q.avg_compile_duration / 1000. / 1000.)) AS AvgCompileDuration_Sec
             ,   CONVERT(NUMERIC (18, 4), MAX(q.last_compile_duration / 1000. / 1000.)) AS LastCompileDuration_Sec
             FROM
                 sys.query_store_runtime_stats rs
             INNER JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
             INNER JOIN sys.query_store_query q ON p.query_id = q.query_id
             INNER JOIN sys.query_store_runtime_stats_interval rsi ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
             WHERE
                 CONVERT(DATE,DATEADD(HOUR,-3,rsi.start_time)) BETWEEN @DataInicio AND @DataFim
             AND CONVERT(TIME(0),DATEADD(HOUR,-3,rsi.start_time)) BETWEEN @TimeInicio AND @TimeFim
             GROUP BY
                 q.query_hash
             ,   q.object_id
         )
        INSERT INTO #QShistory
        (
            DB
        ,   query_hash
        ,   InicioExecucaoRange
        ,   FimExecucaoRange
        ,   NumberOfDistinctPlans
        ,   PlanIDSample
        ,   QueryPlanSample
        ,   HasMissingIndex
        ,   MinQueryTextId
        ,   MinQueryId
        ,   ListOfQueryIDs
        ,   QuerySample
        ,   QuerySampleText
        ,   [ObjId]
        ,   ObjName
        ,   ExecutionRegularCount
        ,   ExecutionAbortedCount
        ,   ExecutionExceptionCount
        ,   TotalExecutions
        ,   TotalDuration_Sec
        ,   AvgDuration_Sec
        ,   MinDuration_Sec
        ,   MaxDuration_Sec
        ,   LastDuration_Sec
        ,   TotalCPU_Sec
        ,   AvgCPUTime_Sec
        ,   MinCPUTime_Sec
        ,   MaxCPUTime_Sec
        ,   LastCPUTime_Sec
        ,   TotalLogicalPageReads
        ,   AvgLogicalPageReads
        ,   MinLogicalPageReads
        ,   MaxLogicalPageReads
        ,   LastLogicalPageReads
        ,   TotalLogicalReadsGB
        ,   AvgLogicalReadsGB
        ,   MinLogicalReadsGB
        ,   MaxLogicalReadsGB
        ,   LastLogicalReadsGB
        ,   TotalPhysicalPageReads
        ,   AvgPhysicalPageReads
        ,   MinPhysicalPageReads
        ,   MaxPhysicalPageReads
        ,   LastPhysicalPageReads
        ,   TotalPhysicalReadsGB
        ,   AvgPhysicalReadsGB
        ,   MinPhysicalReadsGB
        ,   MaxPhysicalReadsGB
        ,   LastPhysicalReadsGB
        ,   TotalLogicalPageWrites
        ,   AvgLogicalPageWrites
        ,   MinLogicalPageWrites
        ,   MaxLogicalPageWrites
        ,   LastLogicalPageWrites
        ,   TotalLogicalWritesGB
        ,   AvgLogicalWritesGB
        ,   MinLogicalWritesGB
        ,   MaxLogicalWritesGB
        ,   LastLogicalWritesGB
        ,   AvgDOP
        ,   MinDOP
        ,   [MaxDOP]
        ,   LastDOP
        ,   AvgMemoryGrantMB
        ,   MinMemoryGrantMB
        ,   MaxMemoryGrantMB
        ,   LastMemoryGrantMB
        ,   AvgRowCount
        ,   MinRowCount
        ,   MaxRowCount
        ,   LastRowCount
        ,   AvgCompileDuration_Sec
        ,   LastCompileDuration_Sec
        )
        SELECT TOP ( @Top )
               *
        FROM
            CTE
        ORDER BY
            CASE
                WHEN @TopBy = ''Duration'' THEN AvgDuration_Sec
                WHEN @TopBy = ''CPU'' THEN TotalCPU_Sec
                WHEN @TopBy = ''Logical Reads'' THEN TotalLogicalPageReads
                WHEN @TopBy = ''Physical Reads'' THEN TotalPhysicalPageReads
                WHEN @TopBy = ''Memory Grant'' THEN AvgMemoryGrantMB
                WHEN @TopBy = ''Possible Timeouts'' THEN ExecutionAbortedCount
            END DESC
        OPTION ( MAXDOP 1, RECOMPILE );

        UPDATE
            #QShistory
        SET
            ListOfQueryIDs = Tab1.cQuery
        ,   QuerySample = master.dbo.fn_QueryTextToXML(Tab2.query_sql_text)
        ,   QuerySampleText = Tab2.query_sql_text
        ,   ObjName = OBJECT_NAME(q.ObjId, DB_ID())
        FROM
            master.#QShistory q
        CROSS APPLY
        (
            SELECT
                CONVERT(VARCHAR (200), q1.query_id) + '',''
            FROM
                sys.query_store_query AS q1
            WHERE
                q1.query_hash = q.query_hash
            FOR XML PATH('''')
        ) AS Tab1(cQuery)
        OUTER APPLY
        (
            SELECT TOP 1
                   query_sql_text
            FROM
                sys.query_store_query_text qt
            WHERE
                qt.query_text_id = q.MinQueryTextId
        ) AS Tab2
        WHERE
            DB = db_name()
        ';

        EXEC sp_executesql
            @QUERY
        ,   N'@Top BIGINT, @TopBy varchar(100), @DataInicio datetime, @DataFim datetime, @TimeInicio varchar(100), @TimeFim varchar(100)'
        ,   @Top
        ,   @TopBy
        ,   @DataInicio
        ,   @DataFim
        ,   @TimeInicio
        ,   @TimeFim

        -- Lendo a próxima linha
        FETCH NEXT FROM cursor1
        INTO
            @db;
    END;

-- Fechando Cursor para leitura
CLOSE cursor1;

-- Finalizado o cursor
DEALLOCATE cursor1;


DECLARE @TEXTO2 NVARCHAR(MAX)
SELECT
    @TEXTO2 = 
N'
IF @TopBy = ''Possible Timeouts'' AND NOT EXISTS (SELECT * FROM #QShistory WHERE ExecutionAbortedCount >= 1)
BEGIN
    
    SELECT Info = ''Não existe nenhuma query abortada neste range de horário''
    RETURN
END


;WITH CTE_2
AS
(
    SELECT TOP ( @Top )
           DtColeta = GETDATE()
    ,      [Rank] = ROW_NUMBER() OVER ( ORDER BY
                                            CASE
                                                WHEN @TopBy = ''Duration'' THEN AvgDuration_Sec
                                                WHEN @TopBy = ''CPU'' THEN TotalCPU_Sec
                                                WHEN @TopBy = ''Logical Reads'' THEN TotalLogicalPageReads
                                                WHEN @TopBy = ''Physical Reads'' THEN TotalPhysicalPageReads
                                                WHEN @TopBy = ''Memory Grant'' THEN AvgMemoryGrantMB
                                                WHEN @TopBy = ''Possible Timeouts'' THEN ExecutionAbortedCount
                                            END DESC
                                      )
    ,      *
    FROM
        #QShistory
    ORDER BY
        CASE
            WHEN @TopBy = ''Duration'' THEN AvgDuration_Sec
            WHEN @TopBy = ''CPU'' THEN TotalCPU_Sec
            WHEN @TopBy = ''Logical Reads'' THEN TotalLogicalPageReads
            WHEN @TopBy = ''Physical Reads'' THEN TotalPhysicalPageReads
            WHEN @TopBy = ''Memory Grant'' THEN AvgMemoryGrantMB
            WHEN @TopBy = ''Possible Timeouts'' THEN ExecutionAbortedCount
        END DESC
)
SELECT
    DtColeta
,   TopBy = @TopBy
,   [Rank]
,   [Peso %] = CONVERT(
                          DECIMAL (18, 2)
                      ,   CONVERT(INT
                                 , CASE
                                       WHEN @TopBy = ''Duration'' THEN AvgDuration_Sec
                                       WHEN @TopBy = ''CPU'' THEN TotalCPU_Sec
                                       WHEN @TopBy = ''Logical Reads'' THEN TotalLogicalPageReads
                                       WHEN @TopBy = ''Physical Reads'' THEN TotalPhysicalPageReads
                                       WHEN @TopBy = ''Memory Grant'' THEN AvgMemoryGrantMB
                                       WHEN @TopBy = ''Possible Timeouts'' THEN ExecutionAbortedCount
                                   END
                                 )
                          / CASE
                                WHEN CONVERT(
                                                DECIMAL (18, 2)
                                            ,   SUM(   CASE
                                                           WHEN @TopBy = ''Duration'' THEN AvgDuration_Sec
                                                           WHEN @TopBy = ''CPU'' THEN TotalCPU_Sec
                                                           WHEN @TopBy = ''Logical Reads'' THEN TotalLogicalPageReads
                                                           WHEN @TopBy = ''Physical Reads'' THEN TotalPhysicalPageReads
                                                           WHEN @TopBy = ''Memory Grant'' THEN AvgMemoryGrantMB
                                                           WHEN @TopBy = ''Possible Timeouts'' THEN ExecutionAbortedCount
                                                       END
                                                   ) OVER ()
                                            ) = 0 THEN NULL
                            ELSE
                                CONVERT(
                                           DECIMAL (18, 2)
                                       ,   SUM(   CASE
                                                      WHEN @TopBy = ''Duration'' THEN AvgDuration_Sec
                                                      WHEN @TopBy = ''CPU'' THEN TotalCPU_Sec
                                                      WHEN @TopBy = ''Logical Reads'' THEN TotalLogicalPageReads
                                                      WHEN @TopBy = ''Physical Reads'' THEN TotalPhysicalPageReads
                                                      WHEN @TopBy = ''Memory Grant'' THEN AvgMemoryGrantMB
                                                      WHEN @TopBy = ''Possible Timeouts'' THEN ExecutionAbortedCount
                                                  END
                                              ) OVER ()
                                       )
                            END  * 100
                      )
,   DB
,   query_hash
,   InicioExecucaoRange
,   FimExecucaoRange
,   NumberOfDistinctPlans
,   PlanIDSample
,   QueryPlanSample
,   HasMissingIndex
,   MinQueryTextId
,   MinQueryId
,   ListOfQueryIDs
,   QuerySample
,   QuerySampleText
,   [ObjId]
,   ObjName
,   ExecutionRegularCount
,   ExecutionAbortedCount
,   ExecutionExceptionCount
,   TotalExecutions
,   TotalDuration_Sec
,   AvgDuration_Sec
,   MinDuration_Sec
,   MaxDuration_Sec
,   LastDuration_Sec
,   TotalCPU_Sec
,   AvgCPUTime_Sec
,   MinCPUTime_Sec
,   MaxCPUTime_Sec
,   LastCPUTime_Sec
,   TotalLogicalPageReads
,   AvgLogicalPageReads
,   MinLogicalPageReads
,   MaxLogicalPageReads
,   LastLogicalPageReads
,   TotalLogicalReadsGB
,   AvgLogicalReadsGB
,   MinLogicalReadsGB
,   MaxLogicalReadsGB
,   LastLogicalReadsGB
,   TotalPhysicalPageReads
,   AvgPhysicalPageReads
,   MinPhysicalPageReads
,   MaxPhysicalPageReads
,   LastPhysicalPageReads
,   TotalPhysicalReadsGB
,   AvgPhysicalReadsGB
,   MinPhysicalReadsGB
,   MaxPhysicalReadsGB
,   LastPhysicalReadsGB
,   TotalLogicalPageWrites
,   AvgLogicalPageWrites
,   MinLogicalPageWrites
,   MaxLogicalPageWrites
,   LastLogicalPageWrites
,   TotalLogicalWritesGB
,   AvgLogicalWritesGB
,   MinLogicalWritesGB
,   MaxLogicalWritesGB
,   LastLogicalWritesGB
,   AvgDOP
,   MinDOP
,   [MaxDOP]
,   LastDOP
,   AvgMemoryGrantMB
,   MinMemoryGrantMB
,   MaxMemoryGrantMB
,   LastMemoryGrantMB
,   AvgRowCount
,   MinRowCount
,   MaxRowCount
,   LastRowCount
,   AvgCompileDuration_Sec
,   LastCompileDuration_Sec

' + CASE WHEN @OutputTable IS NULL THEN '' ELSE 'INTO ' + @OutputTable  END + '
FROM
    CTE_2
ORDER BY
    [Rank]'

   EXEC sp_executesql
            @TEXTO2
        ,   N'@Top BIGINT, @TopBy varchar(100), @DataInicio datetime, @DataFim datetime'
        ,   @Top
        ,   @TopBy
        ,   @DataInicio
        ,   @DataFim;


-----------------------------------------------------------------------------------------------------------------------------------------------
--carga temp
-----------------------------------------------------------------------------------------------------------------------------------------------

--select * into dts_tools.dbo.qs_temp from #qs

--insert dts_tools.dbo.qs_temp (dt, DB,query_hash,InicioExecucaoRange,FimExecucaoRange,NumberOfDistinctPlans,PlanIDSample,QueryPlanSample,HasMissingIndex,MinQueryTextId,MinQueryId,ListOfQueryIDs,QuerySample,QuerySampleText,ObjId,ObjName,ExecutionRegularCount,ExecutionAbortedCount,ExecutionExceptionCount,TotalExecutions,TotalDuration_Sec,AvgDuration_Sec,MinDuration_Sec,MaxDuration_Sec,LastDuration_Sec,TotalCPU_Sec,AvgCPUTime_Sec,MinCPUTime_Sec,MaxCPUTime_Sec,LastCPUTime_Sec,TotalLogicalPageReads,AvgLogicalPageReads,MinLogicalPageReads,MaxLogicalPageReads,LastLogicalPageReads,TotalLogicalReadsGB,AvgLogicalReadsGB,MinLogicalReadsGB,MaxLogicalReadsGB,LastLogicalReadsGB,TotalPhysicalPageReads,AvgPhysicalPageReads,MinPhysicalPageReads,MaxPhysicalPageReads,LastPhysicalPageReads,TotalPhysicalReadsGB,AvgPhysicalReadsGB,MinPhysicalReadsGB,MaxPhysicalReadsGB,LastPhysicalReadsGB,TotalLogicalPageWrites,AvgLogicalPageWrites,MinLogicalPageWrites,MaxLogicalPageWrites,LastLogicalPageWrites,TotalLogicalWritesGB,AvgLogicalWritesGB,MinLogicalWritesGB,MaxLogicalWritesGB,LastLogicalWritesGB,AvgDOP,MinDOP,MaxDOP,LastDOP,AvgMemoryGrantMB,MinMemoryGrantMB,MaxMemoryGrantMB,LastMemoryGrantMB,AvgRowCount,MinRowCount,MaxRowCount,LastRowCount,AvgCompileDuration_Sec,LastCompileDuration_Sec)
--select * from #qs where dt = '20221011'


insert #qs (dt, DB,query_hash,InicioExecucaoRange,FimExecucaoRange,NumberOfDistinctPlans,PlanIDSample,QueryPlanSample,HasMissingIndex,MinQueryTextId,MinQueryId,ListOfQueryIDs,QuerySample,QuerySampleText,ObjId,ObjName,ExecutionRegularCount,ExecutionAbortedCount,ExecutionExceptionCount,TotalExecutions,TotalDuration_Sec,AvgDuration_Sec,MinDuration_Sec,MaxDuration_Sec,LastDuration_Sec,TotalCPU_Sec,AvgCPUTime_Sec,MinCPUTime_Sec,MaxCPUTime_Sec,LastCPUTime_Sec,TotalLogicalPageReads,AvgLogicalPageReads,MinLogicalPageReads,MaxLogicalPageReads,LastLogicalPageReads,TotalLogicalReadsGB,AvgLogicalReadsGB,MinLogicalReadsGB,MaxLogicalReadsGB,LastLogicalReadsGB,TotalPhysicalPageReads,AvgPhysicalPageReads,MinPhysicalPageReads,MaxPhysicalPageReads,LastPhysicalPageReads,TotalPhysicalReadsGB,AvgPhysicalReadsGB,MinPhysicalReadsGB,MaxPhysicalReadsGB,LastPhysicalReadsGB,TotalLogicalPageWrites,AvgLogicalPageWrites,MinLogicalPageWrites,MaxLogicalPageWrites,LastLogicalPageWrites,TotalLogicalWritesGB,AvgLogicalWritesGB,MinLogicalWritesGB,MaxLogicalWritesGB,LastLogicalWritesGB,AvgDOP,MinDOP,MaxDOP,LastDOP,AvgMemoryGrantMB,MinMemoryGrantMB,MaxMemoryGrantMB,LastMemoryGrantMB,AvgRowCount,MinRowCount,MaxRowCount,LastRowCount,AvgCompileDuration_Sec,LastCompileDuration_Sec)
SELECT top 10
    '20221023' dt,
    DB_NAME() AS DB
,   q.query_hash
,   InicioExecucaoRange = MIN(DATEADD(HOUR,-3,rs.first_execution_time))
,   FimExecucaoRange = MAX(DATEADD(HOUR,-3,rs.last_execution_time))
,   COUNT(DISTINCT p.plan_id) AS NumberOfDistinctPlans
,   MIN(p.plan_id) AS PlanIDSample
,   TRY_CONVERT(XML, MIN(p.query_plan)) AS QueryPlanSample
,   CASE
        WHEN MIN(p.query_plan COLLATE Latin1_General_BIN2) LIKE N'%<MissingIndexes>%' THEN 1
    ELSE 0
    END AS HasMissingIndex
,   MIN(q.query_text_id) AS MinQueryTextId
,   MIN(q.query_id) AS MinQueryId
,   CONVERT(VARCHAR (MAX), '''') AS ListOfQueryIDs
,   CONVERT(XML, '''') AS QuerySample
,   '''' as QuerySampleText
,   MIN(q.object_id) AS ObjId
,   CONVERT(VARCHAR (800), '''') AS ObjName
,   ExecutionRegularCount = SUM(   CASE
                                    WHEN execution_type_desc = 'Regular' THEN rs.count_executions
                                ELSE 0
                                END
                            )
,   ExecutionAbortedCount = SUM(   CASE
                                    WHEN execution_type_desc = 'Aborted' THEN rs.count_executions
                                ELSE 0
                                END
                            )
,   ExecutionExceptionCount = SUM(   CASE
                                        WHEN execution_type_desc = 'Exception' THEN rs.count_executions
                                    ELSE 0
                                    END
                                )
,   SUM(rs.count_executions) AS TotalExecutions
,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_duration)/ 1000. / 1000.) AS TotalDuration_Sec
,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_duration / 1000. / 1000.)) AS AvgDuration_Sec
,   CONVERT(NUMERIC (18, 4), MIN(rs.min_duration / 1000. / 1000.)) AS MinDuration_Sec
,   CONVERT(NUMERIC (18, 4), MAX(rs.max_duration / 1000. / 1000.)) AS MaxDuration_Sec
,   CONVERT(NUMERIC (18, 4), MAX(rs.last_duration / 1000. / 1000.)) AS LastDuration_Sec
,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_cpu_time)/ 1000. / 1000.) AS TotalCPU_Sec
,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_cpu_time / 1000. / 1000.)) AS AvgCPUTime_Sec
,   CONVERT(NUMERIC (18, 4), MIN(rs.min_cpu_time / 1000. / 1000.)) AS MinCPUTime_Sec
,   CONVERT(NUMERIC (18, 4), MAX(rs.max_cpu_time / 1000. / 1000.)) AS MaxCPUTime_Sec
,   CONVERT(NUMERIC (18, 4), MAX(rs.last_cpu_time / 1000. / 1000.)) AS LastCPUTime_Sec
,   SUM(rs.count_executions * rs.avg_logical_io_reads) AS TotalLogicalPageReads
,   CONVERT(BIGINT, AVG(rs.avg_logical_io_reads)) AS AvgLogicalPageReads
,   CONVERT(BIGINT, MIN(rs.min_logical_io_reads)) AS MinLogicalPageReads
,   CONVERT(BIGINT, MAX(rs.max_logical_io_reads)) AS MaxLogicalPageReads
,   CONVERT(BIGINT, MAX(rs.last_logical_io_reads)) AS LastLogicalPageReads
,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_logical_io_reads) * 8 / 1024. / 1024.) AS TotalLogicalReadsGB
,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_logical_io_reads * 8 / 1024. / 1024.)) AS AvgLogicalReadsGB
,   CONVERT(NUMERIC (18, 4), MIN(rs.min_logical_io_reads * 8 / 1024. / 1024.)) AS MinLogicalReadsGB
,   CONVERT(NUMERIC (18, 4), MAX(rs.max_logical_io_reads * 8 / 1024. / 1024.)) AS MaxLogicalReadsGB
,   CONVERT(NUMERIC (18, 4), MAX(rs.last_logical_io_reads * 8 / 1024. / 1024.)) AS LastLogicalReadsGB
,   SUM(rs.count_executions * rs.avg_physical_io_reads) AS TotalPhysicalPageReads
,   CONVERT(BIGINT, AVG(rs.avg_physical_io_reads)) AS AvgPhysicalPageReads
,   CONVERT(BIGINT, MIN(rs.min_physical_io_reads)) AS MinPhysicalPageReads
,   CONVERT(BIGINT, MAX(rs.max_physical_io_reads)) AS MaxPhysicalPageReads
,   CONVERT(BIGINT, MAX(rs.last_physical_io_reads)) AS LastPhysicalPageReads
,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_physical_io_reads) * 8 / 1024. / 1024.) AS TotalPhysicalReadsGB
,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_physical_io_reads * 8 / 1024. / 1024.)) AS AvgPhysicalReadsGB
,   CONVERT(NUMERIC (18, 4), MIN(rs.min_physical_io_reads * 8 / 1024. / 1024.)) AS MinPhysicalReadsGB
,   CONVERT(NUMERIC (18, 4), MAX(rs.max_physical_io_reads * 8 / 1024. / 1024.)) AS MaxPhysicalReadsGB
,   CONVERT(NUMERIC (18, 4), MAX(rs.last_physical_io_reads * 8 / 1024. / 1024.)) AS LastPhysicalReadsGB
,   SUM(rs.count_executions * rs.avg_logical_io_writes) AS TotalLogicalPageWrites
,   CONVERT(BIGINT, AVG(avg_logical_io_reads)) AS AvgLogicalPageWrites
,   CONVERT(BIGINT, MIN(min_logical_io_reads)) AS MinLogicalPageWrites
,   CONVERT(BIGINT, MAX(max_logical_io_reads)) AS MaxLogicalPageWrites
,   CONVERT(BIGINT, MAX(last_logical_io_reads)) AS LastLogicalPageWrites
,   CONVERT(NUMERIC (18, 4), SUM(rs.count_executions * rs.avg_logical_io_writes) * 8 / 1024. / 1024.) AS TotalLogicalWritesGB
,   CONVERT(NUMERIC (18, 4), AVG(rs.avg_logical_io_writes * 8 / 1024. / 1024.)) AS AvgLogicalWritesGB
,   CONVERT(NUMERIC (18, 4), MIN(rs.min_logical_io_writes * 8 / 1024. / 1024.)) AS MinLogicalWritesGB
,   CONVERT(NUMERIC (18, 4), MAX(rs.max_logical_io_writes * 8 / 1024. / 1024.)) AS MaxLogicalWritesGB
,   CONVERT(NUMERIC (18, 4), MAX(rs.last_logical_io_writes * 8 / 1024. / 1024.)) AS LastLogicalWritesGB
,   CONVERT(BIGINT, AVG(rs.avg_dop)) AS AvgDOP
,   CONVERT(BIGINT, MIN(rs.min_dop)) AS MinDOP
,   CONVERT(BIGINT, MAX(rs.max_dop)) AS MaxDOP
,   CONVERT(BIGINT, MAX(rs.last_dop)) AS LastDOP
,   CONVERT(BIGINT, AVG(rs.avg_query_max_used_memory) * 8 / 1024) AS AvgMemoryGrantMB
,   CONVERT(BIGINT, MIN(rs.min_query_max_used_memory) * 8 / 1024) AS MinMemoryGrantMB
,   CONVERT(BIGINT, MAX(rs.max_query_max_used_memory) * 8 / 1024) AS MaxMemoryGrantMB
,   CONVERT(BIGINT, MAX(rs.last_query_max_used_memory) * 8 / 1024) AS LastMemoryGrantMB
,   CONVERT(BIGINT, AVG(rs.avg_rowcount)) AS AvgRowCount
,   CONVERT(BIGINT, MIN(rs.min_rowcount)) AS MinRowCount
,   CONVERT(BIGINT, MAX(rs.max_rowcount)) AS MaxRowCount
,   CONVERT(BIGINT, MAX(rs.last_rowcount)) AS LastRowCount
,   CONVERT(NUMERIC (18, 4), AVG(q.avg_compile_duration / 1000. / 1000.)) AS AvgCompileDuration_Sec
,   CONVERT(NUMERIC (18, 4), MAX(q.last_compile_duration / 1000. / 1000.)) AS LastCompileDuration_Sec
--into #qs
from 
    sys.query_store_runtime_stats rs
INNER JOIN sys.query_store_plan p ON rs.plan_id = p.plan_id
INNER JOIN sys.query_store_query q ON p.query_id = q.query_id
INNER JOIN sys.query_store_runtime_stats_interval rsi ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
WHERE
    CONVERT(DATE,DATEADD(HOUR,-3,rsi.start_time)) BETWEEN '20221023' AND '20221024'
AND CONVERT(TIME(0),DATEADD(HOUR,-3,rsi.start_time)) BETWEEN '00:00' AND '23:59'
--and 1= 2
GROUP BY
    q.query_hash
,   q.object_id
order by TotalCPU_Sec desc


-----------------------------------------------------------------------------------------------------------------------------------------------
traces
-----------------------------------------------------------------------------------------------------------------------------------------------


use Traces
go

-- TRAZER AS TOP QUERIES DO AMBIENTE
declare @dt_inicio datetime = '20221207 08:39:00.000'
        ,@dt_fim datetime = '20221207 08:41:00.000'
        ,@qtd_minimo_execucao int = 1

--declare @dt_inicio datetime = '20221206 08:29:00.000'
--      ,@dt_fim datetime = '20221206 08:55:30.000'
--      ,@qtd_minimo_execucao int = 1

--- MODIFICAR A LINHA "order by total_duracao desc" DE ACORDO COM O QUE DESEJA BUSCAR. 
if object_id('tempdb..#tmp') is not null drop table #tmp
select top 10
    DataBaseName,
    LEFT(convert(varchar(max),textdata),66) as TRECHO,
    sum(convert(bigint,cpu)) as total_cpu,
    sum(convert(bigint,reads+writes)) as total_IOs,
    sum(convert(bigint,duration)) as total_duracao,
    avg(convert(bigint,cpu)) as media_cpu,
    AVG(duration) as Media_duracao,
    min(duration) as Menor_duracao,
    max(duration) as Maior_duracao,
    count(*) as Total_Execucoes
        into #tmp
from
    Traces
where  DataBaseName not in ('traces','DTS_TOOLS') and
   StartTime between  @dt_inicio and @dt_fim--and HostName <> 'AL7001'
group by
    DataBaseName,
    LEFT(convert(varchar(max),textdata),66)
HAVING COUNT(*) > 5

order by total_duracao desc
OPTION(RECOMPILE)

;with cte
as
(

select
a.DataBaseName,
c1.full_text_sample,
a.total_IOs,
a.Total_Execucoes,
dateadd(second,a.total_duracao,'19900101') as total_duracao,
dateadd(ms,a.total_cpu,'19900101') as total_cpu,
dateadd(ms,a.media_cpu,'19900101') as media_cpu,
dateadd(second,a.Media_duracao,'19900101') as Media_duracao


from
    #tmp a 
cross apply (
            select top 1 
                    convert(varchar(max),b.textdata) full_text_sample                   
            from 
                Traces b
            where 
                b.StartTime between  @dt_inicio and @dt_fim--and HostName <> 'AL7001'
            and LEFT(convert(varchar(max),b.textdata),66) = a.TRECHO
            order by b.Duration desc
            ) c1

)
select
DataBaseName,
full_text_sample,
total_IOs,
Total_Execucoes,
RIGHT( '00' + CONVERT(VARCHAR(30),DATEDIFF(DAY,'19900101',total_duracao)),5)  + ' ' + CONVERT(VARCHAR(300),CONVERT(TIME(0),total_duracao))  total_duracao,
RIGHT( '00' + CONVERT(VARCHAR(30),DATEDIFF(DAY,'19900101',total_cpu)),5)  + ' ' + CONVERT(VARCHAR(300),CONVERT(TIME(0),total_cpu))  total_cpu,
RIGHT( '00' + CONVERT(VARCHAR(30),DATEDIFF(DAY,'19900101',media_cpu)),5)  + ' ' + CONVERT(VARCHAR(300),CONVERT(TIME(0),media_cpu))  media_cpu,
RIGHT( '00' + CONVERT(VARCHAR(30),DATEDIFF(DAY,'19900101',Media_duracao)),5)  + ' ' + CONVERT(VARCHAR(300),CONVERT(TIME(0),Media_duracao)) Media_duracao 

from
    cte
OPTION(RECOMPILE)