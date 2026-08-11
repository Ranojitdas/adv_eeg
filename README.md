# EEG Android Application

A comprehensive mobile application for EEG (Electroencephalogram) monitoring and analysis, built with Flutter and integrated with a custom backend API.

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [Features](#features)
- [Technical Stack](#technical-stack)
- [Backend Integration](#backend-integration)
- [Authentication System](#authentication-system)
- [User Roles](#user-roles)
- [File Structure](#file-structure)
- [Setup and Installation](#setup-and-installation)
- [API Documentation](#api-documentation)
- [Contributing](#contributing)

## Overview

This application is designed to facilitate EEG monitoring and analysis for medical professionals, patients, and their relatives. It provides a comprehensive platform for managing patient data, monitoring brain activity, and facilitating communication between different stakeholders in the healthcare process.

## Project Structure

```
lib/
├── Constants/
│   └── constants.dart         # API endpoints and configuration
├── controllers/
│   └── auth/
│       └── login_controller.dart  # Authentication logic
├── models/
│   ├── auth/
│   │   └── loginModel.dart    # Authentication data models
│   ├── patients/             # Patient-related models
│   ├── doctor_model.dart     # Doctor data model
│   ├── profile_model.dart    # User profile model
│   └── brainScoreModel.dart  # EEG score model
├── screens/
│   ├── adminScreens/        # Admin interface
│   ├── auth/                # Authentication screens
│   ├── doctorScreens/       # Doctor interface
│   ├── patientScreens/      # Patient interface
│   └── relativeScreens/     # Relative interface
└── utils/
    └── notifications/       # Notification handling
```

## Features

### 1. Authentication System
- Multi-role user authentication (Admin, Doctor, Patient, Relative)
- JWT token-based authentication with Railway backend integration
- OTP verification system for secure registration
- Secure password handling and validation
- Session management with automatic token refresh
- Role-based access control with comprehensive permissions

### 2. Enhanced Patient Management
- Comprehensive patient profiles with location tracking
- Medical history tracking with detailed records
- Family history documentation and relationship mapping
- Treatment progress monitoring with visual charts
- EEG data visualization with interactive graphs
- Depression status tracking and prioritization
- Real-time patient location monitoring for emergency situations

### 3. Advanced Doctor Interface
- Enhanced patient list management with depression-based sorting
- Medical record access with comprehensive data views
- Treatment planning with assignment capabilities
- Patient progress tracking with detailed analytics
- EEG analysis tools with chart filtering (Weekly/Monthly/Yearly)
- Interactive patient location maps with Google Maps integration
- Professional PDF report generation for patient data
- Real-time notifications for patient status updates

### 4. Comprehensive Relative Interface
- Patient monitoring with real-time location tracking
- Progress tracking with visual charts and analytics
- Communication with doctors through notification system
- Medical history access with detailed timeline views
- Treatment updates with real-time synchronization
- Interactive maps showing patient location with OpenStreetMap
- Google Maps integration for navigation to patient location

### 5. Admin Dashboard
- User management with role-based controls
- System monitoring with comprehensive analytics
- Data analytics with visual reporting
- Access control with permission management
- System configuration and maintenance tools

### 6. Advanced EEG Features
- Real-time EEG monitoring with TensorFlow Lite integration
- Brain score calculation with ML prediction services
- Interactive data visualization with Syncfusion charts
- Historical data analysis with time period filtering
- Professional PDF report generation with charts and graphs
- Background notification system for score updates
- MongoDB integration for secure data storage

### 7. Enhanced Notification System
- Firebase Cloud Messaging integration with background processing
- Real-time updates for patient status changes
- Custom notification handling with read/unread status
- Background message processing with Workmanager
- Platform-specific notifications with local storage
- Debug mode controls for production environments

### 8. Location Tracking & Maps
- Real-time GPS location tracking for patients
- Interactive maps with OpenStreetMap integration
- Google Maps integration with direct navigation
- Location permission handling with user consent
- Geographic address resolution and display
- Emergency location sharing capabilities
- Privacy-focused location handling with secure storage

### 9. UI/UX Enhancements
- Modern gradient-based design with enhanced visual appeal
- Responsive layouts for all screen sizes
- Interactive chart filtering with time period selection
- Professional styling with Google Fonts integration
- Enhanced empty states with informative messages
- Improved loading states and error handling
- Consistent theming with brand colors throughout the app

## Technical Stack

### Frontend
- Flutter SDK (Latest stable version)
- GetX for reactive state management
- Material Design 3 with custom theming
- Custom UI components with gradient styling
- Responsive design for all screen sizes
- Google Fonts integration for typography
- Syncfusion Charts for data visualization
- Interactive maps with Flutter Map
- Professional PDF generation capabilities

### Backend Integration
- RESTful API architecture
- JWT authentication
- HTTP package for API calls
- JSON serialization
- Error handling

### Data Storage
- GetStorage for local storage and preferences
- Secure JWT token management with automatic refresh
- Session persistence with timestamp validation
- User preferences and settings storage
- Comprehensive cache management for offline support
- MongoDB integration via Railway backend
- Real-time data synchronization
- Location data storage with privacy controls

### Additional Features
- Firebase integration with Cloud Messaging
- Push notifications with background processing
- Offline mode support with local caching
- Data synchronization with Railway backend
- Comprehensive error logging and handling
- PDF report generation with Syncfusion
- Interactive maps with Flutter Map
- Location services with Geolocator
- Chart visualization with time period filtering
- Google Maps integration for navigation
- Background task management with Workmanager
- Professional UI design with gradient styling

## Backend Integration

### API Endpoints
- Base URL: `https://eeg-node-backend-production.up.railway.app/api/v1`
- Prediction Service: `http://65.2.70.71:8080/`
- Authentication: JWT-based with automatic token refresh
- Real-time data processing with comprehensive error handling

### Authentication Flow
1. User login with credentials
2. Server validates and returns JWT token
3. Token stored locally using GetStorage
4. Token used for subsequent API calls
5. Session management with timestamp checking

### Data Models

#### User Model
```dart
class User {
    String? uid;
    String? username;
    String? email;
    String? name;
    String? role;
    // ... additional fields
}
```

#### Login Model
```dart
class Login {
    String? message;
    User? user;
    String? token;
}
```

## User Roles

### 1. Admin
- System management
- User management
- Access control
- Data analytics
- System configuration

### 2. Doctor
- Patient management
- Medical records
- Treatment planning
- EEG analysis
- Patient communication

### 3. Patient
- Personal health tracking
- Treatment progress
- Medical history
- Communication with doctors
- EEG data access

### 4. Relative
- Patient monitoring
- Progress tracking
- Doctor communication
- Medical updates
- Treatment information

## File Structure Details

### Authentication
- `lib/screens/auth/emailLogin.dart`: Email-based login screen
- `lib/screens/auth/signUpPage.dart`: User registration
- `lib/controllers/auth/login_controller.dart`: Authentication logic

### Models
- `lib/models/auth/loginModel.dart`: Authentication data structure
- `lib/models/doctor_model.dart`: Doctor data structure
- `lib/models/profile_model.dart`: User profile data
- `lib/models/brainScoreModel.dart`: EEG score data

### Screens
- `lib/screens/landing.dart`: Application landing page
- `lib/screens/adminScreens/`: Admin interface screens
- `lib/screens/doctorScreens/`: Doctor interface screens
- `lib/screens/patientScreens/`: Patient interface screens
- `lib/screens/relativeScreens/`: Relative interface screens

### Utils
- `lib/utils/notifications/`: Notification handling utilities
- `lib/Constants/constants.dart`: Application constants

## Setup and Installation

1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Configure Firebase:
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
4. Update API endpoints in `lib/Constants/constants.dart`
5. Run the application:
   ```bash
   flutter run
   ```

## API Documentation

### Authentication Endpoints
- POST `/login/`: User authentication
- POST `/devices/`: Device registration for notifications

### User Management
- GET `/users/`: Get user list
- POST `/users/`: Create new user
- PUT `/users/{id}`: Update user
- DELETE `/users/{id}`: Delete user

### Patient Management
- GET `/patients/`: Get patient list
- POST `/patients/`: Create patient record
- PUT `/patients/{id}`: Update patient record
- GET `/patients/{id}/eeg`: Get patient EEG data

### EEG Data
- GET `/brain-signal-score/{patientId}`: Get patient brain scores
- POST `/brain-signal/store`: Store EEG analysis results
- GET `/eeg/history`: Get historical EEG data
- Integration with ML prediction service for real-time analysis

### Location Services
- GET `/users/{id}`: Get user location data
- PUT `/users/{id}`: Update user location
- Real-time location tracking with GPS integration

### Quiz Management
- POST `/quiz/self-initiate`: Start new quiz session
- POST `/quiz/submit`: Submit quiz responses
- GET `/quiz/history/{patientId}`: Get quiz history
- Support for HAM_D and BDI assessment types

### Notification Services
- GET `/notification/get-notifications`: Fetch user notifications
- POST `/notification/mark-read`: Mark notifications as read
- Real-time notification processing with Firebase integration

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is proprietary and confidential. All rights reserved.
