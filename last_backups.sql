use master
go

; with bkp as
(
	select	database_name, type, user_name, backup_start_date, backup_finish_date, rank() over (partition by database_name, type order by backup_start_date desc) as rnk
	from	msdb..backupset 
	where	database_name = 'BDTPEDI'
) 
select	database_name, type, user_name, backup_start_date, backup_finish_date, datediff(ss,bkp.backup_start_date, bkp.backup_finish_date) as diff_in_Sec, datediff(mi,bkp.backup_start_date, bkp.backup_finish_date) as diff_in_Min
from	bkp
where	rnk < 4--quantidade de backups por tipo a serem exibidos

--

select		b.database_name, MAX(b.backup_start_date) as last_backup_start, MAX(b.backup_finish_date) as last_backup_finish
from		sys.databases d
inner join	msdb..backupset b
	on		DB_NAME(d.database_id) = b.database_name
where		1 = 1
	and		d.recovery_model_desc <> 'SIMPLE'
	and		d.database_id <> 3
	and		b.[user_name] <> 'visanet\t1702fbn'
	and		b.type in ('L')
	--and		b.backup_start_date < '2018-07-29 00:00:00.000'
group by	b.database_name
order by	b.database_name

select		
			db_name(d.database_id) as databaseName, a.type, a.user_name, a.backup_start_date, a.backup_finish_date, datediff(ss,a.backup_start_date, a.backup_finish_date) as diff_in_Sec, datediff(mi,a.backup_start_date, a.backup_finish_date) as diff_in_Min
from		sys.databases d
cross apply	(
				select		top 3 b2.database_name, b2.type, b2.user_name, b2.backup_start_date, b2.backup_finish_date	
				from		msdb..backupset as b2
				where		1 = 1
					and		b2.database_name = db_name(d.database_id)
					--and		b2.user_name = 'NT AUTHORITY\SYSTEM'
					and		b2.type in ('L')
				order by	b2.backup_start_date desc	
			) as a
order by 1,4 desc

select		b2.database_name, b2.type, max(b2.backup_start_date) backup_start_date, max(b2.backup_finish_date) backup_finish_date
from		msdb..backupset as b2
group by	b2.database_name, b2.type
order by	b2.database_name 

