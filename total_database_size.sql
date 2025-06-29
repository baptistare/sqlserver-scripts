/*
drop table ##tb_databases_size
go
create table ##tb_databases_size
(
	id int identity (1,1),
	instance varchar(128),
	database_name varchar(128),
	mount varchar(128),
	volume varchar(128),
	physical_name varchar(128),
	total_file_size_in_GB numeric(18,14),
	file_size_used_in_GB numeric(18,14),
	file_size_unused_in_GB  numeric(18,14),
	total_disk_size_in_GB  numeric(18,14),
	free_space_in_GB  numeric(18,14),
	dtProcessamento  varchar(128)

)
select * from ##tb_databases_size
*/

exec sp_msforeachdb ' use [?]

insert		##tb_databases_size (instance,database_name,mount,volume,physical_name,total_file_size_in_GB,file_size_used_in_GB,file_size_unused_in_GB,total_disk_size_in_GB,free_space_in_GB,dtProcessamento)
select		@@servername as instance,
			db_name(dfsu.database_id) as [database_name],
			dovs.volume_mount_point as mount,
			dovs.logical_volume_name as volume,
			mf.physical_name,


			sum(dfsu.total_page_count * 8) / 1024 / 1024. as total_file_size_in_GB,
			sum(dfsu.allocated_extent_page_count * 8) / 1024 / 1024.  as file_size_used_in_GB,
			sum(dfsu.unallocated_extent_page_count* 8) / 1024 / 1024. as file_size_unused_in_GB,
			dovs.total_bytes / 1024 / 1024 / 1024. as total_disk_size_in_GB,
			dovs.available_bytes / 1024 / 1024 / 1024. as free_space_in_GB,

			convert(varchar,getdate(),103) as dtProcessamento
from		sys.dm_db_file_space_usage dfsu with (nolock)
inner join	sys.master_files mf with (nolock) 
	on		dfsu.file_id=mf.file_id 
	and		dfsu.database_id=mf.database_id
cross apply sys.dm_os_volume_stats (mf.database_id, mf.file_id) as dovs
group by	db_name(dfsu.database_id), mf.physical_name, dovs.volume_mount_point, dovs.logical_volume_name, dovs.total_bytes / 1024 / 1024., dovs.available_bytes / 1024 / 1024., dovs.total_bytes / 1024 / 1024 / 1024., dovs.available_bytes / 1024 / 1024 / 1024.
'
