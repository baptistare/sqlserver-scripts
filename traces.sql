--obtem informações de traces em execução
SELECT * FROM :: fn_trace_getinfo(default)

--ler o arquivo de trace  
SELECT * FROM ::fn_trace_gettable('C:\temp\Trace\blocked_process_threshold.trc', DEFAULT)--663

SELECT cast(textdata as xml),* FROM ::fn_trace_gettable('C:\temp\Trace\blocked_process_threshold.trc', DEFAULT)--663

--parar o trace id 2
EXEC sp_trace_setstatus 2, 0

--iniciar o trace id 2
EXEC sp_trace_setstatus 2, 1

--para e remove trace id 2
EXEC sp_trace_setstatus 2, 2

