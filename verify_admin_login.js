// Verify admin login and Firestore access
const API_KEY = 'AIzaSyAdkaskPsfqw4HVzikROGQjkrwb-iu-YEU';
const EMAIL = 'admin@ayam-chat.com';
const PASSWORD = 'AdminPassword123!';
const PROJECT_ID = 'ayam-chat';

async function verifyAdminLogin() {
  try {
    console.log('=== Verifying Admin Login ===\n');
    
    // Step 1: Authenticate
    console.log('Step 1: Authenticating with Firebase Auth...');
    const authResponse = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: EMAIL,
        password: PASSWORD,
        returnSecureToken: true,
      }),
    });

    const authData = await authResponse.json();
    
    if (authData.error) {
      console.error('❌ Authentication failed:', authData.error.message);
      return false;
    }
    
    console.log('✓ Authentication successful');
    console.log('  UID:', authData.localId);
    console.log('  Email:', authData.email);
    console.log('  Email Verified:', authData.emailVerified);
    
    // Step 2: Check Firestore document
    console.log('\nStep 2: Checking Firestore user document...');
    const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${authData.localId}?key=${API_KEY}`;
    
    const docResponse = await fetch(firestoreUrl, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${authData.idToken}`,
      },
    });

    const docData = await docResponse.json();
    
    if (!docResponse.ok) {
      console.error('❌ Failed to fetch Firestore document:', docData);
      return false;
    }
    
    console.log('✓ Firestore document exists');
    
    // Step 3: Verify required fields
    console.log('\nStep 3: Verifying required fields...');
    
    const getField = (fields, fieldName) => {
      if (fields && fields[fieldName]) {
        const field = fields[fieldName];
        if (field.stringValue !== undefined) return field.stringValue;
        if (field.integerValue !== undefined) return field.integerValue;
        if (field.booleanValue !== undefined) return field.booleanValue;
        if (field.arrayValue) return field.arrayValue.values?.map(v => v.stringValue);
        if (field.mapValue) return field.mapValue.fields;
      }
      return null;
    };
    
    const role = getField(docData.fields, 'role');
    const name = getField(docData.fields, 'name');
    const permissions = getField(docData.fields, 'permissions');
    const isBanned = getField(docData.fields, 'isBanned');
    
    console.log('  Role:', role);
    console.log('  Name:', name);
    console.log('  Permissions:', permissions);
    console.log('  Is Banned:', isBanned);
    
    // Step 4: Validate admin access
    console.log('\nStep 4: Validating admin access...');
    const allowedRoles = ['owner', 'super_admin', 'regional_manager', 'app_manager', 'agency_admin', 'banner_admin', 'moderator'];
    
    if (!allowedRoles.includes(role)) {
      console.error('❌ Invalid role for admin access:', role);
      console.error('   Required one of:', allowedRoles);
      return false;
    }
    
    if (isBanned === true) {
      console.error('❌ User is banned');
      return false;
    }
    
    console.log('✓ Admin access validation passed');
    
    console.log('\n=== ✅ SUCCESS: Admin login is fixed! ===\n');
    console.log('You can now log in to the admin panel with:');
    console.log('  Email: admin@ayam-chat.com');
    console.log('  Password: AdminPassword123!');
    console.log('  Role: owner');
    console.log('  Permissions: all');
    
    return true;
  } catch (error) {
    console.error('❌ Error during verification:', error);
    return false;
  }
}

verifyAdminLogin().then((success) => {
  process.exit(success ? 0 : 1);
}).catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});