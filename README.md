# Hadhir Business - Order Receiver App

[![CI/CD Pipeline](https://github.com/YOUR_USERNAME/order-receiver-app-2/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/YOUR_USERNAME/order-receiver-app-2/actions/workflows/ci-cd.yml)
[![Security Scanning](https://github.com/YOUR_USERNAME/order-receiver-app-2/actions/workflows/security.yml/badge.svg)](https://github.com/YOUR_USERNAME/order-receiver-app-2/actions/workflows/security.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive business management application for restaurants, stores, pharmacies, and cloud kitchens to manage orders, integrate with POS systems, and coordinate with a centralized delivery platform.

## 🔄 Automated Deployment

This project uses **GitHub Actions for automated CI/CD** with multi-environment deployments:

- **Development**: Auto-deploy on push to `develop` branch
- **Staging**: Auto-deploy on push to `main` branch  
- **Production**: Manual approval after staging validation

**[📖 Complete CI/CD Setup Guide](./.github/README.md)**

## 📋 Complete Documentation

**[📚 Documentation Index](./DOCS_INDEX.md)** - All documentation organized by category

**[📚 Complete Technical Documentation](./DOCUMENTATION.md)** - Architecture, features, API reference, and deployment guide

## ✅ Project Status

**Production Ready** - Fully functional Flutter mobile app with Python backend API

- ✅ **Mobile App**: Complete Flutter application with all business features
- ✅ **Backend API**: Full Python FastAPI server with MongoDB integration
- ✅ **Multi-language**: English and Arabic localization complete
- ✅ **Build Ready**: Clean compilation, ready for app store deployment

## 🚀 Quick Start

### Mobile App (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

### Backend API (Python)

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 📱 Key Features

- **Order Management** - Real-time order tracking and management
- **POS Integration** - Square, Toast, Clover, and custom systems
- **Multi-language** - Complete English and Arabic support
- **Business Analytics** - Sales metrics and performance insights
- **Discount Management** - Flexible promotional campaigns
- **Responsive Design** - Mobile, tablet, and desktop optimized

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.27+, Dart, Material Design 3
- **Backend**: FastAPI, MongoDB, JWT Authentication
- **Integration**: POS APIs, REST APIs, Real-time notifications

## 📚 Additional Documentation

- **[User Guide](./USER_GUIDE.md)** - Complete application usage guide
- **[Production Guide](./PRODUCTION_IMPLEMENTATION_GUIDE.md)** - Deployment instructions
- **[Production Roadmap](./PRODUCTION_ROADMAP.md)** - Development planning
- **[Changelog](./CHANGELOG.md)** - Version history and updates

## 📄 License

© 2025 Hadhir Business. All rights reserved.
