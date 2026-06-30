# Architecture & Load Strategy

This document records the **current-state** architecture for the provider
datamart and the load decisions that follow from it.

## Current architecture

The datamart is sourced from the existing **enterprise data warehouse (DWH)**,
which is fed from the source applications. Because the DWH already integrates,
cleanses, and historizes data, the datamart's job is narrow: *select the provider
subject area, shape it into a star schema, and own the surrogate keys.*

```
Source applications ──► Enterprise DWH ──► Provider Datamart (star) ──► Power BI
                        integrated,          dim.* / fact.* / bridge.*
                        cleansed,
                        history kept
```

### Future state (planned, not built)

A Bronze → Silver → Gold medallion architecture is planned. Mapping:
Bronze = staging, Silver = data warehouse, Gold = datamart. When it arrives this
datamart **becomes the Gold layer unchanged** — only the source moves from the
current DWH to Silver. The dimensional design does not change, which is why it is
safe to build now.

## Confirmed facts that drove the design

| Question | Answer | Design consequence |
|----------|--------|--------------------|
| Does the DWH track provider history? | **Yes** | Datamart uses **SCD2 pass-through** — map the DWH's versioned rows; no change detection in the load. |
| Provider dimension volume? | **< 1M rows** | **Materialized tables** with rowstore PK + non-clustered FK indexes; columnstore not needed. |

## SCD2 pass-through (because the DWH keeps history)

The DWH already stores effective-dated versions of each provider/organization.
The datamart load therefore **does not detect changes** — it maps each DWH version
to one dimension row and assigns a surrogate key per version.

Conceptual load for `Dim_Provider`:

```sql
-- One dimension row per DWH provider version.
-- Map the DWH's effective dates straight into the SCD2 columns; the datamart
-- only adds the surrogate key (IDENTITY) and a current-flag derived from dates.
INSERT INTO dim.Dim_Provider
    (NPI, ProviderFirstName, ProviderLastName, ProviderFullName, Gender,
     CredentialDegree, PrimarySpecialty, LicenseNumber, LicenseStateCode,
     DEANumber, ProviderStatus, TelehealthFlag,
     EffectiveDate, ExpirationDate, IsCurrent, DW_SourceSystem)
SELECT
     src.NPI, src.FirstName, src.LastName, src.FullName, src.Gender,
     src.Degree, src.PrimarySpecialty, src.LicenseNumber, src.LicenseState,
     src.DEANumber, src.Status, src.TelehealthFlag,
     src.EffectiveDate,                              -- from DWH
     ISNULL(src.EndDate, '9999-12-31'),              -- from DWH
     CASE WHEN src.EndDate IS NULL THEN 1 ELSE 0 END,
     'DWH'
FROM dwh.ProviderHistory AS src;                     -- adjust to real table
```

> Map column names to the real DWH columns in `06-source-to-target-mapping.md`.
> If a fact event must join to the *version of the provider valid at the event
> date*, resolve the surrogate key by `NPI` where the event date falls between
> `EffectiveDate` and `ExpirationDate`.

## Persistence & indexing (because volume is small)

- **Materialize** dimensions and facts as physical tables, refreshed on a
  schedule. This gives Power BI Import the best performance and decouples report
  refresh from the DWH load.
- **Indexing:** the rowstore primary keys plus the non-clustered FK indexes in
  `sql/04_constraints_indexes.sql` are sufficient at < 1M provider rows.
  Clustered columnstore is **not** required now; revisit only if a fact table
  grows into the tens of millions of rows.
- Small, slowly-changing reference dims (e.g. `Dim_Specialty`) could alternatively
  be exposed as views over the DWH — optional, since materializing them is cheap.

## Load order & scheduling

1. **DWH load completes** (upstream dependency — trigger off its success).
2. **Load dimensions** (`dim.*`), SCD2 pass-through.
3. **Load facts** (`fact.*`) and **bridge** (`bridge.*`), resolving surrogate keys.
4. **Refresh the Power BI dataset.**

Keep the steps idempotent and restartable. Truncate-and-reload is acceptable for
the reference dimensions and small facts at this volume; switch to incremental
(merge by business key + effective date) if load windows get tight.
