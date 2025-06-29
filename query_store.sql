-----------------------------------------------------------------------------------------------------------------------------------------------
--links
-----------------------------------------------------------------------------------------------------------------------------------------------

https://learn.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-ver16

https://www.sqlservercentral.com/forums/topic/is-it-possible-get-from-query-store-historical-cpu-usage-by-each-query


-----------------------------------------------------------------------------------------------------------------------------------------------
enable query store
-----------------------------------------------------------------------------------------------------------------------------------------------
ALTER DATABASE [AdventureWorks2014] SET QUERY_STORE = ON;

-----------------------------------------------------------------------------------------------------------------------------------------------
operation mode (OFF, READ_ONLY, READ_WRITE) 
-----------------------------------------------------------------------------------------------------------------------------------------------
/*
Off – The SQL Server Query Store turned off
Read Only – This mode indicates that new query runtime statistics or executed plans will not be tracked (collected)
Read Write – Allows capturing query executed plans and query runtime statistics
*/
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON ( OPERATION_MODE = READ_WRITE);

-----------------------------------------------------------------------------------------------------------------------------------------------
Data Flush Interval (Minutes) 
-----------------------------------------------------------------------------------------------------------------------------------------------
/*
an interval in minutes can be set which shows how frequent the query runtime statistics and query execution plans will be flushed from memory of 
SQL Server instance to disk. 
By default, this option is set to 15 minutes
*/
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON ( DATA_FLUSH_INTERVAL_SECONDS = 900 );

-----------------------------------------------------------------------------------------------------------------------------------------------
Statistics Collection Interval (1, 5, 10, 15, 30, 60, 1440)
-----------------------------------------------------------------------------------------------------------------------------------------------
/*
defined aggregation interval of query runtime statistics that should be used inside the SQL Server Query Store. By default, it is set to 60 minutes. 
Lower value means that granularity of query runtime statistics is finer, because of that, more intervals occur which requires more disk space for 
storing query runtime statistics.
Note, in the T-SQL code for the Statistics Collection Interval option the following values in minutes 1, 5, 10, 15, 30, 60, 1440 can be set.
*/
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON ( INTERVAL_LENGTH_MINUTES = 1440 );

-----------------------------------------------------------------------------------------------------------------------------------------------
The Max Size (MB) 
-----------------------------------------------------------------------------------------------------------------------------------------------
/*
is for configuring the maximum size of the SQL Server Query Store. 
By default, the maximum size of the SQL Server Query Store is set to 100 MB. 
The data in the SQL Server Query Store is stored in the database where the SQL Server Query Store is enabled. 
The SQL Server Query Store doesn’t auto grow and once the SQL Server Query Store reaches the maximum size, the Operation Mode will be switched to 
the Read Only mode, automatically, and new query execution plan and query runtime statistics will not be collected
*/
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON ( MAX_STORAGE_SIZE_MB = 1024 );

-----------------------------------------------------------------------------------------------------------------------------------------------
The Query Store Capture Mode (ALL, AUTO, CUSTOM, NONE)
-----------------------------------------------------------------------------------------------------------------------------------------------
/*
determines what type of query will be captured in the Query Store. 
By default, the Query Store Capture Mode option is set to All, which means that every executed query will be stored in the SQL Server Query Store that 
runs on the database. 
When the Query Store Capture Mode option is set to Auto then the SQL Server Query Store will try to triage which query capture, by priority, and try to 
ignore infrequently executed and other ad hoc queries. 
Also, there is the third value in the Query Store Capture Mode drop down box which is None. 
When the None value is chosen, then the SQL Server Query Store will not gather information for the new queries and will continue gathering information only on 
the queries that it has been recorded previously
*/
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON ( QUERY_CAPTURE_MODE = ALL );

