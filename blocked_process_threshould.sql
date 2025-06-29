sp_configure 'blocked process threshold (s)'
go
sp_configure 'blocked process threshold (s)', 5
go
reconfigure
go

SELECT * FROM :: fn_trace_getinfo(default)

SELECT * FROM ::fn_trace_gettable('G:\Trace\blocked_process_threshould.trc', DEFAULT)

SELECT cast(textdata as xml) text_data_xml, spid, endtime, duration / 1000 /1000 as duration, *
FROM ::fn_trace_gettable('G:\Trace\blocked_process_threshould.trc', DEFAULT)


--parar o trace id 2
EXEC sp_trace_setstatus 2, 0

--iniciar o trace id 2
EXEC sp_trace_setstatus 2, 1

--para e remove trace id 2
EXEC sp_trace_setstatus 2, 2

--##################################################################################################################################


-- Create a Queue
declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 5 

--alterar caminho trace
exec @rc = sp_trace_create @TraceID output, 0, N'G:\Trace\blocked_process_threshould', @maxfilesize, NULL 
if (@rc != 0) goto error

-- Client side File and Table cannot be scripted

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 137, 3, @on
exec sp_trace_setevent @TraceID, 137, 15, @on
exec sp_trace_setevent @TraceID, 137, 51, @on
exec sp_trace_setevent @TraceID, 137, 4, @on
exec sp_trace_setevent @TraceID, 137, 12, @on
exec sp_trace_setevent @TraceID, 137, 24, @on
exec sp_trace_setevent @TraceID, 137, 32, @on
exec sp_trace_setevent @TraceID, 137, 60, @on
exec sp_trace_setevent @TraceID, 137, 64, @on
exec sp_trace_setevent @TraceID, 137, 1, @on
exec sp_trace_setevent @TraceID, 137, 13, @on
exec sp_trace_setevent @TraceID, 137, 41, @on
exec sp_trace_setevent @TraceID, 137, 14, @on
exec sp_trace_setevent @TraceID, 137, 22, @on
exec sp_trace_setevent @TraceID, 137, 26, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

--23 - FILTRO DO BANCO DE DADOS A MONITORAR
set @intfilter = 23
exec sp_trace_setfilter @TraceID, 3, 0, 0, @intfilter

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID
goto finish

error: 
select ErrorCode=@rc

finish: 
go
