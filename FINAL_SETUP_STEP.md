# Final Setup Step - Import Admin Document to Firestore

## Admin Document Ready ✅

The admin document has been generated with:
- **Document ID**: `admin_1c0592c83712df69c9767bb42a65`
- **Email**: `admin@ayam-chat.com`
- **Password**: `Admin@123456`
- **Role**: `owner` (full admin access)
- **File**: `admin_document.json`

## Manual Import Steps (2 minutes)

### Step 1: Create Firebase Auth User
1. Go to: https://console.firebase.google.com/project/ayam-chat/authentication/users
2. Click "Add user"
3. Email: `admin@ayam-chat.com`
4. Password: `Admin@123456`
5. Click "Add user"
6. **Important**: Copy the User UID that Firebase generates

### Step 2: Update Document ID (if needed)
If the Firebase Auth UID is different from `admin_1c0592c83712df69c9767bb42a65`:
1. Open `admin_document.json`
2. Change `"id"` field to match the Firebase Auth UID
3. Save the file

### Step 3: Import to Firestore
1. Go to: https://console.firebase.google.com/project/ayam-chat/firestore/data/users
2. Click "Add document"
3. Document ID: Paste the Firebase Auth UID
4. Add fields from `admin_document.json`:
   - `id`: string (the UID)
   - `name`: string "Admin"
   - `email`: string "admin@ayam-chat.com"
   - `role`: string "owner"
   - `permissions`: array ["all", "manage_users", "manage_rooms", "manage_agencies", "manage_store", "manage_banners", "manage_moderation", "manage_financial", "view_analytics", "system_config"]
   - `isOnline`: boolean false
   - `level`: number 999
   - `currentXP`: number 0
   - `vipLevel`: number 7
   - `svipLevel`: number 10
   - `wealthLevel`: number 10
   - `magicLevel`: number 10
   - `nobleLevel`: number 10
   - `wallet`: map { "balance": number 999999999 }

### Step 4: Verify Login
1. Open: https://ayam-chat.web.app
2. Login with: `admin@ayam-chat.com` / `Admin@123456`
3. Should access admin dashboard successfully

## Alternative: Use Existing Admin User

If you already have an admin user in Firebase Auth:
1. Get their UID from Firebase Console
2. Update `admin_document.json` with that UID
3. Import to Firestore as described above

## What's Already Done ✅

- ✅ Web admin panel built and deployed
- ✅ Firestore rules updated and deployed
- ✅ Android APK built (371.2MB)
- ✅ Admin document generated with proper structure
- ✅ Firebase Hosting live at https://ayam-chat.web.app

## After This Step

Once you complete the manual import, the entire system will be 100% functional:
- Admin login will work on web and mobile
- All admin features will be accessible
- Firestore permissions will be properly configured
- The app is ready for production use
