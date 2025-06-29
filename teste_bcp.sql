use MUTANT
select * from sys.tables
select top 1 * from TB_CALLBACK

create table tb_teste_bcp_1
(
	id		int identity primary key,
	col1	varchar(32),
	col2	varchar(64),
	col3	datetime,
	col4	int,
	col5	int
)

create table tb_teste_bcp_2
(
	col1	varchar(32),
	col2	varchar(64),
	col3	datetime,
	col4	int,
	col5	int
)

select * from tb_teste_bcp_1
select * from tb_teste_bcp_2--31

truncate table tb_teste_bcp_2


select getdate()


--bcp "select * from sgf_cadr.dbo.MCAD_PRODUTO where dt_cadastro >= '20151215' and cd_Area = 4 and cd_categoria = 7 and cd_produto in ('0000071196824', '0000071197128','0000071197203','0000071197395')" queryout "C:\temp\BCP\MCAD_PRODUTO.dat" -S MSCOMERCIAL -T -N


bcp MUTANT..TB_TESTE_BCP_1 in C:\TIVIT_SQL_SERVER\Testes\carga_bcp_1.txt -S VVCEWHSHDDB01 -T -N

bcp MUTANT..TB_TESTE_BCP_2 in C:\TIVIT_SQL_SERVER\Testes\carga_bcp_1.txt -S VVCEWHSHDDB01 -T -c -r\n -t;
bcp MUTANT..TB_TESTE_BCP_2 in C:\TIVIT_SQL_SERVER\Testes\carga_bcp_2.txt -S VVCEWHSHDDB01 -T -c -r\n -t;
bcp MUTANT..TB_TESTE_BCP_2 in C:\TIVIT_SQL_SERVER\Testes\teste_csv.csv -S VVCEWHSHDDB01 -T -c -r\n -t;
bcp MUTANT..TB_TESTE_BCP_2 in C:\TIVIT_SQL_SERVER\Testes\teste_csv2.csv -S VVCEWHSHDDB01 -T -c -r\n -t;

bcp MUTANT..TB_TESTE_BCP_2 in C:\TIVIT_SQL_SERVER\Testes\teste_csv3.csv -S VVCEWHSHDDB01 -T -c -r\n -t;

bcp MUTANT.dbo.tb_teste_bcp_2 format nul -f C:\TIVIT_SQL_SERVER\Testes\arquivoFormato.fmt -S VVCEWHSHDDB01 -T -c

