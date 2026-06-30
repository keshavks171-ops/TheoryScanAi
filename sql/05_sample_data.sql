/*=============================================================================
  Provider Datamart - 05_sample_data.sql
  Illustrative sample data so the model can be queried, demoed, and connected
  to Power BI without a live DWH feed.
  Target: Microsoft SQL Server (T-SQL)

  This is DEMO data, not production data. NPIs, names, tax IDs, and addresses
  are fictitious. Run AFTER 00-04.

  Design notes:
    * Dim_Date is generated for 2023-01-01 .. 2025-12-31.
    * Dimension surrogate keys are IDENTITY, so every fact/bridge row resolves
      its keys by JOINing on the natural (business) key against the CURRENT
      dimension row - exactly how the ETL load will do it. Nothing here depends
      on a hard-coded surrogate value.
    * Every section is guarded so the script is safe to re-run.
    * Demo rows are tagged DW_SourceSystem = 'SAMPLE' for easy cleanup:
        DELETE FROM fact.<...>   WHERE DW_SourceSystem = 'SAMPLE';
        DELETE FROM bridge.<...> WHERE DW_SourceSystem = 'SAMPLE';
        DELETE FROM dim.<...>    WHERE DW_SourceSystem = 'SAMPLE';
=============================================================================*/

/*-----------------------------------------------------------------------------
  Dim_Date  (generate the calendar)
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Date WHERE Date_SK > 0)
BEGIN
    ;WITH d AS
    (
        SELECT CAST('2023-01-01' AS DATE) AS dt
        UNION ALL
        SELECT DATEADD(DAY, 1, dt) FROM d WHERE dt < '2025-12-31'
    )
    INSERT INTO dim.Dim_Date
        (Date_SK, FullDate, DayOfMonth, DayName, DayOfWeek, CalendarWeek,
         CalendarMonth, MonthName, CalendarQuarter, CalendarYear,
         FirstDayOfMonth, LastDayOfMonth, IsLastDayOfMonth)
    SELECT
        YEAR(dt) * 10000 + MONTH(dt) * 100 + DAY(dt),
        dt,
        DAY(dt),
        DATENAME(WEEKDAY, dt),
        DATEPART(WEEKDAY, dt),
        DATEPART(WEEK, dt),
        MONTH(dt),
        DATENAME(MONTH, dt),
        DATEPART(QUARTER, dt),
        YEAR(dt),
        DATEFROMPARTS(YEAR(dt), MONTH(dt), 1),
        EOMONTH(dt),
        CASE WHEN dt = EOMONTH(dt) THEN 1 ELSE 0 END
    FROM d
    OPTION (MAXRECURSION 0);
END
GO

/*-----------------------------------------------------------------------------
  Dim_Specialty  (NUCC taxonomy)
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Specialty WHERE TaxonomyCode = '207R00000X')
    INSERT INTO dim.Dim_Specialty
        (TaxonomyCode, SpecialtyName, SpecialtyGroup, ProviderClass, IsPrimaryCareFlag, DW_SourceSystem)
    VALUES
        ('207R00000X', 'Internal Medicine',    'Primary Care', 'Physician',         1, 'SAMPLE'),
        ('208000000X', 'Pediatrics',           'Primary Care', 'Physician',         1, 'SAMPLE'),
        ('207Q00000X', 'Family Medicine',      'Primary Care', 'Physician',         1, 'SAMPLE'),
        ('363LF0000X', 'Family Nurse Practitioner', 'Primary Care', 'Advanced Practice', 1, 'SAMPLE'),
        ('207RC0000X', 'Cardiovascular Disease', 'Specialist', 'Physician',         0, 'SAMPLE'),
        ('207N00000X', 'Dermatology',          'Specialist',   'Physician',         0, 'SAMPLE'),
        ('207X00000X', 'Orthopaedic Surgery',  'Specialist',   'Physician',         0, 'SAMPLE');
GO

/*-----------------------------------------------------------------------------
  Dim_Location
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Location WHERE LocationBK = 'LOC-001')
    INSERT INTO dim.Dim_Location
        (LocationBK, AddressLine1, AddressLine2, City, StateCode, ZipCode, CountyName, Latitude, Longitude, DW_SourceSystem)
    VALUES
        ('LOC-001', '100 Market St',   'Suite 300', 'Austin',      'TX', '78701', 'Travis',   30.267200, -97.743100, 'SAMPLE'),
        ('LOC-002', '250 Congress Ave', NULL,       'Austin',      'TX', '78704', 'Travis',   30.249500, -97.750800, 'SAMPLE'),
        ('LOC-003', '4500 Medical Pkwy','Bldg B',   'Round Rock',  'TX', '78664', 'Williamson',30.508300,-97.678900, 'SAMPLE'),
        ('LOC-004', '900 Riverside Dr', NULL,       'Dallas',      'TX', '75201', 'Dallas',   32.776700, -96.797000, 'SAMPLE'),
        ('LOC-005', '17 Lakeshore Blvd','Suite 12', 'Houston',     'TX', '77002', 'Harris',   29.760400, -95.369800, 'SAMPLE');
GO

/*-----------------------------------------------------------------------------
  Dim_Network
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Network WHERE NetworkCode = 'NET-COM-PPO')
    INSERT INTO dim.Dim_Network
        (NetworkCode, NetworkName, NetworkType, LineOfBusiness, DW_SourceSystem)
    VALUES
        ('NET-COM-PPO', 'Statewide Commercial PPO',   'PPO', 'Commercial', 'SAMPLE'),
        ('NET-MA-HMO',  'Senior Choice Medicare HMO', 'HMO', 'Medicare',   'SAMPLE'),
        ('NET-MCD',     'Community Medicaid Network',  'HMO', 'Medicaid',   'SAMPLE');
GO

/*-----------------------------------------------------------------------------
  Dim_Plan
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Plan WHERE PlanCode = 'PLN-COM-GOLD')
    INSERT INTO dim.Dim_Plan
        (PlanCode, PlanName, ProductType, LineOfBusiness, DW_SourceSystem)
    VALUES
        ('PLN-COM-GOLD', 'Commercial Gold PPO',       'PPO', 'Commercial', 'SAMPLE'),
        ('PLN-MA-PLUS',  'Senior Choice Plus (HMO)',  'HMO', 'Medicare',   'SAMPLE'),
        ('PLN-MCD-STD',  'Community Care Standard',   'HMO', 'Medicaid',   'SAMPLE');
GO

/*-----------------------------------------------------------------------------
  Dim_ProviderOrganization  (SCD Type 2; all rows current for the demo)
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM dim.Dim_ProviderOrganization WHERE OrganizationName = 'Lone Star Medical Group')
    INSERT INTO dim.Dim_ProviderOrganization
        (OrganizationNPI, TaxID, OrganizationName, OrganizationType, OwnershipType,
         ParentOrganization, OrganizationStatus, EffectiveDate, ExpirationDate, IsCurrent, DW_SourceSystem)
    VALUES
        ('1900000001', '74-1000001', 'Lone Star Medical Group',     'Group',    'For-Profit',  NULL,                        'Active', '2020-01-01', '9999-12-31', 1, 'SAMPLE'),
        ('1900000002', '74-1000002', 'Hill Country Regional Hospital','Hospital','Non-Profit',  NULL,                        'Active', '2020-01-01', '9999-12-31', 1, 'SAMPLE'),
        ('1900000003', '74-1000003', 'Eastside Community Health',    'FQHC',     'Non-Profit',  'Eastside Health Alliance',  'Active', '2020-01-01', '9999-12-31', 1, 'SAMPLE');
GO

/*-----------------------------------------------------------------------------
  Dim_Provider  (SCD Type 2)
  Provider 1003000001 carries history: an expired row (no telehealth) and a
  current row (began offering telehealth on 2023-07-01).
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM dim.Dim_Provider WHERE NPI = '1003000001')
    INSERT INTO dim.Dim_Provider
        (NPI, ProviderFirstName, ProviderLastName, ProviderFullName, Gender, CredentialDegree,
         PrimarySpecialty, LicenseNumber, LicenseStateCode, DEANumber, ProviderStatus, TelehealthFlag,
         EffectiveDate, ExpirationDate, IsCurrent, DW_SourceSystem)
    VALUES
        -- Provider 1: history row, then current row
        ('1003000001', 'John',  'Smith',  'John Smith, MD',   'M', 'MD', 'Internal Medicine',   'TXM10001', 'TX', 'BS1000011', 'Active',     0, '2020-01-01', '2023-06-30', 0, 'SAMPLE'),
        ('1003000001', 'John',  'Smith',  'John Smith, MD',   'M', 'MD', 'Internal Medicine',   'TXM10001', 'TX', 'BS1000011', 'Active',     1, '2023-07-01', '9999-12-31', 1, 'SAMPLE'),
        ('1003000002', 'Maria', 'Garcia', 'Maria Garcia, MD', 'F', 'MD', 'Pediatrics',          'TXM10002', 'TX', 'BG1000022', 'Active',     0, '2021-03-15', '9999-12-31', 1, 'SAMPLE'),
        ('1003000003', 'David', 'Lee',    'David Lee, DO',    'M', 'DO', 'Family Medicine',     'TXO10003', 'TX', 'BL1000033', 'Active',     1, '2019-06-01', '9999-12-31', 1, 'SAMPLE'),
        ('1003000004', 'Susan', 'Patel',  'Susan Patel, NP',  'F', 'NP', 'Family Medicine',     'TXN10004', 'TX', NULL,        'Active',     0, '2022-09-01', '9999-12-31', 1, 'SAMPLE'),
        ('1003000005', 'Robert','Chen',   'Robert Chen, MD',  'M', 'MD', 'Cardiovascular Disease','TXM10005','TX', 'BC1000055', 'Active',    0, '2018-02-10', '9999-12-31', 1, 'SAMPLE'),
        ('1003000006', 'Linda', 'Nguyen', 'Linda Nguyen, MD', 'F', 'MD', 'Dermatology',         'TXM10006', 'TX', 'BN1000066', 'Active',     1, '2020-11-20', '9999-12-31', 1, 'SAMPLE'),
        ('1003000007', 'James', 'Wilson', 'James Wilson, MD', 'M', 'MD', 'Orthopaedic Surgery', 'TXM10007', 'TX', 'BW1000077', 'Terminated', 0, '2017-05-01', '9999-12-31', 1, 'SAMPLE'),
        ('1003000008', 'Emily', 'Brown',  'Emily Brown, MD',  'F', 'MD', 'Internal Medicine',   'TXM10008', 'TX', 'BB1000088', 'Active',     0, '2023-04-01', '9999-12-31', 1, 'SAMPLE');
GO

/*-----------------------------------------------------------------------------
  Bridge_ProviderAffiliation  (provider <-> organization, many-to-many)
  Provider 1003000005 (cardiology) practices at both the group and the hospital.
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM bridge.Bridge_ProviderAffiliation WHERE DW_SourceSystem = 'SAMPLE')
    INSERT INTO bridge.Bridge_ProviderAffiliation
        (Provider_SK, Organization_SK, IsPrimaryFlag, AffiliationRole, EffectiveDate, ExpirationDate, IsCurrent, DW_SourceSystem)
    SELECT p.Provider_SK, o.Organization_SK, m.IsPrimary, m.Role, m.Eff, '9999-12-31', 1, 'SAMPLE'
    FROM ( VALUES
        ('1003000001', 'Lone Star Medical Group',        1, 'Employed',   '2020-01-01'),
        ('1003000002', 'Lone Star Medical Group',        1, 'Employed',   '2021-03-15'),
        ('1003000003', 'Eastside Community Health',       1, 'Employed',   '2019-06-01'),
        ('1003000004', 'Eastside Community Health',       1, 'Employed',   '2022-09-01'),
        ('1003000005', 'Lone Star Medical Group',        1, 'Employed',   '2018-02-10'),
        ('1003000005', 'Hill Country Regional Hospital',  0, 'Admitting',  '2018-02-10'),
        ('1003000006', 'Lone Star Medical Group',        1, 'Contracted', '2020-11-20'),
        ('1003000007', 'Hill Country Regional Hospital',  1, 'Admitting',  '2017-05-01'),
        ('1003000008', 'Lone Star Medical Group',        1, 'Employed',   '2023-04-01')
    ) m(NPI, OrgName, IsPrimary, Role, Eff)
    JOIN dim.Dim_Provider             p ON p.NPI = m.NPI AND p.IsCurrent = 1
    JOIN dim.Dim_ProviderOrganization o ON o.OrganizationName = m.OrgName AND o.IsCurrent = 1;
GO

/*-----------------------------------------------------------------------------
  A reusable provider "home" assignment for the snapshot facts:
  primary org + primary specialty + practice location + a network.
-----------------------------------------------------------------------------*/
IF OBJECT_ID('tempdb..#ProviderBase') IS NOT NULL DROP TABLE #ProviderBase;
CREATE TABLE #ProviderBase
(
    NPI         CHAR(10)    NOT NULL,
    OrgName     VARCHAR(200) NOT NULL,
    Taxonomy    VARCHAR(20) NOT NULL,
    LocationBK  VARCHAR(50) NOT NULL,
    NetworkCode VARCHAR(30) NOT NULL,
    IsActive    BIT         NOT NULL,
    IsTerminated BIT        NOT NULL,
    TenureMonths INT        NOT NULL   -- as of 2025-03-31
);
INSERT INTO #ProviderBase VALUES
    ('1003000001', 'Lone Star Medical Group',         '207R00000X', 'LOC-001', 'NET-COM-PPO', 1, 0, 62),
    ('1003000002', 'Lone Star Medical Group',         '208000000X', 'LOC-001', 'NET-COM-PPO', 1, 0, 48),
    ('1003000003', 'Eastside Community Health',        '207Q00000X', 'LOC-005', 'NET-MCD',     1, 0, 69),
    ('1003000004', 'Eastside Community Health',        '363LF0000X', 'LOC-005', 'NET-MCD',     1, 0, 30),
    ('1003000005', 'Lone Star Medical Group',         '207RC0000X', 'LOC-002', 'NET-MA-HMO',  1, 0, 85),
    ('1003000006', 'Lone Star Medical Group',         '207N00000X', 'LOC-002', 'NET-COM-PPO', 1, 0, 52),
    ('1003000007', 'Hill Country Regional Hospital',   '207X00000X', 'LOC-003', 'NET-COM-PPO', 0, 1, 94),
    ('1003000008', 'Lone Star Medical Group',         '207R00000X', 'LOC-001', 'NET-MA-HMO',  1, 0, 23);
