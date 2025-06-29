use DBA_Admin
go

--drop table tb_who_is_active

if OBJECT_ID('DBA_Admin.dbo.tb_who_is_active','U') is null
begin
	create table dbo.tb_who_is_active 
	( 
		id						int identity primary key not null	,
		[dd hh:mm:ss.mss]		varchar(8000) NULL					,
		[session_id]			smallint NOT NULL					,
		[blocking_session_id]	smallint NULL						,
		[sql_text]				xml NULL							,
		[sql_command]			xml	NULL							,
		[query_plan]			xml	NULL							,
		[login_name]			nvarchar(128) NOT NULL				,
		[host_name]				nvarchar(128) NULL					,
		[database_name]			nvarchar(128) NULL					,
		[program_name]			nvarchar(128) NULL					,
		[wait_info]				nvarchar(4000) NULL					,
		[CPU]					varchar(30) NULL					,
		[reads]					varchar(30) NULL					,
		[writes]				varchar(30) NULL					,
		[physical_reads]		varchar(30) NULL					,
		[used_memory]			varchar(30) NULL					,
		[tempdb_allocations]	varchar(30) NULL					,
		[tempdb_current]		varchar(30) NULL					,
		[status]				varchar(30) NOT NULL				,
		[open_tran_count]		varchar(30) NULL					,
		[percent_complete]		varchar(30) NULL					,
		[start_time]			datetime NOT NULL					,
		[login_time]			datetime NULL						,
		[request_id]			int NULL							,
		[collection_time]		datetime NOT NULL
	)
end

exec master..sp_WhoIsActive @format_output = 1, @destination_table = 'DBA_Admin.dbo.tb_who_is_active', @get_plans = 1, @get_outer_command = 1, @output_column_list = '[dd hh:mm:ss.mss],[session_id],[blocking_session_id],[sql_text],[sql_command],[query_plan],[login_name],[host_name],[database_name],[program_name],[wait_info],[CPU],[reads],[writes],[physical_reads],[used_memory],[tempdb_allocations],[tempdb_current],[status],[open_tran_count],[percent_complete],[start_time],[login_time],[request_id],[collection_time]'

select * from DBA_Admin.dbo.tb_who_is_active

