# 💸 ExpenseTracker

A modern, full-featured **Flutter Expense Tracker** application built with **Clean Architecture**, **Firebase**, and **BLoC** state management. Track your income and expenses, visualize spending patterns, and manage budgets — all with a beautiful dark-first Material 3 UI.

---

## 📸 Preview

> Dark theme dashboard with balance card, income/expense stats, and transaction list.

```
┌─────────────────────────────┐
│   ExpenseTracker      🔔 👤  │
│                             │
│  ┌───────────────────────┐  │
│  │  Total Balance        │  │
│  │  $1,360.00        📈  │  │
│  │  +12.5% vs last month │  │
│  └───────────────────────┘  │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │ Income   │ │ Expenses │  │
│  │ $3,200   │ │ $1,840   │  │
│  └──────────┘ └──────────┘  │
│                             │
│  Recent Transactions        │
│  🍔 Burger King   -$12.50   │
│  💡 Electricity   -$85.00   │
│  💰 Salary       +$3200.00  │
│                             │
│  🏠  📊  👛  👤        ➕   │
└─────────────────────────────┘
```

---

## 🏗️ Architecture

This project follows **Uncle Bob's Clean Architecture** with strict layer separation:

```
Presentation  ──►  Domain  ◄──  Data
(BLoC/Pages)      (Entities,     (Firestore,
                   UseCases,      Hive,
                   Repo contracts) Repo impls)
```

### Layers
| Layer | Responsibility | Dependencies |
|---|---|---|
| **Domain** | Business logic, entities, use-cases | Pure Dart only |
| **Data** | Firestore/Hive DTOs, repo implementations | Domain + Firebase |
| **Presentation** | UI, BLoC, pages, widgets | Domain + Flutter |

---

## 📁 Project Structure

```
lib/
├── main.dart                            # App bootstrap
│
├── core/                                # Shared utilities
│   ├── constants/app_constants.dart     # Global constants
│   ├── errors/
│   │   ├── failures.dart                # Domain failure types
│   │   └── exceptions.dart              # Data exception types
│   ├── theme/app_theme.dart             # Material 3 dark/light themes
│   └── utils/
│       ├── use_case.dart                # UseCase<T, P> base class
│       └── formatters.dart              # Currency & date helpers
│
└── features/
    ├── expenses/
    │   ├── domain/
    │   │   ├── entities/expense.dart    # Expense entity
    │   │   ├── entities/category.dart   # Category + 10 defaults
    │   │   └── repositories/            # Abstract repo contract
    │   ├── data/
    │   │   ├── models/expense_model.dart# Firestore DTO
    │   │   ├── datasources/             # Remote + local sources
    │   │   └── repositories/            # Repository implementation
    │   └── presentation/
    │       ├── bloc/                    # ExpenseBloc / Cubit
    │       ├── pages/dashboard_page.dart# Dashboard screen
    │       └── widgets/                 # Reusable UI components
    │
    └── auth/
        ├── domain/entities/app_user.dart# AppUser entity
        ├── data/                        # Auth data sources
        └── presentation/                # Login / Signup pages

assets/
├── images/
├── icons/
└── animations/
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Firebase project (for full functionality)
- Android Studio / VS Code with Flutter extension

### 1. Clone & Install

```bash
# Navigate to project
cd expense_tracker

# Install dependencies
flutter pub get
```

### 2. Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

Then uncomment `Firebase.initializeApp()` in `lib/main.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### 3. Run the App

