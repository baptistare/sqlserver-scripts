select count(*) from sys.tables--95

select		count(distinct t.name)
from		sys.indexes i
inner join	sys.tables t
	on		i.object_id = t.object_id
inner join	sys.schemas s
	on		t.schema_id = s.schema_id
inner join	sys.filegroups f
	on		i.data_space_id = f.data_space_id
inner join	sys.all_objects o
	on		i.object_id = o.object_id 
where		o.type = 'U'--82

select		count(distinct t.name)
from		sys.indexes i
inner join	sys.partition_schemes s 
	on		i.data_space_id = s.data_space_id
inner join	sys.tables t 
	on		i.object_id = t.object_id--13

--########################################################################################################


select		object_schema_name(t.object_id) as schema_name, t.name as table_name, case when i.name is null then 'Heap Table' else i.name end as index_name, i.index_id, f.name as filegroup_name
from		sys.indexes i
inner join	sys.tables t
	on		i.object_id = t.object_id
inner join	sys.filegroups f
	on		i.data_space_id = f.data_space_id
inner join	sys.all_objects o
	on		i.object_id = o.object_id 
where		o.type = 'U'

select 
			object_schema_name(i.object_id) as [schema],
			object_name(i.object_id) as [object_name],
			t.name as [table_name],
			i.name as [index_name],
			s.name as [partition_scheme]
from		sys.indexes i
inner join	sys.partition_schemes s 
	on		i.data_space_id = s.data_space_id
inner join	sys.tables t 
	on		i.object_id = t.object_id--13

--#######################################################################################################

select
			object_name(p.object_id) as tabela, 
			rows as linhas,
			sum(total_pages * 8) as reservado,
			sum(total_pages * 8) / 1024 /1024. as reservado_in_GB,
			sum(case when i.index_id > 1 then 0 else data_pages * 8 end) as dados,
				sum(used_pages * 8) -
				sum(case when i.index_id > 1 then 0 else data_pages * 8 end) as indice,
			sum((total_pages - used_pages) * 8) as naoutilizado,
			sum(a.used_pages) as used_pages
from		sys.partitions as p with (nolock)
inner join	sys.allocation_units as a with (nolock)
	on		p.partition_id = a.container_id--hobt_id
inner join	sys.tables t with (nolock)
	on		p.object_id = t.object_id
inner join	sys.indexes i
	on		t.object_id = i.object_id
inner join	sys.filegroups f
	on		i.data_space_id = f.data_space_id
inner join	sys.all_objects o
	on		i.object_id = o.object_id
where		o.type = 'U'	 
group by object_name(p.object_id), rows
order by 4 desc


select
			object_name(p.object_id) as tabela, 
			rows as linhas,
			sum(total_pages * 8) as reservado,
			sum(total_pages * 8) / 1024 /1024. as reservado_in_GB,
			sum(case when i.index_id > 1 then 0 else data_pages * 8 end) as dados,
				sum(used_pages * 8) -
				sum(case when i.index_id > 1 then 0 else data_pages * 8 end) as indice,
			sum((total_pages - used_pages) * 8) as naoutilizado,
			sum(a.used_pages) as used_pages
from		sys.partitions as p with (nolock)
inner join	sys.allocation_units as a with (nolock)
	on		p.partition_id = a.container_id--hobt_id
inner join	sys.tables t with (nolock)
	on		p.object_id = t.object_id
inner join	sys.indexes i
	on		t.object_id = i.object_id
inner join	sys.partition_schemes s 
	on		i.data_space_id = s.data_space_id
inner join	sys.all_objects o
	on		i.object_id = o.object_id
where		o.type = 'U'	 
group by object_name(p.object_id), rows
order by 4 desc