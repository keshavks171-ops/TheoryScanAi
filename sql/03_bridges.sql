/*=============================================================================
  Provider Datamart - 03_bridges.sql
  Bridge tables resolving many-to-many relationships.
  Target: Microsoft SQL Server (T-SQL)
=============================================================================*/

/*-----------------------------------------------------------------------------
  Bridge_ProviderAffiliation
  Resolves the many-to-many between providers and organizations.
  A provider may practice at several organizations; an organization has many
  providers. One row per current provider-organization affiliation.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('bridge.Bridge_ProviderAffiliation') IS NULL
BEGIN
    CREATE TABLE bridge.Bridge_ProviderAffiliation
    (
        Affiliation_SK     BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Bridge_ProviderAffiliation PRIMARY KEY,
        Provider_SK        INT     NOT NULL,
        Organization_SK    INT     NOT NULL,
        IsPrimaryFlag      BIT     NOT NULL CONSTRAINT DF_BPA_Primary DEFAULT (0),
        AffiliationRole    VARCHAR(50) NULL,        -- e.g. Employed, Contracted, Admitting
        EffectiveDate      DATE    NOT NULL,
        ExpirationDate     DATE    NOT NULL CONSTRAINT DF_BPA_Exp DEFAULT ('9999-12-31'),
        IsCurrent          BIT     NOT NULL CONSTRAINT DF_BPA_Cur DEFAULT (1),
        DW_SourceSystem    VARCHAR(50)  NULL,
        DW_CreatedDate     DATETIME2(3) NOT NULL CONSTRAINT DF_BPA_Created DEFAULT (SYSUTCDATETIME())
    );
END
GO