```bash
# Chrome (web)
flutter run -d chrome --web-port 8080

# Windows desktop
flutter run -d windows

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 📦 Dependencies

### Core
| Package | Purpose |
|---|---|
| `firebase_core` | Firebase SDK |
| `cloud_firestore` | Cloud database |
| `firebase_auth` | Authentication |
| `flutter_bloc` | State management |
| `equatable` | Value equality |
| `get_it` + `injectable` | Dependency injection |
| `dartz` | Functional Either/Option types |

### UI & UX
| Package | Purpose |
|---|---|
| `google_fonts` | Inter font family |
| `flutter_svg` | SVG assets |
| `cached_network_image` | Network image caching |
| `shimmer` | Loading skeleton UI |
| `fl_chart` | Charts & graphs |
| `iconsax` | Premium icon set |

### Storage & Navigation
| Package | Purpose |
|---|---|
| `hive_flutter` + `hive` | Offline local cache |
| `shared_preferences` | Key-value settings |
| `go_router` | Declarative navigation |
| `intl` | Date & currency formatting |
| `uuid` | Unique ID generation |
| `rxdart` | Reactive streams |

### Dev Tools
| Package | Purpose |
|---|---|
| `build_runner` | Code generation |
| `injectable_generator` | DI annotations |
| `hive_generator` | Hive type adapters |
| `mockito` | Unit test mocking |
| `flutter_lints` | Lint rules |

---

## 🎨 Design System

### Color Palette
| Token | Dark | Light |
|---|---|---|
| Background | `#13131F` | `#F8F8FF` |
| Surface | `#1E1E2E` | `#FFFFFF` |
| Primary | `#6C63FF` | `#6C63FF` |
| Secondary | `#03DAC6` | `#03DAC6` |
| Income | `#4CAF50` | `#4CAF50` |
| Expense | `#EF5350` | `#EF5350` |

### Typography
- **Font:** Inter (Google Fonts)
- **Style:** Material 3 type scale

### Components
- Rounded cards (16–24 dp radius)
- Gradient hero balance card
- Glassmorphism-inspired surfaces
- Micro-animations on interactions

---

## 🗂️ Domain Model

### Expense
```dart
Expense {
  id           : String         // Firestore document ID
  userId       : String         // Firebase UID
  title        : String         // e.g. "Burger King"
  amount       : double         // Absolute value
  categoryId   : String
  categoryName : String
  date         : DateTime
  type         : ExpenseType    // .expense | .income
  note         : String?
  receiptUrl   : String?
  createdAt    : DateTime
  updatedAt    : DateTime
}
```

### Default Categories
| Emoji | Name | Emoji | Name |
|---|---|---|---|
| 🍔 | Food & Dining | 🚗 | Transport |
| 🛍️ | Shopping | 🎬 | Entertainment |
| 💊 | Health | 💡 | Bills & Utilities |
| 📚 | Education | 💰 | Salary |
| 💻 | Freelance | 📦 | Other |

---

## 🔥 Firebase Structure

```
/users/{userId}
    email, displayName, photoUrl, currency, createdAt

/users/{userId}/expenses/{expenseId}
    title, amount, categoryId, categoryName,
    date, type, note, receiptUrl, createdAt, updatedAt

/users/{userId}/categories/{categoryId}
    name, icon, color, isDefault

/users/{userId}/budgets/{budgetId}
    categoryId, limit, month, year
```

---

## 🛣️ Roadmap

### ✅ Phase 0 — Foundation (Complete)
- [x] Clean Architecture scaffold
- [x] Material 3 dark/light theme system
- [x] Domain entities (Expense, Category, AppUser)
- [x] Repository contracts
- [x] Firestore DTOs
- [x] Error handling hierarchy (Either/Failure)
- [x] Utility classes (formatters, use-case base)
- [x] Placeholder dashboard UI

### 🔲 Phase 1 — Core Features
- [ ] Firebase Auth (Email + Google Sign-In)
- [ ] Add / Edit / Delete expense
- [ ] Expense list with search & filter
- [ ] Category management

### 🔲 Phase 2 — Analytics
- [ ] Monthly summary dashboard
- [ ] Pie chart by category
- [ ] Bar chart: income vs expenses (6 months)
- [ ] Daily spending trend

### 🔲 Phase 3 — Budgets
- [ ] Monthly budget per category
- [ ] Budget progress bars
- [ ] Overspend notifications

### 🔲 Phase 4 — Polish
- [ ] Receipt photo upload
- [ ] Offline mode (Hive)
- [ ] Theme toggle (dark/light)
- [ ] Multi-currency support
- [ ] CSV export

---

## 🧪 Testing

```bash
# Run all unit tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

---

## 📂 Project Info

| Field | Value |
|---|---|
| **Version** | 1.0.0+1 |
| **Flutter** | ≥ 3.0.0 |
| **Dart** | ≥ 3.0.0 |
| **Platforms** | Android · iOS · Web · Windows |
| **State Mgmt** | BLoC / Cubit |
| **Backend** | Firebase (Firestore + Auth) |
| **Architecture** | Clean Architecture |

---

## 📄 License

This project is for personal / educational use.

---

*Built with ❤️ using Flutter & Firebase*
