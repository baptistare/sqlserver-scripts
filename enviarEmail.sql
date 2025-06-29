declare @strsubject varchar(100);
declare @tableHTML  nvarchar(max);
declare @profile_name varchar(100);		
declare @dataProcessamento datetime;

begin try
	--obter nome perfil padrao
	select @profile_name = p.name from msdb.dbo.sysmail_profile p inner join msdb.dbo.sysmail_principalprofile pp on p.profile_id = pp.profile_id where pp.is_default = 1;

	--assunto email
	select @strsubject = 'ACOMPANHAMENTO VENDA DIÁRIA DAS LOJAS POR HORA';

	--variavel conteudo email
	select @tableHTML = '';

	--formatar informacoes de tamanhos bases de dados
	select @tableHTML = @tableHTML + '' +
						N'<H3><b>Acompanhamento de Vendas Diárias das Lojas por Hora:</b></H3>' +					
						N'<br><br>' +	
						N'<H3><b>Vendas 2016 (R$)</b></H2>' +
						N'<table border="1"  width="100%" style="font-size:12px">' +
						N'<th align="left">DataVenda</th>' +
						N'<th align="left">Loja</th>' +
						N'<th align="left">8h-9h</th>' +
						N'<th align="left">9h-10h</th>' +
						N'<th align="left">10h-11h</th>' +
						N'<th align="left">11h-12h</th>' +
						N'<th align="left">12h-13h</th>' +
						N'<th align="left">13h-14h</th>' +
						N'<th align="left">14h-15h</th>' +
						N'<th align="left">15h-16h</th>' +
						N'<th align="left">16h-17h</th>' +
						N'<th align="left">17h-18h</th>' +
						N'<th align="left">18h-19h</th>' +
						N'<th align="left">19h-20h</th>' +
						N'<th align="left">20h-21h</th>' +
						N'<th align="left">21h-22h</th>' +
						N'<th align="left">22h-23h</th>' +
						N'<th align="left">23h-24h</th>' +
						N'<th align="left">Acum</th>' +
						N'<th align="left">Acum N-1</th>' +
						N'<th align="left">N-N1</th>' +
						N'<th align="left">% N/N1</th>' +
						CAST ( (	SELECT	td = [DataVenda], '',
											td = [Loja], '',
											td = cast([8h-9h] as int), '',
											td = cast([9h-10h] as int), '',
											td = cast([10h-11h] as int), '',
											td = cast([11h-12h] as int), '',
											td = cast([12h-13h] as int), '',
											td = cast([13h-14h] as int), '',
											td = cast([14h-15h] as int), '',
											td = cast([15h-16h] as int), '',
											td = cast([16h-17h] as int), '',
											td = cast([17h-18h] as int), '',
											td = cast([18h-19h] as int), '',
											td = cast([19h-20h] as int), '',
											td = cast([20h-21h] as int), '',
											td = cast([21h-22h] as int), '',
											td = cast([22h-23h] as int), '',
											td = cast([23h-24h] as int), '',
											td = cast([ACUM] as int), '',
											td = cast([ACUM N-1] as int), '',
											td = cast([N-N1] as int), '',
											td = [% N/N1]
									FROM	SGF_MIS.dbo.tb_dashboard_vendas_online_ano_corrente 
									FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX) 
							) + N'</table>';

				EXEC msdb.dbo.sp_send_dbmail
				@from_address='sqlreport@fnac.com.br',
				@recipients='',
				@blind_copy_recipients = 'reinaldo.baptista-ext@fnac.com.br',
				@subject = @strsubject,
				@body = @tableHTML,
				@body_format = 'HTML' ,
				@profile_name= @profile_name;
end try
begin catch
	declare @ErrorMessage nvarchar(2048)
	declare @ErrorNumber int
	declare @ErrorLine int
	declare @ErrorState int
	declare @ErrorSeverity int
	declare @ErrorProcedure nvarchar(126)

	select 'Erro ao enviar email.';

	select	@ErrorMessage = ERROR_MESSAGE(),
	@ErrorNumber = ERROR_NUMBER(),
	@ErrorSeverity = ERROR_SEVERITY(),
	@ErrorState = ERROR_STATE(),
	@ErrorLine = ERROR_LINE(),
	@ErrorProcedure = ERROR_PROCEDURE();
				
	raiserror (@ErrorMessage, @ErrorNumber, @ErrorSeverity,@ErrorState,@ErrorLine,@ErrorProcedure);	
end catch
