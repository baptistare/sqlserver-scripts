--database a ser verificado o plan cache
use BDTPEDI
go

--info memory
select	physical_memory_kb, physical_memory_kb / 1024 / 1024. as physical_memory_gb, 
		virtual_memory_kb, virtual_memory_kb / 1024 /1024. as virtual_memory_gb,
		committed_kb, committed_kb /1024 / 1024. as committed_gb,
		committed_target_kb, committed_target_kb / 1024 / 1024. as committed_target_gb
from	sys.dm_os_sys_info with (nolock);

--tamanho buffer cache
select	count(*) as buffer_cache_pages,
		count(*) * 8 / 1024. as buffer_cache_used_mb,
		count(*) * 8 / 1024 / 1024. as buffer_cache_used_gb
from	sys.dm_os_buffer_descriptors with (nolock);

--tamanho databases no cache
select		databases.name as database_name,
			count(*) * 8 / 1024. as mb_used,
			count(*) * 8 / 1024 / 1024. as gb_used
from		sys.dm_os_buffer_descriptors with (nolock)
inner join	sys.databases with (nolock)
	on		databases.database_id = dm_os_buffer_descriptors.database_id
group by	databases.name
order by	count(*) desc;

--tamanho tabelas no cache
select		top 25
			objects.name as object_name,
			objects.type_desc as object_type_description,
			count(*) as buffer_cache_pages,
			count(*) * 8 / 1024.  as buffer_cache_used_mb
from		sys.dm_os_buffer_descriptors with (nolock)
inner join	sys.allocation_units with (nolock)
	on		allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
inner join	sys.partitions with (nolock)
	on		((allocation_units.container_id = partitions.hobt_id and type in (1,3))
	or		(allocation_units.container_id = partitions.partition_id and type in (2)))
inner join	sys.objects with (nolock)
	on		partitions.object_id = objects.object_id
where		allocation_units.type in (1,2,3)
	and		objects.is_ms_shipped = 0
	and		dm_os_buffer_descriptors.database_id = db_id()
group by	objects.name, objects.type_desc
order by	count(*) desc;

--tamanho indices no cache
select		top 25
			case when indexes.index_id = 0 then 'Heap Table' else indexes.name end as index_name,
			objects.name as object_name,
			objects.type_desc as object_type_description,
			count(*) as buffer_cache_pages,
			count(*) * 8 / 1024.  as buffer_cache_used_mb
from		sys.dm_os_buffer_descriptors with (nolock)
inner join	sys.allocation_units with (nolock)
	on		allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
inner join	sys.partitions with (nolock)
	on		((allocation_units.container_id = partitions.hobt_id and type in (1,3))
	or		(allocation_units.container_id = partitions.partition_id and type in (2)))
inner join	sys.objects with (nolock)
	on		partitions.object_id = objects.object_id
inner join	sys.indexes with (nolock)
	on		objects.object_id = indexes.object_id
	and		partitions.index_id = indexes.index_id
where		allocation_units.type in (1,2,3)
	and		objects.is_ms_shipped = 0
	and		dm_os_buffer_descriptors.database_id = db_id()
group by	indexes.name, objects.name, objects.type_desc
order by	count(*) desc;

--porcentagem tabela no cache
with cte_buffer_cache as 
(
	select
				objects.name as object_name,
				objects.type_desc as object_type_description,
				objects.object_id,
				count(*) as buffer_cache_pages,
				count(*) * 8 / 1024.  as buffer_cache_used_mb,
				count(*) * 8 / 1024 / 1024.  as buffer_cache_used_gb
	from		sys.dm_os_buffer_descriptors with (nolock)
	inner join	sys.allocation_units with (nolock)
		on		allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
	inner join	sys.partitions with (nolock)
		on		((allocation_units.container_id = partitions.hobt_id and type in (1,3))
		or		(allocation_units.container_id = partitions.partition_id and type in (2)))
	inner join	sys.objects with (nolock)
		on		partitions.object_id = objects.object_id
	where		allocation_units.type in (1,2,3)
		and		objects.is_ms_shipped = 0
		and		dm_os_buffer_descriptors.database_id = db_id()
	group by	objects.name, objects.type_desc, objects.object_id
)
select
			partition_stats.name,
			cte_buffer_cache.object_type_description,
			cte_buffer_cache.buffer_cache_pages,
			cte_buffer_cache.buffer_cache_used_mb,
			cte_buffer_cache.buffer_cache_used_gb,
			partition_stats.total_number_of_used_pages,
			partition_stats.total_number_of_used_pages * 8 / 1024. as total_mb_used_by_object,
			partition_stats.total_number_of_used_pages * 8 / 1024 / 1024. as total_gb_used_by_object,
			cast((cast(cte_buffer_cache.buffer_cache_pages as decimal) / cast(partition_stats.total_number_of_used_pages as decimal) * 100) as decimal(5,2)) as percent_of_pages_in_memory
