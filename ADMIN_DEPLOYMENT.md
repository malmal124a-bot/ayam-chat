# Ayam Chat Admin Portal - Deployment Guide

## Overview
The Admin Portal is a standalone Flutter Web application that connects to the same Firebase project as the mobile app. It provides role-based access control for administrators to manage users, agencies, store items, banners, and moderation.

## Prerequisites
- Flutter SDK (3.13.0 or higher)
- Firebase project configured for the app
- Admin user account with appropriate role in Firestore

## Firebase Configuration
1. Ensure your Firebase project has the following collections:
   - `users` - with `role` field (super_admin, agency_admin, banner_admin, user)
   - `agencies` - for agency management
   - `agency_requests` - for pending agency applications
   - `store_items` - for store inventory
   - `banners` - for home screen banners
   - `rooms` - for voice room moderation
   - `reports` - for user reports

2. Set up Firebase Authentication with Email/Password provider enabled

3. Create at least one admin user in Firestore:
   ```javascript
   // In Firestore Console
   users/{userId} = {
     name: "Admin Name",
     email: "admin@yourdomain.com",
     role: "super_admin",
     permissions: ["all"],
     isOnline: false,
     // ... other user fields
   }
   ```

## Building for Web

### Standard Build
```bash
flutter build web --release
```

### Build with Custom Entry Point
```bash
flutter build web --release -t lib/admin_main.dart
```

### Build for Firebase Hosting
```bash
flutter build web --release -t lib/admin_main.dart --web-renderer canvaskit
```

## Deployment Options

### 1. Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase Hosting in the project
firebase init hosting

# Deploy
firebase deploy --only hosting
```

### 2. Vercel
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

### 3. Netlify
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Deploy
netlify deploy --prod
```

### 4. Custom Server
Build the web files and serve them using any web server (Nginx, Apache, etc.)

```bash
# After build, files are in build/web/
# Copy to your web server directory
```

## Environment Configuration

### Firebase Configuration
The admin portal uses the same `firebase_options.dart` file as the mobile app. Ensure it's properly configured for web.

### Allowed Admin Roles
The following roles have access to the admin portal:
- `super_admin` - Full access to all features
- `agency_admin` - Agency management only
- `banner_admin` - Store and banner management only

## Features

### 1. Dashboard
- Real-time metrics (total users, active rooms, system balance, transactions)
- Recent activity feed
- Quick navigation to all sections

### 2. User Management
- Search users by ID or name
- View user details and wallet balance
- Manual recharge/deduction with reason logging
- Transaction history tracking

### 3. Agency Management
- View pending agency applications
- Approve/reject applications with reasons
- Manage active agencies
- Toggle agency activation status

### 4. Store Management
- Add/edit/delete store items
- Manage home screen banners
- Toggle item/banner visibility
- Grid view for store items

### 5. Moderation Tools
- View active voice rooms
- Monitor room participants
- Mute/kick users from rooms
- Ban users with duration options
- Handle user reports

## Security Considerations

1. **Role-Based Access Control**: Only users with admin roles can access the portal
2. **Firebase Auth Persistence**: Admin sessions persist across browser refreshes
3. **Transaction Logging**: All wallet modifications are logged with admin ID and reason
4. **Audit Trail**: All administrative actions are recorded in Firestore

## Customization

### Branding
Update the following files to customize the admin portal:
- `web/admin_index.html` - Title, meta description
- `lib/admin_main.dart` - App title and theme colors
- `lib/admin/screens/admin_login_screen.dart` - Logo and branding

### Additional Roles
To add more admin roles, update:
1. `lib/models/user_model.dart` - Add new role to `UserRole` enum
2. `lib/admin/controllers/admin_auth_controller.dart` - Add to `_allowedAdminRoles` list

## Troubleshooting

### Login Issues
- Verify user has correct role in Firestore
- Check Firebase Auth is enabled
- Ensure email/password authentication is working

### Build Errors
- Run `flutter clean` before building
- Update Flutter SDK to latest version
- Check Firebase dependencies in `pubspec.yaml`

### Firebase Connection Issues
- Verify Firebase project configuration
- Check Firestore rules allow admin access
- Ensure Firebase SDK versions are compatible

## Performance Optimization

### Web Renderer
For better performance, use CanvasKit renderer:
```bash
flutter build web --release -t lib/admin_main.dart --web-renderer canvaskit
```

### Asset Optimization
- Compress images before uploading
- Use WebP format for images
- Enable CDN for static assets

## Support
For issues or questions, refer to:
- Flutter Web documentation: https://docs.flutter.dev/platform-integration/web
- Firebase documentation: https://firebase.google.com/docs
