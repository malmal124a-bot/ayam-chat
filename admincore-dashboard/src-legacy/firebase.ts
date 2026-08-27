import { initializeApp, type FirebaseApp } from 'firebase/app'
import { getAnalytics, isSupported, type Analytics } from 'firebase/analytics'
import {
  getAuth,
  signInWithEmailAndPassword,
  onAuthStateChanged,
  signOut,
  type Auth,
  type User as FirebaseUser,
} from 'firebase/auth'

const firebaseConfig = {
  apiKey: 'AIzaSyCGASmIR9P8ylA3Oia2HSMNa4K80d0xHMk',
  authDomain: 'zeroappzero-e1b4a.firebaseapp.com',
  databaseURL: 'https://zeroappzero-e1b4a-default-rtdb.firebaseio.com',
  projectId: 'zeroappzero-e1b4a',
  storageBucket: 'zeroappzero-e1b4a.firebasestorage.app',
  messagingSenderId: '95008435096',
  appId: '1:95008435096:web:aaf5b8c78a397b133099ed',
  measurementId: 'G-JG150HLC1N',
}

export const firebaseApp: FirebaseApp = initializeApp(firebaseConfig)

export const firebaseAuth: Auth = getAuth(firebaseApp)

export async function loginWithFirebaseEmail(email: string, password: string) {
  await signInWithEmailAndPassword(firebaseAuth, email, password)
}

export function onFirebaseAuthChange(callback: (user: FirebaseUser | null) => void) {
  return onAuthStateChanged(firebaseAuth, callback)
}

export async function firebaseLogout() {
  await signOut(firebaseAuth)
}

let analytics: Analytics | null = null

export const initFirebaseAnalytics = async (): Promise<Analytics | null> => {
  if (analytics) return analytics
  if (!(await isSupported())) return null
  analytics = getAnalytics(firebaseApp)
  return analytics
}
