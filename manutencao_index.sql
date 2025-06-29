       EXECUTE dbo.IndexOptimize
		@Databases = 'BDTPEDI',
		@FragmentationLow = NULL,
		@FragmentationMedium = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
		@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
		@FragmentationLevel1 = 5,
		@FragmentationLevel2 = 30,
		@Indexes = 'BDTPEDI.dbo.TRANS_DATA',
		@UpdateStatistics = 'ALL',
		@OnlyModifiedStatistics = 'Y',
		@MaxDOP = 4,
		@LogToTable = 'Y'

       EXECUTE dbo.IndexOptimize
		@Databases = 'BDTPEDI',
		@FragmentationLow = NULL,
		@FragmentationMedium = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
		@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
		@FragmentationLevel1 = 5,
		@FragmentationLevel2 = 30,
		@Indexes = 'BDTPEDI.dbo.WORKFLOW_LINKAGE',
		@UpdateStatistics = 'ALL',
		@OnlyModifiedStatistics = 'Y',
		@MaxDOP = 4,
		@LogToTable = 'Y'

       EXECUTE dbo.IndexOptimize
		@Databases = 'BDTPEDI',
		@FragmentationLow = NULL,
		@FragmentationMedium = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
		@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
		@FragmentationLevel1 = 5,
		@FragmentationLevel2 = 30,
		@Indexes = 'BDTPEDI.dbo.WORKFLOW_CONTEXT',
		@UpdateStatistics = 'ALL',
		@OnlyModifiedStatistics = 'Y',
		@MaxDOP = 4,
		@LogToTable = 'Y'

