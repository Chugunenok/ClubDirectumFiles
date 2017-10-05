USE [DIR_TEST]
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetPickReqValueCodeByID]    Script Date: 07/08/2016 09:10:56 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetPickReqValueCodeByID]
(
	@ReqCode varchar(255),
	@ReqValueID varchar(1),
	@ToReturn varchar(5)
)
RETURNS varchar(255)
AS
BEGIN
	DECLARE @Code varchar(255)
	declare @PriznValuesString varchar(3000)
	set @PriznValuesString = (
		select
			PriznValues
		from
			MBRecvAn
		where
			MBRecvAn.[Type] = 'П'
			and Kod = @ReqCode)

	
	
	with PriznValuesTable(Code,LocID,ID,valleft) as 
	(
	select top 1
		convert(varchar(max),'')
		, convert(varchar(max),'')
		, convert(varchar(max),'')
		, convert(varchar(max),@PriznValuesString + ';')
	union all
	select 
		convert(varchar(max), substring(valleft, 3, charindex('|@', valleft)-3))
		, convert(varchar(max), substring(valleft, charindex('|@', valleft) + 2, charindex(';', valleft)-2-charindex('|@', valleft)))
		, convert(varchar(max), substring(valleft, 1, 1))
		, stuff(valleft, 1, charindex(';', valleft), '')
	from 
		PriznValuesTable 
	where 
		valleft!=''
	)

	select @Code = case @ToReturn when 'LocID' then LocID else Code end from PriznValuesTable where ID = @ReqValueID

	 

	RETURN @Code

END
  
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetShortFIOFromFIO]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
  CREATE FUNCTION [dbo].[UDL_GetShortFIOFromFIO](@FIO varchar(200))
  RETURNS varchar(50)
  AS
    BEGIN
    DECLARE @FInitials varchar(50);
    
    SET @FIO=RTRIM(LTRIM(@FIO));
    DECLARE @FamiliaLen int = CHARINDEX(' ',@FIO,1);
    IF(@FamiliaLen = 0) set @FamiliaLen = LEN(@FIO);
    SET @FInitials=LEFT(@FIO,@FamiliaLen);
    WHILE CHARINDEX(' ',@FIO,1)>0 BEGIN
      SET @FIO=LTRIM(RIGHT(@FIO,LEN(@FIO)-CHARINDEX(' ',@FIO,1)));
      SET @FInitials+=LEFT(@FIO,1) + '.';
    END
  
  RETURN @FInitials
END
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDev]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDev](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	
		select *
		from
		(	select
			(select Xini.ValuePar from Xini where Xini.NamePar = 'PlatformVersion') as PlatformVesion
			,'*' as SystemMask
			,'true' as ForMainServer
			,'false' as ImitationMode
			,(select dbo.UDL_GetXMLDevGrFunc(@date_filter)) as GrFunctions
			,(select dbo.UDL_GetXMLDevFunc(@date_filter)) as Functions
			,(select dbo.UDL_GetXMLDevConstants(@date_filter)) as Constants
			,(select dbo.UDL_GetXMLDevModules(@date_filter)) as Modules
			,(select dbo.UDL_GetXMLDevViewers(@date_filter)) as Viewers
			,(select dbo.UDL_GetXMLDevScripts(@date_filter)) as Scripts
			,(select dbo.UDL_GetXMLDevReports(@date_filter)) as Reports
			,(select dbo.UDL_GetXMLDevWFBlockGr(@date_filter)) as WorkflowBlockGroups
			,(select dbo.UDL_GetXMLDevWFBlocks(@date_filter)) as WorkflowBlocks
			,(select dbo.UDL_GetXMLDevLocalization(@date_filter)) as LocalizedStrings
			,(select dbo.UDL_GetXMLDevDocRequisites(@date_filter)) as EDocRequisites
			,(select dbo.UDL_GetXMLDevRefRequisites(@date_filter)) as RefRequisites
			,(select dbo.UDL_GetXMLDevReferences(@date_filter)) as RefTypes
			,(select dbo.UDL_GetXMLDevDocuments(@date_filter)) as EDCardTypes
		) tmp
		where 
			GrFunctions is not null
			or Functions is not null
			or Constants is not null
			or Modules is not null
			or Viewers is not null
			or Scripts is not null
			or Reports is not null
			or WorkflowBlockGroups is not null
			or WorkflowBlocks is not null
			or LocalizedStrings is not null
			or EDocRequisites is not null
			or RefRequisites is not null
			or RefTypes is not null 
			or EDCardTypes is not null	
		for xml raw('Components'), type
	)
	return @Xml

END
   
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevConstants]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevConstants](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBConstLst.Const as KeyValue
					,mainMBConstLst.Nazn as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBConstLst.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBConstLst.Const as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBConstLst.Nazn as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBConstServerStatus' as Code
											,	case MBConstLst.IsGlob 
													when 'Д' then 'Реплицировать'
													when 'Н' then 'Не реплицировать'
													else '' 
												end as Value
											,	case MBConstLst.IsGlob 
													when 'Д' then 'SYSRES_SYSCOMP.CONST_SERVER_STATUS_REPLICATE'
													when 'Н' then 'SYSRES_SYSCOMP.CONST_SERVER_STATUS_DONT_REPLICATE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBConstFirmStatus' as Code
											,	case MBConstLst.IsAllFirm 
													when 'Д' then 'Общая'
													when 'Н' then 'Индивидуальная'
													else '' 
												end as Value
											,	case MBConstLst.IsAllFirm 
													when 'Д' then 'SYSRES_SYSCOMP.CONST_FIRM_STATUS_COMMON'
													when 'Н' then 'SYSRES_SYSCOMP.CONST_FIRM_STATUS_INDIVIDUAL'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'LastUpdate' as Code, convert(varchar(30),MBConstLst.LastUpd,104) + ' ' + convert(varchar(30),MBConstLst.LastUpd,108)  as Value for xml raw('Requisite'), type)
							from 
								MBConstLst
							where
								MBConstLst.XRecID = mainMBConstLst.XRecID
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainMBConstLst.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					MBConstLst mainMBConstLst
				where
					mainMBConstLst.LastUpd >= @date_filter
				for xml raw('Constants'), type
	)
	return @Xml

