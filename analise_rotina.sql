--#######################################################################################################################################################
--PRODECURE_CACHE
--#######################################################################################################################################################

select		
			substring	(
							dest.text, 
							deqs.statement_start_offset / 2,
							( 
								case 
									when deqs.statement_end_offset = -1
									then len(convert(nvarchar(max), dest.[text])) * 2
									else deqs.statement_end_offset
								end - deqs.statement_start_offset 
							) / 2
						) as statement_executing,
			db_name(deps.database_id) as databaseName,
			object_name(deps.object_id,deps.database_id) as objectName,
			deps.cached_time as p_cached_time,
			deps.last_execution_time as p_last_execution_time,
			deps.execution_count as p_execution_count,
			deqs.creation_time as q_creation_time,
			deqs.last_execution_time as q_last_execution_time,
			deqs.execution_count as q_execution_count,
			deqs.total_rows as q_total_rows,
			deps.last_worker_time as p_last_worker_time,
			deps.last_physical_reads as p_last_physical_reads,
			deps.last_logical_reads as p_last_logical_reads,
			deps.last_logical_writes as p_last_logical_writes,
			deps.last_elapsed_time as p_last_elapsed_time,
			deqs.last_worker_time as q_last_worker_time,
			deqs.last_physical_reads as q_last_physical_reads,
			deqs.last_logical_reads as q_last_logical_reads,
			deqs.last_logical_writes as q_last_logical_writes,
			deqs.last_elapsed_time as q_last_elapsed_time,
			deps.total_worker_time as p_total_worker_time, 
			deps.total_physical_reads as p_total_physical_reads,			
			deps.total_logical_reads as p_total_logical_reads,
			deps.total_logical_writes as p_total_logical_writes,
			deps.total_elapsed_time as p_total_elapsed_time,
			deqs.total_worker_time as q_total_worker_time, 
			deqs.total_physical_reads as q_total_physical_reads,
			deqs.total_logical_reads as q_total_logical_reads,
			deqs.total_logical_writes as q_total_logical_writes,
			deqs.total_elapsed_time as q_total_elapsed_time,
			deps.min_worker_time as p_min_worker_time,
			deps.min_physical_reads as p_min_physical_reads,
			deps.min_logical_reads as p_min_logical_reads,
			deps.min_logical_writes as p_min_logical_writes,
			deps.min_elapsed_time as min_elapsed_time,
			deqs.min_worker_time as q_min_worker_time,
			deqs.min_physical_reads as q_min_physical_reads,
			deqs.min_logical_reads as q_min_logical_reads,
			deqs.min_logical_writes as q_min_logical_writes,
			deqs.min_elapsed_time as q_min_elapsed_time,
			deps.max_worker_time as p_max_worker_time,
			deps.max_physical_reads as p_max_physical_reads,
			deps.max_logical_reads as p_max_logical_reads,
			deps.max_logical_writes as p_max_logical_writes,
			deps.max_elapsed_time as p_max_elapsed_time,
			deqs.max_worker_time as q_max_worker_time,
			deqs.max_physical_reads as q_max_physical_reads,
			deqs.max_logical_reads as q_max_logical_reads,
			deqs.max_logical_writes as q_max_logical_writes,
			deqs.max_elapsed_time as q_max_elapsed_time,
			--cast(dest.text as xml) as text,
			SUBSTRING	(
							dest.[text], deqs.statement_start_offset / 2,
							(	CASE	
									WHEN deqs.statement_end_offset = -1
									THEN LEN(CONVERT(NVARCHAR(MAX), dest.[text])) * 2
									ELSE deqs.statement_end_offset
								END - deqs.statement_start_offset 
							) / 2
						) as statement_executing,
			--cast(
			--		SUBSTRING	(
			--						dest.[text], deqs.statement_start_offset / 2, 
			--						(	CASE
			--								WHEN deqs.statement_end_offset = -1
			--								THEN LEN(CONVERT(NVARCHAR(MAX), dest.[text])) * 2
			--								ELSE deqs.statement_end_offset
			--							END - deqs.statement_start_offset 
			--						) / 2
			--					) as xml
			--	) as statement_executing,
			deqp.query_plan,
			deps.plan_handle as proc_plan_handle,
			deps.sql_handle as proc_sql_handle,
			deqs.sql_handle as query_sql_handle,
			deqs.plan_handle as query_plan_handle,
			deqs.statement_start_offset as query_statement_start_offset,
			deqs.statement_end_offset as query_statement_end_offset,
			dest.number as sql_text_number,
			deqp.number as text_query_plan_number
