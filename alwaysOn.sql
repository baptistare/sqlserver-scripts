set nocount on;
if object_id('tempdb..##ag') is not null
	drop table ##ag;

if (select serverproperty ('IsHadrEnabled')) = 1
begin
	if (
			select	top 1 replicaStates.role_desc 
			from	sys.dm_hadr_availability_replica_states as replicaStates
			join	sys.availability_replicas as availReplica
				on	availReplica.replica_id = replicaStates.replica_id
			where	availReplica.replica_server_name = @@servername
		) = 'PRIMARY'
	begin

		create table ##ag
		(
			id								int identity not null,
			node_name						varchar(64) not null,
			role_desc						varchar(64) not null,
			[database_name]					varchar(64) not null,
			availability_mode_desc			varchar(64) not null,
			synchronization_state_desc		varchar(64) not null,
			lag_or_last_commmit				varchar(10) not null,
			synchronization_health_desc		varchar(64) not null
		);

		insert		##ag (node_name, role_desc, database_name, availability_mode_desc, synchronization_state_desc, lag_or_last_commmit, synchronization_health_desc)
		select		n.node_name,rs.role_desc, db_name(drs.database_id) as 'database_name', r.availability_mode_desc, drs.synchronization_state_desc,right('00' + cast(datediff(s,drs.last_commit_time,getdate()) / 60 / 60 as varchar(2)),2) + ':' + right('00' + cast(datediff(s,drs.last_commit_time,getdate()) / 60 % 60 as varchar(2)),2) + ':' + right('00' + cast(datediff(s,drs.last_commit_time,getdate()) % 60 as varchar(2)),2) as lag_or_last_commit,drs.synchronization_health_desc 
		from		sys.dm_hadr_availability_replica_cluster_nodes n with (nolock)
		inner join	sys.dm_hadr_availability_replica_cluster_states cs with (nolock)
			on		n.replica_server_name = cs.replica_server_name 
		inner join	sys.dm_hadr_availability_replica_states rs  with (nolock)
			on		rs.replica_id = cs.replica_id
		inner join	sys.dm_hadr_database_replica_states drs with (nolock)
			on		rs.replica_id=drs.replica_id 
		inner join	sys.availability_replicas r with (nolock)
			on		rs.replica_id=r.replica_id;

		select		node_name, role_desc, database_name, availability_mode_desc, synchronization_state_desc, lag_or_last_commmit, synchronization_health_desc 
		from		##ag;
	end
end

select percent_complete, t.text, * from sys.dm_exec_requests r cross join sys.dm_exec_query

--#################################################################################################################################################################

select 
		cast(db_name(database_id)as varchar(40)) database_name,
		last_commit_time, 
		getdate() as [current_time],
		right('00' + cast(datediff(s,last_commit_time,getdate()) / 60 / 60 as varchar(2)),2) + ':' + right('00' + cast(datediff(s,last_commit_time,getdate()) / 60 % 60 as varchar(2)),2) + ':' + right('00' + cast(datediff(s,last_commit_time,getdate()) % 60 as varchar(2)),2) as lag, --time_behind_primary,
		log_send_queue_size,
		log_send_rate,
		redo_queue_size,
		redo_rate,
		dateadd(mi,(redo_queue_size/redo_rate/60.0),getdate()) as estimated_completion_time,
		cast((redo_queue_size/redo_rate/60.0) as decimal(10,2)) as estimated_recovery_time_minutes,
		(redo_queue_size/redo_rate) as estimated_recovery_time_seconds
from	sys.dm_hadr_database_replica_states
where	last_redone_time is not null

---------------------------------------------------
SELECT 
	ar.replica_server_name, 
	adc.database_name, 
	ag.name AS ag_name, 
	drs.is_local, 
	--drs.is_primary_replica, 
	drs.synchronization_state_desc, 
	right('00' + cast(datediff(s,drs.last_commit_time,getdate()) / 60 / 60 as varchar(2)),2) + ':' + right('00' + cast(datediff(s,drs.last_commit_time,getdate()) / 60 % 60 as varchar(2)),2) + ':' + right('00' + cast(datediff(s,drs.last_commit_time,getdate()) % 60 as varchar(2)),2) as lag_or_last_commit, --time_behind_primary,
	drs.is_commit_participant, 
	drs.synchronization_health_desc, 
	drs.recovery_lsn, 
	drs.truncation_lsn, 
	drs.last_sent_lsn, 
	drs.last_sent_time, 
	drs.last_received_lsn, 
	drs.last_received_time, 
	drs.last_hardened_lsn, 
	drs.last_hardened_time, 
	drs.last_redone_lsn, 
	drs.last_redone_time, 
	drs.log_send_queue_size, 
	drs.log_send_rate, 
	drs.redo_queue_size, 
	drs.redo_rate, 
	drs.filestream_send_rate, 
	drs.end_of_log_lsn, 
	drs.last_commit_lsn, 
	drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
	ON drs.group_id = adc.group_id AND 
	drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
	ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar 
	ON drs.group_id = ar.group_id AND 
	drs.replica_id = ar.replica_id
