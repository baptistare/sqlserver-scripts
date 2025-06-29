select top 3 * from sys.dm_hadr_auto_page_repair
select top 3 * from sys.dm_hadr_automatic_seeding
select top 3 * from sys.dm_hadr_availability_group_states
select top 3 * from sys.dm_hadr_availability_replica_cluster_nodes
select top 3 * from sys.dm_hadr_availability_replica_cluster_states
select top 3 * from sys.dm_hadr_availability_replica_states
select top 3 * from sys.dm_hadr_cluster
select top 3 * from sys.dm_hadr_cluster_members
select top 3 * from sys.dm_hadr_cluster_networks
select top 3 * from sys.dm_hadr_database_replica_cluster_states
select top 3 * from sys.dm_hadr_database_replica_states
select top 3 * from sys.dm_hadr_instance_node_map
select top 3 * from sys.dm_hadr_name_id_map
select top 3 * from sys.dm_hadr_physical_seeding_stats

select top 3 * from sys.availability_databases_cluster
select top 3 * from sys.availability_group_listener_ip_addresses
select top 3 * from sys.availability_group_listeners
select top 3 * from sys.availability_groups
select top 3 * from sys.availability_groups_cluster
select top 3 * from sys.availability_read_only_routing_lists
select top 3 * from sys.availability_replicas

select top 3 * from sys.dm_tcp_listener_states

select	n.group_name, n.replica_server_name, n.node_name, rs.role_desc
from	sys.dm_hadr_availability_replica_cluster_nodes n
join	sys.dm_hadr_availability_replica_cluster_states cs
	on	n.replica_server_name = cs.replica_server_name
join	sys.dm_hadr_availability_replica_states rs
	on	cs.replica_id = rs.replica_id

select	n.group_name, n.replica_server_name, n.node_name, rs.role_desc, db_name(drs.database_id) as databaseName, drs.synchronization_health_desc
from	sys.dm_hadr_availability_replica_cluster_nodes n
join	sys.dm_hadr_availability_replica_cluster_states cs
	on	n.replica_server_name = cs.replica_server_name
join	sys.dm_hadr_availability_replica_states rs
	on	cs.replica_id = rs.replica_id
join	sys.dm_hadr_database_replica_states drs
	on	rs.replica_id = drs.replica_id
where	n.replica_server_name = @@SERVERNAME

select	object_name, counter_name, instance_name, cntr_value
from	sys.dm_os_performance_counters
where	object_name like '%replica%'