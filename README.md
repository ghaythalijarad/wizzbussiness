# Hadhir Business - Order Receiver App

A comprehensive business management application for restaurants, stores, pharmacies, and cloud kitchens to manage orders, integrate with POS systems, and coordinate with a centralized delivery platform.

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

- **📋 Order Management**: Accept, track, and manage customer orders
- **💳 POS Integration**: Connect with Square, Toast, Clover, and custom systems
- **🔔 Real-time Notifications**: Customer and driver notifications
- **📊 Business Analytics**: Performance metrics and reports
- **🌐 Multi-language**: English and Arabic support
- **🔌 Platform Integration**: Centralized delivery platform connectivity

## 🏗️ Architecture

```text
Customer Apps → Centralized Platform → Hadhir Business App
                       ↓
              Driver Apps ← Platform (handles assignments)
```

## 📚 Documentation

- **[Complete User Guide](./USER_GUIDE.md)** - Comprehensive app usage guide
- **[Centralized Platform Architecture](./docs/CENTRALIZED_PLATFORM_ARCHITECTURE.md)** - Platform integration details
- **[Deployment Guide](./docs/CENTRALIZED_PLATFORM_STARTER.md)** - Platform deployment template

## 🛠️ Tech Stack

### Frontend

- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language
- **Material Design** - UI components

### Backend

- **FastAPI** - Modern Python web framework
- **MongoDB** - Document database
- **Beanie** - ODM for MongoDB
- **JWT** - Authentication

### Integration

- **POS Systems** - Square, Toast, Clover APIs
- **Webhooks** - Real-time order and driver updates
- **REST APIs** - Centralized platform communication

## 📁 Project Structure

```text
├── frontend/              # Flutter mobile app
│   ├── lib/              # Main application code
│   ├── android/          # Android platform files
│   └── ios/              # iOS platform files
├── backend/              # Python API server
│   ├── app/              # Application modules
│   ├── tests/            # Test suites
│   └── requirements.txt  # Python dependencies
├── docs/                 # Documentation
└── USER_GUIDE.md         # Complete user guide
```

## 🚀 Deployment

### Mobile App

- **Android**: Build APK/AAB for Google Play Store
- **iOS**: Build IPA for Apple App Store

### Backend API

- **Heroku**: Platform-as-a-Service deployment
- **Railway**: Modern deployment platform  
- **DigitalOcean**: Virtual private servers
- **AWS**: Enterprise cloud hosting

### Database

- **MongoDB Atlas**: Fully managed cloud database
- **Local MongoDB**: Development environment

## 🔒 Security

- **JWT Authentication**: Secure token-based auth
- **Password Encryption**: BCrypt password hashing
- **API Security**: Request validation and rate limiting
- **Data Protection**: Encrypted data transmission

## 📞 Support

- **📖 Documentation**: [Complete User Guide](./USER_GUIDE.md)
- **🏗️ Architecture**: [Platform Integration Guide](./docs/CENTRALIZED_PLATFORM_ARCHITECTURE.md)
- **🚀 Deployment**: [Platform Starter Template](./docs/CENTRALIZED_PLATFORM_STARTER.md)

## 📄 License

© 2025 Hadhir Business. All rights reserved.
