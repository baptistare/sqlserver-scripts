use dinoDB
go
select		t.object_id, t.name, p.index_id, p.rows, au.total_pages, au.used_pages, au.data_pages, f.name, df.file_id, df.physical_name
from		sys.tables t
inner join	sys.partitions p
	on		t.object_id = p.object_id
inner join	sys.allocation_units au
	on		p.partition_id = au.container_id
inner join	sys.filegroups f
	on		au.data_space_id = f.data_space_id
inner join	sys.database_files df
	on		au.data_space_id = df.data_space_id
where		t.object_id = object_id('syslogData')



