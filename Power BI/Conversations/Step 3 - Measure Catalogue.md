# Step 3 - Measure Catalogue

Fleet list measures (Measures Table / Fleet List folder):
- Average Vehicle Age = ROUND(AVERAGEX(VALUES('vEng_VehicleImportData'[Fleet No]), [Vehicle Age (Days)] / 365.25), 2).
- Vehicle Age = ROUND(DATEDIFF(MAX('vEng_VehicleImportData'[Date First Registered]), TODAY(), DAY) / 365.25, 2).
- Vehicle Age (Days) = DATEDIFF(MAX('vEng_VehicleImportData'[Date First Registered]), TODAY(), DAY).
- Total Spare Veh counts vehicles where Vehicle Role LookUp is "Extra Spare-Service" or "Service-TVR Spare" (IF + COUNTROWS filter).
- PercentageOfSpareVehicles = DIVIDE([Total Spare Veh], COUNTROWS(FILTER(vEng_VehicleImportData, NOT CONTAINSSTRING([Fleet Type], "NONPSV"))), 0).
- Expired MOT and Expired Tax use COALESCE(CALCULATE(COUNTROWS(vEng_VehicleImportData), Flag = 1), 0) on MOT Expired and Tax Expired columns.
- PVR Count, TVR Count, TVR Spare Count count rows for Service-Service / Service-TVR Spare role combinations.

Mileage and allocation measures (Measures Table root):
- Scheduled Mileage = SUM(FactMileage[Scheduled Mileage]).
- Operated Mileage = SUM(FactMileage[Operated Mileage]).
- CountVehicleRoute = COUNT(vVerdisView[Fleet No]).
- TotalVehicleCountForRoute = CALCULATE(COUNT(vVerdisView[Fleet No]), ALLEXCEPT(vVerdisView, vVerdisView[Allocation])).
- Vehicles per Route = CALCULATE(DISTINCTCOUNT(vVerdisView[Fleet No]), ALLEXCEPT(vVerdisView, vVerdisView[Allocation])).
- Operated Per Vehicle = [Operated Mileage] * [CountVehicleRoute] / [TotalVehicleCountForRoute].
- PerVehicle Operated Mileage uses VAR route/date to SUM(FactMileage[Operated Mileage]) by route and divide by DISTINCTCOUNT of vehicles on that route (ALL(vVerdisView) to reset other filters).
