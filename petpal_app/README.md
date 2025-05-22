# PetPal

A comprehensive pet diary and management application with cloud synchronization.

## Features Implemented

### Core Architecture
- Flutter-based cross-platform mobile app
- Supabase backend for real-time data synchronization
- Offline-first architecture with local storage using Isar
- Riverpod for state management
- Modular, feature-based code organization

### Authentication
- Social sign-in (Google, Apple)
- Email/password authentication
- Role-based access control
- Multi-user household management

### Pet Profiles
- Detailed pet information storage
- Pet type classification (dog, cat, etc.)
- Photo gallery and avatar management
- Medical information tracking
- Weight history

### Journal
- Comprehensive pet diary entries
- Multiple entry types:
  - Food tracking
  - Activity logging
  - Health observations
  - Mood monitoring
  - General notes
- Photo attachments
- Filtering and search capabilities

### Reminders
- Medication reminders
- Feeding schedules
- Vet appointments
- Recurring reminders (daily, weekly, monthly)
- Push notifications
- Assignment to household members
- Completion tracking

### UI/UX
- Consistent design system
- Dark and light theme support
- Floating bottom navigation
- Quick action buttons
- Responsive layouts
- Accessibility considerations

## In Progress

### Health Analytics
- Weight trend visualization
- Activity pattern analysis
- Health metrics dashboard
- AI-powered health insights
- Exportable health reports

### Lost Mode
- GPS location tracking
- Alert system for missing pets
- Nearby user notifications
- QR code generation for pet tags

### In-App Store
- Pet supplies e-commerce
- AI-based product recommendations
- Subscription management

## Database Schema

The app uses a combination of local Isar database and Supabase PostgreSQL database with the following collections:

- Users
- Households
- Pets
- Journal Entries
- Reminders
- Medications
- Health Records
- Media

## Getting Started

1. Clone the repository
2. Set up your Supabase project
3. Update `lib/config/app_config.dart` with your Supabase credentials
4. Run `flutter pub get`
5. Run `flutter pub run build_runner build` to generate required files
6. Run the app using `flutter run`

## Development Notes

### Project Structure

```
lib/
├── app.dart              # App entry point
├── config/               # App configurations
├── core/                 # Core utilities and services
│   ├── constants/        # App-wide constants
│   ├── models/           # Core data models
│   ├── providers/        # Core state providers
│   └── services/         # Services like API and storage
├── features/             # Feature modules
│   ├── auth/             # Authentication
│   ├── pets/             # Pet profiles
│   ├── journal/          # Daily journal
│   ├── reminders/        # Care reminders
│   ├── analytics/        # Health analytics
│   └── settings/         # App settings
└── widgets/              # Shared widgets
```

### State Management

- Using Riverpod for state management
- AsyncValue for handling loading, error, and success states
- Repository pattern for data access

### Offline Support

- Local-first data strategy using Isar database
- Queue-based synchronization
- Conflict resolution strategies

### Cloud Integration

- Real-time data using Supabase Realtime
- Storage for media files
- Authentication services

## Future Enhancements

- Wearable device integration
- Advanced AI health predictions
- Social features for pet owners
- Gamification elements
- Multi-language support