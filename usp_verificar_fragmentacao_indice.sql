use tempdb
go

alter procedure usp_verificar_fragmentacao_indice
@databaseID tinyint = NULL,
@objectID int = NULL,
@indexID int = NULL
as
begin
	declare @command nvarchar(1000);
	
	if @databaseID is null
	begin
		select 'Favor informar o DatabaseID.';
		return
	end

	select @command = N'';
	select @command = @command + N' use [' + db_name(@databaseID) + ']';
	select @command = @command + N' select		object_name(a.object_id),b.name,a.avg_fragmentation_in_percent,a.*';
	select @command = @command + N' from		sys.dm_db_index_physical_stats(db_id(),' + isnull(cast(@objectID as varchar(15)),'null') + ',' + isnull(cast(@indexID as varchar(15)),'null') + ',null,null) a';
	select @command = @command + N' join		sys.indexes b';
	select @command = @command + N' 	on		a.object_id = b.object_id';
	select @command = @command + N' 	and		a.index_id = b.index_id';
	select @command = @command + N' 	and		a.page_count > 20';
	select @command = @command + N' 	and		a.index_id > 0';
	select @command = @command + N' order by	object_name(b.object_id), b.index_id;';
	--select @command;
	execute sp_executesql @command;

end

/*
exec usp_verificar_fragmentacao_indice @databaseID = NULL, @objectID = NULL, @indexID = NULL;
exec usp_verificar_fragmentacao_indice @databaseID = 7, @objectID = 1780089785, @indexID = NULL;
exec usp_verificar_fragmentacao_indice @databaseID = 7, @objectID = NULL, @indexID = NULL;
*/