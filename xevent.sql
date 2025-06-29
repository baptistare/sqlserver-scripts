use master
go

select * from sys.dm_xe_session_events
select * from sys.dm_xe_sessions
select * from sys.dm_xe_session_targets
select * from sys.dm_xe_session_event_actions
select * from sys.dm_xe_packages


create event session session_waits on server	
	add event sqlos.wait_info
		(where sqlserver.session_id = 1 and duration > 0)
   ,add event sqlos.wait_info_external
		(where sqlserver.session_id = 1 and duration > 0)
	add target package0.asynchronous_file_target
		(set filename=N'c:\temp\wait_stats.xel', metadatafile=N'c:\temp\wait_stats.xem');
go

alter event session session_waits on server state = start;
go

--drop event session session_waits on server;

--alter event session session_waits on server state = stop;

;with cte_xevent as 
(
	select	cast(event_data as xml) as xevent
	from	sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null)
),
cte_xevent2 as
(
	select	xevent.value(N'(/event/data[@name="wait_type"]/text)[1]','sysname') as wait_type,
			xevent.value(N'(/event/data[@name="duration"]/value)[1]','int') as duration,
			xevent.value(N'(/event/data[@name="signal_duration"]/value)[1]','int') as signal_duration
	from	cte_xevent
)
select		wait_type,
			count(*) as count_waits,
			sum(duration) as total_duration,
			sum(signal_duration) as total_signal_duration,
			max(duration) as max_duration,
			max(signal_duration) as max_signal_duration
			--cast(avg(duration) as numeric (5,2)) as avg_duration,
from		cte_xevent2
group by	wait_type
order by	sum(duration) desc;

/*
select * from sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null);

;with cte_xevent as 
(
	select	cast(event_data as xml) as xevent
	from	sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null)
)
select	* 
from	cte_xevent;

;with cte_xevent as 
(
	select	cast(event_data as xml) as xevent
	from	sys.fn_xe_file_target_read_file ('c:\temp\wait_stats*.xel', 'c:\temp\wait_stats*.xem',null,null)
)
select	xevent.value(N'(/event/data[@name="wait_type"]/text)[1]','sysname') as wait_type,
		xevent.value(N'(/event/data[@name="duration"]/text)[1]','int') as duration,
		xevent.value(N'(/event/data[@name="signal_duration"]/text)[1]','int') as signal_duration
from	cte_xevent;
*/