-----------------------------------------------------------------------------------------------------------------------------------------------
Size Based Cleanup Mode (AUTO, OFF)
-----------------------------------------------------------------------------------------------------------------------------------------------
/*
is for cleaning the SQL Server Query Store data when the maximum size in the Max Size (MB) option is reached to 90% of capacity. 
The cleanup process will remove the oldest and less expensive query data. 
The cleanup process stops when 80% of the maximum size in the Max Size (MB) option is reached. 
By default, this option is set to Auto. If in the Size Based Cleanup Mode drop down box the Off value is set, then the cleanup process will not be performed 
when the size of the SQL Server Query Store reaches 90% of the maximum size and the SQL Server Query Store will go to Read Only mode when the maximum size is 
reached
*/
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON ( SIZE_BASED_CLEANUP_MODE = AUTO );

-----------------------------------------------------------------------------------------------------------------------------------------------
Stale Query Threshold (Days) 
-----------------------------------------------------------------------------------------------------------------------------------------------
--is for defining how long the data will stay in the SQL Server Query Store. By default, it is set for 30 days
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON ( CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30) );

-----------------------------------------------------------------------------------------------------------------------------------------------
MAX_PLANS_PER_QUERY
-----------------------------------------------------------------------------------------------------------------------------------------------
/*
On more options that can be set via T-SQL and not present in the SQL Server Query Store tab is :
With this option, maximum Execution Plans can be set that will be stored in the SQL Server Query Store per query. 
By default, this is set to 200 Execution Plans per query.
*/
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE = ON ( MAX_PLANS_PER_QUERY=200 );

-----------------------------------------------------------------------------------------------------------------------------------------------
Purge Query Data
-----------------------------------------------------------------------------------------------------------------------------------------------
--The last option on the SQL Server Query Store tab is an option that clears/purges all data in the SQL Server Query Store
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE CLEAR;
ALTER DATABASE AdventureWorks2014 SET QUERY_STORE CLEAR ALL;

--Note, query plans that show the SQL Server Query Store are estimated execution plans not actual execution plans.

-----------------------------------------------------------------------------------------------------------------------------------------------
Waits Statistics Capture Mode (ON, OFF)
-----------------------------------------------------------------------------------------------------------------------------------------------
--Select ON to capture wait statistics 
--Select OFF to stop capturing wait statistics 

-----------------------------------------------------------------------------------------------------------------------------------------------
Trace Flags 7745 e 7752
-----------------------------------------------------------------------------------------------------------------------------------------------

Trace Flag 7745 – Evita que o SQL aguarde o flush da memória para o disco dos dados do QUERY_STORE
Trace Flag 7752 – Faz com que o SQL carregue dados do QUERY_STORE em memória de forma assíncrona ao iniciar o serviço

--https://learn.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-traceon-trace-flags-transact-sql?view=sql-server-2017
--https://www.fabriciolima.net/blog/2019/02/26/query-store-04-melhores-praticas-para-habilitar-o-query-store/

-----------------------------------------------------------------------------------------------------------------------------------------------
QDS_STMT
-----------------------------------------------------------------------------------------------------------------------------------------------
--ocorre uma espera para inserir novos registros no local da memória onde as informações das queries executadas são armazenados pelo Query Store

 ALTER DATABASE NOME SET QUERY_STORE = OFF






-----------------------------------------------------------------------------------------------------------------------------------------------
Reports
-----------------------------------------------------------------------------------------------------------------------------------------------

--Regressed Queries is a built-in report that shows all queries that execution matrices are degraded in specific time range (last hour, day, week)

--The Regressed Queries built-in report is divided in several pans. By default, the top 25 regressed queries in the last hour are shown.
--The Overall Resource Consumption built-in report shows summary resource consumption during the specific set of time. 
--By default, results are shown for the last month and the results are shown in four charts: Duration, CPU Time, Logical Reads and Execution count

--To set additional charts report, time and aggregation interval, press the Configure button and the Configure Overall Resource Consumption dialog will appear 
--where different options can be set for the Overall Resource Consumption report

--The Top Resource Consuming Queries built-in report shows, by default, the top 25 queries against specific database that consume most of resources like 
--CPU Time, Memory Consumption, Physical Reads etc. over specific set of time

