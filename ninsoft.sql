dbcc sqlperf (logspace)
/*
BDTPNSFT	5474.117	1.175436	0	15:45
BDTPNSFT	5474.117	4.053049	0	16:12
BDTPNSFT	5474.117	42.41876	0	17:20
BDTPNSFT	12386.12	99.46262	0	19:54
BDTPNSFT	18530.12	1.07496		0	21:30

F	44598

*/

select percent_complete, estimated_completion_time, * from sys.dm_exec_requests where session_id = 86

xp_fixeddrives
/*
F	44598/44598/37686

*/

select * from sys.database_files
select * from sys.database_recovery_status

select 		db_name(dfsu.database_id) as database_name,
			df.[name] as data_file_name,
			df.physical_name,
			dfsu.[file_id],
			dfsu.[filegroup_id],
			dfsu.total_page_count * 8 / 1024. as total_data_file_size_in_MB,
			dfsu.allocated_extent_page_count * 8 / 1024. as allocated_data_file_size_in_MB,
			dfsu.unallocated_extent_page_count * 8 / 1024. as unallocated_data_file_size_in_MB,
			dfsu.total_page_count * 8 / 1024 / 1024. as total_data_file_size_in_GB,
			dfsu.allocated_extent_page_count * 8 / 1024 / 1024. as allocated_data_file_size_in_GB,
			dfsu.unallocated_extent_page_count * 8 / 1024 / 1024. as unallocated_data_file_size_in_GB,
			dfsu.total_page_count * 8 / 1024 / 1024 / 1024. as total_data_file_size_in_TB,
			dfsu.allocated_extent_page_count * 8 / 1024 / 1024 / 1024. as allocated_data_file_size_in_TB,
			dfsu.unallocated_extent_page_count * 8 / 1024 / 1024 / 1024. as unallocated_data_file_size_in_TB
from		sys.dm_db_file_space_usage dfsu with (nolock)
inner join	sys.database_files df
	on		dfsu.[filegroup_id] = df.data_space_id
	and		dfsu.[file_id] = df.[file_id]

select	db_name() as database_name,
		df.[name] as log_file_name,
		df.physical_name,
		df.[file_id],
		df.data_space_id,
		df.size * 8 / 1024. as total_log_file_size_in_MB,
		df.size * 8 / 1024 / 1024. as total_log_file_size_in_GB
from	sys.database_files df
where	type = 1

select 	db_name() as database_name,
		total_log_size_in_bytes / 1024 / 1024. as total_log_size_in_MB,
		used_log_space_in_bytes / 1024 / 1024. as used_log_space_in_MB,
		(total_log_size_in_bytes - used_log_space_in_bytes) / 1024 / 1024. as unused_log_space_in_MB,
		total_log_size_in_bytes / 1024 / 1024 / 1024. as total_log_size_in_GB,
		used_log_space_in_bytes / 1024 / 1024 / 1024. as used_log_space_in_GB,
		(total_log_size_in_bytes - used_log_space_in_bytes) / 1024 / 1024 / 1024. as unused_log_space_in_GB,
		used_log_space_in_percent,
		(100 - used_log_space_in_percent) as unused_log_space_in_percent
from	sys.dm_db_log_space_usage

select * from sys.database_files

select * from sys.databases

select		b2.database_name, b2.type, max(b2.backup_start_date) backup_start_date, max(b2.backup_finish_date) backup_finish_date
from		msdb..backupset as b2
group by	b2.database_name, b2.type
order by	b2.database_name

--BDTPNSFT	D	2019-02-11 16:47:39.000	2019-02-11 19:52:24.000

--select * from msdb..backupset

exec master..sp_WhoIsActive
go
select 	db_name() as database_name,
		total_log_size_in_bytes / 1024 / 1024. as total_log_size_in_MB,
		used_log_space_in_bytes / 1024 / 1024. as used_log_space_in_MB,
		(total_log_size_in_bytes - used_log_space_in_bytes) / 1024 / 1024. as unused_log_space_in_MB,
		total_log_size_in_bytes / 1024 / 1024 / 1024. as total_log_size_in_GB,
		used_log_space_in_bytes / 1024 / 1024 / 1024. as used_log_space_in_GB,
		(total_log_size_in_bytes - used_log_space_in_bytes) / 1024 / 1024 / 1024. as unused_log_space_in_GB,
		used_log_space_in_percent,
		(100 - used_log_space_in_percent) as unused_log_space_in_percent
from	sys.dm_db_log_space_usage