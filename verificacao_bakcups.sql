use tempdb
go

if	not exists (select 1 from sys.dm_hadr_availability_group_states with (nolock))
	or 
	exists (select 1 from sys.dm_hadr_availability_group_states with (nolock) where primary_replica = @@SERVERNAME)
begin
	begin try
		if OBJECT_ID('tempdb.dbo.tb_database_backup','U') is null
			create table dbo.tb_database_backup
			(
				id					tinyint			identity			,
				database_name		varchar(128)	not null			,
				recovery_model		tinyint			not null			,
				fl_bkp_full			bit				not null			,
				fl_bkp_diff			bit				not null			,
				fl_bkp_log			bit				not null			,
				threshold_bkp_full	tinyint			null				,
				threshold_bkp_diff	tinyint			null				,
				threshold_bkp_log	tinyint			null				,
				dt_cadastro			datetime		default(getdate())
			);

		if OBJECT_ID('tempdb.dbo.tb_info_database_backup','U') is null
			create table dbo.tb_info_database_backup
			(
				id						tinyint			identity	,
				database_name			varchar(128)	not null	,
				type_backup				char(1)			not null	,
				last_backup_start_date	datetime		null		,
				last_backup_finish_date	datetime		null		,
				[difference]			smallint		null		
			);

		truncate table dbo.tb_database_backup;
		truncate table dbo.tb_info_database_backup;

		insert	dbo.tb_database_backup (database_name, recovery_model, fl_bkp_full, fl_bkp_diff, fl_bkp_log, threshold_bkp_full, threshold_bkp_diff, threshold_bkp_log)
		select	name, recovery_model, 1 as fl_bkp_full, 1 as fl_bkp_diff, 1 as fl_bkp_log, 1 as threshold_bkp_full, 1 as threshold_bkp_diff, 2 as threshold_bkp_log 
		from	sys.databases with (nolock)
		where	database_id not in (2);

		insert		dbo.tb_info_database_backup (database_name, type_backup, last_backup_start_date, last_backup_finish_date, [difference])
		select		b2.database_name, b2.type, max(b2.backup_start_date) backup_start_date, max(b2.backup_finish_date) backup_finish_date,
					case 
						when b2.type = 'D' then DATEDIFF(dd,max(b2.backup_start_date),getdate())
						when b2.type = 'I' then DATEDIFF(dd,max(b2.backup_start_date),getdate())
						when b2.type = 'L' then DATEDIFF(hh,max(b2.backup_start_date),getdate())
					end as diff
		from		msdb..backupset as b2 with (nolock)
		inner join	dbo.tb_database_backup db with (nolock)
			on		b2.database_name = db.database_name
		where		1=1
			and		(
						b2.type = 'D' and fl_bkp_full = 1
					or
						b2.type = 'I' and fl_bkp_diff = 1
					or	
						b2.type = 'L' and fl_bkp_log = 1
					)
		group by	b2.database_name, b2.type
		order by	b2.database_name;

		--backup Full
		select		'FULL' as 'Informações Backup', 
					db.database_name, 
					case 
						when db.recovery_model = 1 then 'FULL' 
						when db.recovery_model = 2 then 'BULK LOGGED' 
						when db.recovery_model = 3 then 'SIMPLE' 
					end as recovery_model,
					db.fl_bkp_full,
					db.fl_bkp_diff,
					db.fl_bkp_log,
					db.threshold_bkp_full,
					db.threshold_bkp_diff,
					db.threshold_bkp_log,
					--case when isnull(idb.type_backup,'') = '' then 'Sem Backup Full' else idb.type_backup end as type_backup,
					--case when isnull(idb.last_backup_start_date,'') = '' then 'Sem Backup Full' else idb.last_backup_start_date end as last_backup_start_date,
					--case when isnull(idb.last_backup_finish_date,'') IS NULL then 'Sem Backup Full' else idb.last_backup_finish_date end as last_backup_finish_date,
					--case when isnull(idb.difference,'') IS NULL then 'Sem Backup Full' else idb.difference end as days_difference
					idb.type_backup,
					idb.last_backup_start_date,
					idb.last_backup_finish_date,
					idb.[difference]
		from		dbo.tb_database_backup db with (nolock)
		left join	dbo.tb_info_database_backup idb with (nolock)
			on		db.database_name = idb.database_name
		where		1 = 1
			and		db.fl_bkp_full = 1
			and		(idb.type_backup = 'D' or idb.type_backup is null)
			and		(idb.[difference] > db.threshold_bkp_full or idb.[difference] is null)
		union
		--backup Diff
		select		'DIFF' as 'Informações Backup', 
					db.database_name, 
					case 
						when db.recovery_model = 1 then 'FULL' 
						when db.recovery_model = 2 then 'BULK LOGGED' 
						when db.recovery_model = 3 then 'SIMPLE' 
					end as recovery_model,
					db.fl_bkp_full,
					db.fl_bkp_diff,
					db.fl_bkp_log,
					db.threshold_bkp_full,
					db.threshold_bkp_diff,
					db.threshold_bkp_log,
					idb.type_backup,
					idb.last_backup_start_date,
					idb.last_backup_finish_date,
					idb.[difference]
		from		dbo.tb_database_backup db with (nolock)
		left join	dbo.tb_info_database_backup idb with (nolock)
			on		db.database_name = idb.database_name
		where		1 = 1
			and		db.fl_bkp_diff = 1
			and		(idb.type_backup = 'I' or idb.type_backup is null)
			and		(idb.[difference] > db.threshold_bkp_diff or idb.[difference] is null)
		union
		--backup Log
		select		'LOG' as 'Informações Backup', 
					db.database_name, 
					case 
						when db.recovery_model = 1 then 'FULL' 
						when db.recovery_model = 2 then 'BULK LOGGED' 
						when db.recovery_model = 3 then 'SIMPLE' 
					end as recovery_model,
					db.fl_bkp_full,
					db.fl_bkp_diff,
					db.fl_bkp_log,
					db.threshold_bkp_full,
					db.threshold_bkp_diff,
					db.threshold_bkp_log,
					idb.type_backup,
					idb.last_backup_start_date,
					idb.last_backup_finish_date,
					idb.[difference]
		from		dbo.tb_database_backup db with (nolock)
		left join	dbo.tb_info_database_backup idb with (nolock)
			on		db.database_name = idb.database_name
		where		1 = 1
			and		db.fl_bkp_log = 1
			and		db.recovery_model in (1,2)
			and		(idb.type_backup = 'L' or idb.type_backup is null)
			and		(idb.[difference] > db.threshold_bkp_diff or idb.[difference] is null);

		--drop table dbo.tb_database_backup;
		--drop table dbo.tb_info_database_backup;
	end try
	begin catch
		--if OBJECT_ID('tempdb.dbo.tb_database_backup','U') is not null
		--	drop table dbo.tb_database_backup;
		--if OBJECT_ID('tempdb.dbo.tb_database_backup','U') is not null
		--	drop table dbo.tb_info_database_backup;

		select	ERROR_NUMBER() as ErrorNumber,
				ERROR_SEVERITY() as ErrorSeverity,
				ERROR_STATE() as ErrorState,
				ERROR_PROCEDURE() as ErrorProcedure,
				ERROR_LINE() as ErrorLine,
				ERROR_MESSAGE() as ErrorMessage;
	end catch
