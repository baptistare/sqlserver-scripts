select is_memory_optimized_elevate_to_snapshot_on,* from sys.databases

select * from sys.all_objects where type = 'V' and name like 'dm_%'


sys.dm_resource_governor_resource_pool_volumes
sys.dm_os_hosts
sys.dm_os_memory_brokers
sys.dm_os_memory_allocations
sys.dm_db_xtp_nonclustered_index_stats
sys.dm_db_mirroring_past_actions
sys.dm_xe_session_object_columns
sys.dm_os_loaded_modules
sys.dm_db_task_space_usage
sys.dm_os_memory_objects
sys.dm_audit_class_type_map
sys.dm_os_schedulers
sys.dm_os_server_diagnostics_log_configurations
sys.dm_hadr_instance_node_map
sys.dm_io_cluster_valid_path_names
sys.dm_os_dispatcher_pools
sys.dm_xtp_transaction_stats
sys.dm_exec_query_profiles
sys.dm_os_threads
sys.dm_exec_requests
sys.dm_tran_commit_table
sys.dm_exec_query_parallel_workers
sys.dm_fts_outstanding_batches
sys.dm_exec_query_optimizer_memory_gateways
sys.dm_repl_tranhash
sys.dm_hadr_cluster
sys.dm_qn_subscriptions
sys.dm_db_session_space_usage
sys.dm_xtp_gc_stats
sys.dm_exec_query_optimizer_info
sys.dm_xe_map_values
sys.dm_db_xtp_index_stats
sys.dm_tran_top_version_generators
sys.dm_fts_fdhosts
sys.dm_xe_sessions
sys.dm_db_log_space_usage
sys.dm_db_column_store_row_group_physical_stats
sys.dm_hadr_name_id_map
sys.dm_os_waiting_tasks
sys.dm_exec_background_job_queue
sys.dm_db_missing_index_details
sys.dm_clr_properties
sys.dm_os_sublatches
sys.dm_exec_session_wait_stats
sys.dm_os_buffer_pool_extension_configuration
sys.dm_exec_query_memory_grants
sys.dm_resource_governor_external_resource_pool_affinity
sys.dm_logpool_hashentries
sys.dm_tran_current_snapshot
sys.dm_exec_valid_use_hints
sys.dm_db_column_store_row_group_operational_stats
sys.dm_os_wait_stats
sys.dm_os_memory_node_access_stats
sys.dm_os_spinlock_stats
sys.dm_database_encryption_keys
sys.dm_tran_global_transactions_log
sys.dm_db_xtp_checkpoint_stats
sys.dm_hadr_availability_replica_states
sys.dm_broker_connections
sys.dm_db_mirroring_auto_page_repair
sys.dm_exec_compute_node_status
sys.dm_server_registry
sys.dm_os_dispatchers
sys.dm_os_stacks
sys.dm_tran_global_recovery_transactions
sys.dm_external_script_execution_stats
sys.dm_db_xtp_object_stats
sys.dm_filestream_non_transacted_handles
sys.dm_xe_session_targets
sys.dm_audit_actions
sys.dm_hadr_availability_group_states
sys.dm_os_ring_buffers
sys.dm_hadr_physical_seeding_stats
sys.dm_db_xtp_table_memory_stats
sys.dm_db_missing_index_groups
sys.dm_hadr_cluster_members
sys.dm_db_uncontained_entities
sys.dm_exec_cached_plans
sys.dm_hadr_availability_replica_cluster_states
sys.dm_exec_sessions
sys.dm_broker_forwarded_messages
sys.dm_resource_governor_resource_pools
sys.dm_os_memory_clerks
sys.dm_hadr_auto_page_repair
sys.dm_db_xtp_memory_consumers--
sys.dm_repl_articles
sys.dm_xe_session_events
sys.dm_external_script_requests
sys.dm_fts_memory_buffers
sys.dm_fts_index_population
sys.dm_db_rda_migration_status
sys.dm_tran_current_transaction
sys.dm_os_cluster_properties
sys.dm_os_child_instances
sys.dm_exec_connections
sys.dm_server_memory_dumps
sys.dm_xtp_threads
sys.dm_exec_background_job_queue_stats
sys.dm_os_memory_broker_clerks
sys.dm_filestream_file_io_handles
sys.dm_exec_distributed_requests
sys.dm_xtp_transaction_recent_rows
sys.dm_hadr_availability_replica_cluster_nodes
sys.dm_fts_active_catalogs
sys.dm_tran_database_transactions
sys.dm_filestream_file_io_requests
sys.dm_exec_external_work
sys.dm_exec_function_stats
sys.dm_cdc_log_scan_sessions
sys.dm_os_memory_cache_clock_hands
sys.dm_repl_schemas
sys.dm_db_mirroring_connections
sys.dm_resource_governor_external_resource_pools
sys.dm_db_xtp_checkpoint_files
sys.dm_db_partition_stats
sys.dm_os_sys_memory
sys.dm_io_pending_io_requests
sys.dm_xtp_system_memory_consumers
sys.dm_hadr_cluster_networks
sys.dm_os_nodes
sys.dm_tcp_listener_states
sys.dm_os_memory_cache_entries
sys.dm_os_virtual_address_dump
sys.dm_cryptographic_provider_properties
sys.dm_tran_transactions_snapshot
sys.dm_os_memory_cache_hash_tables
sys.dm_cdc_errors
sys.dm_resource_governor_configuration
sys.dm_exec_external_operations
sys.dm_exec_query_stats
sys.dm_exec_compute_nodes
sys.dm_fts_semantic_similarity_population
sys.dm_clr_tasks
sys.dm_db_xtp_hash_index_stats
sys.dm_os_worker_local_storage
sys.dm_db_persisted_sku_features
sys.dm_db_index_usage_stats
sys.dm_os_buffer_descriptors
sys.dm_tran_active_snapshot_database_transactions
sys.dm_server_services
sys.dm_tran_active_transactions
sys.dm_tran_global_transactions_enlistments
sys.dm_db_file_space_usage
sys.dm_broker_activated_tasks
sys.dm_broker_queue_monitors
sys.dm_exec_distributed_sql_requests
sys.dm_os_memory_cache_counters
sys.dm_tran_session_transactions
sys.dm_clr_appdomains
sys.dm_db_xtp_gc_cycle_stats
sys.dm_exec_trigger_stats
sys.dm_os_memory_pools
sys.dm_os_latch_stats
sys.dm_io_backup_tapes
sys.dm_resource_governor_workload_groups
sys.dm_hadr_database_replica_states
sys.dm_fts_memory_pools
sys.dm_resource_governor_resource_pool_affinity
sys.dm_os_sys_info
sys.dm_tran_locks
sys.dm_exec_procedure_stats
sys.dm_exec_dms_services
sys.dm_hadr_database_replica_cluster_states
sys.dm_exec_distributed_request_steps
sys.dm_exec_query_transformation_stats
sys.dm_exec_query_resource_semaphores
sys.dm_repl_traninfo
sys.dm_exec_compute_node_errors
sys.dm_db_missing_index_group_stats
sys.dm_exec_dms_workers
sys.dm_hadr_automatic_seeding
sys.dm_fts_population_ranges
sys.dm_column_store_object_pool
sys.dm_os_performance_counters
sys.dm_os_workers
sys.dm_xe_session_event_actions
sys.dm_db_script_level
sys.dm_server_audit_status
sys.dm_db_rda_schema_update_status
sys.dm_io_cluster_shared_drives
sys.dm_os_tasks
sys.dm_db_fts_index_physical_stats
sys.dm_xe_packages
sys.dm_logpool_stats
sys.dm_os_memory_nodes
sys.dm_tran_version_store
sys.dm_os_windows_info
sys.dm_os_cluster_nodes
sys.dm_xtp_gc_queue_stats
sys.dm_os_process_memory
sys.dm_tran_global_transactions
sys.dm_xe_objects
sys.dm_xe_object_columns
sys.dm_db_xtp_transactions
sys.dm_clr_loaded_assemblies

