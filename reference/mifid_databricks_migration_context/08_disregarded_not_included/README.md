# Disregarded files for current MiFID table-generation scope

These uploaded files are intentionally not included in the active migration folders because they are not part of the current MiFID table-generation scope:

- US regulatory procedures:
  - SP_Reg_US_Customers.sql
  - [SP_Reg_US_NOrders].sql
  - [SP_Reg_US_ROrders].sql
  - [SP_Reg_US_Reconsile].sql

- ASIC2 collateral / hedge-only procedures, unless future inspection proves they affect the MiFID-compatible ASIC2 subset:
  - SP_ASIC_CollateralReport.sql
  - SP_ASIC_TransactionsReport_Hedge.sql
  - SP_ASIC_PositionReport_Agg_Hedge.sql

Legacy ASIC tables/procedures should not be used as the source of truth. The current MiFID migration should use ASIC2 where an ASIC dependency is required.
