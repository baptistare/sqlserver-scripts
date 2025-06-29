--verify duplicated index
select		
			t.name,
			i.name,
			i.type_desc,
			i.index_id,
			COL_NAME(t.object_id,ic.column_id) as column_name,
			ic.key_ordinal,
			ic.is_included_column,
			ty.name as data_type,
			c.max_length,
			i.is_primary_key,
			c.is_identity,
			i.is_unique,
			c.is_nullable,
			i.ignore_dup_key,
			i.is_unique_constraint,
			i.is_disabled,
			i.is_hypothetical,
			i.allow_row_locks,
			i.allow_page_locks
from		sys.tables t	
inner join	sys.indexes i
	on		t.object_id = i.object_id
inner join	sys.index_columns ic
	on		i.object_id = ic.object_id
	and		i.index_id = ic.index_id
inner join	sys.columns c
	on		ic.object_id = c.object_id
	and		ic.column_id = c.column_id
inner join	sys.types ty
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		1 = 1 
	--and		ic.is_included_column = 0
order by	t.name, i.index_id, ic.key_ordinal--1249
/*
ACCESS_TOKEN (2,3) drop 3
ATIVIDADE (40,45) drop 40
ATRIBUTO_VALOR (2,3) drop 2,3
CLIENTE_IDIOMA (1,2) drop 2
CLIENTE_LICENCA (2,4,17) drop 2,4
CLIENTE_LICENCA_ATIVIDADE_TIPO (1,2) drop 2
CLIENTE_LICENCA_IMPORTACAO_TIPO (1,2) drop 2
CLIENTE_LICENCA_TEMA (1,2) drop 2
COMPETICAO (17,27)----- drop 17
COMPETICAO_MATERIAL_COMPLEMENTAR (1,2) drop 2
COMPETICAO_SKILL_CONSOLIDADO (1,2) drop 2
EMAIL_CAMPO (1,2) drop 2
EMAIL_TIPO_VARIAVEL (1,2) drop 2
ENTIDADE_ATRIBUTO (8,10)* drop 10 CONFIRMAR 
ENTIDADE_GRUPO (2,3)*---MANTER OS 2 USADOS CONFIRMAR
ENVIO_EMAIL (1,13)-----MANTER OS 2 USADOS CONFIRMAR
GRUPO (9,14 | 13,14) refazer index 14, com as chaves do 13, mas mantendo include do 14, drop 13
IMPORTACAO_GRUPO (1,11)* manter os 2
IMPORTACAO_ROTULO (1,2) drop 2
IMPORTACAO_USUARIO_CLIENT_APPLICATION (1,2) manter CONFIRMAR
INTEGRACAO (2,3) drop 3
INTEGRACAO_PLATAFORMA_CAMPO (1,2,3) drop 2,3
INTEGRACAO_PLATAFORMA_CRITERIO (1,2) drop 2
INTEGRACAO_PLATAFORMA_TIPO (1,2) drop 2
NOTIFICACAO (2,3) drop 3
PERFIL_JOGO_TRILHA (7,11) drop 11
PLANO_ATIVIDADE_TIPO (1,2) drop 2
PLANO_IMPORTACAO_TIPO (1,2) drop 2
PLANO_TEMA (1,2) drop 2
PONTUACAO_USUARIO_POR_COMPETICAO (14,30)-----drop 14, mas alterar 30 com includes 14
RODADA_RECORRENTE_CRITERIO (2,3) drop 2,3 sem uso
SKILL_CONSOLE_CONSOLIDADO (1,2) drop 2
TENTATIVA_CONFIGURACAO (1,2) manter 2 apesar da chave duplicada
USUARIO (18,40,44) todos usados, mas manter indice 18, com includes dos indices 40 e 44
*/

