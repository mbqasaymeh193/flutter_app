# HealthCare Flutter App

A comprehensive healthcare mobile application built with Flutter featuring multiple screens and functionalities.

## Features

### 🔐 Authentication
- **Login Screen**: Secure login with email and password
- **Sign Up Screen**: User registration with validation
- **Splash Screen**: Animated splash screen with app logo

### 🏠 Main Features
- **Home Screen**: 
  - Search functionality for doctors and specialties
  - Browse medical specialties (General, Cardiology, Pediatrics, etc.)
  - View top-rated doctors with ratings and experience
  - Bottom navigation for easy access
  - Drawer menu for quick navigation

### 👤 User Profile
- **Profile Screen**:
  - Personal information display
  - Medical information (blood type, height, weight, allergies)
  - Statistics (appointments, reports, reviews)
  - Edit profile functionality

### ⚙️ Settings
- **Settings Screen**:
  - Account settings (edit profile, change password)
  - Notification preferences (push, email, SMS)
  - Appearance settings (dark mode, language)
  - Privacy & security options
  - Payment methods management
  - Help center and support

### 💳 Payment
- **Payment Screen**:
  - Multiple payment methods (Credit/Debit Card, PayPal, Apple Pay, Google Pay, Cash)
  - Saved cards management
  - Add new payment method
  - Payment summary with breakdown
  - Secure payment processing

### 👨‍💼 Admin Panel
- **Admin Screen**:
  - Dashboard with statistics
  - User management
  - Doctor management
  - Appointments overview
  - Payment tracking
  - Recent activity monitoring

## Screenshots

The app includes the following screens:
1. Splash Screen
2. Login Screen
3. Sign Up Screen
4. Home Screen
5. Profile Screen
6. Settings Screen
7. Payment Screen
8. Admin Panel

## Technical Details

### Dependencies
- `flutter`: SDK
- `google_fonts`: Custom fonts
- `flutter_rating_bar`: Star ratings display
- `font_awesome_flutter`: Icon library
- `provider`: State management
- `shared_preferences`: Local storage

### Project Structure
```
lib/
├── main.dart
├── models/
│   └── doctor.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── settings_screen.dart
│   ├── payment_screen.dart
│   └── admin_screen.dart
├── widgets/
├── utils/
└── services/
```

## Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Requirements

- Flutter SDK: >=3.0.0 <4.0.0
- Dart: >=3.0.0
- Android Studio / VS Code with Flutter extensions

## Features Highlights

### 🎨 UI/UX
- Modern and clean design
- Smooth animations and transitions
- Responsive layout
- Material Design components
- Gradient backgrounds
- Custom cards and widgets

### 🔒 Security
- Password validation
- Secure authentication flow
- Protected admin panel
- Privacy settings

### 📱 Navigation
- Bottom navigation bar
- Drawer menu
- Route-based navigation
- Back button handling

### 💡 User Experience
- Search functionality
- Filter by specialty
- Doctor ratings and reviews
- Appointment booking
- Payment processing
- Notifications management

## Future Enhancements

- Real-time chat with doctors
- Video consultation
- Prescription management
- Medical records storage
- Push notifications
- Multi-language support
- Dark mode theme
- API integration
- Database connectivity

## License

This project is created for educational purposes.

## Contact

For any queries or support, please contact the development team.

---

**Note**: This is a UI/UX prototype. Backend integration and API connections need to be implemented for production use.
