# Veridis Data Visual Notes

- Veridis feed: this page surfaces data from the VerdisView SQL view in the ML-Equinox database. Veridis is Metroline's scheduling/performance platform that records allocation-level operated mileage; the view enriches each allocation with vehicle type, ownership, fuel/engine categorisation, and derived mileage fields before loading into the model.
- Main table: combines Verdis attributes (Consumer Location/Asset, Vehicle Type, Ownership, Fuel Type, Engine Type, Fleet No) with calculated measures PerVehicleOperatedMileage and PerVehicleDeadMileage from the VehicleOperatedMileage calculated table, giving per-vehicle operated/dead mileage by allocation.
- Time slicers: Year, MET Period, and Quarter from DimDateFiltered allow filtering the Verdis dataset to the desired reporting window before exporting.
- Standard navigation: header icons (home + service-desk link) and the page navigator at the bottom mirror the rest of the report.
