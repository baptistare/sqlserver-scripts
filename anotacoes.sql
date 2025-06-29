https://www.sqlshack.com/force-query-execution-plan-using-sql-server-2016-query-store/

https://www.sqlshack.com/sql-server-estimated-vs-actual-execution-plans/

threat starvation
non schdule yeld

a partir do sql2019 da pra pegar o plano real, como fazer isso


--redirecionar output 
dbcc traceon (3604)

--logical tree
option (recompile, querytraceon 8606)

--physical tree
option (recompile, querytraceon 8607)

--mais tempo pro QO - quando o plano da timeout, uma tentativa/alternativa
option (recompile, querytraceon 8780)

--plan guide
quando a query é adhoc para utilizar um plan guide, não é possível utilizar o traceflag querytraceon
para uma query adhoc só é possível habilitar parametrization simple ou forced
quando sp_executesql, procedure, temos mais opções a utilizar no plan guide

sp_showindex

variaveis locais usarão as informaçoes de densidade da estatística
opção OPTION (RECOMPILE), avaliar quantidade de execuções
opção sp_executesql 

predicado com OR ISNULL
causará index scan
opção OPTION (RECOMPILE), avaliar quantidade de execuções
opção query dinâmica e sp_executesql

conversão implícita
reescrever a query, predicate

cursor
reescrever a uery, CROSS APPLY, SUB SELECT


