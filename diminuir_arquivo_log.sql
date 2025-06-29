dbcc sqlperf (logspace)

select recovery_model_desc,* from sys.databases where database_id = db_id('SGF_MIS')
select name,* from sys.master_files where type = 1 and database_id = db_id('SGF_MIS')

use SGF_MIS

alter database SGF_MIS set recovery simple with no_wait

dbcc shrinkfile ('SGF_MIS_Log',2048)

alter database SGF_MIS set recovery full
