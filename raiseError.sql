		/*
		select
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_STATE() AS ErrorState,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;		
		*/

		declare @ErrorMessage nvarchar(2048)
		declare @ErrorNumber int
		declare @ErrorLine int
		declare @ErrorState int
		declare @ErrorSeverity int
		declare @ErrorProcedure nvarchar(126)

		select	@ErrorMessage = ERROR_MESSAGE(),
				@ErrorNumber = ERROR_NUMBER(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE(),
				@ErrorLine = ERROR_LINE(),
				@ErrorProcedure = ERROR_PROCEDURE();
				
		raiserror (@ErrorMessage, @ErrorNumber, @ErrorSeverity,@ErrorState,@ErrorLine,@ErrorProcedure);	

		select	ERROR_NUMBER() as ErrorNumber,
				ERROR_SEVERITY() as ErrorSeverity,
				ERROR_STATE() as ErrorState,
				ERROR_PROCEDURE() as ErrorProcedure,
				ERROR_LINE() as ErrorLine,
				ERROR_MESSAGE() as ErrorMessage;