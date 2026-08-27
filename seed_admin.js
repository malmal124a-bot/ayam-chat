const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://ayam-chat.firebaseio.com'
});

const auth = admin.auth();
const db = admin.firestore();

const email = 'admin@ayam-chat.com';
const password = 'AdminPassword123!';

console.log('Creating initial Super Admin account...');
console.log('Email:', email);
console.log('Password:', password);

async function createAdmin() {
  try {
    // Create Firebase Auth user
    console.log('\nStep 1: Creating Firebase Auth user...');
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      emailVerified: true,
    });
    const userId = userRecord.uid;
    console.log('✓ Firebase Auth user created with UID:', userId);

    // Create Firestore user document
    console.log('\nStep 2: Creating Firestore user document...');
    await db.collection('users').doc(userId).set({
      id: userId,
      name: 'Super Admin',
      email: email,
      profilePic: '',
      gender: 'other',
      level: 1,
      currentXP: 0,
      vipLevel: 0,
      svipLevel: 0,
      wealthLevel: 1,
      magicLevel: 1,
      nobleLevel: 1,
      wealthXP: 0,
      magicXP: 0,
      nobleXP: 0,
      globalScore: 0,
      followersCount: 0,
      visitorsCount: 0,
      friendsCount: 0,
      likesCount: 0,
      role: 'owner',
      permissions: ['all'],
      isOnline: false,
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
      adminAccessExpiresAt: null,
      isBanned: false,
      wallet: {
        balance: 0.0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'system_seed',
    });
    console.log('✓ Firestore user document created');

    console.log('\n✅ SUCCESS: Initial Super Admin account created successfully!');
    console.log('\nLogin credentials:');
    console.log('  Email: admin@ayam-chat.com');
    console.log('  Password: AdminPassword123!');
    console.log('  Role: owner');
    console.log('  Permissions: all');
    console.log('\nYou can now log in at: https://ayam-chat.web.app');

  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log('\n⚠️  Email already exists. Updating Firestore document...');
      try {
        // Get existing user by email
        const userRecord = await auth.getUserByEmail(email);
        const userId = userRecord.uid;
        
        await db.collection('users').doc(userId).set({
          id: userId,
          name: 'Super Admin',
          email: email,
          profilePic: '',
          gender: 'other',
          level: 1,
          currentXP: 0,
          vipLevel: 0,
          svipLevel: 0,
          wealthLevel: 1,
          magicLevel: 1,
          nobleLevel: 1,
          wealthXP: 0,
          magicXP: 0,
          nobleXP: 0,
          globalScore: 0,
          followersCount: 0,
          visitorsCount: 0,
          friendsCount: 0,
          likesCount: 0,
          role: 'owner',
          permissions: ['all'],
          isOnline: false,
          lastSeen: admin.firestore.FieldValue.serverTimestamp(),
          adminAccessExpiresAt: null,
          isBanned: false,
          wallet: {
            balance: 0.0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          createdBy: 'system_seed',
        }, { merge: true });
        
        console.log('✓ Firestore user document updated with owner role');
        console.log('\n✅ SUCCESS: Admin account updated successfully!');
        console.log('\nLogin credentials:');
        console.log('  Email: admin@ayam-chat.com');
        console.log('  Password: AdminPassword123!');
        console.log('  Role: owner');
        console.log('  Permissions: all');
      } catch (updateError) {
        console.error('❌ Error updating existing user:', updateError);
      }
    } else {
      console.error('❌ Error:', error);
    }
  }
}

createAdmin().then(() => {
  process.exit(0);
}).catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
