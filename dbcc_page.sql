dbcc traceon (3604)

--dbName|dbID, filenum, pagenum, printopt (0|1|2|3)
dbcc page (18,1,2,3) --with tableresults
dbcc page (18,1,165,3) with tableresults

--dbName|dbID, tableName, indexId (-1|-2)
dbcc ind(18, 'cielo_errorlog', 0)
go
dbcc ind(18, 'cielo_errorlog', -1)


