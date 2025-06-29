use sgf_fisc
go

--verificar utilização arquivos
dbcc showfilestats
/*
Fileid	FileGroup	TotalExtents	UsedExtents	Name	FileName
1		1			563735			259068				SGF_FISC_Data	S:\Dados\SGF_FISC_Data.mdf
3		1			65536			28085				SGF_FISC_Data2	R:\Data\SGF_FISC_Data2.ndf
*/

use sgf_fisc
go

--zerar o arquivo a ser removido
dbcc SHRINKFILE ('SGF_FISC_Data2', EMPTYFILE);

--remover arquivo
alter database sgf_fisc remove file SGF_FISC_Data2

