# Step 2 - Relationship Topology

- Total of 19 relationships defined; majority are single-direction with joinOnDateBehavior = datePartOnly for auto date tables.
- vEng_VehicleImportData is central: bi-directional one-to-many joins to vEng_FleetSORN and FactNONPSVExtraDetails, plus standard single-direction links to vEng_VehicleTemplate and DimGarage.
- FactMileage connects to vVerdisView through a many-to-many style join (Allocation -> NewRoute) allowing allocation slicers to shape mileage results.
- VehicleOperatedMileage calculated table links back to vVerdisView (FleetNo) and DimDateFiltered (DateKey) to expose per-vehicle mileage in visuals.
- DimDateFiltered and DimDate rely on dedicated LocalDateTable_* companions for their key date columns (DateKey, WeekEndingMET, WeekEndingTFL, MOT/Tax dates, etc.).
- No direct DimDate -> FactMileage relationship; date slicing goes through LocalDateTable objects or DimDateFiltered to avoid disconnected filters.
