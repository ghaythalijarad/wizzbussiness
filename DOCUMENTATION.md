# Hadhir Business - Order Receiver App Documentation

A comprehensive business management application for restaurants, stores, pharmacies, and cloud kitchens to manage orders, integrate with POS systems, and coordinate with a centralized delivery platform.

## 📋 Table of Contents

1. [Project Status](#project-status)
2. [Quick Start](#quick-start)
3. [Architecture Overview](#architecture-overview)
4. [Features](#features)
5. [Localization](#localization)
6. [Testing](#testing)
7. [API Documentation](#api-documentation)
8. [Development Guide](#development-guide)
9. [Deployment](#deployment)

---

## 🚀 Project Status

**Production Ready** - Fully functional Flutter mobile app with Python backend API

### Current Status
- ✅ **Mobile App**: Complete Flutter application with all business features
- ✅ **Backend API**: Full Python FastAPI server with MongoDB integration
- ✅ **Local Notifications**: Flutter local notifications working correctly (v17.2.4)
- ✅ **POS Integration**: Square, Toast, Clover, and custom system support
- ✅ **Multi-language**: English and Arabic localization complete
- ✅ **Build Ready**: Clean compilation, ready for app store deployment
- ✅ **Code Quality**: 125 analysis issues (all non-critical style suggestions)
- ✅ **Test Coverage**: Unit tests for core order management functionality
- ✅ **Documentation**: Clean project documentation, development artifacts removed

### Recent Updates (June 2025)
- 🔧 **Flutter Local Notifications**: Resolved compilation errors by removing conflicting local plugin files
- 🎨 **Deprecation Warnings**: Updated all `withOpacity()` calls to `withValues(alpha: ...)`
- 🛠️ **Android Build**: Fixed Gradle configuration and updated compileSdk to 35
- 🧹 **Code Cleanup**: Removed unused test files and development artifacts
- 📚 **Documentation**: Streamlined documentation, removed redundant tracking files

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.7+
- Python 3.8+
- MongoDB Atlas account (or local MongoDB)

### Mobile App (Flutter)

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Backend API (Python)

```bash
# Navigate to backend directory
cd backend

# Install dependencies
pip install -r requirements.txt

# Start the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Local Development URLs
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health

---

## 🏗️ Architecture Overview

### Frontend (Flutter)
- **Framework**: Flutter 3.7+
- **State Management**: Provider pattern
- **HTTP Client**: Dio for API communication
- **Local Storage**: SharedPreferences
- **Notifications**: flutter_local_notifications
- **Localization**: ARB files (English & Arabic)

### Backend (Python)
- **Framework**: FastAPI
- **Database**: MongoDB Atlas with Beanie ODM
- **Authentication**: JWT tokens
- **File Storage**: Local file system with multipart upload
- **API Documentation**: Automatic Swagger/OpenAPI

### Database Schema
```
Users Collection:
- id, email, phone, password_hash
- business_type, business_name
- created_at, updated_at

Businesses Collection:
- id, name, type, email, phone
- address (separate Address collection)
- settings, business_hours
- created_at, updated_at

Orders Collection:
- id, business_id, customer_info
- items, total_amount, status
- created_at, updated_at

Notifications Collection:
- id, business_id, title, message
- type, priority, read_status
- created_at
```

---

## ✨ Features

### Core Business Management
- **Dashboard**: Real-time business metrics and quick actions
- **Order Management**: View, update, and track order status
- **Item Management**: Add, edit, and organize menu items
- **Analytics**: Sales performance and business insights
- **Discount Management**: Create percentage, fixed amount, and conditional discounts

### Advanced Features
- **POS Integration**: Square, Toast, Clover, and custom systems
- **Multi-language Support**: English and Arabic with RTL support
- **Responsive Design**: Optimized for mobile, tablet, and desktop
- **Local Notifications**: Real-time order notifications
- **Order Simulation**: Generate test orders for development
- **Centralized Platform**: Multi-business coordination (planned)

### Discount System
- **Percentage Discounts**: Apply percentage-based reductions
- **Fixed Amount**: Apply fixed monetary discounts
- **Conditional Discounts**: Minimum order requirements
- **Buy X Get Y**: Complex promotional offers
- **Free Delivery**: Complimentary shipping options
- **Scheduling**: Set start and end dates for promotions

### User Management
- **Registration**: Multi-step business registration with document upload
- **Authentication**: Secure JWT-based login system
- **Profile Management**: Update business and owner information
- **Password Management**: Secure password change with validation

---

## 🌍 Localization

### Supported Languages
- **English (en)**: Primary language
- **Arabic (ar)**: Full RTL support

### Implementation
- **ARB Files**: JSON-based localization files
- **Generated Code**: Automatic Dart code generation
- **Context Integration**: AppLocalizations throughout the app

### Key Localized Components
- Login and registration flows
- Dashboard and navigation
- Order management interfaces
- Item and discount management
- Settings and profile pages
- Error messages and notifications

### Adding New Translations
1. Add keys to `lib/l10n/app_en.arb`
2. Add Arabic translations to `lib/l10n/app_ar.arb`
3. Run `flutter gen-l10n` to generate code
4. Use `AppLocalizations.of(context)!.keyName` in widgets

---

## 🧪 Testing

### Flutter Tests
```bash
cd frontend
flutter test
```

### Backend Tests
```bash
cd backend
pytest
```

### Test Coverage
- **Unit Tests**: Core business logic and utilities
- **Widget Tests**: Key UI components
- **API Tests**: Backend endpoint validation
- **Integration Tests**: End-to-end user flows

### Order Simulation Testing
The app includes a built-in order simulation feature for testing:
- Generate 1 or 3 realistic test orders
- UAE-specific customer data and addresses
- Random menu items with proper pricing
- VAT calculation (5%) and delivery fees

---

## 📚 API Documentation

### Authentication Endpoints
```
POST /auth/register-multipart - Register new business
POST /auth/jwt/login - JWT login
POST /auth/jwt/logout - JWT logout
GET /auth/me - Get current user profile
```

### Business Endpoints
```
GET /businesses - List businesses
POST /businesses - Create business
GET /businesses/{id} - Get business details
PUT /businesses/{id} - Update business
```

### Order Endpoints
```
GET /orders - List orders
POST /orders - Create order
GET /orders/{id} - Get order details
PUT /orders/{id} - Update order
PUT /orders/{id}/status - Update order status
```

### Notification Endpoints
```
GET /notifications - List notifications
POST /notifications - Send notification
PUT /notifications/{id}/read - Mark as read
DELETE /notifications/{id} - Delete notification
```

### Health Check
```
GET /health - Basic health check
GET /health/detailed - Detailed system status
```

---

## 💻 Development Guide

### Project Structure
```
order-receiver-app-2/
├── frontend/                 # Flutter mobile app
│   ├── lib/
│   │   ├── l10n/            # Localization files
│   │   ├── models/          # Data models
│   │   ├── screens/         # UI screens
│   │   ├── services/        # API and business logic
│   │   ├── utils/           # Helper utilities
│   │   └── widgets/         # Reusable UI components
│   └── pubspec.yaml
├── backend/                  # Python FastAPI server
│   ├── app/
│   │   ├── controllers/     # API route handlers
│   │   ├── models/          # Database models
│   │   ├── services/        # Business logic
│   │   └── core/            # Configuration
│   └── requirements.txt
└── docs/                    # Additional documentation
```

### Coding Standards
- **Flutter**: Follow Dart style guide with analysis_options.yaml
- **Python**: PEP 8 compliance with type hints
- **Git**: Conventional commit messages
- **Documentation**: Inline comments for complex logic

### Environment Configuration
```bash
# Backend environment variables
MONGODB_URL=mongodb+srv://...
JWT_SECRET_KEY=your-secret-key
DEBUG=true

# Flutter environment
API_BASE_URL=http://localhost:8000
```

### Adding New Features
1. Create feature branch from main
2. Implement backend API endpoints
3. Add corresponding Flutter UI
4. Update localization files
5. Add tests for new functionality
6. Update documentation
7. Submit pull request

---

## 🚀 Deployment

### Local Development
Backend runs on `http://localhost:8000`
Frontend connects to local backend automatically

### Production Considerations
- **Environment Variables**: Configure for production MongoDB
- **SSL/TLS**: Enable HTTPS for production API
- **App Store**: Follow platform guidelines for mobile deployment
- **Monitoring**: Implement logging and error tracking
- **Backup**: Regular database backups

### Build Commands
```bash
# Flutter production build
cd frontend
flutter build apk --release
flutter build ios --release

# Backend production
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

---

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch
3. Make changes with proper testing
4. Update documentation
5. Submit pull request with detailed description

### Code Review Process
- All PRs require review
- Tests must pass
- Documentation must be updated
- Follow established coding standards

---

## 📞 Support

For technical support or questions:
- Review this documentation first
- Check the API documentation at `/docs`
- Examine the test files for usage examples
- Refer to Flutter and FastAPI official documentation

---

*Last Updated: June 30, 2025*