--With the Tracked Queries built-in report, query runtime statistics and query Execution plans can be tracked for the specific query over time. 
--In the Tracking query text box, enter the query id (e.g. 205) and press the green play button next to the Tracking query box

--The Queries With Forced Plans built-in report shows all forced Execution Plans for specific queries

--To force SQL Server to use a specific Execution Plan for the particular query, in the Regressed Queries, Top Resource Consuming Queries, Queries With 
--Hight Variation or Tracked Queries built-in reports, first select the Execution Plan Id and click the Force Plan button
--By doing this, you force SQL Server to use this Execution Plan for specific query from now on when that query is executed. 
--This means that SQL Server will not generate a new Execution Plans for that query until unforce that plan.

--To unforce SQL Server to use a specific Execution Plan for the particle query in the Queries With Forced Plans, Regressed Queries, Top Resource Consuming 
--Queries, Queries With High Variation or Tracked Queries report, select the Execution Plan and press the Unforce Plan button

--The Queries With High Variation built-in report analyze the queries and show the queries with the most frequent parameterization problems


--#############################################################################################################################################
-----------------------------------------------------------------------------------------------------------------------------------------------
--#############################################################################################################################################


-----------------------------------------------------------------------------------------------------------------------------------------------
DMVS
----------------------------------------------------------------------------------------------------------------------------------------------
select top 3 * from sys.query_context_settings
select top 3 * from sys.query_store_plan
select top 3 * from sys.query_store_query
select top 3 * from sys.query_store_query_text
select top 3 * from sys.query_store_runtime_stats
select top 3 * from sys.query_store_runtime_stats_interval
select top 3 * from sys.query_store_wait_stats

-----------------------------------------------------------------------------------------------------------------------------------------------


select * from sys.query_store_runtime_stats where plan_id = 44
select * from sys.query_store_runtime_stats_interval

-----------------------------------------------------------------------------------------------------------------------------------------------
--espaço utilizado QUERY_STORE
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT	actual_state_desc, desired_state_desc, current_storage_size_mb, max_storage_size_mb, readonly_reason  
FROM 	sys.database_query_store_options;

--How Query Store collects data
--https://learn.microsoft.com/en-us/sql/relational-databases/performance/how-query-store-collects-data?view=sql-server-ver16

--query store hints
--https://learn.microsoft.com/en-us/sql/relational-databases/performance/query-store-hints?view=sql-server-ver16

--links
--https://learn.microsoft.com/en-us/sql/relational-databases/performance/tune-performance-with-the-query-store?view=sql-server-ver16

-----------------------------------------------------------------------------------------------------------------------------------------------
 Last queries executed on the database
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 10 qt.query_sql_text, q.query_id,
    qt.query_text_id, p.plan_id, rs.last_execution_time
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id = rs.plan_id
ORDER BY rs.last_execution_time DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------
Execution counts
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT q.query_id, qt.query_text_id, qt.query_sql_text,
    SUM(rs.count_executions) AS total_execution_count
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id = rs.plan_id
GROUP BY q.query_id, qt.query_text_id, qt.query_sql_text
ORDER BY total_execution_count DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------
Longest average execution time
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 10 rs.avg_duration, qt.query_sql_text, q.query_id,
    qt.query_text_id, p.plan_id, GETUTCDATE() AS CurrentUTCTime,
    rs.last_execution_time
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id = rs.plan_id
WHERE rs.last_execution_time > DATEADD(hour, -1, GETUTCDATE())
ORDER BY rs.avg_duration DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------
Biggest average physical I/O reads
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 10 rs.avg_physical_io_reads, qt.query_sql_text,
    q.query_id, qt.query_text_id, p.plan_id, rs.runtime_stats_id,
    rsi.start_time, rsi.end_time, rs.avg_rowcount, rs.count_executions
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats AS rs
    ON p.plan_id = rs.plan_id
JOIN sys.query_store_runtime_stats_interval AS rsi
    ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
