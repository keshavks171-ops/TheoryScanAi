/*=============================================================================
  Provider Datamart - 01_dimensions.sql
  Dimension tables for the Provider subject area.
  Target: Microsoft SQL Server (T-SQL)

  Conventions:
    *_SK            surrogate key (INT IDENTITY), primary key of the dimension
    *_BK / NPI etc. business / natural key carried from source
    SCD Type 2      EffectiveDate / ExpirationDate / IsCurrent
    Audit           DW_CreatedDate / DW_UpdatedDate / DW_SourceSystem
    Unknown member  a -1 row is seeded so facts never lose rows on lookup miss
=============================================================================*/

/*-----------------------------------------------------------------------------
  Dim_Date  (conformed, SCD Type 0 - static calendar)
-----------------------------------------------------------------------------*/
IF OBJECT_ID('dim.Dim_Date') IS NULL
BEGIN
    CREATE TABLE dim.Dim_Date
    (
        Date_SK            INT          NOT NULL CONSTRAINT PK_Dim_Date PRIMARY KEY,  -- yyyymmdd
        FullDate           DATE         NOT NULL,
        DayOfMonth         TINYINT      NOT NULL,
        DayName            VARCHAR(10)  NOT NULL,
        DayOfWeek          TINYINT      NOT NULL,
        CalendarWeek       TINYINT      NOT NULL,
        CalendarMonth      TINYINT      NOT NULL,
        MonthName          VARCHAR(10)  NOT NULL,
        CalendarQuarter    TINYINT      NOT NULL,
        CalendarYear       SMALLINT     NOT NULL,
        FirstDayOfMonth    DATE         NOT NULL,
        LastDayOfMonth     DATE         NOT NULL,
        IsLastDayOfMonth   BIT          NOT NULL,
        DW_CreatedDate     DATETIME2(3) NOT NULL CONSTRAINT DF_Dim_Date_Created DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Dim_Specialty  (specialty & provider taxonomy; SCD Type 1)
-----------------------------------------------------------------------------*/
IF OBJECT_ID('dim.Dim_Specialty') IS NULL
BEGIN
    CREATE TABLE dim.Dim_Specialty
    (
        Specialty_SK        INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dim_Specialty PRIMARY KEY,
        TaxonomyCode        VARCHAR(20)   NOT NULL,   -- NUCC taxonomy code (business key)
        SpecialtyName       VARCHAR(150)  NOT NULL,
        SpecialtyGroup      VARCHAR(100)  NULL,        -- rollup, e.g. Primary Care / Specialist
        ProviderClass       VARCHAR(50)   NULL,        -- e.g. Physician, Dentist, Behavioral
        IsPrimaryCareFlag   BIT           NOT NULL CONSTRAINT DF_Dim_Specialty_PCP DEFAULT (0),
        DW_SourceSystem     VARCHAR(50)   NULL,
        DW_CreatedDate      DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Specialty_Created DEFAULT (SYSUTCDATETIME()),
        DW_UpdatedDate      DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Specialty_Updated DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Dim_Location  (practice location / geography; conformed; SCD Type 1)
-----------------------------------------------------------------------------*/
IF OBJECT_ID('dim.Dim_Location') IS NULL
BEGIN
    CREATE TABLE dim.Dim_Location
    (
        Location_SK     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dim_Location PRIMARY KEY,
        LocationBK      VARCHAR(50)   NOT NULL,   -- source location id (business key)
        AddressLine1    VARCHAR(150)  NULL,
        AddressLine2    VARCHAR(150)  NULL,
        City            VARCHAR(100)  NULL,
        StateCode       CHAR(2)       NULL,
        ZipCode         VARCHAR(10)   NULL,
        CountyName      VARCHAR(100)  NULL,
        Latitude        DECIMAL(9,6)  NULL,
        Longitude       DECIMAL(9,6)  NULL,
        DW_SourceSystem VARCHAR(50)   NULL,
        DW_CreatedDate  DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Location_Created DEFAULT (SYSUTCDATETIME()),
        DW_UpdatedDate  DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Location_Updated DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Dim_Network  (provider networks; SCD Type 1)
-----------------------------------------------------------------------------*/
IF OBJECT_ID('dim.Dim_Network') IS NULL
BEGIN
    CREATE TABLE dim.Dim_Network
    (
        Network_SK      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dim_Network PRIMARY KEY,
        NetworkCode     VARCHAR(30)   NOT NULL,   -- business key
        NetworkName     VARCHAR(150)  NOT NULL,
        NetworkType     VARCHAR(50)   NULL,        -- e.g. HMO, PPO, EPO
        LineOfBusiness  VARCHAR(50)   NULL,        -- e.g. Commercial, Medicare, Medicaid
        DW_SourceSystem VARCHAR(50)   NULL,
        DW_CreatedDate  DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Network_Created DEFAULT (SYSUTCDATETIME()),
        DW_UpdatedDate  DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Network_Updated DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Dim_Plan  (health-plan products; SCD Type 1)
-----------------------------------------------------------------------------*/
IF OBJECT_ID('dim.Dim_Plan') IS NULL
BEGIN
    CREATE TABLE dim.Dim_Plan
    (
        Plan_SK         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dim_Plan PRIMARY KEY,
        PlanCode        VARCHAR(30)   NOT NULL,   -- business key
        PlanName        VARCHAR(150)  NOT NULL,
        ProductType     VARCHAR(50)   NULL,
        LineOfBusiness  VARCHAR(50)   NULL,
        DW_SourceSystem VARCHAR(50)   NULL,
        DW_CreatedDate  DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Plan_Created DEFAULT (SYSUTCDATETIME()),
        DW_UpdatedDate  DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Plan_Updated DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Dim_Provider  (individual practitioner; conformed; SCD Type 2)
-----------------------------------------------------------------------------*/
IF OBJECT_ID('dim.Dim_Provider') IS NULL
BEGIN
    CREATE TABLE dim.Dim_Provider
    (
        Provider_SK         INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dim_Provider PRIMARY KEY,
        NPI                 CHAR(10)      NOT NULL,   -- National Provider Identifier (business key)
        ProviderFirstName   VARCHAR(100)  NULL,
        ProviderLastName    VARCHAR(100)  NULL,
        ProviderFullName    VARCHAR(200)  NULL,
        Gender              CHAR(1)       NULL,
        CredentialDegree    VARCHAR(50)   NULL,        -- MD, DO, NP, ...
        PrimarySpecialty    VARCHAR(150)  NULL,        -- denormalized for convenience
        LicenseNumber       VARCHAR(50)   NULL,
        LicenseStateCode    CHAR(2)       NULL,
        DEANumber           VARCHAR(20)   NULL,
        ProviderStatus      VARCHAR(30)   NULL,        -- Active, Inactive, Terminated
        TelehealthFlag      BIT           NOT NULL CONSTRAINT DF_Dim_Provider_Tele DEFAULT (0),
        -- SCD Type 2 tracking
        EffectiveDate       DATE          NOT NULL,
        ExpirationDate      DATE          NOT NULL CONSTRAINT DF_Dim_Provider_Exp DEFAULT ('9999-12-31'),
        IsCurrent           BIT           NOT NULL CONSTRAINT DF_Dim_Provider_Cur DEFAULT (1),
        -- Audit
        DW_SourceSystem     VARCHAR(50)   NULL,
        DW_CreatedDate      DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Provider_Created DEFAULT (SYSUTCDATETIME()),
        DW_UpdatedDate      DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Provider_Updated DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Dim_ProviderOrganization  (group / facility; SCD Type 2)
-----------------------------------------------------------------------------*/
IF OBJECT_ID('dim.Dim_ProviderOrganization') IS NULL
BEGIN
    CREATE TABLE dim.Dim_ProviderOrganization
    (
        Organization_SK     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dim_ProviderOrganization PRIMARY KEY,
        OrganizationNPI     CHAR(10)      NULL,        -- Type 2 NPI (business key)
        TaxID               VARCHAR(15)   NULL,        -- TIN / EIN
        OrganizationName    VARCHAR(200)  NOT NULL,
        OrganizationType    VARCHAR(50)   NULL,        -- Group, Hospital, FQHC, ...
        OwnershipType       VARCHAR(50)   NULL,
        ParentOrganization  VARCHAR(200)  NULL,
        OrganizationStatus  VARCHAR(30)   NULL,
        -- SCD Type 2 tracking
        EffectiveDate       DATE          NOT NULL,
        ExpirationDate      DATE          NOT NULL CONSTRAINT DF_Dim_Org_Exp DEFAULT ('9999-12-31'),
        IsCurrent           BIT           NOT NULL CONSTRAINT DF_Dim_Org_Cur DEFAULT (1),
        -- Audit
        DW_SourceSystem     VARCHAR(50)   NULL,
        DW_CreatedDate      DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Org_Created DEFAULT (SYSUTCDATETIME()),
        DW_UpdatedDate      DATETIME2(3)  NOT NULL CONSTRAINT DF_Dim_Org_Updated DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Seed the "Unknown" (-1) member into each dimension.
  Facts point here when a natural key cannot be resolved.
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Date WHERE Date_SK = -1)
    INSERT INTO dim.Dim_Date (Date_SK, FullDate, DayOfMonth, DayName, DayOfWeek,
        CalendarWeek, CalendarMonth, MonthName, CalendarQuarter, CalendarYear,
        FirstDayOfMonth, LastDayOfMonth, IsLastDayOfMonth)
    VALUES (-1, '1900-01-01', 1, 'Unknown', 0, 0, 0, 'Unknown', 0, 1900,
        '1900-01-01', '1900-01-01', 0);
GO

SET IDENTITY_INSERT dim.Dim_Specialty ON;
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Specialty WHERE Specialty_SK = -1)
    INSERT INTO dim.Dim_Specialty (Specialty_SK, TaxonomyCode, SpecialtyName)
    VALUES (-1, 'UNK', 'Unknown');
SET IDENTITY_INSERT dim.Dim_Specialty OFF;
GO

SET IDENTITY_INSERT dim.Dim_Location ON;
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Location WHERE Location_SK = -1)
    INSERT INTO dim.Dim_Location (Location_SK, LocationBK) VALUES (-1, 'UNK');
SET IDENTITY_INSERT dim.Dim_Location OFF;
GO

SET IDENTITY_INSERT dim.Dim_Network ON;
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Network WHERE Network_SK = -1)
    INSERT INTO dim.Dim_Network (Network_SK, NetworkCode, NetworkName) VALUES (-1, 'UNK', 'Unknown');
SET IDENTITY_INSERT dim.Dim_Network OFF;
GO

SET IDENTITY_INSERT dim.Dim_Plan ON;
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Plan WHERE Plan_SK = -1)
    INSERT INTO dim.Dim_Plan (Plan_SK, PlanCode, PlanName) VALUES (-1, 'UNK', 'Unknown');
SET IDENTITY_INSERT dim.Dim_Plan OFF;
GO

SET IDENTITY_INSERT dim.Dim_Provider ON;
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Provider WHERE Provider_SK = -1)
    INSERT INTO dim.Dim_Provider (Provider_SK, NPI, ProviderFullName, EffectiveDate)
    VALUES (-1, '0000000000', 'Unknown', '1900-01-01');
SET IDENTITY_INSERT dim.Dim_Provider OFF;
GO

SET IDENTITY_INSERT dim.Dim_ProviderOrganization ON;
IF NOT EXISTS (SELECT 1 FROM dim.Dim_ProviderOrganization WHERE Organization_SK = -1)
    INSERT INTO dim.Dim_ProviderOrganization (Organization_SK, OrganizationName, EffectiveDate)
    VALUES (-1, 'Unknown', '1900-01-01');
SET IDENTITY_INSERT dim.Dim_ProviderOrganization OFF;
GO
