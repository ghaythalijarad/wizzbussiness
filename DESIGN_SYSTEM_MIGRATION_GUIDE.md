# Design System Migration Guide

This guide provides step-by-step instructions for migrating existing Flutter screens to use the new design system while maintaining functionality and improving consistency.

## Quick Reference

### Import Statement

```dart
import '../core/design_system/design_system.dart';
```

### Common Replacements

| Old Approach | New Design System Approach |
|--------------|---------------------------|
| `Color(0xFF32CD32)` | `AppColors.primary` or `DesignSystem.primaryColor` |
| `Color(0xFFFFD300)` | `AppColors.secondary` or `DesignSystem.secondaryColor` |
| `EdgeInsets.all(16)` | `SpacingSystem.allMd` |
| `EdgeInsets.symmetric(horizontal: 20)` | `SpacingSystem.horizontalXl` |
| `SizedBox(height: 12)` | `SpacingWidgets.verticalLg` |
| `BorderRadius.circular(12)` | `BorderRadius.circular(DesignSystem.borderRadius)` |
| `FontSize: 16, FontWeight.w500` | `TypographySystem.bodyMedium` |

## Step-by-Step Migration Process

### 1. Update Imports

Replace theme-specific imports with the design system:

```dart
// OLD
import '../core/theme/app_colors.dart';

// NEW
import '../core/design_system/design_system.dart';
```

### 2. Replace Hardcoded Colors

```dart
// OLD
Container(
  color: Color(0xFF32CD32),
  child: Text(
    'Hello',
    style: TextStyle(color: Color(0xFFFFD300)),
  ),
)

// NEW
Container(
  color: DesignSystem.primaryColor,
  child: Text(
    'Hello',
    style: TypographySystem.bodyMedium.copyWith(color: DesignSystem.secondaryColor),
  ),
)
```

### 3. Update Spacing

```dart
// OLD
Padding(
  padding: EdgeInsets.all(16),
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: 12),
      Text('Content'),
    ],
  ),
)

// NEW
Padding(
  padding: SpacingSystem.allMd,
  child: Column(
    children: [
      Text('Title'),
      SpacingWidgets.verticalLg,
      Text('Content'),
    ],
  ),
)
```

### 4. Replace Custom Buttons

```dart
// OLD
ElevatedButton(
  onPressed: onPressed,
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF32CD32),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  child: Text('Submit'),
)

// NEW
DesignSystem.primaryButton(
  text: 'Submit',
  onPressed: onPressed,
)
```

### 5. Update Text Styles

```dart
// OLD
Text(
  'Headline',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  ),
)

// NEW
Text(
  'Headline',
  style: TypographySystem.headlineMedium,
)
```

### 6. Replace Custom Cards

```dart
// OLD
Container(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: content,
)

// NEW
DesignSystem.card(
  child: content,
)
```

### 7. Update Text Fields

```dart
// OLD
TextFormField(
  decoration: InputDecoration(
    labelText: 'Email',
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF32CD32)),
    ),
  ),
)

// NEW
DesignSystem.textField(
  label: 'Email',
  keyboardType: TextInputType.emailAddress,
)
```

### 8. Replace Loading Indicators

```dart
// OLD
CircularProgressIndicator(
  color: Color(0xFF32CD32),
)

// NEW
DesignSystem.loadingIndicator()
```

### 9. Update SnackBars

```dart
// OLD
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Success!'),
    backgroundColor: Colors.green,
  ),
)

// NEW
DesignSystem.showSnackBar(
  context,
  message: 'Success!',
  type: SnackBarType.success,
)
```

## Screen-Specific Migration Examples

### Account Settings Page Migration

```dart
// OLD structure
class AccountSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings'),
        backgroundColor: Color(0xFF32CD32),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF32CD32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Profile Header',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF32CD32),
              ),
              child: Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

// NEW structure using design system
class AccountSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings'),
      ),
      body: Padding(
        padding: SpacingSystem.pageContent,
        child: Column(
          children: [
            DesignSystem.card(
              child: Column(
                children: [
                  Text(
                    'Profile Header',
                    style: TypographySystem.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SpacingWidgets.verticalXl,
            DesignSystem.primaryButton(
              text: 'Save Changes',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
```

### Business Dashboard Migration

```dart
// Focus on key areas for migration:
// 1. Bottom navigation colors
// 2. Card layouts
// 3. Button styling
// 4. Text field styling
// 5. Spacing consistency

// OLD bottom navigation
BottomNavigationBar(
  selectedItemColor: Color(0xFF32CD32),
  unselectedItemColor: Colors.grey,
  items: [...],
)

// NEW bottom navigation (already updated)
BottomNavigationBar(
  selectedItemColor: AppColors.primary,
  unselectedItemColor: Colors.grey,
  items: [...],
)
```

## Migration Checklist

### For Each Screen

- [ ] Update imports to use design system
- [ ] Replace hardcoded colors with design system colors
- [ ] Update all spacing to use SpacingSystem
- [ ] Replace custom buttons with DesignSystem buttons
- [ ] Update text styles to use TypographySystem
- [ ] Replace custom cards with design system cards
- [ ] Update text fields to use design system patterns
- [ ] Replace loading indicators
- [ ] Update SnackBars and notifications
- [ ] Test all interactions and visual appearance
- [ ] Verify responsive behavior
- [ ] Check dark theme compatibility

### Testing After Migration

1. **Visual Consistency**: All elements should follow the same design patterns
2. **Color Harmony**: Primary (lime green) and secondary (gold) colors used consistently
3. **Spacing Rhythm**: Golden ratio spacing creates visual harmony
4. **Typography Hierarchy**: Clear visual hierarchy with proper text styles
5. **Interactive States**: Hover, pressed, and disabled states work correctly
6. **Responsive Behavior**: Components adapt to different screen sizes
7. **Accessibility**: Proper contrast ratios and touch targets

## Best Practices

1. **Gradual Migration**: Update one screen at a time to avoid conflicts
2. **Component Reuse**: Prefer design system components over custom implementations
3. **Consistent Patterns**: Use the same design patterns across similar features
4. **Extension Over Customization**: Use design system extensions rather than overriding styles
5. **Documentation**: Update component documentation as you migrate

## Common Pitfalls to Avoid

1. **Mixing Old and New**: Don't mix hardcoded values with design system values
2. **Overriding Styles**: Avoid overriding design system styles unless absolutely necessary
3. **Inconsistent Spacing**: Always use the spacing system for consistency
4. **Wrong Color Usage**: Use semantic colors (primary, secondary, error) appropriately
5. **Ignoring Typography**: Always use typography system for text styling

## Getting Help

- Check `DesignSystemExamplesScreen` for component usage examples
- Refer to individual theme files in `lib/core/design_system/themes/`
- Use the design system extension methods for quick access: `context.ds`
- Test components in isolation before integrating into screens
