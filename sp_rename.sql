use dbTestes

drop table tb_teste_col
drop table tb_teste_col2
drop table tb_teste_colNovo
drop table tb_teste_col_bkp

create table tb_teste_col
(id int identity not null primary key, col2 varchar(10) null, col3 datetime default(getdate()))

insert tb_teste_col (col2) values ('teste')
insert tb_teste_col (col2) values ('teste2')
insert tb_teste_col (col2) values ('teste3')

create nonclustered index ix on tb_teste_col(col3)

sp_helpindex tb_teste_col
/*
index_name						index_description									index_keys
ix								nonclustered located on PRIMARY						col3
PK__tb_teste__3213E83F5E55CAA0	clustered, unique, primary key located on PRIMARY	id
*/

sp_helpconstraint tb_teste_col
/*
constraint_type			constraint_name					delete_action	update_action	status_enabled	status_for_replication	constraint_keys
DEFAULT on column col3	DF__tb_teste_c__col3__603E1312	(n/a)			(n/a)			(n/a)			(n/a)					(getdate())
PRIMARY KEY (clustered)	PK__tb_teste__3213E83F5E55CAA0	(n/a)			(n/a)			(n/a)			(n/a)					id
*/

create table tb_teste_colNovo
(id int identity not null primary key, col2 varchar(10) null, colNova int null, col3 datetime default(getdate()))

insert tb_teste_colNovo (col2,colNova,col3) values ('teste',1,'2015-07-30 12:29:07.543')
insert tb_teste_colNovo (col2,colNova,col3) values ('teste2',2,'2015-07-30 12:29:07.560')
insert tb_teste_colNovo (col2,colNova,col3) values ('teste3',3,'2015-07-30 12:29:07.577')

select * from tb_teste_col
select * from tb_teste_colNovo
select * from tb_teste_col_bkp

select * from tb_teste_col
select * from tb_teste_col2

sp_helpindex tb_teste_col
sp_helpconstraint tb_teste_col

sp_helpindex tb_teste_col2
sp_helpconstraint tb_teste_col2

select * into tb_teste_col_bkp from tb_teste_col

sp_helpindex tb_teste_col_bkp
sp_helpconstraint tb_teste_col_bkp

sp_rename @objname = 'tb_teste_col', @newname = 'tb_teste_col2', @objtype = 'OBJECT'
sp_rename @objname = 'tb_teste_colNovo', @newname = 'tb_teste_col', @objtype = 'OBJECT'