from		sys.dm_exec_procedure_stats deps
inner join	sys.dm_exec_query_stats deqs
	on		deps.sql_handle = deqs.sql_handle
cross apply sys.dm_exec_sql_text (deps.sql_handle) dest
cross apply sys.dm_exec_query_plan (deps.plan_handle) deqp
--query plan is null
--cross apply sys.dm_exec_sql_text (deqs.sql_handle) dest
--cross apply sys.dm_exec_text_query_plan (deqs.plan_handle, deqs.statement_start_offset, deqs.statement_end_offset) deqp
--where		deps.object_id = object_id('culturadb.dbo.SPC_FC_CMV_Kardex')
where		deps.database_id = 5
	and		datediff(mi, deps.last_execution_time, getdate()) < 3
	and		deps.object_id = object_id('culturadb.dbo.SPC_Atualiza_CartaoCult_CPF_Internet')
--order by	deqs.last_worker_time desc
--order by	deqs.total_worker_time desc
--order by	deqs.last_elapsed_time desc
--order by	deqs.total_elapsed_time desc
--order by	deps.last_elapsed_time desc, deps.execution_count desc
--order by	deps.execution_count desc, deps.last_physical_reads desc

/*
from sys.dm_exec_procedure_stats deps
inner join sys.dm_exec_query_stats deqs
	on	deps.sql_handle = deqs.sql_handle
cross apply sys.dm_exec_sql_text (deqs.sql_handle) dest
cross apply sys.dm_exec_text_query_plan (deqs.plan_handle, deqs.statement_start_offset, deqs.statement_end_offset) deqp
where database_id = DB_ID('BDTGTC')
--and last_execution_time >= DATEADD(mi,-10,getdate())
and deps.object_id = object_id('BDTGTC.dbo.PR_GT_INTEGRACAO')
order by deps.last_elapsed_time desc
*/


select		top 10 *
from		sys.dm_exec_procedure_stats deps
--inner join	sys.dm_exec_query_stats deqs
--	on		deps.sql_handle = deqs.sql_handle
cross apply sys.dm_exec_sql_text (deps.sql_handle) dest
cross apply sys.dm_exec_query_plan (deps.plan_handle) deqp
--query plan is null
--cross apply sys.dm_exec_sql_text (deqs.sql_handle) dest
--cross apply sys.dm_exec_text_query_plan (deqs.plan_handle, deqs.statement_start_offset, deqs.statement_end_offset) deqp
--where		deps.object_id = object_id('culturadb.dbo.SPC_FC_CMV_Kardex')
where		deps.database_id = 5
	--and		datediff(mi, deps.last_execution_time, getdate()) < 3
	order by deps.total_worker_time / deps.execution_count desc

--#######################################################################################################################################################
--INFOS
--#######################################################################################################################################################

--indices
select		
			t.name,
			i.name,
			i.type_desc,
			i.index_id,
			COL_NAME(t.object_id,ic.column_id) as column_name,
			ic.key_ordinal,
			ic.is_included_column,
			ty.name as data_type,
			c.max_length,
			i.is_primary_key,
			c.is_identity,
			i.is_unique,
			c.is_nullable,
			i.ignore_dup_key,
			i.is_unique_constraint,
			i.is_disabled,
			i.is_hypothetical,
			i.allow_row_locks,
			i.allow_page_locks