select	o.name,* 
from	sys.memory_optimized_tables_internal_attributes m
join	sys.objects o
	on	m.object_id = o.object_id

select	* 
from	sys.memory_optimized_tables_internal_attributes m



--bases de dados habilitadas para in memory
use master
go
select * from sys.databases where is_memory_optimized_elevate_to_snapshot_on = 1

--tablas habilitadas para in memory
use DB_BAM
go
select * from sys.tables where is_memory_optimized = 1

--memory consumption of columnstore indexes on memory-optimized tables
select
			quotename(schema_name(o.schema_id)) + N'.' + quotename(object_name(motia.object_id)) as 'table',
			i.name as 'columnstore index',
			sum(mc.allocated_bytes) / 1024 as [allocated_kb],
			sum(mc.used_bytes) / 1024 as [used_kb]
from		sys.memory_optimized_tables_internal_attributes motia
inner join	sys.indexes i 
	on		motia.object_id = i.object_id 
	and		i.type in (5,6)
inner join	sys.dm_db_xtp_memory_consumers mc 
	on		motia.xtp_object_id=mc.xtp_object_id
inner join	sys.objects o 
	on		motia.object_id=o.object_id
where		1=1
	and		motia.type in (0, 2, 3, 4)
group by	o.schema_id, motia.object_id, i.name;

