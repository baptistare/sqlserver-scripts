--################################################################################################################################################################################################
--identificar rotinas custosas
--################################################################################################################################################################################################

select		top 10
			deps.cached_time,
			deps.last_execution_time,
			deps.execution_count,
			deps.last_worker_time,
			deps.last_physical_reads,
			deps.last_logical_writes,
			deps.last_logical_reads,
			deps.last_elapsed_time,
			dest.text,
			db_name(deqp.dbid),
			deqp.query_plan,*
from		sys.dm_exec_procedure_stats deps
cross apply sys.dm_exec_sql_text (deps.sql_handle) dest
cross apply sys.dm_exec_query_plan (deps.plan_handle) deqp
where		deqp.dbid <> 32767	
order by	deps.last_worker_time desc
--order by	deps.total_worker_time desc
--order by	deps.execution_count desc
--order by	deps.last_elapsed_time desc
--order by	deps.total_elapsed_time desc
--order by	deps.last_physical_reads desc
--order by	deps.total_physical_reads desc

select		top 100 
			deps.cached_time,
			deps.last_execution_time,
			deps.execution_count,
			deps.last_worker_time,
			deps.last_physical_reads,
			deps.last_logical_writes,
			deps.last_logical_reads,
			deps.last_elapsed_time,
			dest.text,
			db_name(deqp.dbid),
			deqp.query_plan,*
from		sys.dm_exec_procedure_stats deps
inner join	sys.dm_exec_query_stats deqs
	on		deps.sql_handle = deqs.sql_handle
cross apply sys.dm_exec_sql_text (deps.sql_handle) dest
cross apply sys.dm_exec_query_plan (deps.plan_handle) deqp
where		deqp.dbid <> 32767	
--where		deps.object_id = object_id('picking.dbo.p_PRODUTIVIDADE_TEGMA')
order by	deps.last_worker_time desc
--order by	deps.total_worker_time desc
--order by	deps.execution_count desc
--order by	deps.last_elapsed_time desc
--order by	deps.total_elapsed_time desc
--order by	deps.last_physical_reads desc
--order by	deps.total_physical_reads desc

--################################################################################################################################################################################################
--identificar rotina especifica
--################################################################################################################################################################################################
select		deps.cached_time,
			deps.last_execution_time,
			deps.execution_count,
			deps.last_worker_time,
			deps.last_physical_reads,
			deps.last_logical_writes,
			deps.last_logical_reads,
			deps.last_elapsed_time,
			dest.text,
			db_name(deqp.dbid),
			deqp.query_plan,*
from		sys.dm_exec_procedure_stats deps
inner join	sys.dm_exec_query_stats deqs
	on		deps.sql_handle = deqs.sql_handle
cross apply sys.dm_exec_sql_text (deps.sql_handle) dest
cross apply sys.dm_exec_query_plan (deps.plan_handle) deqp
where		deps.object_id = object_id('[SIGER.Database].dbo.spEnviaConfirmacaoNaoInformadosPeloSIGER')

--################################################################################################################################################################################################
--verificar indices
--################################################################################################################################################################################################
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
where		t.object_id = object_id('dbo.events')

--database_id, object_id, index_id, partition_number, mode
select		*
from		sys.dm_db_index_physical_stats(db_id(),1727657548,1,null,'DETAILED')
where		avg_fragmentation_in_percent > 10.0 
	and		index_id > 0
	and		page_count > 25


--################################################################################################################################################################################################
--verificar stats
--################################################################################################################################################################################################
select		t.name,
			s.name,
			stats_date(sc.object_id,sc.stats_id) as [stats_date], 
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
			s.filter_definition,
			s.stats_id,
			sc.stats_column_id, 
			sc.column_id
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
	on		c.system_type_id = ty.user_type_id
where		t.object_id = OBJECT_ID('tb_pedidos_confirmacao')
	--and		s.name = 'pk_mfat_itemnf'
order by	sc.stats_column_id

--################################################################################################################################################################################################
--atualizar stats
--################################################################################################################################################################################################
UPDATE STATISTICS STK_POSICAO_ESTOQUE PK__STK_POSI__3213E83F3B01A16B WITH FULLSCAN

--################################################################################################################################################################################################
--atualizar indice
--################################################################################################################################################################################################
ALTER INDEX [ix1] ON [dbo].[MSrepl_commands] REBUILD WITH (ONLINE=OFF,SORT_IN_TEMPDB=ON,FILLFACTOR=95,STATISTICS_NORECOMPUTE=ON, PAD_INDEX=ON);

--################################################################################################################################################################################################
--HEAP - forwarded_record_count
--################################################################################################################################################################################################
ALTER TABLE [HEAP] REBUILD;

--################################################################################################################################################################################################
--verificar se proc está agendada em algum job
--################################################################################################################################################################################################
select * from msdb..sysjobs j inner join msdb..sysjobsteps s on j.job_id = s.job_id where s.command like '%spEnviaConfirmacaoNaoInformadosPeloSIGER%'

