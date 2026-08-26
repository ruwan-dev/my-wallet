# Application Features: Premium Aurora Expense Tracker

Welcome to the **Premium Aurora Expense Tracker**! This application is designed to be a state-of-the-art, visually stunning, cross-platform financial management tool. 

Below is a comprehensive breakdown of the features and capabilities built into the application:

## 🎨 Premium UI/UX Design System
- **Aurora Aesthetic:** The app features a signature `PremiumAuroraVectorBackground`—an animated, smoothly morphing gradient background utilizing deep purples and vibrant lavenders (`#1E1B4B`, `#311060`, `#7C3AED`).
- **Glassmorphism:** Forms, lists, and dialogs utilize frosted glass effects (`BackdropFilter` with blur) and semi-transparent containers instead of flat solid colors.
- **Responsive Layouts:** The app seamlessly adapts to mobile, tablet, and web views. For example, the authentication screens use a top-to-bottom layout on mobile, and a beautiful 50/50 split-screen layout on wide web displays.
- **Custom Web Loader:** The initial web bootloader features a pure CSS-animated aurora effect, ensuring a seamless visual transition before the Flutter engine even initializes.
- **Skeleton Loaders:** Content blocks use shimmering skeleton loaders (`ShimmerTile`) rather than basic circular spinners to maintain a premium feel during network requests.

## 🔐 Authentication & Onboarding
- **Firebase Authentication:** Secure email/password login and registration powered by Firebase Auth.
- **Seamless State Management:** Real-time auth state listening using `AuthCubit` to automatically redirect users based on their session status.
- **Integrated Forgot Password:** An inline password reset flow that directly integrates into the login screen (no jarring popups), allowing users to request a password reset email securely.

## 💰 Expense & Income Tracking
- **Transaction Management:** Easily add, edit, and categorize daily expenses and income streams.
- **Categorization:** Assign transactions to specific categories (e.g., Food, Transport, Entertainment) complete with distinct colors and icons.
- **Account/Wallet Tracking:** Manage balances across multiple accounts or wallets seamlessly.

## 🪣 Bucket Planner (Barefoot Investor System)
- **Visual Bucket Segregation:** Divide funds into Daily Expenses, Splurge, Smile, Fire, Mojo, and Grow using an interactive Segmented Control system.
- **3D Card UI:** Buckets are rendered as large, beautiful cards with custom 3D background imagery.
- **Exclusive Account Syncing:** Link specific bank accounts to distinct buckets (e.g., link a High-Yield Savings Account to Mojo). **Rule: A single bank account can only be linked to ONE bucket at a time.** If an account is already synced to a bucket, it is intentionally hidden from the available options for other buckets.

## 📊 Budgeting & Analytics
- **Category Budgets:** Set spending limits on individual categories. The app visually tracks your spending against these budgets to help you stay disciplined.
- **Visual Insights:** View your financial health at a glance. Identify trends, track weekly/monthly spending patterns, and see exactly where your money goes.
- **"Focus on the discipline, not the amount"** – The core philosophy driven into the analytics dashboard to encourage healthier financial habits.

## 🛠 Architecture & Tech Stack
- **Framework:** Flutter (Web, iOS, Android).
- **State Management:** BLoC (Business Logic Component) using `flutter_bloc` and `Cubit` for highly scalable, reactive state management.
- **Routing:** Advanced declarative routing using `go_router`, complete with custom fade/slide page transitions to preserve the continuous background animations.
- **Backend:** Firebase (Authentication and Firestore for real-time cloud data storage).
- **Dependency Injection:** `get_it` for clean, decoupled architecture.

## 🐛 Developer & Debug Tools
- **Debug Database View:** A dedicated developer screen to manually inspect local and remote database states, trigger syncs, and clear caches without needing to access the Firebase console directly.
