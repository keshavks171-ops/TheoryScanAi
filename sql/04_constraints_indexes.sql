/*=============================================================================
  Provider Datamart - 04_constraints_indexes.sql
  Foreign keys, unique constraints, and indexing strategy.
  Target: Microsoft SQL Server (T-SQL)

  Run last. Adds referential integrity from facts/bridges to dimensions and a
  baseline set of indexes for typical Power BI query patterns.
=============================================================================*/

/*-----------------------------------------------------------------------------
  Natural-key uniqueness on dimensions
  For SCD Type 2 dimensions the natural key alone is NOT unique (history),
  so uniqueness is on (BusinessKey, EffectiveDate).
-----------------------------------------------------------------------------*/
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Provider_NPI_Eff')
    CREATE UNIQUE INDEX UX_Dim_Provider_NPI_Eff
        ON dim.Dim_Provider (NPI, EffectiveDate);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Dim_Provider_Current')
    CREATE INDEX IX_Dim_Provider_Current
        ON dim.Dim_Provider (NPI) WHERE IsCurrent = 1;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Org_NPI_Eff')
    CREATE UNIQUE INDEX UX_Dim_Org_NPI_Eff
        ON dim.Dim_ProviderOrganization (OrganizationName, EffectiveDate);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Specialty_Taxonomy')
    CREATE UNIQUE INDEX UX_Dim_Specialty_Taxonomy
        ON dim.Dim_Specialty (TaxonomyCode);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Network_Code')
    CREATE UNIQUE INDEX UX_Dim_Network_Code ON dim.Dim_Network (NetworkCode);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Plan_Code')
    CREATE UNIQUE INDEX UX_Dim_Plan_Code ON dim.Dim_Plan (PlanCode);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Dim_Location_BK')
    CREATE UNIQUE INDEX UX_Dim_Location_BK ON dim.Dim_Location (LocationBK);
GO

/*-----------------------------------------------------------------------------
  Foreign keys: Fact_ProviderNetworkParticipation
-----------------------------------------------------------------------------*/
ALTER TABLE fact.Fact_ProviderNetworkParticipation WITH CHECK
    ADD CONSTRAINT FK_FNP_Date FOREIGN KEY (SnapshotDateKey) REFERENCES dim.Dim_Date (Date_SK);
ALTER TABLE fact.Fact_ProviderNetworkParticipation WITH CHECK
    ADD CONSTRAINT FK_FNP_Provider FOREIGN KEY (Provider_SK) REFERENCES dim.Dim_Provider (Provider_SK);
ALTER TABLE fact.Fact_ProviderNetworkParticipation WITH CHECK
    ADD CONSTRAINT FK_FNP_Org FOREIGN KEY (Organization_SK) REFERENCES dim.Dim_ProviderOrganization (Organization_SK);
ALTER TABLE fact.Fact_ProviderNetworkParticipation WITH CHECK
    ADD CONSTRAINT FK_FNP_Specialty FOREIGN KEY (Specialty_SK) REFERENCES dim.Dim_Specialty (Specialty_SK);
ALTER TABLE fact.Fact_ProviderNetworkParticipation WITH CHECK
    ADD CONSTRAINT FK_FNP_Location FOREIGN KEY (Location_SK) REFERENCES dim.Dim_Location (Location_SK);
ALTER TABLE fact.Fact_ProviderNetworkParticipation WITH CHECK
    ADD CONSTRAINT FK_FNP_Network FOREIGN KEY (Network_SK) REFERENCES dim.Dim_Network (Network_SK);
ALTER TABLE fact.Fact_ProviderNetworkParticipation WITH CHECK
    ADD CONSTRAINT FK_FNP_Plan FOREIGN KEY (Plan_SK) REFERENCES dim.Dim_Plan (Plan_SK);
GO

/*-----------------------------------------------------------------------------
  Foreign keys: Fact_ProviderCredentialing (role-playing dates)
-----------------------------------------------------------------------------*/
ALTER TABLE fact.Fact_ProviderCredentialing WITH CHECK
    ADD CONSTRAINT FK_FC_Provider FOREIGN KEY (Provider_SK) REFERENCES dim.Dim_Provider (Provider_SK);
ALTER TABLE fact.Fact_ProviderCredentialing WITH CHECK
    ADD CONSTRAINT FK_FC_Org FOREIGN KEY (Organization_SK) REFERENCES dim.Dim_ProviderOrganization (Organization_SK);
ALTER TABLE fact.Fact_ProviderCredentialing WITH CHECK
    ADD CONSTRAINT FK_FC_Specialty FOREIGN KEY (Specialty_SK) REFERENCES dim.Dim_Specialty (Specialty_SK);
ALTER TABLE fact.Fact_ProviderCredentialing WITH CHECK
    ADD CONSTRAINT FK_FC_Received FOREIGN KEY (ReceivedDateKey) REFERENCES dim.Dim_Date (Date_SK);
ALTER TABLE fact.Fact_ProviderCredentialing WITH CHECK
    ADD CONSTRAINT FK_FC_Approved FOREIGN KEY (ApprovedDateKey) REFERENCES dim.Dim_Date (Date_SK);
GO

/*-----------------------------------------------------------------------------
  Foreign keys: Fact_ProviderQualityMeasure
-----------------------------------------------------------------------------*/
ALTER TABLE fact.Fact_ProviderQualityMeasure WITH CHECK
    ADD CONSTRAINT FK_FQ_Date FOREIGN KEY (PeriodDateKey) REFERENCES dim.Dim_Date (Date_SK);