--################################################################################################################################################################################################
--bcp
--################################################################################################################################################################################################
bcp "select * from [SIGER.Database]..t_pedidos" queryout "C:\temp\BCP\t_pedidos.dat" -S MSSTBOSQL -T -N
bcp WCH_PCK..t_pedidos in c:\temp\BCP\t_pedidos.dat -S MSPNP -T -N

--################################################################################################################################################################################################
--verificar waits
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
--info stats
--################################################################################################################################################################################################

set statistics io on
set statistics time on

set statistics io off
set statistics time off

--################################################################################################################################################################################################
--identificar stats usadas
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
--verificar utilização indices
--################################################################################################################################################################################################

select		t.name															,
			case when i.name is null then 'Heap' else i.name end as name	,
			i.type															,
			i.index_id														,
			dius.user_seeks													,
			dius.user_scans													,
			--case	
			--	when dius.user_scans > 0 and dius.user_seeks > 0 
			--	then (cast(dius.user_scans as numeric(10,5)) / cast(dius.user_seeks as numeric(10,5))) 
			--end as '%_Scan_x_Seek',
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
join		sys.dm_db_index_usage_stats dius
	on		t.object_id = dius.object_id
	join		sys.indexes i
	on		t.object_id = i.object_id
	and		i.index_id = dius.index_id
where		1 = 1
	--and		t.object_id = OBJECT_ID('MFAT_ITEMNF')
	and		dius.database_id = db_id()
--order by	dius.user_seeks

--percentual leituras x escritas
select		tablename = object_name(s.object_id),
			reads = sum(user_seeks + user_scans + user_lookups), 
			writes =  sum(user_updates)
			,cast((cast(sum(user_seeks + user_scans + user_lookups) as decimal) / cast(sum(user_updates) as decimal) * 100) as decimal(5,2)) as '%_reads_writes'
from		sys.dm_db_index_usage_stats as s
inner join	sys.indexes as i
	on		s.object_id = i.object_id
	and		i.index_id = s.index_id
where		objectproperty(s.object_id,'isusertable') = 1 
	--and		s.object_id = object_id('tb_teste_read_write')
	and		s.database_id = db_id('DBA_Admin')
group by	object_name(s.object_id)
order by	writes desc

--################################################################################################################################################################################################
--verificar missing indices
--################################################################################################################################################################################################

select		
			ddmid.database_id, 
			ddmid.object_id,
			ddmigs.avg_user_impact,
			ddmigs.avg_user_impact * (ddmigs.user_seeks+ddmigs.user_scans) as avg_estimated_impact,
			ddmid.statement,
			ddmid.equality_columns,
			ddmid.inequality_columns,
			ddmid.included_columns,
			ddmigs.user_seeks,
			ddmigs.user_scans,
			ddmigs.last_user_seek,
			ddmigs.last_user_scan,
			ddmigs.avg_total_user_cost,
			'CREATE INDEX [IX_' + OBJECT_NAME(ddmid.OBJECT_ID,ddmid.database_id) + '_' + REPLACE(REPLACE(REPLACE(ISNULL(ddmid.equality_columns,''),', ','_'),'[',''),']','') + 
			CASE
				WHEN ddmid.equality_columns IS NOT NULL AND ddmid.inequality_columns IS NOT NULL THEN '_'
				ELSE ''
			END + REPLACE(REPLACE(REPLACE(ISNULL(ddmid.inequality_columns,''),', ','_'),'[',''),']','') + ']' + ' ON ' + ddmid.statement + ' (' + ISNULL (ddmid.equality_columns,'') + 
			CASE 
				WHEN ddmid.equality_columns IS NOT NULL AND ddmid.inequality_columns IS NOT NULL THEN ',' 
				ELSE '' 
			END + ISNULL (ddmid.inequality_columns, '') + ')' + ISNULL (' INCLUDE (' + ddmid.included_columns + ')', '') AS Create_Statement
from		sys.dm_db_missing_index_details ddmid
inner join	sys.dm_db_missing_index_groups ddmig
	on		ddmid.index_handle = ddmig.index_handle
inner join	sys.dm_db_missing_index_group_stats ddmigs
	on		ddmig.index_group_handle = ddmigs.group_handle
--order by	ddmigs.avg_user_impact desc
where		ddmid.database_ID = DB_ID()
--order by	ddmigs.user_seeks desc
--order by	ddmigs.avg_estimated_impact desc
order by	ddmigs.avg_total_user_cost desc

--################################################################################################################################################################################################
----blob data types
--################################################################################################################################################################################################

--varbinary(max), image, text, varchar(max), ntext, nvarchar(max), xml, sqlvariant, geometry, geography
--165, 34, 35, 167, 99, 231, 241, 98, 129, 130

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
where		1=1
	--and		t.object_id = OBJECT_ID('tb_teste')
	and		(
				ty.user_type_id in (34, 35, 99, 241, 98, 129, 130)
		or		(ty.user_type_id in (165, 167, 231) and c.max_length = '-1')
			)
order by	t.name

