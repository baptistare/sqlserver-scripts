--identificacao maiores tabelas
select
			object_name(p.object_id) as tabela, rows as linhas,
			sum(total_pages * 8) as reservado,
			sum(case when index_id > 1 then 0 else data_pages * 8 end) as dados,
				sum(used_pages * 8) -
				sum(case when index_id > 1 then 0 else data_pages * 8 end) as indice,
			sum((total_pages - used_pages) * 8) as naoutilizado,
			sum(a.used_pages) as used_pages
from		sys.partitions as p
inner join	sys.allocation_units as a 
	on		p.partition_id = a.container_id
inner join	sys.tables t 
	on		p.object_id = t.object_id
group by	object_name(p.object_id), rows
order by 2	desc

sp_spaceused 'dbo.tb_dados_fake'
/*
name			rows		reserved	data		index_size	unused
tb_dados_fake	10000001    162184 KB	162000 KB	8 KB		176 KB
*/

--verificacao existencia de compactacao
select * from sys.partitions where object_id = object_id('dbo.tb_dados_fake')


/*
sp_estimate_data_compression_savings 
     [ @schema_name = ] 'schema_name'  
   , [ @object_name = ] 'object_name' 
   , [@index_id = ] index_id 
   , [@partition_number = ] partition_number 
   , [@data_compression = ] 'data_compression' 
[;]
*/

--estimar ganhos com a compactacao
exec sp_estimate_data_compression_savings 'dbo', 'tb_dados_fake', NULL, NULL, 'PAGE'
/*
size_with_current_compression_setting(KB)	size_with_requested_compression_setting(KB)
2580656										164296

select 2580656 / 1024 / 1024. --2.460937
select 164296 / 1024 / 1024. --0.156250
select 164296 / 1024. --160.445312

select 162184 / 1024. --158.382812
*/

exec sp_estimate_data_compression_savings 'dbo', 'tb_dados_fake', NULL, NULL, 'ROW'
/*
size_with_current_compression_setting(KB)	size_with_requested_compression_setting(KB)
2580656										164296

select 2580656 / 1024 / 1024. --2.460937
select 2500936 / 1024 / 1024. --2.384765
*/

--compactar tabela
alter table dbo.tb_dados_fake rebuild partition = all with (data_compression = page);   

--compactar indice
alter index ix_teste on dbo.tb_dados_fake rebuild partition = all with (data_compression = page);  

