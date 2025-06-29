use master
go

select		b.database_name, MAX(b.backup_start_date) as last_backup_start, MAX(b.backup_finish_date) as last_backup_finish
from		sys.databases d
inner join	msdb..backupset b
	on		DB_NAME(d.database_id) = b.database_name
where		1 = 1
	and		d.recovery_model_desc <> 'SIMPLE'
	and		d.database_id <> 3
	and		b.[user_name] = 'NT AUTHORITY\SYSTEM'
	and		b.type in ('D','I')
	and		b.backup_start_date < '2018-07-29 00:00:00.000'
group by	b.database_name
order by	b.database_name

select		
			db_name(d.database_id) as databaseName, a.type, a.user_name, a.backup_start_date, a.backup_finish_date
from		sys.databases d
cross apply	(
				select		top 3 b2.database_name, b2.type, b2.user_name, b2.backup_start_date, b2.backup_finish_date	
				from		msdb..backupset as b2
				where		1 = 1
					and		b2.database_name = db_name(d.database_id)
					and		b2.user_name = 'NT AUTHORITY\SYSTEM'
					and		b2.type in ('D')
				order by	b2.backup_start_date desc	
			) as a
order by 1,4 desc