WHERE rsi.start_time >= DATEADD(hour, -24, GETUTCDATE())
ORDER BY rs.avg_physical_io_reads DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------
Queries with multiple plans
-----------------------------------------------------------------------------------------------------------------------------------------------
WITH Query_MultPlans
AS
(
SELECT COUNT(*) AS cnt, q.query_id
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p
    ON p.query_id = q.query_id
GROUP BY q.query_id
HAVING COUNT(distinct plan_id) > 1
)

SELECT q.query_id, object_name(object_id) AS ContainingObject,
    query_sql_text, plan_id, p.query_plan AS plan_xml,
    p.last_compile_start_time, p.last_execution_time
FROM Query_MultPlans AS qm
JOIN sys.query_store_query AS q
    ON qm.query_id = q.query_id
JOIN sys.query_store_plan AS p
    ON q.query_id = p.query_id
JOIN sys.query_store_query_text qt
    ON qt.query_text_id = q.query_text_id
ORDER BY query_id, plan_id;

-----------------------------------------------------------------------------------------------------------------------------------------------
Highest wait durations
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 10
    qt.query_text_id,
    q.query_id,
    p.plan_id,
    sum(total_query_wait_time_ms) AS sum_total_wait_ms
FROM sys.query_store_wait_stats ws
JOIN sys.query_store_plan p ON ws.plan_id = p.plan_id
JOIN sys.query_store_query q ON p.query_id = q.query_id
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
GROUP BY qt.query_text_id, q.query_id, p.plan_id
ORDER BY sum_total_wait_ms DESC;

-----------------------------------------------------------------------------------------------------------------------------------------------
Queries that recently regressed in performance
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    qt.query_sql_text,
    q.query_id,
    qt.query_text_id,
    rs1.runtime_stats_id AS runtime_stats_id_1,
    rsi1.start_time AS interval_1,
    p1.plan_id AS plan_1,
    rs1.avg_duration AS avg_duration_1,
    rs2.avg_duration AS avg_duration_2,
    p2.plan_id AS plan_2,
    rsi2.start_time AS interval_2,
    rs2.runtime_stats_id AS runtime_stats_id_2
FROM sys.query_store_query_text AS qt
JOIN sys.query_store_query AS q
    ON qt.query_text_id = q.query_text_id
JOIN sys.query_store_plan AS p1
    ON q.query_id = p1.query_id
JOIN sys.query_store_runtime_stats AS rs1
    ON p1.plan_id = rs1.plan_id
JOIN sys.query_store_runtime_stats_interval AS rsi1
    ON rsi1.runtime_stats_interval_id = rs1.runtime_stats_interval_id
JOIN sys.query_store_plan AS p2
    ON q.query_id = p2.query_id
JOIN sys.query_store_runtime_stats AS rs2
    ON p2.plan_id = rs2.plan_id
JOIN sys.query_store_runtime_stats_interval AS rsi2
    ON rsi2.runtime_stats_interval_id = rs2.runtime_stats_interval_id
WHERE rsi1.start_time > DATEADD(hour, -48, GETUTCDATE())
    AND rsi2.start_time > rsi1.start_time
    AND p1.plan_id <> p2.plan_id
    AND rs2.avg_duration > 2*rs1.avg_duration
ORDER BY q.query_id, rsi1.start_time, rsi2.start_time;

-----------------------------------------------------------------------------------------------------------------------------------------------
Queries with historical regression in performance
-----------------------------------------------------------------------------------------------------------------------------------------------
--- "Recent" workload - last 1 hour
DECLARE @recent_start_time datetimeoffset;
DECLARE @recent_end_time datetimeoffset;
SET @recent_start_time = DATEADD(hour, -1, SYSUTCDATETIME());
SET @recent_end_time = SYSUTCDATETIME();

--- "History" workload
DECLARE @history_start_time datetimeoffset;
DECLARE @history_end_time datetimeoffset;
SET @history_start_time = DATEADD(hour, -24, SYSUTCDATETIME());
SET @history_end_time = SYSUTCDATETIME();

