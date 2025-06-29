--VVCEWPITSMDB01

--tabela com histórico do agente da replicação distribution
select * from distribution..MSdistribution_history

--identifica registros com erro 
--select * from distribution..MSdistribution_history where error_id > 0 and runstatus = 6
select count(*) as qtde_erros from distribution..MSdistribution_history where error_id > 0 and runstatus = 6

--agrumento de erros por data
select cast(start_time as date) as data_erro, count(*) as qtd from distribution..MSdistribution_history where error_id > 0 and runstatus = 6 group by cast(start_time as date)

--agrumento por tipo de erro
select		count(*) as qtd,left(comments,70) as comments
from		distribution..MSdistribution_history 
where		error_id > 0 and runstatus = 6
group by	left(comments,70)

/*
verificação dos erros por tipo
select * from MSdistribution_history where error_id > 0 and runstatus = 6
and left(comments,70) = 'The row was not found at the Subscriber when applying the replicated D'

select * from MSdistribution_history where error_id > 0 and runstatus = 6
and left(comments,70) = 'The row was not found at the Subscriber when applying the replicated U'

select * from MSdistribution_history where error_id > 0 and runstatus = 6
and left(comments,70) = 'Violation of PRIMARY KEY constraint ''XPKnot_log''. Cannot insert duplic'
*/

/*
use distribution

select min(start_time) from MSdistribution_history
select * from MSdistribution_history where start_time >= cast(getdate() as date) and error_id > 0 and runstatus = 6--12
select * from MSdistribution_history where start_time between '2018-12-13' and '2018-12-14'and error_id > 0 and runstatus = 6--130
select * from MSdistribution_history where error_id > 0
select * from MSdistribution_history where error_id > 0 and runstatus = 6

select		count(*),left(comments,70)
from		MSdistribution_history 
where		error_id > 0 and runstatus = 6
group by	left(comments,70)

select * from MSdistribution_history where error_id > 0 and runstatus = 6
and left(comments,70) = 'The row was not found at the Subscriber when applying the replicated U'

select * from MSdistribution_history where error_id > 0 and runstatus = 6
and left(comments,70) = 'Violation of PRIMARY KEY constraint ''XPKnot_log''. Cannot insert duplic'


The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22091868

select * from mdb.[dbo].[att_evt] where id = 22091868
select * from mdb.[dbo].[att_evt] where id = 22089832
select * from mdb.[dbo].[att_evt] where id = 22089834
select * from mdb.[dbo].[att_evt] where id = 22089836
select * from mdb.[dbo].[att_evt] where id = 22089838
select * from mdb.[dbo].[att_evt] where id = 22088455

The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22091868
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22091868
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22091868
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22091868
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22091868
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22089832
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22089834
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22089836
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22089838
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22088455

Violation of PRIMARY KEY constraint 'XPKnot_log'. Cannot insert duplicate key in object 'dbo.not_log'. The duplicate key value is (72285086).
Violation of PRIMARY KEY constraint 'XPKnot_log'. Cannot insert duplicate key in object 'dbo.not_log'. The duplicate key value is (72285087).
Violation of PRIMARY KEY constraint 'XPKnot_log'. Cannot insert duplicate key in object 'dbo.not_log'. The duplicate key value is (72285088).

select * from mdb.dbo.not_log where id = 72285086
select * from mdb.dbo.not_log where id = 72285087
select * from mdb.dbo.not_log where id = 72285088	

The row was not found at the Subscriber when applying the replicated DELETE command for Table '[dbo].[anima]' with Primary Key(s): [id] = 25338949
The row was not found at the Subscriber when applying the replicated UPDATE command for Table '[dbo].[att_evt]' with Primary Key(s): [id] = 22091868
Violation of PRIMARY KEY constraint 'XPKnot_log'. Cannot insert duplicate key in object 'dbo.not_log'. The duplicate key value is (72285086).
*/