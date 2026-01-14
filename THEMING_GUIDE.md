# Theme Configuration Guide

## Overview
The Ahadi app now supports dynamic theming, allowing users to switch between Light Mode, Dark Mode, and System Default themes directly from their profile screen.

## Architecture

### 1. **ThemeController** (`lib/core/controllers/theme_controller.dart`)
- Manages the current theme mode state using GetX
- Persists theme preference to local storage
- Provides methods to switch between themes:
  - `setLightMode()` - Switch to light theme
  - `setDarkMode()` - Switch to dark theme
  - `setSystemMode()` - Follow device system settings
  - `toggleTheme()` - Quick toggle between light/dark

### 2. **AppTheme** (`lib/core/theme/app_theme.dart`)
- Defines two complete theme configurations:
  - `AppTheme.lightTheme` - Light mode with grayscale palette
  - `AppTheme.darkTheme` - Dark mode with blue accents
- Both themes follow Material Design 3 guidelines
- Consistent styling across all widgets (buttons, cards, inputs, etc.)

### 3. **StorageService** (`lib/core/services/storage_service.dart`)
- Added `saveThemeMode()` and `getThemeMode()` methods
- Persists user's theme preference using SharedPreferences
- Theme choice survives app restarts

### 4. **Profile Screen** (`lib/features/profile/screens/profile_screen.dart`)
- New "Appearance" section with three theme options
- Visual feedback showing currently selected theme
- Instant theme switching with smooth transitions

## Usage

### For Users
1. Open the app and navigate to your Profile
2. Scroll to the "Appearance" section
3. Tap on one of three options:
   - **Light Mode**: Always use light theme
   - **Dark Mode**: Always use dark theme
   - **System Default**: Follow your device's system theme setting
4. Theme changes apply immediately

### For Developers

#### Accessing the ThemeController
```dart
final themeController = Get.find<ThemeController>();

// Check current theme
bool isDark = themeController.isDarkMode;
bool isLight = themeController.isLightMode;
bool isSystem = themeController.isSystemMode;

// Change theme programmatically
await themeController.setDarkMode();
await themeController.toggleTheme();
```

#### Adding Custom Theme Colors
Edit `lib/core/theme/app_theme.dart`:

```dart
class AppColors {
  // Add your custom colors here
  static const Color customPrimary = Color(0xFF...);
  
  // For dark theme, consider different shades
  static const Color customPrimaryDark = Color(0xFF...);
}
```

#### Applying Theme-Aware Colors in Widgets
```dart
// Always use theme colors instead of hardcoded colors
Container(
  color: Theme.of(context).primaryColor,  // ✅ Good
  // color: Colors.blue,  // ❌ Avoid - won't adapt to theme
)
```

## Theme Specifications

### Light Theme
- Primary: Gray 900 (#111827)
- Background: Gray 50 (#F9FAFB)
- Surface: White
- Accent: Blue for interactive elements

### Dark Theme
- Primary: Blue 400 (#60A5FA)
- Background: Gray 900 (#111827)
- Surface: Gray 800 (#1F2937)
- Text: White with appropriate opacity

## File Structure
```
lib/
├── core/
│   ├── controllers/
│   │   └── theme_controller.dart       # Theme state management
│   ├── theme/
│   │   └── app_theme.dart              # Theme definitions
│   ├── services/
│   │   └── storage_service.dart        # Theme persistence
│   └── config/
│       └── app_config.dart             # Storage keys
├── features/
│   └── profile/
│       └── screens/
│           └── profile_screen.dart     # Theme UI controls
└── main.dart                           # Theme initialization
```

## Best Practices

1. **Always use theme colors**: Use `Theme.of(context)` instead of hardcoded colors
2. **Test both themes**: Verify your UI works in light and dark mode
3. **Consistent contrast**: Ensure text is readable in both themes
4. **Icon colors**: Use theme-appropriate icon colors
5. **Image assets**: Consider providing separate assets for dark mode if needed

## Troubleshooting

### Theme not persisting
- Check that StorageService is initialized before ThemeController
- Verify SharedPreferences permissions

### Colors not updating
- Ensure you're using `Theme.of(context)` not hardcoded colors
- Wrap custom widgets with `Obx()` if they need to react to theme changes

### System theme not working
- Check device settings allow app to access system theme
- iOS: Settings > Display & Brightness > Appearance
- Android: Settings > Display > Dark theme

## Future Enhancements
- [ ] Custom color palette selection
- [ ] Scheduled theme switching (e.g., auto dark mode at night)
- [ ] Per-event custom themes
- [ ] High contrast mode for accessibility
- [ ] Custom font size scaling
