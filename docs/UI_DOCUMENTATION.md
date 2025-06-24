# UI Documentation

This document outlines all the UI components in the Hadhir Business Order Receiver App, their responsibilities, key properties, and structure. Use this for troubleshooting UI issues.

---

## Screens

### RegistrationFormScreen (lib/screens/registration_form_screen.dart)

**Class**: `RegistrationFormScreen` (StatefulWidget)

**State Class**: `_RegistrationFormScreenState`

**Description**: Provides a multi-section form for business and owner registration, including text fields, dropdowns, and file/image pickers.

**Key Widgets & Structure**:
- `Form` wrapped in `SingleChildScrollView` with `ScrollController`
- Business Information section:
  - `TextFormField`s for name, phone, email
- Address section (city, district, country, zip, neighborhood, street, home)
- Business Type dropdown: `DropdownButtonFormField<String>`
- Owner Information section:
  - `TextFormField`s for owner name, phone, email, address, national ID, date of birth
- Document upload cards: `_buildDocumentUploadCard`
  - Uses `Card` + `ListTile` + `FilePicker` or `ImagePicker`
- Submit button at bottom validates form

**Validators & Controllers**:
- Uses `GlobalKey<FormState>` for validation
- Individual `TextEditingController`s for each field
- `_pickDocument` and `_pickImage` methods for file selection

**Localization**: All labels and messages use `AppLocalizations.of(context)`.

---

### OrderListScreen (lib/screens/order_list_screen.dart)

**Class**: `OrderListScreen` (StatefulWidget)

**Description**: Shows a scrollable list of orders for the current business with summary cards or list tiles.

**Key Widgets & Structure**:

- `Scaffold` with `AppBar` and `RefreshIndicator`
- `ListView.builder` or `FutureBuilder` for order items
- Custom `OrderCard` or `ListTile` showing order summary

**Data Flow**:

- Retrieves orders via `OrderService.fetchOrders(businessId)`
- Listens to `OrderService.orderStream` for real-time updates

**Key Callbacks**:

- Pull-to-refresh triggers `_loadOrders()`
- Tapping an order navigates to `OrderDetailScreen`

---

### AnalyticsPage (lib/screens/analytics_page.dart)

**Class**: `AnalyticsPage` (StatelessWidget)

**Description**: Displays charts and metrics (sales, orders by status, top items).

**Key Widgets & Structure**:

- `Scaffold` with `AppBar`
- `SingleChildScrollView` containing multiple metric cards
- Chart widgets (`PieChart`, `BarChart`, `LineChart`) from `fl_chart`

**Data Flow**:

- Loads analytics data via `AnalyticsService.getSummary()`

**Key Callbacks**:

- Chart taps call `onChartTap` for details
- Date range filter dropdown calls `_refreshMetrics()`

---

### DashboardScreen (lib/screens/dashboard_screen.dart)

**Class**: `DashboardScreen` (StatelessWidget)

**Description**: Home screen with quick stats and navigation.

**Key Widgets & Structure**:

- `Scaffold` with `AppBar`
- `GridView.count` showing summary cards
- `ElevatedButton`s for quick navigation

**Data Flow**:

- Fetches stats via `DashboardService.getStats()`

**Key Callbacks**:

- Buttons navigate to Orders or Analytics screens

---

### SettingsScreen (lib/screens/settings_screen.dart)

**Class**: `SettingsScreen` (StatefulWidget)

**Description**: Allows configuration of app and business settings.

**Key Widgets & Structure**:

- `Scaffold` with `AppBar`
- `ListView` of `SwitchListTile`, `DropdownButtonFormField`, `TextFormField`

**Data Flow**:

- Loads and saves settings via `SettingsService.loadSettings()` and `SettingsService.updateSetting()`

**Key Callbacks**:

- Switch and dropdown changes update settings immediately

---

## Widgets

### LocationSettingsWidget (lib/widgets/location_settings_widget.dart)

**Description**: UI for picking and displaying a selected location. Wraps a map view and address fields.

**Key Properties**:
- `onLocationChanged`: callback with new latitude/longitude
- `initialLocation`: optional coordinates to center map

**Structure**:
- `Column`
  - `SizedBox` for map preview (e.g., `GoogleMap` or `FlutterMap`)
  - `TextFormField` for address
  - `IconButton` to open full-screen picker


### LanguageSwitcher (lib/widgets/language_switcher.dart)

**Description**: Dropdown or toggle to switch app locale between English and Arabic.

**Key Widgets**:
- `DropdownButton<String>` displaying current locale code
- Updates `Locale` via `MyApp.of(context).setLocale(...)`

---

### MapLocationPicker (lib/widgets/map_location_picker.dart)

**Description**: Full-screen map interface to select a location on tap/long-press.

**Key Features**:
- Uses `FlutterMap` or `GoogleMap` widget
- Marker updates on user interaction
- Confirmation button returns chosen `LatLng`

**Callbacks**:
- `onLocationSelected(LatLng loc)`


---

## Guidelines for Troubleshooting UI

1. **Source of truth**: All text labels come from `lib/l10n/` ARB files. If label missing or wrong language, check `.arb` and regenerate `app_localizations.dart`.
2. **Visual layout**: Inspect padding/margin in `_buildDocumentUploadCard`, `Card` elevations, and use Flutter’s `Widget Inspector`.
3. **Form validation**: Check validators on each `TextFormField`. Ensure `_formKey.currentState!.validate()` triggers.
4. **File/image picker errors**: Confirm proper permissions and plugin setup in `AndroidManifest.xml` and `Info.plist`.

---

_Last updated: 2025-06-19_
