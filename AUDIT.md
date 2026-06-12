# Zayi Project Audit & Recommendations

## 1. Architecture & Modularity

### Current State
- The app uses Riverpod for state management, which is excellent.
- However, there is a tight coupling between the State layer (Providers) and the Data layer (`DatabaseHelper`).
- `DatabaseHelper` is a "God Object" (1300+ lines) handling schema, migrations, and all business queries.

### Recommendations
- **Introduce Repository Pattern:** Create abstract repository classes (e.g., `SaleRepository`) that define the data operations. This allows for better testing (mocking) and easier swaps of data sources in the future.
- **Modularize Database Access (DAOs):** Split the massive `DatabaseHelper` into specific Data Access Objects (DAOs) like `SalesDao`, `InventoryDao`, and `SettingsDao`.
- **Dependency Injection:** Use Riverpod to provide these repositories/DAOs to the state notifiers.

---

## 2. Models & Boilerplate

### Current State
- Models are manually implemented with `fromMap` and `toMap` methods.
- This is error-prone and tedious to maintain as fields are added or changed.

### Recommendations
- **Use `freezed` and `json_serializable`:** These tools will automatically generate `copyWith`, `fromMap`, `toMap`, and equality checks. It significantly reduces boilerplate and prevents bugs in data mapping.

---

## 3. Database Safety & Migrations

### Current State
- **CRITICAL:** `DatabaseHelper` has `const bool forceRecreate = true;` which deletes the entire database on every app start. This must be removed before production.
- Migrations are handled via a long `_onUpgrade` method.

### Recommendations
- **Fix `forceRecreate`:** Guard this with `kDebugMode` or remove it entirely in favor of controlled developer tools.
- **Structured Migrations:** Consider a more structured way to handle migrations (e.g., separate migration scripts or a version-controlled migration list).

---

## 4. UI & Theme

### Current State
- Uses `InstaPalette` for colors/spacing.
- Some screens still have hardcoded styles and layout values.

### Recommendations
- **Centralize Theme:** Fully leverage `ThemeData` (colorScheme, textTheme) so that changes in the theme file reflect across the entire app without manual tweaks in individual widgets.
- **Componentize Widgets:** Identify repeating UI patterns and move them into reusable widgets in the `widgets/` directory.

---

## 5. General Best Practices

- **Naming:** Update `pubspec.yaml` name from `egg_trader` to `zayi` to match the project identity.
- **Constants:** Move magic strings (currency codes, etc.) to a `constants.dart` file.
- **Validation:** Add business logic validation in the service/repository layer rather than relying on database constraints alone.

## Proposed Action Plan

1.  **Immediate:** Fix `forceRecreate` in `DatabaseHelper`.
2.  **Structural:** Begin refactoring `DatabaseHelper` into separate DAOs.
3.  **Boilerplate:** Migrate core models (`Sale`, `Product`) to `freezed`.
4.  **Architectural:** Introduce Repositories for Sales and Inventory.
