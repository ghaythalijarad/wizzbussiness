# 🧪 STAGING TESTING GUIDE

## 🎯 **Phase 1 Core Features Testing**

Your staging environment is now **LIVE and ready for testing**! Follow this guide to validate all core functionality.

---

## 🚀 **Quick Start**

### 1. **Start the Staging Server**
```bash
./scripts/start-staging-server.sh
```

### 2. **Access the Staging App**
Open your browser to: **http://localhost:8080**

### 3. **Login with Staging Credentials**
```
Email: staging-test@wizzbusiness.com
Password: StagingTest123!
```

---

## 📋 **Core Features Testing Checklist**

### ✅ **Authentication Testing**
- [ ] **Login Flow**
  - Navigate to login page
  - Enter staging credentials
  - Verify successful login
  - Check user session persistence

- [ ] **Logout Flow**
  - Click logout button
  - Verify redirect to login
  - Confirm session cleared

- [ ] **Token Handling**
  - Verify API calls include authentication
  - Check token refresh functionality
  - Test expired token handling

### ✅ **Product Search Testing** (Fixed Feature!)
- [ ] **Basic Search**
  - Search for existing products
  - Verify results appear instantly
  - Test empty search (should show all products)

- [ ] **Advanced Search**
  - Search by product name
  - Search by product description
  - Test case-insensitive search
  - Test partial matching

- [ ] **Performance**
  - Verify search results appear in <100ms
  - Test with various search terms
  - Check search while typing

### ✅ **Order Management Testing**
- [ ] **View Orders**
  - Access orders list
  - Verify order data loads
  - Check order status display

- [ ] **Create Order**
  - Navigate to create order form
  - Fill in order details
  - Submit and verify creation
  - Check order appears in list

- [ ] **Update Order Status**
  - Select an existing order
  - Change order status
  - Verify status update
  - Check status persistence

- [ ] **Order Details**
  - View individual order details
  - Verify all order information
  - Test order modification

### ✅ **Merchant Dashboard Testing**
- [ ] **Dashboard Access**
  - Navigate to dashboard
  - Verify data loads correctly
  - Check dashboard components

- [ ] **Statistics Display**
  - Verify order statistics
  - Check revenue displays
  - Test data accuracy

- [ ] **Navigation**
  - Test menu navigation
  - Verify page transitions
  - Check responsive design

---

## 🔧 **Technical Validation**

### **API Integration**
- [ ] **Backend Connectivity**
  - Verify API calls to staging backend
  - Check error handling
  - Test network failure scenarios

- [ ] **Authentication Integration**
  - Verify Cognito integration
  - Test token-based API access
  - Check authentication errors

### **Feature Flags**
- [ ] **Core Features Enabled**
  - Authentication: ✅ Enabled
  - Search: ✅ Enabled
  - Orders: ✅ Enabled
  - Dashboard: ✅ Enabled

- [ ] **Enhanced Features Disabled**
  - Real-time notifications: ❌ Disabled
  - Firebase push: ❌ Disabled
  - Floating UI: ❌ Disabled

### **Performance**
- [ ] **Load Times**
  - Initial page load < 3 seconds
  - Search results < 100ms
  - API calls < 2 seconds
  - Page transitions smooth

- [ ] **Responsiveness**
  - Test on desktop browser
  - Test mobile viewport
  - Verify responsive design

---

## 🧪 **Test Scenarios**

### **Scenario 1: New Merchant Onboarding**
1. Login with staging credentials
2. Navigate through dashboard
3. Create first order
4. Search for products
5. Update order status

### **Scenario 2: Daily Operations**
1. Login and check dashboard
2. Review pending orders
3. Update multiple order statuses
4. Search for specific products
5. Create new orders for customers

### **Scenario 3: Error Handling**
1. Test with invalid login credentials
2. Test network disconnection
3. Test API timeout scenarios
4. Verify error messages are user-friendly

---

## 📊 **Expected Results**

### **✅ Success Criteria**
- Login works with staging credentials
- Search returns accurate results instantly
- Orders can be created and updated
- Dashboard displays correctly
- No console errors
- Responsive design works

### **⚠️ Known Limitations (Phase 1)**
- Real-time notifications not enabled
- Firebase push notifications disabled
- Advanced merchant features in Phase 2
- Some enhanced UI components in Phase 3

---

## 🐛 **Bug Reporting**

If you find any issues during testing:

### **High Priority Issues**
- Authentication failures
- Search not working
- Cannot create/update orders
- API connection errors

### **Medium Priority Issues**
- UI/UX inconsistencies
- Performance issues
- Mobile responsiveness problems

### **Low Priority Issues**
- Minor visual glitches
- Non-critical feature requests

---

## 📝 **Testing Notes Template**

```
Date: [Date]
Tester: [Your Name]
Environment: staging
Browser: [Chrome/Safari/Firefox]
Device: [Desktop/Mobile]

Test Results:
- Authentication: ✅/❌
- Product Search: ✅/❌
- Order Management: ✅/❌
- Dashboard: ✅/❌

Issues Found:
1. [Description]
2. [Description]

Overall Assessment:
- Ready for Phase 2? ✅/❌
- Feedback: [Comments]
```

---

## 🚀 **Ready for Phase 2?**

Once Phase 1 testing is complete and satisfactory:

```bash
# Deploy enhanced features
./scripts/deploy.sh staging enhanced
```

**Phase 2 will add:**
- Real-time order notifications
- Enhanced merchant approval workflow
- Online/offline status toggle
- WebSocket integration

---

## 📞 **Support**

- **Staging API**: https://371prqogn5.execute-api.us-east-1.amazonaws.com/staging
- **Test Credentials**: staging-test@wizzbusiness.com / StagingTest123!
- **Local Server**: http://localhost:8080
- **Documentation**: See project documentation files

---

**🎯 Your staging environment is ready for comprehensive testing! Start with the basic scenarios and work through the complete checklist.**