/*
ACCESS_TOKEN (2,3) drop 3
DROP INDEX [IX_AccessToken_UsuarioId_ClientId_ClientApplicationId_DeviceId] on [dbo].[ACCESS_TOKEN]

ATIVIDADE (40,45) drop 40
DROP INDEX [IX_Atividade_ClienteId] on [dbo].[ATIVIDADE]

ATRIBUTO_VALOR (2,3) drop 2,3
DROP INDEX [IX_AtributoValor_Guid] on [dbo].[ATRIBUTO_VALOR]
DROP INDEX [IX_AtributoGrupo_Guid] on [dbo].[ATRIBUTO_VALOR]

CLIENTE_IDIOMA (1,2) drop 2
DROP INDEX [IX_ID_CLIENTE] on [dbo].[CLIENTE_IDIOMA]

CLIENTE_LICENCA (2,4,17) drop 2,4
DROP INDEX [IX_ID_CLIENTE] on [dbo].[CLIENTE_LICENCA]
DROP INDEX [UQ_ClienteLicenca_Cliente_Status] on [dbo].[CLIENTE_LICENCA]

CLIENTE_LICENCA_ATIVIDADE_TIPO (1,2) drop 2
DROP INDEX [IX_ID_LICENCA_ID_CLIENTE_ID_PLANO] on [dbo].[CLIENTE_LICENCA_ATIVIDADE_TIPO]

CLIENTE_LICENCA_IMPORTACAO_TIPO (1,2) drop 2
DROP INDEX [IX_ID_LICENCA_ID_CLIENTE_ID_PLANO] on [dbo].[CLIENTE_LICENCA_IMPORTACAO_TIPO]

CLIENTE_LICENCA_TEMA (1,2) drop 2
DROP INDEX [IX_ID_LICENCA_ID_CLIENTE_ID_PLANO] on [dbo].[CLIENTE_LICENCA_TEMA]

COMPETICAO (17,27)----- drop 17
DROP INDEX [DTS001_COMPETICAO_03082021] on [dbo].[COMPETICAO]

COMPETICAO_MATERIAL_COMPLEMENTAR (1,2) drop 2
DROP INDEX [UQ_CompeticaoMaterialComplementar_1] on [dbo].[COMPETICAO_MATERIAL_COMPLEMENTAR]

COMPETICAO_SKILL_CONSOLIDADO (1,2) drop 2
DROP INDEX [IX_ID_SKILL_ID_CLIENTE] on [dbo].[COMPETICAO_SKILL_CONSOLIDADO]

EMAIL_CAMPO (1,2) drop 2
DROP INDEX [IX_ID_EMAIL_ID_CLIENTE] on [dbo].[EMAIL_CAMPO]

EMAIL_TIPO_VARIAVEL (1,2) drop 2
DROP INDEX [IX_EmailTipo_EmailTipoID] on [dbo].[EMAIL_TIPO_VARIAVEL]

IMPORTACAO_ROTULO (1,2) drop 2
DROP INDEX [IX_ID_IMPORTACAO_ID_CLIENTE] on [dbo].[IMPORTACAO_ROTULO]

INTEGRACAO (2,3) drop 3
DROP INDEX [IX_ID_PLATAFORMA] on [dbo].[INTEGRACAO]

INTEGRACAO_PLATAFORMA_CAMPO (1,2,3) drop 2,3
DROP INDEX [IX_ID_PLATAFORMA] on [dbo].[INTEGRACAO_PLATAFORMA_CAMPO]
DROP INDEX [IX_ID_PLATAFORMA_ID_TIPO] on [dbo].[INTEGRACAO_PLATAFORMA_CAMPO]

INTEGRACAO_PLATAFORMA_CRITERIO (1,2) drop 2
DROP INDEX [IX_ID_PLATAFORMA] on [dbo].[INTEGRACAO_PLATAFORMA_CRITERIO]

INTEGRACAO_PLATAFORMA_TIPO (1,2) drop 2
DROP INDEX [IX_ID_PLATAFORMA] on [dbo].[INTEGRACAO_PLATAFORMA_TIPO]

NOTIFICACAO (2,3) drop 3
DROP INDEX [IX_Notificacao_UsuarioID_ClienteID] on [dbo].[NOTIFICACAO]

PERFIL_JOGO_TRILHA (7,11) drop 11
DROP INDEX [idx_PERFIL_JOGO_TRILHA] on [dbo].[PERFIL_JOGO_TRILHA]

PLANO_ATIVIDADE_TIPO (1,2) drop 2
DROP INDEX [IX_ID_PLANO] on [dbo].[PLANO_ATIVIDADE_TIPO]

PLANO_IMPORTACAO_TIPO (1,2) drop 2
DROP INDEX [IX_ID_PLANO] on [dbo].[PLANO_IMPORTACAO_TIPO]

PLANO_TEMA (1,2) drop 2
DROP INDEX [IX_ID_PLANO] on [dbo].[PLANO_TEMA]

RODADA_RECORRENTE_CRITERIO (2,3) drop 2,3 sem uso
DROP INDEX [IX_ID_PLATAFORMA] on [dbo].[RODADA_RECORRENTE_CRITERIO]
DROP INDEX [IX_ID_PLATAFORMA_ID_CRITERIO] on [dbo].[RODADA_RECORRENTE_CRITERIO]

SKILL_CONSOLE_CONSOLIDADO (1,2) drop 2
DROP INDEX [IX_ID_SKILL_ID_CLIENTE] on [dbo].[SKILL_CONSOLE_CONSOLIDADO]

IMPORTACAO_GRUPO (1,11)* manter os 2
TENTATIVA_CONFIGURACAO (1,2) manter 2 apesar da chave duplicada

PONTUACAO_USUARIO_POR_COMPETICAO (14,30)-----drop 14, mas alterar 30 com includes 14
DROP INDEX [IX_PontuacaoUsuarioPorCompeticao_ClienteId] ON [dbo].[PONTUACAO_USUARIO_POR_COMPETICAO]
--testar  DROP_EXISTING = OFF
CREATE NONCLUSTERED INDEX [DTS_PONTUACAO_USUARIO_POR_COMPETICAO_ID_CLIENTE_ID_COMPETICAO_98D01] ON [dbo].[PONTUACAO_USUARIO_POR_COMPETICAO]
(
	[ID_CLIENTE] ASC,
	[ID_COMPETICAO] ASC
)
INCLUDE([NU_PONTUACAO],[NU_BONUS],[NU_PONTUACAO_MAXIMA_COMPETICAO]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO


USUARIO (18,40,44) todos usados, mas manter indice 18, com includes dos indices 40 e 44

DROP INDEX [DTS_USUARIO_CLIENTE_COVER] ON [dbo].[USUARIO]
DROP INDEX [DTS001_USUARIO_09182021] ON [dbo].[USUARIO]

CREATE NONCLUSTERED INDEX [IX_Usuario_ClienteId_Status] ON [dbo].[USUARIO]
(
	[ID_CLIENTE] ASC,
	[FL_STATUS] DESC
)
INCLUDE([ID],[TX_NOME_COMPLETO],[TX_LOGIN],[TX_EMAIL],[FL_PADRAO],[ID_PERFIL_ADM],[DT_CADASTRO],[COD_EXTERNO],[ID_IDIOMA], [ID_USUARIO_SUPERIOR],[ID_DEPARTAMENTO],[ID_CARGO],[ID_AREA],[DT_NASCIMENTO],[TX_SEXO],[TX_TELEFONE],[TX_CELULAR],[TX_SENHA],[FL_BLOQUEADO],[DT_ULTIMA_ATUALIZACAO],[DT_ULTIMA_SENHA],[TX_MOBILE_REGISTRATION_ID],[TX_MOBILE_SO],[TX_CPF],[FL_MOSTRAR_AJUDA],[FL_EMAIL_CONFIRMADO],[CRIADO_POR],[ATUALIZADO_POR],[VERSAO_REGISTRO],[TX_CIDADE],[TX_ESTADO],[TX_SENHA_INICIAL],[FL_CRIADO_VIA_AUTOCADASTRO],[DT_ULTIMA_ATUALIZACAO_CADASTRAL],[FL_TERMO_ACEITE_ACEITO],[TX_IMAGEM])
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]


GRUPO (9,14 | 13,14) refazer index 14, com as chaves do 13, mas mantendo include do 14, drop 13
DROP INDEX [IX_GRUPO_CLIENTEID_STATUS] ON [dbo].[GRUPO]
DROP INDEX [DTS_GRUPO_ID_CLIENTE_152A4] ON [dbo].[GRUPO]

CREATE NONCLUSTERED INDEX [DTS_GRUPO_ID_CLIENTE_152A4] ON [dbo].[GRUPO]
(
	[ID_CLIENTE] ASC,
	[FL_STATUS] ASC
)
INCLUDE([TX_NOME],[TX_DESCRICAO],[TX_LOGO],[TX_COR],[TX_COR2],[TX_IMAGEM_BACKGROUND],[ID_GRUPO_PAI],[FL_STATUS],[COD_EXTERNO],[DT_CADASTRO],[DT_ULTIMA_ATUALIZACAO],[CRIADO_POR],[ATUALIZADO_POR],[VERSAO_REGISTRO],[FL_PADRAO],[FL_PERMITIR_ACESSO_APENAS_GESTOR_NA_TRILHA]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO


ENTIDADE_ATRIBUTO (8,10)* drop 10 CONFIRMAR 
DROP INDEX [IX_EntidadeAtributo_AtributoId_ClienteId_EntidadeId_EntidadeTipoId_Id] ON [dbo].[ENTIDADE_ATRIBUTO]


ENTIDADE_GRUPO (2,3)*---MANTER OS 2 USADOS CONFIRMAR
ENVIO_EMAIL (1,13)-----MANTER OS 2 USADOS CONFIRMAR
IMPORTACAO_USUARIO_CLIENT_APPLICATION (1,2) manter CONFIRMAR
*/