from		sys.tables t	
inner join	sys.indexes i
	on		t.object_id = i.object_id
inner join	sys.index_columns ic
	on		i.object_id = ic.object_id
	and		i.index_id = ic.index_id
inner join	sys.columns c
	on		ic.object_id = c.object_id
	and		ic.column_id = c.column_id
inner join	sys.types ty
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		t.object_id = OBJECT_ID('IntegraLCTotvs.NOTA_FISCAL_ELETRONICA_PRODUTO')
--	and		i.name = '_dta_index_MCAD_PRODUTO_39_1623780942__K40_K44_45'
order by	i.index_id, ic.key_ordinal

--verify duplicated index
select		
			t.name,
			i.name,
			i.type_desc,
			i.index_id,
			COL_NAME(t.object_id,ic.column_id) as column_name,
			ic.key_ordinal,
			ic.is_included_column,
			ty.name as data_type,
			c.max_length,
			i.is_primary_key,
			c.is_identity,
			i.is_unique,
			c.is_nullable,
			i.ignore_dup_key,
			i.is_unique_constraint,
			i.is_disabled,
			i.is_hypothetical,
			i.allow_row_locks,
			i.allow_page_locks
from		sys.tables t	
inner join	sys.indexes i
	on		t.object_id = i.object_id
inner join	sys.index_columns ic
	on		i.object_id = ic.object_id
	and		i.index_id = ic.index_id
inner join	sys.columns c
	on		ic.object_id = c.object_id
	and		ic.column_id = c.column_id
inner join	sys.types ty
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		1 = 1 
	--and		ic.is_included_column = 0
order by	t.name, i.index_id, ic.key_ordinal

--tabela
select		t.name,
			c.name,
			ty.name as data_type,
			c.max_length,
			c.is_computed,
			c.precision,
			c.scale,
			c.is_nullable,
			c.collation_name
from		sys.tables t
inner join	sys.columns c
	on		t.object_id = c.object_id
inner join	sys.types ty
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		t.object_id = OBJECT_ID('MFAT_SOLIC_EMISSAO_NF_IMPOSTRIBUT')
order by	c.column_id

--stats
select		t.name,
			s.name,
			col_name(t.object_id,sc.column_id) as column_name,
			ty.name as data_type,
			c.max_length,
			c.is_identity,
			c.is_nullable,
			c.is_computed,
			c.precision,
			c.scale,
			c.collation_name,
			s.auto_created,
			s.user_created,
			s.no_recompute,
			s.has_filter,
			s.filter_definition
from		sys.tables t
inner join	sys.stats s
	on		t.object_id = s.object_id
inner join	sys.stats_columns sc
	on		s.object_id = sc.object_id
	and		s.stats_id = sc.stats_id	
inner join	sys.columns c
	on		sc.object_id = c.object_id
	and		sc.column_id = c.column_id
inner join	sys.types ty
	--on		c.system_type_id = ty.system_type_id
	on		c.user_type_id = ty.user_type_id 
where		1 = 1
	and 	t.object_id = OBJECT_ID('MFAT_ITEMNF')
	and		s.name = 'pk_mfat_itemnf'
order by	sc.stats_column_id

select		t.name, 
			s.name, 
			stats_date(sc.object_id,sc.stats_id) as [stats_date], 
			col_name(sc.object_id, sc.column_id) as column_name, 
			s.stats_id,
			s.auto_created, 
			s.user_created, 
			s.no_recompute, 
			s.has_filter, 
			s.filter_definition, 
			sc.stats_column_id, 
			sc.column_id
from		sys.tables t
inner join	sys.stats s
	on		t.object_id = s.object_id 
inner join	sys.stats_columns sc
	on		s.object_id = sc.object_id
	and		s.stats_id = sc.stats_id
where		t.name = 't_pck_item_pedido'

