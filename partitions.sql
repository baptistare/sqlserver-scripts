with partitionedtables as 
(
    select		distinct 
				t.object_id,
				t.name as table_name
    from		sys.tables as t
    inner join	sys.indexes as si 
		on		t.object_id=si.object_id 
    inner join	sys.partition_schemes as sc 
		on		si.data_space_id=sc.data_space_id
)
select 
			pt.table_name,
			si.index_id,
			si.name as index_name,
			isnull(pf.name, 'NonAligned') AS partition_function,
			isnull(sc.name, fg.name) AS partition_scheme_or_filegroup,
			ic.partition_ordinal, /* 0= not a partitioning column*/
			ic.key_ordinal,
			ic.is_included_column,
			c.name AS column_name,
			t.name AS data_type_name,
			c.is_identity,
			ic.is_descending_key,
			si.filter_definition
from		partitionedtables as pt
inner join	sys.indexes as si 
	on		pt.object_id=si.object_id
inner join	sys.index_columns as ic 
	on		si.object_id=ic.object_id
    and		si.index_id=ic.index_id
inner join	sys.columns as c 
	on		ic.object_id=c.object_id
    and		ic.column_id=c.column_id
inner join	sys.types as t 
	on		c.system_type_id=t.system_type_id
left join	sys.partition_schemes as sc 
	on		si.data_space_id=sc.data_space_id
left join	sys.partition_functions as pf 
	on		sc.function_id=pf.function_id
left join	sys.filegroups as fg 
	on		si.data_space_id=fg.data_space_id
order by	1,2,3,4,5,6 desc,7,8
go