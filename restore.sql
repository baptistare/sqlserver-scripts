RESTORE VERIFYONLY FROM DISK = 'D:\AdventureWorks.bak';
GO

https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-verifyonly-transact-sql?view=sql-server-ver16

RESTORE FILELISTONLY FROM AdventureWorksBackups WITH FILE=2;  
GO  

RESTORE FILELISTONLY FROM DISK = '\\NOTE-REI\Reinaldo\HD\SQLServer\SampleDatabases\WideWorldImporters_Legacy.bak';
GO

https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-filelistonly-transact-sql?view=sql-server-ver16

RESTORE HEADERONLY FROM DISK = N'C:\AdventureWorks-FullBackup.bak';  
GO  

https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-headeronly-transact-sql?view=sql-server-ver16

---

RESTORE DATABASE WideWorldImporters_Legacy
  FROM DISK = N'<location of BAK file here>' WITH REPLACE, RECOVERY, 
  MOVE N'WWI_Legacy_Data' TO N'<location of data files here>\WWI_Legacy.mdf',
  MOVE N'WWI_Legacy_Log'  TO N'<location of log files here>\WWI_Legacy.ldf';