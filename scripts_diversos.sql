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
where		t.object_id = OBJECT_ID('MFAT_ITEMNF')
	and		dius.database_id = db_id()
--order by	dius.user_seeks


----------
----------
----------

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
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		t.object_id = OBJECT_ID('MFAT_ITEMNF')
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
join		sys.dm_db_index_usage_stats dius
	on		t.object_id = dius.object_id
	join		sys.indexes i
	on		t.object_id = i.object_id
	and		i.index_id = dius.index_id
where		t.object_id = OBJECT_ID('MFAT_ITEMNF')
	and		dius.database_id = db_id()
--order by	dius.user_seeks

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

----------
----------
----------

bcp "select * from sgf_cadr.dbo.MCAD_PRODUTO where dt_cadastro >= '20151215' and cd_Area = 4 and cd_categoria = 7 and cd_produto in ('0000071196824', '0000071197128','0000071197203','0000071197395')" queryout "C:\temp\BCP\MCAD_PRODUTO.dat" -S MSCOMERCIAL -T -N
bcp SGF_CADR..MCAD_PRODUTO in c:\temp\BCP\MCAD_PRODUTO.dat -S SQLDESENV2\MSCOMERCIAL -T -N


----------
----------
----------

use master
go

select * from sys.sysprocesses where blocked <> 0 and spid <> blocked

select		
			dec.session_id as blocking_session
			,der.session_id as blocked_session
			,des.status as blocking_status
			,des2.status as blocked_status
			,dowt1.wait_duration_ms as blocking_wait_duration
			,dowt2.wait_duration_ms as blocked_wait_duration
			,dowt1.wait_type as blocking_wait_type
			,dowt2.wait_type as blocked_wait_type
			,dowt1.resource_description as blocking_resource_description
			,dowt2.resource_description as blocked_resource_description
			,des.login_name as blocking_login_name
			,des2.login_name as blocked_login_name
			,des.host_name as blocking_hostname
			,des2.host_name as blocked_hostname
			,des.program_name as blocking_program_name
			,des2.program_name as blocking_program_name
			,blocking.text as blocking_command
			,blocked.text as blocked_command
			,dec.connect_time as blocking_connect_time
			,dec2.connect_time as blocked_connect_time
			,dec.client_net_address as blocking_client_net_address
			,dec2.client_net_address as blocked_client_net_address
			,db_name(der.database_id) as database_name
			,dec.net_transport as blocking_net_transport
			,dec2.net_transport as blocked_net_transport
			,der.open_transaction_count as open_transaction_count
			,j.name blocking_job_name
			,j2.name blocked_job_name
			,der.scheduler_id as blocked_scheduler_id
			,des.transaction_isolation_level as blocking_transaction_isolation_level
			,des2.transaction_isolation_level as blocked_transaction_isolation_level
			,dtat.transaction_begin_time blocking_transaction_begin_time
			,case 
				when dtat.transaction_type = 1 then 'Transação de leitura/gravação'
				when dtat.transaction_type = 2 then 'Transação somente leitura'
				when dtat.transaction_type = 3 then 'Transação do sistema'
				when dtat.transaction_type = 4 then 'Transação distribuída'
			end as blocking_transaction_type_desc
			,case
				when dtat.transaction_state = 0 then 'transação não foi completamente inicializada ainda'
				when dtat.transaction_state = 1 then 'transação foi inicializada mas não foi iniciada'
				when dtat.transaction_state = 2 then 'transação está ativa'
				when dtat.transaction_state = 3 then 'transação foi encerrada,somente leitura'
				when dtat.transaction_state = 4 then 'processo de confirmação foi iniciado na transação distribuída'
				when dtat.transaction_state = 5 then 'transação está em um estado preparado e aguardando resolução'
				when dtat.transaction_state = 6 then 'transação foi confirmada'
				when dtat.transaction_state = 7 then 'transação está sendo revertida'
				when dtat.transaction_state = 8 then 'transação foi revertida'
			end as blocking_transaction_state_desc
			,dec.most_recent_sql_handle
			,dec.net_transport
			,dec.protocol_type 
			,dec.auth_scheme
			,des.client_interface_name
			,dtat.transaction_uow
			,dtst.is_user_transaction
			,dtst.is_local
from		sys.dm_exec_connections dec
inner join	sys.dm_exec_sessions des
	on		dec.session_id = des.session_id
inner join	sys.dm_exec_requests der
	on		dec.session_id = der.blocking_session_id
inner join	sys.dm_exec_sessions des2
	on		der.session_id = des2.session_id
inner join	sys.dm_exec_connections dec2
	on		der.session_id = dec2.session_id
left join	sys.dm_os_waiting_tasks dowt1
	on		dec.session_id = dowt1.session_id
left join	sys.dm_os_waiting_tasks dowt2
	on		der.session_id = dowt2.session_id
cross apply sys.dm_exec_sql_text(dec.most_recent_sql_handle) blocking
cross apply sys.dm_exec_sql_text(der.sql_handle) blocked
left join	msdb..sysjobs j
	on		substring(des.program_name,30,34) = convert(varchar(34), convert(varbinary(32), j.job_id), 1) 
	and		des.program_name like 'sqlagent%'
left join	msdb..sysjobs j2
	on		substring(des2.program_name,30,34) = convert(varchar(34), convert(varbinary(32), j2.job_id), 1) 
	and		des2.program_name like 'sqlagent%'
left join	sys.dm_tran_session_transactions dtst
	on		dec.session_id = dtst.session_id
left join	sys.dm_tran_active_transactions dtat
	on		dtat.transaction_id = dtst.transaction_id
order by	blocking_status desc

declare @sql nvarchar(4000)
declare @database_name varchar(64);
select @database_name = db_name(database_id) from master.sys.dm_exec_requests where blocking_session_id <> 0;

if object_id('tempdb..#blocks','U') is not null
	drop table #blocks;

create table #blocks (session_id smallint not null);

insert #blocks (session_id)
select session_id from master.sys.dm_exec_requests where blocking_session_id <> 0
union 
select blocking_session_id from master.sys.dm_exec_requests where blocking_session_id <> 0;

