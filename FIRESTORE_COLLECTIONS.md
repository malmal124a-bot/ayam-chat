# Firestore Collections Documentation

## Overview
This document describes all Firestore collections used in the Ayam Chat application and Admin Panel.

## User Collections

### `users`
Stores user account information and profile data.

**Fields:**
- `id` (string): Unique user identifier
- `name` (string): Display name
- `profilePic` (string): Profile image URL
- `gender` (string): User gender
- `level` (number): Account level
- `currentXP` (number): Current experience points
- `vipLevel` (number): VIP level (1-7)
- `svipLevel` (number): SVIP level (0-10)
- `wealthLevel` (number): Wealth level
- `magicLevel` (number): Magic level
- `nobleLevel` (number): Noble level
- `wealthXP` (number): Wealth experience
- `magicXP` (number): Magic experience
- `nobleXP` (number): Noble experience
- `globalScore` (number): Global score
- `activeFrame` (string): Active frame ID
- `avatarUrl` (string): Avatar image URL
- `avatarType` (string): Avatar type (static, gif, lottie)
- `followersCount` (number): Followers count
- `visitorsCount` (number): Visitors count
- `friendsCount` (number): Friends count
- `likesCount` (number): Likes count
- `role` (string): User role (owner, regional_manager, app_manager, super_admin, agency_admin, banner_admin, moderator, user)
- `permissions` (array): List of permission strings
- `isOnline` (boolean): Online status
- `lastSeen` (timestamp): Last seen timestamp
- `currentRoomId` (string): Current room ID
- `currentRoomName` (string): Current room name
- `adminAccessExpiresAt` (timestamp): Admin role expiration
- `customNumericId` (string): Custom numeric ID (e.g., 7777)
- `deviceId` (string): Device fingerprint for bans
- `ipAddress` (string): IP address for bans
- `isBanned` (boolean): Ban status
- `banReason` (string): Ban reason
- `banExpiresAt` (timestamp): Ban expiration
- `svipExpiresAt` (timestamp): SVIP expiration
- `timedStoreItems` (map): itemId -> expiration timestamp
- `wallet` (map): Wallet information
  - `balance` (number): Wallet balance
  - `updatedAt` (timestamp): Last update
- `updatedAt` (timestamp): Last update timestamp

**Subcollections:**
- `transactions`: User transaction history
  - `id` (string): Transaction ID
  - `amount` (number): Transaction amount
  - `date` (timestamp): Transaction date
  - `status` (string): Transaction status
  - `description` (string): Transaction description
  - `adminId` (string): Admin ID (if admin action)
  - `adminName` (string): Admin name (if admin action)
  - `type` (string): Transaction type

## Agency Collections

### `agencies`
Stores agency information and member data.

**Fields:**
- `id` (string): Agency ID
- `name` (string): Agency name
- `ownerId` (string): Owner user ID
- `description` (string): Agency description
- `level` (number): Agency level
- `commissionRate` (number): Commission rate
- `isActive` (boolean): Active status
- `createdAt` (timestamp): Creation timestamp
- `updatedAt` (timestamp): Last update
- `members` (array): List of agency members
  - `userId` (string): Member user ID
  - `userName` (string): Member name
  - `joinedAt` (timestamp): Join date
  - `role` (string): Member role
- `chargingLogs` (array): Charging transaction logs
  - `transactionId` (string): Transaction ID
  - `amount` (number): Amount
  - `date` (timestamp): Transaction date
  - `status` (string): Transaction status

### `agency_requests`
Stores pending agency applications.

**Fields:**
- `id` (string): Request ID
- `userId` (string): Applicant user ID
- `userName` (string): Applicant name
- `agencyName` (string): Proposed agency name
- `description` (string): Agency description
- `status` (string): Request status (pending, approved, rejected)
- `createdAt` (timestamp): Creation timestamp
- `reviewedAt` (timestamp): Review timestamp
- `reviewedBy` (string): Reviewer admin ID
- `rejectionReason` (string): Rejection reason (if rejected)

## Room Collections

### `rooms`
Stores voice room information.

**Fields:**
- `id` (string): Room ID
- `roomName` (string): Room name
- `ownerId` (string): Owner user ID
- `category` (string): Room category
- `participantCount` (number): Current participant count
- `isActive` (boolean): Active status
- `createdAt` (timestamp): Creation timestamp
- `closedAt` (timestamp): Close timestamp (if closed)
- `closedBy` (string): Admin ID who closed room
- `micSeats` (array): Mic seat configurations
  - `index` (number): Seat index (0-7)
  - `userId` (string): User ID on seat
  - `userName` (string): User name on seat
  - `isMuted` (boolean): Mute status
  - `updatedAt` (timestamp): Last update

