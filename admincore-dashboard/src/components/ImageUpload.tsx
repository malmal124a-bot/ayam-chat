import { useState, useRef, ChangeEvent } from 'react';
import { Upload, X, Loader2, Camera, Film, Image, FileJson, FileArchive } from 'lucide-react';

type AssetType = 'svga' | 'vap' | 'mp4' | 'webp' | 'gif' | 'png' | 'jpg' | 'zip' | 'json' | 'other';

function detectAssetType(fileName: string): AssetType {
  const match = fileName.match(/[?&]assetType=(\w+)/i);
  if (match) {
    const val = match[1].toLowerCase() as AssetType;
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

function encodeAssetType(url: string, type: AssetType): string {
  const cleaned = url.replace(/[?&]assetType=\w+/gi, '').replace(/[?&]$/, '');
  if (!cleaned) return url;
  const separator = cleaned.includes('?') ? '&' : '?';
  return `${cleaned}${separator}assetType=${type}`;
}

const ASSET_BADGES: Record<AssetType, { label: string; color: string }> = {
  svga: { label: 'SVGA', color: 'text-purple-400 bg-purple-500/20 border-purple-500/30' },
  vap: { label: 'VAP', color: 'text-pink-400 bg-pink-500/20 border-pink-500/30' },
  mp4: { label: 'MP4', color: 'text-rose-400 bg-rose-500/20 border-rose-500/30' },
  webp: { label: 'WEBP', color: 'text-emerald-400 bg-emerald-500/20 border-emerald-500/30' },
  gif: { label: 'GIF', color: 'text-amber-400 bg-amber-500/20 border-amber-500/30' },
  png: { label: 'PNG', color: 'text-sky-400 bg-sky-500/20 border-sky-500/30' },
  jpg: { label: 'JPG', color: 'text-orange-400 bg-orange-500/20 border-orange-500/30' },
  zip: { label: 'ZIP', color: 'text-yellow-400 bg-yellow-500/20 border-yellow-500/30' },
  json: { label: 'JSON', color: 'text-cyan-400 bg-cyan-500/20 border-cyan-500/30' },
  other: { label: 'FILE', color: 'text-slate-400 bg-slate-500/20 border-slate-500/30' },
};

function getTypeIcon(type: AssetType) {
  switch (type) {
    case 'svga': return <FileJson className="w-5 h-5" />;
    case 'vap':
    case 'mp4': return <Film className="w-5 h-5" />;
    case 'zip': return <FileArchive className="w-5 h-5" />;
    case 'json': return <FileJson className="w-5 h-5" />;
    default: return <Image className="w-5 h-5" />;
  }
}

interface ImageUploadProps {
  currentUrl?: string | null;
  currentType?: AssetType;
  onUpload: (file: File, onProgress?: (pct: number) => void) => Promise<string>;
  onUrlChange?: (url: string, type: AssetType) => void;
  label?: string;
  accept?: string;
  className?: string;
}

const ASSET_TYPE_OPTIONS: AssetType[] = ['webp', 'png', 'gif', 'jpg', 'svga', 'vap', 'mp4', 'zip', 'json'];

export default function ImageUpload({ currentUrl, currentType, onUpload, onUrlChange, label = 'Upload Image', accept = 'image/*', className = '' }: ImageUploadProps) {
  const initialUrl = currentUrl || '';
  const [preview, setPreview] = useState<string | null>(initialUrl);
  const [uploading, setUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [urlInput, setUrlInput] = useState(initialUrl);
  const [showUrlInput, setShowUrlInput] = useState(false);
  const [assetType, setAssetType] = useState<AssetType>(() => {
    if (currentType) return currentType;
    if (initialUrl) return detectAssetType(initialUrl);
    return 'other';
  });
  const inputRef = useRef<HTMLInputElement>(null);
  const cameraRef = useRef<HTMLInputElement>(null);

  const setPreviewWithType = (url: string, type: AssetType) => {
    const encoded = encodeAssetType(url, type);
    setPreview(encoded);
    onUrlChange?.(encoded, type);
  };

  const handleFile = async (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    setProgress(0);
    const detected = detectAssetType(file.name);
    setAssetType(detected);
    try {
      const url = await onUpload(file, (pct) => setProgress(pct));
      setPreviewWithType(url, detected);
    } catch (err) {
      alert('Upload failed: ' + (err as Error).message);
    }
    setUploading(false);
    setProgress(0);
    if (inputRef.current) inputRef.current.value = '';
  };

  const handleTypeChange = (newType: AssetType) => {
    setAssetType(newType);
    if (preview) {
      setPreviewWithType(preview, newType);
    }
  };

  const handleUrlSubmit = () => {
    if (urlInput.trim()) {
      const detected = detectAssetType(urlInput.trim());
      setAssetType(detected);
      setPreviewWithType(urlInput.trim(), detected);
      setShowUrlInput(false);
    }
  };

  const handleRemove = () => {
    setPreview(null);
    setAssetType('other');
    onUrlChange?.('', 'other');
  };

  const isImageType = (t: AssetType) => t === 'webp' || t === 'gif' || t === 'png' || t === 'jpg';
  const badge = ASSET_BADGES[assetType];

  return (
    <div className={`space-y-2 ${className}`}>
      <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{label}</label>
      {preview ? (
        <div className="flex items-start gap-3">
          <div className="relative inline-block flex-shrink-0">
            {isImageType(assetType) ? (
              <img src={preview} className="w-20 h-20 object-cover rounded-lg border border-white/10" onError={() => setPreview(null)} />
            ) : (
              <div className="w-20 h-20 rounded-lg bg-gradient-to-br from-indigo-500/20 to-purple-500/20 border border-indigo-500/30 flex flex-col items-center justify-center gap-1">
                {getTypeIcon(assetType)}
              </div>
            )}
            <button
              onClick={handleRemove}
              className="absolute -top-1.5 -right-1.5 w-5 h-5 rounded-full bg-rose-500 text-white flex items-center justify-center"
            >
              <X className="w-3 h-3" />
            </button>
          </div>
          <div className="flex flex-col gap-1.5 min-w-0">
            <select
              value={assetType}
              onChange={e => handleTypeChange(e.target.value as AssetType)}
              className="bg-[#141417] border border-white/10 rounded-lg py-1 px-2 text-[10px] text-white font-bold uppercase"
            >
              {ASSET_TYPE_OPTIONS.map(t => (
                <option key={t} value={t}>{t.toUpperCase()}</option>
              ))}
            </select>
            <span className="text-[7px] text-slate-500 truncate max-w-[160px]" title={preview}>{preview}</span>
          </div>
        </div>
      ) : (
        <div className="flex items-center gap-2">
          <button
            onClick={() => inputRef.current?.click()}
            disabled={uploading}
            className="w-20 h-20 rounded-lg border-2 border-dashed border-white/10 flex items-center justify-center text-slate-500 hover:border-indigo-500/50 hover:text-indigo-400 transition-all"
          >
            {uploading ? <Loader2 className="w-5 h-5 animate-spin" /> : <Upload className="w-5 h-5" />}
          </button>
          {accept === 'image/*' && (
            <button
              onClick={() => cameraRef.current?.click()}
              disabled={uploading}
              className="w-10 h-10 rounded-lg border border-white/10 flex items-center justify-center text-slate-500 hover:text-indigo-400 hover:border-indigo-500/50 transition-all"
              title="Take Photo"
            >
              <Camera className="w-4 h-4" />
            </button>
          )}
          <button onClick={() => setShowUrlInput(!showUrlInput)} className="text-[10px] text-indigo-400 hover:text-indigo-300 font-semibold">
            {showUrlInput ? 'Cancel' : 'URL'}
          </button>
        </div>
      )}
      <input ref={inputRef} type="file" accept={accept} onChange={handleFile} className="hidden" />
      <input ref={cameraRef} type="file" accept="image/*" capture="environment" onChange={handleFile} className="hidden" />
      {uploading && progress > 0 && (
        <div className="w-full bg-slate-800 rounded-full h-1.5">
          <div className="bg-indigo-500 h-1.5 rounded-full transition-all" style={{ width: `${progress}%` }} />
        </div>
      )}
      {showUrlInput && (
        <div className="flex gap-2">
          <input
            type="text" value={urlInput} onChange={e => setUrlInput(e.target.value)}
            placeholder="Paste image URL..."
            className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
          />
          <button onClick={handleUrlSubmit} className="px-2 py-1 bg-indigo-600 text-xs text-white rounded-lg">Set</button>
        </div>
      )}
    </div>
  );
}
