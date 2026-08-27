# Get Admin User UID - Quick Steps

## Option 1: Firebase Console (Recommended)

1. **Open Firebase Console Authentication**
   - Go to: https://console.firebase.google.com/project/ayam-chat/authentication/users

2. **Find the Admin User**
   - Look for user with email: `admin@ayam-chat.com`
   - If not found, click "Add user" and create it with any password

3. **Copy the User UID**
   - Click on the user row to open user details
   - Copy the "User UID" (looks like: `abc123xyz789...`)

4. **Run the Setup Script**
   ```bash
   node setup_admin.js <PASTE_UID_HERE>
   ```

## Option 2: Direct Firestore Import

If you prefer to skip the script and create the document directly:

1. **Get the UID** using steps above
2. **Go to Firestore Console**: https://console.firebase.google.com/project/ayam-chat/firestore/data/users
3. **Click "Add document"**
4. **Document ID**: Paste the UID
5. **Add these fields**:

```json
{
  "id": "PASTE_UID_HERE",
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

## After Setup

Once the admin document is created, you can:
- Login to web admin panel: https://ayam-chat.web.app
- Login to mobile app with admin@ayam-chat.com
- Access all admin features and permissions
