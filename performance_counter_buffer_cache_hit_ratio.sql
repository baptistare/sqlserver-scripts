SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100.0 [BufferCacheHitRatio]

FROM (SELECT *, 1 x FROM sys.dm_os_performance_counters  

        WHERE counter_name = 'Buffer cache hit ratio'

          AND object_name = 'SQLServer:Buffer Manager') a  

     JOIN

     (SELECT *, 1 x FROM sys.dm_os_performance_counters  

        WHERE counter_name = 'Buffer cache hit ratio base'

          and object_name = 'SQLServer:Buffer Manager') as b
		  on a.object_name = b.object_name