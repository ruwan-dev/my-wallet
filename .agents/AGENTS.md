# UI/UX Rules for Premium Aurora Expense Tracker

Whenever you are asked to introduce a new page, component, or UI element in this app, you MUST strictly adhere to the following design system rules. **Failure to follow these rules breaks the premium aesthetic of the application.**

### 1. The Core Aesthetic (Glassmorphism & Gradients)
- **Colors:** The primary theme colors are **Teal and Cyan** (`#60C5B8`). The main app background is a vibrant animated gradient. The **Auth screens (Login/Register) use a flat light cyan background (`Color(0xFFEEF5F5)`) — this is intentional and should NOT be changed back to a dark gradient.**
- **Do not use solid flat colors** for cards, panels, list items, or dialogs in the main app. 
- **Glassmorphism:** Combine `Container` with highly translucent colors (e.g., `Colors.white.withOpacity(0.15)` or `Color(0xFF60C5B8).withOpacity(0.15)`).
- **Blur Effects:** Modals and back panels must use `BackdropFilter` with `ImageFilter.blur(sigmaX: 15, sigmaY: 15)`.
- **Borders:** Containers must have subtle, semi-transparent borders (e.g., `Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)`).

### 2. Details Rows & List Items
- Do not use the default Material `ListTile` with a solid white background.
- Detail rows and list items must be implemented as glassmorphic containers (as seen in the Categories page):
  - **Background:** `Colors.white.withOpacity(0.15)`
  - **Border Radius:** Use `BorderRadius.circular(20)` for lists and cards.
  - **Padding:** Internal padding should be around `EdgeInsets.all(16)`.
  - **Icons:** Leading icons should have a soft, translucent circular background (`Colors.white.withOpacity(0.1)`).

### 3. Loaders and Loading States
- **NO CircularProgressIndicators:** Never use standard `CircularProgressIndicator` for loading blocks of content.
- **Skeleton Loaders Only:** All loading states must use skeleton loaders (the `ShimmerTile` widget or a custom `shimmer` effect). Loading states should mimic the shape of the content they are loading.

### 4. Dialogs, Modals & Forms
- **No pure white dialogs:** Do not use default Material white `AlertDialogs`. They must be restyled using glassmorphic containers with blurred backdrops.
- **Desktop Responsiveness:** Dialogs and bottom sheets must never have `width: double.infinity` without constraints. Always wrap them in `BoxConstraints(maxWidth: 500)` so they don't stretch aggressively on wide desktop web screens.
- **Forms & Inputs (`TextField`):** Never hardcode white backgrounds for text fields inside modals. Rely on `Theme.of(context).inputDecorationTheme`, which ensures the transparent, thin-bordered aesthetic is preserved.

### 5. Typography & Spacing
- **Text Colors:** Primary text must be `Colors.white` or extremely dark purple depending on the brightness of the glass layer. Secondary text should be `Colors.white70` or `Colors.white54`.
- **Padding:** Keep UI breathing room high. 
- **Shadows:** Always use `Offset` shadows to give cards depth (e.g., `BoxShadow` with `blurRadius: 15` and a slight downward offset).

### 6. Cross-Platform Responsiveness
- **Adaptive Layouts:** Every screen must be strictly responsive and designed to look great across **Mobile, Web, and Tablet** platforms. Remember to adapt layouts dynamically, constrain wide widths (such as using `ConstrainedBox` for dialogs and content on desktop), and utilize available screen real estate effectively when designing UI.

### 7. Action Modals Consistency
- **Bottom Sheets over Centered Dialogs:** For actions like editing items, setting schedules, or adding entities, prefer using Bottom Sheets (`showModalBottomSheet`) instead of centered pop-up dialogs (`showDialog`). This keeps the UI consistent, mobile-friendly, and more accessible.

### 8. Screen Transitions & Continuous Backgrounds
- **Preserve the Global Background:** When pushing a new screen over a screen that has the `PremiumAuroraVectorBackground` (like within a shell route), do NOT wrap the new screen in another `PremiumAuroraVectorBackground` to avoid breaking the gradient.
- **Use Transparent Routes:** Push the new screen using `PageRouteBuilder` with `opaque: false` so the global background remains visible underneath.
- **Fade Out Previous Screen:** To prevent the old screen's content from overlapping with the new screen, use a `ValueNotifier<bool>` and `AnimatedOpacity` to explicitly fade out the calling screen's content (opacity 0.0) right before the `Navigator.push`, and fade it back in (opacity 1.0) right after the push returns.
- **Professional Slide/Fade Animations:** In the `PageRouteBuilder`, use `SlideTransition` combined with `FadeTransition` and `Curves.easeOutCubic` for a premium, buttery-smooth screen entry.

### 9. Inline Editors for Add/Edit Actions
- **No Centered Popups:** Never use centered pop-up dialogs (`showDialog` or `AlertDialog`) for "Add" or "Edit" actions.
- **Inline Forms First:** Prefer using inline expanding editors (such as `InlineDebtEditor` or the inline subcategory editor) that appear directly within the current page layout. This keeps the user grounded in their current context without disruptive overlays.

### 10. Confirmation Messages
- **Glassmorphic Styling:** When implementing confirmation messages (such as Delete warnings), do NOT use standard opaque Material `AlertDialog` widgets.
- **Implementation:** Always wrap the `AlertDialog` in a `BackdropFilter` (e.g., `ImageFilter.blur(sigmaX: 15, sigmaY: 15)`). Set the dialog's `backgroundColor` to a highly translucent tint (e.g., `Color(0xFF7C3AED).withOpacity(0.15)`) and give it a semi-transparent border using `RoundedRectangleBorder`. This ensures the premium, translucent aesthetic is preserved.

### 11. Currency & Amount Validation
- **Strict Decimal Limits:** Everywhere in the app where an amount, balance, or currency value is entered by the user, the input must strictly allow only numbers with up to 2 decimal points.
- **Implementation:** Always apply `FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))` (from `package:flutter/services.dart`) to the `inputFormatters` of the corresponding `TextField`.

### 12. Transaction Insufficient Funds Validation
- **Prevent Over-drafting:** Users should not be able to create an expense or deduction transaction if the entered amount exceeds the current balance of the selected account or vault.
- **Validation Message:** When this rule is violated, show a clear validation message (e.g., via `SnackBar` or inline error) informing the user that the account has insufficient funds.
