select top 1000 sys.fn_PhysLocFormatter(%%%physloc%) as Physical_RID, * from tb_teste

-----------------------------------------------------------------------------------------------------------------------------------------------------------
Page Prefetch
-----------------------------------------------------------------------------------------------------------------------------------------------------------

- otimização de IO
- utilizado pelo operador Loop Join (withUnorderedPrefetch ou withOrderedPrefetch)
- SQL envia várias requisições de IO de modo async
- Utiliza stripe diks com mais eficiência enviada requisições de IO em paralelo
- Segura lock nas linhas lidas por mais tempo

queryTraceOn 2340 --desabilitar o batchsort
queryTraceOn 8744 --desabilitar o prefetch

se SQL ler menos de 25 linhas o prefetch não será habilitado

