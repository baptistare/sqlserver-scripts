--###############################################################################################################################################################################################################################
--SINGLE USE PLANS - CACHE BLOAT
--###############################################################################################################################################################################################################################

--plan cache by objtype
select 'Utilização Plan Cache'

select		objtype as [CacheType]
			, count_big(*) as [Total Plans]
			, sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 as [Total MBs]
			, avg(usecounts) as [Avg Use Count]
			, sum(cast((case when usecounts = 1 then size_in_bytes else 0 end) as decimal(18,2)))/1024/1024 as [Total MBs - USE Count 1]
			, sum(case when usecounts = 1 then 1 else 0 end) as [Total Plans - USE Count 1]
from		sys.dm_exec_cached_plans
group by	objtype
order by	[Total MBs - USE Count 1] desc

--total size plan cache
select sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 as [Total MBs] from sys.dm_exec_cached_plans

--total size single use plan in plan cache
select sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 as [Total MBs - Single Use Plans] from sys.dm_exec_cached_plans where usecounts = 1

--total size single use plan in plan cache - percent
select (select sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 as [Total MBs] from sys.dm_exec_cached_plans where usecounts = 1) / (select sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 as [Total MBs] from sys.dm_exec_cached_plans) as percent_single_use_plan

--text single use plan
select		text, cp.objtype, cp.size_in_bytes
from		sys.dm_exec_cached_plans as cp 
cross apply sys.dm_exec_sql_text(cp.plan_handle) st
where		cp.cacheobjtype = N'Compiled Plan'
	AND		cp.objtype IN (N'Adhoc', N'Prepared')
	and		cp.usecounts = 1
order by	cp.size_in_bytes desc 
option		(recompile);

--###############################################################################################################################################################################################################################
--
--###############################################################################################################################################################################################################################

--MissingIndexes
;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')       
SELECT dec.usecounts, dec.refcounts, dec.objtype
      ,dec.cacheobjtype, des.dbid, des.text      
      ,deq.query_plan 
FROM sys.dm_exec_cached_plans AS dec 
     CROSS APPLY sys.dm_exec_sql_text(dec.plan_handle) AS des 
     CROSS APPLY sys.dm_exec_query_plan(dec.plan_handle) AS deq 
WHERE deq.query_plan.exist(N'/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup') <> 0 
ORDER BY dec.usecounts DESC 

--ImplicitConversions
;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT 
cp.query_hash, cp.query_plan_hash,
ConvertIssue = operators.value('@ConvertIssue', 'nvarchar(250)'), 
Expression = operators.value('@Expression', 'nvarchar(250)'), qp.query_plan
FROM sys.dm_exec_query_stats cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY query_plan.nodes('//Warnings/PlanAffectingConvert') rel(operators)		

--Lookups
;WITH XMLNAMESPACES(DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
SELECT 
cp.query_hash, cp.query_plan_hash,
PhysicalOperator = operators.value('@PhysicalOp','nvarchar(50)'), 
LogicalOp = operators.value('@LogicalOp','nvarchar(50)'),
AvgRowSize = operators.value('@AvgRowSize','nvarchar(50)'),
EstimateCPU = operators.value('@EstimateCPU','nvarchar(50)'),
EstimateIO = operators.value('@EstimateIO','nvarchar(50)'),
EstimateRebinds = operators.value('@EstimateRebinds','nvarchar(50)'),
EstimateRewinds = operators.value('@EstimateRewinds','nvarchar(50)'),
EstimateRows = operators.value('@EstimateRows','nvarchar(50)'),
Parallel = operators.value('@Parallel','nvarchar(50)'),
NodeId = operators.value('@NodeId','nvarchar(50)'),
EstimatedTotalSubtreeCost = operators.value('@EstimatedTotalSubtreeCost','nvarchar(50)')
FROM sys.dm_exec_query_stats cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY query_plan.nodes('//RelOp') rel(operators)