use tempdb
go

create table tb_shrink_execution_time
(
	id int identity (1,1) not null,
	dt_insert datetime default (getdate())
)

--truncate table tb_shrink_execution_time
--select * from tb_shrink_execution_time

use master--nome base
go

declare @file_size_unused_in_MB int = null --149560
declare @total_file_size_in_MB int = null
declare @resize int = null
declare @sql nvarchar(max) = null

select		@total_file_size_in_MB = sum(dfsu.total_page_count * 8) / 1024,
			@file_size_unused_in_MB = sum(dfsu.unallocated_extent_page_count * 8) / 1024.
from		sys.dm_db_file_space_usage dfsu with (nolock)
join		sys.master_files mf with (nolock)
on			dfsu.file_id = mf.file_id
and			dfsu.database_id = mf.database_id
cross apply	sys.dm_os_volume_stats (mf.database_id, mf.file_id) as dovs
group by	db_name(dfsu.database_id), mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, dovs.total_bytes / 1024 / 1024., dovs.available_bytes / 1024 / 1024., dovs.total_bytes / 1024 / 1024 / 1024., dovs.available_bytes / 1024 / 1024 / 1024.

--select @total_file_size_in_MB
--select @file_size_unused_in_MB

while @file_size_unused_in_MB >= 10240
begin
	set @resize = @total_file_size_in_MB - 1024--1GB

	insert tempdb..tb_shrink_execution_time default values

	set @sql = N'checkpoint; dbcc shrinkfile (1,' + cast(@resize as varchar(128)) + ');'
	exec sp_executesql @sql

	select		@total_file_size_in_MB = sum(dfsu.total_page_count * 8) / 1024,
				@file_size_unused_in_MB = sum(dfsu.unallocated_extent_page_count * 8) / 1024.
	from		sys.dm_db_file_space_usage dfsu with (nolock)
	join		sys.master_files mf with (nolock)
	on			dfsu.file_id = mf.file_id
	and			dfsu.database_id = mf.database_id
	cross apply	sys.dm_os_volume_stats (mf.database_id, mf.file_id) as dovs
	group by	db_name(dfsu.database_id), mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, dovs.total_bytes / 1024 / 1024., dovs.available_bytes / 1024 / 1024., dovs.total_bytes / 1024 / 1024 / 1024., dovs.available_bytes / 1024 / 1024 / 1024.

	--se select acima demorar muito, descomentar o trecho abaixo e deixar valor fixo
	--set @file_size_unused_in_MB = @file_size_unused_in_MB - 1024
end