WITH
hist AS
(
    SELECT
        p.query_id query_id,
        ROUND(ROUND(CONVERT(FLOAT, SUM(rs.avg_duration * rs.count_executions)) * 0.001, 2), 2) AS total_duration,
        SUM(rs.count_executions) AS count_executions,
        COUNT(distinct p.plan_id) AS num_plans
     FROM sys.query_store_runtime_stats AS rs
        JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
    WHERE (rs.first_execution_time >= @history_start_time
               AND rs.last_execution_time < @history_end_time)
        OR (rs.first_execution_time <= @history_start_time
               AND rs.last_execution_time > @history_start_time)
        OR (rs.first_execution_time <= @history_end_time
               AND rs.last_execution_time > @history_end_time)
    GROUP BY p.query_id
),
recent AS
(
    SELECT
        p.query_id query_id,
        ROUND(ROUND(CONVERT(FLOAT, SUM(rs.avg_duration * rs.count_executions)) * 0.001, 2), 2) AS total_duration,
        SUM(rs.count_executions) AS count_executions,
        COUNT(distinct p.plan_id) AS num_plans
    FROM sys.query_store_runtime_stats AS rs
        JOIN sys.query_store_plan AS p ON p.plan_id = rs.plan_id
    WHERE  (rs.first_execution_time >= @recent_start_time
               AND rs.last_execution_time < @recent_end_time)
        OR (rs.first_execution_time <= @recent_start_time
               AND rs.last_execution_time > @recent_start_time)
        OR (rs.first_execution_time <= @recent_end_time
               AND rs.last_execution_time > @recent_end_time)
    GROUP BY p.query_id
)
SELECT
    results.query_id AS query_id,
    results.query_text AS query_text,
    results.additional_duration_workload AS additional_duration_workload,
    results.total_duration_recent AS total_duration_recent,
    results.total_duration_hist AS total_duration_hist,
    ISNULL(results.count_executions_recent, 0) AS count_executions_recent,
    ISNULL(results.count_executions_hist, 0) AS count_executions_hist
FROM
(
    SELECT
        hist.query_id AS query_id,
        qt.query_sql_text AS query_text,
        ROUND(CONVERT(float, recent.total_duration/
                   recent.count_executions-hist.total_duration/hist.count_executions)
               *(recent.count_executions), 2) AS additional_duration_workload,
        ROUND(recent.total_duration, 2) AS total_duration_recent,
        ROUND(hist.total_duration, 2) AS total_duration_hist,
        recent.count_executions AS count_executions_recent,
        hist.count_executions AS count_executions_hist
    FROM hist
        JOIN recent
            ON hist.query_id = recent.query_id
        JOIN sys.query_store_query AS q
            ON q.query_id = hist.query_id
        JOIN sys.query_store_query_text AS qt
            ON q.query_text_id = qt.query_text_id
) AS results
WHERE additional_duration_workload > 0
ORDER BY additional_duration_workload DESC
OPTION (MERGE JOIN);

-----------------------------------------------------------------------------------------------------------------------------------------------
Force a plan for a query (apply forcing policy)
-----------------------------------------------------------------------------------------------------------------------------------------------
EXEC sp_query_store_force_plan @query_id = 48, @plan_id = 49;

-----------------------------------------------------------------------------------------------------------------------------------------------
Remove plan forcing for a query
-----------------------------------------------------------------------------------------------------------------------------------------------
EXEC sp_query_store_unforce_plan @query_id = 48, @plan_id = 49;



