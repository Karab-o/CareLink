# alerta
A personal safety app.
## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# Personal Safety App

A comprehensive Flutter mobile application designed for personal safety and emergency situations. The app enables users to send emergency alerts to trusted contacts with location sharing, even when they don't have anyone they fully trust.

## Features

### 🚨 Emergency Alert System
- **Prominent Panic Button**: Large, accessible emergency button on the home screen
- **Multiple Alert Types**: General emergency, medical, violence/assault, harassment, stalking, accident, fire, and natural disaster
- **Automatic Location Sharing**: GPS coordinates and address included in emergency alerts
- **Quick Emergency Response**: Streamlined process to send alerts in critical situations

### 👥 Trusted Contacts Management
- **Emergency Contacts**: Add and manage trusted contacts who will receive alerts
- **Contact Relationships**: Categorize contacts by relationship (family, friend, colleague, etc.)
- **Active/Inactive Toggle**: Enable or disable contacts without deleting them
- **Contact Verification**: Test emergency system with selected contacts

### 📍 Location Services
- **High-Accuracy GPS**: Precise location tracking for emergency situations
- **Address Resolution**: Reverse geocoding to provide readable addresses
- **Location Permissions**: Proper handling of location permissions and privacy
- **Maps Integration**: Generate shareable maps links for emergency responders

### 📱 Smart Notifications
- **SMS Integration**: Send emergency messages via SMS to all active contacts
- **Phone Call Integration**: Option to automatically call emergency services
- **Push Notifications**: In-app notifications for alert status updates
- **Customizable Alerts**: Configure sound, vibration, and notification preferences

### 🔒 Security & Privacy
- **PIN Protection**: Optional PIN lock for app access
- **Biometric Authentication**: Fingerprint and face unlock support
- **Stealth Mode**: Hide app from recent apps list for privacy
- **Auto-Lock**: Automatic app locking after specified time
- **Data Encryption**: Secure storage of sensitive information

### 📊 Alert History & Tracking
- **Complete Alert Log**: Track all sent emergency alerts with timestamps
- **Status Tracking**: Monitor alert delivery and acknowledgment status
- **Search & Filter**: Find specific alerts by type, date, or status
- **Detailed Reports**: View comprehensive alert details including location and contacts notified

### ⚙️ Customizable Settings
- **User Profile**: Manage personal information and emergency medical details
- **Notification Preferences**: Configure alert sounds, vibration, and timing
- **Emergency Settings**: Set alert delays, auto-police contact, and location sharing
- **Data Management**: Export data, reset settings, and clear all information

## Technical Architecture

### 🏗️ Project Structure
```
lib/
├── constants/          # App-wide constants (colors, dimensions, text styles)
├── models/            # Data models (User, Contact, Alert, etc.)
├── providers/         # State management with Provider pattern
├── screens/           # UI screens and pages
├── services/          # Business logic and external integrations
├── utils/             # Utility functions and helpers
└── widgets/           # Reusable UI components
```

### 🎨 Design System
- **Color Palette**: Emergency-focused colors with high contrast for accessibility
- **Typography**: Inter font family for excellent readability
- **Spacing**: Consistent spacing system using predefined dimensions
- **Components**: Reusable widgets following Material Design 3 principles
- **Accessibility**: Large touch targets, screen reader support, and high contrast

### 🔧 State Management
- **Provider Pattern**: Centralized state management for app data
- **Local Storage**: SharedPreferences for persistent data storage
- **Real-time Updates**: Reactive UI updates based on state changes
- **Error Handling**: Comprehensive error handling and user feedback

### 📦 Key Dependencies
- `provider`: State management
- `shared_preferences`: Local data storage
- `geolocator`: Location services
- `permission_handler`: Runtime permissions
- `url_launcher`: Phone calls and SMS
- `local_auth`: Biometric authentication
- `intl`: Date formatting and internationalization

## Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- iOS 11.0+ / Android API 21+

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Configuration
1. **Permissions**: The app requests location, phone, and contacts permissions
2. **Location Services**: Enable GPS for accurate location sharing
3. **Emergency Contacts**: Add at least 2-3 trusted contacts for optimal coverage
4. **Test System**: Use the test feature to verify alert delivery

## Usage Guide

### Initial Setup
1. **Onboarding**: Complete the guided setup process
2. **Profile Creation**: Enter your personal information and medical details
3. **Add Contacts**: Add emergency contacts with phone numbers and relationships
4. **Configure Settings**: Set preferences for alerts, notifications, and security
5. **Test System**: Send a test alert to verify everything works

### Emergency Situations
1. **Quick Alert**: Tap the large SOS button on the home screen
2. **Select Alert Type**: Choose the appropriate emergency type
3. **Automatic Processing**: The app will:
   - Get your current location
   - Send SMS to all active contacts
   - Include location and emergency details
   - Log the alert for future reference

### Managing Contacts
- **Add Contacts**: Use the + button to add new emergency contacts
- **Edit Information**: Update contact details and relationships
- **Toggle Active Status**: Enable/disable contacts without deleting
- **Test Contacts**: Send test messages to verify contact information

### Viewing Alert History
- **Complete Log**: View all sent alerts with status information
- **Filter & Search**: Find specific alerts by type or date
- **Detailed View**: See full alert information including location and contacts
- **Export Data**: Backup your alert history and settings

## Security Considerations

### Privacy Protection
- **Local Storage**: All data stored locally on device
- **No Cloud Sync**: No automatic cloud backup of sensitive information
- **Permission Control**: Granular control over app permissions
- **Data Encryption**: Sensitive data encrypted at rest

### Emergency Access
- **Quick Access**: Minimal steps to send emergency alerts
- **Offline Capability**: Core features work without internet connection
- **Battery Optimization**: Efficient location services to preserve battery
- **Reliability**: Robust error handling for critical situations

## Customization

### Color Scheme
The app uses an emergency-focused color palette:
- **Emergency Red**: Primary action color for alerts
- **Safe Green**: Confirmation and success states
- **Warning Orange**: Caution and setup reminders
- **Neutral Grays**: Text and background elements

### Typography
- **Font Family**: Inter for excellent readability
- **Size Scale**: Responsive text sizing for accessibility
- **Weight Hierarchy**: Clear information hierarchy
- **High Contrast**: Optimized for emergency readability

### Layout
- **Large Touch Targets**: Minimum 44pt touch targets for accessibility
- **Emergency Button**: 200pt diameter for easy access
- **Consistent Spacing**: 8pt grid system for visual harmony
- **Responsive Design**: Adapts to different screen sizes

## Contributing

This is a demo project showcasing Flutter development best practices for emergency applications. Key areas for enhancement:

1. **Backend Integration**: Connect to emergency services APIs
2. **Real-time Tracking**: Continuous location sharing during emergencies
3. **Multi-language Support**: Internationalization for global use
4. **Advanced Security**: Enhanced encryption and authentication
5. **Wearable Integration**: Apple Watch and Android Wear support

## License

This project is created for demonstration purposes. Please ensure compliance with local emergency services regulations before deploying in production.

## Disclaimer

This app is designed to supplement, not replace, official emergency services. Always contact local emergency services (911, 112, etc.) for immediate assistance in life-threatening situations.

---

**Emergency Contacts**: Always keep your emergency contacts up to date and test the system regularly to ensure it works when you need it most.