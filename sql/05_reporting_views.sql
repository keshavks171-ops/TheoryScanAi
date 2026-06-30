/*=============================================================================
  Provider Datamart - 05_reporting_views.sql
  Power BI-facing reporting views (semantic layer) over the star schema.
  Target: Microsoft SQL Server (T-SQL)  [STRING_AGG requires SQL Server 2017+]

  Views live in the `rpt` schema so they form a stable contract for Power BI,
  decoupled from the physical dim/fact tables.
=============================================================================*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'rpt')
    EXEC('CREATE SCHEMA rpt');
GO

/*-----------------------------------------------------------------------------
  rpt.vw_ProviderDetails  - "Provider 360 / master"
  Grain : ONE row per CURRENT provider (Dim_Provider.IsCurrent = 1).

  Composition:
    - Provider attributes ....... from Dim_Provider (current version)
    - Primary organization ...... from Bridge_ProviderAffiliation (primary)
    - Current specialty/location  from the latest Roster snapshot
    - Active status / tenure ..... from the latest Roster snapshot
    - Network participation ...... collapsed to a count + name list to keep
                                   the grain at one row per provider (avoids
                                   the many-to-many fan-out that would
                                   double-count providers in Power BI)
-----------------------------------------------------------------------------*/
IF OBJECT_ID('rpt.vw_ProviderDetails') IS NOT NULL
    DROP VIEW rpt.vw_ProviderDetails;
GO

CREATE VIEW rpt.vw_ProviderDetails
AS
WITH LatestRoster AS
(
    -- Most recent monthly snapshot per provider gives current operational context.
    SELECT  r.Provider_SK, r.Specialty_SK, r.Location_SK,
            r.IsActiveFlag, r.TenureMonths, r.SnapshotDateKey,
            ROW_NUMBER() OVER (PARTITION BY r.Provider_SK
                               ORDER BY r.SnapshotDateKey DESC) AS rn
    FROM    fact.Fact_ProviderRosterSnapshot AS r
),
NetworkSummary AS
(
    -- Collapse the provider's CURRENT network participation to one row.
    SELECT  p.Provider_SK,
            COUNT(DISTINCT p.Network_SK) AS NetworkCount,
            STRING_AGG(n.NetworkName, ', ')
                WITHIN GROUP (ORDER BY n.NetworkName) AS NetworkNames
    FROM    fact.Fact_ProviderNetworkParticipation AS p
    JOIN    dim.Dim_Network AS n ON n.Network_SK = p.Network_SK
    WHERE   p.IsParticipatingFlag = 1
      AND   p.SnapshotDateKey = (SELECT MAX(SnapshotDateKey)
                                 FROM fact.Fact_ProviderNetworkParticipation)
    GROUP BY p.Provider_SK
)
SELECT
    -- ===== Keys =====
    pr.Provider_SK,
    pr.NPI,

    -- ===== Provider attributes =====
    pr.ProviderFirstName,
    pr.ProviderLastName,
    pr.ProviderFullName,
    pr.Gender,
    pr.CredentialDegree,
    pr.ProviderStatus,
    pr.TelehealthFlag,
    pr.LicenseNumber,
    pr.LicenseStateCode,
    pr.DEANumber,

    -- ===== Specialty (latest snapshot, falls back to provider's denormalized value) =====
    COALESCE(sp.SpecialtyName, pr.PrimarySpecialty) AS SpecialtyName,
    sp.TaxonomyCode,
    sp.SpecialtyGroup,
    sp.ProviderClass,
    ISNULL(sp.IsPrimaryCareFlag, 0)                  AS IsPrimaryCareFlag,

    -- ===== Primary organization (affiliation) =====
    org.OrganizationNPI,
    org.TaxID,
    org.OrganizationName                              AS PrimaryOrganizationName,
    org.OrganizationType,
    aff.AffiliationRole,

    -- ===== Primary practice location (latest snapshot) =====
    loc.AddressLine1,
    loc.City,
    loc.StateCode,
    loc.ZipCode,
    loc.CountyName,
    loc.Latitude,
    loc.Longitude,

    -- ===== Network participation summary =====
    ISNULL(ns.NetworkCount, 0)                        AS NetworkCount,
    ns.NetworkNames,

    -- ===== Roster status =====
    ISNULL(lr.IsActiveFlag, 0)                        AS IsActiveFlag,
    lr.TenureMonths,

    -- ===== SCD lineage (handy for auditing in reports) =====
    pr.EffectiveDate                                  AS ProviderVersionEffectiveDate
FROM        dim.Dim_Provider AS pr
LEFT JOIN   bridge.Bridge_ProviderAffiliation AS aff
                ON  aff.Provider_SK   = pr.Provider_SK
                AND aff.IsPrimaryFlag = 1
                AND aff.IsCurrent     = 1
LEFT JOIN   dim.Dim_ProviderOrganization AS org
                ON  org.Organization_SK = aff.Organization_SK
                AND org.IsCurrent       = 1
LEFT JOIN   LatestRoster AS lr
                ON  lr.Provider_SK = pr.Provider_SK
                AND lr.rn          = 1
LEFT JOIN   dim.Dim_Specialty AS sp ON sp.Specialty_SK = lr.Specialty_SK
LEFT JOIN   dim.Dim_Location  AS loc ON loc.Location_SK = lr.Location_SK
LEFT JOIN   NetworkSummary    AS ns  ON ns.Provider_SK = pr.Provider_SK
WHERE       pr.IsCurrent    = 1
  AND       pr.Provider_SK <> -1;   -- exclude the unknown member
GO
