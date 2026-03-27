# Staff Portal Navigation System

## Overview
Complete bottom navigation bar with 5 main screens for the Staff Portal app.

## Navigation Structure

### Bottom Navigation Bar (5 Tabs)
1. **Home** - Dashboard with quick actions and recent activities
2. **Requests** - View and manage leave, overtime, training, and equipment requests
3. **Attendance** - Check-in/out, monthly summary, and attendance history
4. **Community** - Social feed for staff communication and updates
5. **Profile** - User profile with personal info, employment details, and documents

## Screens

### 1. Home Tab (`lib/view/home/home_tab.dart`)
Features:
- Welcome card with user avatar and name
- Quick action cards (Attendance, Tasks, Leave, Payroll)
- Recent activities feed
- Notification icon in app bar

### 2. Requests Screen (`lib/view/requests/requests_screen.dart`)
Features:
- List of all requests with status badges (Pending, Approved, Rejected)
- Request types: Leave, Overtime, Training, Equipment
- Filter button in app bar
- Floating action button to create new requests
- Bottom sheet for selecting request type

### 3. Attendance Screen (`lib/view/attendance/attendance_screen.dart`)
Features:
- Today's status card with check-in/out times
- Monthly summary cards (Present, Absent, Late, Leave)
- Recent attendance history with status indicators
- Color-coded status (Green: Present, Orange: Late, Red: Absent)

### 4. Community Screen (`lib/view/community/community_screen.dart`)
Features:
- Social feed with posts from staff members
- Like, comment, and share functionality
- Search icon in app bar
- Floating action button to create new posts
- Bottom sheet for creating posts

### 5. Profile Screen (`lib/view/profile/profile_screen.dart`)
Features:
- Profile header with avatar, name, position, and status badge
- Personal Information section (Name, Employee ID, Gender, Phone, Email)
- Employment Information section (Cadre, Department, Facility)
- Documents section (Employment Letter, Professional License, Training Certificates)
- Edit Profile button in app bar
- Logout button at bottom

## Main Navigation Component

### `lib/view/main_navigation.dart`
- Manages bottom navigation state
- Switches between 5 main screens
- Custom styled bottom navigation bar with icons
- Active/inactive states for navigation items

## Color Scheme
- Primary: Green (#43A047)
- Background: Grey[50]
- Cards: White with grey borders
- Status Colors:
  - Green: Success/Present/Approved
  - Orange: Pending/Late
  - Red: Rejected/Absent
  - Blue: Info
  - Purple: Special actions

## Navigation Icons
- Home: `home_outlined` / `home`
- Requests: `grid_view_outlined` / `grid_view`
- Attendance: `calendar_today_outlined` / `calendar_today`
- Community: `people_outline` / `people`
- Profile: `person_outline` / `person`

## Usage

### Running the App
After login, users are automatically navigated to the MainNavigation component which displays the Home tab by default.

### Navigation Flow
```
Splash Screen
    ↓
Login Screen
    ↓
Main Navigation (Home Tab)
    ├── Home Tab
    ├── Requests Screen
    ├── Attendance Screen
    ├── Community Screen
    └── Profile Screen
```

### Adding New Screens
1. Create screen file in appropriate folder under `lib/view/`
2. Add screen to `_screens` list in `MainNavigation`
3. Add corresponding `BottomNavigationBarItem`
4. Update navigation logic if needed

## Profile Features

### Edit Profile (`lib/view/profile/edit_profile_screen.dart`)
- Avatar upload functionality
- Phone number editing
- Email editing
- Save changes button

### Documents
- View employment documents
- PDF icon with file size
- Tap to view/download

### Logout
- Clears user session
- Redirects to login screen
- Confirmation dialog (recommended to add)

## Next Steps
- Implement actual API calls for each screen
- Add pull-to-refresh functionality
- Implement document viewer
- Add request creation forms
- Implement community post creation
- Add attendance check-in/out functionality
- Implement search in community
- Add filters for requests
- Implement edit profile functionality
- Add push notifications
