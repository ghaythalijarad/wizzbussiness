# Wizz Business - Order Receiver App

A comprehensive Flutter-based business management application for restaurants and food businesses, featuring order management, POS integration, product management, and real-time business analytics.

## 🚀 Features

### Core Functionality
- **Multi-language Support**: Arabic and English interface
- **User Authentication**: Secure registration and auto-login flow
- **Business Management**: Complete business profile and settings management
- **Order Management**: Real-time order processing and tracking
- **Product Management**: Full CRUD operations for menu items and categories
- **POS Integration**: Support for Square, Toast, Clover, and generic APIs
- **Discount Management**: Create and manage various discount types
- **Real-time Analytics**: Business performance insights and reporting

### User Experience
- **Auto-Login**: Seamless registration → verification → dashboard flow
- **Responsive Design**: Optimized for mobile, tablet, and desktop
- **Real-time Updates**: Live order notifications and status updates
- **Offline Support**: Core functionality works without internet connection
- **Business Photo Management**: Upload and manage business profile images

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.x with Dart
- **State Management**: Provider pattern with ChangeNotifier
- **Navigation**: Flutter Router with named routes
- **UI Components**: Custom widgets with Material Design
- **Localization**: Complete Arabic and English support
- **Authentication**: AWS Cognito integration with auto-login

### Backend (AWS Serverless)
- **API Gateway**: RESTful API endpoints
- **Lambda Functions**: Node.js serverless functions
- **Database**: DynamoDB with optimized schemas
- **Authentication**: AWS Cognito User Pools
- **File Storage**: S3 for business photos and assets
- **Real-time**: WebSocket connections for live updates

### Third-party Integrations
- **POS Systems**: Square, Toast, Clover APIs
- **Payment Processing**: Stripe integration
- **Analytics**: Custom dashboard with business metrics
- **Notifications**: Push notifications for orders and updates

## 📱 Screenshots

### Registration & Authentication
- Seamless multi-step registration process
- Auto-login after email verification
- Secure password reset functionality

### Business Dashboard
- Real-time order tracking
- Business performance analytics
- Quick access to all management features

### Product Management
- Visual product catalog
- Category organization
- Bulk operations support

### Order Management
- Live order notifications
- Order status tracking
- Customer communication tools

## 🛠️ Installation & Setup

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- iOS Simulator / Android Emulator
- AWS CLI (for backend deployment)
- Node.js 18+ (for backend development)

### Frontend Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/ghaythalijarad/wizzbussiness.git
   cd wizzbussiness
   ```

2. **Install Flutter dependencies**
   ```bash
   cd frontend
   flutter pub get
   ```

3. **Configure environment variables**
   ```bash
   # Create .env file with your AWS credentials
   cp .env.example .env
   ```

4. **Run the application**
   ```bash
   # For iOS
   flutter run -d ios

   # For Android
   flutter run -d android

   # For Web
   flutter run -d chrome
   ```

### Backend Setup

1. **Install dependencies**
   ```bash
   cd backend
   npm install
   ```

2. **Configure AWS credentials**
   ```bash
   aws configure
   ```

3. **Deploy to AWS**
   ```bash
   # Deploy all services
   npm run deploy

   # Deploy specific function
   npm run deploy:auth
   ```

## ⚙️ Configuration

### Environment Variables

#### Frontend (.env)
```env
# AWS Configuration
COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
COGNITO_USER_POOL_CLIENT_ID=xxxxxxxxxxxxxxxxxx
COGNITO_REGION=us-east-1

# API Configuration
API_BASE_URL=https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/dev
ENVIRONMENT=development

# Feature Flags
ENABLE_OFFLINE_MODE=true
ENABLE_PUSH_NOTIFICATIONS=true
```

#### Backend (serverless.yml)
```yaml
# AWS Configuration
provider:
  name: aws
  runtime: nodejs18.x
  region: us-east-1
  stage: ${opt:stage, 'dev'}

# Environment Variables
environment:
  USERS_TABLE: order-receiver-users-${self:provider.stage}
  BUSINESSES_TABLE: order-receiver-businesses-${self:provider.stage}
  ORDERS_TABLE: order-receiver-orders-${self:provider.stage}
```

## 🔧 Development

### Project Structure
```
order-receiver-app/
├── frontend/                 # Flutter application
│   ├── lib/
│   │   ├── models/          # Data models
│   │   ├── screens/         # UI screens
│   │   ├── services/        # API and business logic
│   │   ├── widgets/         # Reusable UI components
│   │   └── l10n/           # Localization files
│   └── test/               # Unit and widget tests
├── backend/                 # AWS Lambda functions
│   ├── functions/
│   │   ├── auth/           # Authentication endpoints
│   │   ├── orders/         # Order management
│   │   ├── products/       # Product CRUD operations
│   │   └── businesses/     # Business management
│   └── test/               # Backend tests
└── docs/                   # Documentation
```

### Key Commands

#### Frontend Development
```bash
# Run app in development mode
flutter run --dart-define=ENVIRONMENT=development

