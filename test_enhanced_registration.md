# Enhanced Registration Form Test Plan

## ✅ Business Photo Mandatory Feature
### Test Cases:
1. **Attempt submission without business photo**
   - Expected: Red error message "Business photo is required. Please add a photo of your business."
   - Form should not proceed

2. **Add business photo and submit**
   - Expected: Form should proceed to upload photo
   - Photo preview should appear in 100px container
   - Submit button should work after photo is selected

3. **Visual indicators**
   - Expected: Red asterisk (*) next to "Business Photo" label
   - Text should show "Required - Please add a photo" when no photo selected
   - Text should show filename in green when photo selected

## ✅ Compact Documents Section
### Test Cases:
1. **Grid layout verification**
   - Expected: 2x2 grid layout with 4 document cards
   - Cards should be evenly spaced with proper margins

2. **Visual design verification**
   - Expected: Each card shows appropriate icon (📋, 👤, 🏥, 📷)
   - "UPLOAD" badge in blue background for empty cards
   - "UPLOADED" badge in green background for filled cards
   - Checkmark icon replaces document icon when uploaded

3. **Interaction testing**
   - Expected: Entire card should be clickable
   - Tap should open file picker
   - Visual feedback on touch (InkWell ripple effect)

4. **File upload flow**
   - Expected: After selecting file, card updates to show:
     - Green border instead of gray
     - Green checkmark icon
     - "UPLOADED" badge in green
     - Truncated filename at bottom

5. **Responsive design**
   - Expected: Cards should adapt to different screen sizes
   - Text should truncate properly with ellipsis
   - Touch targets should remain accessible

## 🎯 Success Criteria
- ✅ Business photo is mandatory and blocks submission
- ✅ Documents section takes up significantly less vertical space
- ✅ Upload buttons are highly visible and prominent
- ✅ Visual feedback is clear and immediate
- ✅ All functionality works on iOS simulator
- ✅ Registration flow completes successfully with business photo

## 📱 Live Testing Results
*To be filled during actual device testing*

### Registration Flow Test:
1. Open app → [ ]
2. Navigate to registration → [ ]
3. Fill form without business photo → [ ]
4. Attempt submit (should fail) → [ ]
5. Add business photo → [ ]
6. Test document uploads → [ ]
7. Complete registration → [ ]

### Visual Verification:
1. Documents grid layout → [ ]
2. Upload button visibility → [ ]
3. Status indicators → [ ]
4. Touch responsiveness → [ ]
5. File upload feedback → [ ]
