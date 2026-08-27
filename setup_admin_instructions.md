# Admin Document Setup Instructions

## Prerequisites
1. Download Firebase service account key from Firebase Console:
   - Go to Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Save as `service-account-key.json` in project root

## Option 1: Using Node.js Script (Recommended)
```bash
# Install dependencies
npm install firebase-admin

# Run the setup script
node setup_admin.js
```

## Option 2: Manual Setup via Firebase Console
1. Go to Firebase Console > Authentication
2. Create user with email: `admin@ayam-chat.com`
3. Note the User UID from the Authentication tab
4. Go to Firestore Database
5. Create document in `users` collection with ID = User UID
6. Add the following fields:
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

## Verification
After setup, verify the admin can login by:
1. Opening the admin panel
2. Entering email: `admin@ayam-chat.com`
3. Entering the password you set
4. Should successfully login and show dashboard
