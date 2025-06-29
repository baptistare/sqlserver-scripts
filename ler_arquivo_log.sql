--lista os arquivos de logs
exec sp_enumerrorlogs

--le conteúdo do arquivo de log (default 0 - parâmetros arquivos de log)
exec sp_readerrorlog

--parâmetros a serem usados com sp_readerrorlog
/*
Parameter Name		Usage
@ArchiveID			Extension of the file which we would like to read.
					0 = ERRORLOG/SQLAgent.out
					1 = ERRORLOG.1/SQLAgent.1  and so on
@LogType			1 for SQL Server ERRORLOG (ERRORLOG.*)
					2 for SQL Agent Logs (SQLAgent.*)
@FilterText1		First Text filter on data
@FilterText2		Another Text filter on data. Output would be after applying both filters, if specified
@FirstEntry			Start Date Filter on Date time in the log
@LastEntry			END Date Filter on Date time in the log
@SortOrder			'asc' or 'desc' for sorting the data based on time in log.
*/

xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "Server process ID is"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "System Manufacturer"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "Authentication mode"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "The service account is"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "Server is listening on"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "Starting up database"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "Recovery completed"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "Recovery of database"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "Login failed"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "Logging SQL Server messages in"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "STACK DUMP"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "availability group"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "SQL Server has encountered 1 occurrence(s) of cachestore flush for the"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "memory has been paged out"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "I/O requests taking"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "FlushCache"
xp_readerrorlog @ArchiveID = 0, @LogType = 1, @FilterText1 = "SSPI handshake"
