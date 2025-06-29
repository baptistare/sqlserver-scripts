use master
go

--verificação databases, datafiles, filegroups por instância
if object_id('tempdb..#tb_info_databases') is not null
	drop table #tb_info_databases;

create table #tb_info_databases (database_name varchar(128), file_id int, size int, file_type bit, file_logical_name varchar(128), file_physical_name varchar(255), filegroup_name varchar(64), is_default bit);
go

sp_msforeachdb 'use [?];
				insert #tb_info_databases
				select		db_name() as database_name, df.file_id, df.size, df.type as file_type, df.name as file_logical_name, df.physical_name as file_physical_name, f.name as filegroup_name, f.is_default
				from		sys.database_files df
				left join	sys.filegroups f
					on		df.data_space_id = f.data_space_id
				order by	df.file_id
				'
select * from #tb_info_databases;
select size * 8 / 1024 / 1024., * from #tb_info_databases where database_name = 'DB_BAM' order by 1 desc

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

