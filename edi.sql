exec master..sp_WhoIsActive;

select percent_complete, * from sys.dm_exec_requests where session_id = 101

select log_reuse_wait_desc, * from sys.databases where database_id = db_id()

xp_fixeddrives

dbcc sqlperf(logspace)

use BDTPEDI
go
checkpoint
dbcc shrinkfile (2,286720)

; with bkp as
(
	select	database_name, type, user_name, backup_start_date, backup_finish_date, rank() over (partition by database_name, type order by backup_start_date desc) as rnk
	from	msdb..backupset 
	where	database_name = 'BDTPEDI'
) 
select	database_name, type, user_name, backup_start_date, backup_finish_date, datediff(ss,bkp.backup_start_date, bkp.backup_finish_date) as diff_in_Sec, datediff(mi,bkp.backup_start_date, bkp.backup_finish_date) as diff_in_Min
from	bkp
where	rnk < 4--quantidade de backups por tipo a serem exibidos