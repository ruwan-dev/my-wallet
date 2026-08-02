# 🤖 AI Agent Strict Rules for Finance App

As an AI Assistant working on this Flutter project, you MUST strictly adhere to the following rules for every prompt unless explicitly overridden by the user.

## 1. ZERO Feature Regression (DO NOT BREAK FUNCTIONALITY)
- **Never** modify, delete, or refactor existing business logic, state management (Providers/Controllers), models, or backend/database integrations.
- Your primary task is to enhance the UI/UX. The app's core functionality is already built and working perfectly. Do not break it.

## 2. UI & Styling Modifications ONLY
- Only change visual elements (e.g., `ThemeData`, colors, padding, margins, `BorderRadius`, and typography).
- Do not alter the structure of data-binding or how data is passed to widgets.
- If you need to wrap a widget (e.g., in a `Container` or `Padding`), ensure the original child widget and its properties remain exactly intact.

## 3. Design System Consistency
- Always use the predefined global theme variables (e.g., `Theme.of(context).colorScheme`).
- Maintain the "Glassmorphic / Premium Soft-UI" aesthetic.
- Do not introduce random harsh colors, neon gradients, or outdated heavy drop shadows.

## 4. Ask Before Complex Changes
- If a UI request requires changing how the data model works, STOP and ask the user for permission before writing the code.
