// Cloudinary upload helpers — uses the SAME unsigned upload preset as the app
// (CloudinaryService in lib/services/cloudinary_service.dart), so assets added
// from the dashboard live in the same media library the app uploads to.
export const CLOUDINARY_CLOUD_NAME: string =
  import.meta.env.VITE_CLOUDINARY_CLOUD_NAME || 'womtce0x';
export const CLOUDINARY_UPLOAD_PRESET: string =
  import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET || 'ayam_chat';

export function isImageFile(file: File): boolean {
  return file.type.startsWith('image/');
}

/** Uploads a File (image or raw SVGA/GIF) and returns the public secure URL. */
export async function uploadToCloudinary(
  file: File,
  options: { folder?: string; resourceType?: 'image' | 'raw' } = {},
): Promise<string> {
  const resourceType = options.resourceType || (isImageFile(file) ? 'image' : 'raw');
  const form = new FormData();
  form.append('upload_preset', CLOUDINARY_UPLOAD_PRESET);
  if (options.folder) form.append('folder', options.folder);
  form.append('file', file);

  const url = `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/${resourceType}/upload`;
  const res = await fetch(url, { method: 'POST', body: form });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`Cloudinary upload failed (${res.status}): ${body.slice(0, 200)}`);
  }
  const json = (await res.json()) as { secure_url?: string; url?: string };
  const finalUrl = json.secure_url || json.url;
  if (!finalUrl) throw new Error('Cloudinary returned no URL');
  return finalUrl;
}