from		cte_buffer_cache
inner join (
			select 
						objects.name,
						objects.object_id,
						sum(total_pages) as total_number_of_used_pages
			from		sys.partitions with (nolock)
			inner join	sys.allocation_units with (nolock)
				on		((allocation_units.container_id = partitions.hobt_id and type in (1,3))
				or		(allocation_units.container_id = partitions.partition_id and type in (2)))
			inner join	sys.objects with (nolock)
				on		objects.object_id = partitions.object_id
			where		objects.is_ms_shipped = 0
			group by	objects.name, objects.object_id) partition_stats
				on		partition_stats.object_id = cte_buffer_cache.object_id
order by	cast(cte_buffer_cache.buffer_cache_pages as decimal) / cast(partition_stats.total_number_of_used_pages as decimal) desc;

--porcentagem indice no cache
select
			indexes.name as index_name,
			objects.name as object_name,
			objects.type_desc as object_type_description,
			count(*) as buffer_cache_pages,
			count(*) * 8 / 1024.  as buffer_cache_used_mb,
			count(*) * 8 / 1024 / 1024. as buffer_cache_used_gb,
			sum(allocation_units.used_pages) as pages_in_index,
			sum(allocation_units.used_pages) * 8 / 1024. as total_index_size_mb,
			sum(allocation_units.used_pages) * 8 / 1024 /1024. as total_index_size_gb,
			cast((cast(count(*) as decimal) / cast(sum(allocation_units.used_pages) as decimal) * 100) as decimal(5,2)) as percent_of_pages_in_memory
from		sys.dm_os_buffer_descriptors with (nolock)
inner join	sys.allocation_units with (nolock)
	on		allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
inner join	sys.partitions with (nolock)
	on		((allocation_units.container_id = partitions.hobt_id and type in (1,3))
	or		(allocation_units.container_id = partitions.partition_id and type in (2)))
inner join	sys.objects with (nolock)
	on		partitions.object_id = objects.object_id
inner join	sys.indexes with (nolock)
	on		objects.object_id = indexes.object_id
	and		partitions.index_id = indexes.index_id
where		allocation_units.type in (1,2,3)
	and		objects.is_ms_shipped = 0
	and		dm_os_buffer_descriptors.database_id = db_id()
group by	indexes.name, objects.name, objects.type_desc
order by	cast((cast(count(*) as decimal) / cast(sum(allocation_units.used_pages) as decimal) * 100) as decimal(5,2)) desc;
 

 --espaço livre nas páginas de dados no cache por base de dados
 with cte_buffer_cache as
( 
	select
				databases.name as database_name,
				count(*) as total_number_of_used_pages,
				cast(count(*) * 8 as decimal) / 1024. as buffer_cache_total_mb,
				cast(count(*) * 8 as decimal) / 1024 / 1024. as buffer_cache_total_gb,
				cast(cast(sum(cast(dm_os_buffer_descriptors.free_space_in_bytes as bigint)) as decimal) / (1024 * 1024) as decimal(20,2))  as buffer_cache_free_space_in_mb,
				cast(cast(sum(cast(dm_os_buffer_descriptors.free_space_in_bytes as bigint)) as decimal) / (1024 * 1024 * 1024) as decimal(20,2))  as buffer_cache_free_space_in_gb
	from		sys.dm_os_buffer_descriptors with (nolock)
	inner join	sys.databases with (nolock)
		on		databases.database_id = dm_os_buffer_descriptors.database_id
	group by	databases.name
)
select		*,
			cast((buffer_cache_free_space_in_mb / nullif(buffer_cache_total_mb, 0)) * 100 as decimal(5,2)) as buffer_cache_percent_free_space
from		cte_buffer_cache
order by	buffer_cache_free_space_in_mb / nullif(buffer_cache_total_mb, 0) desc

--espaço livre nas páginas de dados no cache por tabela
select
			objects.name as object_name,
			objects.type_desc as object_type_description,
			count(*) as buffer_cache_pages,
			cast(count(*) * 8 as decimal) / 1024.  as buffer_cache_total_mb,
			cast(count(*) * 8 as decimal) / 1024 / 1024.  as buffer_cache_total_gb,
			cast(sum(cast(dm_os_buffer_descriptors.free_space_in_bytes as bigint)) as decimal) / 1024 / 1024. as buffer_cache_free_space_in_mb,
			cast(sum(cast(dm_os_buffer_descriptors.free_space_in_bytes as bigint)) as decimal) / 1024 / 1024 / 1024. as buffer_cache_free_space_in_gb,
			cast((cast(sum(cast(dm_os_buffer_descriptors.free_space_in_bytes as bigint)) as decimal) / 1024 / 1024) / (cast(count(*) * 8 as decimal) / 1024) * 100 as decimal(5,2)) as buffer_cache_percent_free_space
