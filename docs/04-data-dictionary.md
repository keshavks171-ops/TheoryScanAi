# Data Dictionary

Field-level documentation for every table in the provider datamart. Use the
right-hand **Power BI source field** column during Phase 1 gap analysis to map
your analyzed report fields to each column (left blank in the prototype).

---

## dim.Dim_Provider  *(SCD Type 2)*
Individual practitioner. One row per version of a provider.

| Column | Type | Description | Power BI source field |
|--------|------|-------------|-----------------------|
| Provider_SK | INT IDENTITY | Surrogate key (PK) | _(generated)_ |
| NPI | CHAR(10) | National Provider Identifier (business key) | |
| ProviderFirstName | VARCHAR(100) | First name | |
| ProviderLastName | VARCHAR(100) | Last name | |
| ProviderFullName | VARCHAR(200) | Display name | |
| Gender | CHAR(1) | M/F/U | |
| CredentialDegree | VARCHAR(50) | MD, DO, NP, PA, ... | |
| PrimarySpecialty | VARCHAR(150) | Denormalized primary specialty | |
| LicenseNumber | VARCHAR(50) | State license number | |
| LicenseStateCode | CHAR(2) | License state | |
| DEANumber | VARCHAR(20) | DEA registration | |
| ProviderStatus | VARCHAR(30) | Active / Inactive / Terminated | |
| TelehealthFlag | BIT | Offers telehealth | |
| EffectiveDate | DATE | SCD2 row start | |
| ExpirationDate | DATE | SCD2 row end (9999-12-31 = open) | |
| IsCurrent | BIT | 1 = current version | |
| DW_SourceSystem / DW_CreatedDate / DW_UpdatedDate | — | Audit columns | |

## dim.Dim_ProviderOrganization  *(SCD Type 2)*
Provider group, facility, or billing organization.

| Column | Type | Description | Power BI source field |
|--------|------|-------------|-----------------------|
| Organization_SK | INT IDENTITY | Surrogate key (PK) | _(generated)_ |
| OrganizationNPI | CHAR(10) | Type-2 (organizational) NPI | |
| TaxID | VARCHAR(15) | TIN / EIN | |
| OrganizationName | VARCHAR(200) | Legal / DBA name | |
| OrganizationType | VARCHAR(50) | Group, Hospital, FQHC, ... | |
| OwnershipType | VARCHAR(50) | Ownership classification | |
| ParentOrganization | VARCHAR(200) | Parent system name | |
| OrganizationStatus | VARCHAR(30) | Status | |
| EffectiveDate / ExpirationDate / IsCurrent | — | SCD2 tracking | |
| DW_* | — | Audit columns | |

## dim.Dim_Specialty  *(SCD Type 1)*
| Column | Type | Description | Power BI source field |
|--------|------|-------------|-----------------------|
| Specialty_SK | INT IDENTITY | Surrogate key (PK) | _(generated)_ |
| TaxonomyCode | VARCHAR(20) | NUCC taxonomy code (business key) | |
| SpecialtyName | VARCHAR(150) | Specialty description | |
| SpecialtyGroup | VARCHAR(100) | Rollup (Primary Care / Specialist) | |
| ProviderClass | VARCHAR(50) | Physician / Dentist / Behavioral | |
| IsPrimaryCareFlag | BIT | PCP indicator | |

## dim.Dim_Location  *(SCD Type 1, conformed)*
| Column | Type | Description | Power BI source field |
|--------|------|-------------|-----------------------|
| Location_SK | INT IDENTITY | Surrogate key (PK) | _(generated)_ |
| LocationBK | VARCHAR(50) | Source location id (business key) | |
| AddressLine1 / AddressLine2 | VARCHAR(150) | Street address | |
| City | VARCHAR(100) | City | |
| StateCode | CHAR(2) | State | |
| ZipCode | VARCHAR(10) | ZIP/postal code | |
| CountyName | VARCHAR(100) | County | |
| Latitude / Longitude | DECIMAL(9,6) | Geocode for mapping visuals | |

## dim.Dim_Network  *(SCD Type 1)*
| Column | Type | Description | Power BI source field |
|--------|------|-------------|-----------------------|
| Network_SK | INT IDENTITY | Surrogate key (PK) | _(generated)_ |
| NetworkCode | VARCHAR(30) | Network code (business key) | |
| NetworkName | VARCHAR(150) | Network name | |
| NetworkType | VARCHAR(50) | HMO / PPO / EPO | |
| LineOfBusiness | VARCHAR(50) | Commercial / Medicare / Medicaid | |

## dim.Dim_Plan  *(SCD Type 1)*
| Column | Type | Description | Power BI source field |
|--------|------|-------------|-----------------------|
| Plan_SK | INT IDENTITY | Surrogate key (PK) | _(generated)_ |
| PlanCode | VARCHAR(30) | Plan/product code (business key) | |
| PlanName | VARCHAR(150) | Product name | |
| ProductType | VARCHAR(50) | Product type | |
| LineOfBusiness | VARCHAR(50) | LOB | |