END
    
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevDocRequisites]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevDocRequisites](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBRecvEDoc.Kod as KeyValue
					,mainMBRecvEDoc.Name as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBRecvEDoc.XRecID as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBRecvEDoc.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBRecvEDoc.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefReqFieldName' as [Requisite!1!Code], cast(MBRecvEDoc.FldName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBRefReqSection' as Code
											,	case MBRecvEDoc.Razd 
													when 'Ш' then 'Карточка'
													when 'Т' then 'Таблица'
													when 'С' then 'Таблица2'
													when 'Р' then 'Таблица3'
													when 'О' then 'Таблица4'
													when 'Н' then 'Таблица5'
													when 'М' then 'Таблица6'
													else '' 
												end as Value
											,	case MBRecvEDoc.Razd 
													when 'Ш' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_CARD'
													when 'Т' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE'
													when 'С' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE2'
													when 'Р' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE3'
													when 'О' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE4'
													when 'Н' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE5'
													when 'М' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE6'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefReqStored' as Code
											,	case MBRecvEDoc.Stored 
													when 'Д' then 'Да'
													when 'Н' then 'Нет'
													else '' 
												end as Value
											,	case MBRecvEDoc.Stored 
													when 'Д' then 'SYSRES_COMMON.YES_CONST'
													when 'Н' then 'SYSRES_COMMON.NO_CONST'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefReqType' as Code
											,	case MBRecvEDoc.[Type] 
													when 'Д' then 'Дата'
													when 'Ч' then 'Дробное число'
													when 'П' then 'Признак'
													when 'А' then 'Справочник'
													when 'С' then 'Строка'
													when 'М' then 'Текст'
													when 'Ц' then 'Целое число'													
													else '' 
												end as Value
											,	case MBRecvEDoc.[Type] 
													when 'Д' then 'SYSRES_SYSCOMP.DATA_TYPE_DATE'
													when 'Ч' then 'SYSRES_SYSCOMP.DATA_TYPE_FLOAT'
													when 'П' then 'SYSRES_SYSCOMP.DATA_TYPE_PICK'
													when 'А' then 'SYSRES_SYSCOMP.DATA_TYPE_REFERENCE'
													when 'С' then 'SYSRES_SYSCOMP.DATA_TYPE_STRING'
													when 'М' then 'SYSRES_SYSCOMP.DATA_TYPE_TEXT'
													when 'Ц' then 'SYSRES_SYSCOMP.DATA_TYPE_INTEGER'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefReqFormat' as Code
											,	case MBRecvEDoc.Align 
													when 'Е' then 'Без разрядов'
													when 'Л' then 'Влево'
													when 'П' then 'Вправо'
													when 'Д' then 'ДД.ММ.ГГГГ'
													when 'Ц' then 'ДД.ММ.ГГГГ ЧЧ:НН:СС'
													when 'Т' then 'По разрядам'
													else '' 
												end as Value
											,	case MBRecvEDoc.Align 
													when 'Е' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_WITHOUT_UNIT'
													when 'Л' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_LEFT'
													when 'П' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_RIGHT'
													when 'Д' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_DATE_FULL'
													when 'Ц' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_DATE_TIME'
													when 'Т' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_BY_UNIT'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefReqLength' as Code, MBRecvEDoc.[Len] as Value  for xml raw('Requisite'), type)
								, (select 'ISBRefReqPrecision' as Code, MBRecvEDoc.Toch as Value  for xml raw('Requisite'), type)
								, (select 'ISBRefReqReference' as Code, ltrim(MBVidAn.Kod) as Value  for xml raw('Requisite'), type)
								, (select 'ISBRefReqView' as Code, ltrim(MBVidAnView.Kod) as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBRefReqTokens' as [Requisite!1!Code], cast(MBRecvEDoc.PriznValues as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ExistFld' as Code
											,	case MBRecvEDoc.Stored 
													when 'Е' then 'Да'
													when 'Н' then 'Нет'
													else '' 
												end as Value
											,	case MBRecvEDoc.Stored 
													when 'Е' then 'SYSRES_COMMON.YES_CONST'
													when 'Н' then 'SYSRES_COMMON.NO_CONST'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'LastUpdate' as Code, convert(varchar(30),MBRecvEDoc.LastUpd,104) + ' ' + convert(varchar(30),MBRecvEDoc.LastUpd,108)  as Value for xml raw('Requisite'), type)
							from 
								MBRecvEDoc MBRecvEDoc
								left join MBVidAn MBVidAn on MBVidAn.Vid = MBRecvEDoc.VidAn
								left join MBVidAnView MBVidAnView on MBVidAnView.XRecID = MBRecvEDoc.ViewID
							where 
								MBRecvEDoc.XRecID = mainMBRecvEDoc.XRecID 
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainMBRecvEDoc.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					MBRecvEDoc mainMBRecvEDoc
				where
					mainMBRecvEDoc.LastUpd >= @date_filter
				for xml raw('EDocRequisites'), type
	)
	return @Xml

