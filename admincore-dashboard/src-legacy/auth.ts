import {
  loginWithFirebaseEmail,
  onFirebaseAuthChange,
  firebaseLogout,
  type FirebaseUser,
} from './firebase'

export type AppUser = {
  id: string
  email: string | null
  displayName: string | null
  photoUrl: string | null
}

const toAppUser = (u: FirebaseUser | null): AppUser | null =>
  u
    ? {
        id: u.uid,
        email: u.email,
        displayName: u.displayName,
        photoUrl: u.photoURL,
      }
    : null

export function onAuthChange(callback: (user: AppUser | null) => void) {
  return onFirebaseAuthChange(u => callback(toAppUser(u)))
}

export async function loginWithEmail(email: string, password: string) {
  await loginWithFirebaseEmail(email, password)
}

export async function logout() {
  await firebaseLogout()
}
