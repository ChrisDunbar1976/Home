# Step 1 - Data Model Overview

- Source: Power BI/Example Reports/Metroline Fleet List Template.pbit.extract/DataModelSchema (compatibility level 1567, culture en-US).
- Import model with 27 tables; 11 core tables pull from SQL Server MLNOESQLEXP01 (e.g. vEng_VehicleImportData, FactMileage, vVerdisView, DimRoute, DimGarage).
- vEng_VehicleImportData enriches fleet records via calculated columns for MOT/Tax tracking and MOT certificate URL construction.
- FactMileage trims dbo_FactLostMileageHyperion, adds NewRoute, filters to 2025+, and excludes route N20 before load.
- VehicleOperatedMileage is a calculated table combining calendar dates with Verdis vehicle routes to derive operated/dead mileage per vehicle/day.
- DimDateFiltered scopes DimDate to the VehicleOperatedMileage date span, while 12 LocalDateTable_* objects power auto hierarchies for key date columns.
- Measures Table holds all report measures; LocalDate/DateTableTemplate entries remain hidden support tables.
