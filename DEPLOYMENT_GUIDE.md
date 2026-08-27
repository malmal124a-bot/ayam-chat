# Complete Deployment Guide

## Step 1: Setup Admin User in Firestore

### Option A: Using the Setup Script (Recommended)
1. Download Firebase service account key:
   - Go to Firebase Console > Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save as `service-account-key.json` in project root

2. Install dependencies:
```bash
npm install firebase-admin
```

3. Run the setup script:
```bash
node setup_admin.js
```

### Option B: Manual Setup via Firebase Console
1. Go to Firebase Console > Authentication
2. Create user with email: `admin@ayam-chat.com` and set a password
3. Note the User UID from the Authentication tab
4. Go to Firestore Database
5. Create document in `users` collection with ID = User UID
6. Add these fields:
```json
{
  "id": "USER_UID_FROM_AUTH",
  "name": "Admin",
  "email": "admin@ayam-chat.com",
  "role": "owner",
  "permissions": [
    "all",
    "manage_users",
    "manage_rooms",
    "manage_agencies",
    "manage_store",
    "manage_banners",
    "manage_moderation",
    "manage_financial",
    "view_analytics",
    "system_config"
  ],
  "isOnline": false,
  "level": 999,
  "currentXP": 0,
  "vipLevel": 7,
  "svipLevel": 10,
  "wealthLevel": 10,
  "magicLevel": 10,
  "nobleLevel": 10,
  "wallet": {
    "balance": 999999999
  }
}
```

## Step 2: Deploy Firestore Rules

Since PowerShell script execution is disabled, you'll need to:

1. Open PowerShell as Administrator
2. Enable script execution temporarily:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```

3. Deploy Firestore rules:
```bash
firebase deploy --only firestore:rules
```

Or use Firebase Console:
1. Go to Firebase Console > Firestore Database > Rules
2. Copy contents of `firestore.rules` file
3. Paste and publish

## Step 3: Deploy Admin Panel to Firebase Hosting

### Option A: Using Firebase CLI
```bash
firebase deploy --only hosting
```

### Option B: Manual Deployment
1. Go to Firebase Console > Hosting
2. Click "Add site" or select existing site
3. Upload contents of `build/web` folder
4. Configure rewrites in Firebase Console to match firebase.json

## Step 4: Verify Deployment

### Test Admin Panel
1. Open your Firebase Hosting URL
2. Try to login with `admin@ayam-chat.com`
3. Should successfully access the admin dashboard

### Test Mobile App
1. Install the APK from: `build/app/outputs/flutter-apk/app-release.apk`
2. Launch the app
3. Should load without white screen issues
4. Test user registration and login flow

## Step 5: Configure Firebase Indexes

Deploy indexes for optimal query performance:
```bash
firebase deploy --only firestore:indexes
```

Or manually create indexes in Firebase Console > Firestore Database > Indexes using `firestore.indexes.json`

## Troubleshooting

### Login Issues
- **Error: "User not found"**: Ensure admin document exists in `users` collection with correct Auth UID
- **Error: "Access denied"**: Verify role field is set to "owner" in the user document
- **Error: "Permission denied"**: Check firestore.rules are deployed correctly

### White Screen Issues
- **Web**: Check browser console for errors, ensure Firebase config is correct
- **Mobile**: Verify `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist` are present

### Build Issues
- **Dependencies**: Run `flutter pub get` before building
- **Firebase**: Ensure all Firebase config files are in place
- **Permissions**: Check Android/iOS permissions in respective config files

## File Locations

- **APK**: `build/app/outputs/flutter-apk/app-release.apk`
- **Web Build**: `build/web/`
- **Firestore Rules**: `firestore.rules`
- **Firestore Indexes**: `firestore.indexes.json`
- **Firebase Config**: `firebase.json`
- **Admin Setup Script**: `setup_admin.js`

## Security Notes

1. **Never commit** `service-account-key.json` to version control
2. **Add** `service-account-key.json` to `.gitignore`
3. **Use environment variables** for sensitive data in production
4. **Enable App Check** for additional security
5. **Review** firestore.rules regularly for security updates

## Post-Deployment Checklist

- [ ] Admin user can login successfully
- [ ] Admin dashboard loads without errors
- [ ] Firestore rules are active and working
- [ ] Mobile app launches without white screen
- [ ] User registration/login works in mobile app
- [ ] All Firebase services are connected
- [ ] Indexes are deployed for optimal performance
- [ ] Error monitoring is set up (Firebase Crashlytics)
