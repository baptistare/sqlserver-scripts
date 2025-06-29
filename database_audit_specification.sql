
USE [master]
GO

/****** Object:  Audit [testeAudit]    Script Date: 27/10/2022 00:02:22 ******/
CREATE SERVER AUDIT [testeAudit]
TO FILE 
(	FILEPATH = N'\\note-rei\\reinaldo\hd\sqlserver\lab\audit\'
	,MAXSIZE = 50 MB
	,MAX_ROLLOVER_FILES = 100
	,RESERVE_DISK_SPACE = OFF
) WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE, AUDIT_GUID = '2190d27c-6fdc-445b-a793-283b4020b8cc')
ALTER SERVER AUDIT [testeAudit] WITH (STATE = ON)
GO

USE [master]
GO
ALTER SERVER AUDIT [testeAudit] WITH (STATE = ON)
GO

USE [master]
GO
ALTER SERVER AUDIT [testeAudit] WITH (STATE = OFF)
GO

USE [master]
GO
/****** Object:  Audit [testeAudit]    Script Date: 27/10/2022 01:10:48 ******/
DROP SERVER AUDIT [testeAudit]
GO

USE [Northwind]
GO

CREATE DATABASE AUDIT SPECIFICATION [testeDatabaseAuditSpecification]
FOR SERVER AUDIT [testeAudit]
ADD (SELECT ON SCHEMA::[dbo] BY [public]),
ADD (INSERT ON SCHEMA::[dbo] BY [public]),
ADD (UPDATE ON SCHEMA::[dbo] BY [public]),
ADD (DELETE ON SCHEMA::[dbo] BY [public]),
ADD (EXECUTE ON SCHEMA::[dbo] BY [public])
GO

ALTER DATABASE AUDIT SPECIFICATION [testeDatabaseAuditSpecification]
ADD (EXECUTE ON SCHEMA::[dbo] BY [public])
GO

USE [Northwind]
GO
ALTER DATABASE AUDIT SPECIFICATION [testeDatabaseAuditSpecification] WITH (STATE = ON)
GO

USE [Northwind]
GO
ALTER DATABASE AUDIT SPECIFICATION [testeDatabaseAuditSpecification] WITH (STATE = OFF)
GO

USE [Northwind]
GO
DROP DATABASE AUDIT SPECIFICATION [testeDatabaseAuditSpecification]
GO




-- Retorna as informações de um arquivo específico
select object_name,transaction_id,audit_file_offset,* 
from sys.fn_get_audit_file('\\note-rei\reinaldo\hd\sqlserver\lab\audit\testeAudit_2190D27C-6FDC-445B-A793-283B4020B8CC_0_133113176397620000.sqlaudit',default,default)  
 where 1 = 1
and object_id > 0

select transaction_id, count(1) qty, count(distinct transaction_id) qty2
from sys.fn_get_audit_file('\\note-rei\reinaldo\hd\sqlserver\lab\audit\testeAudit_2190D27C-6FDC-445B-A793-283B4020B8CC_0_133113176397620000.sqlaudit',default,default)  
where 1 = 1
and object_id > 0
group by  transaction_id

select database_name, schema_name, object_name, server_principal_name, action_id, transaction_id, count(1) qty, count(transaction_id) qty2
from sys.fn_get_audit_file('\\note-rei\reinaldo\hd\sqlserver\lab\audit\testeAudit_2190D27C-6FDC-445B-A793-283B4020B8CC_0_133113176397620000.sqlaudit',default,default)  
where 1 = 1
and object_id > 0
group by database_name, schema_name, object_name, server_principal_name, action_id, transaction_id


select server_principal_name, database_name, schema_name, object_name, count(distinct audit_file_offset) qty
from sys.fn_get_audit_file('\\note-rei\reinaldo\hd\sqlserver\lab\audit\testeAudit_2190D27C-6FDC-445B-A793-283B4020B8CC_0_133113176397620000.sqlaudit',default,default)  
where 1 = 1
and object_id > 0
group by database_name, schema_name, object_name, server_principal_name

select database_name, schema_name, object_name, server_principal_name, action_id, count(1) qty, count(action_id) qty2
from sys.fn_get_audit_file('\\note-rei\reinaldo\hd\sqlserver\lab\audit\testeAudit_2190D27C-6FDC-445B-A793-283B4020B8CC_0_133113176397620000.sqlaudit',default,default)  
where 1 = 1
and object_id > 0
group by database_name, schema_name, object_name, server_principal_name, action_id


-- Retorna as informações de todos os arquivos
SELECT event_time,action_id,server_principal_name,statement,* 
FROM Sys.fn_get_audit_file('\\note-rei\reinaldo\hd\sqlserver\lab\audit\*.sqlaudit',default,default)
where 1 = 1
and	class_type = 'U'

select * from sys.server_audits
select * from sys.database_audit_specifications

select * from sys.tables

select top 1 * from Test
update Test set LastName = 'Neves Amorim' where id = 20060
delete Test  where id = 20060

select top 3 * from OrdersBig
select top 3 * from CustomersBig
select top 3 * from Order_DetailsBig

execute usp_teste_2

create procedure usp_teste_2
as
select	c.CustomerID, c.CompanyName
from	OrdersBig o
join	CustomersBig c
	on	o.CustomerID = c.CustomerID

create view vww_teste
as
select	top 10 c.CustomerID, c.CompanyName
from	OrdersBig o
join	CustomersBig c
	on	o.CustomerID = c.CustomerID

select * from vww_teste


-------------------------------------------------

USE [master]
GO

/****** Object:  Audit [testeAudit]    Script Date: 27/10/2022 00:02:22 ******/
CREATE SERVER AUDIT [testeTruncateDelete]
TO FILE 
(	FILEPATH = N'\\note-rei\\reinaldo\hd\sqlserver\lab\audit\'
	,MAXSIZE = 50 MB
	,MAX_ROLLOVER_FILES = 100
	,RESERVE_DISK_SPACE = OFF
) WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE)
ALTER SERVER AUDIT [testeAudit] WITH (STATE = ON)
GO

USE [Northwind]
GO

CREATE DATABASE AUDIT SPECIFICATION [truncate_delete_DatabaseAuditSpecification]
FOR SERVER AUDIT [testeTruncateDelete]
ADD (DELETE ON DATABASE::[Northwind] BY [public])
GO

-------------------------------------------------

select * from sys.tables 

select top 100 * into tb_delete_truncate from CustomersBig

select * from tb_delete_truncate

delete tb_delete_truncate where CustomerID = 1
truncate table tb_delete_truncate

select object_name,transaction_id,audit_file_offset,* 
from sys.fn_get_audit_file('\\note-rei\reinaldo\hd\sqlserver\lab\audit\testeTruncateDelete_7485D49C-C661-48CD-8DAA-070F73466D23_0_133113707746320000.sqlaudit',default,default)  
where 1 = 1
and object_id > 0


EXEC master..xp_dirtree '\\note-rei\reinaldo\hd\sqlserver\lab\audit\', 10, 1

EXEC master..xp_dirtree '\\note-rei\reinaldo\hd\sqlserver\lab\'
EXEC master..xp_dirtree '\\note-rei\reinaldo\hd\sqlserver\lab\', 10, 1