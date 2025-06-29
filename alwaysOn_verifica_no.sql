--Script para verificar se o nó do AlwaysOn é Primario ou Secundário
--DECLARE		@Node		VARCHAR(50)
--SELECT		@Node = ReplicaStates.role_desc
--FROM		sys.dm_hadr_availability_replica_states							AS ReplicaStates
--JOIN		sys.availability_replicas										AS AvailReplica
--                ON AvailReplica.replica_id = ReplicaStates.replica_id
--WHERE		AvailReplica.replica_server_name = @@ServerName

--PRINT  @@SERVERNAME + '    ' + @Node


--DECLARE		@Node		VARCHAR(50)
--SELECT		@Node = ReplicaStates.role_desc
--FROM		sys.dm_hadr_availability_replica_states							AS ReplicaStates
--JOIN		sys.availability_replicas										AS AvailReplica
--                ON AvailReplica.replica_id = ReplicaStates.replica_id
--WHERE		AvailReplica.replica_server_name = @@ServerName

--IF (@Node = 'PRIMARY')
--BEGIN
--	SELECT ''
--END


select	distinct @@SERVERNAME as server_name, ReplicaStates.role_desc, *
from	sys.dm_hadr_availability_replica_states AS ReplicaStates
join	sys.availability_replicas AS AvailReplica
	on	AvailReplica.replica_id = ReplicaStates.replica_id
where	AvailReplica.replica_server_name = @@ServerName

