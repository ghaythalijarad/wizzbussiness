# Hadhir Business - Order Receiver App

A comprehensive business management application for restaurants, stores, pharmacies, and cloud kitchens to manage orders, integrate with POS systems, and coordinate with a centralized delivery platform.

## ✅ Project Status

**Production Ready** - Fully functional Flutter mobile app with Python backend API

- ✅ **Mobile App**: Complete Flutter application with all business features
- ✅ **Backend API**: Full Python FastAPI server with MongoDB integration
- ✅ **Local Notifications**: Flutter local notifications working correctly (v17.2.4)
- ✅ **POS Integration**: Square, Toast, Clover, and custom system support
- ✅ **Multi-language**: English and Arabic localization complete
- ✅ **Build Ready**: Clean compilation, ready for app store deployment
- ✅ **Code Quality**: 125 analysis issues (all non-critical style suggestions)
- ✅ **Test Coverage**: Unit tests for core order management functionality
- ✅ **Documentation**: Clean project documentation, development artifacts removed

### Recent Fixes (June 2025)

- 🔧 **Flutter Local Notifications**: Resolved compilation errors by removing conflicting local plugin files
- 🎨 **Deprecation Warnings**: Updated all `withOpacity()` calls to `withValues(alpha: ...)`
- 🛠️ **Android Build**: Fixed Gradle configuration and updated compileSdk to 35
- 🧹 **Code Cleanup**: Removed unused test files and development artifacts
- 📚 **Documentation**: Streamlined documentation, removed redundant tracking files

## 🚀 Quick Start

### Mobile App (Flutter)

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Backend API (Python)

```bash
# Navigate to backend
cd backend

# Install dependencies
pip install -r requirements.txt

# Start the server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 📱 Features

- **📋 Order Management**: Accept, track, and manage customer orders in real-time
- **💳 POS Integration**: Seamless connection with Square, Toast, Clover, and custom systems
- **🔔 Real-time Notifications**: Push notifications for orders, customers, and drivers
- **📊 Business Analytics**: Performance metrics, sales reports, and business insights
- **🌐 Multi-language Support**: Complete English and Arabic localization
- **🔌 Platform Integration**: Connect with centralized delivery platform
- **💼 Business Management**: Items, categories, discounts, and account settings
- **📱 Cross-platform**: Native mobile app for iOS and Android

## 🏗️ Architecture

```text
Customer Apps → Centralized Platform → Hadhir Business App
                       ↓
              Driver Apps ← Platform (handles assignments)
```

## 📚 Documentation

- **[User Guide](./USER_GUIDE.md)** - Complete application usage guide  
- **[Platform Architecture](./docs/CENTRALIZED_PLATFORM_ARCHITECTURE.md)** - System integration details
- **[Deployment Guide](./docs/CENTRALIZED_PLATFORM_STARTER.md)** - Platform deployment template
- **[Changelog](./CHANGELOG.md)** - Version history and updates

## 🛠️ Tech Stack

### Frontend

- **Flutter 3.27+** - Cross-platform mobile development
- **Dart** - Programming language
- **Material Design 3** - Modern UI components
- **Flutter Local Notifications** - Push notification system
- **Provider/Riverpod** - State management

### Backend

- **FastAPI** - High-performance Python web framework
- **MongoDB** - NoSQL document database
- **Beanie ODM** - Object Document Mapper for MongoDB
- **JWT Authentication** - Secure token-based auth
- **Pydantic** - Data validation and serialization

### Integration

- **POS APIs** - Square, Toast, Clover integration
- **REST APIs** - Platform communication
- **WebSockets** - Real-time updates
- **File Upload** - Image and document handling

## 📁 Project Structure

```text
├── frontend/              # Flutter mobile app
│   ├── lib/              # Main application code
│   │   ├── screens/      # App screens and pages
│   │   ├── widgets/      # Reusable UI components
│   │   ├── services/     # API and business logic
│   │   ├── models/       # Data models
│   │   └── l10n/         # Localization files
│   ├── android/          # Android platform files
│   ├── ios/              # iOS platform files
│   └── test/             # Flutter widget tests
├── backend/              # Python API server
│   ├── app/              # Application modules
│   │   ├── controllers/  # API route handlers
│   │   ├── models/       # Database models
│   │   ├── services/     # Business logic
│   │   └── schemas/      # Request/response schemas
│   ├── tests/            # Unit tests
│   └── requirements.txt  # Python dependencies
├── docs/                 # Core documentation
│   ├── CENTRALIZED_PLATFORM_ARCHITECTURE.md
│   └── CENTRALIZED_PLATFORM_STARTER.md
├── README.md             # This file
├── USER_GUIDE.md         # Complete user guide
└── CHANGELOG.md          # Version history
```

## 🚀 Deployment

### Prerequisites

- **Flutter SDK 3.27+** - Mobile app development
- **Python 3.9+** - Backend API server
- **MongoDB** - Database (Atlas recommended for production)

### Mobile App Deployment

```bash
# Android Release Build
flutter build apk --release
flutter build appbundle --release  # For Google Play Store

# iOS Release Build  
flutter build ios --release
# Then archive in Xcode for App Store
```

### Backend API Deployment

**Production Platforms:**
- **Heroku** - Easy deployment with Git integration
- **Railway** - Modern platform with auto-scaling
- **DigitalOcean** - Virtual private servers
- **AWS/GCP** - Enterprise cloud hosting

**Database Options:**
- **MongoDB Atlas** - Fully managed cloud database (recommended)
- **Self-hosted MongoDB** - Custom server setup

## 🔒 Security

- **JWT Authentication** - Secure token-based authentication
- **Password Encryption** - BCrypt password hashing
- **API Security** - Request validation and rate limiting  
- **Data Protection** - Encrypted data transmission
- **Input Validation** - Pydantic schema validation

## 📞 Support

- **📖 User Guide** - [Complete User Guide](./USER_GUIDE.md)
- **🏗️ Architecture** - [Platform Integration Guide](./docs/CENTRALIZED_PLATFORM_ARCHITECTURE.md)
- **🚀 Deployment** - [Platform Starter Template](./docs/CENTRALIZED_PLATFORM_STARTER.md)
- **📝 Changelog** - [Version History](./CHANGELOG.md)

## 📄 License

© 2025 Hadhir Business. All rights reserved.