--################################################################################################################################################################################################
--VERIFICAR WAITS
--################################################################################################################################################################################################

create event session session_waits on server	
	add event sqlos.wait_info
		(where sqlserver.session_id = 53 and duration > 0)
   ,add event sqlos.wait_info_external
		(where sqlserver.session_id = 53 and duration > 0)
	add target package0.asynchronous_file_target
		(set filename=N'c:\temp\wait_stats.xel', metadatafile=N'c:\temp\wait_stats.xem');
go

--drop event session session_waits on server;

alter event session session_waits on server state = start;

alter event session session_waits on server state = stop;

;with cte_xevent as 
(
	select	cast(event_data as xml) as xevent
	from	sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null)
),
cte_xevent2 as
(
	select	xevent.value(N'(/event/data[@name="wait_type"]/text)[1]','sysname') as wait_type,
			xevent.value(N'(/event/data[@name="duration"]/value)[1]','int') as duration,
			xevent.value(N'(/event/data[@name="signal_duration"]/value)[1]','int') as signal_duration
	from	cte_xevent
)
select		wait_type,
			count(*) as count_waits,
			sum(duration) as total_duration,
			sum(signal_duration) as total_signal_duration,
			max(duration) as max_duration,
			max(signal_duration) as max_signal_duration
from		cte_xevent2
group by	wait_type
order by	sum(duration) desc;

--################################################################################################################################################################################################
--IDENTIFICAR STATS USADAS
--################################################################################################################################################################################################

DBCC TRACEON (3604)
DBCC TRACEOFF (3604)

DBCC TRACEON (9204)
DBCC TRACEOFF (9204)

DBCC TRACEON (8666)
DBCC TRACEOFF (8666)

DBCC TRACEON (9292)
DBCC TRACEOFF (9292)

OPTION
(
    RECOMPILE,-- Used to see the Statistics Output
    QUERYTRACEON 3604,-- Redirects the output to SSMS
    QUERYTRACEON 9204 -- Returns the Statistics that were used during Cardinality Estimation ("Stats loaded")
)

--################################################################################################################################################################################################
--VERIFICAR FRAGMENTAÇÃO INDICES
--################################################################################################################################################################################################

--database_id, object_id, index_id, partition_number, mode
select		object_name(a.object_id),b.name,a.avg_fragmentation_in_percent,a.*
from		sys.dm_db_index_physical_stats(db_id(),null,null,null,null) a
join		sys.indexes b 
	on		a.object_id = b.object_id 
	and		a.index_id = b.index_id
	and		a.page_count > 20
	and		a.index_id > 0	
order by	object_name(b.object_id), b.index_id

--select object_id('TB_ATTRIBUTES')
--select	i.index_id, i.* from sys.tables t join sys.indexes i on t.object_id = i.object_id 
--where	t.object_id = object_id('TB_ATTRIBUTES') and i.name = 'PK_ATTRIBUTES'

--################################################################################################################################################################################################
--MISSING INDEX
--################################################################################################################################################################################################

-- missing index
select		--top 25
			dbmid.database_id AS DatabaseID,
			dbmigs.avg_user_impact*(dbmigs.user_seeks+dbmigs.user_scans) Avg_Estimated_Impact,
			dbmigs.last_user_seek AS Last_User_Seek,
			OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) AS [TableName],
			'CREATE INDEX [IX_' + OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) + '_'
			+ REPLACE(REPLACE(REPLACE(ISNULL(dbmid.equality_columns,''),', ','_'),'[',''),']','') 
			+ CASE
			WHEN dbmid.equality_columns IS NOT NULL
			AND dbmid.inequality_columns IS NOT NULL THEN '_'
			ELSE ''
			END
			+ REPLACE(REPLACE(REPLACE(ISNULL(dbmid.inequality_columns,''),', ','_'),'[',''),']','')
			+ ']'
			+ ' ON ' + dbmid.statement
			+ ' (' + ISNULL (dbmid.equality_columns,'')
			+ CASE WHEN dbmid.equality_columns IS NOT NULL AND dbmid.inequality_columns 
			IS NOT NULL THEN ',' ELSE
			'' END
			+ ISNULL (dbmid.inequality_columns, '')
			+ ')'
			+ ISNULL (' INCLUDE (' + dbmid.included_columns + ')', '') AS Create_Statement