--memory consumption across internal structures used for columnstore indexes on memory-optimized tables
select
			quotename(schema_name(o.schema_id)) + N'.' + quotename(object_name(motia.object_id)) as 'table',
			i.name as 'columnstore index',
			motia.type_desc as 'internal table',
			mc.index_id as 'index',
			mc.memory_consumer_desc,
			mc.allocated_bytes / 1024 as [allocated_kb],
			mc.used_bytes / 1024 as [used_kb]
from		sys.memory_optimized_tables_internal_attributes motia
inner join	sys.indexes i 
	on		motia.object_id = i.object_id 
	and		i.type in (5,6)
inner join	sys.dm_db_xtp_memory_consumers mc 
	on		motia.xtp_object_id=mc.xtp_object_id
inner join	sys.objects o 
	on		motia.object_id=o.object_id
where		motia.type in (0, 2, 3, 4)

--shows all columns that are stored off-row, along with their sizes. A size of -1 indicates a LOB column. All LOB columns are stored off-row
select 
			quotename(schema_name(o.schema_id)) + N'.' + quotename(object_name(motia.object_id)) as 'table', 
			c.name as 'column', 
			c.max_length
from		sys.memory_optimized_tables_internal_attributes motia
inner join	sys.columns c 
	on		motia.object_id = c.object_id 
	and		motia.minor_id=c.column_id
inner join	sys.objects o 
	on		motia.object_id=o.object_id 
where		motia.type=5;

--shows the memory consumption of all internal tables and their indexes that are used to store the off-row columns
select
			quotename(schema_name(o.schema_id)) + N'.' + quotename(object_name(motia.object_id)) as 'table',
			c.name as 'column',
			c.max_length,
			mc.memory_consumer_desc,
			mc.index_id,
			mc.allocated_bytes,
			mc.used_bytes
from		sys.memory_optimized_tables_internal_attributes motia
inner join	sys.columns c 
	on		motia.object_id = c.object_id 
	and		motia.minor_id=c.column_id
inner join	sys.dm_db_xtp_memory_consumers mc 
	on		motia.xtp_object_id=mc.xtp_object_id
inner join	sys.objects o 
	on		motia.object_id=o.object_id 
where		motia.type=5;

SELECT object_name([object_id]) AS 'table_name', [object_id],  
     [name] AS 'index_name', [type_desc], [bucket_count]   
FROM sys.hash_indexes   
WHERE OBJECT_NAME([object_id]) = 'Transaction_Current'; 