from		sys.dm_os_buffer_descriptors with (nolock)
inner join	sys.allocation_units with (nolock)
	on		allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
inner join	sys.partitions with (nolock)
	on		((allocation_units.container_id = partitions.hobt_id and type in (1,3))
	or		(allocation_units.container_id = partitions.partition_id and type in (2)))
inner join	sys.objects with (nolock)
	on		partitions.object_id = objects.object_id
where		allocation_units.type in (1,2,3)
	and		objects.is_ms_shipped = 0
	and		dm_os_buffer_descriptors.database_id = db_id()
group by	objects.name, objects.type_desc, objects.object_id
having		count(*) > 0
order by	count(*) desc;

--utilização e tamanho das páginas de dados no cache por base de dados
select
			databases.name as database_name,
			count(*) as buffer_cache_total_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) as buffer_cache_dirty_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) as buffer_cache_clean_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) * 8 / 1024. as buffer_cache_dirty_page_mb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) * 8 / 1024 / 1024. as buffer_cache_dirty_page_gb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) * 8 / 1024 as buffer_cache_clean_page_mb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) * 8 / 1024 / 1024. as buffer_cache_clean_page_gb
from		sys.dm_os_buffer_descriptors with (nolock)
inner join	sys.databases with (nolock)
	on		dm_os_buffer_descriptors.database_id = databases.database_id
group by	databases.name;

--utilização e tamanho das páginas de dados no cache por tabela
select
			objects.name as object_name,
			objects.type_desc as object_type_description,
			count(*) as buffer_cache_total_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) as buffer_cache_dirty_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) as buffer_cache_clean_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) * 8 / 1024. as buffer_cache_dirty_page_mb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) * 8 / 1024 / 1024. as buffer_cache_dirty_page_gb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) * 8 / 1024. as buffer_cache_clean_page_mb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) * 8 / 1024 / 1024. as buffer_cache_clean_page_gb
from		sys.dm_os_buffer_descriptors with (nolock)
inner join	sys.allocation_units with (nolock)
	on		allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
inner join	sys.partitions with (nolock)
	on		((allocation_units.container_id = partitions.hobt_id and type in (1,3))
	or		(allocation_units.container_id = partitions.partition_id and type in (2)))
inner join	sys.objects with (nolock)
	on		partitions.object_id = objects.object_id
where		allocation_units.type in (1,2,3)
	and		objects.is_ms_shipped = 0
	and		dm_os_buffer_descriptors.database_id = db_id()
group by	objects.name, objects.type_desc
order by	count(*) desc;


--utilização e tamanho das páginas de dados no cache por indice
select
			indexes.name as index_name,
			objects.name as object_name,
			objects.type_desc as object_type_description,
			count(*) as buffer_cache_total_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) as buffer_cache_dirty_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) as buffer_cache_clean_pages,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) * 8 / 1024. as buffer_cache_dirty_page_mb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 1
						else 0
				end) * 8 / 1024 / 1024. as buffer_cache_dirty_page_gb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) * 8 / 1024. as buffer_cache_clean_page_mb,
			sum(case when dm_os_buffer_descriptors.is_modified = 1
						then 0
						else 1
				end) * 8 / 1024 / 1024. as buffer_cache_clean_page_gb
from		sys.dm_os_buffer_descriptors with (nolock)
inner join	sys.allocation_units with (nolock)
	on		allocation_units.allocation_unit_id = dm_os_buffer_descriptors.allocation_unit_id
inner join	sys.partitions with (nolock)
	on		((allocation_units.container_id = partitions.hobt_id and type in (1,3))
	or		(allocation_units.container_id = partitions.partition_id and type in (2)))
inner join	sys.objects with (nolock)
	on		partitions.object_id = objects.object_id
inner join	sys.indexes with (nolock)
	on		objects.object_id = indexes.object_id
	and		partitions.index_id = indexes.index_id
where		allocation_units.type in (1,2,3)
	and		objects.is_ms_shipped = 0
	and		dm_os_buffer_descriptors.database_id = db_id()
group by	indexes.name, objects.name, objects.type_desc
order by	count(*) desc;

--

select	*
from	sys.dm_os_performance_counters
where	dm_os_performance_counters.object_name like '%buffer manager%'
	and dm_os_performance_counters.counter_name = 'page life expectancy';
 

select	*
from	sys.dm_os_performance_counters
where	dm_os_performance_counters.object_name like '%buffer node%'
	and dm_os_performance_counters.counter_name = 'page life expectancy';
 

