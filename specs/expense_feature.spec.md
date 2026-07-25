# Expense Tracker — Phase 1: Core Features
## Feature Specification Document

**Author:** Senior Software Architect
**Version:** 1.0.0
**Status:** Approved for Implementation
**Date:** 2026-07-25

---

## Table of Contents

1. [Overview](#1-overview)
2. [Architecture & Tech Stack](#2-architecture--tech-stack)
3. [Data Models](#3-data-models)
4. [Layer-by-Layer Breakdown](#4-layer-by-layer-breakdown)
   - 4.1 [Data Layer — Datasources](#41-data-layer--datasources)
   - 4.2 [Data Layer — Repository Implementation](#42-data-layer--repository-implementation)
   - 4.3 [Domain Layer — Use Cases](#43-domain-layer--use-cases)
   - 4.4 [Presentation Layer — Cubit](#44-presentation-layer--cubit)
5. [UI/UX Requirements](#5-uiux-requirements)
   - 5.1 [DashboardPage](#51-dashboardpage)
   - 5.2 [AddExpensePage](#52-addexpensepage)
   - 5.3 [Shared Components](#53-shared-components)
6. [Navigation Map](#6-navigation-map)
7. [Dependency Injection](#7-dependency-injection)
8. [Error Handling Strategy](#8-error-handling-strategy)
9. [Local Storage Schema (Hive)](#9-local-storage-schema-hive)
10. [Acceptance Criteria](#10-acceptance-criteria)

---

## 1. Overview

Phase 1 delivers a **fully interactive expense tracking experience** powered entirely by **local Hive storage**. No Firebase credentials are required at this stage. The feature set covers:

- Viewing a live financial dashboard (balance, income, expenses)
- Adding, editing, and deleting expense/income entries
- Categorising transactions and filtering by date
- Persisting data offline between app sessions

> **Firebase Note:** The architecture is designed so that the `ExpenseRemoteDatasource` (Firestore) can be **swapped in** at Phase 2 without touching any domain or presentation code.

---

## 2. Architecture & Tech Stack

### Principle
Strict **Clean Architecture** — each layer depends only on the layer inside it. The domain layer is pure Dart with zero external dependencies.

```
┌─────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                  │
│  go_router · flutter_bloc (Cubit) · Material 3 UI  │
└────────────────────────┬────────────────────────────┘
                         │ depends on
┌────────────────────────▼────────────────────────────┐
│                   DOMAIN LAYER                      │
│   Entities · Repository Contracts · Use Cases       │
│            ← Pure Dart. No Flutter. →               │
└────────────────────────┬────────────────────────────┘
                         │ implements
┌────────────────────────▼────────────────────────────┐
│                    DATA LAYER                       │
│   Hive Datasource · Models (DTOs) · Repo Impls      │
└─────────────────────────────────────────────────────┘
```

### Tech Stack

| Concern | Tool | Version |
|---|---|---|
| Language | Dart | ≥ 3.0 |
| Framework | Flutter | ≥ 3.10 |
| State Management | `flutter_bloc` (Cubit) | ^8.1.6 |
| Dependency Injection | `get_it` + `injectable` | ^8.0.2 / ^2.4.4 |
| Local Storage | `hive` + `hive_flutter` | ^2.2.3 / ^1.1.0 |
| Navigation | `go_router` | ^14.3.0 |
| Functional Types | `dartz` | ^0.10.1 |
| Equality | `equatable` | ^2.0.5 |
| Unique IDs | `uuid` | ^4.5.1 |
| Formatting | `intl` | ^0.19.0 |
| UI / Fonts | `google_fonts`, `iconsax` | ^6.2.1 / ^0.0.8 |

---

## 3. Data Models

### 3.1 `ExpenseEntity` — Domain Layer

The canonical business object. Contains **no serialisation logic**.

| Field | Type | Nullable | Description |
|---|---|---|---|
| `id` | `String` | ✗ | Unique identifier (UUIDv4) |
| `title` | `String` | ✗ | Short transaction label (e.g. "Burger King") |
| `amount` | `double` | ✗ | Absolute monetary value. Always positive. |
| `date` | `DateTime` | ✗ | Date the transaction occurred |
| `categoryId` | `String` | ✗ | FK to a `Category` slug (e.g. `"food"`) |
| `categoryName` | `String` | ✗ | Denormalized display name for performance |
| `isIncome` | `bool` | ✗ | `true` = income entry, `false` = expense |
| `note` | `String?` | ✓ | Optional memo / description |
| `createdAt` | `DateTime` | ✗ | Record creation timestamp |
| `updatedAt` | `DateTime` | ✗ | Last modification timestamp |

**Computed helpers (on entity):**
- `signedAmount` → `isIncome ? amount : -amount`
- `formattedAmount` → `"\$1,200.00"` string via `AppFormatters`

---

### 3.2 `ExpenseModel` — Data Layer

Extends `ExpenseEntity`. Adds Hive serialisation support via `TypeAdapter`.

| Additional Concern | Detail |
|---|---|
| Hive TypeId | `0` (reserved for `ExpenseModel`) |
| Serialisation | `toMap()` / `fromMap(Map<String, dynamic>)` |
| Hive fields | Each entity field gets a `@HiveField(n)` annotation |
| Factory constructors | `ExpenseModel.fromEntity(ExpenseEntity e)` · `ExpenseModel.fromMap(Map m)` |

**Hive Field Index Map:**

| Index | Field |
|---|---|
| 0 | `id` |
| 1 | `title` |
| 2 | `amount` |
| 3 | `date` |
| 4 | `categoryId` |
| 5 | `categoryName` |
| 6 | `isIncome` |
| 7 | `note` |
| 8 | `createdAt` |
| 9 | `updatedAt` |

---

### 3.3 `Category` — Domain Layer

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique slug (e.g. `"food"`) |
| `name` | `String` | Display name |
| `icon` | `String` | Emoji icon character |
| `color` | `Color` | Accent hex colour |
| `isDefault` | `bool` | Shipped with app vs. user-created |

**10 built-in defaults:**

| ID | Name | Icon | Colour |
|---|---|---|---|
| `food` | Food & Dining | 🍔 | `#FF6584` |
| `transport` | Transport | 🚗 | `#42A5F5` |
| `shopping` | Shopping | 🛍️ | `#6C63FF` |
| `entertainment` | Entertainment | 🎬 | `#FFBE0B` |
| `health` | Health | 💊 | `#4CAF50` |
| `bills` | Bills & Utilities | 💡 | `#FF9800` |
| `education` | Education | 📚 | `#9C27B0` |
| `salary` | Salary | 💰 | `#4CAF50` |
| `freelance` | Freelance | 💻 | `#03DAC6` |
| `other` | Other | 📦 | `#8888AA` |

---

## 4. Layer-by-Layer Breakdown

### 4.1 Data Layer — Datasources

#### `ExpenseLocalDatasource` (Abstract Contract)

```
interface ExpenseLocalDatasource
  ┣ Stream<List<ExpenseModel>>  watchAllExpenses()
  ┣ List<ExpenseModel>          getAllExpenses()
  ┣ ExpenseModel?               getExpenseById(String id)
  ┣ void                        saveExpense(ExpenseModel model)
  ┣ void                        updateExpense(ExpenseModel model)
  ┣ void                        deleteExpense(String id)
  ┗ void                        clearAll()
```

#### `HiveExpenseLocalDatasource` (Concrete Implementation)

- Opens / closes `Box<ExpenseModel>` identified by `AppConstants.expenseBox`
- `watchAllExpenses()` — uses `box.watch()` to emit a new list on every Hive write
- All writes call `box.put(model.id, model)` (keyed by ID for O(1) lookup)
- `deleteExpense(id)` — calls `box.delete(id)`
- Throws `CacheException` on any `HiveError`

---

### 4.2 Data Layer — Repository Implementation

#### `ExpenseRepositoryImpl`

Implements domain's `ExpenseRepository` contract.

| Method | Datasource call | Error wrapping |
|---|---|---|
| `watchExpenses(...)` | `localDatasource.watchAllExpenses()` | Maps `CacheException` → `Left(CacheFailure)` |
| `getExpenses(...)` | `localDatasource.getAllExpenses()` | try/catch → `Left(CacheFailure)` |
| `addExpense(expense)` | `localDatasource.saveExpense(model)` | try/catch → `Left(CacheFailure)` |
| `updateExpense(expense)` | `localDatasource.updateExpense(model)` | try/catch → `Left(CacheFailure)` |
| `deleteExpense(id)` | `localDatasource.deleteExpense(id)` | try/catch → `Left(CacheFailure)` |
| `getMonthlyTotal(...)` | `getAllExpenses()` + in-memory filter | try/catch → `Left(CacheFailure)` |

**Conversion rule:** always converts `ExpenseEntity` → `ExpenseModel` before writing, and `ExpenseModel` → `ExpenseEntity` before returning to domain.

---

### 4.3 Domain Layer — Use Cases

All use-cases extend `UseCase<ReturnType, Params>` and return `Future<Either<Failure, T>>`.

#### `GetExpensesUseCase`
- **Params:** `GetExpensesParams { userId, limit, lastDate? }`
- **Returns:** `Either<Failure, List<ExpenseEntity>>`
- **Logic:** delegates to `repository.getExpenses(...)`, applies optional date filter

#### `WatchExpensesUseCase`
- **Params:** `WatchExpensesParams { userId, startDate?, endDate?, categoryId?, isIncome? }`
- **Returns:** `Stream<Either<Failure, List<ExpenseEntity>>>`
- **Logic:** delegates to `repository.watchExpenses(...)` for real-time list updates

#### `AddExpenseUseCase`
- **Params:** `ExpenseEntity`
- **Returns:** `Either<Failure, ExpenseEntity>`
- **Validation:** title not empty, amount > 0, categoryId not empty
- **Logic:** generates `id` (UUID v4), sets `createdAt` & `updatedAt` to `DateTime.now()`, calls `repository.addExpense(...)`

#### `UpdateExpenseUseCase`
- **Params:** `ExpenseEntity`
- **Returns:** `Either<Failure, ExpenseEntity>`
- **Validation:** same as Add
- **Logic:** stamps `updatedAt = DateTime.now()`, calls `repository.updateExpense(...)`

#### `DeleteExpenseUseCase`
- **Params:** `String id`
- **Returns:** `Either<Failure, void>`
- **Logic:** calls `repository.deleteExpense(id)`

#### `GetMonthlyTotalUseCase`
- **Params:** `MonthlyTotalParams { userId, month, year, isIncome }`
- **Returns:** `Either<Failure, double>`
- **Logic:** sums all matching entries for the given month/year/type

---

### 4.4 Presentation Layer — Cubit

#### `ExpenseCubit`

**Constructor dependencies (injected via GetIt):**
- `WatchExpensesUseCase`
- `AddExpenseUseCase`
- `UpdateExpenseUseCase`
- `DeleteExpenseUseCase`
- `GetMonthlyTotalUseCase`

---

#### State: `ExpenseState`

```
ExpenseState (abstract, Equatable)
 ├── ExpenseInitial
 ├── ExpenseLoading
 ├── ExpenseLoaded {
 │     List<ExpenseEntity> expenses
 │     double totalBalance
 │     double totalIncome
 │     double totalExpense
 │     ExpenseEntity? deletedExpense   ← for undo snackbar
 │   }
 └── ExpenseError { String message }
```

---

#### Cubit Methods

| Method | Signature | Description |
|---|---|---|
| `loadExpenses` | `Future<void> loadExpenses()` | Subscribes to `WatchExpensesUseCase` stream; emits `ExpenseLoaded` on each event |
| `addExpense` | `Future<void> addExpense(ExpenseEntity e)` | Calls `AddExpenseUseCase`; stream auto-refreshes list |
| `updateExpense` | `Future<void> updateExpense(ExpenseEntity e)` | Calls `UpdateExpenseUseCase` |
| `deleteExpense` | `Future<void> deleteExpense(String id)` | Calls `DeleteExpenseUseCase`; stores deleted item in state for undo |
| `undoDelete` | `Future<void> undoDelete()` | Re-adds `deletedExpense` from state via `AddExpenseUseCase` |
| `refreshTotals` | `void _refreshTotals(List<ExpenseEntity> list)` | Private; recalculates balance, income, expense sums |

---

## 5. UI/UX Requirements

### Design Tokens (Reminder)

| Token | Dark Value | Light Value |
|---|---|---|
| Background | `#13131F` | `#F8F8FF` |
| Surface (card) | `#1E1E2E` | `#FFFFFF` |
| Primary | `#6C63FF` | `#6C63FF` |
| Income | `#4CAF50` | `#4CAF50` |
| Expense | `#EF5350` | `#EF5350` |
| Font | Inter (Google Fonts) | Inter |

---

### 5.1 DashboardPage

**Route:** `/`

#### AppBar
- Left: App name "ExpenseTracker" (bold, Inter)
- Right: Notification bell icon + Avatar circle (user initials)

---

#### Balance Hero Card
- Full-width gradient card (`#6C63FF` → `#9C63FF`)
- Drop shadow: `rgba(108,99,255,0.4)` · blur 24 · offset (0,8)
- Fields:
  - Label: "Total Balance" (white70, 14sp)
  - Amount: `$X,XXX.XX` (white, 36sp, weight 800, letter-spacing -1)
  - Trend: `+X.X% vs last month` with `trending_up` icon (white70, 13sp)
- **Data binding:** `ExpenseLoaded.totalBalance`

---

#### Stats Row (Income / Expenses)
- Two equal-width chips side by side, 12dp gap
- Each chip:
  - Background: semantic colour at 12% opacity
  - Border: semantic colour at 25% opacity
  - Icon badge: colour at 20% opacity background
  - Fields: label (12sp, muted) + amount (15sp, bold)
- **Data binding:** `ExpenseLoaded.totalIncome` / `totalExpense`

---

#### Month Selector Strip
- Horizontal scrollable row of the last 6 months
- Selected month pill: primary colour background, white text
- Unselected: transparent, muted text
- Tapping a month filters the transaction list to that month

---

#### Recent Transactions Section
- Header row: "Recent Transactions" (17sp bold) + "See all" TextButton
- **Transaction list:**
  - Groups entries by date (Today / Yesterday / date string)
  - Each group has a sticky date label
  - Each entry renders an `ExpenseCard` widget (see §5.3)
  - Sorted by date descending
- **Empty state:** centred illustration + "No transactions yet" + "Add your first expense" button
- **Loading state:** 5× shimmer skeleton tiles

---

#### Floating Action Button
- `FloatingActionButton.extended` bottom-right
- Icon: `Icons.add_rounded` · Label: "Add"
- Navigates to `/add-expense`

---

#### Bottom Navigation Bar
| Index | Label | Icon (inactive) | Icon (active) |
|---|---|---|---|
| 0 | Home | `home_outlined` | `home_rounded` |
| 1 | Analytics | `bar_chart_outlined` | `bar_chart_rounded` |
| 2 | Budgets | `wallet_outlined` | `wallet_rounded` |
| 3 | Profile | `person_outline_rounded` | `person_rounded` |

- Navigates via `go_router` `context.go(...)` on tap
- Preserves scroll position per tab using `StatefulShellRoute`

---

### 5.2 AddExpensePage

**Route:** `/add-expense` (add mode) · `/edit-expense/:id` (edit mode)
**Presentation:** Full-screen page (not bottom sheet) with custom AppBar

---

#### AppBar
- Back arrow (pops route)
- Title: "Add Expense" or "Edit Expense" depending on mode
- Right action: "Save" text button (enabled only when form is valid)

---

#### Type Toggle (Income / Expense)
- Segmented control at the top of the form
- Two segments: "Expense 💸" / "Income 💰"
- Selecting a segment changes the amount display colour
  - Expense → `#EF5350`
  - Income → `#4CAF50`

---

#### Amount Display
- Large centred display (not a TextField) — e.g. `$0.00`
- Font: 48sp, bold, dynamically coloured by type
- Tapping opens the **Numeric Keyboard** (see §5.3)
- Shows `$0.00` as placeholder when empty

---

#### Numeric Keyboard (Custom Widget)
- Displayed in the bottom half of the screen (or as a bottom sheet)
- Grid layout: `1 2 3 / 4 5 6 / 7 8 9 / . 0 ⌫`
- Supports decimal entry (max 2 decimal places)
- Backspace key clears last character
- No system keyboard is shown for the amount field

---

#### Title Field
- Standard `TextFormField`
- Hint: "What did you spend on?"
- Max length: 50 characters
- Validation: required, min 2 characters

---

#### Category Picker
- Read-only tappable field (not a dropdown)
- Shows selected category emoji + name + chevron icon
- Tapping opens the **Category Picker Bottom Sheet** (see §5.3)
- Default: first category in the list (`food`)

---

#### Date Picker Field
- Read-only tappable field
- Shows formatted date: "Today", "Yesterday", or "Jul 25, 2026"
- Tapping opens `showDatePicker(...)` with `initialDate = DateTime.now()`
- Cannot select future dates

---

#### Note Field (Optional)
- Multi-line `TextFormField` (max 3 lines)
- Hint: "Add a note (optional)"
- Max length: 200 characters

---

#### Submit Button
- Full-width `ElevatedButton` at the bottom
- Label: "Save Expense" / "Save Income" (changes with type toggle)
- Gradient background matching primary → secondary
- Disabled & greyed when form is invalid
- Shows `CircularProgressIndicator` while saving
- On success: pops route with `context.pop()`
- On error: shows error `SnackBar`

---

### 5.3 Shared Components

#### `ExpenseCard` Widget

**Layout:**
```
┌────────────────────────────────────────────┐
│  [Emoji Badge]  Title          -$XX.XX     │
│                 Category · Time  (coloured)│
└────────────────────────────────────────────┘
```

**Behaviour:**
- Swipe LEFT → reveals red delete background with trash icon
- On confirmed swipe → calls `cubit.deleteExpense(id)`
- Simultaneously shows **SnackBar** with "Undo" action (3-second timeout)
- Tapping "Undo" → calls `cubit.undoDelete()`
- Tapping card → navigates to `/edit-expense/:id`

**Implementation:** wrap with `Dismissible` widget, key = `ValueKey(expense.id)`

---

#### Category Picker Bottom Sheet

- Triggered by tapping the category field on `AddExpensePage`
- Modal bottom sheet with drag handle
- Title: "Select Category"
- Grid: `3-column` grid of category cards
- Each card: large emoji + category name below
- Selected card: primary colour border + background tint
- Tapping a card: selects it and closes the sheet

---

#### Date Group Header

Used in the transaction list to visually separate entries by date.

```
─────── Today ────────
─────── Yesterday ────
─────── Jul 22, 2026 ─
```

- Light horizontal rule with date label centred
- Muted text colour, 12sp, letter-spaced

---

#### Empty State Widget

Shown when `ExpenseLoaded.expenses` is empty.

- Centred column layout
- Large emoji illustration: `💸`
- Title: "No transactions yet" (18sp bold)
- Subtitle: "Tap the + button to add your first expense" (muted, 14sp)
- CTA button: "Add Expense" → navigates to `/add-expense`

---

#### Shimmer Loading Tile

Shown during `ExpenseLoading` state.

- Same dimensions as `ExpenseCard`
- Animated shimmer gradient: surface → surface+highlight → surface
- Repeated 5× in a `ListView`

---

## 6. Navigation Map

```
/ (DashboardPage)
 ├── /add-expense          → AddExpensePage (add mode)
 ├── /edit-expense/:id     → AddExpensePage (edit mode, preloaded)
 ├── /analytics            → AnalyticsPage  (Phase 2 placeholder)
 ├── /budgets              → BudgetsPage    (Phase 2 placeholder)
 └── /profile              → ProfilePage    (Phase 2 placeholder)
```

**Router configuration (`go_router`):**

| Route | Builder | Extra |
|---|---|---|
| `/` | `DashboardPage` | — |
| `/add-expense` | `AddExpensePage` | `extra: null` |
| `/edit-expense/:id` | `AddExpensePage` | `extra: ExpenseEntity` |
| `/analytics` | `PlaceholderPage('Analytics')` | — |
| `/budgets` | `PlaceholderPage('Budgets')` | — |
| `/profile` | `PlaceholderPage('Profile')` | — |

**Transitions:** `CustomTransitionPage` with a slide-up animation (300ms, ease-out curve) for `AddExpensePage`; default fade for all others.

---

## 7. Dependency Injection

All registrations live in `lib/core/di/injection.dart`, called from `main()` before `runApp()`.

```
GetIt registration order (dependencies before dependents):

[Singleton]  HiveExpenseLocalDatasource
[Singleton]  ExpenseRepositoryImpl
                 └─ depends on: HiveExpenseLocalDatasource

[Factory]    WatchExpensesUseCase   ─┐
[Factory]    AddExpenseUseCase       │ depend on: ExpenseRepositoryImpl
[Factory]    UpdateExpenseUseCase    │
[Factory]    DeleteExpenseUseCase    │
[Factory]    GetMonthlyTotalUseCase ─┘

[Factory]    ExpenseCubit
                 └─ depends on: all 5 use-cases above
```

**`MultiBlocProvider` in `main.dart`:**
```
MultiBlocProvider
 └── BlocProvider(create: (_) => sl<ExpenseCubit>()..loadExpenses())
```

---

## 8. Error Handling Strategy

### Failure → UI Message Mapping

| Failure Type | User-facing Message |
|---|---|
| `CacheFailure` | "Could not read local data. Please restart the app." |
| `ValidationFailure` | Show inline field error on the form |
| `NetworkFailure` | "No internet connection." (Phase 2) |
| `ServerFailure` | "Server error. Please try again." (Phase 2) |
| `UnexpectedFailure` | "Something went wrong. Please try again." |

### SnackBar vs Dialog policy
- **SnackBar** (bottom): non-critical errors, undo actions, success confirmations
- **AlertDialog**: destructive confirmations (e.g. bulk delete)
- **Inline field errors**: validation on form fields (shown on submit attempt)

---

## 9. Local Storage Schema (Hive)

### Box: `expenses_box`
- Type: `Box<ExpenseModel>`
- Key: `expense.id` (String, UUIDv4)
- Registered type adapter: `ExpenseModelAdapter` (TypeId: 0)
- Opened at app launch in `main()` before `runApp()`

### Box: `settings_box`
- Type: `Box<dynamic>`
- Used for: theme preference, default currency
- Keys: `AppConstants.themeKey`, `AppConstants.currencyKey`

### Hive initialisation order in `main()`:
1. `await Hive.initFlutter()`
2. `Hive.registerAdapter(ExpenseModelAdapter())`
3. `await Hive.openBox<ExpenseModel>(AppConstants.expenseBox)`
4. `await Hive.openBox(AppConstants.settingsBox)`
5. `configureDependencies()` (GetIt)
6. `runApp(ExpenseTrackerApp())`

---

## 10. Acceptance Criteria

### DashboardPage
- [ ] Renders balance card with correct computed total balance
- [ ] Income and expense chips show correct monthly sums
- [ ] Transaction list renders all saved expenses sorted by date (newest first)
- [ ] Entries are grouped by date with "Today" / "Yesterday" / date labels
- [ ] Empty state shown when no expenses exist
- [ ] Shimmer shown during loading state
- [ ] Swiping a card left deletes it and shows an "Undo" snackbar
- [ ] Tapping "Undo" in the snackbar restores the deleted entry
- [ ] Tapping a transaction card opens the edit screen pre-filled
- [ ] FAB navigates to `/add-expense`
- [ ] Bottom nav tabs navigate correctly without losing state

### AddExpensePage
- [ ] Type toggle switches between Expense and Income
- [ ] Amount display updates character by character from numeric keyboard
- [ ] Amount colour changes with type (red = expense, green = income)
- [ ] Title field shows validation error if empty or < 2 chars
- [ ] Category picker opens bottom sheet and reflects selection
- [ ] Date picker opens calendar and reflects selection
- [ ] Cannot select a future date
- [ ] Note field accepts up to 200 characters
- [ ] Save button is disabled until form is valid
- [ ] Save button shows loading indicator while saving
- [ ] Successfully saving pops the screen and reflects in dashboard
- [ ] Edit mode pre-fills all fields from the existing expense

### Data Integrity
- [ ] Expenses persist across app restarts (Hive)
- [ ] Deleting then undoing returns the exact same expense object
- [ ] All monetary values are stored as `double` and displayed with 2 decimal places
- [ ] UUIDs are unique for every new expense

---

*End of Specification — Phase 1: Core Features*