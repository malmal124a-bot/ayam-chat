export interface UserRow {
  auth_uid: string;
  numeric_id: string | null;
  name: string | null;
  email: string | null;
  photo_url: string | null;
  gender: string | null;
  level: number;
  current_xp: number;
  vip_level: number;
  wealth_level: number;
  magic_level: number;
  noble_level: number;
  global_score: number;
  diamonds: number;
  coins: number;
  balance: number;
  total_recharged: number;
  status: string;
  is_online: boolean;
  is_agent: boolean;
  role: string;
  permissions: unknown;
  current_room_id: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export interface RoomRow {
  room_id: string;
  room_name: string | null;
  description: string | null;
  category: string | null;
  owner_id: string | null;
  owner_uid: string | null;
  owner_name: string | null;
  room_cover: string | null;
  participant_count: number;
  status: string;
  is_active: boolean;
  active_mic_count: number;
  room_password: string | null;
  is_chat_enabled: boolean;
  all_mics_muted: boolean;
  created_at: string | null;
  last_active: string | null;
}

export interface MessageRow {
  id: string;
  room_id: string;
  sender_name: string | null;
  text: string | null;
  type: string;
  sender_level: number;
  target_name: string | null;
  gift_name: string | null;
  gift_count: number | null;
  image_url: string | null;
  created_at: string | null;
}

export interface DmMessageRow {
  id: string;
  from_user_id: string;
  to_user_id: string;
  from_name: string | null;
  to_name: string | null;
  text: string | null;
  is_read: boolean;
  created_at: string | null;
}

export type StoreItemType = 'gift' | 'frame' | 'entryEffect' | 'fancyId';

export interface StoreItemRow {
  id: string;
  name: string;
  category: string;
  item_type: StoreItemType;
  price: number;
  image_url: string | null;
  svga_url: string | null;
  animated: boolean;
  min_level: number;
  is_active: boolean;
  order: number;
  created_at: string | null;
  updated_at: string | null;
}

export interface BannerRow {
  id: string;
  image_url: string | null;
  title: string | null;
  order: number;
  created_at: string | null;
}

export interface Stats {
  users: number;
  rooms: number;
  messages: number;
  dms: number;
  participants: number;
  giftsSent: number;
  diamondsSpent: number;
  onlineUsers: number;
  activeRooms: number;
}

export const STORE_CATEGORIES = [
  'شائعة',
  'CP',
  'الأعلام',
  'الحظ',
  'المطابخ / ارستقراطية',
  'الغامض',
  'نقاط',
];

export const STORE_TYPES: { value: StoreItemType; label: string }[] = [
  { value: 'gift', label: 'هدية متحركة' },
  { value: 'frame', label: 'إطار' },
  { value: 'entryEffect', label: 'تأثير دخول' },
  { value: 'fancyId', label: 'رقم مميز' },
];
