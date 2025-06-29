
--verificação remote admin connections
exec sp_configure 'show advanced options', 1
RECONFIGURE WITH OVERRIDE

exec sp_configure 'remote admin connections', 1
RECONFIGURE WITH OVERRIDE

--procedure criptografada
use DBA
go
create procedure usp_teste_encrypted
WITH ENCRYPTION
as
begin
	select 'proc criptografada'
	select getdate();
	select		top 1000 *
	from		sys.all_columns c
	cross join	sys.all_columns c2
	cross join	sys.all_columns c3
	select 'proc criptografada - texto 2'
	select getdate();
	select		top 10000 *
	from		sys.all_columns c
	cross join	sys.all_columns c2
	cross join	sys.all_columns c3
end

--abrir conexão DAC
--ADMIN:NOTE-REI\SQL2016

SET NOCOUNT ON
GO

--usar contexto do banco de dados onde a procedure está criptografada
use dba

DECLARE @encrypted NVARCHAR(MAX)
SET @encrypted = ( 
 SELECT imageval 
 FROM sys.sysobjvalues
 WHERE OBJECT_NAME(objid) = 'usp_teste_encrypted' )
DECLARE @encryptedLength INT
SET @encryptedLength = DATALENGTH(@encrypted) / 2

DECLARE @procedureHeader NVARCHAR(MAX)
SET @procedureHeader = N'ALTER PROCEDURE dbo.usp_teste_encrypted WITH ENCRYPTION AS '
SET @procedureHeader = @procedureHeader + REPLICATE(N'-',(@encryptedLength - LEN(@procedureHeader)))
EXEC sp_executesql @procedureHeader
DECLARE @blankEncrypted NVARCHAR(MAX)
SET @blankEncrypted = ( 
 SELECT imageval 
 FROM sys.sysobjvalues
 WHERE OBJECT_NAME(objid) = 'usp_teste_encrypted' )

SET @procedureHeader = N'CREATE PROCEDURE dbo.usp_teste_encrypted WITH ENCRYPTION AS '
SET @procedureHeader = @procedureHeader + REPLICATE(N'-',(@encryptedLength - LEN(@procedureHeader)))

DECLARE @cnt SMALLINT
DECLARE @decryptedChar NCHAR(1)
DECLARE @decryptedMessage NVARCHAR(MAX)
SET @decryptedMessage = ''
SET @cnt = 1
WHILE @cnt <> @encryptedLength
BEGIN
  SET @decryptedChar = 
      NCHAR(
        UNICODE(SUBSTRING(
           @encrypted, @cnt, 1)) ^
        UNICODE(SUBSTRING(
           @procedureHeader, @cnt, 1)) ^
        UNICODE(SUBSTRING(
           @blankEncrypted, @cnt, 1))
     )
  SET @decryptedMessage = @decryptedMessage + @decryptedChar
 SET @cnt = @cnt + 1
END
SELECT @decryptedMessage

----------------------------------------------------------------------------------------------------------------

--example procedure criptografada
CREATE PROCEDURE dbo.TestDecryption WITH ENCRYPTION AS
BEGIN
 PRINT 'This text is going to be decrypted'
END 
GO

DECLARE @encrypted NVARCHAR(MAX)
SET @encrypted = ( 
 SELECT imageval 
 FROM sys.sysobjvalues
 WHERE OBJECT_NAME(objid) = 'TestDecryption' )
DECLARE @encryptedLength INT
SET @encryptedLength = DATALENGTH(@encrypted) / 2

DECLARE @procedureHeader NVARCHAR(MAX)
SET @procedureHeader = N'ALTER PROCEDURE dbo.TestDecryption WITH ENCRYPTION AS '
SET @procedureHeader = @procedureHeader + REPLICATE(N'-',(@encryptedLength - LEN(@procedureHeader)))
EXEC sp_executesql @procedureHeader
DECLARE @blankEncrypted NVARCHAR(MAX)
SET @blankEncrypted = ( 
 SELECT imageval 
 FROM sys.sysobjvalues
 WHERE OBJECT_NAME(objid) = 'TestDecryption' )

SET @procedureHeader = N'CREATE PROCEDURE dbo.TestDecryption WITH ENCRYPTION AS '
SET @procedureHeader = @procedureHeader + REPLICATE(N'-',(@encryptedLength - LEN(@procedureHeader)))

DECLARE @cnt SMALLINT
DECLARE @decryptedChar NCHAR(1)
DECLARE @decryptedMessage NVARCHAR(MAX)
SET @decryptedMessage = ''
SET @cnt = 1
WHILE @cnt <> @encryptedLength
BEGIN
  SET @decryptedChar = 
      NCHAR(
        UNICODE(SUBSTRING(
           @encrypted, @cnt, 1)) ^
        UNICODE(SUBSTRING(
           @procedureHeader, @cnt, 1)) ^
        UNICODE(SUBSTRING(
           @blankEncrypted, @cnt, 1))
     )
  SET @decryptedMessage = @decryptedMessage + @decryptedChar
 SET @cnt = @cnt + 1
END
SELECT @decryptedMessage

--------------------------
--hash example

drop FUNCTION dbo.getHash

CREATE FUNCTION dbo.getHash ( @inputString VARCHAR(20) )
RETURNS VARBINARY(8000) --WITH ENCRYPTION 
AS BEGIN
    DECLARE @salt VARCHAR(32)    
	DECLARE @outputHash VARBINARY(8000)
	SET @salt = '9CE08BE9AB824EEF8ABDF4EBCC8ADB19'
	SET @outputHash = HASHBYTES('SHA2_256', (@inputString + @salt))
RETURN @outputHash
END
GO

select master.dbo.fn_varbintohexstr(dbo.getHash('teste criptografia'))