## dim.Dim_Date  *(conformed calendar)*
| Column | Type | Description |
|--------|------|-------------|
| Date_SK | INT | Surrogate key in yyyymmdd form (PK) |
| FullDate | DATE | Calendar date |
| DayOfMonth / DayName / DayOfWeek | — | Day attributes |
| CalendarWeek / CalendarMonth / MonthName | — | Week & month attributes |
| CalendarQuarter / CalendarYear | — | Quarter & year |
| FirstDayOfMonth / LastDayOfMonth / IsLastDayOfMonth | — | Month boundaries for snapshots |

---

## fact.Fact_ProviderNetworkParticipation  *(periodic snapshot)*
**Grain:** provider × organization × network × plan × location, per snapshot month.

| Column | Type | Role | Power BI source field |
|--------|------|------|-----------------------|
| ParticipationFact_SK | BIGINT IDENTITY | PK | _(generated)_ |
| SnapshotDateKey | INT | FK → Dim_Date | |
| Provider_SK | INT | FK → Dim_Provider | |
| Organization_SK | INT | FK → Dim_ProviderOrganization | |
| Specialty_SK | INT | FK → Dim_Specialty | |
| Location_SK | INT | FK → Dim_Location | |
| Network_SK | INT | FK → Dim_Network | |
| Plan_SK | INT | FK → Dim_Plan | |
| ParticipationStartDateKey / ParticipationEndDateKey | INT | FK → Dim_Date | |
| IsParticipatingFlag | BIT | Measure (flag) | |
| AcceptingNewPatientsFlag | BIT | Measure (flag) | |
| IsParInNetworkFlag | BIT | Par vs non-par | |
| PanelSize | INT | Measure | |

## fact.Fact_ProviderCredentialing  *(accumulating snapshot)*
**Grain:** one credentialing application / case.

| Column | Type | Role | Power BI source field |
|--------|------|------|-----------------------|
| CredentialingFact_SK | BIGINT IDENTITY | PK | _(generated)_ |
| Provider_SK | INT | FK → Dim_Provider | |
| Organization_SK | INT | FK → Dim_ProviderOrganization | |
| Specialty_SK | INT | FK → Dim_Specialty | |
| ReceivedDateKey | INT | FK → Dim_Date (milestone) | |
| CommitteeReviewDateKey | INT | FK → Dim_Date (milestone) | |
| ApprovedDateKey | INT | FK → Dim_Date (milestone) | |
| EffectiveDateKey | INT | FK → Dim_Date (milestone) | |
| NextRecredentialDateKey | INT | FK → Dim_Date (milestone) | |
| CredentialingCaseNumber | VARCHAR(40) | Degenerate dimension | |
| CredentialingType | VARCHAR(30) | Initial / Recredential | |
| CycleTimeDays | INT | Measure (Received→Approved) | |
| IsApprovedFlag | BIT | Measure (flag) | |
| IsExpeditedFlag | BIT | Measure (flag) | |

## fact.Fact_ProviderQualityMeasure  *(periodic snapshot)*
**Grain:** provider × quality measure × measurement period.

| Column | Type | Role | Power BI source field |
|--------|------|------|-----------------------|
| QualityFact_SK | BIGINT IDENTITY | PK | _(generated)_ |
| PeriodDateKey | INT | FK → Dim_Date | |
| Provider_SK | INT | FK → Dim_Provider | |
| Organization_SK | INT | FK → Dim_ProviderOrganization | |
| Specialty_SK | INT | FK → Dim_Specialty | |
| Network_SK | INT | FK → Dim_Network | |
| MeasureCode | VARCHAR(30) | Measure id (e.g. HEDIS) | |
| MeasureName | VARCHAR(150) | Measure description | |
| MeasureNumerator / MeasureDenominator | INT | Measures | |
| MeasureRate | DECIMAL(9,4) | Numerator / denominator | |
| BenchmarkRate | DECIMAL(9,4) | Benchmark | |
| StarRating | DECIMAL(3,1) | Star rating | |

## fact.Fact_ProviderRosterSnapshot  *(periodic snapshot, monthly)*
**Grain:** provider × snapshot month.

| Column | Type | Role | Power BI source field |
|--------|------|------|-----------------------|
| RosterFact_SK | BIGINT IDENTITY | PK | _(generated)_ |
| SnapshotDateKey | INT | FK → Dim_Date | |
| Provider_SK | INT | FK → Dim_Provider | |
| Organization_SK | INT | FK → Dim_ProviderOrganization | |
| Specialty_SK | INT | FK → Dim_Specialty | |
| Location_SK | INT | FK → Dim_Location | |
| Network_SK | INT | FK → Dim_Network | |
| ProviderCount | INT | Additive count (=1 per active provider) | |
| IsActiveFlag | BIT | Measure (flag) | |
| IsNewThisMonthFlag | BIT | Measure (flag) | |
| IsTerminatedFlag | BIT | Measure (flag) | |
| TenureMonths | INT | Measure | |

---

## bridge.Bridge_ProviderAffiliation
Resolves the provider ↔ organization many-to-many.

| Column | Type | Role |
|--------|------|------|
| Affiliation_SK | BIGINT IDENTITY | PK |
| Provider_SK | INT | FK → Dim_Provider |
| Organization_SK | INT | FK → Dim_ProviderOrganization |
| IsPrimaryFlag | BIT | Primary practice location |
| AffiliationRole | VARCHAR(50) | Employed / Contracted / Admitting |
| EffectiveDate / ExpirationDate / IsCurrent | — | Validity window |
