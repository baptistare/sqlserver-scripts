/*
For the U-value, the percentage of updates, we are given this code:

To compute U, use the statistics in the DMV sys.dm_db_index_operational_stats. 
U is the ratio (expressed in percent) of updates performed on a table or index
 to the sum of all operations (scans + DMLs + lookups) on that table or index. 
 The following query reports U for each table and index in the database. 
*/
 
SELECT o.name AS [Table_Name], x.name AS [Index_Name],
       i.partition_number AS [Partition],
       i.index_id AS [Index_ID], x.type_desc AS [Index_Type],
       i.leaf_update_count * 100.0 /
           (i.range_scan_count + i.leaf_insert_count
            + i.leaf_delete_count + i.leaf_update_count
            + i.leaf_page_merge_count + i.singleton_lookup_count
           ) AS [Percent_Update]
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
JOIN sys.objects o with (nolock) ON o.object_id = i.object_id
JOIN sys.indexes x with (nolock) ON x.object_id = i.object_id AND x.index_id = i.index_id
WHERE  (i.range_scan_count + i.leaf_insert_count
       + i.leaf_delete_count + leaf_update_count
       + i.leaf_page_merge_count + i.singleton_lookup_count) != 0
AND objectproperty(i.object_id,'IsUserTable') = 1
ORDER BY [Percent_Update] ASC

SELECT o.name AS [Table_Name], x.name AS [Index_Name],
       i.partition_number AS [Partition],
       i.index_id AS [Index_ID], x.type_desc AS [Index_Type],
       i.leaf_update_count * 100.0 /
           (i.range_scan_count + i.leaf_insert_count
            + i.leaf_delete_count + i.leaf_update_count
            + i.leaf_page_merge_count + i.singleton_lookup_count
           ) AS [Percent_Update]
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
JOIN sys.objects o with (nolock) ON o.object_id = i.object_id
JOIN sys.indexes x with (nolock) ON x.object_id = i.object_id AND x.index_id = i.index_id
join sys.tables t with (nolock) on x.object_id = t.object_id
join sys.partitions as p with (nolock) on p.object_id = t.object_id
join sys.allocation_units as au with (nolock) on p.partition_id = au.container_id
WHERE  (i.range_scan_count + i.leaf_insert_count
       + i.leaf_delete_count + leaf_update_count
       + i.leaf_page_merge_count + i.singleton_lookup_count) != 0
AND objectproperty(i.object_id,'IsUserTable') = 1
order by 1
ORDER BY [Percent_Update] ASC


from		sys.partitions as p with (nolock)
inner join	sys.allocation_units as au with (nolock)
	on		p.partition_id = au.container_id--hobt_id
inner join	sys.tables t with (nolock)
	on		p.object_id = t.object_id

/*
For S, the percentage of scans, we are given this code:

To compute S, use the statistics in the DMV sys.dm_db_index_operational_stats. 
S is the ratio (expressed in percent) of scans performed on a table or index 
to the sum of all operations (scans + DMLs + lookups) on that table or index. 
In other words, S represents how heavily the table or index is scanned. 
The following query reports S for each table, index, and partition in the database.
*/
 
SELECT o.name AS [Table_Name], x.name AS [Index_Name],
       i.partition_number AS [Partition],
       i.index_id AS [Index_ID], x.type_desc AS [Index_Type],
       i.range_scan_count * 100.0 /
           (i.range_scan_count + i.leaf_insert_count
            + i.leaf_delete_count + i.leaf_update_count
            + i.leaf_page_merge_count + i.singleton_lookup_count
           ) AS [Percent_Scan]
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
JOIN sys.objects o with (nolock) ON o.object_id = i.object_id
JOIN sys.indexes x with (nolock) ON x.object_id = i.object_id AND x.index_id = i.index_id
WHERE (i.range_scan_count + i.leaf_insert_count
       + i.leaf_delete_count + leaf_update_count
       + i.leaf_page_merge_count + i.singleton_lookup_count) != 0
AND objectproperty(i.object_id,'IsUserTable') = 1
ORDER BY [Percent_Scan] DESC

