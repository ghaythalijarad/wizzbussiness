# Flutter Frontend Testing Guide

## 🧪 Testing Registration and Login

### Prerequisites
✅ Backend running on: `http://localhost:8000`  
✅ Flutter app running on: iPhone 16 Pro Simulator  
✅ AuthService configured to use: `http://127.0.0.1:8000`

---

## 📝 Test 1: User Registration

### Step-by-Step Registration Test:

1. **Launch the App**
   - Open the Flutter app on the iPhone 16 Pro simulator
   - You should see the Welcome/Splash screen

2. **Navigate to Registration**
   - Look for "Register" or "Sign Up" button
   - Tap to go to the Registration Form Screen

3. **Fill Out the Registration Form**
   **Business Information:**
   - Business Type: `Restaurant` (or any option)
   - Business Name: `Test Flutter Restaurant`
   - Owner Name: `Flutter Test Owner`
   
   **Authentication:**
   - Email: `fluttertest@example.com`
   - Phone: `7701234567` (10 digits, will auto-prefix +964)
   - Password: `Password123`
   - Confirm Password: `Password123`

   **Address Information (ALL REQUIRED):**
   - Country: `Iraq`
   - City: `Baghdad`
   - District: `Karrada` ⚠️ **REQUIRED**
   - Neighborhood: `Al-Karrada Al-Sharqiya`
   - Street: `Al-Karrada Street`
   - Building Number: `123`
   - Zip Code: `10001`

   **Owner Information:**
   - National ID: `123456789012`
   - Date of Birth: `1990-01-01`

4. **Document Uploads (Optional)**
   - You can skip file uploads for testing
   - Or upload sample images/PDFs if available

5. **Submit Registration**
   - Tap "Register" or "Submit" button
   - Should show loading indicator
   - **Expected Result**: Green success message "Registration successful, please login"
   - Should navigate back to login screen

---

## 🔐 Test 2: User Login

### Step-by-Step Login Test:

1. **Navigate to Login Screen**
   - Should automatically be on login screen after registration
   - Or navigate from welcome screen

2. **Test with Existing User (Quick Test)**
   - Email: `testlogin@example.com`
   - Password: `Password123`
   - Tap "Login"
   - **Expected Result**: Should login successfully and show business dashboard

3. **Test with Newly Registered User**
   - Email: `fluttertest@example.com`
   - Password: `Password123`
   - Tap "Login"
   - **Expected Result**: Should login successfully and show business dashboard

---

## 🚨 Expected Behaviors

### Registration Success Indicators:
- ✅ Loading spinner during submission
- ✅ Green success snackbar message
- ✅ Automatic navigation back to login screen
- ✅ No error messages

### Registration Error Indicators:
- ❌ Red error snackbar with specific message
- ❌ Form validation errors (missing required fields)
- ❌ "User already exists" if email is taken

### Login Success Indicators:
- ✅ Loading spinner during login
- ✅ Navigation to Business Dashboard
- ✅ Business name displayed in dashboard
- ✅ Menu items/categories visible

### Login Error Indicators:
- ❌ Red error snackbar
- ❌ "Invalid credentials" message
- ❌ "User not verified" message (if applicable)

---

## 🔍 Debugging Information

### If Registration Fails:
1. Check console logs in Flutter app
2. Verify all required address fields are filled
3. Ensure password meets requirements (uppercase, lowercase, numbers, 8+ chars)
4. Check phone number format (10 digits only)

### If Login Fails:
1. Verify credentials are correct
2. Check if user was successfully created in database
3. Ensure network connectivity to backend

### Console Commands for Verification:
```bash
# Check if user was created
curl -X POST "http://localhost:8000/auth/jwt/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=fluttertest@example.com&password=Password123"

# Should return JWT token if successful
```

---

## 📱 Testing Flow Summary

**Complete Test Sequence:**
1. Open Flutter app ➜ 
2. Navigate to Registration ➜ 
3. Fill complete form ➜ 
4. Submit registration ➜ 
5. See success message ➜ 
6. Return to login ➜ 
7. Login with new credentials ➜ 
8. Access business dashboard ✅

**Alternative Quick Test:**
1. Open Flutter app ➜ 
2. Navigate to Login ➜ 
3. Use `testlogin@example.com` / `Password123` ➜ 
4. Access business dashboard ✅

---

## 🎯 Key Test Points

- **Address Validation**: District field is mandatory
- **Phone Format**: 10 digits only, auto-prefixed with +964
- **Password Policy**: Must include uppercase, lowercase, number, 8+ chars
- **Network Configuration**: iOS simulator uses 127.0.0.1:8000
- **Token Storage**: JWT tokens stored in SharedPreferences
- **Navigation**: Registration success returns to login screen

---

*Ready to test! Follow the steps above in your Flutter app.*
