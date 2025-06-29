--###############################################################################################################################################################
--LISTAGEM USUARIOS ORFAOS
--###############################################################################################################################################################

declare @database_name	varchar(128)= '';
declare @user_name varchar(128) = '';
declare @countLoop tinyint = 0;
declare @countUsers tinyint = 0;
declare @TSQL varchar(1000) = '';

if OBJECT_ID('tempdb..#tb_permissions') is not null
	drop table #tb_permissions;

create table #tb_permissions
(
	id				int identity(1,1) primary key	,
	database_name	varchar(128)					,
	user_name		varchar(128)					
);


exec master..sp_MSforeachdb 'use [?]
insert		#tb_permissions (database_name, user_name)
select		db_name() as database_name,
			dp.name AS UserName
from		sys.database_principals dp with(nolock)
left join	sys.sql_logins sl with(nolock) 
	on		dp.[sid] = sl.[sid]
inner join	sys.server_principals sp with(nolock) 
	on		dp.[name] COLLATE SQL_Latin1_General_CP1_CI_AI = sp.[name] COLLATE SQL_Latin1_General_CP1_CI_AI
where		1=1
    and		dp.principal_id > 4
    and		sl.[sid] IS NULL
    and		dp.is_fixed_role = 0
    and		sp.is_fixed_role = 0
    and		dp.name NOT LIKE ''##MS_%''
    and		dp.[type_desc] = ''SQL_USER''
    and		sp.[type_desc] = ''SQL_LOGIN''
    and		dp.name NOT IN (''sa'')
order by	dp.name'

select * from #tb_permissions

--###############################################################################################################################################################
--CORRECAO
--###############################################################################################################################################################
declare @database_name	varchar(128)= '';
declare @user_name varchar(128) = '';
declare @countLoop tinyint = 0;
declare @countUsers tinyint = 0;
declare @TSQL nvarchar(1000) = '';

if OBJECT_ID('tempdb..#tb_permissions') is not null
	drop table #tb_permissions;

create table #tb_permissions
(
	id				int identity(1,1) primary key	,
	database_name	varchar(128)					,
	user_name		varchar(128)					
);


exec master..sp_MSforeachdb 'use [?]
insert		#tb_permissions (database_name, user_name)
select		db_name() as database_name,
			dp.name AS UserName
from		sys.database_principals dp with(nolock)
left join	sys.sql_logins sl with(nolock) 
	on		dp.[sid] = sl.[sid]
inner join	sys.server_principals sp with(nolock) 
	on		dp.[name] COLLATE SQL_Latin1_General_CP1_CI_AI = sp.[name] COLLATE SQL_Latin1_General_CP1_CI_AI
where		1=1
    and		dp.principal_id > 4
    and		sl.[sid] IS NULL
    and		dp.is_fixed_role = 0
    and		sp.is_fixed_role = 0
    and		dp.name NOT LIKE ''##MS_%''
    and		dp.[type_desc] = ''SQL_USER''
    and		sp.[type_desc] = ''SQL_LOGIN''
    and		dp.name NOT IN (''sa'')
order by	dp.name'

select @countUsers = count(*) from #tb_permissions;

if @countUsers > 0
begin
	select @countLoop = 1;
	while @countLoop <= @countUsers
	begin
		select @database_name = database_name, @user_name = user_name from #tb_permissions where id = @countLoop;
		select @TSQL = N'';
		select @TSQL = N'use [' + @database_name + ']';
		select @TSQL += char(13) + char(10);
		select @TSQL += N'EXEC sp_change_users_login ''Auto_Fix'', ''' + @user_name + '''';
		--select @TSQL
		exec sp_executesql @TSQL;
		select @countLoop = @countLoop + 1;
	end
end

go
--select * from #tb_permissions



--use BDTPFCO
--EXEC sp_change_users_login 'Report'
--EXEC sp_change_users_login 'Auto_Fix', 'fircosoft_prd'

--EXEC sp_change_users_login 'update_one' , 'usr_negativacao' , 'usr_negativacao'