// Upload helpers for legacy pages. All uploads go to the SAME Cloudinary
// account + unsigned preset as the Flutter app (CloudinaryService), so assets
// added from the dashboard appear in the app's media library immediately.
import { uploadToCloudinary as uploadToCloudinaryCore } from './cloudinary';

const CLOUD_NAME = 'womtce0x';
const UPLOAD_PRESET = 'ayam_chat';

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
  if (config && config.cloudName) {
    return config;
  }
  return {
    cloudName: localStorage.getItem('cloudinary_cloud_name') || CLOUD_NAME,
    apiKey: localStorage.getItem('cloudinary_api_key') || '',
    apiSecret: localStorage.getItem('cloudinary_api_secret') || '',
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

async function uploadAny(file: File, folder: string, onProgress?: (pct: number) => void): Promise<string> {
  const type = detectAssetType(file.name);
  const isRaw = type === 'svga' || type === 'vap' || type === 'zip' || type === 'json';
  if (onProgress) onProgress(20);
  const url = await uploadToCloudinaryCore(file, {
    folder,
    resourceType: isRaw ? 'raw' : 'image',
  });
  if (onProgress) onProgress(100);
  return url;
}

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