-----------------------------------------------------------------------------------------------------------------------------------------------
--regressed queries ???
-----------------------------------------------------------------------------------------------------------------------------------------------
exec sp_executesql N'WITH
hist AS
(
    SELECT 
        p.query_id query_id, 
        CONVERT(float, MAX(rs.max_duration)) max_duration, 
        SUM(rs.count_executions) count_executions,
        COUNT(distinct p.plan_id) num_plans 
    FROM sys.query_store_runtime_stats rs
        JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id
    WHERE NOT (rs.first_execution_time > @history_end_time OR rs.last_execution_time < @history_start_time)
    GROUP BY p.query_id
),
recent AS
(
    SELECT 
        p.query_id query_id, 
        CONVERT(float, MAX(rs.max_duration)) max_duration, 
        SUM(rs.count_executions) count_executions,
        COUNT(distinct p.plan_id) num_plans 
    FROM sys.query_store_runtime_stats rs
        JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id
    WHERE NOT (rs.first_execution_time > @recent_end_time OR rs.last_execution_time < @recent_start_time)
    GROUP BY p.query_id
)
SELECT TOP (@results_row_count)
    results.query_id query_id,
    results.query_text query_text,
    results.duration_regr_perc_recent duration_regr_perc_recent,
    results.max_duration_recent max_duration_recent,
    results.max_duration_hist max_duration_hist,
    ISNULL(results.count_executions_recent, 0) count_executions_recent,
    ISNULL(results.count_executions_hist, 0) count_executions_hist,
    queries.num_plans num_plans
FROM
(
    SELECT
        hist.query_id query_id,
        qt.query_sql_text query_text,
        ROUND(CONVERT(float, recent.max_duration-hist.max_duration)/NULLIF(hist.max_duration,0)*100.0, 2) duration_regr_perc_recent,
        ROUND(recent.max_duration, 2) max_duration_recent, 
        ROUND(hist.max_duration, 2) max_duration_hist,
        recent.count_executions count_executions_recent,
        hist.count_executions count_executions_hist   
    FROM hist 
        JOIN recent ON hist.query_id = recent.query_id        
        JOIN sys.query_store_query q ON q.query_id = hist.query_id
        JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
    WHERE
        recent.count_executions >= @min_exec_count
) AS results
JOIN 
(
    SELECT
        p.query_id query_id, 
        COUNT(distinct p.plan_id) num_plans 
    FROM sys.query_store_plan p       
    GROUP BY p.query_id
) AS queries ON queries.query_id = results.query_id
WHERE duration_regr_perc_recent > 0
ORDER BY duration_regr_perc_recent DESC
OPTION (MERGE JOIN)',N'@results_row_count int,@recent_start_time datetimeoffset(7),@recent_end_time datetimeoffset(7),@history_start_time datetimeoffset(7),@history_end_time datetimeoffset(7),@min_exec_count bigint',@results_row_count=25,@recent_start_time='2016-01-18 14:00:42.7253669 -08:00',@recent_end_time='2016-01-18 15:00:42.7253669 -08:00',@history_start_time='2016-01-11 15:00:42.7253669 -08:00',@history_end_time='2016-01-18 15:00:42.7253669 -08:00',@min_exec_count=1;
GO