GO

/*-----------------------------------------------------------------------------
  Fact_ProviderRosterSnapshot  (monthly snapshots: Jan/Feb/Mar 2025)
  Grain: one row per provider per snapshot month.
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM fact.Fact_ProviderRosterSnapshot WHERE DW_SourceSystem = 'SAMPLE')
    INSERT INTO fact.Fact_ProviderRosterSnapshot
        (SnapshotDateKey, Provider_SK, Organization_SK, Specialty_SK, Location_SK, Network_SK,
         ProviderCount, IsActiveFlag, IsNewThisMonthFlag, IsTerminatedFlag, TenureMonths, DW_SourceSystem)
    SELECT
        mo.DateKey,
        p.Provider_SK, o.Organization_SK, s.Specialty_SK, l.Location_SK, n.Network_SK,
        1,
        b.IsActive,
        CASE WHEN b.NPI = '1003000008' AND mo.DateKey = 20250131 THEN 1 ELSE 0 END,  -- new hire ramp
        b.IsTerminated,
        b.TenureMonths - mo.MonthsBack,
        'SAMPLE'
    FROM #ProviderBase b
    CROSS JOIN ( VALUES (20250131, 2), (20250228, 1), (20250331, 0) ) mo(DateKey, MonthsBack)
    JOIN dim.Dim_Provider             p ON p.NPI = b.NPI AND p.IsCurrent = 1
    JOIN dim.Dim_ProviderOrganization o ON o.OrganizationName = b.OrgName AND o.IsCurrent = 1
    JOIN dim.Dim_Specialty            s ON s.TaxonomyCode = b.Taxonomy
    JOIN dim.Dim_Location             l ON l.LocationBK = b.LocationBK
    JOIN dim.Dim_Network              n ON n.NetworkCode = b.NetworkCode
    JOIN dim.Dim_Date                dt ON dt.Date_SK = mo.DateKey;
GO

/*-----------------------------------------------------------------------------
  Fact_ProviderNetworkParticipation  (periodic snapshot, 2025-03-31)
  Grain: provider x org x network x plan x location per snapshot month.
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM fact.Fact_ProviderNetworkParticipation WHERE DW_SourceSystem = 'SAMPLE')
    INSERT INTO fact.Fact_ProviderNetworkParticipation
        (SnapshotDateKey, Provider_SK, Organization_SK, Specialty_SK, Location_SK, Network_SK, Plan_SK,
         ParticipationStartDateKey, ParticipationEndDateKey,
         IsParticipatingFlag, AcceptingNewPatientsFlag, IsParInNetworkFlag, PanelSize, DW_SourceSystem)
    SELECT
        20250331,
        p.Provider_SK, o.Organization_SK, s.Specialty_SK, l.Location_SK, n.Network_SK, pl.Plan_SK,
        m.StartKey, m.EndKey,
        m.IsParticipating, m.Accepting, m.InNetwork, m.PanelSize, 'SAMPLE'
    FROM ( VALUES
        --  NPI,        NetCode,       PlanCode,      Participating, Accepting, InNetwork, Panel, Start,    End
        ('1003000001', 'NET-COM-PPO', 'PLN-COM-GOLD', 1, 1, 1, 1450, 20230101, NULL),
        ('1003000002', 'NET-COM-PPO', 'PLN-COM-GOLD', 1, 1, 1,  900, 20230101, NULL),
        ('1003000003', 'NET-MCD',     'PLN-MCD-STD',  1, 1, 1, 1800, 20230101, NULL),
        ('1003000004', 'NET-MCD',     'PLN-MCD-STD',  1, 1, 1, 1100, 20230101, NULL),
        ('1003000005', 'NET-MA-HMO',  'PLN-MA-PLUS',  1, 0, 1,  600, 20230101, NULL),
        ('1003000006', 'NET-COM-PPO', 'PLN-COM-GOLD', 1, 0, 1,  300, 20230101, NULL),
        ('1003000007', 'NET-COM-PPO', 'PLN-COM-GOLD', 0, 0, 0,    0, 20230101, 20241231),  -- terminated
        ('1003000008', 'NET-MA-HMO',  'PLN-MA-PLUS',  1, 1, 1,  500, 20240101, NULL)
    ) m(NPI, NetCode, PlanCode, IsParticipating, Accepting, InNetwork, PanelSize, StartKey, EndKey)
    JOIN dim.Dim_Provider             p  ON p.NPI = m.NPI AND p.IsCurrent = 1
    JOIN #ProviderBase                b  ON b.NPI = m.NPI
    JOIN dim.Dim_ProviderOrganization o  ON o.OrganizationName = b.OrgName AND o.IsCurrent = 1
    JOIN dim.Dim_Specialty            s  ON s.TaxonomyCode = b.Taxonomy
    JOIN dim.Dim_Location             l  ON l.LocationBK = b.LocationBK
    JOIN dim.Dim_Network              n  ON n.NetworkCode = m.NetCode
    JOIN dim.Dim_Plan                 pl ON pl.PlanCode = m.PlanCode
    JOIN dim.Dim_Date                dt  ON dt.Date_SK = 20250331;
GO

/*-----------------------------------------------------------------------------
  Fact_ProviderCredentialing  (accumulating snapshot)
  Grain: one row per credentialing case. Mix of completed and in-flight cases.
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM fact.Fact_ProviderCredentialing WHERE DW_SourceSystem = 'SAMPLE')
    INSERT INTO fact.Fact_ProviderCredentialing
        (Provider_SK, Organization_SK, Specialty_SK,
         ReceivedDateKey, CommitteeReviewDateKey, ApprovedDateKey, EffectiveDateKey, NextRecredentialDateKey,
         CredentialingCaseNumber, CredentialingType, CycleTimeDays, IsApprovedFlag, IsExpeditedFlag, DW_SourceSystem)
    SELECT
        p.Provider_SK, o.Organization_SK, s.Specialty_SK,
        m.Received, m.Committee, m.Approved, m.EffKey, NULL,
        m.CaseNo, m.CredType, m.CycleDays, m.Approved2, m.Expedited, 'SAMPLE'
    FROM ( VALUES
        --  NPI,        CaseNo,      CredType,      Received, Committee, Approved, EffKey,  Cycle, Approved?, Expedited
        ('1003000008', 'CRED-2024-001', 'Initial',      20240115, 20240220, 20240301, 20240315,  46, 1, 0),
        ('1003000004', 'CRED-2024-002', 'Initial',      20240210, 20240315, 20240401, 20240415,  51, 1, 0),
        ('1003000001', 'CRED-2024-010', 'Recredential', 20241001, 20241101, 20241115, 20241201,  45, 1, 0),
        ('1003000005', 'CRED-2025-003', 'Recredential', 20250105, NULL,     NULL,     NULL,     NULL, 0, 0),  -- in flight
        ('1003000002', 'CRED-2025-007', 'Initial',      20250120, 20250210, 20250225, 20250301,  36, 1, 1)   -- expedited
    ) m(NPI, CaseNo, CredType, Received, Committee, Approved, EffKey, CycleDays, Approved2, Expedited)
    JOIN dim.Dim_Provider             p ON p.NPI = m.NPI AND p.IsCurrent = 1
    JOIN #ProviderBase                b ON b.NPI = m.NPI
    JOIN dim.Dim_ProviderOrganization o ON o.OrganizationName = b.OrgName AND o.IsCurrent = 1
    JOIN dim.Dim_Specialty            s ON s.TaxonomyCode = b.Taxonomy;
GO

/*-----------------------------------------------------------------------------
  Fact_ProviderQualityMeasure  (periodic snapshot; period end 2024-12-31)
  Grain: provider x measure x measurement period.
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM fact.Fact_ProviderQualityMeasure WHERE DW_SourceSystem = 'SAMPLE')
    INSERT INTO fact.Fact_ProviderQualityMeasure
        (PeriodDateKey, Provider_SK, Organization_SK, Specialty_SK, Network_SK,
         MeasureCode, MeasureName, MeasureNumerator, MeasureDenominator, MeasureRate,
         BenchmarkRate, StarRating, DW_SourceSystem)
    SELECT
        20241231,
        p.Provider_SK, o.Organization_SK, s.Specialty_SK, n.Network_SK,
        m.Code, m.Name, m.Num, m.Den,
        CAST(m.Num AS DECIMAL(9,4)) / NULLIF(m.Den, 0),
        m.Benchmark, m.Stars, 'SAMPLE'
    FROM ( VALUES
        --  NPI,        Code,    Name,                              Num,  Den, Benchmark, Stars
        ('1003000001', 'CBP',   'Controlling High Blood Pressure',  712,  900, 0.7200, 4.0),
        ('1003000001', 'BCS',   'Breast Cancer Screening',          540,  720, 0.7400, 4.0),
        ('1003000002', 'CIS',   'Childhood Immunization Status',     430,  500, 0.8600, 5.0),
        ('1003000003', 'CDC',   'Comprehensive Diabetes Care',       380,  560, 0.6500, 3.0),
        ('1003000005', 'SPC',   'Statin Therapy (Cardiovascular)',   410,  480, 0.8000, 4.0),
        ('1003000008', 'CBP',   'Controlling High Blood Pressure',   300,  450, 0.6800, 3.0)
    ) m(NPI, Code, Name, Num, Den, Benchmark, Stars)
    JOIN dim.Dim_Provider             p ON p.NPI = m.NPI AND p.IsCurrent = 1
    JOIN #ProviderBase                b ON b.NPI = m.NPI
    JOIN dim.Dim_ProviderOrganization o ON o.OrganizationName = b.OrgName AND o.IsCurrent = 1
    JOIN dim.Dim_Specialty            s ON s.TaxonomyCode = b.Taxonomy
    JOIN dim.Dim_Network              n ON n.NetworkCode = b.NetworkCode;
GO

IF OBJECT_ID('tempdb..#ProviderBase') IS NOT NULL DROP TABLE #ProviderBase;
GO

/*-----------------------------------------------------------------------------
  Quick verification (optional - select counts after loading)
-----------------------------------------------------------------------------*/
-- SELECT 'Dim_Date' t, COUNT(*) n FROM dim.Dim_Date
-- UNION ALL SELECT 'Dim_Provider',         COUNT(*) FROM dim.Dim_Provider
-- UNION ALL SELECT 'Dim_ProviderOrg',      COUNT(*) FROM dim.Dim_ProviderOrganization
-- UNION ALL SELECT 'Bridge_Affiliation',   COUNT(*) FROM bridge.Bridge_ProviderAffiliation
-- UNION ALL SELECT 'Fact_RosterSnapshot',  COUNT(*) FROM fact.Fact_ProviderRosterSnapshot
-- UNION ALL SELECT 'Fact_NetworkPart',     COUNT(*) FROM fact.Fact_ProviderNetworkParticipation
-- UNION ALL SELECT 'Fact_Credentialing',   COUNT(*) FROM fact.Fact_ProviderCredentialing
-- UNION ALL SELECT 'Fact_QualityMeasure',  COUNT(*) FROM fact.Fact_ProviderQualityMeasure;
