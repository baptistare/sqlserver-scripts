use master;
set nocount on;

declare @path nvarchar(500)
if HAS_PERMS_BY_NAME(NULL, NULL, 'ALTER TRACE') = 1
select @path = convert(nvarchar(500), value)
from ::fn_trace_getinfo(0) i
join sys.traces t on t.id = i.traceid
where t.is_default = 1 and i.property = 2;
select @path

if @path is not null
begin
   select @path = reverse(substring(reverse(@path), charindex('\', reverse(@path)), 500)) + N'log.trc'
   select last_occurrence, name + isnull(' (' + subclass_name + ')', '') EventName,
      DatabaseName, LoginName, RoleName, TargetUserName, TargetLoginName, SessionLoginName, TextData, num_occurrences
   from (
      select e.name,
         v.subclass_name,
         df.ApplicationName,
         df.DatabaseName,
         df.LoginName,
         df.RoleName,
         df.TargetUserName,
         df.TargetLoginName,
         df.SessionLoginName,
         convert(nvarchar(255), df.TextData) TextData,
         max(df.StartTime) last_occurrence,
         count(*) num_occurrences
      from ::fn_trace_gettable(convert(nvarchar(255), @path), 0) df
      join sys.trace_events e ON df.EventClass = e.trace_event_id
      left join sys.trace_subclass_values v on v.trace_event_id = e.trace_event_id and v.subclass_value = df.EventSubClass
      where e.category_id = 8
      and e.trace_event_id <> 175
      group by e.name, v.subclass_name, df.ApplicationName, df.DatabaseName, df.LoginName, df.RoleName, df.TargetUserName, df.TargetLoginName, df.SessionLoginName, convert(nvarchar(255), df.TextData)) x
   order by last_occurrence desc
end

-------------------------------------------------------------------------------------------------------------------------------

      select e.name,
         v.subclass_name,
         df.ApplicationName,
         df.DatabaseName,
         df.LoginName,
         df.RoleName,
         df.TargetUserName,
         df.TargetLoginName,
         df.SessionLoginName,
         convert(nvarchar(255), df.TextData) TextData,
		df.StartTime last_occurrence
      from ::fn_trace_gettable(convert(nvarchar(255), 'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\log_83.trc'), 0) df
      join sys.trace_events e ON df.EventClass = e.trace_event_id
      left join sys.trace_subclass_values v on v.trace_event_id = e.trace_event_id and v.subclass_value = df.EventSubClass
      where e.category_id = 8
      and e.trace_event_id <> 175

-------------------------------------------------------------------------------------------------------------------------------

SELECT
  [PAGE ID],
  [Slot ID],
  [AllocUnitId],
  [Transaction ID],
  [RowLog Contents 0],
  [RowLog Contents 1],
  [RowLog Contents 3],
  [RowLog Contents 4],
  [Log Record], *
FROM   sys.fn_dblog(NULL, NULL)
WHERE  AllocUnitId IN (SELECT
                         [Allocation_unit_id]
                       FROM       sys.allocation_units allocunits
                       INNER JOIN sys.partitions partitions
                               ON ( allocunits.type IN ( 1, 3 )
                                    AND partitions.hobt_id = allocunits.container_id )
                               OR ( allocunits.type = 2
                                    AND partitions.partition_id = allocunits.container_id )
                       WHERE      1 =1
					   --and object_id = object_ID('' + 'dbo.GMACTDISASTER' + '')
					   )
       AND Operation IN ( 'LOP_MODIFY_ROW', 'LOP_MODIFY_COLUMNS' )
       AND [Context] IN ( 'LCX_HEAP', 'LCX_CLUSTERED' ) 