end

/*
		select * from dbo.tb_database_backup with (nolock)
		select * from dbo.tb_info_database_backup with (nolock)

		select		* 
		from		dbo.tb_database_backup db with (nolock)
		left join	dbo.tb_info_database_backup idb with (nolock)
			on		db.database_name = idb.database_name

		update tb_database_backup set fl_bkp_full = 0 where id = 5

		select		'FULL' as 'Informações Backup', 
					db.database_name, 
					case 
						when db.recovery_model = 1 then 'FULL' 
						when db.recovery_model = 2 then 'BULK LOGGED' 
						when db.recovery_model = 3 then 'SIMPLE' 
					end as recovery_model,
					db.fl_bkp_full,
					db.fl_bkp_diff,
					db.fl_bkp_log,
					db.threshold_bkp_full,
					db.threshold_bkp_diff,
					db.threshold_bkp_log,
					idb.type_backup,
					idb.last_backup_start_date,
					idb.last_backup_finish_date,
					idb.[difference]
		from		dbo.tb_database_backup db with (nolock)
		left join	dbo.tb_info_database_backup idb with (nolock)
			on		db.database_name = idb.database_name
		where		1 = 1
			and		db.fl_bkp_full = 1
			and		(idb.type_backup = 'D' or idb.type_backup is null)
			and		(idb.[difference] >= db.threshold_bkp_full or idb.[difference] is null)

		update tb_database_backup set fl_bkp_log = 0 where id = 5

		select		'LOG' as 'Informações Backup', 
					db.database_name, 
					case 
						when db.recovery_model = 1 then 'FULL' 
						when db.recovery_model = 2 then 'BULK LOGGED' 
						when db.recovery_model = 3 then 'SIMPLE' 
					end as recovery_model,
					db.fl_bkp_full,
					db.fl_bkp_diff,
					db.fl_bkp_log,
					db.threshold_bkp_full,
					db.threshold_bkp_diff,
					db.threshold_bkp_log,
					idb.type_backup,
					idb.last_backup_start_date,
					idb.last_backup_finish_date,
					idb.[difference]
		from		dbo.tb_database_backup db with (nolock)
		left join	dbo.tb_info_database_backup idb with (nolock)
			on		db.database_name = idb.database_name
		where		1 = 1
			and		db.fl_bkp_log = 1
			and		db.recovery_model in (1,2)
			and		(idb.type_backup = 'L' or idb.type_backup is null)
			and		(idb.[difference] > db.threshold_bkp_diff or idb.[difference] is null);
*/