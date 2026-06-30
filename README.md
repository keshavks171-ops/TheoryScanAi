# Provider Datamart (Prototype)

A dimensional (star-schema) datamart for the **Provider** subject area, targeting
**Microsoft SQL Server (T-SQL)** and consumed by Power BI.

This repository is a *design prototype*. It delivers the schema, model
documentation, an entity-relationship diagram, and a field-level data dictionary.
It intentionally does **not** yet include source-to-target ETL or sample data —
those are the next phases (see the roadmap).

## Architecture (current state)

The datamart is sourced from the existing **enterprise data warehouse (DWH)**,
which is fed from the source applications. The datamart is the dimensional,
Power BI-facing consumption layer.

```
Source applications ──► Enterprise DWH (integrated, cleansed, history kept)
                              │  subject-area extract + dimensional shaping
                              ▼
                      Provider Datamart  (STAR SCHEMA)  ──► Power BI
                      dim.* / fact.* / bridge.*
```

> A future Bronze → Silver → Gold (medallion) architecture is planned. When it
> lands, this datamart becomes the **Gold** layer unchanged — only its source
> shifts from "current DWH" to "Silver." The star-schema design is identical
> either way.

## Key design decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Datamart model | **Star schema** (dimensional) | Optimal for Power BI / DAX; simple, fast, reusable |
| Source | **Existing enterprise DWH** | DWH already integrates & cleanses; datamart only shapes & selects |
| Provider history (SCD) | **SCD Type 2, passed through from the DWH** | DWH already maintains provider history — the load maps existing versioned rows; no change detection needed in the datamart |
| Surrogate keys | **Owned by the datamart** | Insulates Power BI from DWH key changes; powers the star join |
| Persistence | **Materialized physical tables** on a scheduled load | Best for Power BI Import; decouples report load from DWH load |
| Indexing | **Rowstore PK + non-clustered FK indexes** | Provider dim is < 1M rows — columnstore not needed at this volume |
| Fact grain | **Atomic** | Let Power BI aggregate; answers future questions; add summaries only on demand |
| Refresh order | DWH load → dimensions → facts → Power BI dataset | Respects dependencies |

## What's here

| Path | Purpose |
|------|---------|
| `docs/01-methodology-and-roadmap.md` | How a datamart is built and the phased plan to take this prototype to production |
| `docs/02-dimensional-model.md`       | Design rationale: grains, SCD strategy, and the bus matrix |
| `docs/03-erd.md`                     | Entity-relationship diagram (Mermaid) |
| `docs/04-data-dictionary.md`         | Every table and column documented |
| `docs/05-architecture-and-load.md`   | DWH-sourced architecture, SCD pass-through, and load strategy |
| `docs/06-source-to-target-mapping.md`| Template mapping each datamart column to its DWH source column |
| `sql/00_schema.sql`                  | Database schemas and naming conventions |
| `sql/01_dimensions.sql`              | Dimension table DDL |
| `sql/02_facts.sql`                   | Fact table DDL |
| `sql/03_bridges.sql`                 | Bridge / many-to-many helper tables |
| `sql/04_constraints_indexes.sql`     | Foreign keys and indexing strategy |
| `sql/05_sample_data.sql`             | Optional illustrative demo data (fictitious) |

## The model at a glance

**Dimensions**
- `Dim_Provider` — individual practitioner (SCD Type 2)
- `Dim_ProviderOrganization` — group / facility (SCD Type 2)
- `Dim_Specialty` — specialty & taxonomy
- `Dim_Location` — practice location / geography
- `Dim_Network` — provider networks
- `Dim_Plan` — health-plan products / line of business
- `Dim_Date` — conformed calendar dimension

**Facts**
- `Fact_ProviderNetworkParticipation` — periodic snapshot of who is in which network
- `Fact_ProviderCredentialing` — accumulating snapshot of the credentialing lifecycle
- `Fact_ProviderQualityMeasure` — periodic snapshot of quality/performance measures
- `Fact_ProviderRosterSnapshot` — monthly roster snapshot for counts & trending

**Bridges**
- `Bridge_ProviderAffiliation` — many-to-many provider ↔ organization

## How to deploy the prototype

Run the scripts in order against a SQL Server database:

```sql
:r sql/00_schema.sql
:r sql/01_dimensions.sql
:r sql/02_facts.sql
:r sql/03_bridges.sql
:r sql/04_constraints_indexes.sql
:r sql/05_sample_data.sql   -- optional: illustrative demo data
```

> The scripts are idempotent-friendly (they check for existence before creating).
> Review `docs/01-methodology-and-roadmap.md` before adapting to your real fields.

`05_sample_data.sql` is **optional**. It generates the `Dim_Date` calendar and
loads a small set of fictitious providers, organizations, networks, plans, and
fact rows so the star schema can be queried and connected to Power BI without a
live DWH feed. Every demo row is tagged `DW_SourceSystem = 'SAMPLE'`, so it is
easy to remove before a real load (e.g. `DELETE FROM fact.Fact_ProviderRosterSnapshot
WHERE DW_SourceSystem = 'SAMPLE';`, and likewise for the other `fact.*`,
`bridge.*`, and `dim.*` tables).

## Important: this is a starting point, not your final model

This model is a *standard* healthcare provider datamart. The next step is to map
**your** Power BI report fields onto these tables — see the gap-analysis step in
the roadmap. Fields that don't fit become new columns, new dimensions, or new
facts.