ORDER BY 
	ag.name, 
	ar.replica_server_name, 
	adc.database_name;

/*
select		ag_name, replica_server_name, database_name, last_commit_time, diff as diff_last_commit_time_primary
from		(
			select		ag.name AS ag_name,
						ar.replica_server_name, 
						adc.database_name, 
						drs.last_commit_time,
						case 
							when lag (drs.last_commit_time,1,0) over (partition by ag.name order by drs.last_commit_time desc) > '1900-01-01 00:00:00.000' 
							then DATEDIFF(ms,drs.last_commit_time,lag (drs.last_commit_time,1,0) over (partition by ag.name order by drs.last_commit_time desc))
							else NULL
						end as diff
			FROM		sys.dm_hadr_database_replica_states AS drs
			INNER JOIN	sys.availability_databases_cluster AS adc 
				ON		drs.group_id = adc.group_id 
				AND		drs.group_database_id = adc.group_database_id
			INNER JOIN	sys.availability_groups AS ag
				ON		ag.group_id = drs.group_id
			INNER JOIN	sys.availability_replicas AS ar 
				ON		drs.group_id = ar.group_id 
				AND 	drs.replica_id = ar.replica_id
) as a
where diff is not null
*/
---------------------------------------------------

--RPO metric queries - Log send queue method
;WITH UpTime AS
			(
			SELECT DATEDIFF(SECOND,create_date,GETDATE()) [upTime_secs]
			FROM sys.databases
			WHERE name = 'tempdb'
			),
	AG_Stats AS 
			(
			SELECT AR.replica_server_name,
				   HARS.role_desc, 
				   Db_name(DRS.database_id) [DBName], 
				   CAST(DRS.log_send_queue_size AS DECIMAL(19,2)) log_send_queue_size_KB, 
				   (CAST(perf.cntr_value AS DECIMAL(19,2)) / CAST(UpTime.upTime_secs AS DECIMAL(19,2))) / CAST(1024 AS DECIMAL(19,2)) [log_KB_flushed_per_sec]
			FROM   sys.dm_hadr_database_replica_states DRS 
			INNER JOIN sys.availability_replicas AR ON DRS.replica_id = AR.replica_id 
			INNER JOIN sys.dm_hadr_availability_replica_states HARS ON AR.group_id = HARS.group_id 
				AND AR.replica_id = HARS.replica_id 
			--I am calculating this as an average over the entire time that the instance has been online.
			--To capture a smaller, more recent window, you will need to:
			--1. Store the counter value.
			--2. Wait N seconds.
			--3. Recheck counter value.
			--4. Divide the difference between the two checks by N.
			INNER JOIN sys.dm_os_performance_counters perf ON perf.instance_name = Db_name(DRS.database_id)
				AND perf.counter_name like 'Log Bytes Flushed/sec%'
			CROSS APPLY UpTime
			),
	Pri_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
					, [log_KB_flushed_per_sec]
			FROM	AG_Stats
			WHERE	role_desc = 'PRIMARY'
			),
	Sec_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
					--Send queue will be NULL if secondary is not online and synchronizing
					, log_send_queue_size_KB
			FROM	AG_Stats
			WHERE	role_desc = 'SECONDARY'
			)
SELECT p.replica_server_name [primary_replica]
	, p.[DBName] AS [DatabaseName]
	, s.replica_server_name [secondary_replica]
	, CAST(s.log_send_queue_size_KB / p.[log_KB_flushed_per_sec] AS BIGINT) [Sync_Lag_Secs]
FROM Pri_CommitTime p
LEFT JOIN Sec_CommitTime s ON [s].[DBName] = [p].[DBName]
where CAST(s.log_send_queue_size_KB / p.[log_KB_flushed_per_sec] AS BIGINT) > 0

