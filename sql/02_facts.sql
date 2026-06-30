/*=============================================================================
  Provider Datamart - 02_facts.sql
  Fact tables for the Provider subject area.
  Target: Microsoft SQL Server (T-SQL)

  Each fact declares ONE grain (see docs/02-dimensional-model.md).
  Foreign keys are added in 04_constraints_indexes.sql.
=============================================================================*/

/*-----------------------------------------------------------------------------
  Fact_ProviderNetworkParticipation
  Type : periodic snapshot
  Grain: one row per provider x organization x network x plan x location,
         per snapshot month.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('fact.Fact_ProviderNetworkParticipation') IS NULL
BEGIN
    CREATE TABLE fact.Fact_ProviderNetworkParticipation
    (
        ParticipationFact_SK      BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Fact_ProviderNetworkParticipation PRIMARY KEY,
        -- Dimension foreign keys
        SnapshotDateKey           INT      NOT NULL,
        Provider_SK               INT      NOT NULL,
        Organization_SK           INT      NOT NULL,
        Specialty_SK              INT      NOT NULL,
        Location_SK               INT      NOT NULL,
        Network_SK                INT      NOT NULL,
        Plan_SK                   INT      NOT NULL,
        -- Effective dates of the participation record (Type 2 source dates)
        ParticipationStartDateKey INT      NULL,
        ParticipationEndDateKey   INT      NULL,
        -- Measures / flags
        IsParticipatingFlag       BIT      NOT NULL,
        AcceptingNewPatientsFlag  BIT      NOT NULL CONSTRAINT DF_FNP_Accept DEFAULT (0),
        IsParInNetworkFlag        BIT      NOT NULL CONSTRAINT DF_FNP_Par DEFAULT (1),
        PanelSize                 INT      NULL,
        -- Audit
        DW_SourceSystem           VARCHAR(50)  NULL,
        DW_CreatedDate            DATETIME2(3) NOT NULL CONSTRAINT DF_FNP_Created DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Fact_ProviderCredentialing
  Type : accumulating snapshot
  Grain: one row per credentialing application / case.
         Date keys fill in as the case progresses through milestones.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('fact.Fact_ProviderCredentialing') IS NULL
BEGIN
    CREATE TABLE fact.Fact_ProviderCredentialing
    (
        CredentialingFact_SK    BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Fact_ProviderCredentialing PRIMARY KEY,
        -- Dimension foreign keys
        Provider_SK             INT     NOT NULL,
        Organization_SK         INT     NOT NULL,
        Specialty_SK            INT     NOT NULL,
        -- Role-playing dates (milestones of the accumulating snapshot)
        ReceivedDateKey         INT     NOT NULL,
        CommitteeReviewDateKey  INT     NULL,
        ApprovedDateKey         INT     NULL,
        EffectiveDateKey        INT     NULL,
        NextRecredentialDateKey INT     NULL,
        -- Degenerate dimension
        CredentialingCaseNumber VARCHAR(40) NOT NULL,
        CredentialingType       VARCHAR(30) NULL,   -- Initial / Recredential
        -- Measures
        CycleTimeDays           INT     NULL,        -- Received -> Approved
        IsApprovedFlag          BIT     NOT NULL CONSTRAINT DF_FC_Approved DEFAULT (0),
        IsExpeditedFlag         BIT     NOT NULL CONSTRAINT DF_FC_Expedited DEFAULT (0),
        -- Audit
        DW_SourceSystem         VARCHAR(50)  NULL,
        DW_CreatedDate          DATETIME2(3) NOT NULL CONSTRAINT DF_FC_Created DEFAULT (SYSUTCDATETIME()),
        DW_UpdatedDate          DATETIME2(3) NOT NULL CONSTRAINT DF_FC_Updated DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Fact_ProviderQualityMeasure
  Type : periodic snapshot
  Grain: one row per provider x quality measure x measurement period.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('fact.Fact_ProviderQualityMeasure') IS NULL
BEGIN
    CREATE TABLE fact.Fact_ProviderQualityMeasure
    (
        QualityFact_SK      BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Fact_ProviderQualityMeasure PRIMARY KEY,
        -- Dimension foreign keys
        PeriodDateKey       INT     NOT NULL,   -- end of measurement period
        Provider_SK         INT     NOT NULL,
        Organization_SK     INT     NOT NULL,
        Specialty_SK        INT     NOT NULL,
        Network_SK          INT     NOT NULL,
        -- Measure identity (consider promoting to Dim_Measure as the model grows)
        MeasureCode         VARCHAR(30)  NOT NULL,   -- e.g. HEDIS measure id
        MeasureName         VARCHAR(150) NULL,
        -- Measures
        MeasureNumerator    INT     NULL,
        MeasureDenominator  INT     NULL,
        MeasureRate         DECIMAL(9,4) NULL,        -- numerator / denominator
        BenchmarkRate       DECIMAL(9,4) NULL,
        StarRating          DECIMAL(3,1) NULL,
        -- Audit
        DW_SourceSystem     VARCHAR(50)  NULL,
        DW_CreatedDate      DATETIME2(3) NOT NULL CONSTRAINT DF_FQ_Created DEFAULT (SYSUTCDATETIME())
    );
END
GO

/*-----------------------------------------------------------------------------
  Fact_ProviderRosterSnapshot
  Type : periodic snapshot (monthly)
  Grain: one row per provider x snapshot month. Drives counts & trending.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('fact.Fact_ProviderRosterSnapshot') IS NULL
BEGIN
    CREATE TABLE fact.Fact_ProviderRosterSnapshot
    (
        RosterFact_SK     BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Fact_ProviderRosterSnapshot PRIMARY KEY,
        -- Dimension foreign keys
        SnapshotDateKey   INT     NOT NULL,
        Provider_SK       INT     NOT NULL,
        Organization_SK   INT     NOT NULL,
        Specialty_SK      INT     NOT NULL,
        Location_SK       INT     NOT NULL,
        Network_SK        INT     NOT NULL,
        -- Measures / flags (additive count is the "1" per active provider)
        ProviderCount     INT     NOT NULL CONSTRAINT DF_FR_Count DEFAULT (1),
        IsActiveFlag      BIT     NOT NULL,
        IsNewThisMonthFlag BIT    NOT NULL CONSTRAINT DF_FR_New DEFAULT (0),
        IsTerminatedFlag  BIT     NOT NULL CONSTRAINT DF_FR_Term DEFAULT (0),
        TenureMonths      INT     NULL,
        -- Audit
        DW_SourceSystem   VARCHAR(50)  NULL,
        DW_CreatedDate    DATETIME2(3) NOT NULL CONSTRAINT DF_FR_Created DEFAULT (SYSUTCDATETIME())
    );
END
GO
