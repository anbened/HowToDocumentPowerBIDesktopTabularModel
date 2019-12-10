
/* 0. SETUP 
	- check the PORT used by PBI Desktop
	- check the GUID as DB Name
*/

/* 1. Create linked server to Power BI Desktop */
EXEC master.dbo.sp_addlinkedserver
   @server = N'CubeLinkedServer',
   @srvproduct=N'',
   @provider=N'MSOLAP',
   @datasrc=N'localhost:62325', /* <-- change the PORT */
   @catalog=N'3b85a18d-9de2-488b-8883-1d1a8eafb1b3' /* <-- change the DB Name */

	/*
	-- Drop linked server
	EXEC master.dbo.sp_dropserver @server=N'CubeLinkedServer'
	*/


/* 2. Setup procedures to retrieve info from PBI Desktop */

		/* Template:
		CREATE PROCEDURE [dbo].[up_***name***]
		AS
		  SELECT *
		  FROM OPENQUERY(
			CubeLinkedServer,
			'
	
			***query***

			')
		GO
		*/

USE tempdb
GO

CREATE PROCEDURE [dbo].[up_AllModels]
AS
  SELECT *
  FROM OPENQUERY(
	CubeLinkedServer,
    '
	
	SELECT 
		[CATALOG_NAME] AS SSAS_Database_Name,
		[CUBE_NAME] AS Cube_or_Perspective_Name,
		[CUBE_CAPTION] AS Cube_or_Perspective_Caption,
		[CUBE_TYPE] AS Cube_Type,
		[BASE_CUBE_NAME] AS Base_Cube
	FROM 
		$SYSTEM.MDSCHEMA_CUBES
	WHERE
		CUBE_SOURCE=1
	ORDER BY CUBE_NAME

	')
GO

CREATE PROCEDURE [dbo].[up_CatalogInfo]
AS
  SELECT *
  FROM OPENQUERY(
	CubeLinkedServer,
    '
	select 
		[CATALOG_NAME], 
		[date_modified], 
		[compatibility_level], 
		[type], 
		[version]
	from $SYSTEM.DBSCHEMA_CATALOGS

	')
GO

CREATE PROCEDURE [dbo].[up_Dimensions]
AS
  SELECT *
  FROM OPENQUERY(
	CubeLinkedServer,
    '
	
	SELECT 
		[CATALOG_NAME] as [DATABASE Name],
		[CUBE_NAME] AS [CUBE],
		[DIMENSION_NAME] AS Dimension_Name,
		[DIMENSION_UNIQUE_NAME] AS Dimension_Real_Name,
		[DIMENSION_CAPTION] AS [DIMENSION],
		[DIMENSION_CARDINALITY] AS [Count],
		[DIMENSION_IS_VISIBLE] AS Dimension_Visible
	FROM $system.MDSchema_Dimensions
	WHERE 
		[CUBE_NAME] =''Model''
	AND DIMENSION_CAPTION <> ''Measures''
	ORDER BY DIMENSION_CAPTION

	')
GO

CREATE PROCEDURE [dbo].[up_Attributes]
AS
  SELECT *
  FROM OPENQUERY(
	CubeLinkedServer,
    '
	
	SELECT 
		[CATALOG_NAME] as [DATABASE],
		[CUBE_NAME] AS [CUBE],
		[DIMENSION_UNIQUE_NAME] AS [DIMENSION],
		[HIERARCHY_DISPLAY_FOLDER] AS [FOLDER],
		[HIERARCHY_CAPTION] AS [DIMENSION ATTRIBUTE],
		[HIERARCHY_IS_VISIBLE] AS [VISIBLE]
	 FROM $system.MDSchema_hierarchies
	WHERE CUBE_NAME  =''Model''
	AND HIERARCHY_ORIGIN=2
	ORDER BY [DIMENSION_UNIQUE_NAME]

	')
GO

CREATE PROCEDURE [dbo].[up_AttributesKeyColumns]
AS
  SELECT *
  FROM OPENQUERY(
	CubeLinkedServer,
    '
	
	SELECT 
		[CATALOG_NAME] as [DATABASE],
		[CUBE_NAME] AS [CUBE],
		[DIMENSION_UNIQUE_NAME] AS [DIMENSION],
		LEVEL_CAPTION AS [ATTRIBUTE],
		[LEVEL_NAME_SQL_COLUMN_NAME] AS [ATTRIBUTE_NAME_SQL_COLUMN_NAME],
		[LEVEL_KEY_SQL_COLUMN_NAME] AS [ATTRIBUTE_KEY_SQL_COLUMN_NAME]
	FROM $system.MDSchema_levels
	WHERE CUBE_NAME  =''Model''
	AND level_origin=2
	AND LEVEL_NAME <> ''(All)''
	order by [DIMENSION_UNIQUE_NAME]

	')
GO

CREATE PROCEDURE [dbo].[up_Measures]
AS
  SELECT *
  FROM OPENQUERY(
	CubeLinkedServer,
    '
	
	SELECT
		[CATALOG_NAME] AS SSAS_Database_Name,
		[CUBE_NAME] AS Cube_or_Perspective_Name,
		[MEASUREGROUP_NAME] AS MeasureGroup_Name,
		[MEASURE_NAME] AS Measure_Name,
		[MEASURE_Caption] AS Measure_Caption,
		[MEASURE_IS_VISIBLE] AS Dimension_Visible,
		[MEASURE_AGGREGATOR] AS Measure_Aggregator,
		[DEFAULT_FORMAT_STRING] AS [Format_String],
		[EXPRESSION] AS Calculated_Measure_Expression
	FROM
		$SYSTEM.MDSCHEMA_MEASURES
	WHERE CUBE_NAME  =''Model''
	ORDER BY
		[MEASURE_NAME]

	')
GO

CREATE PROCEDURE [dbo].[up_CalculatedMeasures]
AS
  SELECT *
  FROM OPENQUERY(
	CubeLinkedServer,
    '
	
	SELECT 
		[MEMBER_UNIQUE_NAME] AS [CALCULATED_MEASURE],
		[MEMBER_CAPTION] AS [CAPTION],
		[EXPRESSION]
	FROM $system.MDSCHEMA_MEMBERS
	WHERE CUBE_NAME =''Model''
	AND [MEMBER_TYPE]=4 --MDMEMBER_TYPE_FORMULA

	')
GO

CREATE PROCEDURE [dbo].[up_DimensionFactBusMatrix]
AS
  SELECT *
  FROM OPENQUERY(
	CubeLinkedServer,
    '
	
	SELECT  [MEASUREGROUP_NAME] AS [MEASUREGROUP],
			[MEASUREGROUP_CARDINALITY],
			[DIMENSION_UNIQUE_NAME] AS [DIM],
			[DIMENSION_GRANULARITY] AS [DIM_KEY],
			[DIMENSION_CARDINALITY],
			[DIMENSION_IS_VISIBLE] AS [IS_VISIBLE],
			[DIMENSION_IS_FACT_DIMENSION] AS [IS_FACT_DIM]
	FROM $system.MDSCHEMA_MEASUREGROUP_DIMENSIONS
	WHERE [CUBE_NAME] =''Model''

	')
GO

/* 3. Execute procedures */
exec [dbo].[up_AllModels]
exec [dbo].[up_CatalogInfo]
exec [dbo].[up_Dimensions]
exec [dbo].[up_Attributes]
exec [dbo].[up_AttributesKeyColumns]
exec [dbo].[up_Measures]
exec [dbo].[up_DimensionFactBusMatrix]
GO
