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
from		sys.tables t with (nolock)
inner join	sys.indexes i with (nolock)
	on		t.object_id = i.object_id
inner join	sys.index_columns ic with (nolock)
	on		i.object_id = ic.object_id
	and		i.index_id = ic.index_id
inner join	sys.columns c with (nolock)
	on		ic.object_id = c.object_id
	and		ic.column_id = c.column_id
inner join	sys.types ty with (nolock)
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		t.object_id = OBJECT_ID('TRANS_DATA')
--	and		i.name = 'SCI_PK_14_2'
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
from		sys.tables t with (nolock)
inner join	sys.columns c with (nolock)
	on		t.object_id = c.object_id
inner join	sys.types ty with (nolock)
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		t.object_id = OBJECT_ID('TRANS_DATA')
order by	c.column_id

--stats
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
			s.filter_definition
from		sys.tables t with (nolock)
inner join	sys.stats s with (nolock)
	on		t.object_id = s.object_id
inner join	sys.stats_columns sc with (nolock)
	on		s.object_id = sc.object_id
	and		s.stats_id = sc.stats_id	
inner join	sys.columns c with (nolock)
	on		sc.object_id = c.object_id
	and		sc.column_id = c.column_id
inner join	sys.types ty with (nolock)
	--on		c.system_type_id = ty.system_type_id
	on		c.user_type_id = ty.user_type_id 
where		t.object_id = OBJECT_ID('TRANS_DATA')
	--and		s.name = 'pk_mfat_itemnf'
order by	sc.stats_column_id

--fragmentation
select		object_name(a.object_id),b.name,a.avg_fragmentation_in_percent,a.*
from		sys.dm_db_index_physical_stats(db_id('BDTPEDI'),object_id('TRANS_DATA'),1,null,null) a 
--from		sys.dm_db_index_physical_stats(db_id('BDTPEDI'),object_id('TRANS_DATA'),1,null,'DETAILED') a 
join		sys.indexes b with (nolock)
	on		a.object_id = b.object_id 
	and		a.index_id = b.index_id
	and		a.page_count > 20
	and		a.index_id > 0	
order by	object_name(b.object_id), b.index_id

--utilization
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
from		sys.tables t with (nolock)
inner join	sys.dm_db_index_usage_stats dius with (nolock)
	on		t.object_id = dius.object_id
inner join	sys.indexes i with (nolock)
	on		t.object_id = i.object_id
	and		i.index_id = dius.index_id
where		t.object_id = OBJECT_ID('TRANS_DATA')
	and		dius.database_id = db_id()
--order by	dius.user_seeks