select		t.name															,
			case when i.name is null then 'Heap' else i.name end as name	,
			i.type															,
			i.index_id														,
			dius.user_seeks													,
			dius.user_scans													,
			dius.user_lookups												,
			dius.user_updates												,
			dius.last_user_seek												,
			dius.last_user_scan												,
			dius.last_user_lookup											,
			dius.last_user_update											,
			dius.system_seeks												,
			dius.system_scans												,
			dius.system_lookups												,
			dius.system_updates												,
			dius.last_system_seek											,
			dius.last_system_scan											,
			dius.last_system_lookup											,
			dius.last_system_update	
--select		distinct i.name
from		sys.tables t
join		sys.indexes i
	on		t.object_id = i.object_id
join		sys.dm_db_index_usage_stats dius
	on		i.object_id = dius.object_id
	and		i.index_id = dius.index_id
where		1 = 1
	and		dius.database_id = db_id()
	and		i.index_id in (2,3)
	and		t.object_id = OBJECT_ID('prod_my_engage_autosservico.dbo.ACCESS_TOKEN')
--order by	dius.user_seeks

select		
			t.name,
			i.name,
			i.type_desc,
			i.index_id,
			COL_NAME(t.object_id,ic.column_id) as column_name,
			ic.key_ordinal,
			ic.is_included_column,
			ty.name as data_type,
			c.max_length,
			i.is_primary_key,
			c.is_identity,
			i.is_unique,
			c.is_nullable,
			i.ignore_dup_key,
			i.is_unique_constraint,
			i.is_disabled,
			i.is_hypothetical,
			i.allow_row_locks,
			i.allow_page_locks
from		sys.tables t	
inner join	sys.indexes i
	on		t.object_id = i.object_id
inner join	sys.index_columns ic
	on		i.object_id = ic.object_id
	and		i.index_id = ic.index_id
inner join	sys.columns c
	on		ic.object_id = c.object_id
	and		ic.column_id = c.column_id
inner join	sys.types ty
	on		c.system_type_id = ty.system_type_id
	and		c.user_type_id = ty.user_type_id 
where		1 = 1
	and		t.object_id = OBJECT_ID('prod_my_engage_autosservico.dbo.ACCESS_TOKEN')
	and		i.index_id in (2,3)
order by	i.index_id, ic.key_ordinal