-----------------------------------------------------------------------------------------------------------------------------------------------
--top 20 CPU
-----------------------------------------------------------------------------------------------------------------------------------------------
SELECT      top 20
            q.query_hash, 
            SUM(count_executions) AS total_executions, 
            SUM(count_executions * avg_cpu_time / 1000.0) AS total_cpu_millisec, 
            SUM(count_executions * avg_cpu_time / 1000.0)/ SUM(count_executions) AS avg_cpu_millisec, 
            MAX(rs.max_cpu_time / 1000.00) AS max_cpu_millisec, 
            MIN(rs.min_cpu_time / 1000.00) AS min_cpu_time, 
            SUM(count_executions * avg_duration / 1000.0) AS total_duration_millisec, 
            SUM(count_executions * avg_duration / 1000.0)/ SUM(count_executions) AS avg_duration_millisec, 
            MAX(rs.max_duration / 1000.00) AS max_duration_millisec, 
            MIN(rs.min_duration / 1000.00) AS min_duration, 
            SUM(count_executions * avg_physical_io_reads) AS total_physical_io_reads, 
            SUM(count_executions * avg_physical_io_reads)/ SUM(count_executions) AS avg_physical_io_reads, 
            MAX(rs.max_physical_io_reads) AS max_physical_io_reads, 
            MIN(rs.min_physical_io_reads) AS min_physical_io_reads, 
            SUM(count_executions * avg_logical_io_reads) AS total_logical_io_reads, 
            SUM(count_executions * avg_logical_io_reads)/ SUM(count_executions) AS avg_logical_io_reads, 
            MAX(rs.max_logical_io_reads) AS max_logical_io_reads, 
            MIN(rs.min_logical_io_reads) AS min_logical_io_reads, 
            SUM(count_executions * avg_logical_io_writes) AS total_logical_io_writes, 
            SUM(count_executions * avg_logical_io_writes)/ SUM(count_executions) AS avg_logical_io_writes, 
            MAX(rs.max_logical_io_writes) AS max_logical_io_writes, 
            MIN(rs.min_logical_io_writes) AS min_logical_io_writes, 
            SUM(count_executions * avg_query_max_used_memory) AS total_query_max_used_memory, 
            SUM(count_executions * avg_query_max_used_memory)/ SUM(count_executions) AS avg_query_max_used_memory, 
            MAX(rs.max_query_max_used_memory) AS max_query_max_used_memory, 
            MIN(rs.min_query_max_used_memory) AS min_query_max_used_memory, 
            SUM(count_executions * avg_rowcount) AS total_rowcount, 
            SUM(count_executions * avg_rowcount)/ SUM(count_executions) AS avg_rowcount, 
            MAX(rs.max_rowcount) AS max_rowcount, 
            MIN(rs.min_rowcount) AS min_rowcount, 
            SUM(CASE WHEN rs.execution_type_desc='Regular' THEN count_executions ELSE 0 END) AS Regular_Execution_Count, 
            SUM(CASE WHEN rs.execution_type_desc='Aborted' THEN count_executions ELSE 0 END) AS Aborted_Execution_Count, 
            SUM(CASE WHEN rs.execution_type_desc='Exception' THEN count_executions ELSE 0 END) AS Exception_Execution_Count, 
            COUNT(DISTINCT p.plan_id) AS number_of_distinct_plans, 
            COUNT(DISTINCT p.query_id) AS number_of_distinct_query_ids, 
            MIN(qt.query_sql_text) AS sampled_query_text
FROM        sys.query_store_query_text AS qt
JOIN        sys.query_store_query AS q ON qt.query_text_id=q.query_text_id
JOIN        sys.query_store_plan AS p ON q.query_id=p.query_id
JOIN        sys.query_store_runtime_stats AS rs ON rs.plan_id=p.plan_id
JOIN        sys.query_store_runtime_stats_interval AS rsi ON rsi.runtime_stats_interval_id=rs.runtime_stats_interval_id
WHERE       1 = 1
and         rs.execution_type_desc IN ('Regular', 'Aborted', 'Exception')
--and           q.query_id in (107, 116)
--and           datediff(mi,rs.last_execution_time,dateadd(hh,+3,getdate())) <= 60
GROUP BY    q.query_hash
--order by  total_cpu_millisec desc
order by    avg_cpu_millisec desc

-----------------------------------------------------------------------------------------------------------------------------------------------
--get plan top 20 CPU (analisar)
-----------------------------------------------------------------------------------------------------------------------------------------------

