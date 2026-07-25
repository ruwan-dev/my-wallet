# Multi-Account Feature Specification

**Author:** Senior Software Architect
**Version:** 1.0.0
**Status:** Planning / Architecture
**Date:** 2026-07-25

---

## 1. Overview
This document outlines the architectural changes required to transition the expense tracker from a single global balance model to a **Multi-Account** architecture. Transactions will now be tied to specific accounts (e.g., Cash, Savings, Credit Cards), and adding a transaction will automatically update its parent account's balance.

## 2. Architecture & Tech Stack Updates
The existing Clean Architecture layers will be updated to accommodate the new domain boundaries:

*   **Domain Layer:** Introduction of `AccountEntity`. Renaming `ExpenseEntity` to `TransactionEntity` with an added relationship to `AccountEntity`.
*   **Data Layer:** New `AccountLocalDatasource` (Hive) and `AccountRepositoryImpl`. `TransactionModel` updated to include `accountId`.
*   **Presentation Layer:** Dashboard overhauled to support a horizontal scroll of accounts. Cubits updated to manage both Account and Transaction states.

The technology stack remains consistent: `flutter_bloc`, `hive`, `get_it`, `go_router`, and standard Flutter SDK components.

---

## 3. Updated Data Models

### 3.1 AccountEntity (New)
Represents a financial account belonging to the user.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique identifier (UUIDv4). |
| `name` | `String` | Display name (e.g., "Cash Wallet", "Chase Sapphire"). |
| `balance` | `double` | Current balance of the account. |
| `type` | `AccountType` | Enum: `Asset` (positive wealth, e.g., cash) or `Liability` (debt, e.g., credit card). |
| `userId` | `String` | Identifier of the owning user. |

### 3.2 TransactionEntity (Updated from ExpenseEntity)
Represents a single movement of money in or out of a specific account.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Unique identifier (UUIDv4). |
| `accountId` | `String` | **[NEW]** Foreign key linking to `AccountEntity.id`. |
| `title` | `String` | Short description. |
| `amount` | `double` | Absolute monetary value. |
| `categoryId` | `String` | Link to category. |
| `categoryName` | `String` | Denormalized category name. |
| `date` | `DateTime` | Date of transaction. |
| `isIncome` | `bool` | True for money in, False for money out. |
| `note` | `String?` | Optional description. |

---

## 4. Layer-by-Layer Breakdown

### 4.1 Data Layer
*   **AccountLocalDatasource:** New Hive box (`accounts_box`) for CRUD operations on accounts.
*   **TransactionLocalDatasource:** Updated to filter transactions by `accountId` when necessary.
*   **Repositories:** `AccountRepositoryImpl` and `TransactionRepositoryImpl` handles mapping between Hive Models and Domain Entities.

### 4.2 Domain Layer (Use Cases)
Business logic will heavily rely on orchestrating accounts and transactions.

*   **`AddTransactionUseCase`:** 
    1. Validates transaction data.
    2. Saves the `TransactionEntity`.
    3. **Business Logic:** Retrieves the linked `AccountEntity`, calculates the new balance based on `isIncome` and `amount`, and updates the `AccountEntity` via `AccountRepository`.
*   **`DeleteTransactionUseCase`:** Reverses the balance change on the linked account before deleting the transaction.
*   **`UpdateTransactionUseCase`:** Calculates the delta between the old and new amount/type and adjusts the account balance accordingly.
*   **`GetAccountsUseCase` / `WatchAccountsUseCase`:** Retrieves the user's accounts.

### 4.3 Presentation Layer (Cubit)
*   **`AccountCubit`:** Manages the state of the user's accounts (Loading, Loaded with a list of `AccountEntity`, Error).
*   **`TransactionCubit`:** Manages transactions. Will likely depend on the selected account or show an aggregate view.

---

## 5. UI/UX Requirements

The Dashboard and entry flows require significant changes.

### 5.1 DashboardPage
*   **Horizontal Account Cards:** Replace the single global balance card.
    *   Horizontal `ListView` or `PageView`.
    *   **Styling:** Teal/Green gradients for `AccountType.Asset`, Orange/Red gradients for `AccountType.Liability`.
    *   Displays Account Name, Current Balance, and Account Type.
*   **'Fixed Commitments (This Month)' Card:** 
    *   A summary card placed below the accounts row showing anticipated fixed costs (e.g., rent, subscriptions).
*   **'Recent Transactions' List:**
    *   Vertical scrolling list below the commitments.
    *   Must display the related account name lightly alongside the transaction category.
    *   **Empty State:** A prominent empty state icon (e.g., a ghost or empty wallet icon) with text when no transactions exist.
*   **Floating Action Button (FAB):**
    *   Remains in the bottom right for "Add".

### 5.2 AddTransactionPage (Formerly AddExpensePage)
*   **Account Selector:** A new required field. A dropdown or bottom sheet to select which account this transaction belongs to.
*   **Amount Input:** Must retain the custom numeric keyboard.
*   **Type Toggle, Category Picker, Date, Notes:** Unchanged from previous spec.

### 5.3 Interactions
*   **Swipe-to-delete:** Retained on the Recent Transactions list. Must trigger the `DeleteTransactionUseCase` to ensure account balances recalculate.

---
*End of Multi-Account Feature Specification*
