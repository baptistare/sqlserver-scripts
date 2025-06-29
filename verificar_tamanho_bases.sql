if object_id('tempdb..##tb_databases') is not null
	drop table ##tb_databases;

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
			database_size_in_MB = ltrim(str((convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) + convert (dec (15,2),sum(convert(bigint,case when status & 64 <> 0 then size else 0 end)))) * 8192 / 1048576,15,2) ),
			database_size_in_GB = ltrim(str((convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) + convert (dec (15,2),sum(convert(bigint,case when status & 64 <> 0 then size else 0 end)))) * 8192 / 1048576 / 1024,15,2) ),
			space_available_in_MB = ltrim(str((case when sum(convert(bigint,case when status & 64 = 0 then size else 0 end)) >= c.reservedpages then (convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) - convert (dec (15,2),c.reservedpages)) * 8192 / 1048576 else 0 end),15,2) ),
			space_available_in_GB = ltrim(str((case when sum(convert(bigint,case when status & 64 = 0 then size else 0 end)) >= c.reservedpages then (convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) - convert (dec (15,2),c.reservedpages)) * 8192 / 1048576 / 1024 else 0 end),15,2) )
into		##tb_databases
from		cte_reserved_pages c with (nolock)
cross join	dbo.sysfiles with (nolock)
where		1=2
group by	c.reservedpages
go

exec sp_msforeachdb 'use [?];

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
insert		##tb_databases
select		database_name = db_name(),
			database_size = ltrim(str((convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) + convert (dec (15,2),sum(convert(bigint,case when status & 64 <> 0 then size else 0 end)))) * 8192 / 1048576,15,2)),
			database_size_in_GB = ltrim(str((convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) + convert (dec (15,2),sum(convert(bigint,case when status & 64 <> 0 then size else 0 end)))) * 8192 / 1048576 / 1024,15,2) ),
			''space_available'' = ltrim(str((case when sum(convert(bigint,case when status & 64 = 0 then size else 0 end)) >= c.reservedpages then (convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) - convert (dec (15,2),c.reservedpages)) * 8192 / 1048576 else 0 end),15,2)),
			''space_available_in_GB'' = ltrim(str((case when sum(convert(bigint,case when status & 64 = 0 then size else 0 end)) >= c.reservedpages then (convert (dec (15,2),sum(convert(bigint,case when status & 64 = 0 then size else 0 end))) - convert (dec (15,2),c.reservedpages)) * 8192 / 1048576 / 1024 else 0 end),15,2))
from		cte_reserved_pages c with (nolock)
cross join	dbo.sysfiles with (nolock)
group by	c.reservedpages'
go

select * from ##tb_databases
