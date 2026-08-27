# Firebase Security Rules Deployment Guide

## Overview
This guide provides instructions for deploying the updated Firebase Security Rules to ensure proper access control for both the Flutter App and Web Admin Panel.

## Rules Files
- **Firestore Rules**: `firestore.rules` - Controls Firestore database access
- **Realtime Database Rules**: `database.rules.json` - Controls Realtime Database access

## Security Features Implemented

### 1. Admin & App Access Control

#### Admin Roles (Full Access)
- `owner` - Master control, full financial access
- `super_admin` - Full access including financial operations
- `regional_manager` - Regional operations (no financial access)
- `app_manager` - App operations (no financial access)
- `agency_admin` - Agency management
- `banner_admin` - Banner/store management
- `moderator` - Moderation tools

#### Financial Admin Roles (Gems/Coins Modification)
- `owner` - Can modify wallet balances
- `super_admin` - Can modify wallet balances

### 2. User Access Permissions

#### Regular App Users Can:
- ✅ Read their own user document
- ✅ Update their own profile (name, profile pic, gender)
- ✅ Read their own wallet data
- ✅ Read their own transactions
- ✅ Create their own transactions
- ✅ Read rooms and messages
- ✅ Read store items, gifts, families, leaderboards

#### Regular App Users Cannot:
- ❌ Modify wallet balance/diamonds (financial fields)
- ❌ Modify VIP/SVIP levels
- ❌ Modify role/level permissions
- ❌ Modify ban status
- ❌ Modify other users' data
- ❌ Access admin-only collections

### 3. Sensitive Field Protection

The following fields are protected and can only be modified by financial admins:
- `balance` (Gems in USD)
- `diamonds` (Coins)
- `vipLevel`
- `svipLevel`
- `level`
- `wealthLevel`
- `magicLevel`
- `nobleLevel`
- `role`
- `isBanned`
- `banReason`
- `banExpiresAt`

## Deployment Instructions

### Option 1: Firebase Console (Recommended for Quick Deployment)

#### Deploy Firestore Rules
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `ayam-chat`
3. Navigate to **Firestore Database** → **Rules** tab
4. Click **Publish** after reviewing the rules below
5. Copy the contents of `firestore.rules` file and paste into the rules editor
6. Click **Publish**

#### Deploy Realtime Database Rules
1. Navigate to **Realtime Database** → **Rules** tab
2. Copy the contents of `database.rules.json` file
3. Paste into the rules editor
4. Click **Publish**

### Option 2: Firebase CLI (Recommended for Production)

#### Install Firebase CLI (if not installed)
```bash
npm install -g firebase-tools
```

#### Login to Firebase
```bash
firebase login
```

#### Initialize Firebase in project (if not already done)
```bash
firebase init
```
Select:
- Firestore: Configure security rules
- Realtime Database: Configure security rules

#### Deploy Rules
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Realtime Database rules
firebase deploy --only database:rules

# Deploy both at once
firebase deploy --only firestore:rules,database:rules
```

### Option 3: Firebase CLI with Existing Configuration

If your project already has Firebase CLI configured:

```bash
# From project root directory
firebase deploy --only firestore:rules
firebase deploy --only database:rules
```

## Rules Verification

### Test Firestore Rules
After deployment, verify rules using Firebase Console:

1. Go to **Firestore Database** → **Rules** tab
2. Click **Simulate** button
3. Test scenarios:
   - Regular user reading their own data ✅
   - Regular user modifying their own profile ✅
   - Regular user modifying wallet balance ❌ (should fail)
   - Admin reading all users ✅
   - Admin modifying wallet balance ✅

### Test Realtime Database Rules
1. Go to **Realtime Database** → **Rules** tab
2. Use the simulator to test:
   - Regular user reading rooms ✅
   - Regular user writing to rooms ❌ (should fail)
   - Admin writing to rooms ✅

## Important Notes

### Initial Admin Setup
Before deploying rules, ensure you have at least one admin user:
1. Create a user in Firebase Authentication
2. Add their document to Firestore `users` collection with `role: 'owner'`
3. Deploy rules after confirming admin access

### Role Assignment
Admin roles are assigned via the `role` field in the user document:
```javascript
// Example: Set a user as owner
await firestore.collection('users').doc(userId).update({
  role: 'owner'
});
```

### Wallet Protection
The wallet subcollection has strict protection:
- Only `owner` and `super_admin` can modify wallet data
- Users can only read their wallet, not write to it
- Admin Panel wallet transactions work because admins have financial access

### Testing Before Production
1. Deploy rules to a test environment first
2. Test all admin functions from Admin Panel
3. Test all user functions from Flutter App
4. Verify sensitive field protection
5. Then deploy to production

## Troubleshooting

### Permission Denied Errors
If you encounter permission errors:
1. Check the user's `role` field in Firestore
2. Verify the role is in the allowed roles list
3. Ensure the user is authenticated
4. Check the Firestore Rules tab for syntax errors

### Admin Panel Not Working
If Admin Panel cannot access data:
1. Verify admin user has correct role in Firestore
2. Check that Firebase Auth is working
3. Verify Admin Panel is using correct Firebase project
4. Check browser console for specific error messages

### Users Cannot Update Profile
If users cannot update their profile:
1. Verify the fields being updated are not sensitive fields
2. Check that the user is authenticated
3. Ensure the user is updating their own document (not someone else's)

## Rules Summary

### Firestore Rules Key Points
- ✅ Admin users (all roles) can read/write most collections
- ✅ Financial admins (owner, super_admin) can modify wallet data
- ✅ Regular users can read/write their own profile (non-sensitive fields)
- ✅ Regular users can read their wallet but not write to it
- ✅ All authenticated users can read public collections (rooms, store, gifts)
- ❌ Non-admin users cannot modify sensitive fields
- ❌ Non-authenticated users have no access

### Realtime Database Rules Key Points
- ✅ Admin users can read/write rooms
- ✅ All authenticated users can read rooms and messages
- ✅ All authenticated users can create messages
- ❌ Non-admin users cannot write to room configuration
- ❌ Non-authenticated users have no access

## Contact & Support
For issues with rules deployment or permissions:
1. Check Firebase Console Rules tab for syntax errors
2. Review Firebase documentation on security rules
3. Test using the Rules Simulator in Firebase Console
4. Verify Firebase project configuration matches code

## Version History
- **v2.0** - Updated with wallet protection, financial admin roles, and comprehensive subcollection rules
- **v1.0** - Initial basic rules
