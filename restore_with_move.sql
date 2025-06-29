use master
go

RESTORE DATABASE SGF_Cadastro_teste
   FROM DISK = 'F:\BackupSQL\bkpFull_SGF_Cadastro_20150506.bak'
   WITH RECOVERY,
   MOVE 'PrimaryFileName' TO 'E:\Dados\SGF_Cadastro_teste_Data.mdf', 
   MOVE 'PrimaryLogFileName' TO 'E:\Logs\SGF_Cadastro_teste_Log.ldf',
   MOVE 'sysft_ECReloadCatalog' TO 'E:\Logs\SGF_Cadastro_teste_2.ECReloadCatalog'
