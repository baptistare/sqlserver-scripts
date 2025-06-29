SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

if object_id('tempdb..#temp1') is not null
	drop table #temp1;--##sqlskillsstats1

if object_id('tempdb..#temp2') is not null
	drop table #temp2;--##sqlskillsstats2

select  database_id, file_id, num_of_reads, io_stall_read_ms, num_of_writes, io_stall_write_ms, io_stall, num_of_bytes_read, num_of_bytes_written, file_handle
into	#temp1
from	sys.dm_io_virtual_file_stats (null, null)
--where	database_id = 25
go

waitfor delay '00:00:30';
go
 
select  database_id, file_id, num_of_reads, io_stall_read_ms, num_of_writes, io_stall_write_ms, io_stall, num_of_bytes_read, num_of_bytes_written, file_handle
into	#temp2
from	sys.dm_io_virtual_file_stats (null, null)
--where	database_id = 25
go
 
with diff_latencies as
(
	-- files that weren't in the first snapshot
	select
		        t2.database_id, t2.file_id, t2.num_of_reads, t2.io_stall_read_ms, t2.num_of_writes, t2.io_stall_write_ms, t2.io_stall, t2.num_of_bytes_read, t2.num_of_bytes_written
    from		#temp2 as t2
    left join	#temp1 as t1
        on		t2.file_handle = t1.file_handle
    where		t1.file_handle is null
	union
	-- diff of latencies in both snapshots
	select
				t2.database_id, t2.file_id, t2.num_of_reads - t1.num_of_reads as num_of_reads, t2.io_stall_read_ms - t1.io_stall_read_ms as io_stall_read_ms, t2.num_of_writes - t1.num_of_writes as num_of_writes, t2.io_stall_write_ms - t1.io_stall_write_ms as io_stall_write_ms, t2.io_stall - t1.io_stall as io_stall, t2.num_of_bytes_read - t1.num_of_bytes_read as num_of_bytes_read, t2.num_of_bytes_written - t1.num_of_bytes_written as num_of_bytes_written
    from		#temp2 as t2
    left join	#temp1 as t1
        on		t2.file_handle = t1.file_handle
    where		t1.file_handle is not null
)
select
			db_name (vfs.database_id) as db,
			left (mf.physical_name, 2) as drive,
			mf.type_desc,
			num_of_reads as reads,
			num_of_writes as writes,
			readlatency_ms = case when num_of_reads = 0 then 0 else (io_stall_read_ms / num_of_reads) end,
			writelatency_ms = case when num_of_writes = 0 then 0 else (io_stall_write_ms / num_of_writes) end,
			--latency = case when (num_of_reads = 0 and num_of_writes = 0) then 0 else (io_stall / (num_of_reads + num_of_writes)) end,
			avgbperread = case when num_of_reads = 0 then 0 else (num_of_bytes_read / num_of_reads) end, 
			avgbperwrite = case when num_of_writes = 0 then 0 else (num_of_bytes_written / num_of_writes) end,
			--avgbpertransfer = case when (num_of_reads = 0 and num_of_writes = 0) then 0 else ((num_of_bytes_read + num_of_bytes_written) / (num_of_reads + num_of_writes)) end,
			mf.physical_name
from		diff_latencies as vfs
inner join	sys.master_files as mf
    on		vfs.database_id = mf.database_id
    and		vfs.file_id = mf.file_id
order by	readlatency_ms desc
--order by	writelatency_ms desc;
go
 
if object_id('tempdb..#temp1') is not null
	drop table #temp1;--##sqlskillsstats1

if object_id('tempdb..#temp2') is not null
	drop table #temp2;--##sqlskillsstats2



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Calculates average stalls per read, per write, and per total input/output for each database file. 
select		db_name(database_id) as database_name, file_id, io_stall_read_ms ,
			num_of_reads ,
			cast(io_stall_read_ms / ( 1.0 + num_of_reads ) as numeric(10, 1)) as avg_read_stall_ms ,
			io_stall_write_ms ,
			num_of_writes ,
			cast(io_stall_write_ms / ( 1.0 + num_of_writes ) as numeric(10, 1)) as avg_write_stall_ms ,
			io_stall_read_ms + io_stall_write_ms as io_stalls ,
			num_of_reads + num_of_writes as total_io ,
			cast(( io_stall_read_ms + io_stall_write_ms ) / ( 1.0 + num_of_reads + num_of_writes) as numeric(10,1)) as avg_io_stall_ms
from		sys.dm_io_virtual_file_stats(null, null)
--order by	avg_io_stall_ms desc;
--order by	avg_read_stall_ms desc;
order by	avg_write_stall_ms desc;

-- Look at pending I/O requests by file
select		db_name(mf.database_id) as database_name, mf.physical_name, r.io_pending, r.io_pending_ms_ticks, r.io_type, fs.num_of_reads, fs.num_of_writes
from		sys.dm_io_pending_io_requests as r
inner join	sys.dm_io_virtual_file_stats(null, null) as fs
	on		r.io_handle = fs.file_handle
inner join	sys.master_files as mf 
	on		fs.database_id = mf.database_id
	and		fs.file_id = mf.file_id
order by	r.io_pending, r.io_pending_ms_ticks desc;

select		db_name(mf.database_id) as database_name, r.io_type, count(r.io_pending) io_pending_count, sum(r.io_pending_ms_ticks) io_pending_ms_sum
from		sys.dm_io_pending_io_requests as r
inner join	sys.dm_io_virtual_file_stats(null, null) as fs
	on		r.io_handle = fs.file_handle
inner join	sys.master_files as mf 
	on		fs.database_id = mf.database_id
	and		fs.file_id = mf.file_id
group by	db_name(mf.database_id) , r.io_type


select cast(dt_start as date) dt, DATEPART(hh,dt_start) hh, DB, sum(Reads) sum_reads, sum(writes) sum_writes, sum([ReadLatency(ms)]) sum_ReadLatency, sum([WriteLatency(ms)]) sum_WriteLatency
from dm_io_virtual_file_stats_hist with (nolock)
where 1 = 1
and dt_start between '20230207' and '20230208'
group by cast(dt_start as date), DATEPART(hh,dt_start), DB
order by 1,2 desc