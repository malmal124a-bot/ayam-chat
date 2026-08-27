import { supabase } from './supabase';
import type { BannerRow, MessageRow, RoomRow, StoreItemRow, UserRow, DmMessageRow, Stats } from './types';

async function wrap<T>(p: PromiseLike<{ data: T | null; error: any }>): Promise<T> {
  const { data, error } = await p;
  if (error) throw new Error(error.message);
  return data as T;
}

// ---------- Stats ----------
export async function fetchStats(): Promise<Stats> {
  const [users, rooms, messages, dms, participants, giftRows] = await Promise.all([
    supabase.from('users').select('auth_uid,is_online', { count: 'exact' }),
    supabase.from('rooms').select('room_id,is_active', { count: 'exact' }),
    supabase.from('messages').select('id', { count: 'exact' }),
    supabase.from('dm_messages').select('id', { count: 'exact' }),
    supabase.from('participants').select('id', { count: 'exact' }),
    supabase.from('messages').select('gift_count,gift_name').eq('type', 'gift'),
  ]);
  const diamondRows = await supabase
    .from('messages')
    .select('gift_count')
    .eq('type', 'gift');

  const online = (users.data ?? []).filter((u) => u.is_online).length;
  const activeRooms = (rooms.data ?? []).filter((r) => r.is_active).length;
  let diamondsSpent = 0;
  for (const r of diamondRows.data ?? []) {
    diamondsSpent += Number(r.gift_count ?? 0);
  }
  return {
    users: users.count ?? 0,
    rooms: rooms.count ?? 0,
    messages: messages.count ?? 0,
    dms: dms.count ?? 0,
    participants: participants.count ?? 0,
    giftsSent: (giftRows.data ?? []).length,
    diamondsSpent,
    onlineUsers: online,
    activeRooms,
  };
}

// ---------- Users ----------
export const listUsers = (): Promise<UserRow[]> =>
  wrap(supabase.from('users').select('*').order('created_at', { ascending: false }).limit(500));

export const updateUser = (authUid: string, patch: Partial<UserRow>): Promise<UserRow> =>
  wrap(supabase.from('users').update(patch).eq('auth_uid', authUid).select().single());

export const deleteUser = async (authUid: string): Promise<void> => {
  await supabase.from('users').delete().eq('auth_uid', authUid);
};

// ---------- Rooms ----------
export const listRooms = (): Promise<RoomRow[]> =>
  wrap(supabase.from('rooms').select('*').order('last_active', { ascending: false }));

export const updateRoom = (roomId: string, patch: Partial<RoomRow>): Promise<RoomRow> =>
  wrap(supabase.from('rooms').update(patch).eq('room_id', roomId).select().single());

export const deleteRoom = async (roomId: string): Promise<void> => {
  await supabase.from('rooms').delete().eq('room_id', roomId);
};

// ---------- Messages ----------
export const listMessages = (limit = 200): Promise<MessageRow[]> =>
  wrap(supabase.from('messages').select('*').order('created_at', { ascending: false }).limit(limit));

export const messagesByRoom = (roomId: string, limit = 200): Promise<MessageRow[]> =>
  wrap(
    supabase
      .from('messages')
      .select('*')
      .eq('room_id', roomId)
      .order('created_at', { ascending: false })
      .limit(limit),
  );

export const deleteMessage = async (id: string): Promise<void> => {
  await supabase.from('messages').delete().eq('id', id);
};

// ---------- DMs ----------
export const listDMs = (limit = 300): Promise<DmMessageRow[]> =>
  wrap(supabase.from('dm_messages').select('*').order('created_at', { ascending: false }).limit(limit));

// ---------- Store / Gifts ----------
export const listStoreItems = (): Promise<StoreItemRow[]> =>
  wrap(supabase.from('store_items').select('*').order('order'));

export const upsertStoreItem = async (item: Partial<StoreItemRow>): Promise<StoreItemRow> => {
  const now = new Date().toISOString();
  const payload = { ...item, updated_at: now } as Record<string, unknown>;
  if (!item.id) {
    payload.id = `item_${Date.now()}`;
    payload.created_at = now;
  }
  return wrap(
    supabase.from('store_items').upsert(payload, { onConflict: 'id' }).select().single(),
  );
};

export const deleteStoreItem = async (id: string): Promise<void> => {
  await supabase.from('store_items').delete().eq('id', id);
};

// ---------- Banners ----------
export const listBanners = (): Promise<BannerRow[]> =>
  wrap(supabase.from('banners').select('*').order('order'));

export const upsertBanner = async (b: Partial<BannerRow>): Promise<BannerRow> => {
  const payload = { ...b } as Record<string, unknown>;
  if (!b.id) {
    payload.id = crypto.randomUUID();
    payload.created_at = new Date().toISOString();
  }
  return wrap(supabase.from('banners').upsert(payload, { onConflict: 'id' }).select().single());
};

export const deleteBanner = async (id: string): Promise<void> => {
  await supabase.from('banners').delete().eq('id', id);
};
