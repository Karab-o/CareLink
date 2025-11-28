# CareLink App

CareLink is a web safety application that enables users to instantly send emergency alerts to their loved ones when in danger. Built with Flutter for cross-platform compatibility and powered by a robust Node.js backend, CareLink ensures help is just a tap away.

## 📱 Overview

CareLink provides a quick and reliable way to alert trusted contacts during emergencies. Whether you're walking alone at night, feeling unsafe, or facing a medical emergency, CareLink connects you with your support network instantly.

## ✨ Features

- **Emergency Alert System**: Send instant alerts to multiple emergency contacts with a single tap
- **SMS Notifications**: Real-time SMS alerts via Twilio integration
- **Email Notifications**: Email alerts to emergency contacts using SendGrid
- **Firebase Authentication**: Secure user authentication and account management
- **Emergency Contacts Management**: Add, edit, and organize your trusted contacts
- **Location Sharing**: Share your real-time location with alerts (if enabled)
- **Alert History**: Track all sent alerts and responses
- **Cross-Platform**: Available on both iOS and Android

## 🏗️ Architecture

### Frontend
- **Framework**: Flutter
- **Language**: Dart
- **Authentication**: Firebase Auth

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js 
- **Database**: MongoDB
- **Authentication**: Firebase Admin SDK
- **SMS Service**: Twilio
- **Email Service**: SendGrid

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Node.js (16.x or higher)
- MongoDB (4.4 or higher)
- Firebase account
- Twilio account
- SendGrid account
- ngrok (for public URL during development/testing)

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.karab-o/carelink.git
cd carelink
```

#### 2. Backend Setup

```bash
cd backend
npm install
```

Create a `.env` file in the backend directory:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/sentinel_db

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email

# Twilio
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=your-twilio-number

# SendGrid
SENDGRID_API_KEY=your-sendgrid-api-key
SENDGRID_FROM_EMAIL=noreply@carelink.com
```

Start the backend server:

```bash
npm start
```

#### 3. Flutter App Setup

```bash
cd ../app
flutter pub get
```

Configure Firebase:
- Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Place them in their respective directories

Create a config file for API endpoints:

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
}
```

Run the app:

```bash
flutter run
```

#### 4. Setting Up ngrok for Public URL (Development/Testing)

ngrok is used to expose your local backend server to the internet, which is necessary for:
- Testing on physical devices
- Twilio webhook callbacks
- Testing with team members

Install ngrok:
```bash
# macOS
brew install ngrok

# Windows/Linux - download from https://ngrok.com/download
```

Start ngrok tunnel:
```bash
ngrok http 3000
```

You'll see output like:
```
Forwarding   https://abc123.ngrok.io -> http://localhost:3000
```

Update your Flutter app's API configuration with the ngrok URL:
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://abc123.ngrok.io/api';
}
```

**⚠️ Important Notes about ngrok:**
- The free tier URL changes every time you restart ngrok
- Your local server must be running for ngrok to work
- This is for **development/testing only**, not production deployment
- For production, deploy to proper hosting services (see Deployment section below)

## 📂 Project Structure

```
carelink/
├── .vscode/                      # VSCode workspace settings
├── alerta/                       # Flutter mobile application
│   ├── lib/
│   │   ├── models/              # Data models
│   │   ├── screens/             # UI screens
│   │   ├── services/            # API and business logic
│   │   ├── widgets/             # Reusable widgets
│   │   ├── config/              # Configuration files
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── sentinel-backend/             # Node.js backend
│   ├── src/
│   │   ├── controllers/         # Route controllers
│   │   ├── models/              # MongoDB schemas
│   │   ├── routes/              # API routes
│   │   ├── middleware/          # Express middleware
│   │   ├── services/            # External services (Twilio, SendGrid)
│   │   └── utils/               # Helper functions
│   ├── .env
│   ├── package.json
│   └── server.js
│
├── node_modules/                 # Root dependencies
├── LICENSE                       # Project license
├── package.json                  # Root package configuration
├── package-lock.json
└── README.md                     # This file
```

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

### Emergency Contacts
- `GET /api/contacts` - Get all emergency contacts
- `POST /api/contacts` - Add emergency contact
- `PUT /api/contacts/:id` - Update contact
- `DELETE /api/contacts/:id` - Delete contact

### Alerts
- `POST /api/alerts/send` - Send emergency alert
- `GET /api/alerts/history` - Get alert history
- `GET /api/alerts/:id` - Get specific alert details

## 🔐 Security

- Firebase Authentication for secure user management
- JWT tokens for API authorization
- Environment variables for sensitive credentials
- HTTPS encryption for data transmission (via ngrok in development)
- Input validation and sanitization

## 🚀 Deployment

### Current Setup (Development)
The app currently uses **ngrok** to create a public URL for the local backend server. This is suitable for development and testing but **NOT for production**.

### Recommended Production Deployment

#### Backend Deployment Options:
1. **Heroku** - Easy deployment with free tier
2. **Railway** - Modern platform with great developer experience
3. **Render** - Simple deployment with auto-scaling
4. **DigitalOcean App Platform** - Affordable and reliable
5. **AWS/Google Cloud** - Enterprise-grade solutions

#### Database:
- **MongoDB Atlas** - Free tier available, cloud-hosted MongoDB

#### Steps for Production Deployment:
1. Choose a hosting platform for your Node.js backend
2. Set up MongoDB Atlas for your database
3. Configure environment variables on your hosting platform
4. Update your Flutter app's `baseUrl` to point to your deployed backend
5. Build and release your Flutter app to Google Play Store and Apple App Store

#### Example: Deploying to Render
```bash
# 1. Push your code to GitHub
# 2. Connect your GitHub repo to Render
# 3. Set environment variables in Render dashboard
# 4. Deploy automatically on git push
```

## 📱 Screenshots

<img width="1329" height="714" alt="image" src="https://github.com/user-attachments/assets/bf21720e-842f-48f8-954c-fd71d0772fb5" />


## 🛠️ Technologies Used

### Frontend
- Flutter
- Firebase Auth
- HTTP/Dio for API calls
- Provider/Riverpod for state management

### Backend
- Node.js
- Express.js
- MongoDB with Mongoose
- Twilio API
- SendGrid API
- Firebase Admin SDK
- ngrok (for development/testing)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Name** - [karab-o](https://github.com/karab-o)

## 🙏 Acknowledgments

- Firebase for authentication services
- Twilio for SMS capabilities
- SendGrid for email delivery
- MongoDB for database solutions
- Flutter community for excellent documentation

## 📞 Support

For support, email support@carelink.com or open an issue in the repository.

## 🗺️ Roadmap

- [ ] Add in-app chat feature
- [ ] Implement push notifications
- [ ] Add panic button widget
- [ ] Multi-language support
- [ ] Web dashboard for emergency contacts
- [ ] Integration with emergency services

---

**Note**: This app is designed to complement, not replace, official emergency services. Always call 911 or your local emergency number in life-threatening situations.