# Build for production
flutter build apk --release
flutter build ios --release

# Run tests
flutter test

# Generate code coverage
flutter test --coverage
```

#### Backend Development
```bash
# Local development
npm run dev

# Run tests
npm test

# Deploy to staging
npm run deploy:staging

# Deploy to production
npm run deploy:prod
```

## 🧪 Testing

### Frontend Testing
- **Unit Tests**: Model and service layer testing
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end user flow testing

### Backend Testing
- **Unit Tests**: Individual function testing
- **Integration Tests**: API endpoint testing
- **Load Tests**: Performance and scalability testing

### Test Coverage
- Frontend: 85%+ code coverage
- Backend: 90%+ code coverage

## 📊 Performance

### Key Metrics
- **App Launch Time**: < 3 seconds
- **API Response Time**: < 500ms average
- **Memory Usage**: < 100MB typical
- **Battery Impact**: Optimized for mobile devices

### Optimization Features
- **Image Caching**: Efficient image loading and storage
- **Data Persistence**: Local storage for offline functionality
- **Lazy Loading**: On-demand content loading
- **Background Processing**: Non-blocking operations

## 🔒 Security

### Authentication & Authorization
- **JWT Tokens**: Secure API authentication
- **Role-based Access**: Different permission levels
- **Session Management**: Automatic token refresh
- **Secure Storage**: Encrypted local data storage

### Data Protection
- **HTTPS**: All API communications encrypted
- **Input Validation**: Server-side data validation
- **SQL Injection Protection**: Parameterized queries
- **XSS Prevention**: Output sanitization

## 🌍 Localization

### Supported Languages
- **Arabic**: Complete RTL support
- **English**: Default language

### Adding New Languages
1. Create new `.arb` file in `frontend/lib/l10n/`
2. Add translations for all keys
3. Update `pubspec.yaml` with new locale
4. Generate localization files: `flutter gen-l10n`

## 📈 Analytics & Monitoring

### Business Analytics
- **Order Metrics**: Volume, value, and trends
- **Product Performance**: Best-selling items
- **Customer Insights**: Ordering patterns
- **Revenue Tracking**: Daily, weekly, monthly reports

### Technical Monitoring
- **Error Tracking**: Crash reports and error logs
- **Performance Monitoring**: API response times
- **Usage Analytics**: Feature adoption metrics
- **Health Checks**: System status monitoring

## 🚀 Deployment

### Production Deployment

#### Frontend (Mobile Apps)
```bash
# iOS App Store
flutter build ios --release
# Upload to App Store Connect

# Google Play Store
flutter build appbundle --release
# Upload to Google Play Console

# Web Deployment
flutter build web --release
# Deploy to hosting service
```

#### Backend (AWS)
```bash
# Production deployment
npm run deploy:prod

# Database migrations
npm run migrate:prod

# Environment setup
npm run setup:prod
```

### Continuous Integration
- **GitHub Actions**: Automated testing and deployment
- **Quality Checks**: Code linting and formatting
- **Security Scans**: Dependency vulnerability checks
- **Performance Tests**: Automated performance monitoring

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `flutter test` & `npm test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Standards
- **Dart**: Follow official Dart style guide
- **JavaScript**: ESLint configuration
- **Commit Messages**: Conventional commit format
- **Documentation**: Update README for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

### Getting Help
- **Documentation**: Check this README and inline code comments
- **Issues**: Create GitHub issues for bugs and feature requests
- **Discussions**: Use GitHub Discussions for questions

### Contact Information
- **Developer**: Ghayth Al-Jarad
- **Repository**: [https://github.com/ghaythalijarad/wizzbussiness](https://github.com/ghaythalijarad/wizzbussiness)

## 🗺️ Roadmap

### Upcoming Features
- [ ] Multi-location business support
- [ ] Advanced reporting and analytics
- [ ] Voice ordering integration
- [ ] AI-powered business insights
- [ ] Enhanced POS integrations
- [ ] Customer loyalty programs
- [ ] Inventory management system
- [ ] Staff management tools

### Version History
- **v1.0.0**: Initial release with core features
- **v1.1.0**: Auto-login implementation
- **v1.2.0**: Enhanced product management
- **v1.3.0**: POS integrations
- **v1.4.0**: Advanced analytics (Current)

---

**Built with ❤️ using Flutter and AWS**
