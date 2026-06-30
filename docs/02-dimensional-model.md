# Dimensional Model Design

## Subject area scope

The **Provider** subject area answers questions such as:

- Which providers participate in which networks, and are they accepting new
  patients?
- How long does credentialing / re-credentialing take, and what is in the
  pipeline?
- How do providers perform on quality measures over time?
- How many active providers do we have by specialty, network, and geography, and
  how is that trending?

## Fact grain declarations

| Fact table | Type | Grain (one row per...) |
|------------|------|------------------------|
| `Fact_ProviderNetworkParticipation` | Periodic snapshot | provider × organization × network × plan × location, per snapshot month |
| `Fact_ProviderCredentialing` | Accumulating snapshot | credentialing application/case |
| `Fact_ProviderQualityMeasure` | Periodic snapshot | provider × quality measure × measurement period |
| `Fact_ProviderRosterSnapshot` | Periodic snapshot | provider × snapshot month |

> The grain is the contract for each fact. Never mix grains in one table — if a
> new requirement implies a different level of detail, it is a new fact.

## Slowly Changing Dimensions (SCD)

Providers and organizations change over time (specialty, address, status). We
track history with **SCD Type 2** on `Dim_Provider` and `Dim_ProviderOrganization`:
each change closes the prior row (`ExpirationDate`, `IsCurrent = 0`) and inserts a
new versioned row with a fresh surrogate key. Reference dimensions
(`Dim_Specialty`, `Dim_Network`, `Dim_Plan`, `Dim_Location`) are SCD Type 1
(overwrite) in this prototype.

## Conformed dimensions

`Dim_Date`, `Dim_Provider`, and `Dim_Location` are designed to be **conformed** —
identical structure and meaning across marts — so the provider mart can later join
to claims and member marts without rework.

## Role-playing dates

`Dim_Date` is referenced multiple times from a single fact under different
business meanings (e.g. credentialing `ReceivedDateKey`, `ApprovedDateKey`,
`NextRecredentialDateKey`). In Power BI these become role-playing relationships or
`USERELATIONSHIP` measures.

## Many-to-many: provider ↔ organization

A provider can practice at many organizations and an organization has many
providers. This many-to-many relationship is resolved with
`Bridge_ProviderAffiliation`, keeping the facts at their declared grain.

## Bus matrix

Rows = business processes (facts). Columns = conformed dimensions. ✔ marks
participation.

| Business process \ Dimension | Date | Provider | Organization | Specialty | Location | Network | Plan |
|------------------------------|:----:|:--------:|:------------:|:---------:|:--------:|:-------:|:----:|
| Network participation        |  ✔   |    ✔     |      ✔       |     ✔     |    ✔     |    ✔    |  ✔   |
| Credentialing                |  ✔   |    ✔     |      ✔       |     ✔     |          |         |      |
| Quality measures             |  ✔   |    ✔     |      ✔       |     ✔     |          |    ✔    |      |
| Roster snapshot              |  ✔   |    ✔     |      ✔       |     ✔     |    ✔     |    ✔    |      |

## Degenerate & junk dimensions

- **Degenerate dimension:** `CredentialingCaseNumber` lives on
  `Fact_ProviderCredentialing` (an operational identifier with no attributes of
  its own).
- **Junk-dimension candidates:** low-cardinality flags such as
  `AcceptingNewPatients`, `TelehealthFlag` are modeled inline for prototype
  simplicity; consolidate into a junk dimension if they proliferate.