ALTER TABLE fact.Fact_ProviderQualityMeasure WITH CHECK
    ADD CONSTRAINT FK_FQ_Provider FOREIGN KEY (Provider_SK) REFERENCES dim.Dim_Provider (Provider_SK);
ALTER TABLE fact.Fact_ProviderQualityMeasure WITH CHECK
    ADD CONSTRAINT FK_FQ_Org FOREIGN KEY (Organization_SK) REFERENCES dim.Dim_ProviderOrganization (Organization_SK);
ALTER TABLE fact.Fact_ProviderQualityMeasure WITH CHECK
    ADD CONSTRAINT FK_FQ_Specialty FOREIGN KEY (Specialty_SK) REFERENCES dim.Dim_Specialty (Specialty_SK);
ALTER TABLE fact.Fact_ProviderQualityMeasure WITH CHECK
    ADD CONSTRAINT FK_FQ_Network FOREIGN KEY (Network_SK) REFERENCES dim.Dim_Network (Network_SK);
GO

/*-----------------------------------------------------------------------------
  Foreign keys: Fact_ProviderRosterSnapshot
-----------------------------------------------------------------------------*/
ALTER TABLE fact.Fact_ProviderRosterSnapshot WITH CHECK
    ADD CONSTRAINT FK_FR_Date FOREIGN KEY (SnapshotDateKey) REFERENCES dim.Dim_Date (Date_SK);
ALTER TABLE fact.Fact_ProviderRosterSnapshot WITH CHECK
    ADD CONSTRAINT FK_FR_Provider FOREIGN KEY (Provider_SK) REFERENCES dim.Dim_Provider (Provider_SK);
ALTER TABLE fact.Fact_ProviderRosterSnapshot WITH CHECK
    ADD CONSTRAINT FK_FR_Org FOREIGN KEY (Organization_SK) REFERENCES dim.Dim_ProviderOrganization (Organization_SK);
ALTER TABLE fact.Fact_ProviderRosterSnapshot WITH CHECK
    ADD CONSTRAINT FK_FR_Specialty FOREIGN KEY (Specialty_SK) REFERENCES dim.Dim_Specialty (Specialty_SK);
ALTER TABLE fact.Fact_ProviderRosterSnapshot WITH CHECK
    ADD CONSTRAINT FK_FR_Location FOREIGN KEY (Location_SK) REFERENCES dim.Dim_Location (Location_SK);
ALTER TABLE fact.Fact_ProviderRosterSnapshot WITH CHECK
    ADD CONSTRAINT FK_FR_Network FOREIGN KEY (Network_SK) REFERENCES dim.Dim_Network (Network_SK);
GO

/*-----------------------------------------------------------------------------
  Foreign keys: Bridge_ProviderAffiliation
-----------------------------------------------------------------------------*/
ALTER TABLE bridge.Bridge_ProviderAffiliation WITH CHECK
    ADD CONSTRAINT FK_BPA_Provider FOREIGN KEY (Provider_SK) REFERENCES dim.Dim_Provider (Provider_SK);
ALTER TABLE bridge.Bridge_ProviderAffiliation WITH CHECK
    ADD CONSTRAINT FK_BPA_Org FOREIGN KEY (Organization_SK) REFERENCES dim.Dim_ProviderOrganization (Organization_SK);
GO

/*-----------------------------------------------------------------------------
  Foreign-key (non-clustered) indexes on facts.
  SQL Server does not auto-index FK columns; these support star-join filtering.
-----------------------------------------------------------------------------*/
CREATE INDEX IX_FNP_Provider ON fact.Fact_ProviderNetworkParticipation (Provider_SK);
CREATE INDEX IX_FNP_Network  ON fact.Fact_ProviderNetworkParticipation (Network_SK);
CREATE INDEX IX_FNP_Date     ON fact.Fact_ProviderNetworkParticipation (SnapshotDateKey);
CREATE INDEX IX_FC_Provider  ON fact.Fact_ProviderCredentialing (Provider_SK);
CREATE INDEX IX_FC_Received  ON fact.Fact_ProviderCredentialing (ReceivedDateKey);
CREATE INDEX IX_FQ_Provider  ON fact.Fact_ProviderQualityMeasure (Provider_SK);
CREATE INDEX IX_FQ_Date      ON fact.Fact_ProviderQualityMeasure (PeriodDateKey);
CREATE INDEX IX_FR_Provider  ON fact.Fact_ProviderRosterSnapshot (Provider_SK);
CREATE INDEX IX_FR_Date      ON fact.Fact_ProviderRosterSnapshot (SnapshotDateKey);
CREATE INDEX IX_BPA_Provider ON bridge.Bridge_ProviderAffiliation (Provider_SK);
CREATE INDEX IX_BPA_Org      ON bridge.Bridge_ProviderAffiliation (Organization_SK);
GO

/*-----------------------------------------------------------------------------
  For large fact volumes, consider clustered columnstore indexes instead of the
  rowstore PK + NCIs above, e.g.:
    CREATE CLUSTERED COLUMNSTORE INDEX CCI_Fact_ProviderRosterSnapshot
        ON fact.Fact_ProviderRosterSnapshot;
  Columnstore is typically the best fit for Power BI DirectQuery/Import at scale.
-----------------------------------------------------------------------------*/