--select        p.plan_id, p.query_plan,    sq.query_id,    CPU.*
select      sq.query_id,    CPU.*
from        (
                SELECT      top 20
                            q.query_hash, 
                            SUM(count_executions) AS total_executions, 
                            SUM(count_executions * avg_cpu_time / 1000.0) AS total_cpu_millisec, 
                            SUM(count_executions * avg_cpu_time / 1000.0)/ SUM(count_executions) AS avg_cpu_millisec, 
                            MAX(rs.max_cpu_time / 1000.00) AS max_cpu_millisec, 
                            MIN(rs.min_cpu_time / 1000.00) AS min_cpu_time, 
                            SUM(count_executions * avg_duration / 1000.0) AS total_duration_millisec, 
                            SUM(count_executions * avg_duration / 1000.0)/ SUM(count_executions) AS avg_duration_millisec, 
                            MAX(rs.max_duration / 1000.00) AS max_duration_millisec, 
                            MIN(rs.min_duration / 1000.00) AS min_duration, 
                            SUM(count_executions * avg_physical_io_reads) AS total_physical_io_reads, 
                            SUM(count_executions * avg_physical_io_reads)/ SUM(count_executions) AS avg_physical_io_reads, 
                            MAX(rs.max_physical_io_reads) AS max_physical_io_reads, 
                            MIN(rs.min_physical_io_reads) AS min_physical_io_reads, 
                            SUM(count_executions * avg_logical_io_reads) AS total_logical_io_reads, 
                            SUM(count_executions * avg_logical_io_reads)/ SUM(count_executions) AS avg_logical_io_reads, 
                            MAX(rs.max_logical_io_reads) AS max_logical_io_reads, 
                            MIN(rs.min_logical_io_reads) AS min_logical_io_reads, 
                            SUM(count_executions * avg_logical_io_writes) AS total_logical_io_writes, 
                            SUM(count_executions * avg_logical_io_writes)/ SUM(count_executions) AS avg_logical_io_writes, 
                            MAX(rs.max_logical_io_writes) AS max_logical_io_writes, 
                            MIN(rs.min_logical_io_writes) AS min_logical_io_writes, 
                            SUM(count_executions * avg_query_max_used_memory) AS total_query_max_used_memory, 
                            SUM(count_executions * avg_query_max_used_memory)/ SUM(count_executions) AS avg_query_max_used_memory, 
                            MAX(rs.max_query_max_used_memory) AS max_query_max_used_memory, 
                            MIN(rs.min_query_max_used_memory) AS min_query_max_used_memory, 
                            SUM(count_executions * avg_rowcount) AS total_rowcount, 
                            SUM(count_executions * avg_rowcount)/ SUM(count_executions) AS avg_rowcount, 
                            MAX(rs.max_rowcount) AS max_rowcount, 
                            MIN(rs.min_rowcount) AS min_rowcount, 
                            SUM(CASE WHEN rs.execution_type_desc='Regular' THEN count_executions ELSE 0 END) AS Regular_Execution_Count, 
                            SUM(CASE WHEN rs.execution_type_desc='Aborted' THEN count_executions ELSE 0 END) AS Aborted_Execution_Count, 
                            SUM(CASE WHEN rs.execution_type_desc='Exception' THEN count_executions ELSE 0 END) AS Exception_Execution_Count, 
                            COUNT(DISTINCT p.plan_id) AS number_of_distinct_plans, 
                            COUNT(DISTINCT p.query_id) AS number_of_distinct_query_ids, 
                            MIN(qt.query_sql_text) AS sampled_query_text
                FROM        sys.query_store_query_text AS qt
                JOIN        sys.query_store_query AS q ON qt.query_text_id=q.query_text_id
                JOIN        sys.query_store_plan AS p ON q.query_id=p.query_id
                JOIN        sys.query_store_runtime_stats AS rs ON rs.plan_id=p.plan_id
                JOIN        sys.query_store_runtime_stats_interval AS rsi ON rsi.runtime_stats_interval_id=rs.runtime_stats_interval_id
                WHERE       1 = 1
                and         rs.execution_type_desc IN ('Regular', 'Aborted', 'Exception')
                --and           q.query_id in (107, 116)
                --and           datediff(mi,rs.last_execution_time,dateadd(hh,+3,getdate())) <= 60
                GROUP BY    q.query_hash
                --order by  total_cpu_millisec desc
                order by    avg_cpu_millisec desc
) as CPU
inner join      sys.query_store_query sq
    on          CPU.query_hash = sq.query_hash
--inner join        sys.query_store_plan p
--  on          sq.query_id = p.query_id
order by        CPU.query_hash