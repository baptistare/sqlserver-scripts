--server roles
select		sp.name as [user] , sp2.name as server_role
from		sys.server_role_members srm with (nolock)
inner join	sys.server_principals sp with (nolock) 
	on		srm.member_principal_id= sp.principal_id
inner join	sys.server_principals sp2 with (nolock) 
	on		srm.role_principal_id= sp2.principal_id
where		1=1
	and		sp2.name = 'sysadmin'
	--and		sp.name = 'ServiceDesk'

--server permissions
select		sp.class_desc tipo_permissao,
			sp.state_desc tipo_operacao,
			sp.permission_name permissao,
			sl.name login,
			spr.type_desc tipo_login
from		sys.server_permissions sp with (nolock)
inner join	sys.server_principals spr with (nolock) 
	on		sp.grantee_principal_id=spr.principal_id
left join	sys.syslogins sl with (nolock) 
	on		spr.sid = sl.sid
order by	sl.name

--database roles and members
select		db_name() as database_name, dp2.name as database_user, dp.name as database_role--,dp2.type
from		sys.database_role_members drm
inner join	sys.database_principals dp 
	on		drm.role_principal_id = dp.principal_id
right join	sys.database_principals dp2 
	on		drm.member_principal_id = dp2.principal_id
where		1=1
	and		dp2.type in ('S','U')
	--and		dp2.name = 'mdbadmin'
	and		dp.name = 'regadmin'
order by	dp2.name

-- user and logins
select		sl.name as login_user, su.name as [user] 
from		sys.database_principals dp with (nolock)
inner join	sys.sysusers su with (nolock) 
	on		dp.principal_id= su.uid
left join	sys.syslogins sl with (nolock) 
	on		su.sid = sl.sid
where		1=1
	and		dp.type_desc!='DATABASE_ROLE';

--user database permission
--sp_helprotect @username = 'ServiceDesk'
select		dp.class_desc as permission_type,
			dp.permission_name as permission,
			dp.state_desc as operation,
			su.name as permission_user,
			sl.name as permission_login,
			o.name as object
from		sys.database_permissions dp with (nolock)
inner join	sys.sysusers su with (nolock) 
	on		dp.grantee_principal_id=su.uid
left join	sys.syslogins sl with (nolock) 
	on		su.sid = sl.sid
left join	sys.objects o with (nolock) 
	on		dp.major_id= o.object_id
where		1=1
	and		dp.major_id>=0
	and		su.name = 'ServiceDesk'
order by	su.name

