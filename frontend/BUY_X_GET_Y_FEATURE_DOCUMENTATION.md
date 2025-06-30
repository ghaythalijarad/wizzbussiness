# Buy X Get Y Discount Feature Documentation

## Overview

The Buy X Get Y discount feature allows businesses to create promotional offers where customers can get free or discounted items when they purchase specific quantities of certain items. For example: "Buy 2 Pizzas, Get 1 Drink Free" or "Buy 3 T-shirts, Get 1 T-shirt Free".

## Implementation Details

### 1. Model Changes

#### DiscountType Enum
Added `buyXGetY` to the existing `DiscountType` enum in `/lib/models/discount.dart`:

```dart
enum DiscountType {
  percentage,
  fixedAmount,
  conditional,
  freeDelivery,
  buyXGetY,  // New type added
  others,
}
```

#### Conditional Parameters
The Buy X Get Y discount uses the existing `conditionalParameters` field in the `Discount` model to store:

```dart
Map<String, dynamic> conditionalParameters = {
  'buyItemId': 'string',      // ID of the item to buy
  'buyQuantity': int,         // Quantity required to buy
  'getItemId': 'string',      // ID of the item to get for free/discounted
  'getQuantity': int,         // Quantity to get
};
```

### 2. UI Changes

#### Discount Creation Form
Enhanced the discount creation dialog in `/lib/screens/discount_management_page.dart`:

1. **Buy X Get Y Configuration Section**: Added when `discountType == DiscountType.buyXGetY`
2. **Buy Configuration**: 
   - Quantity input field
   - Item selection dropdown
3. **Get Configuration**:
   - Quantity input field  
   - Item selection dropdown

#### Form Validation
- Validates that both buy and get items are selected
- Validates that quantities are positive integers
- Prevents form submission if required fields are missing

#### Item Selection Dialogs
- **Single Item Selection**: Radio button interface for selecting individual items
- **Item Display**: Shows item name, category, and price
- **Clear Option**: Allows clearing selection

### 3. Localization Support

#### English (`app_en.arb`)
```json
"buyXGetY": "Buy X Get Y"
```

#### Arabic (`app_ar.arb`)
```json
"buyXGetY": "اشتري X واحصل على Y"
```

### 4. API Integration

Added comprehensive discount management API methods in `/lib/services/api_service.dart`:

- `createDiscount()`: Create new discount with Buy X Get Y parameters
- `updateDiscount()`: Update existing discount
- `deleteDiscount()`: Remove discount
- `getDiscounts()`: Fetch discounts with filtering
- `validateBuyXGetYDiscount()`: Validate discount eligibility for orders
- `applyDiscountToOrder()`: Apply discount to specific order
- `getDiscountStats()`: Get usage statistics

### 5. Form Structure

#### Buy X Get Y Configuration UI
```
┌─────────────────────────────────────┐
│ Buy X Get Y Configuration           │
├─────────────────────────────────────┤
│ Buy Configuration                   │
│ ┌──────────┐ ┌──────────────────┐  │
│ │Quantity  │ │Select Item ▼     │  │
│ └──────────┘ └──────────────────┘  │
│                                     │
│ Get Configuration                   │
│ ┌──────────┐ ┌──────────────────┐  │
│ │Quantity  │ │Select Item ▼     │  │
│ └──────────┘ └──────────────────┘  │
└─────────────────────────────────────┘
```

## Usage Examples

### Example 1: Buy 2 Pizzas, Get 1 Drink Free
```dart
Discount(
  type: DiscountType.buyXGetY,
  conditionalRule: ConditionalDiscountRule.buyXGetY,
  conditionalParameters: {
    'buyItemId': 'pizza-margherita-id',
    'buyQuantity': 2,
    'getItemId': 'cola-500ml-id', 
    'getQuantity': 1,
  },
  value: 0.0, // Free item
  // ... other properties
)
```

### Example 2: Buy 3 T-shirts, Get 1 T-shirt 50% Off
```dart
Discount(
  type: DiscountType.buyXGetY,
  conditionalRule: ConditionalDiscountRule.buyXGetY,
  conditionalParameters: {
    'buyItemId': 'tshirt-basic-id',
    'buyQuantity': 3,
    'getItemId': 'tshirt-basic-id', // Same item
    'getQuantity': 1,
  },
  value: 50.0, // 50% discount
  // ... other properties
)
```

## Technical Implementation

### 1. Form State Management
- Uses `StatefulBuilder` for dynamic form updates
- Manages item selection state with callback functions
- Validates form inputs before submission

### 2. Item Selection Logic
- Loads all items from all categories via API
- Displays items with category context and pricing
- Supports both buy and get item selection independently

### 3. Data Persistence
- Stores Buy X Get Y parameters in `conditionalParameters` field
- Uses `ConditionalDiscountRule.buyXGetY` for rule identification
- Maintains backward compatibility with existing discount types

### 4. Error Handling
- Validates item selection before form submission
- Shows error dialogs for missing required fields
- Handles API errors gracefully with user feedback

## Testing Scenarios

### Create Buy X Get Y Discount
1. Navigate to Discounts section
2. Tap "Create Discount" 
3. Select "Buy X Get Y" from discount type dropdown
4. Fill in buy configuration (quantity + item)
5. Fill in get configuration (quantity + item)
6. Complete other required fields
7. Save discount

### Edit Existing Buy X Get Y Discount
1. Tap edit on existing Buy X Get Y discount
2. Modify quantities or items
3. Save changes
4. Verify parameters are updated correctly

### Form Validation
1. Try to save without selecting buy item → Should show error
2. Try to save without selecting get item → Should show error
3. Enter invalid quantities (0 or negative) → Should show validation error
4. Enter valid data → Should save successfully

## Future Enhancements

### Potential Improvements
1. **Multiple Item Types**: Support buying different items to get reward
2. **Tiered Discounts**: Progressive rewards based on quantity
3. **Time-based Restrictions**: Limit offers to specific hours/days
4. **Customer Segments**: Target specific customer groups
5. **Usage Limits**: Per-customer usage restrictions
6. **Preview Mode**: Show customers how discount applies to their cart

### Backend Integration
The current implementation focuses on the frontend discount creation interface. Backend integration would require:

1. **Order Processing Logic**: Automatically detect and apply Buy X Get Y discounts
2. **Inventory Management**: Track free item allocation
3. **Analytics**: Monitor discount performance and usage patterns
4. **Customer Interface**: Show available discounts to customers during ordering

## Conclusion

The Buy X Get Y discount feature provides a comprehensive solution for creating complex promotional offers. The implementation maintains code quality, follows Flutter best practices, and provides a user-friendly interface for business owners to create and manage their promotional campaigns.
