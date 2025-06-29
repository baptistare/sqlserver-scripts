-----------------------------------------------------------------------------------------------------------------------
--problemas mais comuns em uma query
-----------------------------------------------------------------------------------------------------------------------

parse -> bind -> optimization

parse - verifica se é um código tsql válido, gerar o parse tree, que contem as operações a serem executadas
bind - tabelas e colunas existem, carrega os metadados, expande as views, gera query processor tree
optimization - submete a query processor tree ao processo de otimização para geração ou busca de um plano válido

otimizador é baseado em custo
usa heurística para a otimização do plano, estimativas
fase optimization possui mais 3 fases (search 0, 1 e 2)
pesquisa de planos em cache, utiliza o query_hash
objetivo, encontrar o melhor plano no menor tempo possível
geração de planos são custosos e podem causar high CPU utilization
reutilização de planos (stored procedure e sp_executesql)
dbcc traceon (3604) - redirecionar o output para o ssms
TF 8606 - gerar o logical tree
TF 8607 - gerar o physical tree
select - properties - reason for early termination
TF 8780 - da mais tempo ao QO para geração de planos
querytraceon - hint para utilizar TF em uma query
plan guide não permite utilizar hints além de parameterization simple ou forced

conversão explícita
conversão implícita
eliminando cursores
subconsulta no select
variável local
operador OR
variável tabela x tabela temporária

convert 112 - 20221025 - formato universal de datas

--------------------------------------------------------------------------------------------------------------------------------------------

where convert(varchar(10),orderdate,112) = '20280105' --conversão explícita
substituir por
where orderdate >= '20280105' and orderdate < '20280106'

--------------------------------------------------------------------------------------------------------------------------------------------

conversão implícita - normalmente relacionado aos data types diferentes, o que está na tabela e como vem na query
data type precedence transact sql - microsoft - achar o link

--------------------------------------------------------------------------------------------------------------------------------------------

exemplo cursor, pegar os 2 últimos pedidos para cada cliente
substituir a utilização do cursor por uma das opções abaixo
usar crossapply com top 2 order by desc
ou cte, subconsulta, windows function, cte recursiva

select 	product, 
		(select top 1 sales from tab1 b where b.key = a.key order by orderdate desc),
		(select top 1 order from tab1 b where b.key = a.key order by orderdate desc)
from 	dim_product 

substituir por

select 	product
from 	dim_product
outter apply (
				select top 1 sales, order
				from tab1 b
				where b.key = a.key
				order by orderdate desc
			) op

--------------------------------------------------------------------------------------------------------------------------------------------

variável local não usa histograma e usará informações de densidade do objeto estatístico
select - properties - parameter list - parameter compiled value
para resolver ou usar o hint recompile, ou proc, ou sp_executesql

--------------------------------------------------------------------------------------------------------------------------------------------

where productkey = @productkey or @productkey is null
ou
where productkey = isnull(@productkey,productkey)

substituir por sql dinamico para montar a query, usar if ou case para atribuir o valor correto e usar sp_executesql
option (recompile) tb resolve, mas sempre considerar o custo das recompilações
alternativa tb usar union separando as queries e predicados

--------------------------------------------------------------------------------------------------------------------------------------------

quando realizando join com variável de tabela, antes do sql 2019 o QO estima apenas 1 linha, com isso pode escolher um operador join ruim
a partir do sql 2019 é um pouco melhor mais ainda ruim
nesse usar tabela temporária para que o QO estime melhor e não erre no operador do join








marcio rego junior 










