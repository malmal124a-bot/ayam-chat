const admin = require('firebase-admin');
const fs = require('fs');

async function setupAdminDocument() {
  const adminEmail = 'admin@ayam-chat.com';
  const adminPassword = 'Admin@123456';
  const projectId = 'ayam-chat';
  
  try {
    console.log('Setting up admin user and document for:', adminEmail);
    
    // Check for service account key - REQUIRED for Firebase Admin SDK
    if (!fs.existsSync('service-account-key.json')) {
      console.log('❌ Service account key not found.');
      console.log('');
      console.log('To use Firebase Admin SDK CLI, you need a service account key.');
      console.log('Download it from Firebase Console:');
      console.log('https://console.firebase.google.com/project/ayam-chat/settings/serviceaccounts/adminsdk');
      console.log('');
      console.log('Steps:');
      console.log('1. Click "Generate New Private Key"');
      console.log('2. Save as service-account-key.json in the project root');
      console.log('3. Run: node setup_admin.js');
      console.log('');
      console.log('The service account key is required to:');
      console.log('- Create users in Firebase Auth');
      console.log('- Write documents to Firestore');
      console.log('- Perform admin operations programmatically');
      
      process.exit(1);
    }
    
    console.log('✅ Found service account key');
    
    // Initialize Firebase Admin SDK
    const serviceAccount = require('./service-account-key.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: projectId
    });
    
    console.log('✅ Firebase Admin SDK initialized');
    
    const auth = admin.auth();
    const db = admin.firestore();
    
    // Step 1: Check if user exists in Firebase Auth
    console.log('Checking if admin user exists in Firebase Auth...');
    let userUid;
    
    try {
      const userRecord = await auth.getUserByEmail(adminEmail);
      userUid = userRecord.uid;
      console.log('✅ Found existing admin user with UID:', userUid);
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log('User not found, creating new admin user...');
        
        // Create the user
        const newUser = await auth.createUser({
          email: adminEmail,
          emailVerified: true,
          password: adminPassword,
          displayName: 'Admin',
          disabled: false
        });
        
        userUid = newUser.uid;
        console.log('✅ Created new admin user with UID:', userUid);
      } else {
        throw error;
      }
    }
    
    // Step 2: Create Firestore document
    console.log('Creating admin document in Firestore...');
    
    const adminDoc = {
      id: userUid,
      name: 'Admin',
      email: adminEmail,
      role: 'owner',
      permissions: [
        'all',
        'manage_users',
        'manage_rooms',
        'manage_agencies',
        'manage_store',
        'manage_banners',
        'manage_moderation',
        'manage_financial',
        'view_analytics',
        'system_config'
      ],
      isOnline: false,
      level: 999,
      currentXP: 0,
      vipLevel: 7,
      svipLevel: 10,
      wealthLevel: 10,
      magicLevel: 10,
      nobleLevel: 10,
      wallet: {
        balance: 999999999
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
    
    await db.collection('users').doc(userUid).set(adminDoc, { merge: true });
    console.log('✅ Admin document created successfully in Firestore');
    
    console.log('\n✨ Admin setup completed successfully!');
    console.log('Email:', adminEmail);
    console.log('Password:', adminPassword);
    console.log('User UID:', userUid);
    console.log('Admin Panel: https://ayam-chat.web.app');
    console.log('');
    console.log('You can now login with these credentials on both web and mobile.');
    
    process.exit(0);
    
  } catch (error) {
    console.error('\n💥 Admin setup failed:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the setup
setupAdminDocument();
