use BDTPSDY
go

select count(*) from TBSDYW_TELEFONEMA with (nolock)
select count(*) from TBSDYW_CLIENTE with (nolock) 
select count(*) from TBSDYW_CONTATO with (nolock)
select count(*) from TBSDYW_EC with (nolock)
select count(*) from TBSDYW_ENDERECO with (nolock)
select count(*) from TBSDYW_MCC with (nolock)

use BDTPSDY
go

select * from TBSDYW_MCC with (nolock)

 
select top 100 * from TBSDYW_TELEFONEMA with (nolock) order by DH_ATUALIZACAO DESC
select top 100 * from TBSDYW_CLIENTE with (nolock) order by DH_ATUALIZACAO DESC
select top 100 * from TBSDYW_CONTATO with (nolock) order by DH_ATUALIZACAO DESC
select top 100 * from TBSDYW_EC with (nolock) order by DH_ATUALIZACAO DESC
select top 100 * from TBSDYW_ENDERECO with (nolock) order by DH_ATUALIZACAO DESC
select top 100 * from TBSDYW_MCC with (nolock) order by DH_ATUALIZACAO DESC

--

use master
go
CREATE LOGIN CPCUSR WITH PASSWORD=N'C!elo_2018#' MUST_CHANGE, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=ON, CHECK_POLICY=ON


use x

CREATE USER CPCUSR FOR LOGIN CPCUSR

exec sp_addrolemember db_datareader, CPCUSR
exec sp_addrolemember db_datawriter, CPCUSR
exec sp_addrolemember db_ddladmin, CPCUSR

exec master.sys.sp_MSforeachdb '[?]
select db_name(),* from sys.schemas where name = ''CPC'''