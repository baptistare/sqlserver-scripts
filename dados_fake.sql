select		
			top 10000000
			ABS(CHECKSUM(NEWID())) / 100000,
			ISNULL(CONVERT(Date, GETDATE() - (CheckSUM(NEWID()) / 1000000)), GetDate()),
			ISNULL(ABS(CONVERT(Numeric(18,2), (CheckSUM(NEWID()) / 1000000.5))),0),
			replicate('A',32),
			replicate('B',64),
			replicate('C',128)						
from		sys.all_columns a1
cross join	sys.all_columns a2