--RPO metric queries - Last commit time method
;with ag_stats as  
( 
	select		ar.replica_server_name, hars.role_desc,db_name (drs.database_id) as [dbname], drs.last_commit_time 
	from		sys.dm_hadr_database_replica_states drs  
	inner join	sys.availability_replicas ar 
		on		drs.replica_id = ar.replica_id  
	inner join	sys.dm_hadr_availability_replica_states hars 
		on		ar.group_id = hars.group_id  
		and		ar.replica_id = hars.replica_id 
), pri_committime as  
( 
	select	 replica_server_name, dbname, last_commit_time 
	from	 ag_stats 
	where	 role_desc = 'primary' 
), sec_committime  as  
( 
	select	 replica_server_name, dbname, last_commit_time 
	from	 ag_stats 
	where	 role_desc = 'secondary' 
) 
select		p.[dbname] as [databasename],
			p.replica_server_name  [primary_replica],
			s.replica_server_name [secondary_replica],
			datediff (ms, s.last_commit_time, p.last_commit_time) as [sync_lag_milisecs] 
from		pri_committime p		
left join	sec_committime s  
	on		[s].[dbname] = [p].[dbname] 

 --RTO metric query

 ;WITH 
	AG_Stats AS 
			(
			SELECT AR.replica_server_name,
				   HARS.role_desc, 
				   Db_name(DRS.database_id) [DBName], 
				   DRS.redo_queue_size redo_queue_size_KB,
				   DRS.redo_rate redo_rate_KB_Sec
			FROM   sys.dm_hadr_database_replica_states DRS 
			INNER JOIN sys.availability_replicas AR ON DRS.replica_id = AR.replica_id 
			INNER JOIN sys.dm_hadr_availability_replica_states HARS ON AR.group_id = HARS.group_id 
				AND AR.replica_id = HARS.replica_id 
			),
	Pri_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
					, redo_queue_size_KB
					, redo_rate_KB_Sec
			FROM	AG_Stats
			WHERE	role_desc = 'PRIMARY'
			),
	Sec_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
					--Send queue and rate will be NULL if secondary is not online and synchronizing
					, redo_queue_size_KB
					, redo_rate_KB_Sec
			FROM	AG_Stats
			WHERE	role_desc = 'SECONDARY'
			)
SELECT p.replica_server_name [primary_replica]
	, p.[DBName] AS [DatabaseName]
	, s.replica_server_name [secondary_replica]
	, CAST(s.redo_queue_size_KB / s.redo_rate_KB_Sec AS BIGINT) [Redo_Lag_Secs]
FROM Pri_CommitTime p
LEFT JOIN Sec_CommitTime s ON [s].[DBName] = [p].[DBName]

--Synchronization metric queries - Performance monitor counters method

--Check metrics first
 
IF OBJECT_ID('tempdb..#perf') IS NOT NULL
	DROP TABLE #perf
 
SELECT IDENTITY (int, 1,1) id
	,instance_name
	,CAST(cntr_value * 1000 AS DECIMAL(19,2)) [mirrorWriteTrnsMS]
	,CAST(NULL AS DECIMAL(19,2)) [trnDelayMS]
INTO #perf
FROM sys.dm_os_performance_counters perf
WHERE perf.counter_name LIKE 'Mirrored Write Transactions/sec%'
	AND object_name LIKE 'SQLServer:Database Replica%'
	
UPDATE p
SET p.[trnDelayMS] = perf.cntr_value
FROM #perf p
INNER JOIN sys.dm_os_performance_counters perf ON p.instance_name = perf.instance_name
WHERE perf.counter_name LIKE 'Transaction Delay%'
	AND object_name LIKE 'SQLServer:Database Replica%'
	AND trnDelayMS IS NULL
 
-- Wait for recheck
-- I found that these performance counters do not update frequently,
-- thus the long delay between checks.
WAITFOR DELAY '00:01:00'
GO
--Check metrics again
 
INSERT INTO #perf
(
	instance_name
	,mirrorWriteTrnsMS
	,trnDelayMS
)
SELECT instance_name
	,CAST(cntr_value * 1000 AS DECIMAL(19,2)) [mirrorWriteTrnsMS]
	,NULL
FROM sys.dm_os_performance_counters perf
WHERE perf.counter_name LIKE 'Mirrored Write Transactions/sec%'
	AND object_name LIKE 'SQLServer:Database Replica%'
	
UPDATE p
SET p.[trnDelayMS] = perf.cntr_value
FROM #perf p
INNER JOIN sys.dm_os_performance_counters perf ON p.instance_name = perf.instance_name
WHERE perf.counter_name LIKE 'Transaction Delay%'
	AND object_name LIKE 'SQLServer:Database Replica%'
	AND trnDelayMS IS NULL
	
