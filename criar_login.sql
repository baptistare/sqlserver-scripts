select sysadmin,* from sys.syslogins where name = 'itm623'

CREATE LOGIN itm623 WITH PASSWORD=N'Tivoli123', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

use master
use msdb
use model
use tempdb

CREATE USER itm623 FOR LOGIN itm623
exec sp_addrolemember db_datareader, itm623

select dp.name as database_role, dp2.name as database_user
from sys.database_role_members drm
  join sys.database_principals dp on (drm.role_principal_id = dp.principal_id)
  join sys.database_principals dp2 on (drm.member_principal_id = dp2.principal_id)
where dp2.name in ('itm623')
order by dp.name

-----

use master
go
CREATE LOGIN [FNACBR\aaraujo] FROM WINDOWS 
DROP LOGIN [FNACBR\aaraujo]

CREATE LOGIN [FNACBR\rbaptista] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO


--CREATE LOGIN usr_reinaldo WITH PASSWORD=N'usr_reinaldo', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF

--CREATE LOGIN usr_reinaldo WITH PASSWORD=N'ReinaldoTestes2' MUST_CHANGE, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=ON, CHECK_POLICY=ON

use ECRReload

CREATE USER [FNACBR\aaraujo] FOR LOGIN [FNACBR\aaraujo];
DROP USER [FNACBR\aaraujo]

exec sp_addrolemember db_owner, [FNACBR\aaraujo]
exec sp_addrolemember db_datareader, [FNACBR\aaraujo]

exec sp_droprolemember db_datareader, [FNACBR\aaraujo]

--consultar roles
sp_helpsrvrole
sp_helprole
/*
public
db_owner
db_accessadmin
db_securityadmin
db_ddladmin
db_backupoperator
db_datareader
db_datawriter
db_denydatareader
db_denydatawriter
*/

--adicionar / remover usuário a role sysadmin

sp_addsrvrolemember @loginame= 'userchalldef' , @rolename = 'sysadmin'
sp_dropsrvrolemember @loginame= 'userchalldef' , @rolename = 'sysadmin'


--ROLES

use master
go

CREATE ROLE Desenvolvimento AUTHORIZATION dbo
DROP ROLE Desenvolvimento 

CREATE ROLE Systax AUTHORIZATION dbo
DROP ROLE Systax 

ALTER ROLE Systax ADD MEMBER afim;
ALTER ROLE Systax DROP MEMBER afim;

sp_helprole @rolename = 'Desenvolvimento'
sp_helprole @rolename = 'Systax'

exec sp_addrolemember db_owner, Systax

exec sp_addrolemember db_datareader, Systax
exec sp_addrolemember db_datawriter, Systax

--verificar permissão usário na base
select dp.name as database_role, dp2.name as database_user
from sys.database_role_members drm
  join sys.database_principals dp on (drm.role_principal_id = dp.principal_id)
  join sys.database_principals dp2 on (drm.member_principal_id = dp2.principal_id)
where dp2.name in ('FNACBR\aaraujo')
order by dp.name

--listar usuário e grants base
select		db_name() as database_name, dp2.name as database_user, dp.name as database_role--,dp2.type
from		sys.database_role_members drm
join		sys.database_principals dp 
	on		drm.role_principal_id = dp.principal_id
right join	sys.database_principals dp2 
	on		drm.member_principal_id = dp2.principal_id
where		dp2.type in ('S','U')
order by	dp2.name

--listar permissões de usuário específico
--sp_helprotect @username = 'MYABCM_CLOUD_USER'

select		SCHEMA_NAME(o.schema_id) as owner, 
			o.name as object,
			user_name(p.grantee_principal_id) as grantee,
			p.state_desc as protect_type,
			p.permission_name as action
from		sys.database_permissions p
inner join	sys.all_objects o
	on		p.major_id = o.object_id 
where		p.grantee_principal_id = database_principal_id('MYABCM_CLOUD_USER') 
order by	object

select dp.name as database_role, dp2.name as database_user
from sys.database_role_members drm
  join sys.database_principals dp on (drm.role_principal_id = dp.principal_id)
  join sys.database_principals dp2 on (drm.member_principal_id = dp2.principal_id)
where dp.name = 'db_datareader'
order by dp.name

select dp.name as database_role, dp2.name as database_user, *
from		sys.sysusers u with(nolock) 
join		sys.database_role_members drm with(nolock) 
	on		drm.member_principal_id = u.uid
join		sys.database_principals dp with(nolock)  
	on		drm.role_principal_id = dp.principal_id
join		sys.database_principals dp2 
	on		drm.member_principal_id = dp2.principal_id
where		dp.name = 'db_datareader'

select dp.name as database_role, dp2.name as database_user, *
from		sys.sysusers u with(nolock) 
join		sys.database_role_members drm with(nolock) 
	on		drm.member_principal_id = u.uid
join		sys.database_principals dp with(nolock)  
	on		drm.role_principal_id = dp.principal_id
join		sys.database_principals dp2 
	on		drm.member_principal_id = dp2.principal_id
where		u.islogin = 1 
and			u.hasdbaccess = 1 
and			u.issqluser = 1--22
and			dp.name = 'db_datareader'

xp_logininfo 
xp_logininfo 'FNACBR\Desenvolvimento-Challenger-GG', 'members';
xp_logininfo 'FNACBR\Desenvolvimento-DBProd-1-GG', 'members';
xp_logininfo 'FNACBR\Desenvolvimento-DBProd-2-GG', 'members';
xp_logininfo 'FNACBR\Desenvolvimento-DBDesenv-GG', 'members';
xp_logininfo 'FNACBR\SQL Admins', 'members';

--identificar grupos de domínio cadastrados no SQL
select	p.name,*
from	sys.syslogins l
join	sys.server_principals p
	on	l.sid = p.sid
where	p.type = 'G'


--criar usuario em todas as bases
sp_msforeachdb 'use [?]
if db_name() not in (''master'',''msdb'',''model'',''tempdb'',''distribution'',''dbAuditoria'')
begin
	CREATE USER usr_cultura FOR LOGIN usr_cultura;
	exec sp_addrolemember db_datareader, usr_cultura;
	exec sp_addrolemember db_datawriter, usr_cultura;
	exec sp_addrolemember db_ddladmin, usr_cultura;
	grant execute to usr_cultura;
end
else
begin
	select ''bases sistema''
end
'

sp_msforeachdb 'use [?]
select db_name(),dp.name as database_role, dp2.name as database_user
from sys.database_role_members drm
  join sys.database_principals dp on (drm.role_principal_id = dp.principal_id)
  join sys.database_principals dp2 on (drm.member_principal_id = dp2.principal_id)
where dp2.name in (''usr_cultura'')
'
