# Staff Portal Authentication System

## Overview
Complete authentication system with login and registration functionality for the Staff Portal app.

## Features

### 1. Login Screen
- Email and password authentication
- Password visibility toggle
- Form validation
- Loading states
- Error handling with Flushbar notifications
- Navigation to registration

### 2. Registration Flow
- Multi-step registration process
- Personal information collection (name, email, phone, gender)
- Password confirmation
- Personal info verification (payroll + DOB)
- Complete account creation

### 3. API Integration
- Login: `POST /api/login`
- Get Personal Info: `POST /api/getPersonalInfo`
- Create Account: `POST /api/createAccount`

## Project Structure

```
lib/
├── data/
│   └── network/
│       └── api_service.dart          # API endpoints
├── model/
│   ├── user_model.dart               # User data model
│   └── registration_model.dart       # Registration data model
├── repository/
│   └── auth_repository.dart          # Auth business logic
├── view/
│   └── auth/
│       ├── login_screen.dart         # Login UI
│       ├── registration_screen.dart  # Registration UI
│       ├── verify_personal_info_screen.dart  # Verification step
│       └── splash_view.dart          # Splash with auth check
├── view_model/
│   └── auth_view_model.dart          # Auth state management
└── utils/
    └── validators.dart               # Form validators
```

## Usage

### Running the App
```bash
flutter pub get
flutter run
```

### Login Flow
1. App starts with splash screen
2. Checks if user is logged in
3. Redirects to login or home accordingly
4. User enters email and password
5. On success, navigates to home screen

### Registration Flow
1. User clicks "Register" on login screen
2. Fills personal information form
3. Clicks "Continue" to verification screen
4. Enters payroll number and date of birth
5. System verifies against API
6. On verification, completes registration
7. Redirects to login screen

## API Endpoints

### Login
```bash
POST https://hris-api.hezo.co.tz/api/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "string"
}
```

### Get Personal Info
```bash
POST https://hris-api.hezo.co.tz/api/getPersonalInfo
Content-Type: application/json

{
  "payroll": "string",
  "date_of_birth": "string"
}
```

### Create Account
```bash
POST https://hris-api.hezo.co.tz/api/createAccount
Content-Type: application/json

{
  "first_name": "string",
  "middle_name": "string",
  "last_name": "string",
  "location_id": "string",
  "gender": "string",
  "phone_no": "string",
  "date_of_birth": "string",
  "email": "string",
  "password": "string",
  "working_station_id": "string",
  "personal_information_id": "string",
  "path_id": "string"
}
```

## State Management
- Uses Provider for state management
- AuthViewModel handles all auth operations
- Persistent storage with SharedPreferences

## Validation
- Email format validation
- Password minimum length (6 characters)
- Required field validation
- Phone number validation
- Password confirmation matching

## Next Steps
- Add forgot password functionality
- Implement biometric authentication
- Add email verification
- Enhance error messages
- Add loading animations
