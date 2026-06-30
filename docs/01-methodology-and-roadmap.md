# Methodology & Roadmap

This document explains *how* to build a provider datamart and lays out the phased
plan to take this prototype from design to a production-grade, Power BI-ready mart.

## The approach: Kimball dimensional modeling

A datamart is a subject-area-focused slice of an analytics platform, modeled
dimensionally (star schema) so it is fast to query and intuitive in Power BI.
We follow the Kimball four-step design process:

1. **Select the business process.** Here: managing the *provider* — network
   participation, credentialing, quality, and roster reporting.
2. **Declare the grain.** The level of detail of one fact row. We define one grain
   per fact table (see `02-dimensional-model.md`). Getting the grain right is the
   single most important modeling decision.
3. **Identify the dimensions.** The "who / what / where / when" — provider,
   organization, specialty, location, network, plan, date.
4. **Identify the facts.** The numeric measures and the events being measured.

### Why dimensional (and not just copy the Power BI tables)?

Power BI reports are *presentation*-shaped — already filtered, joined, and
aggregated for a specific question. A datamart is *foundation*-shaped: a clean,
conformed, reusable set of dimensions and facts that can answer many questions,
including future ones the current reports don't ask. Conformed dimensions also
let the provider mart join cleanly to other marts (claims, members) later.

## How to use your Power BI field analysis

You already extracted the fields used across the provider reports. Classify each
field into one of four buckets — this is the bridge from "report fields" to
"datamart objects":

| If the field is... | It becomes... | Example |
|--------------------|---------------|---------|
| A descriptive attribute you filter/group by | A **dimension column** | Specialty, Provider Status, State |
| A unique identifier of a thing | A **dimension business key** | NPI, Tax ID |
| A number you sum/average/count | A **fact measure** | Panel size, Quality rate, Cycle-time days |
| A date you slice by | A **role-playing `Dim_Date`** FK | Effective date, Credentialed date |

Anything that doesn't fit is a signal: you may need a new dimension, a new fact,
or a degenerate/junk dimension.

## Phased roadmap

### Phase 0 — Design (this prototype) ✅
- Star-schema model, ERD, DDL, data dictionary.
- **Deliverable:** the contents of this repo.

### Phase 1 — Field gap analysis (next)
- Map every Power BI report field to a table.column in this model.
- Flag gaps: fields with no home, and model columns with no source.
- **Deliverable:** a source-to-target mapping (extend `04-data-dictionary.md`).

### Phase 2 — Source profiling & staging
- Identify systems of record (credentialing system, provider master / MDM,
  network/contracting, quality engine).
- Profile data quality (NPI completeness, duplicate providers, address quality).
- Build a `staging` layer that lands raw source extracts.

### Phase 3 — ETL / ELT to the mart
- Load dimensions first (with SCD Type 2 handling), then facts.
- Generate surrogate keys, resolve late-arriving dimensions, enforce the grain.
- Tooling options on SQL Server: stored procedures, SSIS, Azure Data Factory,
  or dbt. For a prototype, stored procedures or dbt are the fastest path.

### Phase 4 — Validation & seed data
- Add synthetic/sample data to demo end-to-end.
- Reconcile mart aggregates against the original Power BI report numbers.

### Phase 5 — Semantic layer & reports
- Build a Power BI dataset (model) on top of the mart: relationships, measures
  (DAX), and a date table marked as the date dimension.
- Re-point or rebuild the existing provider reports against the mart.

## Conventions used in this prototype

- **Schemas:** `dim`, `fact`, `bridge`, `stg` (staging, reserved for later).
- **Surrogate keys:** `*_SK`, `INT IDENTITY`, the primary key of every dimension.
- **Business/natural keys:** `*_BK` or named (e.g. `NPI`), carried from source.
- **SCD Type 2 columns:** `EffectiveDate`, `ExpirationDate`, `IsCurrent`.
- **Audit columns:** `DW_CreatedDate`, `DW_UpdatedDate`, `DW_SourceSystem`.
- **Unknown member:** every dimension has a `-1` row so facts never lose rows on
  a failed lookup.
- **Naming:** `Dim_*`, `Fact_*`, `Bridge_*`; PascalCase columns.
