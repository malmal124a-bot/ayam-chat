// Uploads go to Cloudinary (same account + preset as the Flutter app), because
// Firebase Storage is not enabled on this project (no billing account linked).
// The returned URL is a secure_url that the app reads normally via R.cachedImage().

const CLOUD_NAME = 'dl30muiuc';
const API_KEY = '865669713469485';
const API_SECRET = 'mnxgBf0IUGLH5UqJaQ4D3TjlHHs';
const UPLOAD_PRESET = 'zero_app';

interface CloudinaryConfig {
  cloudName: string;
  apiKey: string;
  apiSecret: string;
}

function getCloudinaryConfig(): CloudinaryConfig {
  let config: CloudinaryConfig | null = null;
  try {
    const raw = localStorage.getItem('cloudinary_config');
    if (raw) config = JSON.parse(raw);
  } catch {}
  if (config && config.cloudName && config.apiKey && config.apiSecret) {
    return config;
  }
  return {
    cloudName: localStorage.getItem('cloudinary_cloud_name') || CLOUD_NAME,
    apiKey: localStorage.getItem('cloudinary_api_key') || API_KEY,
    apiSecret: localStorage.getItem('cloudinary_api_secret') || API_SECRET,
  };
}

export function getCloudinaryStatus(): { configured: boolean; cloudName: string } {
  const cfg = getCloudinaryConfig();
  return { configured: !!(cfg.cloudName && cfg.apiKey), cloudName: cfg.cloudName || '' };
}

export function saveCloudinaryConfig(cloudName: string, apiKey: string, apiSecret: string): void {
  const cfg = { cloudName, apiKey, apiSecret };
  localStorage.setItem('cloudinary_config', JSON.stringify(cfg));
  localStorage.setItem('cloudinary_cloud_name', cloudName);
  localStorage.setItem('cloudinary_api_key', apiKey);
  localStorage.setItem('cloudinary_api_secret', apiSecret);
}

export function detectAssetType(fileName: string): string {
  const match = fileName.match(/[?&]assetType=(\w+)/i);
  if (match) {
    const val = match[1].toLowerCase();
    if (['svga', 'vap', 'mp4', 'webp', 'gif', 'png', 'jpg', 'zip', 'json', 'other'].includes(val)) return val;
  }
  const withoutParams = fileName.includes('?') ? fileName.slice(0, fileName.indexOf('?')) : fileName;
  const lower = withoutParams.toLowerCase();
  if (lower.endsWith('.svga')) return 'svga';
  if (lower.endsWith('.vap')) return 'vap';
  if (lower.endsWith('.mp4')) return 'mp4';
  if (lower.endsWith('.webp')) return 'webp';
  if (lower.endsWith('.gif')) return 'gif';
  if (lower.endsWith('.png')) return 'png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'jpg';
  if (lower.endsWith('.zip')) return 'zip';
  if (lower.endsWith('.json')) return 'json';
  return 'other';
}

const FOLDERS = {
  giftIcon: 'gift_icons',
  giftAnim: 'gift_animations',
  storeIcon: 'store_icons',
  storeFile: 'store_files',
  appAsset: 'app_assets',
  config: 'app_config',
  userPhoto: 'user_photos',
  roomPhoto: 'room_photos',
  banner: 'banners',
  levelIcon: 'level_icons',
} as const;

// ---- Cloudinary signed upload (mirrors CloudinaryService in the Flutter app) ----

function resourceTypeFor(file: File): 'auto' | 'image' | 'video' | 'raw' {
  const t = detectAssetType(file.name);
  if (t === 'svga' || t === 'vap' || t === 'zip' || t === 'json') return 'raw';
  if (t === 'mp4' || t === 'webm' || t === 'mov') return 'video';
  return 'auto';
}

function cloudinaryUploadUrl(cloudName: string, resourceType: string): string {
  return `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType}/upload`;
}

// Unsigned upload via `upload_preset` only. Signed uploads are rejected by the
// browser because Cloudinary does not send CORS headers for signed requests;
// the unsigned flow returns `Access-Control-Allow-Origin` for any browser origin
// and never exposes the API secret. (The Flutter app signs on-device instead.)
async function uploadToCloudinaryUnsigned(
  file: File,
  folder: string,
  onProgress?: (pct: number) => void,
): Promise<string> {
  const cfg = getCloudinaryConfig();
  const publicId = `${folder}/${Date.now()}_${file.name.replace(/[^a-zA-Z0-9._-]/g, '_')}`;

  const form = new FormData();
  form.append('file', file);
  form.append('upload_preset', UPLOAD_PRESET);
  form.append('public_id', publicId);

  const resourceType = resourceTypeFor(file);
  const url = cloudinaryUploadUrl(cfg.cloudName, resourceType);

  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', url);
    xhr.upload.onprogress = e => {
      if (onProgress && e.lengthComputable) {
        onProgress(Math.round((e.loaded / e.total) * 100));
      }
    };
    xhr.onload = () => {
      try {
        if (xhr.status >= 200 && xhr.status < 300) {
          const data = JSON.parse(xhr.responseText);
          resolve(data.secure_url || data.url);
        } else {
          reject(new Error(`Cloudinary upload failed: ${xhr.status} ${xhr.responseText}`));
        }
      } catch (e) {
        reject(e);
      }
    };
    xhr.onerror = () => reject(new Error('Cloudinary upload network error'));
    xhr.send(form);
  });
}

async function uploadAny(file: File, folder: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadToCloudinaryUnsigned(file, folder, onProgress);
}

// ---- Public upload functions (same signatures as before) ----

export async function uploadToCloudinary(file: File, folder: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, folder || FOLDERS.appAsset, onProgress);
}

export async function uploadGiftIcon(file: File, giftId: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.giftIcon, onProgress);
}

export async function uploadGiftAnimation(file: File, giftId: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.giftAnim, onProgress);
}

export async function uploadStoreItem(file: File, itemId: string, onProgress?: (pct: number) => void): Promise<string> {
  const type = detectAssetType(file.name);
  const isAnimOrFile = type === 'svga' || type === 'json' || type === 'zip' || type === 'mp4' || type === 'vap';
  const folder = isAnimOrFile ? FOLDERS.storeFile : FOLDERS.storeIcon;
  return uploadAny(file, folder, onProgress);
}

export async function uploadAppAsset(file: File, assetKey: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.appAsset, onProgress);
}

export async function uploadUserPhoto(file: File, uid: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.userPhoto, onProgress);
}

export async function uploadLevelImage(file: File, levelType: string, levelNum: number, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.levelIcon, onProgress);
}

export async function uploadRoomPhoto(file: File, roomId: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.roomPhoto, onProgress);
}

export async function uploadBanner(file: File, bannerId: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.banner, onProgress);
}

export async function uploadBadgeIcon(file: File, badgeId: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.giftIcon, onProgress);
}

export async function uploadBadgeSvga(file: File, badgeId: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.giftAnim, onProgress);
}

export async function uploadGiftBannerSvga(file: File, bannerId: string, onProgress?: (pct: number) => void): Promise<string> {
  return uploadAny(file, FOLDERS.banner, onProgress);
}
