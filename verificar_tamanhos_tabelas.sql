select
			object_name(p.object_id) as tabela, 
			max(p.rows) as linhas,
			sum(au.total_pages * 8) as reservado_in_KB,
			sum(au.total_pages * 8) /1024. as reservado_in_MB,
			sum(au.total_pages * 8) / 1024 /1024. as reservado_in_GB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) as dados_in_KB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) /1024. as dados_in_MB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) / 1024 /1024. as dados_in_GB,
			sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) as indice_in_KB,
			(sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end)) /1024. as indice_in_MB,
			(sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end)) / 1024 /1024. as indice_in_GB,
			sum((au.total_pages - au.used_pages) * 8) as naoutilizado_in_KB,
			sum((au.total_pages - au.used_pages) * 8) /1024. as naoutilizado_in_MB,
			sum((au.total_pages - au.used_pages) * 8) / 1024 /1024. as naoutilizado_in_GB,
			sum(au.used_pages) as used_pages
from		sys.partitions as p with (nolock)
inner join	sys.allocation_units as au with (nolock)
	on		p.partition_id = au.container_id--hobt_id
inner join	sys.tables t with (nolock)
	on		p.object_id = t.object_id
group by	object_name(p.object_id)
order by	reservado_in_KB desc

select
			object_name(p.object_id) as tabela, 
			p.rows as linhas,
			f.name as filegroup,
			df.name as file_name,
			df.physical_name,
			sum(au.total_pages * 8) as reservado_in_KB,
			sum(au.total_pages * 8) /1024. as reservado_in_MB,
			sum(au.total_pages * 8) / 1024 /1024. as reservado_in_GB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) as dados_in_KB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) /1024. as dados_in_MB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) / 1024 /1024. as dados_in_GB,
			sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) as indice_in_KB,
			(sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end)) /1024. as indice_in_MB,
			(sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end)) / 1024 /1024. as indice_in_GB,
			sum((au.total_pages - au.used_pages) * 8) as naoutilizado_in_KB,
			sum((au.total_pages - au.used_pages) * 8) /1024. as naoutilizado_in_MB,
			sum((au.total_pages - au.used_pages) * 8) / 1024 /1024. as naoutilizado_in_GB,
			sum(au.used_pages) as used_pages
from		sys.partitions as p with (nolock)
inner join	sys.allocation_units as au with (nolock)
	on		p.partition_id = au.container_id--hobt_id
inner join	sys.tables t with (nolock)
	on		p.object_id = t.object_id
inner join	sys.filegroups f
	on		au.data_space_id = f.data_space_id
inner join	sys.database_files df
	on		au.data_space_id = df.data_space_id
group by	object_name(p.object_id), p.rows, f.name, df.name, df.physical_name
order by	6 desc

select
			object_name(p.object_id) as tabela, 
			p.index_id,
			i.name,
			p.rows as linhas,
			f.name as filegroup,
			df.name as file_name,
			df.physical_name,
			sum(au.total_pages * 8) as reservado_in_KB,
			sum(au.total_pages * 8) /1024. as reservado_in_MB,
			sum(au.total_pages * 8) / 1024 /1024. as reservado_in_GB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) as dados_in_KB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) /1024. as dados_in_MB,
			sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) / 1024 /1024. as dados_in_GB,
			sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end) as indice_in_KB,
			(sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end)) /1024. as indice_in_MB,
			(sum(au.used_pages * 8) - sum(case when p.index_id > 1 then 0 else au.data_pages * 8 end)) / 1024 /1024. as indice_in_GB,
			sum((au.total_pages - au.used_pages) * 8) as naoutilizado_in_KB,
			sum((au.total_pages - au.used_pages) * 8) /1024. as naoutilizado_in_MB,
			sum((au.total_pages - au.used_pages) * 8) / 1024 /1024. as naoutilizado_in_GB,
			sum(au.used_pages) as used_pages
from		sys.partitions as p with (nolock)
inner join	sys.allocation_units as au with (nolock)
	on		p.partition_id = au.container_id--hobt_id
inner join	sys.tables t with (nolock)
	on		p.object_id = t.object_id
inner join	sys.indexes i
	on		p.index_id = i.index_id
	and		t.object_id = i.object_id
inner join	sys.filegroups f
	on		au.data_space_id = f.data_space_id
inner join	sys.database_files df
	on		au.data_space_id = df.data_space_id
group by	object_name(p.object_id), p.index_id, i.name, p.rows, f.name, df.name, df.physical_name
order by	1


select		sum(total_pages * 8) / 1024 /1024. as reservado_in_GB
from		sys.partitions as p with (nolock)
inner join	sys.allocation_units as a with (nolock)
	on		p.partition_id = a.container_id--hobt_id
inner join	sys.tables t with (nolock)
	on		p.object_id = t.object_id

--tamanho base
with cte_reserved_pages as
(
	select		reservedpages = sum(a.total_pages),
				usedpages = sum(a.used_pages),
				pages = sum(
							case
								when it.internal_type IN (202,204,211,212,213,214,215,216) then 0
								when a.type <> 1 then a.used_pages
								when p.index_id < 2 then a.data_pages
								else 0
							end
							)
	from		sys.partitions p with (nolock) 
	join		sys.allocation_units a with (nolock)
		on		p.partition_id = a.container_id
	left join	sys.internal_tables it with (nolock)
		on		p.object_id = it.object_id
)
select		database_name = db_name(),
			database_size = ltrim(str((convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) + convert (dec (15,2),sum(convert(bigint,case when status & 64 <> 0 then size else 0 end)))) * 8192 / 1048576,15,2) + ' MB'),
			'unallocated space' = ltrim(str((case when sum(convert(bigint,case when status & 64 = 0 then size else 0 end)) >= c.reservedpages then (convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) - convert (dec (15,2),c.reservedpages)) * 8192 / 1048576 else 0 end),15,2) + ' MB')
from		cte_reserved_pages c with (nolock)
cross join	dbo.sysfiles with (nolock)	
group by	c.reservedpages