from		sys.dm_db_missing_index_groups dbmig
inner join	sys.dm_db_missing_index_group_stats dbmigs
	on		dbmigs.group_handle = dbmig.index_group_handle
inner join	sys.dm_db_missing_index_details dbmid
	on		dbmig.index_handle = dbmid.index_handle
where		dbmid.database_id = db_id()
order by	Avg_Estimated_Impact desc

--################################################################################################################################################################################################
--VERIFICAR UTILIZAÇÃO INDICES
--################################################################################################################################################################################################

select		t.name															,
			case when i.name is null then 'Heap' else i.name end as name	,
			i.type															,
			i.index_id														,
			dius.user_seeks													,
			dius.user_scans													,
			dius.user_lookups												,
			dius.user_updates												,
			dius.last_user_seek												,
			dius.last_user_scan												,
			dius.last_user_lookup											,
			dius.last_user_update											,
			dius.system_seeks												,
			dius.system_scans												,
			dius.system_lookups												,
			dius.system_updates												,
			dius.last_system_seek											,
			dius.last_system_scan											,
			dius.last_system_lookup											,
			dius.last_system_update	
--select		distinct i.name
from		sys.tables t
join		sys.indexes i
	on		t.object_id = i.object_id
join		sys.dm_db_index_usage_stats dius
	on		i.object_id = dius.object_id
	and		i.index_id = dius.index_id
where		1 = 1
	and		dius.database_id = db_id()
	and		i.index_id > 0
	--and		t.object_id = OBJECT_ID('MFAT_ITEMNF')
--order by	dius.user_seeks

--gerar script drop index para index nonclustered com seeks e scans zerados
select		s.name as schema_name 											,
			t.name as table_name 											,
			case when i.name is null then 'Heap' else i.name end as name	,
			i.type															,
			i.index_id														,
			dius.user_seeks													,
			dius.user_scans													,
			dius.user_lookups												,
			dius.user_updates												,
			dius.last_user_seek												,
			dius.last_user_scan												,
			dius.last_user_lookup											,
			dius.last_user_update											,
			dius.system_seeks												,
			dius.system_scans												,
			dius.system_lookups												,
			dius.system_updates												,
			dius.last_system_seek											,
			dius.last_system_scan											,
			dius.last_system_lookup											,
			dius.last_system_update											
			,'DROP INDEX [' + i.name + '] on [' + s.name + '].[' + t.name + ']'
--select		distinct i.name
from		sys.tables t
join		sys.schemas s
	on		t.schema_id = s.schema_id
join		sys.indexes i
	on		t.object_id = i.object_id
join		sys.dm_db_index_usage_stats dius
	on		i.object_id = dius.object_id
	and		i.index_id = dius.index_id
where		1 = 1
	and		dius.database_id = db_id()
	and		i.index_id > 1
	and		dius.user_seeks = 0
	and		dius.user_scans = 0
order by	dius.user_seeks, dius.user_scans


--#########################################################################################################################
--HYPHOTETICAL INDEX	
--#########################################################################################################################

select	dbid = db_id(),
		objectid = object_id,
		indid = index_id
from	sys.indexes
where	object_id = OBJECT_ID('dbo.SalesOrderDetail')
and		is_hypothetical = 1
--8	519672899	3

dbcc autopilot(0, 8, 519672899, 3)
go
set autopilot on
go
use AdventureWorks2008
go
select * from dbo.salesorderdetail
where productid = 897
go
set autopilot off

--

DBCC TRACEON (2588)
DBCC HELP('AUTOPILOT')
