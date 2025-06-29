USE TSQL2012;
GO
SET NOCOUNT ON;

-- dbo.T1 (numeric sequence with unique values, interval: 1)
IF OBJECT_ID('dbo.T1', 'U') IS NOT NULL DROP TABLE dbo.T1;
CREATE TABLE dbo.T1
(
col1 INT NOT NULL
CONSTRAINT PK_T1 PRIMARY KEY
);
GO

INSERT INTO dbo.T1(col1)
VALUES(2),(3),(7),(8),(9),(11),(15),(16),(17),(28);
GO

-- dbo.T2 (temporal sequence with unique values, interval: 1 day)
IF OBJECT_ID('dbo.T2', 'U') IS NOT NULL DROP TABLE dbo.T2;
CREATE TABLE dbo.T2
(
col1 DATE NOT NULL
CONSTRAINT PK_T2 PRIMARY KEY
);
GO

INSERT INTO dbo.T2(col1) VALUES
('20120202'),
('20120203'),
('20120207'),
('20120208'),
('20120209'),
('20120211'),
('20120215'),
('20120216'),
('20120217'),
('20120228');
GO

-------------------------------------------------------------------------------------------------------------------------
--gaps
-------------------------------------------------------------------------------------------------------------------------
USE TSQL2012;
GO

--sequencial
; with cte_nxtvl as
(
	select col1, lead(col1) over(order by col1) nxtvl from t1
)
select	col1 + 1, nxtvl -1
from	cte_nxtvl
where	1 =1 
and		nxtvl - col1 > 1

--data
; with cte_nxtvl as
(
	select col1, lead(col1) over(order by col1) nxtvl from t2
)
select	dateadd(day,1,col1), dateadd(day,-1,nxtvl)
from	cte_nxtvl
where	1 =1 
and		DATEDIFF(day,col1,nxtvl) > 1

-------------------------------------------------------------------------------------------------------------------------
--island
-------------------------------------------------------------------------------------------------------------------------
USE TSQL2012;
GO

--sequencial
;with cte_grp as
(
	select col1, col1 - DENSE_RANK() over(order by col1) grp from t1
)
select		min(col1), max(col1)
from		cte_grp
group by	grp	

--data
;with cte_grp as
(
	select col1, dateadd(day,-1 *  DENSE_RANK() over(order by col1), col1) grp from t2
)
select		min(col1), max(col1)
from		cte_grp
group by	 grp

-------------------------------------------------------------------------------------------------------------------------
--matriz sequencial
-------------------------------------------------------------------------------------------------------------------------
USE TSQL2012;
GO

--valores colunas até 10
declare @linhas int = 10
declare @colunas int = 5

;with cte_sequencia as
(
	select ROW_NUMBER() over(order by (select null)) n from sys.all_objects
)
select	
			max(case when n % @colunas = 1 then n end) as col1
			,max(case when n % @colunas = 2 then n end) as col2
			,max(case when n % @colunas = 3 then n end) as col3
			,max(case when n % @colunas = 4 then n end) as col4
			,max(case when n % @colunas = 0 then n end) as col5
from		cte_sequencia
where		1 = 1
and			n <= @linhas * @colunas
group by	(n -1) / @colunas

--dinâmico ???

-------------------------------------------------------------------------------------------------------------------------
--missing values
-------------------------------------------------------------------------------------------------------------------------
USE TSQL2012;
GO

--drop table datas

create table datas
(
dt datetime not null
)
go
insert datas (dt) values ('20080101'),('20080102'),('20080105'),('20080109'),('20080110'),('20080111'),('20080112'),('20080115'),('20080117'),('20080119'),('20080120'),('20080122'),('20080129')
go
select * from datas

select	*
		,dateadd(dd, n - 1, '20080101') as dt 
from	TSQL2012..Nums n
where	1 = 1
and		n.n <= datediff(dd,'20080101',getdate()) + 1

select	*
		,dateadd(dd, n - 1, '20080101') as dt 
from	TSQL2012..Nums n
where	1 = 1
and		n.n <= datediff(dd,'20080101','20080131') + 1

--vendas
--select		d.dt as dt_com_vendas
--from		TSQL2012..Nums n
--inner join	datas d
--on			d.dt = dateadd(dd, n - 1, '20080101')
--where		1 = 1
--and			n.n <= datediff(dd,'20080101','20080131') + 1

--sem vendas
select		dateadd(dd, n - 1, '20080101'), case when d.dt is null then 'Sem venda' else 'Com venda' end as Data
from		TSQL2012..Nums n
left join	TSQL2012..datas d
on			d.dt = dateadd(dd, n - 1, '20080101')
where		1 = 1
and			n.n <= datediff(dd,'20080101','20080131') + 1

-------------------------------------------------------------------------------------------------------------------------
--merge tables without join
-------------------------------------------------------------------------------------------------------------------------
USE TSQL2012;
GO

select * from dbo.T1

--drop table tt

create table tt (cd_tipo smallint, numero varchar(20))
go
insert tt (cd_tipo, numero) values (1,'875554')
insert tt (cd_tipo, numero) values (2,'00000000014394')
go
select * from tt

--select * 
--from dbo.T1 t
--left join tt t2
--on 1 = 1
--and t2.cd_tipo = 2

select * 
from dbo.T1 t
cross join tt t2
where cd_tipo = 2

-------------------------------------------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------------------------------------------

select  c.CompanyName, oc.OrderDate 
from  CustomersBig c
cross apply (
    select  top 1 o.OrderDate
    from  OrdersBig o
    where  1 = 1
    and   o.CustomerID = c.CustomerID
	and		o.orderdate between '20190101' and '20200101'
    order by o.OrderDate desc 
   ) oc
where 1 = 1



