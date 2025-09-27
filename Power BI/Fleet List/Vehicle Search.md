# Vehicle Search Visual Notes

- Template header & navigation icons: the page inherits the red banner/grouped template assets plus a home icon that navigates back to the Landing Page and a warning icon that opens the ManageEngine service-desk URL (request template 12656000006066719) for reporting issues.
- Title textbox 'Vehicle Search' anchors the page.
- Background shape panel: a rounded rectangle behind the filters provides visual grouping for the search controls.
- Filter slicers: six slicers let analysts refine the vehicle list by Fleet No, Registration, Fleet Type, Garage Name, MOT/PVC Certificate number, and Operating Company.
- Clear all slicers button: action button invokes the built-in 'ClearAllSlicers' action with tooltip 'Clear all slicers on this page'.
- Selected asset card: single-value card returns the current fleet number (Min of Fleet No) so users can confirm the active selection when drilling in.
- Main vehicle results table: tabular visual listing Fleet No, body type, registration, company, depot, allocation, fleet type, body/chassis serial numbers, first registration date, MOT expiry, MOT/PVC certificate, tax expiry, sub-group code/description, vehicle age measure, fuel type, and vehicle length. This is the primary searchable grid.
- Body type table: two-column table showing body type against fleet numbers for the filtered subset, enabling quick checks of body configuration.
- Fleet type table: two-column table listing fleet type with fleet numbers to highlight whether search results mix PSV, storage, training, etc.
- Page navigator: ribbon-style navigator (matching other tabs) for switching between report pages without leaving the search view.
