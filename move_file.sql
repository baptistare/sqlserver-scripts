use master
go

--identificar local atual arquivos
select name, physical_name, * from sys.master_files where database_id = DB_ID('qqg');
/*
qqg_Data	D:\Dados\qqg.mdf
qqg_Log	L:\Log\qqg_log.ldf
*/

--alter database qqg set single_user with rollback immediate;
alter database qqg set multi_user with rollback immediate;

--alterar caminho arquivos
alter database qqg modify file (name='qqg_Data',filename='D:\Dados\qqg.mdf');
alter database qqg modify file (name='qqg_Log',filename='L:\Log\qqg_log.ldf');

--colocar a base de dados offline para movimentação dos arquivos
alter database qqg set offline;

--movimentar os arquivos físicos para o novo local

--colocar a base de dados online para acesso multi_user
alter database qqg set online;
alter database qqg set multi_user;

--confirmação da movimentação dos arquivos
select name, physical_name, * from sys.master_files where database_id = DB_ID('qqg');
select state_desc, user_access_desc, is_read_only,* from sys.databases where database_id = DB_ID('qqg');

