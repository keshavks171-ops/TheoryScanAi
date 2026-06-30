# Provider Datamart (Prototype)

A dimensional (star-schema) datamart for the **Provider** subject area, targeting
**Microsoft SQL Server (T-SQL)** and consumed by Power BI.

This repository is a *design prototype*. It delivers the schema, model
documentation, an entity-relationship diagram, and a field-level data dictionary.
It intentionally does **not** yet include source-to-target ETL or sample data —
those are the next phases (see the roadmap).

## What's here

| Path | Purpose |
|------|---------|
| `docs/01-methodology-and-roadmap.md` | How a datamart is built and the phased plan to take this prototype to production |
| `docs/02-dimensional-model.md`       | Design rationale: grains, SCD strategy, and the bus matrix |
| `docs/03-erd.md`                     | Entity-relationship diagram (Mermaid) |
| `docs/04-data-dictionary.md`         | Every table and column documented |
| `sql/00_schema.sql`                  | Database schemas and naming conventions |
| `sql/01_dimensions.sql`              | Dimension table DDL |
| `sql/02_facts.sql`                   | Fact table DDL |
| `sql/03_bridges.sql`                 | Bridge / many-to-many helper tables |
| `sql/04_constraints_indexes.sql`     | Foreign keys and indexing strategy |

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
```

> The scripts are idempotent-friendly (they check for existence before creating).
> Review `docs/01-methodology-and-roadmap.md` before adapting to your real fields.

## Important: this is a starting point, not your final model

This model is a *standard* healthcare provider datamart. The next step is to map
**your** Power BI report fields onto these tables — see the gap-analysis step in
the roadmap. Fields that don't fit become new columns, new dimensions, or new
facts.
