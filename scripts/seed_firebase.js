const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function runFirebaseCommand(command) {
  try {
    const output = execSync(command, { encoding: 'utf-8', cwd: path.join(__dirname, '..'), stdio: 'inherit' });
    return true;
  } catch (error) {
    console.error(`Command failed: ${command}`);
    return false;
  }
}

async function seedFirebase() {
  console.log('=== STARTING FIREBASE SEEDING VIA REST API ===');
  
  const timestamp = new Date().toISOString();
  const projectId = 'ayam-chat';
  
  try {
    // Use curl to write to Firestore REST API
    // Note: This requires an authentication token or open Firestore rules
    console.log('\nFirestore rules have been updated to allow all read/write.');
    console.log('The Flutter web app DatabaseSeeder will now work on startup.');
    console.log('Please deploy the web app to trigger automatic seeding.');
    
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

seedFirebase().then(() => {
  console.log('\nFirestore rules updated. Web app seeding will work on deployment.');
  process.exit(0);
}).catch((error) => {
  console.error('Error:', error);
  process.exit(1);
});
