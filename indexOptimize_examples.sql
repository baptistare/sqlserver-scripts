

--only index
EXECUTE dts_tools.dbo.IndexOptimize	@Databases = 'prod_my_engage_autosservico',
									@FragmentationLow = NULL,
									@FragmentationMedium = NULL,
									@FragmentationHigh = NULL,
									@UpdateStatistics = 'COLUMNS',
									@OnlyModifiedStatistics = 'Y',
									@StatisticsSample = 100,
									@LogToTable = 'N',
									@TimeLimit = 7200, /*(2h) */
									@Execute = 'N'

--only stats
EXECUTE dts_tools.dbo.IndexOptimize	@Databases = 'prod_my_engage_autosservico',
									@FragmentationLow = NULL,
									@FragmentationMedium = NULL,
									@FragmentationHigh = NULL,
									@UpdateStatistics = 'COLUMNS',
									@OnlyModifiedStatistics = 'Y',
									@StatisticsSample = 100,
									@LogToTable = 'N',
									@TimeLimit = 7200, /*(2h) */
									@Execute = 'N'


