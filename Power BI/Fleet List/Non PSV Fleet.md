# Non PSV Fleet Visual Notes

- Template header & icons: retains the standard navigation strip plus home (page navigation back to Landing Page) and warning icon linking to the service-desk request form for vehicle issues.
- Title textbox marks the page as "NON PSV Fleet"; background grouping keeps the layout consistent with the PSV overview pages.
- Depot donut (top-left): counts the 55 non-PSV vehicles by operating depot using vEng_VehicleImportData, with the total shown in the centre.
- Non-PSV company matrix (top-centre pivot): row hierarchy of operating company/garage with metrics for fleet count, share of total, average vehicle age, spare counts, and spare percentage?leveraging the same fleet measures but filtered to the non-PSV slice.
- Fuel-by-garage pivot (top-right): cross-tab of DimGarage vs FactNONPSVExtraDetails fuel type (Diesel/Electric/Petrol) to highlight propulsion mix for vans/cars at each site.
- KPI cards (Expired MOT, Expired Tax, Vehicles SORN): track compliance posture for the non-PSV vehicles using MOT/Tax flags and SORN linkage (currently only MOT shows non-zero risk).
- Role description tables (bottom-left): first table lists detailed vehicle role descriptions with counts (e.g., Company Car, Ferry Vehicle, Workshop Van); the adjacent table rolls those into broader sub-descriptions (Car vs Van) for a macro breakdown.
- Selected vehicle card: echoes the currently highlighted fleet number (Min Fleet No) when drilling into the detail grid.
- Vehicle detail table (bottom-centre): master list of non-PSV assets showing fleet number, registration, depot, vehicle role, MOT/tax expiry dates, and manufacturer/model/fuel from FactNONPSVExtraDetails.
- Page navigator: consistent navigation control at the bottom for moving between report tabs.
