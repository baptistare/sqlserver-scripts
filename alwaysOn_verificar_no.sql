--Script para verificar se o nó do AlwaysOn é Primario ou Secundário
--declare		@Node		varchar(50)

--select	@Node = ReplicaStates.role_desc
--from	sys.dm_hadr_availability_replica_states AS ReplicaStates
--join	sys.availability_replicas AS AvailReplica
--	on	AvailReplica.replica_id = ReplicaStates.replica_id
--where	AvailReplica.replica_server_name = @@ServerName

--print   @@SERVERNAME + '    ' + @Node

select	@@SERVERNAME, ReplicaStates.role_desc
from	sys.dm_hadr_availability_replica_states AS ReplicaStates
join	sys.availability_replicas AS AvailReplica
	on	AvailReplica.replica_id = ReplicaStates.replica_id
where	AvailReplica.replica_server_name = @@ServerName