END
     
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevDocuments]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevDocuments](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBEDocType.Kod as KeyValue
					,mainMBEDocType.Name as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBEDocType.TypeID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBEDocType.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeNameLocalizeID' as [Requisite!1!Code], cast(MBEDocType.NameLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBEDocType.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'Состояние' as Code
											,	case MBEDocType.Sost 
													when 'Д' then 'Действующий'
													when 'З' then 'Закрытый'
													else '' 
												end as Value
											,	case MBEDocType.Sost 
													when 'Д' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_MASCULINE'
													when 'З' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_FEMININE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'LastUpdate' as Code, convert(varchar(30),MBEDocType.LastUpd,104) + ' ' + convert(varchar(30),MBEDocType.LastUpd,108)  as Value for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeNameInSingular' as [Requisite!1!Code], cast(MBEDocType.NameEd as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeNameSngLocalizeID' as [Requisite!1!Code], cast(MBEDocType.NameEdLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBEDocTypeNumerationMethod' as Code
											,	case MBEDocType.SposNum 
													when 'А' then 'Автоматическая строгая'
													when 'Н' then 'Автоматическая не строгая'
													when 'И' then 'Из словаря'
													when 'Р' then 'Ручная'
													else '' 
												end as Value
											,	case MBEDocType.SposNum 
													when 'А' then 'SYSRES_SYSCOMP.NUMERATION_AUTO_STRONG'
													when 'Н' then 'SYSRES_SYSCOMP.NUMERATION_AUTO_NOT_STRONG'
													when 'И' then 'SYSRES_SYSCOMP.NUMERATION_FROM_DICTONARY'
													when 'Р' then 'SYSRES_SYSCOMP.NUMERATION_MANUAL'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeEventText' as [Requisite!1!Code], cast(cast(MBEDocType.Exprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeComment' as [Requisite!1!Code], cast(cast(MBEDocType.Comment as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeAddParams' as [Requisite!1!Code], cast(cast(MBEDocType.AddParams as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBEDocType
							where 
								MBEDocType.TypeID = mainMBEDocType.TypeID
							for xml raw('Requisites'), type
						)
						--Детальные разделы
						,(select
							(select --Реквизиты
								(select 'ИД' as Code, MBEDocTypeRecv.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBEDocTypeRecv.TypeID as Value  for xml raw('Requisite'), type) 
								, (select 'ISBEDocTypeReqNumber' as Code, MBEDocTypeRecv.NumRecv as Value  for xml raw('Requisite'), type)
								, (select 'ISBEDocTypeReqSection' as Code
									,	case MBEDocTypeRecv.Razd 
											when 'Ш' then 'Карточка'
											when 'Т' then 'Таблица'
											when 'С' then 'Таблица2'
											when 'Р' then 'Таблица3'
											when 'О' then 'Таблица4'
											when 'Н' then 'Таблица5'
											when 'М' then 'Таблица6'
											else '' 
										end as Value
									,	case MBEDocTypeRecv.Razd 
											when 'Ш' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_CARD'
											when 'Т' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE'
											when 'С' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE2'
											when 'Р' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE3'
											when 'О' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE4'
											when 'Н' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE5'
											when 'М' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE6'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeReqCode' as [Requisite!1!Code], cast(MBEDocTypeRecv.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeReqDescription' as [Requisite!1!Code], cast(MBEDocTypeRecv.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeReqDescLocalizeID' as [Requisite!1!Code], cast(MBEDocTypeRecv.NameLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBEDocTypeReqIsRequired' as Code
									,	case MBEDocTypeRecv.[IsNull]
											when 'Д' then 'Да'
											when 'Н' then 'Нет'
											else '' 
										end as Value
									,	case MBEDocTypeRecv.[IsNull] 
											when 'Д' then 'SYSRES_COMMON.YES_CONST'
											when 'Н' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBEDocTypeReqIsLeading' as Code
									,	case MBEDocTypeRecv.IsHigh 
											when 'Д' then 'Да'
											when 'Н' then 'Нет'
											else '' 
										end as Value
									,	case MBEDocTypeRecv.IsHigh 
											when 'Д' then 'SYSRES_COMMON.YES_CONST'
											when 'Н' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeReqOnChange' as [Requisite!1!Code], cast(cast(MBEDocTypeRecv.Exprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeReqOnSelect' as [Requisite!1!Code], cast(cast(MBEDocTypeRecv.InpExprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBEDocTypeRecv 
							where 
								MBEDocTypeRecv.TypeID = mainMBEDocType.TypeID
								and MBEDocTypeRecv.Razd <> 'К'
							order by
								MBEDocTypeRecv.Razd desc, MBEDocTypeRecv.XRecID asc
							for xml raw('Requisites'), type, root('DetailDataSet1'))
										
							,(select --Действия
								(select 'ИД' as Code, MBEDocTypeRecv.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBEDocTypeRecv.TypeID as Value  for xml raw('Requisite'), type) 
								, (select 'НомСтр' as Code, MBEDocTypeRecv.NumRecv as Value  for xml raw('Requisite'), type)
								, (select 'ISBEDocTypeActSection' as Code, 'Действия' as Value ,	'SYSRES_SYSCOMP.CARD_ACTION_SECTION_ACTIONS' as ValueLocalizeID for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeActCode' as [Requisite!1!Code], cast(MBEDocTypeRecv.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeActDescription' as [Requisite!1!Code], cast(MBEDocTypeRecv.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeActDescLocalizeID' as [Requisite!1!Code], cast(MBEDocTypeRecv.NameLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeActOnExecute' as [Requisite!1!Code], cast(cast(MBEDocTypeRecv.Exprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBEDocTypeRecv 
							where 
								MBEDocTypeRecv.TypeID = mainMBEDocType.TypeID
								and MBEDocTypeRecv.Razd = 'К'
							order by
								MBEDocTypeRecv.XRecID 
							for xml raw('Requisites'), type, root('DetailDataSet2'))

							,(select --Представления
								(select 'ИД' as Code, MBEDocTypeView.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBEDocTypeView.TypeID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeViewCode' as [Requisite!1!Code], cast(MBEDocTypeView.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeViewName' as [Requisite!1!Code], cast(MBEDocTypeView.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeViewNameLocalizeID' as [Requisite!1!Code], cast(MBEDocTypeView.NameLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBEDocTypeViewIsMain' as Code
									,	case MBEDocTypeView.Main 
											when 'Д' then 'Да'
											when 'Н' then 'Нет'
											else '' 
										end as Value
									,	case MBEDocTypeView.Main 
											when 'Д' then 'SYSRES_COMMON.YES_CONST'
											when 'Н' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeViewComment' as [Requisite!1!Code], cast(cast(MBEDocTypeView.Comment as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBEDocTypeViewCardForm' as [Requisite!1!Code], cast(cast(MBEDocTypeView.Dfm as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBEDocTypeView  
							where 
								MBEDocTypeView.TypeID = mainMBEDocType.TypeID
							order by
								MBEDocTypeView.XRecID 
							for xml raw('Requisites'), type, root('DetailDataSet3'))
						for xml raw('DetailDataSet'), type)
				/*,	(	select
							(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
						from
							XProtokol
						where
							SrcRecID = mainMBEDocType.XRecID
							and DateAct >= @date_filter
							and [Action] <> 'F'
						group by
							HostID, UserID
						for xml raw('ChangeHistory'), type
					)*/
				from
					MBEDocType mainMBEDocType
				where
					mainMBEDocType.LastUpd >= @date_filter
				for xml raw('EDCardTypes'), type
	)
	return @Xml

END
  
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevFunc]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevFunc](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBFunc.FName as KeyValue
					,mainMBFunc.FName as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBFunc.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBFunc.FName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBFunc.FName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBFuncGroup' as Code, MBGrFunc.GrName as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBFuncComment' as [Requisite!1!Code], cast(cast(MBFunc.Comment as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBFuncCategory' as Code
											,	case MBFunc.SysFunc 
													when 'P' then 'Прикладная'
													when 'S' then 'Системная'
													else '' 
												end as Value
											,	case MBFunc.SysFunc 
													when 'P' then 'SYSRES_SYSCOMP.FUNCTION_CATEGORY_USER'
													when 'S' then 'SYSRES_SYSCOMP.FUNCTION_CATEGORY_SYSTEM'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'LastUpdate' as Code, convert(varchar(30),MBFunc.LastUpd,104) + ' ' + convert(varchar(30),MBFunc.LastUpd,108)  as Value for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBFuncText' as [Requisite!1!Code], cast(cast(MBFunc.Txt as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBFuncHelp' as [Requisite!1!Code], cast(cast(MBFunc.Help as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBFunc
								left join MBGrFunc on MBFunc.NGroup = MBGrFunc.Ngroup
							where 
								mainMBFunc.XRecID = MBFunc.XRecID 
							for xml raw('Requisites'), type
						)
					,	(select
							(	select
									(select 'ИД' as Code, MBFuncRecv.XRecID as Value  for xml raw('Requisite'), type)
									, (select 1 as Tag, null as Parent, 'ИДЗапГлавРазд' as [Requisite!1!Code], cast(MBFuncRecv.FName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
									, (select 'НомСтр' as Code, MBFuncRecv.NumPar as Value  for xml raw('Requisite'), type)
									, (select 1 as Tag, null as Parent, 'ISBFuncParamIdent' as [Requisite!1!Code], cast(MBFuncRecv.Ident as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
									, (select 1 as Tag, null as Parent, 'ISBFuncParamName' as [Requisite!1!Code], cast(MBFuncRecv.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
									, (select 1 as Tag, null as Parent, 'ISBFuncParamDefValue' as [Requisite!1!Code], cast(MBFuncRecv.ValueDef as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
									, (select 'ISBFuncParamType' as Code
												, case MBFuncRecv.Type 
														when 'V' then 'Вариантный' 
														when 'Д' then 'Дата'
														when 'Ч' then 'Дробное число'
														when 'L' then 'Логический'
														when 'С' then 'Строка'
														when 'Ц' then 'Целое число'
														else '' 
													end as Value, 
													case MBFuncRecv.Type 
														when 'V' then 'SYSRES_SYSCOMP.DATA_TYPE_VARIANT' 
														when 'Д' then 'SYSRES_SYSCOMP.DATA_TYPE_DATE'
														when 'Ч' then 'SYSRES_SYSCOMP.DATA_TYPE_FLOAT'
														when 'L' then 'SYSRES_SYSCOMP.DATA_TYPE_BOOLEAN'
														when 'С' then 'SYSRES_SYSCOMP.DATA_TYPE_STRING'
														when 'Ц' then 'SYSRES_SYSCOMP.DATA_TYPE_INTEGER'
														else '' 
													end as ValueLocalizeID 
													for xml raw('Requisite'), type)
								from 
									MBFuncRecv
									join MBFunc on MBFunc.FName = MBFuncRecv.FName
								where 
									mainMBFunc.FName = MBFunc.FName
								for xml raw('Requisites'), type
							) 
							for xml raw('DetailDataSet1'), type, root('DetailDataSet')
						)
				/*,	(	select
							(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
						from
							XProtokol
						where
							SrcRecID = mainMBFunc.XRecID
							and DateAct >= @date_filter
							and [Action] <> 'F'
						group by
							HostID, UserID
						for xml raw('ChangeHistory'), type
					)*/
				from
					MBFunc mainMBFunc
				where
					mainMBFunc.LastUpd >= @date_filter
				for xml raw('Functions'), type
	)
	return @Xml

END
  
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevGrFunc]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevGrFunc](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	
		
		select
			mainMBGrFunc.GrName as KeyValue
			,mainMBGrFunc.GrName as DisplayValue
			,0 as CompHash
			,'False' as AutoAdded
			,	(	select
						(select 'ИД' as Code, MBGrFunc.NGroup as Value  for xml raw('Requisite'), type) 
						, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBGrFunc.GrName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
						, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBGrFunc.GrName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
						, (select 'ISBFuncGroupNumber' as Code, MBGrFunc.XrecID as Value  for xml raw('Requisite'), type)
						, (select 'Состояние' as Code
											,	case MBGrFunc.Sost 
													when 'Д' then 'Действующая'
													when 'З' then 'Закрытая'
													else '' 
												end as Value
											,	case MBGrFunc.Sost
													when 'Д' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_MASCULINE'
													when 'З' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_FEMININE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
						, (select 1 as Tag, null as Parent, 'ISBFuncGroupComment' as [Requisite!1!Code], cast(cast(MBGrFunc.Comment as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
						, (select 'LastUpdate' as Code, convert(varchar(30),MBGrFunc.LastUpd,104) + ' ' + convert(varchar(30),MBGrFunc.LastUpd,108)  as Value for xml raw('Requisite'), type)
					from 
						MBGrFunc
					where 
						mainMBGrFunc.XRecID = MBGrFunc.XRecID 
					for xml raw('Requisites'), type
				)
		/*,	(	select
					(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
				from
					XProtokol
				where
					SrcRecID = mainMBGrFunc.XRecID
					and DateAct >= @date_filter
					and [Action] <> 'F'
				group by
					HostID, UserID
				for xml raw('ChangeHistory'), type
			)*/ 
		from
			MBGrFunc mainMBGrFunc
		where
			mainMBGrFunc.LastUpd >= @date_filter
		for xml raw('GrFunctions'), type
	)
	return @Xml

END
   
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevLocalization]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevLocalization](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainSBLocalizedData.Code as KeyValue
					,mainSBLocalizedData.Code as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(select
							(select
								(select 'ИД' as Code, SBLocalizedData.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ИДЗапГлавРазд' as [Requisite!1!Code], cast(SBLocalizedData.Code as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBLanguage' as [Requisite!1!Code], cast(SBLocalizedData.LangCode as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBString' as [Requisite!1!Code], cast(cast(SBLocalizedData.String as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBDescription' as [Requisite!1!Code], cast(SBLocalizedData.[Description] as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBGroupCode' as [Requisite!1!Code], cast(SBLocalizedData.GroupCode as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'LastUpdate' as Code, convert(varchar(30),SBLocalizedData.LastUpd,104) + ' ' + convert(varchar(30),SBLocalizedData.LastUpd,108)  as Value for xml raw('Requisite'), type)
							from 
								SBLocalizedData 
							where 
								SBLocalizedData.Code = mainSBLocalizedData.Code 
							for xml raw('Requisites'), type
							)
						for xml raw('DetailDataSet1'), type, root('DetailDataSet'))
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainSBLocalizedData.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					SBLocalizedData mainSBLocalizedData
				where
					mainSBLocalizedData.LastUpd >= @date_filter
				group by
					mainSBLocalizedData.Code, mainSBLocalizedData.XRecID 
				for xml raw('LocalizedStrings'), type
	)
	return @Xml

END

  
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevModules]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevModules](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBRegUnit.Name as KeyValue
					,mainMBRegUnit.Name as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBRegUnit.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBRegUnit.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBRegUnit.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'Состояние' as Code
											,	case MBRegUnit.Sost 
													when 'Д' then 'Действующий'
													when 'З' then 'Закрытый'
													else '' 
												end as Value
											,	case MBRegUnit.Sost 
													when 'Д' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_MASCULINE'
													when 'З' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_FEMININE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'LastUpdate' as Code, convert(varchar(30),MBRegUnit.LastUpd,104) + ' ' + convert(varchar(30),MBRegUnit.LastUpd,108)  as Value for xml raw('Requisite'), type)
							from 
								MBRegUnit
							where 
								MBRegUnit.XRecID = mainMBRegUnit.XRecID 
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainMBRegUnit.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					MBRegUnit mainMBRegUnit
				where
					mainMBRegUnit.LastUpd >= @date_filter
				for xml raw('Modules'), type
	)
	return @Xml

END
    
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevReferences]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevReferences](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBVidAn.Kod as KeyValue
					,mainMBVidAn.Name as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBVidAn.Vid as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBVidAn.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeNameLocalizeID' as [Requisite!1!Code], cast(MBVidAn.NameLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBVidAn.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'Состояние' as Code
											,	case MBVidAn.Sost 
													when 'Д' then 'Действующий'
													when 'З' then 'Закрытый'
													else '' 
												end as Value
											,	case MBVidAn.Sost 
													when 'Д' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_MASCULINE'
													when 'З' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_FEMININE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'LastUpdate' as Code, convert(varchar(30),MBVidAn.LastUpd,104) + ' ' + convert(varchar(30),MBVidAn.LastUpd,108)  as Value for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeNameInSingular' as [Requisite!1!Code], cast(MBVidAn.NameEd as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeNameInSingLocalizeID' as [Requisite!1!Code], cast(MBVidAn.NameEdLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBRefTypeNumerationMethod' as Code
											,	case MBVidAn.SposNum 
													when 'А' then 'Автоматическая строгая'
													when 'Н' then 'Автоматическая не строгая'
													when 'И' then 'Из словаря'
													when 'Р' then 'Ручная'
													else '' 
												end as Value
											,	case MBVidAn.SposNum 
													when 'А' then 'SYSRES_SYSCOMP.NUMERATION_AUTO_STRONG'
													when 'Н' then 'SYSRES_SYSCOMP.NUMERATION_AUTO_NOT_STRONG'
													when 'И' then 'SYSRES_SYSCOMP.NUMERATION_FROM_DICTONARY'
													when 'Р' then 'SYSRES_SYSCOMP.NUMERATION_MANUAL'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefTypeDisplayReqName' as Code
											,	case MBVidAn.TypeConcept 
													when 'Н' then 'Наименование'
													when 'К' then 'Код'
													else '' 
												end as Value
											,	case MBVidAn.TypeConcept 
													when 'Н' then 'SYSRES_SYSCOMP.RECORD_NAME_REQUISITE_NAME'
													when 'К' then 'SYSRES_SYSCOMP.RECORD_NAME_REQUISITE_CODE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefTypeMainLeadingRef' as Code, (select ltrim(tmp.Kod) from MBVidAn tmp where tmp.Vid = MBVidAn.HighLvl) as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBRefTypeEventText' as [Requisite!1!Code], cast(cast(MBVidAn.Exprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeComment' as [Requisite!1!Code], cast(cast(MBVidAn.Comment as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeAddParams' as [Requisite!1!Code], cast(cast(MBVidAn.AddParams as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeCommonSettings' as [Requisite!1!Code], cast(MBVidAn.CommonSettings as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBIsNameLong' as Code
										,	case MBVidAn.IsNameLong 
												when 'Y' then 'Yes'
												when 'N' then 'No'
												else '' 
											end as Value
										,	case MBVidAn.IsNameLong 
												when 'Y' then 'SYSRES_COMMON.YES_CONST'
												when 'N' then 'SYSRES_COMMON.NO_CONST'
												else '' 
											end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBIsNameUnique' as Code
										,	case MBVidAn.IsNameUnique 
												when 'Y' then 'Yes'
												when 'N' then 'No'
												else '' 
											end as Value
										,	case MBVidAn.IsNameUnique 
												when 'Y' then 'SYSRES_COMMON.YES_CONST'
												when 'N' then 'SYSRES_COMMON.NO_CONST'
												else '' 
											end as ValueLocalizeID for xml raw('Requisite'), type)
							from 
								MBVidAn
							where 
								MBVidAn.Vid = mainMBVidAn.Vid
							for xml raw('Requisites'), type
						)
						--Детальные разделы
						,(select
							(select --Реквизиты
								(select 'ИД' as Code, MBVidAnRecv.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBVidAnRecv.Vid as Value  for xml raw('Requisite'), type) 
								, (select 'ISBRefTypeReqNumber' as Code, MBVidAnRecv.NumRecv as Value  for xml raw('Requisite'), type)
								, (select 'ISBRefTypeReqSection' as Code
									,	case MBVidAnRecv.Razd 
											when 'Ш' then 'Карточка'
											when 'Т' then 'Таблица'
											when 'С' then 'Таблица2'
											when 'Р' then 'Таблица3'
											when 'О' then 'Таблица4'
											when 'Н' then 'Таблица5'
											when 'М' then 'Таблица6'
											when 'Q' then 'Таблица7'
											when 'W' then 'Таблица8'
											when 'U' then 'Таблица9'
											when 'R' then 'Таблица10'
											when 'I' then 'Таблица11'
											when 'Y' then 'Таблица12'
											else '' 
										end as Value
									,	case MBVidAnRecv.Razd 
											when 'Ш' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_CARD'
											when 'Т' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE'
											when 'С' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE2'
											when 'Р' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE3'
											when 'О' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE4'
											when 'Н' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE5'
											when 'М' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE6'
											when 'Q' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE7'
											when 'W' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE8'
											when 'U' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE9'
											when 'R' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE10'
											when 'I' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE11'
											when 'Y' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE12'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBRefTypeReqCode' as [Requisite!1!Code], cast(MBVidAnRecv.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeReqDescription' as [Requisite!1!Code], cast(MBVidAnRecv.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeReqDescLocalizeID' as [Requisite!1!Code], cast(MBVidAnRecv.NameLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBRefTypeReqIsRequired' as Code
									,	case MBVidAnRecv.[IsNull]
											when 'Д' then 'Да'
											when 'Н' then 'Нет'
											else '' 
										end as Value
									,	case MBVidAnRecv.[IsNull] 
											when 'Д' then 'SYSRES_COMMON.YES_CONST'
											when 'Н' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefTypeReqIsFilter' as Code
									,	case MBVidAnRecv.IsKlass 
											when 'Д' then 'Да'
											when 'Н' then 'Нет'
											else '' 
										end as Value
									,	case MBVidAnRecv.IsKlass 
											when 'Д' then 'SYSRES_COMMON.YES_CONST'
											when 'Н' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefTypeReqIsLeading' as Code
									,	case MBVidAnRecv.IsHigh 
											when 'Д' then 'Да'
											when 'Н' then 'Нет'
											else '' 
										end as Value
									,	case MBVidAnRecv.IsHigh 
											when 'Д' then 'SYSRES_COMMON.YES_CONST'
											when 'Н' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefTypeReqIsControl' as Code
									,	case MBVidAnRecv.IsSources 
											when 'Д' then 'Да'
											when 'Н' then 'Нет'
											else '' 
										end as Value
									,	case MBVidAnRecv.IsSources 
											when 'Д' then 'SYSRES_COMMON.YES_CONST'
											when 'Н' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)


								, (select 1 as Tag, null as Parent, 'ISBRefTypeReqOnChange' as [Requisite!1!Code], cast(cast(MBVidAnRecv.Exprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeReqOnSelect' as [Requisite!1!Code], cast(cast(MBVidAnRecv.InpExprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBVidAnRecv 
							where 
								MBVidAnRecv.Vid = mainMBVidAn.Vid
								and MBVidAnRecv.Razd <> 'К'
							order by
								MBVidAnRecv.Razd desc, MBVidAnRecv.XRecID asc
							for xml raw('Requisites'), type, root('DetailDataSet1'))
										
							,(select --Действия
								(select 'ИД' as Code, MBVidAnRecv.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBVidAnRecv.Vid as Value  for xml raw('Requisite'), type) 
								, (select 'НомСтр' as Code, MBVidAnRecv.NumRecv as Value  for xml raw('Requisite'), type)
								, (select 'ISBRefTypeActSection' as Code, 'Действия' as Value ,	'SYSRES_SYSCOMP.CARD_ACTION_SECTION_ACTIONS' as ValueLocalizeID for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBRefTypeActCode' as [Requisite!1!Code], cast(MBVidAnRecv.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeActDescription' as [Requisite!1!Code], cast(MBVidAnRecv.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeActDescLocalizeID' as [Requisite!1!Code], cast(MBVidAnRecv.NameLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeActOnExecute' as [Requisite!1!Code], cast(cast(MBVidAnRecv.Exprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBVidAnRecv 
							where 
								MBVidAnRecv.Vid = mainMBVidAn.Vid
								and MBVidAnRecv.Razd = 'К'
							order by
								MBVidAnRecv.XRecID 
							for xml raw('Requisites'), type, root('DetailDataSet2'))

							,(select --Представления
								(select 'ИД' as Code, MBVidAnView.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBVidAnView.Vid as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBRefTypeViewCode' as [Requisite!1!Code], cast(MBVidAnView.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeViewName' as [Requisite!1!Code], cast(MBVidAnView.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeViewNameLocalizeID' as [Requisite!1!Code], cast(MBVidAnView.NameLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBRefTypeViewIsMain' as Code
									,	case MBVidAnView.Main 
											when 'Д' then 'Да'
											when 'Н' then 'Нет'
											else '' 
										end as Value
									,	case MBVidAnView.Main 
											when 'Д' then 'SYSRES_COMMON.YES_CONST'
											when 'Н' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeViewComment' as [Requisite!1!Code], cast(cast(MBVidAnView.Comment as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefTypeViewCardForm' as [Requisite!1!Code], cast(cast(MBVidAnView.Dfm as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBVidAnView 
							where 
								MBVidAnView.Vid = mainMBVidAn.Vid
							order by
								MBVidAnView.XRecID 
							for xml raw('Requisites'), type, root('DetailDataSet3'))

							,(select --Иерархии
								(select 'ИД' as Code, MBVidAnHierarchy.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBVidAnHierarchy.Vid as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBHierarchyName' as [Requisite!1!Code], cast(MBVidAnHierarchy.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBHierarchyTitle' as [Requisite!1!Code], cast(MBVidAnHierarchy.Title as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBHierarchyTitleLocalizeID' as [Requisite!1!Code], cast(MBVidAnHierarchy.TitleLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
							from 
								MBVidAnHierarchy 
							where 
								MBVidAnHierarchy.Vid = mainMBVidAn.Vid
							order by
								MBVidAnHierarchy.XRecID 
							for xml raw('Requisites'), type, root('DetailDataSet4'))

							,(select --Реквизиты иерархий
								(select 'ИД' as Code, MBVidAnHierarchyRecv.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBVidAnHierarchyRecv.Vid as Value  for xml raw('Requisite'), type)
								, (select 'ISBParentRefTypeIdCode' as Code, (select tmp.Kod from MBVidAn tmp where tmp.Vid = MBVidAnHierarchyRecv.RefTypeID) as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBHierarchyName' as [Requisite!1!Code], cast(MBVidAnHierarchyRecv.HierarchyName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBLinkedRefTypeIdCode' as Code, (select tmp.Kod from MBVidAn tmp where tmp.Vid = MBVidAnHierarchyRecv.LinkedRefTypeID) as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBLinkedReqName' as [Requisite!1!Code], cast(MBVidAnHierarchyRecv.LinkedReqName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBOrderNumber' as Code, MBVidAnHierarchyRecv.OrderNumber as Value  for xml raw('Requisite'), type)
							from 
								MBVidAnHierarchyRecv  
							where 
								MBVidAnHierarchyRecv.Vid = mainMBVidAn.Vid
							order by
								MBVidAnHierarchyRecv.XRecID 
							for xml raw('Requisites'), type, root('DetailDataSet5'))

							,(select --Иерархии по представлениям
								(select 'ИД' as Code, MBVidAnHierarchyView.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 'ИДЗапГлавРазд' as Code, MBVidAnHierarchyView.Vid as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'ISBRefTypeViewCode' as [Requisite!1!Code], cast(MBVidAnHierarchyView.ViewCode as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBHierarchyName' as [Requisite!1!Code], cast(MBVidAnHierarchyView.HierarchyName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBMainHierarchyForView' as Code
									,	case MBVidAnHierarchyView.IsMain 
											when 'Y' then 'Yes'
											when 'N' then 'No'
											else '' 
										end as Value
									,	case MBVidAnHierarchyView.IsMain 
											when 'Y' then 'SYSRES_COMMON.YES_CONST'
											when 'N' then 'SYSRES_COMMON.NO_CONST'
											else '' 
										end as ValueLocalizeID for xml raw('Requisite'), type)
							from 
								MBVidAnHierarchyView  
							where 
								MBVidAnHierarchyView.Vid = mainMBVidAn.Vid
							order by
								MBVidAnHierarchyView.XRecID 
							for xml raw('Requisites'), type, root('DetailDataSet6'))

						for xml raw('DetailDataSet'), type)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainMBVidAn.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					MBVidAn mainMBVidAn
				where
					mainMBVidAn.LastUpd >= @date_filter
				for xml raw('RefTypes'), type
	)
	return @Xml

END
   
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevRefRequisites]    Script Date: 07/08/2016 09:10:57 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevRefRequisites](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBRecvAn.Kod as KeyValue
					,mainMBRecvAn.Name as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBRecvAn.XRecID as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBRecvAn.Kod as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBRecvAn.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ISBRefReqFieldName' as [Requisite!1!Code], cast(MBRecvAn.FldName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ISBRefReqSection' as Code
											,	case MBRecvAn.Razd 
													when 'Ш' then 'Карточка'
													when 'Т' then 'Таблица'
													when 'С' then 'Таблица2'
													when 'Р' then 'Таблица3'
													when 'О' then 'Таблица4'
													when 'Н' then 'Таблица5'
													when 'М' then 'Таблица6'
													when 'Q' then 'Таблица7'
													when 'W' then 'Таблица8'
													when 'U' then 'Таблица9'
													when 'R' then 'Таблица10'
													when 'I' then 'Таблица11'
													when 'Y' then 'Таблица12'
													else '' 
												end as Value
											,	case MBRecvAn.Razd 
													when 'Ш' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_CARD'
													when 'Т' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE'
													when 'С' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE2'
													when 'Р' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE3'
													when 'О' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE4'
													when 'Н' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE5'
													when 'М' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE6'
													when 'Q' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE7'
													when 'W' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE8'
													when 'U' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE9'
													when 'R' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE10'
													when 'I' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE11'
													when 'Y' then 'SYSRES_SYSCOMP.REQUISITE_SECTION_TABLE12'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefReqStored' as Code
											,	case MBRecvAn.Stored 
													when 'Д' then 'Да'
													when 'Н' then 'Нет'
													else '' 
												end as Value
											,	case MBRecvAn.Stored 
													when 'Д' then 'SYSRES_COMMON.YES_CONST'
													when 'Н' then 'SYSRES_COMMON.NO_CONST'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefReqType' as Code
											,	case MBRecvAn.[Type] 
													when 'Д' then 'Дата'
													when 'Ч' then 'Дробное число'
													when 'П' then 'Признак'
													when 'А' then 'Справочник'
													when 'С' then 'Строка'
													when 'М' then 'Текст'
													when 'Ц' then 'Целое число'													
													else '' 
												end as Value
											,	case MBRecvAn.[Type] 
													when 'Д' then 'SYSRES_SYSCOMP.DATA_TYPE_DATE'
													when 'Ч' then 'SYSRES_SYSCOMP.DATA_TYPE_FLOAT'
													when 'П' then 'SYSRES_SYSCOMP.DATA_TYPE_PICK'
													when 'А' then 'SYSRES_SYSCOMP.DATA_TYPE_REFERENCE'
													when 'С' then 'SYSRES_SYSCOMP.DATA_TYPE_STRING'
													when 'М' then 'SYSRES_SYSCOMP.DATA_TYPE_TEXT'
													when 'Ц' then 'SYSRES_SYSCOMP.DATA_TYPE_INTEGER'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefReqFormat' as Code
											,	case MBRecvAn.Align 
													when 'Е' then 'Без разрядов'
													when 'Л' then 'Влево'
													when 'П' then 'Вправо'
													when 'Д' then 'ДД.ММ.ГГГГ'
													when 'Ц' then 'ДД.ММ.ГГГГ ЧЧ:НН:СС'
													when 'Т' then 'По разрядам'
													else '' 
												end as Value
											,	case MBRecvAn.Align 
													when 'Е' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_WITHOUT_UNIT'
													when 'Л' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_LEFT'
													when 'П' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_RIGHT'
													when 'Д' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_DATE_FULL'
													when 'Ц' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_DATE_TIME'
													when 'Т' then 'SYSRES_SYSCOMP.REQUISITE_FORMAT_BY_UNIT'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'ISBRefReqLength' as Code, MBRecvAn.[Len] as Value  for xml raw('Requisite'), type)
								, (select 'ISBRefReqPrecision' as Code, MBRecvAn.Toch as Value  for xml raw('Requisite'), type)
								, (select 'ISBRefReqReference' as Code, ltrim(MBVidAn.Kod) as Value  for xml raw('Requisite'), type)
								, (select 'ISBRefReqView' as Code, ltrim(MBVidAnView.Kod) as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'ISBRefReqTokens' as [Requisite!1!Code], cast(MBRecvAn.PriznValues as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ExistFld' as Code
											,	case MBRecvAn.Stored 
													when 'Е' then 'Да'
													when 'Н' then 'Нет'
													else '' 
												end as Value
											,	case MBRecvAn.Stored 
													when 'Е' then 'SYSRES_COMMON.YES_CONST'
													when 'Н' then 'SYSRES_COMMON.NO_CONST'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'LastUpdate' as Code, convert(varchar(30),MBRecvAn.LastUpd,104) + ' ' + convert(varchar(30),MBRecvAn.LastUpd,108)  as Value for xml raw('Requisite'), type)
							from 
								MBRecvAn MBRecvAn
								left join MBVidAn MBVidAn on MBVidAn.Vid = MBRecvAn.VidAn
								left join MBVidAnView MBVidAnView on MBVidAnView.XRecID = MBRecvAn.ViewID
							where 
								MBRecvAn.XRecID = mainMBRecvAn.XRecID 
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainMBRecvAn.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					MBRecvAn mainMBRecvAn
				where
					mainMBRecvAn.LastUpd >= @date_filter 
				for xml raw('RefRequisites'), type
	)
	return @Xml

END
   
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevReports]    Script Date: 07/08/2016 09:10:58 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevReports](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBReports.NameRpt as KeyValue
					,mainMBReports.[Description] as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBReports.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBReports.NameRpt as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Фильтр' as [Requisite!1!Code], cast(substring(MBReports.Filter,1,1) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Код приложения' as [Requisite!1!Code], cast(MBReports.Viewer as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'NeedExecuteScriptOnDesignTemplate' as Code
											,	case MBReports.NeedExecuteScript 
													when 'Д' then 'Да'
													when 'Н' then 'Нет'
													else '' 
												end as Value
											,	case MBReports.NeedExecuteScript 
													when 'Д' then 'SYSRES_COMMON.YES_CONST'
													when 'Н' then 'SYSRES_COMMON.NO_CONST'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Модуль' as [Requisite!1!Code], cast(MBReports.CRegUnit as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ИДМодуля' as Code, MBReports.RegUnit as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Шаблон' as [Requisite!1!Code], cast(MBReports.Report as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Расчет' as [Requisite!1!Code], cast(cast(MBReports.Exprn as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Примечание' as [Requisite!1!Code], cast(cast(MBReports.Comment as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'Состояние' as Code
											,	case MBReports.Sost 
													when 'Д' then 'Действующий'
													when 'З' then 'Закрытый'
													else '' 
												end as Value
											,	case MBReports.Sost 
													when 'Д' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_MASCULINE'
													when 'З' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_FEMININE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Тип' as [Requisite!1!Code], cast(MBReports.TypeRpt as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ИД базового отчета' as Code, MBReports.BaseRpt as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Описание' as [Requisite!1!Code], cast(MBReports.[Description] as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ИД локализации описания' as [Requisite!1!Code], cast(MBReports.DescLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)				 
								, (select 'LastUpdate' as Code, convert(varchar(30),MBReports.LastUpd,104) + ' ' + convert(varchar(30),MBReports.LastUpd,108)  as Value for xml raw('Requisite'), type)
							from 
								MBReports
							where 
								MBReports.XRecID = mainMBReports.XRecID 
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainMBReports.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					MBReports mainMBReports
					outer apply (select top 1 DateAct, UserID from XProtokol where [Action] <> 'F' and SrcRecID = mainMBReports.XRecID order by DateAct desc) as XProt
				where
					mainMBReports.TypeRpt <> 'Function'
					and (XProt.DateAct >= @date_filter or XProt.DateAct is null)
				for xml raw('Reports'), type
	)
	return @Xml

END 
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevScripts]    Script Date: 07/08/2016 09:10:58 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevScripts](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBReports.NameRpt as KeyValue
					,mainMBReports.[Description] as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBReports.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBReports.NameRpt as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Модуль' as [Requisite!1!Code], cast(MBReports.CRegUnit as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ИДМодуля' as Code, MBReports.RegUnit as Value  for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Текст' as [Requisite!1!Code], cast(MBReports.Report as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Примечание' as [Requisite!1!Code], cast(cast(MBReports.Comment as varchar(max)) as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'Состояние' as Code
											,	case MBReports.Sost 
													when 'Д' then 'Действующий'
													when 'З' then 'Закрытый'
													else '' 
												end as Value
											,	case MBReports.Sost 
													when 'Д' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_MASCULINE'
													when 'З' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_FEMININE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Тип' as [Requisite!1!Code], cast(MBReports.TypeRpt as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Описание' as [Requisite!1!Code], cast(MBReports.[Description] as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ИД локализации описания' as [Requisite!1!Code], cast(MBReports.DescLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)				 
								, (select 'LastUpdate' as Code, convert(varchar(30),MBReports.LastUpd,104) + ' ' + convert(varchar(30),MBReports.LastUpd,108)  as Value for xml raw('Requisite'), type)
							from 
								MBReports
							where 
								MBReports.XRecID = mainMBReports.XRecID 
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainMBReports.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					MBReports mainMBReports
					outer apply (select top 1 DateAct, UserID from XProtokol where [Action] <> 'F' and SrcRecID = mainMBReports.XRecID order by DateAct desc) as XProt
				where
					mainMBReports.TypeRpt = 'Function'
					and (XProt.DateAct >= @date_filter or XProt.DateAct is null)
				for xml raw('Scripts'), type 
	)
	return @Xml

END    
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevViewers]    Script Date: 07/08/2016 09:10:58 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevViewers](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainMBRptView.Viewer as KeyValue
					,mainMBRptView.AppName as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, MBRptView.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(MBRptView.Viewer as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(MBRptView.AppName as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Расширение' as [Requisite!1!Code], cast(MBRptView.AppExt as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'ТипРедактора' as Code
											,	case MBRptView.TypeEditor 
													when 'W' then 'Встроенный редактор'
													when 'С' then ''
													when 'E' then 'Microsoft Excel'
													when 'R' then 'Microsoft Word'
													else '' 
												end as Value
											,	case MBRptView.TypeEditor 
													when 'W' then 'SYSRES_SYSCOMP.REPORT_APP_VIEWER_INTERNAL'
													when 'С' then ''
													when 'E' then 'SYSRES_SYSCOMP.REPORT_APP_VIEWER_EXCEL'
													when 'R' then 'SYSRES_SYSCOMP.REPORT_APP_VIEWER_WORD'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'LastUpdate' as Code, convert(varchar(30),MBRptView.LastUpd,104) + ' ' + convert(varchar(30),MBRptView.LastUpd,108)  as Value for xml raw('Requisite'), type)
							from 
								MBRptView
							where 
								MBRptView.XRecID = mainMBRptView.XRecID 
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainMBRptView.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					MBRptView mainMBRptView
				where
					mainMBRptView.LastUpd >= @date_filter
				for xml raw('Viewers'), type
	)
	return @Xml

END    
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevWFBlockGr]    Script Date: 07/08/2016 09:10:58 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevWFBlockGr](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainSBRouteBlockGroup.Name as KeyValue
					,mainSBRouteBlockGroup.Title as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, SBRouteBlockGroup.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(SBRouteBlockGroup.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(SBRouteBlockGroup.Title as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ИД локализации наименования' as [Requisite!1!Code], cast(SBRouteBlockGroup.TitleLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'LastUpdate' as Code, convert(varchar(30),SBRouteBlockGroup.LastUpdate,104) + ' ' + convert(varchar(30),SBRouteBlockGroup.LastUpdate,108)  as Value for xml raw('Requisite'), type)
							from 
								SBRouteBlockGroup
							where 
								SBRouteBlockGroup.XRecID = mainSBRouteBlockGroup.XRecID 
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainSBRouteBlockGroup.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					SBRouteBlockGroup mainSBRouteBlockGroup
				where
					mainSBRouteBlockGroup.LastUpdate >= @date_filter 
				for xml raw('WorkflowBlockGroups'), type
	)
	return @Xml

END  
GO

/****** Object:  UserDefinedFunction [dbo].[UDL_GetXMLDevWFBlocks]    Script Date: 07/08/2016 09:10:58 ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

/*isbl*/ 
CREATE FUNCTION [dbo].[UDL_GetXMLDevWFBlocks](@date_filter datetime)
RETURNS xml
AS
BEGIN

	declare @Xml xml
	
	set @Xml =
	(	select
					mainSBRouteBlock.Name as KeyValue
					,mainSBRouteBlock.Title as DisplayValue
					,0 as CompHash
					,'False' as AutoAdded
					,	(	select
								(select 'ИД' as Code, SBRouteBlock.XRecID as Value  for xml raw('Requisite'), type) 
								, (select 1 as Tag, null as Parent, 'Код' as [Requisite!1!Code], cast(SBRouteBlock.Name as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Наименование' as [Requisite!1!Code], cast(SBRouteBlock.Title as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'ИД локализации наименования' as [Requisite!1!Code], cast(SBRouteBlock.TitleLocalizeID as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 1 as Tag, null as Parent, 'Описание' as [Requisite!1!Code], cast(SBRouteBlock.Comment as image) as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'BaseBlockType' as Code
											,	case SBRouteBlock.BaseBlockType 
													when '2' then 'Уведомление'
													when '3' then 'Задание'
													when '4' then 'Условие'
													when '5' then 'Ожидание'
													when '6' then 'Мониторинг'
													when '7' then 'Сценарий'
													when '9' then 'Подзадача'
													else '' 
												end as Value
											,	case SBRouteBlock.BaseBlockType 
													when '2' then 'SYSRES_SBINTF.NOTICE_BLOCK_DESCRIPTION'
													when '3' then 'SYSRES_SBINTF.JOB_BLOCK_DESCRIPTION'
													when '4' then 'SYSRES_SBINTF.CONDITION_BLOCK_DESCRIPTION'
													when '5' then 'SYSRES_SBINTF.WAITING_BLOCK_DESCRIPTION'
													when '6' then 'SYSRES_SBINTF.MONITORING_BLOCK_DESCRIPTION'
													when '7' then 'SYSRES_SBINTF.SCRIPT_BLOCK_DESCRIPTION'
													when '9' then 'SYSRES_SBINTF.SUBTASK_BLOCK_DESCRIPTION'
													else ''  
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 'BlockGroup' as Code, SBRouteBlockGroup.Name as Value  for xml raw('Requisite'), type)
								, (select 'Состояние' as Code
											,	case SBRouteBlock.[State] 
													when 'Д' then 'Действующий'
													when 'З' then 'Закрытый'
													else '' 
												end as Value
											,	case SBRouteBlock.[State] 
													when 'Д' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_MASCULINE'
													when 'З' then 'SYSRES_SYSCOMP.OPERATING_RECORD_FLAG_VALUE_FEMININE'
													else '' 
												end as ValueLocalizeID for xml raw('Requisite'), type)
								, (select 1 as Tag, null as Parent, 'Properties' as [Requisite!1!Code], SBRouteBlock.Properties as [Requisite!1!!CDATA], 'Text' as [Requisite!1!Текст] for xml explicit, binary base64, type)
								, (select 'LastUpdate' as Code, convert(varchar(30),SBRouteBlock.LastUpdate,104) + ' ' + convert(varchar(30),SBRouteBlock.LastUpdate,108)  as Value for xml raw('Requisite'), type)
							from 
								SBRouteBlock
								left join SBRouteBlockGroup on SBRouteBlockGroup.XRecID = SBRouteBlock.BlockGroup
							where 
								SBRouteBlock.XRecID = mainSBRouteBlock.XRecID 
							for xml raw('Requisites'), type
						)
					/*,	(	select
								(select HostID as HostID, UserID as UserID, Count(*) as AmountOfChanges for xml raw('ChangedBy'), type)
							from
								XProtokol
							where
								SrcRecID = mainSBRouteBlock.XRecID
								and DateAct >= @date_filter
								and [Action] <> 'F'
							group by
								HostID, UserID
							for xml raw('ChangeHistory'), type
						)*/
				from
					SBRouteBlock mainSBRouteBlock
				where
					mainSBRouteBlock.LastUpdate >= @date_filter 
				for xml raw('WorkflowBlocks'), type
	)
	return @Xml

END

GO

