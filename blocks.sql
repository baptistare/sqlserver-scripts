select		 s1.spid blocker
			,s2.spid blocked
			,s1.blocked [blocker blocker]
			,dest1.text command_blocker
			,s1.hostname host_blocker
			,s1.program_name program_blocker
			,s1.loginame login_bloker
			,s1.net_address address_bloker
			,dest2.text command_blocked
			,s2.hostname host_blocked
			,s2.program_name program_blocked
			,s2.loginame login_blocked
			,s2.net_address address_blocked
			,s1.waittime
			,s1.login_time
			,s1.last_batch
			,s1.open_tran
			,s1.status status_blocker
			,s2.status status_blocked
			,case 
				when s1.program_name not like 'sqlagent - tsql jobstep (job %' 
				then s1.program_name
				else	 (	select	name 
                            from	msdb..sysjobs 
                            where	job_id in	(
													select	substring(program_name,38,2) 
															+ substring(program_name,36,2) 
															+ substring(program_name,34,2) 
															+ substring(program_name,32,2) 
															+ '-' + substring(program_name,42,2) 
															+ substring(program_name,40,2) 
															+ '-' + substring(program_name,46,2) 
															+ substring(program_name,44,2) 
															+ '-' + substring(program_name,48,4) 
															+ '-' + substring(program_name,52,12) 
                                                    from	sysprocesses 
													where	spid   = s1.spid 
													and		program_name like 'sqlagent - tsql jobstep (job %'
												)
						)
			end as [program_name]
from		master.dbo.sysprocesses s1
inner join	master.dbo.sysprocesses s2
	on		s1.spid = s2.blocked
cross apply sys.dm_exec_sql_text (s1.sql_handle) dest1
cross apply sys.dm_exec_sql_text (s2.sql_handle) dest2
where		1=1
	and		s1.spid in (	select	blocked
							from	master.dbo.sysprocesses 
							where	1=1
							and		blocked > 0
						)
order by	s1.blocked,s1.spid