## Store Collections

### `store_items`
Store items available for purchase.

**Fields:**
- `id` (string): Item ID
- `name` (string): Item name
- `type` (string): Item type (frame, avatar, effect, badge)
- `price` (number): Item price
- `imageUrl` (string): Item image URL
- `description` (string): Item description
- `isActive` (boolean): Active status
- `createdAt` (timestamp): Creation timestamp

### `banners`
Home screen carousel banners.

**Fields:**
- `id` (string): Banner ID
- `imageUrl` (string): Banner image URL
- `targetUrl` (string): Target URL on click
- `order` (number): Display order
- `isActive` (boolean): Active status
- `createdAt` (timestamp): Creation timestamp
- `createdBy` (string): Creator admin ID
- `updatedAt` (timestamp): Last update

## Moderation Collections

### `reports`
User reports for moderation.

**Fields:**
- `id` (string): Report ID
- `reportedUserId` (string): Reported user ID
- `reporterId` (string): Reporter user ID
- `reason` (string): Report reason
- `status` (string): Report status (pending, resolved)
- `timestamp` (timestamp): Report timestamp
- `resolvedAt` (timestamp): Resolution timestamp
- `resolvedBy` (string): Resolver admin ID

### `banned_devices`
Banned device fingerprints.

**Fields:**
- `deviceId` (string): Device fingerprint
- `userId` (string): Associated user ID
- `bannedAt` (timestamp): Ban timestamp
- `bannedBy` (string): Admin ID who banned

### `banned_ips`
Banned IP addresses.

**Fields:**
- `ipAddress` (string): IP address
- `userId` (string): Associated user ID
- `bannedAt` (timestamp): Ban timestamp
- `bannedBy` (string): Admin ID who banned

## System Configuration Collections

### `system_config/ai_support`
AI customer support configuration.

**Fields:**
- `systemPrompt` (string): AI system prompt
- `faqRules` (string): FAQ rules and guidelines
- `greeting` (string): Initial greeting message
- `updatedAt` (timestamp): Last update
- `updatedBy` (string): Admin ID who updated

### `system_config/global_announcement`
Global announcement bar configuration.

**Fields:**
- `text` (string): Announcement text
- `scrollDuration` (number): Scroll duration in seconds
- `autoScroll` (boolean): Auto-scroll enabled
- `updatedAt` (timestamp): Last update
- `updatedBy` (string): Admin ID who updated

### `system_config/game_ratios`
Game RTP (Return to Player) ratios.

**Fields:**
- `luckGiftsRTP` (number): Luck gifts RTP percentage (50-100)
- `cpGiftsRTP` (number): CP gifts RTP percentage (50-100)
- `miniGamesRTP` (number): Mini games RTP percentage (50-100)
- `updatedAt` (timestamp): Last update
- `updatedBy` (string): Admin ID who updated

## Indexes

### Recommended Composite Indexes

**users collection:**
- `customNumericId` (ascending)
- `role` (ascending), `adminAccessExpiresAt` (ascending)
- `phoneNumber` (ascending)

**rooms collection:**
- `participantCount` (descending)
- `isActive` (ascending), `participantCount` (descending)

**agencies collection:**
- `ownerId` (ascending)
- `isActive` (ascending)

**agency_requests collection:**
- `status` (ascending), `createdAt` (descending)

**reports collection:**
- `status` (ascending), `timestamp` (descending)

**banned_devices collection:**
- `deviceId` (ascending)

**banned_ips collection:**
- `ipAddress` (ascending)

## Security Notes

1. **Role-Based Access**: All admin operations verify user role before execution
2. **Financial Restrictions**: Only `owner` role can modify financial data
3. **Timed Access**: Admin roles with expiration automatically revert to `user` role
4. **Audit Trail**: All admin actions log `adminId` and timestamp
5. **Device/IP Bans**: Separate collections prevent alt-account creation
6. **Transaction Logging**: All financial changes create transaction records

## Data Retention

- **Transaction logs**: Keep for 365 days
- **Reports**: Keep for 180 days after resolution
- **Ban records**: Keep permanently
- **Agency requests**: Keep for 90 days after resolution
