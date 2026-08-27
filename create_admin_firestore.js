// Create Firestore document for admin user
const API_KEY = 'AIzaSyAdkaskPsfqw4HVzikROGQjkrwb-iu-YEU';
const UID = 'GIneMU2bEqQrdkB11n8YlQfweG22';
const EMAIL = 'admin@ayam-chat.com';

async function createFirestoreDocument() {
  try {
    console.log('Creating Firestore document for admin user...');
    console.log('UID:', UID);
    console.log('Email:', EMAIL);
    
    // Get the ID token first
    const signInResponse = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: EMAIL,
        password: 'AdminPassword123!',
        returnSecureToken: true,
      }),
    });

    const signInData = await signInResponse.json();
    
    if (signInData.error) {
      console.error('Error signing in:', signInData.error.message);
      return false;
    }
    
    const idToken = signInData.idToken;
    console.log('✓ Got ID token');
    
    // Create the Firestore document
    const firestoreData = {
      id: UID,
      name: 'Super Admin',
      email: EMAIL,
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
      lastSeen: new Date().toISOString(),
      adminAccessExpiresAt: null,
      isBanned: false,
      wallet: {
        balance: 0.0,
        updatedAt: new Date().toISOString(),
      },
      createdAt: new Date().toISOString(),
      createdBy: 'system_seed',
    };
    
    console.log('Firestore data prepared:', JSON.stringify(firestoreData, null, 2));
    
    // Use Firestore REST API to create the document
    const projectId = 'ayam-chat';
    const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/users/${UID}?key=${API_KEY}`;
    
    const response = await fetch(firestoreUrl, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`,
      },
      body: JSON.stringify({
        fields: Object.keys(firestoreData).reduce((acc, key) => {
          const value = firestoreData[key];
          if (typeof value === 'string') {
            acc[key] = { stringValue: value };
          } else if (typeof value === 'number') {
            acc[key] = { integerValue: value.toString() };
          } else if (typeof value === 'boolean') {
            acc[key] = { booleanValue: value };
          } else if (value === null) {
            acc[key] = { nullValue: null };
          } else if (typeof value === 'object') {
            if (Array.isArray(value)) {
              acc[key] = { 
                arrayValue: { 
                  values: value.map(v => ({ stringValue: v })) 
                } 
              };
            } else {
              acc[key] = { 
                mapValue: { 
                  fields: Object.keys(value).reduce((subAcc, subKey) => {
                    const subValue = value[subKey];
                    if (typeof subValue === 'string') {
                      subAcc[subKey] = { stringValue: subValue };
                    } else if (typeof subValue === 'number') {
                      subAcc[subKey] = { doubleValue: subValue };
                    } else {
                      subAcc[subKey] = { stringValue: subValue.toString() };
                    }
                    return subAcc;
                  }, {})
                } 
              };
            }
          }
          return acc;
        }, {})
      }),
    });

    const result = await response.json();
    
    if (response.ok) {
      console.log('✅ SUCCESS: Firestore document created/updated!');
      console.log('Document ID:', UID);
      console.log('Role: owner');
      console.log('Permissions: all');
      return true;
    } else {
      console.error('Error creating Firestore document:', result);
      return false;
    }
  } catch (error) {
    console.error('Error:', error);
    return false;
  }
}

createFirestoreDocument().then((success) => {
  process.exit(success ? 0 : 1);
}).catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});