select	@sql = N''
select	@sql += N'use ' + @database_name + ';'
select	@sql += N'select		dtl.request_session_id, '
select	@sql += N'			db_name(dtl.resource_database_id) as database_name, '
select	@sql += N'			case ' 
select	@sql += N'				when dtl.resource_type = ''OBJECT'' then OBJECT_NAME(dtl.resource_associated_entity_id) '
select	@sql += N'				when dtl.resource_associated_entity_id = 0 then '''' '
select	@sql += N'				else OBJECT_NAME(p.object_id) '
select	@sql += N'			end as objectname, '
select	@sql += N'			p.rows, '
select	@sql += N'			dtl.resource_type, '
select	@sql += N'			dtl.request_mode, '
select	@sql += N'			dtl.resource_description, '
select	@sql += N'			dtl.request_status, '
select	@sql += N'			i.name index_name, '
select	@sql += N'			i.index_id '
select	@sql += N'from		#blocks b '
select	@sql += N'join		sys.dm_tran_locks dtl '
select	@sql += N'  on		b.session_id = dtl.request_session_id '
select	@sql += N'left join	sys.partitions p '
select	@sql += N'	on		dtl.resource_associated_entity_id = p.hobt_id '
select	@sql += N'	or		dtl.resource_associated_entity_id = p.object_id '
select	@sql += N'left join	sys.tables t '
select	@sql += N'	on		p.object_id = t.object_id '
select	@sql += N'left join	sys.indexes i '
select	@sql += N'	on		p.object_id = i.object_id '
select	@sql += N'	and		p.index_id = i.index_id '
select	@sql += N'left join	sys.dm_exec_requests der '
select	@sql += N'	on		dtl.request_session_id = der.session_id '
select	@sql += N'where		dtl.request_session_id <> @@spid '
select	@sql += N'	and		dtl.resource_type <> ''DATABASE'' '
select	@sql += N'	and		dtl.resource_database_id not in (1,2,3,4)'
select	@sql += N'order by	dtl.request_status desc, dtl.request_session_id; '
execute sp_executesql @sql



--------------

/*

select * from master.sys.sysprocesses where blocked <> 0

--select * from master.sys.dm_exec_sessions where login_name = 'usr_integracao_chl_lc'
--select * from master.sys.dm_exec_requests where session_id > 50

select * from master.sys.dm_exec_sessions where session_id = 161
select * from master.sys.dm_exec_requests where session_id = 161
select * from master.sys.dm_os_waiting_tasks where session_id = 161

select		
			ec.session_id
			,es.login_name			
			,ec.connect_time
			,ec.client_net_address
			,es.[host_name]
			,es.[program_name]
			,es.[status]
			,tat.transaction_id
			,tat.transaction_begin_time
			--,tat.transaction_type
			,case 
				when tat.transaction_type = 1 then 'Transação de leitura/gravação'
				when tat.transaction_type = 2 then 'Transação somente leitura'
				when tat.transaction_type = 3 then 'Transação do sistema'
				when tat.transaction_type = 4 then 'Transação distribuída'
			end as transaction_type_desc
			--,tat.transaction_state
			,case
				when tat.transaction_state = 0 then 'transação não foi completamente inicializada ainda'
				when tat.transaction_state = 1 then 'transação foi inicializada mas não foi iniciada'
				when tat.transaction_state = 2 then 'transação está ativa'
				when tat.transaction_state = 3 then 'transação foi encerrada,somente leitura'
				when tat.transaction_state = 4 then 'processo de confirmação foi iniciado na transação distribuída'
				when tat.transaction_state = 5 then 'transação está em um estado preparado e aguardando resolução'
				when tat.transaction_state = 6 then 'transação foi confirmada'
				when tat.transaction_state = 7 then 'transação está sendo revertida'
				when tat.transaction_state = 8 then 'transação foi revertida'
			end as transaction_state_desc
			--,tat.dtc_state (azure)
			,tat.transaction_uow
			,tst.is_user_transaction
			,tst.is_local
			,er.*
from		sys.dm_tran_active_transactions tat
inner join	sys.dm_tran_session_transactions tst
	on		tat.transaction_id = tst.transaction_id
inner join	sys.dm_exec_sessions es
	on		tst.session_id = es.session_id	
inner join	sys.dm_exec_connections ec
	on		es.session_id = ec.session_id
left join	sys.dm_exec_requests er
	on		es.session_id = er.session_id
where		es.session_id = 161
--where		es.host_name in ('MSDPTS1')

declare @db_id tinyint
declare @sql varchar(4000)

select @db_id = dbid from master.sys.sysprocesses where blocked <> 0

select db_name(@db_id)

select spid as blocked, blocked as blocking, *  from master.sys.sysprocesses where blocked <> 0

use SGF_FAT
go

select 

			dtl.resource_associated_entity_id,
			p.hobt_id,
			p.object_id,
			t.object_id,

			dtl.request_session_id, 
			db_name(dtl.resource_database_id) as database_name,
			case 
				when dtl.resource_type = 'OBJECT' then OBJECT_NAME(dtl.resource_associated_entity_id)
				when dtl.resource_associated_entity_id = 0 then ''
				else OBJECT_NAME(p.object_id)
			end as objectname,
			p.rows,
			dtl.resource_type,
			dtl.request_mode,
			dtl.resource_description,
			dtl.request_status, 
			--dtl.request_lifetime,
			--dtl.resource_associated_entity_id, 
			i.name index_name,
			i.index_id
from		sys.dm_tran_locks dtl
left join	sys.partitions p
	on		dtl.resource_associated_entity_id = p.hobt_id
	or		dtl.resource_associated_entity_id = p.object_id
left join	sys.tables t
	on		p.object_id = t.object_id
left join	sys.indexes i
	on		p.object_id = i.object_id
	and		p.index_id = i.index_id
join		master.sys.sysprocesses sp
	on		dtl.request_session_id = sp.spid
	--and		dtl.request_session_id = sp.blocked
--where		dtl.request_session_id in (161,174)
order by	dtl.request_session_id	


select 

			dtl.resource_associated_entity_id,
			p.hobt_id,
			p.object_id,
			t.object_id,

			dtl.request_session_id, 
			db_name(dtl.resource_database_id) as database_name,
			case 
				when dtl.resource_type = 'OBJECT' then OBJECT_NAME(dtl.resource_associated_entity_id)
				when dtl.resource_associated_entity_id = 0 then ''
				else OBJECT_NAME(p.object_id)
			end as objectname,
			p.rows,
			dtl.resource_type,
			dtl.request_mode,
			dtl.resource_description,
			dtl.request_status, 
			--dtl.request_lifetime,
			--dtl.resource_associated_entity_id, 
			i.name index_name,
			i.index_id
from		sys.dm_tran_locks dtl
left join	sys.partitions p
	on		dtl.resource_associated_entity_id = p.hobt_id
	or		dtl.resource_associated_entity_id = p.object_id
left join	sys.tables t
	on		p.object_id = t.object_id
left join	sys.indexes i
	on		p.object_id = i.object_id
	and		p.index_id = i.index_id
--where		db_name(dtl.resource_database_id)='dbName'
where		dtl.request_session_id in (161,174)
order by	dtl.request_session_id	

*/

--#########################################################################################################################
--XEVENT
--#########################################################################################################################

/*
use master
go

select * from sys.dm_xe_session_events
select * from sys.dm_xe_sessions
select * from sys.dm_xe_session_targets
select * from sys.dm_xe_session_event_actions
select * from sys.dm_xe_packages


create event session session_waits on server	
	add event sqlos.wait_info
		(where sqlserver.session_id = 139 and duration > 0)
   ,add event sqlos.wait_info_external
		(where sqlserver.session_id = 139 and duration > 0)
	add target package0.asynchronous_file_target
		(set filename=N'c:\temp\wait_stats.xel', metadatafile=N'c:\temp\wait_stats.xem');
go

alter event session session_waits on server state = start;
go

--drop event session session_waits on server;

--alter event session session_waits on server state = stop;

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
			--cast(avg(duration) as numeric (5,2)) as avg_duration,
from		cte_xevent2
group by	wait_type
order by	sum(duration) desc;

/*
select * from sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null);

;with cte_xevent as 
(
	select	cast(event_data as xml) as xevent
	from	sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null)
)
select	* 
from	cte_xevent;

;with cte_xevent as 
(
	select	cast(event_data as xml) as xevent
	from	sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null)
)
select	xevent.value(N'(/event/data[@name="wait_type"]/text)[1]','sysname') as wait_type,
		xevent.value(N'(/event/data[@name="duration"]/text)[1]','int') as duration,
		xevent.value(N'(/event/data[@name="signal_duration"]/text)[1]','int') as signal_duration
from	cte_xevent;
*/
*/

--#########################################################################################################################
--BLOCKS,LOCKS
--#########################################################################################################################

/*
select		
			dec.session_id as blocking_session
			,der.session_id as blocked_session
			,des.status as blocking_status
			,des2.status as blocked_status
			,dowt1.wait_duration_ms as blocking_wait_duration
			,dowt2.wait_duration_ms as blocked_wait_duration
			,dowt1.wait_type as blocking_wait_type
			,dowt2.wait_type as blocked_wait_type
			,dowt1.resource_description as blocking_resource_description
			,dowt2.resource_description as blocked_resource_description
			,des.login_name as blocking_login_name
			,des2.login_name as blocked_login_name
			,des.host_name as blocking_hostname
			,des2.host_name as blocked_hostname
			,des.program_name as blocking_program_name
			,des2.program_name as blocking_program_name
			,blocking.text as blocking_command
			,blocked.text as blocked_command
			,dec.connect_time as blocking_connect_time
			,dec2.connect_time as blocked_connect_time
			,dec.client_net_address as blocking_client_net_address
			,dec2.client_net_address as blocked_client_net_address
			,db_name(der.database_id) as database_name
			,dec.net_transport as blocking_net_transport
			,dec2.net_transport as blocked_net_transport
			,der.open_transaction_count as open_transaction_count
			,j.name job_name
			,der.scheduler_id as blocked_scheduler_id
			,des.transaction_isolation_level as blocking_transaction_isolation_level
			,des2.transaction_isolation_level as blocked_transaction_isolation_level
from		sys.dm_exec_connections dec
inner join	sys.dm_exec_sessions des
	on		dec.session_id = des.session_id
inner join	sys.dm_exec_requests der
	on		dec.session_id = der.blocking_session_id
inner join	sys.dm_exec_sessions des2
	on		der.session_id = des2.session_id
inner join	sys.dm_exec_connections dec2
	on		der.session_id = dec2.session_id
left join	sys.dm_os_waiting_tasks dowt1
	on		dec.session_id = dowt1.session_id
left join	sys.dm_os_waiting_tasks dowt2
	on		der.session_id = dowt2.session_id
cross apply sys.dm_exec_sql_text(dec.most_recent_sql_handle) blocking
cross apply sys.dm_exec_sql_text(der.sql_handle) blocked
left join	msdb..sysjobs j
	on		substring(des2.program_name,30,34) = convert(varchar(34), convert(varbinary(32), j.job_id), 1) 
	and		des2.program_name like 'sqlagent%'
order by	blocking_status desc

select		 s1.spid blocker
			,s2.spid blocked
			,s1.blocked [blocker blocker]
			,dest1.text command_blocker
			,s1.hostname host_blocker
			,s1.program_name program_blocker
			,s1.loginame login_bloker
			,s1.net_address address_bloker
			,dest2.text command_blocked
			,s2.hostname host_blocked
			,s2.program_name program_blocked
			,s2.loginame login_blocked
			,s2.net_address address_blocked
			,s1.waittime
			,s1.login_time
			,s1.last_batch
			,s1.open_tran
			,s1.status status_blocker
			,s2.status status_blocked
			,case 
				when s1.program_name not like 'sqlagent - tsql jobstep (job %' 
				then s1.program_name
				else	 (	select	name 
                            from	msdb..sysjobs 
                            where	job_id in	(
													select	substring(program_name,38,2) 
															+ substring(program_name,36,2) 
															+ substring(program_name,34,2) 
															+ substring(program_name,32,2) 
															+ '-' + substring(program_name,42,2) 
															+ substring(program_name,40,2) 
															+ '-' + substring(program_name,46,2) 
															+ substring(program_name,44,2) 
															+ '-' + substring(program_name,48,4) 
															+ '-' + substring(program_name,52,12) 
                                                    from	sysprocesses 
													where	spid   = s1.spid 
													and		program_name like 'sqlagent - tsql jobstep (job %'
												)
						)
			end as [program_name]
from		master.dbo.sysprocesses s1
inner join	master.dbo.sysprocesses s2
	on		s1.spid = s2.blocked
cross apply sys.dm_exec_sql_text (s1.sql_handle) dest1
cross apply sys.dm_exec_sql_text (s2.sql_handle) dest2
where		1=1
	and		s1.spid in (	select	blocked
							from	master.dbo.sysprocesses 
							where	1=1
							and		blocked > 0
						)
order by	s1.blocked,s1.spid

*/

----------
----------
----------

use master
go
CREATE LOGIN [FNACBR\aaraujo] FROM WINDOWS 
DROP LOGIN [FNACBR\aaraujo]

CREATE LOGIN [FNACBR\rbaptista] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO


--CREATE LOGIN usr_reinaldo WITH PASSWORD=N'usr_reinaldo', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

--CREATE LOGIN usr_reinaldo WITH PASSWORD=N'ReinaldoTestes2' MUST_CHANGE, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=ON, CHECK_POLICY=ON

use ECRReload

CREATE USER [FNACBR\aaraujo] FOR LOGIN [FNACBR\aaraujo];
DROP USER [FNACBR\aaraujo]

exec sp_addrolemember db_owner, [FNACBR\aaraujo]
exec sp_addrolemember db_datareader, [FNACBR\aaraujo]

exec sp_droprolemember db_datareader, [FNACBR\aaraujo]

--consultar roles
sp_helpsrvrole
sp_helprole
/*
public
db_owner
db_accessadmin
db_securityadmin
db_ddladmin
db_backupoperator
db_datareader
db_datawriter
db_denydatareader
db_denydatawriter
*/

--adicionar / remover usuário a role sysadmin

sp_addsrvrolemember @loginame= 'userchalldef' , @rolename = 'sysadmin'
sp_dropsrvrolemember @loginame= 'userchalldef' , @rolename = 'sysadmin'


--ROLES

use master
go

CREATE ROLE Desenvolvimento AUTHORIZATION dbo
DROP ROLE Desenvolvimento 

CREATE ROLE Systax AUTHORIZATION dbo
DROP ROLE Systax 

ALTER ROLE Systax ADD MEMBER afim;
ALTER ROLE Systax DROP MEMBER afim;

sp_helprole @rolename = 'Desenvolvimento'
sp_helprole @rolename = 'Systax'

exec sp_addrolemember db_owner, Systax

exec sp_addrolemember db_datareader, Systax
exec sp_addrolemember db_datawriter, Systax

--verificar permissão usário na base
select dp.name as database_role, dp2.name as database_user
from sys.database_role_members drm
  join sys.database_principals dp on (drm.role_principal_id = dp.principal_id)
  join sys.database_principals dp2 on (drm.member_principal_id = dp2.principal_id)
where dp2.name in ('FNACBR\aaraujo')
order by dp.name

select dp.name as database_role, dp2.name as database_user
from sys.database_role_members drm
  join sys.database_principals dp on (drm.role_principal_id = dp.principal_id)
  join sys.database_principals dp2 on (drm.member_principal_id = dp2.principal_id)
where dp.name = 'db_datareader'
order by dp.name

select dp.name as database_role, dp2.name as database_user, *
from		sys.sysusers u with(nolock) 
join		sys.database_role_members drm with(nolock) 
	on		drm.member_principal_id = u.uid
join		sys.database_principals dp with(nolock)  
	on		drm.role_principal_id = dp.principal_id
join		sys.database_principals dp2 
	on		drm.member_principal_id = dp2.principal_id
where		dp.name = 'db_datareader'

select dp.name as database_role, dp2.name as database_user, *
from		sys.sysusers u with(nolock) 
join		sys.database_role_members drm with(nolock) 
	on		drm.member_principal_id = u.uid
join		sys.database_principals dp with(nolock)  
	on		drm.role_principal_id = dp.principal_id
join		sys.database_principals dp2 
	on		drm.member_principal_id = dp2.principal_id
where		u.islogin = 1 
and			u.hasdbaccess = 1 
and			u.issqluser = 1--22
and			dp.name = 'db_datareader'

xp_logininfo 
xp_logininfo 'FNACBR\Desenvolvimento-Challenger-GG', 'members';
xp_logininfo 'FNACBR\Desenvolvimento-DBProd-1-GG', 'members';
xp_logininfo 'FNACBR\Desenvolvimento-DBProd-2-GG', 'members';
xp_logininfo 'FNACBR\Desenvolvimento-DBDesenv-GG', 'members';
xp_logininfo 'FNACBR\SQL Admins', 'members';


--criar usuario em todas as bases
sp_msforeachdb 'use [?]
if db_name() not in (''master'',''msdb'',''model'',''tempdb'',''distribution'',''dbAuditoria'')
begin
	CREATE USER usr_cultura FOR LOGIN usr_cultura;
	exec sp_addrolemember db_datareader, usr_cultura;
	exec sp_addrolemember db_datawriter, usr_cultura;
	exec sp_addrolemember db_ddladmin, usr_cultura;
	grant execute to usr_cultura;
end
else
begin
	select ''bases sistema''
end
'

sp_msforeachdb 'use [?]
select db_name(),dp.name as database_role, dp2.name as database_user
from sys.database_role_members drm
  join sys.database_principals dp on (drm.role_principal_id = dp.principal_id)
  join sys.database_principals dp2 on (drm.member_principal_id = dp2.principal_id)
where dp2.name in (''usr_cultura'')
'

----------
----------
----------

use master
go

--verificação databases, datafiles, filegroups por instância
if object_id('tempdb..#tb_info_databases') is not null
	drop table #tb_info_databases;

create table #tb_info_databases (database_name varchar(64), file_id tinyint, file_type bit, file_logical_name varchar(64), file_physical_name varchar(255), filegroup_name varchar(64), is_default bit);
go

sp_msforeachdb 'use [?];
				insert #tb_info_databases
				select		db_name() as database_name, df.file_id, df.type as file_type, df.name as file_logical_name, df.physical_name as file_physical_name, f.name as filegroup_name, f.is_default
				from		sys.database_files df
				left join	sys.filegroups f
					on		df.data_space_id = f.data_space_id
				order by	df.file_id
				'
select * from #tb_info_databases;

--verificação tabelas, indexes, filegroups por base de dados
use CulturaDB
go

select		s.name as schema_name, t.name as table_name, case when i.name is null then 'Heap Table' else i.name end as index_name, i.index_id, f.name as filegroup_name
from		sys.indexes i
inner join	sys.tables t
	on		i.object_id = t.object_id
inner join	sys.schemas s
	on		t.schema_id = s.schema_id
inner join	sys.filegroups f
	on		i.data_space_id = f.data_space_id
inner join	sys.all_objects o
	on		i.object_id = o.object_id 
where		i.data_space_id = f.data_space_id
	and		o.type = 'U'--2942
	--and		t.name = 'item'


--verificação quantidade objetos por filegroups
select		f.name, i.type, count(i.object_id) as qtd
from		sys.indexes i
inner join	sys.tables t
	on		i.object_id = t.object_id
	inner join	sys.schemas s
	on		t.schema_id = s.schema_id
inner join	sys.filegroups f
	on		i.data_space_id = f.data_space_id
inner join	sys.all_objects o
	on		i.object_id = o.object_id 
where		i.data_space_id = f.data_space_id
	and		o.type = 'U'
group by	f.name,i.type
order by	f.name,i.type, qtd desc

sp_configure 'show advanced options', 1
reconfigure
sp_configure 'show advanced options', 0

sp_configure 'xp_cmdshell'

select * from sys.dm_os_sys_info

--estatisticas acumuladas
;WITH [Waits] AS
    (
		SELECT
				[wait_type],
				[wait_time_ms] / 1000.0 AS [wait_time_s],
				([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [resource_s],
				[signal_wait_time_ms] / 1000.0 AS [signal_s],
				[waiting_tasks_count],
				100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
				ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
		FROM	sys.dm_os_wait_stats
		WHERE	[wait_type] NOT IN (N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
									N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
									N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
									N'CHKPT', N'CLR_AUTO_EVENT',
									N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
 
									-- Maybe uncomment these four if you have mirroring issues
									N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
									N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
 
									N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
									N'EXECSYNC', N'FSAGENT',
									N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
 
									-- Maybe uncomment these six if you have AG issues
									N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
									N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
									N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
 
									N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
									N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
									N'ONDEMAND_TASK_QUEUE',
									N'PREEMPTIVE_XE_GETTARGETSTATE',
									N'PWAIT_ALL_COMPONENTS_INITIALIZED',
									N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
									N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
									N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
									N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
									N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
									N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
									N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
									N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
									N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
									N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
									N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
									N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
									N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
									N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
									N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
									N'WAIT_XTP_RECOVERY',
									N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
									N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
									N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
		AND		[waiting_tasks_count] > 0
    )
SELECT
			MAX ([W1].[wait_type]) AS [wait_type],
			CAST (MAX ([W1].[wait_time_s]) AS DECIMAL (16,2)) AS [wait_time_s],
			CAST (MAX ([W1].[resource_s]) AS DECIMAL (16,2)) AS [resource_s],
			CAST (MAX ([W1].[signal_s]) AS DECIMAL (16,2)) AS [signal_s],
			MAX ([W1].[waiting_tasks_count]) AS [waiting_tasks_count],
			CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [percentage],
			CAST ((MAX ([W1].[wait_time_s]) / MAX ([W1].[waiting_tasks_count])) AS DECIMAL (16,4)) AS [avg_wait_time_s],
			CAST ((MAX ([W1].[resource_s]) / MAX ([W1].[waiting_tasks_count])) AS DECIMAL (16,4)) AS [avg_resource_s],
			CAST ((MAX ([W1].[signal_s]) / MAX ([W1].[waiting_tasks_count])) AS DECIMAL (16,4)) AS [avg_signal_s],
			CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
FROM		[Waits] AS [W1]
INNER JOIN	[Waits] AS [W2]
    ON		[W2].[RowNum] <= [W1].[RowNum]
GROUP BY	[W1].[RowNum]
HAVING		SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold
GO

----------
----------
----------

dbcc sqlperf (logspace)

select recovery_model_desc,* from sys.databases where database_id = db_id('SGF_MIS')
select name,* from sys.master_files where type = 1 and database_id = db_id('SGF_MIS')

use SGF_MIS

alter database SGF_MIS set recovery simple with no_wait

dbcc shrinkfile ('SGF_MIS_Log',2048)

alter database SGF_MIS set recovery full

----------
----------
----------

 /*
select * from sys.tables
select * from sys.indexes
select * from sys.index_columns
select * from sys.columns
select * from sys.types

select * from sys.stats
select * from sys.stats_columns
*/

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
where		t.object_id = OBJECT_ID('MCAD_PRODUTO')
--	and		i.name = '_dta_index_MCAD_PRODUTO_39_1623780942__K40_K44_45'
order by	i.index_id, ic.key_ordinal

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
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		t.object_id = OBJECT_ID('MFAT_ITEMNF')
	and		s.name = 'pk_mfat_itemnf'
order by	sc.stats_column_id

--PROCS
select		--top 1
			db_name(eps.database_id) as database_name,
			object_schema_name(eps.[object_id], eps.database_id) as [schema_name],
			object_name(eps.[object_id], eps.database_id) AS [procedure_name],
			eps.cached_time,
			eps.last_execution_time,
			eps.execution_count,
			--cpu
			eps.min_worker_time,
			eps.max_worker_time,
			eps.total_worker_time / isnull(eps.execution_count, 1) as avg_cpu,
			eps.last_worker_time,
			eps.total_worker_time,
			--elapsed time
			eps.min_elapsed_time,
			eps.max_elapsed_time,
			eps.total_elapsed_time / isnull(eps.execution_count, 1) as avg_duration,
			eps.last_elapsed_time,
			eps.total_elapsed_time,
			--physical reads	
			eps.total_physical_reads,
			eps.last_physical_reads,
			eps.min_physical_reads,
			eps.max_physical_reads,
			eps.total_physical_reads / isnull(eps.execution_count, 1) as avg_physical_reads,
			--logical reads	
			eps.min_logical_reads,
			eps.max_logical_reads,
			eps.total_logical_reads / isnull(eps.execution_count, 1) as avg_logical_reads,
			eps.last_logical_reads,
			eps.total_logical_reads,
			--logical writes	
			eps.min_logical_writes,
			eps.max_logical_writes,
			eps.total_logical_writes / isnull(eps.execution_count, 1) as avg_logical_writes,
			eps.last_logical_writes,
			eps.total_logical_writes,
			--
			ecp.refcounts,
			ecp.size_in_bytes,
			ecp.cacheobjtype,
			ecp.objtype,
			eqp.query_plan,
			est.text
	        --,SUBSTRING(est.[text], r.statement_start_offset / 2, ( CASE WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), est.[text])) * 2 ELSE r.statement_end_offset END - r.statement_start_offset ) / 2) AS [statement_executing]
from		sys.dm_exec_procedure_stats eps
inner join	sys.dm_exec_cached_plans ecp
	on		eps.plan_handle = ecp.plan_handle
cross apply	sys.dm_exec_query_plan (eps.plan_handle) eqp
cross apply	sys.dm_exec_sql_text(eps.plan_handle) est
where		db_name(eps.database_id) = 'dbAuditoria'
	--and		eps.object_id = 709577566
order by	avg_cpu desc
--order by	avg_duration desc
--order by	avg_physical_reads desc
--order by	avg_logical_reads desc
--order by	avg_logical_writes desc
--order by	avg_rows desc

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
----------
----------
----------

--lista os arquivos de logs
exec sp_enumerrorlogs

--le conteúdo do arquivo de log (default 0 - parâmetros arquivos de log)
exec sp_readerrorlog

--parâmetros a serem usados com sp_readerrorlog
/*
Parameter Name		Usage
@ArchiveID			Extension of the file which we would like to read.
					0 = ERRORLOG/SQLAgent.out
					1 = ERRORLOG.1/SQLAgent.1  and so on
@LogType			1 for SQL Server ERRORLOG (ERRORLOG.*)
					2 for SQL Agent Logs (SQLAgent.*)
@FilterText1		First Text filter on data
@FilterText2		Another Text filter on data. Output would be after applying both filters, if specified
@FirstEntry			Start Date Filter on Date time in the log
@LastEntry			END Date Filter on Date time in the log
@SortOrder			'asc' or 'desc' for sorting the data based on time in log.
*/

xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = 'memory has been paged out'
----------
----------
----------

use master
go

--identificar local atual arquivos
select name, physical_name, * from sys.master_files where database_id = DB_ID('erp_bi');
/*
erp_bi_prod		D:\SQL\SQL_Data\erp_bi_prod.mdf
erp_bi_prod_log	D:\SQL\SQL_Logs\erp_bi_prod_log.ldf
*/

--colocar a base de dados offline para movimentação dos arquivos
alter database erp_bi set offline;

--movimentar os arquivos para o novo local

alter database erp_bi
modify file (name='erp_bi_prod_log',filename='novo_caminho\erp_bi_prod_log.ldf');

--repetir os passos anteriores para movimentação de outros arquivos de dados ou log

--colocar a base de dados online para acesso multi_user
alter database erp_bi set online;

--confirmação da movimentação dos arquivos
select name, physical_name, * from sys.master_files where database_id = DB_ID('erp_bi');


----------
----------
----------

select size, (size * 8) / 1024. /1024 from sys.master_files where database_id = DB_ID('qqg') and type = 1
select sum((size * 8) / 1024. /1024) from sys.master_files where database_id = DB_ID('qqg') 

use master
go

--identificar local atual arquivos
select name, physical_name, * from sys.master_files where database_id = DB_ID('qqg');
/*
qqg_Data	Y:\Dados\qqg.mdf
qqg_Log		Y:\Dados\qqg_log.ldf
*/

alter database qqg set single_user with rollback immediate;

--alterar caminho arquivos
alter database qqg modify file (name='qqg_Data',filename='L:\Dados\qqg.mdf');
alter database qqg modify file (name='qqg_Log',filename='L:\Dados\qqg_log.ldf');

--colocar a base de dados offline para movimentação dos arquivos
alter database qqg set offline;

--movimentar os arquivos para o novo local

--colocar a base de dados online para acesso multi_user
alter database qqg set online;
alter database qqg set multi_user;

--confirmação da movimentação dos arquivos
select name, physical_name, * from sys.master_files where database_id = DB_ID('qqg');
select user_access_desc,* from sys.databases where database_id = DB_ID('qqg');



----------
----------
----------

		/*
		select
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_STATE() AS ErrorState,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;		
		*/

		declare @ErrorMessage nvarchar(2048)
		declare @ErrorNumber int
		declare @ErrorLine int
		declare @ErrorState int
		declare @ErrorSeverity int
		declare @ErrorProcedure nvarchar(126)

		select	@ErrorMessage = ERROR_MESSAGE(),
				@ErrorNumber = ERROR_NUMBER(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE(),
				@ErrorLine = ERROR_LINE(),
				@ErrorProcedure = ERROR_PROCEDURE();
				
		raiserror (@ErrorMessage, @ErrorNumber, @ErrorSeverity,@ErrorState,@ErrorLine,@ErrorProcedure);	

		select	ERROR_NUMBER() as ErrorNumber,
				ERROR_SEVERITY() as ErrorSeverity,
				ERROR_STATE() as ErrorState,
				ERROR_PROCEDURE() as ErrorProcedure,
				ERROR_LINE() as ErrorLine,
				ERROR_MESSAGE() as ErrorMessage;
----------
----------
----------

select
    object_name(p.object_id) as tabela, rows as linhas,
    sum(total_pages * 8) as reservado,
    sum(case when index_id > 1 then 0 else data_pages * 8 end) as dados,
        sum(used_pages * 8) -
        sum(case when index_id > 1 then 0 else data_pages * 8 end) as indice,
    sum((total_pages - used_pages) * 8) as naoutilizado,
	sum(a.used_pages) as used_pages
from
    sys.partitions as p
    inner join sys.allocation_units as a on p.partition_id = a.container_id--hobt_id
    inner join sys.tables t on p.object_id = t.object_id
group by object_name(p.object_id), rows
order by 2 desc

select
    object_name(p.object_id) as tabela, rows as linhas,
    sum(total_pages * 8) as reservado,
    sum(case when index_id > 1 then 0 else data_pages * 8 end) as dados,
        sum(used_pages * 8) -
        sum(case when index_id > 1 then 0 else data_pages * 8 end) as indice,
    sum((total_pages - used_pages) * 8) as naoutilizado,
	sum(a.used_pages) as used_pages
from
    sys.partitions as p
    inner join sys.allocation_units as a on p.partition_id = a.container_id--hobt_id
    inner join sys.tables t on p.object_id = t.object_id
group by object_name(p.object_id), rows
order by 2 desc

----------
----------
----------

/*
@echo OFF
cls
echo . Executando scripts
osql.exe -S%1 -E -i".\010_P_MFAT_INCLUIR_PEDNF.sql" -b -h-1 -o".\010_P_MFAT_INCLUIR_PEDNF.txt" 
if errorlevel 1 goto erro
osql.exe -S%1 -E -i".\011_P_MSAR_GERAR_AUTO_NF_TRANSF_STK.sql" -b -h-1 -o".\011_P_MSAR_GERAR_AUTO_NF_TRANSF_STK.txt"
if errorlevel 1 goto erro
goto sucesso
:erro
echo -------------------------------------------------
echo Ocorreram 1 ou mais erros ao executar os scripts, verifique o arquivo de log no mesmo diretorio
pause
goto end
:sucesso
echo -------------------------------------------------
echo Os scripts foram executados com sucesso
pause
:end
*/
osql.exe -S%1 -E -i".\010_P_MFAT_INCLUIR_PEDNF.sql" -b -h-1 -o".\010_P_MFAT_INCLUIR_PEDNF.txt" 

osql.exe -S%1 -E -i".\testeosql.sql" -b -h-1 -o".\testeosql.txt" 

-S - server
-E - trusted connection
-i - inputFile
-b - cod retorno erro
-h - header, nr de linha a imprimir, -1 não imprime nada
-o - outputFile

sqlcmd.exe -S%1 -E -i".\testesqlcmd.sql" -b -h-1 -o".\testesqlcmd.txt" 
sqlcmd.exe -SSQLDEVDEP -E -i".\testesqlcmd.sql" -b -h-1 -o".\testesqlcmd.txt" 

sqlcmd.exe -SSQLDEVDEP -E -i"C:\Reinaldo\FNAC\Scripts\Testes\testesqlcmd.sql" -b -h-1 -o"C:\Reinaldo\FNAC\Scripts\Testes\testesqlcmd.txt" 
osql.exe -SSQLDEVDEP -E -i"C:\Reinaldo\FNAC\Scripts\Testes\testeosql.sql" -b -h-1 -o"C:\Reinaldo\FNAC\Scripts\Testes\testeosql.txt"


----------
----------
----------

--obtem informações de traces em execução
SELECT * FROM :: fn_trace_getinfo(default)

--ler o arquivo de trace  
SELECT * FROM ::fn_trace_gettable('C:\temp\Trace\blocked_process_threshold.trc', DEFAULT)--663

SELECT cast(textdata as xml),* FROM ::fn_trace_gettable('C:\temp\Trace\blocked_process_threshold.trc', DEFAULT)--663

--parar o trace id 2
EXEC sp_trace_setstatus 2, 0

--iniciar o trace id 2
EXEC sp_trace_setstatus 2, 1

--para e remove trace id 2
EXEC sp_trace_setstatus 2, 2

/*
DEFAULT TRACE

C3PO
D:\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_29764.trc

HSQLWEB01\REPL
D:\SQL\MSSQL10_50.REPL\MSSQL\Log\log_227.trc

MSDEPOSITO
D:\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_9671.trc

MSCARETAG
G:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_5506.trc

MSRBPRETAG
E:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_3135.trc

MSPIRETAG
D:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_2282.trc

MSRBRETAG1
E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_305.trc

MSSDRETAG
F:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_3242.trc

MSCBRETAG
D:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_2552.trc

MSBHRETAG
E:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_2760.trc

MSBLRETAG
D:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_2672.trc

MSCOMERCIAL
F:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_22609.trc

MSMBRETAG
F:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_3391.trc

MSGRURETAG
E:\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_247.trc

MSSDSQLNFE
D:\SQL\SQL_Data_System\MSSQL10.MSSQLSERVER\MSSQL\Log\log_10491.trc

MSPNP
E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_4075.trc

MSPRDSAP
C:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_553.trc

MSSDRHDB
D:\SQLDados\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_50.trc

MSPOARETAG
E:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_3180.trc

MSPARETAG
F:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\LOG\log_2437.trc

MSSDSIACSQL02
D:\SQL_Data_System\MSSQL10.MSSQLSERVER\MSSQL\Log\log_341.trc

MSSDFISC
T:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\log_2862.trc

MSSTBOSQL
E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_969.trc

MSGORETAG
d:\dados\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_2242.trc

MSSDDW\BI
C:\Program Files\Microsoft SQL Server\MSSQL10_50.BI\MSSQL\Log\log_89.trc

MSURANO
E:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_8142.trc

MSCOMERCIAL01
E:\MSSQL.1\MSSQL\LOG\log_333.trc
*/
----------
----------
----------

use master
go

select * from sys.dm_xe_session_events
select * from sys.dm_xe_sessions
select * from sys.dm_xe_session_targets
select * from sys.dm_xe_session_event_actions
select * from sys.dm_xe_packages


create event session session_waits on server	
	add event sqlos.wait_info
		(where sqlserver.session_id = 1 and duration > 0)
   ,add event sqlos.wait_info_external
		(where sqlserver.session_id = 1 and duration > 0)
	add target package0.asynchronous_file_target
		(set filename=N'c:\temp\wait_stats.xel', metadatafile=N'c:\temp\wait_stats.xem');
go

alter event session session_waits on server state = start;
go

--drop event session session_waits on server;

--alter event session session_waits on server state = stop;

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
			max(signal_duration) as max_signal_duration,
			--cast(avg(duration) as numeric (5,2)) as avg_duration,
from		cte_xevent2
group by	wait_type
order by	sum(duration) desc;

/*
select * from sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null);

;with cte_xevent as 
(
	select	cast(event_data as xml) as xevent
	from	sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null)
)
select	* 
from	cte_xevent;

;with cte_xevent as 
(
	select	cast(event_data as xml) as xevent
	from	sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null)
)
select	xevent.value(N'(/event/data[@name="wait_type"]/text)[1]','sysname') as wait_type,
		xevent.value(N'(/event/data[@name="duration"]/text)[1]','int') as duration,
		xevent.value(N'(/event/data[@name="signal_duration"]/text)[1]','int') as signal_duration
from	cte_xevent;
*/
----------
----------
----------

use sgf_fisc
go

--verificar utilização arquivos
dbcc showfilestats
/*
Fileid	FileGroup	TotalExtents	UsedExtents	Name	FileName
1		1			563735			259068				SGF_FISC_Data	S:\Dados\SGF_FISC_Data.mdf
3		1			65536			28085				SGF_FISC_Data2	R:\Data\SGF_FISC_Data2.ndf
*/

use sgf_fisc
go

--zerar o arquivo a ser removido
dbcc SHRINKFILE ('SGF_FISC_Data2', EMPTYFILE);

--remover arquivo
alter database sgf_fisc remove file SGF_FISC_Data2


----------
----------
----------

select size, (size * 8) / 1024. /1024 from sys.master_files where database_id = DB_ID('qqg') and type = 1
select sum((size * 8) / 1024. /1024) from sys.master_files where database_id = DB_ID('qqg') 

use master
go

--identificar local atual arquivos
select name, physical_name, * from sys.master_files where database_id = DB_ID('qqg');
/*
qqg_Data	Y:\Dados\qqg.mdf
qqg_Log		Y:\Dados\qqg_log.ldf
*/

alter database qqg set single_user with rollback immediate;

--alterar caminho arquivos
alter database qqg modify file (name='qqg_Data',filename='L:\Dados\qqg.mdf');
alter database qqg modify file (name='qqg_Log',filename='L:\Dados\qqg_log.ldf');

--colocar a base de dados offline para movimentação dos arquivos
alter database qqg set offline;

--movimentar os arquivos para o novo local

--colocar a base de dados online para acesso multi_user
alter database qqg set online;
alter database qqg set multi_user;

--confirmação da movimentação dos arquivos
select name, physical_name, * from sys.master_files where database_id = DB_ID('qqg');
select user_access_desc,* from sys.databases where database_id = DB_ID('qqg');





----------
----------
----------

/*
ALTER DATABASE database_name   
{  
    <add_or_modify_files>  
  | <add_or_modify_filegroups>  
}  
[;]  

<add_or_modify_files>::=  
{  
    ADD FILE <filespec> [ ,...n ]   
        [ TO FILEGROUP { filegroup_name } ]  
  | ADD LOG FILE <filespec> [ ,...n ]   
  | REMOVE FILE logical_file_name   
  | MODIFY FILE <filespec>  
}  

<filespec>::=   
(  
    NAME = logical_file_name    
    [ , NEWNAME = new_logical_name ]   
    [ , FILENAME = {'os_file_name' | 'filestream_path' | 'memory_optimized_data_path' } ]   
    [ , SIZE = size [ KB | MB | GB | TB ] ]   
    [ , MAXSIZE = { max_size [ KB | MB | GB | TB ] | UNLIMITED } ]   
    [ , FILEGROWTH = growth_increment [ KB | MB | GB | TB| % ] ]   
    [ , OFFLINE ]  
)   

<add_or_modify_filegroups>::=  
{  
    | ADD FILEGROUP filegroup_name   
        [ CONTAINS FILESTREAM | CONTAINS MEMORY_OPTIMIZED_DATA ]  
    | REMOVE FILEGROUP filegroup_name   
    | MODIFY FILEGROUP filegroup_name  
        { <filegroup_updatability_option>  
        | DEFAULT  
        | NAME = new_filegroup_name   
        | { AUTOGROW_SINGLE_FILE | AUTOGROW_ALL_FILES }  
        }  
}  
<filegroup_updatability_option>::=  
{  
    { READONLY | READWRITE }   
    | { READ_ONLY | READ_WRITE }  
}  
*/
use dbTestes
go

select * from sys.database_files
select * from sys.filegroups

--data file
alter database dbTestes add file (name= 'dbTestes_Data3', filename = 'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\dbTestes_Data3.ndf', size = 512MB, maxsize=unlimited, filegrowth = 128 MB) to filegroup fg_teste

alter database dbTestes remove file dbTestes_Data3

alter database dbTestes modify file (name='dbTestes_Data3', size=640 MB, maxsize=2 GB, filegrowth=64 MB)

alter database dbTestes modify file (name='dbTestes_Data3', newname='dbTestes_Data_3')

--filegroup
alter database dbTestes add filegroup fg_teste

alter database dbTestes remove filegroup fg_teste

alter database dbTestes modify filegroup fg_teste default
alter database dbTestes modify filegroup [primary] default

----------
----------
----------


----------
----------
----------