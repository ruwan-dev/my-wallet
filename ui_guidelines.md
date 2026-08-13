# UI/UX Design Guidelines

This document serves as the source of truth for design tokens, visual style, and consistency across the Expense Tracker application.

## 1. Aesthetic Direction
The application uses a highly modern, **premium** visual language. 
Key traits:
- Deep, vibrant gradient backgrounds (Pink/Purple)
- Floating **glassmorphic** panels and cards
- Soft, elevated drop shadows
- Clean typography (Inter/Outfit style)

---

## 2. Glassmorphism Standard
Whenever floating cards are placed over the gradient background (such as Account Tiles, Category Tiles, or Dashboard widgets), they must adhere to the following **strict glassmorphism standard**:

### Code Snippet Template
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(20), // or 16 for smaller tiles
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
    child: Container(
      decoration: BoxDecoration(
        // The surface color (usually white or dark surface) with 30% opacity
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        
        borderRadius: BorderRadius.circular(20), // Must match ClipRRect
        
        // Subtle frosted white border
        border: Border.all(
          color: Colors.white.withOpacity(0.2), 
          width: 1.5
        ),
        
        // Very soft shadow
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ... // Content here
    ),
  ),
)
```

### Key Values
- **Blur Radius (`sigmaX`, `sigmaY`)**: `12`
- **Surface Opacity**: `0.3` (30%)
- **Border**: `Colors.white.withOpacity(0.2)`, Width `1.5`
- **Border Radius**: `16` (Compact) or `20` (Spacious)
- **Shadow**: Opacity `0.05`, Blur `10`, Offset `(0, 4)`

---

## 3. Typography & Contrast
- Never use pure black `#000000`. Use deep purples, dark navys, or `Colors.grey.shade900` for primary text.
- Icons sitting on the global gradient (like App Bar actions) should generally use `Colors.white` or the default `titleLarge?.color` for contrast, avoiding bright green/red accent colors unless strictly inside a surface card.

## 4. Badges (Admin Console)
- **Admin**: Gold (`#FFD700` background, `#B8860B` text/border)
- **Premium**: Purple (`#E0B0FF` background, `#673AB7` text/border)
