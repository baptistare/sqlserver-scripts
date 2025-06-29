use tempdb
go

if OBJECT_ID('#tbServers','U') is not null
	drop table #tbServers;
	go

if OBJECT_ID('#tbDatabases','U') is not null
	drop table #tbDatabases;
	go

if OBJECT_ID('#tbObjects','U') is not null
	drop table #tbObjects;
	go


set nocount on;

create table #tbServers (id int identity not null primary key, name varchar(30) not null);

create table #tbDatabases (idServer int not null, id int identity not null primary key, name varchar(30));

--create table #tbObjects (databaseName varchar(30), name varchar(255), object_id int);
create table #tbObjects (databaseName varchar(30), schema_name varchar(255), name varchar(255), object_id int);

declare @server varchar(30);
declare @idServer int;
declare @database varchar(30);
declare @sql nvarchar(1000);

insert #tbServers
select data_source from sys.servers where server_id = 0;

declare c_servers cursor fast_forward for select name, id from #tbServers;

open c_servers;
fetch next from c_servers into @server, @idServer;

set @sql = '';

while @@FETCH_STATUS = 0
begin
	
	select @sql = 'select ' + cast(@idServer as varchar(2)) + ', name from [' + @server + '].master.sys.databases where state = 0 and database_id not in (db_id(''master''),db_id(''msdb''),db_id(''tempdb''),db_id(''model''),db_id(''distribution''),db_id(''dbAuditoria''))';

	insert into #tbDatabases
	exec sp_executesql @sql;

	fetch next from c_servers into @server, @idServer;
end 

close c_servers;
deallocate c_servers;

declare c_databases cursor fast_forward for select name from #tbDatabases where idServer = 1;

open c_databases;
fetch next from c_databases into @database;

set @sql = ''

while @@FETCH_STATUS = 0 
begin
	select @sql = 'use [' + @database + ']' + char(13) + char(10)
	select @sql = @sql + 'insert tempdb..#tbObjects ' + char(13) + char(10)

	--alterar nome do objeto a ser localizado aqui
	--select @sql = @sql + 'select '''+ @database + ''',	name, object_id from sys.objects where OBJECT_DEFINITION(object_id) like ''%ds_serie in %15%'''
	select @sql = @sql + 'select '''+ @database + ''', s.name, o.name, o.object_id from sys.objects o join sys.schemas s on o.schema_id = s.schema_id  where OBJECT_DEFINITION(o.object_id) like ''%ds_serie in %15%'''

	--select @sql = @sql + 'select '''+ @database + ''', name, object_id from sys.objects where OBJECT_DEFINITION(object_id) like ''%MREC_ALOCITEM_DEVOLUCAO%'''

	--select @sql = @sql + 'select '''+ @database + ''', name, object_id from sys.objects where OBJECT_DEFINITION(object_id) like ''%insert MREC_ALOCITEM_DEVOLUCAO%'''
	--select @sql = @sql + 'select '''+ @database + ''', name, object_id from sys.objects where OBJECT_DEFINITION(object_id) like ''%insert into MREC_ALOCITEM_DEVOLUCAO%'''

	--select @sql = @sql + 'select '''+ @database + ''', name, object_id from sys.objects where OBJECT_DEFINITION(object_id) like ''%insert dbo.MREC_ALOCITEM_DEVOLUCAO%'''--
	--select @sql = @sql + 'select '''+ @database + ''', name, object_id from sys.objects where OBJECT_DEFINITION(object_id) like ''%insert into dbo.MREC_ALOCITEM_DEVOLUCAO%'''

	--select @sql = @sql + 'select '''+ @database + ''', name, object_id from sys.objects where OBJECT_DEFINITION(object_id) like ''%insert sgf_rec.dbo.MREC_ALOCITEM_DEVOLUCAO%'''
	--select @sql = @sql + 'select '''+ @database + ''', name, object_id from sys.objects where OBJECT_DEFINITION(object_id) like ''%insert into sgf_rec.dbo.MREC_ALOCITEM_DEVOLUCAO%'''

	exec sp_executesql @sql;

	fetch next from c_databases into @database;
end 

close c_databases;
deallocate c_databases;

select databasename, schema_name, name from #tbObjects;
--select * from #tbObjects

/*
- criar procedure 
- parametrizar o valor a ser pesquisado
- englobar servidores
- rever estrutura tabela
- testar

select * from #tbServers

select * from #tbDatabases

select * from #tbObjects


*/