--Aggregate and present
 ;WITH AG_Stats AS 
			(
			SELECT AR.replica_server_name,
				   HARS.role_desc, 
				   Db_name(DRS.database_id) [DBName]
			FROM   sys.dm_hadr_database_replica_states DRS 
			INNER JOIN sys.availability_replicas AR ON DRS.replica_id = AR.replica_id 
			INNER JOIN sys.dm_hadr_availability_replica_states HARS ON AR.group_id = HARS.group_id 
				AND AR.replica_id = HARS.replica_id 
			),
	Check1 AS
			(
			SELECT DISTINCT p1.instance_name
				,p1.mirrorWriteTrnsMS
				,p1.trnDelayMS
			FROM #perf p1
			INNER JOIN 
				(
					SELECT instance_name, MIN(id) minId
					FROM #perf p2
					GROUP BY instance_name
				) p2 ON p1.instance_name = p2.instance_name
			),
	Check2 AS
			(
			SELECT DISTINCT p1.instance_name
				,p1.mirrorWriteTrnsMS
				,p1.trnDelayMS
			FROM #perf p1
			INNER JOIN 
				(
					SELECT instance_name, MAX(id) minId
					FROM #perf p2
					GROUP BY instance_name
				) p2 ON p1.instance_name = p2.instance_name
			),
	AggregatedChecks AS
			(
				SELECT DISTINCT c1.instance_name
					, c2.mirrorWriteTrnsMS - c1.mirrorWriteTrnsMS mirrorWriteTrnsMS
					, c2.trnDelayMS - c1.trnDelayMS trnDelayMS
				FROM Check1 c1
				INNER JOIN Check2 c2 ON c1.instance_name = c2.instance_name
			),
	Pri_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
			FROM	AG_Stats
			WHERE	role_desc = 'PRIMARY'
			),
	Sec_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
			FROM	AG_Stats
			WHERE	role_desc = 'SECONDARY'
			)
SELECT p.replica_server_name [primary_replica]
	, p.[DBName] AS [DatabaseName]
	, s.replica_server_name [secondary_replica]
	, CAST(CASE WHEN ac.trnDelayMS = 0 THEN 1 ELSE ac.trnDelayMS END AS DECIMAL(19,2) / ac.mirrorWriteTrnsMS) sync_lag_MS
FROM Pri_CommitTime p
LEFT JOIN Sec_CommitTime s ON [s].[DBName] = [p].[DBName]
LEFT JOIN AggregatedChecks ac ON ac.instance_name = p.DBName
 
  --Wait types method
  ;WITH AG_Stats AS 
			(
			SELECT AR.replica_server_name,
				   HARS.role_desc, 
				   Db_name(DRS.database_id) [DBName]
			FROM   sys.dm_hadr_database_replica_states DRS 
			INNER JOIN sys.availability_replicas AR ON DRS.replica_id = AR.replica_id 
			INNER JOIN sys.dm_hadr_availability_replica_states HARS ON AR.group_id = HARS.group_id 
				AND AR.replica_id = HARS.replica_id 
			),
	Waits AS
			(
			select wait_type
				, waiting_tasks_count
				, wait_time_ms
				, wait_time_ms/waiting_tasks_count sync_lag_MS
			from sys.dm_os_wait_stats where waiting_tasks_count >0
			and wait_type = 'HADR_SYNC_COMMIT'
			),
	Pri_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
			FROM	AG_Stats
			WHERE	role_desc = 'PRIMARY'
			),
	Sec_CommitTime AS 
			(
			SELECT	replica_server_name
					, DBName
			FROM	AG_Stats
			WHERE	role_desc = 'SECONDARY'
			)
SELECT p.replica_server_name [primary_replica]
	, w.sync_lag_MS
FROM Pri_CommitTime p
CROSS APPLY Waits w

---------------------------------------------------

--primary
ALTER AVAILABILITY GROUP MyAG ADD DATABASE BDTPISS

--secondary
ALTER DATABASE BDTPISS SET HADR AVAILABILITY GROUP = MyAG;  

---------------------------------------------------
read only routing

ALTER AVAILABILITY GROUP [AG1]  MODIFY REPLICA ON  N'COMPUTER01' WITH   (SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));  
ALTER AVAILABILITY GROUP [AG1]  MODIFY REPLICA ON  N'COMPUTER01' WITH   (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://COMPUTER01.contoso.com:1433'));  
  
ALTER AVAILABILITY GROUP [AG1]  MODIFY REPLICA ON  N'COMPUTER02' WITH   (SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));  
ALTER AVAILABILITY GROUP [AG1]  MODIFY REPLICA ON  N'COMPUTER02' WITH   (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://COMPUTER02.contoso.com:1433'));  
  
ALTER AVAILABILITY GROUP [AG1]   MODIFY REPLICA ON  N'COMPUTER01' WITH   (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('COMPUTER02','COMPUTER01')));  
  
ALTER AVAILABILITY GROUP [AG1]   MODIFY REPLICA ON  N'COMPUTER02' WITH   (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('COMPUTER01','COMPUTER02')));  
GO
