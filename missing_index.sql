-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--missing index
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

;with cte_index as
(
  select      OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) as objectName, dbmid.equality_columns, dbmid.inequality_columns--, sum(dbmigs.user_seeks) as sum_user_seeks, sum(dbmigs.user_scans) as sum_user_scans
  from      sys.dm_db_missing_index_groups dbmig
  inner join    sys.dm_db_missing_index_group_stats dbmigs
    on      dbmigs.group_handle = dbmig.index_group_handle
  inner join    sys.dm_db_missing_index_details dbmid
    on      dbmig.index_handle = dbmid.index_handle
  where     1 = 1
    and     dbmid.database_id = db_id()
    and     dbmigs.avg_user_impact >= 50
  group by    OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id), dbmid.equality_columns, dbmid.inequality_columns         
  having          sum(dbmigs.user_seeks) >= 1000 or sum(dbmigs.user_scans) >= 1000
)
select    missing.*
from      cte_index cte
join        (
        --select dbmigs.*,
                select        OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) as objectName, dbmid.equality_columns, dbmid.inequality_columns, dbmid.included_columns,
                                    dbmigs.user_seeks,dbmigs.user_scans,dbmigs.avg_user_impact, dbmigs.avg_user_impact*(dbmigs.user_seeks+dbmigs.user_scans) avg_estimated_impact,
                  'CREATE INDEX [IX_' + OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) + '_'
                                        + REPLACE(REPLACE(REPLACE(ISNULL(dbmid.equality_columns,''),', ','_'),'[',''),']','')
                                        + CASE
                                        WHEN dbmid.equality_columns IS NOT NULL
                                        AND dbmid.inequality_columns IS NOT NULL THEN '_'
                                        ELSE ''
                                        END
                                        + REPLACE(REPLACE(REPLACE(ISNULL(dbmid.inequality_columns,''),', ','_'),'[',''),']','')
                                        + ']'
                                        + ' ON ' + dbmid.statement
                                        + ' (' + ISNULL (dbmid.equality_columns,'')
                                        + CASE WHEN dbmid.equality_columns IS NOT NULL AND dbmid.inequality_columns
                                        IS NOT NULL THEN ',' ELSE
                                        '' END
                                        + ISNULL (dbmid.inequality_columns, '')
                                        + ')'
                                        + ISNULL (' INCLUDE (' + dbmid.included_columns + ')', '') AS Create_Statement
                from        sys.dm_db_missing_index_groups dbmig
                inner join  sys.dm_db_missing_index_group_stats dbmigs
          on    dbmigs.group_handle = dbmig.index_group_handle
                inner join  sys.dm_db_missing_index_details dbmid
          on    dbmig.index_handle = dbmid.index_handle
                where       1 = 1
          and   dbmid.database_id = db_id()
      ) as missing
    on    cte.objectName = missing.objectName
    and   isnull(cte.equality_columns,'') = isnull(missing.equality_columns,'')
    and   isnull(cte.inequality_columns,'') = isnull(missing.inequality_columns,'')
order by  2,3

 

/*


                               'CREATE INDEX [IX_' + OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) + '_'
                                               + REPLACE(REPLACE(REPLACE(ISNULL(dbmid.equality_columns,''),', ','_'),'[',''),']','')
                                               + CASE
                                               WHEN dbmid.equality_columns IS NOT NULL
                                               AND dbmid.inequality_columns IS NOT NULL THEN '_'
                                               ELSE ''
                                               END
                                               + REPLACE(REPLACE(REPLACE(ISNULL(dbmid.inequality_columns,''),', ','_'),'[',''),']','')
                                               + ']'
                                               + ' ON ' + dbmid.statement
                                               + ' (' + ISNULL (dbmid.equality_columns,'')
                                               + CASE WHEN dbmid.equality_columns IS NOT NULL AND dbmid.inequality_columns
                                               IS NOT NULL THEN ',' ELSE
                                               '' END
                                               + ISNULL (dbmid.inequality_columns, '')
                                               + ')'
                                               + ISNULL (' INCLUDE (' + dbmid.included_columns + ')', '') AS Create_Statement
 
listar os missings index cujo a soma de seeks é menor do q o threshold

;with cte_index as
(
select                    OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) as objectName, dbmid.equality_columns, dbmid.inequality_columns--, sum(dbmigs.user_seeks) as sum_user_seeks, sum(dbmigs.user_scans) as sum_user_scans
from                     sys.dm_db_missing_index_groups dbmig
inner join            sys.dm_db_missing_index_group_stats dbmigs
                on                          dbmigs.group_handle = dbmig.index_group_handle
inner join            sys.dm_db_missing_index_details dbmid
                on                          dbmig.index_handle = dbmid.index_handle
where                   1 = 1
                and                        dbmid.database_id = db_id()
group by              OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id), dbmid.equality_columns, dbmid.inequality_columns         
--having                               sum(dbmigs.user_seeks) >= 1000 or sum(dbmigs.user_scans) >= 1000
having                  sum(dbmigs.user_seeks) >= 300 or sum(dbmigs.user_scans) >= 300
)
select    missing.*
from      cte_index cte
right join             (
                                               select                    OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) as objectName, dbmid.equality_columns, dbmid.inequality_columns, dbmid.included_columns,
                                                                                              dbmigs.user_seeks,dbmigs.user_scans,dbmigs.avg_user_impact, dbmigs.avg_user_impact*(dbmigs.user_seeks+dbmigs.user_scans) avg_estimated_impact
                                               from                     sys.dm_db_missing_index_groups dbmig
                                               inner join            sys.dm_db_missing_index_group_stats dbmigs
                                                               on                          dbmigs.group_handle = dbmig.index_group_handle
                                               inner join            sys.dm_db_missing_index_details dbmid
                                                               on                          dbmig.index_handle = dbmid.index_handle
                                               where                   1 = 1
                                                               and                        dbmid.database_id = db_id()
                               ) as missing
                on          cte.objectName = missing.objectName
                and        isnull(cte.equality_columns,'') = isnull(missing.equality_columns,'')
                and isnull(cte.inequality_columns,'') = isnull(missing.inequality_columns,'')
where 1 =1
                and cte.objectName is null
order by 2,3
 
listar todos os missing index
select                    OBJECT_NAME(dbmid.OBJECT_ID,dbmid.database_id) as objectName, dbmid.equality_columns, dbmid.inequality_columns, dbmid.included_columns,
                                               dbmigs.user_seeks,dbmigs.user_scans,dbmigs.avg_user_impact, dbmigs.avg_user_impact*(dbmigs.user_seeks+dbmigs.user_scans) avg_estimated_impact
from                     sys.dm_db_missing_index_groups dbmig
inner join            sys.dm_db_missing_index_group_stats dbmigs
                on                          dbmigs.group_handle = dbmig.index_group_handle
inner join            sys.dm_db_missing_index_details dbmid
                on                          dbmig.index_handle = dbmid.index_handle
where                   1 = 1
                and                        dbmid.database_id = db_id()
order by 2,3
*/

