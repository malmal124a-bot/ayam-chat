import { supabase, getAdminSupabase } from './supabase'
import type {
  UserModel, RoomModel, GiftModel, SentGiftModel,
  StoreItemModel, UnionModel, BugReport, AppConfig,
  LevelConfig, VIPConfig, BadgeConfig, AgencyModel,
  CPModel, BDModel, GiftedItem, UserVIP, NecklaceConfig,
  AdminUser, AdminActionLog, DashboardBan, AppAssetRecord,
  HostAgencyMemberModel, HostMilestoneModel, CommissionSettingModel,
  AgencyJoinRequestModel, AgencyLedgerEntryModel, AgencyWithdrawalRequestModel,
  HostAgencyModel, CpGiftModel, CpCarModel, CpEventSettings, CpRankRewardModel,
  SigninRewardModel,
} from '../types'

// ---- Auth Admin ----

export async function updateUserPassword(uid: string, password: string) {
  try {
    const adminClient = getAdminSupabase()
    if (!adminClient) throw new Error('Admin client not available')
    const { error } = await adminClient.auth.admin.updateUserById(uid, { password })
    if (error) throw error
  } catch (e) {
    console.warn('updateUserPassword failed:', e)
    throw e
  }
}

export async function getAuthUsers() {
  try {
    const adminClient = getAdminSupabase()
    if (!adminClient) return []
    const { data, error } = await adminClient.auth.admin.listUsers()
    if (error) throw error
    return data.users
  } catch (e) {
    console.warn('getAuthUsers failed:', e)
    return []
  }
}

export async function getAuthUser(uid: string) {
  try {
    const adminClient = getAdminSupabase()
    if (!adminClient) return null
    const { data, error } = await adminClient.auth.admin.getUserById(uid)
    if (error) throw error
    return data.user
  } catch (e) {
    console.warn('getAuthUser failed:', e)
    return null
  }
}

// ---- Helpers ----

function toCamelCase(record: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(record)) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase())
    result[camelKey] = value
  }
  return result
}

function toSnakeCase(record: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {}
  for (const [key, value] of Object.entries(record)) {
    const snakeKey = key.replace(/[A-Z]/g, c => `_${c.toLowerCase()}`)
    result[snakeKey] = value
  }
  return result
}

function mapList<T>(list: Record<string, unknown>[]): T[] {
  return list.map(item => toCamelCase(item) as unknown as T)
}

function mapSingle<T>(item: Record<string, unknown> | null): T | null {
  if (!item) return null
  return toCamelCase(item) as unknown as T
}

// The public.users table uses auth_uid / numeric_id (see supabase_schema.sql),
// while the legacy dashboard models used uid / customId. This fills every
// legacy field so pages render without undefined values.
const USER_DEFAULTS: UserModel = {
  uid: '', customId: '', name: '', email: '', photoUrl: '',
  coins: 0, diamonds: 0, gender: 'male',
  activeFrame: null, activeBubble: null, activeEntrance: null,
  activeCar: null, activeCover: null, activeNecklace: null,
  ownedItems: [], ownedBadges: [], ownedNecklaces: [],
  hostedRoomId: null, followedRooms: [],
  totalGiftsReceived: 0, level: 1, experience: 0,
  followers: 0, following: 0, visitors: 0, charm: 0,
  wealthLevel: 1, wealthExp: 0, rechargeLevel: 1, rechargeExp: 0,
  gemsLevel: 1, gemsExp: 0, ownedLevelFrames: [], ownedLevelBadges: [],
  phone: '', lastIp: '', banned: false, banReason: '',
}

function userRowToModel(row: Record<string, unknown>): UserModel {
  if (!row) return { ...USER_DEFAULTS }
  const base = toCamelCase(row) as Record<string, unknown>
  return {
    ...USER_DEFAULTS,
    ...base,
    uid: String(row.auth_uid ?? ''),
    customId: row.numeric_id ? String(row.numeric_id) : String(row.auth_uid ?? '').slice(0, 8),
    photoUrl: String(row.photo_url ?? row.avatar_url ?? ''),
    banned: String(row.status ?? '').toLowerCase() === 'banned',
  }
}

// ---- Users ----

export async function syncAllAuthUsersToDB() {
  const adminClient = getAdminSupabase()
  if (!adminClient) throw new Error('Admin client not available')

  try {
    // 1. Get all auth users
    const { data: authData, error: authError } = await adminClient.auth.admin.listUsers()
    if (authError) throw authError
    if (!authData?.users) return { total: 0, synced: 0 }

    // 2. Get existing users in DB
    const { data: existingUsers, error: fetchError } = await adminClient.from('users').select('auth_uid')
    if (fetchError) throw fetchError
    const existingUids = new Set((existingUsers || []).map((u: any) => u.auth_uid))

    // 3. Create missing users
    let syncedCount = 0
    for (const au of authData.users) {
      if (!existingUids.has(au.id)) {
        const metadata = au.user_metadata || {}
        const name = metadata.name || metadata.full_name || metadata.display_name || au.email?.split('@')[0] || 'Unknown'
        const photoUrl = metadata.avatar_url || metadata.picture || metadata.photoUrl || metadata.image || ''
        const email = au.email || ''

        const row: Record<string, unknown> = {
          auth_uid: au.id,
          numeric_id: metadata.numeric_id || '', // App generates numeric_id; don't overwrite
          name,
          email: email || null,
          photo_url: photoUrl || null,
          gender: metadata.gender || 'male',
          level: 1,
          diamonds: 0,
          coins: 0,
          wealth_level: 1,
          status: 'Active',
          is_online: true,
          role: 'user',
        }

        const { error: insertError } = await adminClient.from('users').insert(row)
        if (!insertError) {
          syncedCount++
        }
      }
    }
    return { total: authData.users.length, synced: syncedCount }
  } catch (e) {
    console.error('syncAllAuthUsersToDB failed:', e)
    throw e
  }
}

export async function getUsers(): Promise<UserModel[]> {
  const adminClient = getAdminSupabase()
  const results: UserModel[] = []

  // 1. Fetch ONLY from public users table (this is our source of truth!)
  try {
    const client = adminClient || supabase
    const { data } = await client.from('users').select('*').order('created_at', { ascending: false })
    if (data) results.push(...(data as Record<string, unknown>[]).map(userRowToModel))
  } catch (e) {
    console.warn('getUsers: public table failed', e)
  }

  return results.sort((a, b) => (Number(a.customId) || 0) - (Number(b.customId) || 0))
}

export function subscribeUsers(cb: (users: UserModel[]) => void) {
  const client = getAdminSupabase() || supabase
  const sub = client.channel('users-db').on('postgres_changes', { event: '*', schema: 'public', table: 'users' }, () => {
    getUsers().then(cb)
  }).subscribe((status) => {
    if (status !== 'SUBSCRIBED') {
      console.warn('subscribeUsers: channel status', status)
    }
  })
  return () => { try { client.removeChannel(sub) } catch {} }
}

export async function getUser(uid: string): Promise<UserModel | null> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('users').select('*').eq('auth_uid', uid).maybeSingle()
    return userRowToModel(data as Record<string, unknown>)
  } catch (e) {
    console.warn('getUser failed:', e)
    return null
  }
}

export async function updateUser(uid: string, data: Partial<UserModel>) {
  const client = getAdminSupabase() || supabase

  try {
    const { data: existingUser, error: fetchError } = await client.from('users').select('auth_uid').eq('auth_uid', uid).maybeSingle()

    if (fetchError) {
      console.error('Error checking for existing user:', fetchError)
      throw fetchError
    }

    const payload: Record<string, unknown> = {}
    if (data.name !== undefined) payload.name = data.name
    if (data.email !== undefined) payload.email = data.email
    if (data.photoUrl !== undefined) payload.photo_url = data.photoUrl
    if (data.gender !== undefined) payload.gender = data.gender
    if (data.level !== undefined) payload.level = data.level
    if (data.diamonds !== undefined) payload.diamonds = data.diamonds
    if (data.coins !== undefined) payload.coins = data.coins
    if (data.wealthLevel !== undefined) payload.wealth_level = data.wealthLevel
    if (data.wealthExp !== undefined) payload.wealth_xp = data.wealthExp
    if (data.banned !== undefined) payload.status = data.banned ? 'Banned' : 'Active'

    if (!existingUser) {
      // User doesn't exist - create new record
      payload.auth_uid = uid
      payload.numeric_id = data.customId || String(100000 + Math.floor(Math.random() * 900000))
      payload.status = data.banned ? 'Banned' : 'Active'
      payload.is_online = true
      payload.role = 'user'

      console.log('Inserting new user with data:', payload)
      const { error: insertError } = await client.from('users').insert(payload)
      if (insertError) {
        console.error('Error inserting user:', insertError)
        throw insertError
      }
    } else {
      // User exists - update
      console.log('Updating user with data:', payload)
      const { error } = await client.from('users').update(payload).eq('auth_uid', uid)
      if (error) {
        console.error('Error updating user:', error)
        throw error
      }
    }
  } catch (e) {
    console.error('updateUser failed:', e)
    throw e
  }
}

export async function deleteUser(uid: string) {
  console.log('Starting complete user deletion for:', uid)

  // Step 1: Clean up related collections (best-effort, mirror of old FK-safe RPC)
  const related: { col: string; field: string }[] = [
    { col: 'user_wallets', field: 'uid' },
    { col: 'notifications', field: 'uid' },
    { col: 'sent_gifts', field: 'uid' },
    { col: 'gifted_items', field: 'uid' },
    { col: 'follows', field: 'follower_uid' },
    { col: 'follows', field: 'following_uid' },
    { col: 'blocks', field: 'blocker_uid' },
    { col: 'blocks', field: 'blocked_uid' },
    { col: 'room_blocks', field: 'user_id' },
    { col: 'room_members', field: 'uid' },
    { col: 'room_seats', field: 'uid' },
    { col: 'room_messages', field: 'uid' },
    { col: 'profile_visits', field: 'visited_uid' },
    { col: 'profile_visits', field: 'visitor_uid' },
    { col: 'private_messages', field: 'sender_uid' },
    { col: 'private_messages', field: 'receiver_uid' },
  ]
  for (const { col, field } of related) {
    try {
      await supabase.from(col).delete().eq(field, uid)
    } catch { /* ignore */ }
  }

  // Step 2: Delete the user document itself
  const { error } = await supabase.from('users').delete().eq('auth_uid', uid)
  if (error) throw new Error(`Delete error: ${error.message}`)

  // Step 3: Revoke/delete the auth account (browser-safe compat)
  try {
    await getAdminSupabase().auth.admin.deleteUser(uid)
  } catch (e) {
    console.warn('Auth API deletion non-fatal:', e)
  }

  console.log('✅ USER DELETED COMPLETELY!')
}

// ---- Gifts ----
// Gifts live in store_items (item_type='gift') — the SAME table the app reads
// via CatalogService (lib/services/catalog_service.dart). The legacy `gifts`
// table no longer exists; a `gifts` VIEW over store_items keeps old read-only
// code (getStats) working. gift_categories.id <-> store_items.category name.

function giftRowToModel(row: Record<string, unknown>): GiftModel {
  return {
    id: String(row.id ?? ''),
    name: String(row.name ?? ''),
    value: Number(row.price ?? 0),
    iconAsset: String(row.image_url ?? ''),
    animationAsset: row.svga_url ? String(row.svga_url) : null,
    isVap: Boolean(row.is_vap),
    isLucky: Boolean(row.is_lucky),
    isStar: Boolean(row.is_star),
    isMusic: Boolean(row.is_music),
    packageCount: Number(row.package_count ?? 0),
    sortOrder: Number(row.order ?? 0),
    nameKey: row.name_key ? String(row.name_key) : undefined,
    photoKey: row.photo_key ? String(row.photo_key) : undefined,
    defaultImage: row.default_image ? String(row.default_image) : undefined,
    categoryId: row.category ? String(row.category) : undefined,
    isCpGift: Boolean(row.is_cp_gift),
    cpGiftDurationHours: Number(row.cp_gift_duration_hours ?? 0),
  }
}

function giftToStoreRow(data: Partial<GiftModel>, categoryName?: string): Record<string, unknown> {
  return {
    name: data.name ?? '',
    category: categoryName ?? data.categoryId ?? '',
    item_type: 'gift',
    price: Number(data.value ?? 0),
    image_url: data.iconAsset || null,
    svga_url: data.animationAsset || null,
    animated: !!data.animationAsset,
    min_level: 1,
    is_active: true,
    order: Number(data.sortOrder ?? 0),
    is_vap: !!data.isVap,
    is_lucky: !!data.isLucky,
    is_star: !!data.isStar,
    is_music: !!data.isMusic,
    package_count: Number(data.packageCount ?? 0),
    name_key: data.nameKey || null,
    photo_key: data.photoKey || null,
    default_image: data.defaultImage || null,
    is_cp_gift: !!data.isCpGift,
    cp_gift_duration_hours: Number(data.cpGiftDurationHours ?? 0),
  }
}

async function getGiftCategoryNames(): Promise<{ byId: Map<string, string>; byName: Map<string, string> }> {
  const byId = new Map<string, string>()
  const byName = new Map<string, string>()
  try {
    const { data } = await supabase.from('gift_categories').select('id,name')
    for (const c of data ?? []) {
      if (!c.id || !c.name) continue
      byId.set(String(c.id), String(c.name))
      byName.set(String(c.name), String(c.id))
    }
  } catch { /* gift_categories may be missing — falls back to raw text */ }
  return { byId, byName }
}

export async function getGifts(): Promise<GiftModel[]> {
  try {
    const [{ data }, { byName }] = await Promise.all([
      supabase.from('store_items').select('*').eq('item_type', 'gift').order('order'),
      getGiftCategoryNames(),
    ])
    return (data ?? []).map(row => {
      const model = giftRowToModel(row)
      // store_items.category holds the category NAME; surface its id to the UI.
      if (model.categoryId) model.categoryId = byName.get(model.categoryId) ?? model.categoryId
      return model
    })
  } catch {
    return []
  }
}

export function subscribeGifts(cb: (gifts: GiftModel[]) => void) {
  const sub = supabase.channel('gifts').on('postgres_changes', { event: '*', schema: 'public', table: 'store_items' }, () => {
    getGifts().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

export async function updateGift(id: string, data: Partial<GiftModel>) {
  try {
    const { byId } = await getGiftCategoryNames()
    const categoryName = data.categoryId ? (byId.get(data.categoryId) ?? data.categoryId) : undefined
    await supabase.from('store_items').update(giftToStoreRow(data, categoryName)).eq('id', id)
  } catch (e) {
    console.warn('updateGift failed:', e)
  }
}

export async function addGift(id: string, data: GiftModel) {
  try {
    const { byId } = await getGiftCategoryNames()
    const categoryName = data.categoryId ? (byId.get(data.categoryId) ?? data.categoryId) : undefined
    await supabase.from('store_items').upsert({ id, ...giftToStoreRow(data, categoryName) })
  } catch (e) {
    console.warn('addGift failed:', e)
  }
}

export async function deleteGift(id: string) {
  try {
    await supabase.from('store_items').delete().eq('id', id)
  } catch (e) {
    console.warn('deleteGift failed:', e)
  }
}

// ---- Store Items ----

export async function getStoreItems(): Promise<StoreItemModel[]> {
  try {
    const { data } = await supabase.from('store_items').select('*').order('order')
    return (data ?? []).map(row => ({
      itemId: String(row.id ?? ''),
      name: String(row.name ?? ''),
      category: String(row.category ?? '') as StoreItemModel['category'],
      iconAsset: String(row.image_url ?? ''),
      price: Number(row.price ?? 0),
      svgaAsset: row.svga_url ? String(row.svga_url) : null,
      videoAsset: null,
      isPremium: false,
    }))
  } catch {
    return []
  }
}

export function subscribeStoreItems(cb: (items: StoreItemModel[]) => void) {
  const sub = supabase.channel('store_items').on('postgres_changes', { event: '*', schema: 'public', table: 'store_items' }, () => {
    getStoreItems().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

export async function updateStoreItem(id: string, data: Partial<StoreItemModel>) {
  try {
    const payload: Record<string, unknown> = {}
    if (data.name !== undefined) payload.name = data.name
    if (data.category !== undefined) payload.category = data.category
    if (data.iconAsset !== undefined) payload.image_url = data.iconAsset
    if (data.price !== undefined) payload.price = data.price
    if (data.svgaAsset !== undefined) payload.svga_url = data.svgaAsset
    await supabase.from('store_items').update(payload).eq('id', id)
  } catch (e) {
    console.warn('updateStoreItem failed:', e)
  }
}

export async function addStoreItem(id: string, data: StoreItemModel) {
  try {
    await supabase.from('store_items').upsert({
      id,
      name: data.name,
      category: data.category,
      image_url: data.iconAsset,
      price: data.price,
      svga_url: data.svgaAsset,
      item_type: data.category || 'frame',
      is_active: true,
    })
  } catch (e) {
    console.warn('addStoreItem failed:', e)
  }
}

export async function deleteStoreItem(id: string) {
  try {
    await supabase.from('store_items').delete().eq('id', id)
  } catch (e) {
    console.warn('deleteStoreItem failed:', e)
  }
}

// ---- Rooms ----

export async function getRooms(): Promise<RoomModel[]> {
  try {
    const { data } = await supabase.from('rooms').select('*').order('created_at', { ascending: false })
    return mapList<RoomModel>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeRooms(cb: (rooms: RoomModel[]) => void) {
  const sub = supabase.channel('rooms').on('postgres_changes', { event: '*', schema: 'public', table: 'rooms' }, () => {
    getRooms().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

export async function updateRoom(id: string, data: Partial<RoomModel>) {
  try {
    await supabase.from('rooms').update(toSnakeCase(data as Record<string, unknown>)).eq('room_id', id)
  } catch (e) {
    console.warn('updateRoom failed:', e)
  }
}

export async function deleteRoom(id: string) {
  try {
    await supabase.from('rooms').delete().eq('room_id', id)
  } catch (e) {
    console.warn('deleteRoom failed:', e)
  }
}

// ---- Unions ----

export async function getUnions(): Promise<UnionModel[]> {
  try {
    const { data } = await supabase.from('unions').select('*').order('created_at', { ascending: false })
    return mapList<UnionModel>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeUnions(cb: (unions: UnionModel[]) => void) {
  const sub = supabase.channel('unions').on('postgres_changes', { event: '*', schema: 'public', table: 'unions' }, () => {
    getUnions().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

// ---- Sent Gifts ----

export async function getSentGifts(): Promise<SentGiftModel[]> {
  try {
    const { data } = await supabase.from('sent_gifts').select('*').order('created_at', { ascending: false })
    return mapList<SentGiftModel>(data ?? [])
  } catch {
    return []
  }
}

// ---- Bug Reports ----

export async function getBugReports(): Promise<BugReport[]> {
  try {
    const { data } = await supabase.from('bug_reports').select('*').order('created_at', { ascending: false })
    return mapList<BugReport>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeBugReports(cb: (reports: BugReport[]) => void) {
  const sub = supabase.channel('bug_reports').on('postgres_changes', { event: '*', schema: 'public', table: 'bug_reports' }, () => {
    getBugReports().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

// ---- App Config (key-value store, merged into single object) ----

export async function getAppConfig(): Promise<AppConfig | null> {
  try {
    const { data } = await supabase.from('app_config').select('*')
    if (!data || data.length === 0) return null
    const merged: Record<string, unknown> = {}
    for (const row of data) {
      const raw = row.value
      if (typeof raw === 'string') {
        try { merged[row.key as string] = JSON.parse(raw) } catch { merged[row.key as string] = raw }
      } else {
        merged[row.key as string] = raw
      }
    }
    return merged as unknown as AppConfig
  } catch {
    return null
  }
}

export async function updateAppConfig(updates: Partial<AppConfig>) {
  try {
    for (const [key, value] of Object.entries(updates)) {
      if (value === undefined || value === null) continue
      const stored = typeof value === 'object' ? JSON.stringify(value) : value
      await supabase.from('app_config').upsert({ key, value: stored })
    }
  } catch (e) {
    console.warn('updateAppConfig failed:', e)
  }
}

export function subscribeAppConfig(cb: (config: AppConfig | null) => void) {
  const handler = () => getAppConfig().then(cb)
  const sub = supabase.channel('app_config').on('postgres_changes',
    { event: '*', schema: 'public', table: 'app_config' }, handler
  ).subscribe()
  handler()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

// ---- Level Config ----

export async function getLevels(type?: string): Promise<LevelConfig[]> {
  try {
    let query = supabase.from('level_config').select('*')
    if (type) query = query.eq('type', type)
    const { data } = await query.order('level')
    return mapList<LevelConfig>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeLevels(cb: (levels: LevelConfig[]) => void) {
  const sub = supabase.channel('level_config').on('postgres_changes', { event: '*', schema: 'public', table: 'level_config' }, () => {
    getLevels().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

export async function updateLevel(type: string, level: number, data: Partial<LevelConfig>) {
  const payload = toSnakeCase(data as Record<string, unknown>)
  const { data: list } = await supabase.from('level_config').select('level').eq('type', type).eq('level', level)
  const existing = list && list.length > 0 ? list[0] : null
  if (existing) {
    await supabase.from('level_config').update(payload).eq('type', type).eq('level', level)
  } else {
    await supabase.from('level_config').insert(payload)
  }
}

// ---- VIP Config ----

export async function getVIPConfig(): Promise<VIPConfig[]> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('vip_config').select('*').order('tier')
    return mapList<VIPConfig>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeVIPConfig(cb: (configs: VIPConfig[]) => void) {
  const sub = supabase.channel('vip_config').on('postgres_changes', { event: '*', schema: 'public', table: 'vip_config' }, () => {
    getVIPConfig().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

export async function updateVIPConfig(tier: number, data: Partial<VIPConfig>) {
  try {
    const client = getAdminSupabase() || supabase
    const payload = { tier, ...toSnakeCase(data as Record<string, unknown>) }

    const existing = await getTableColumns(client, 'vip_config')
    const filtered: Record<string, unknown> = {}
    for (const key of Object.keys(payload)) {
      if (existing.has(key)) {
        filtered[key] = payload[key]
      }
    }

    console.log('VIP save payload keys:', Object.keys(filtered))
    const { error } = await client.from('vip_config').upsert(filtered)
    if (error) console.error('VIP save error:', error)
  } catch (e) {
    console.warn('updateVIPConfig failed:', e)
  }
}

async function getTableColumns(client: any, table: string): Promise<Set<string>> {
  try {
    const { data } = await client.from(table).select('*').limit(1)
    if (data && data.length > 0) {
      return new Set(Object.keys(data[0]))
    }
  } catch {}
  return new Set([
    'tier', 'name', 'min_spend', 'price', 'color', 'image_url', 'bg_url', 'logo_url',
    'medal_url', 'medal_img_url', 'benefits',
    'headwear_url', 'headwear_img_url',
    'entrance_url', 'entrance_img_url',
    'bubble_url', 'bubble_img_url',
  ])
}

// ---- Badges ----

export async function getBadges(): Promise<BadgeConfig[]> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('badges').select('*').order('id')
    return (data ?? []).map((item: any): BadgeConfig => ({
      id: item.id,
      name: item.name || '',
      name_ar: item.name_ar || '',
      name_en: item.name_en || '',
      iconAsset: item.icon_asset || item.iconAsset || '',
      description: item.description || '',
      description_ar: item.description_ar || '',
      description_en: item.description_en || '',
      unlockCondition: item.unlock_condition || item.unlockCondition || '',
      svgaUrl: item.svga_url || item.svgaUrl || undefined,
      imageUrl: item.image_url || item.imageUrl || undefined,
      sortOrder: item.sort_order ?? item.sortOrder ?? 0,
      isActive: item.is_active ?? item.isActive ?? true,
      type: item.type || 'admin',
      levelType: item.level_type || item.levelType || 'wealth',
      levelNumber: item.level_number || item.levelNumber || undefined,
    }))
  } catch (e) {
    console.warn('getBadges failed:', e)
    return []
  }
}

export function subscribeBadges(cb: (badges: BadgeConfig[]) => void) {
  const sub = supabase.channel('badges').on('postgres_changes', { event: '*', schema: 'public', table: 'badges' }, () => {
    getBadges().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

export async function updateBadge(id: string, data: Partial<BadgeConfig>) {
  try {
    const client = getAdminSupabase() || supabase
    await client.from('badges').update(toSnakeCase(data as Record<string, unknown>)).eq('id', id)
  } catch (e) {
    console.warn('updateBadge failed:', e)
    throw e
  }
}

export async function addBadge(id: string, data: BadgeConfig) {
  try {
    const client = getAdminSupabase() || supabase
    const { error } = await client.from('badges').insert({ id, ...toSnakeCase(data as unknown as Record<string, unknown>) })
    if (error) throw error
  } catch (e) {
    console.warn('addBadge failed:', e)
    throw e
  }
}

export async function deleteBadge(id: string) {
  try {
    const client = getAdminSupabase() || supabase
    await client.from('badges').delete().eq('id', id)
  } catch (e) {
    console.warn('deleteBadge failed:', e)
    throw e
  }
}

// ---- Agencies ----

export async function getAgencies(): Promise<AgencyModel[]> {
  try {
    const { data } = await supabase.from('agencies').select('*').order('id')
    return mapList<AgencyModel>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeAgencies(cb: (agencies: AgencyModel[]) => void) {
  const sub = supabase.channel('agencies').on('postgres_changes', { event: '*', schema: 'public', table: 'agencies' }, () => {
    getAgencies().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

// ---- Host Agencies ----

export async function getHostAgencies(): Promise<HostAgencyModel[]> {
  try {
    const { data } = await supabase.from('agencies').select('*').order('name')
    const enriched = await Promise.all((data ?? []).map(async (a: any) => {
      let numericId = '';
      let ownerPhoto = '';
      let ownerName = '';
      try {
        const { data: user } = await supabase.from('users').select('numeric_id, name, photo_url').eq('auth_uid', a.owner_id).maybeSingle();
        if (user) {
          numericId = user.numeric_id || '';
          ownerPhoto = user.photo_url || '';
          ownerName = user.name || '';
          if (!a.name || a.name === '') a.name = user.name || '';
        }
      } catch {}
      return {
        id: a.id,
        name: a.name || ownerName || 'وكالة',
        owner_id: a.owner_id,
        commission_rate: a.commission_rate ?? 0.05,
        specialty: a.agency_type || 'mixed',
        is_active: a.is_activated ?? true,
        member_count: Array.isArray(a.members) ? a.members.length : 0,
        total_diamonds_earned: a.total_earnings ?? 0,
        monthly_diamonds: 0,
        tier: 'bronze',
        photo_url: ownerPhoto,
        country: '',
        is_hall_of_fame: false,
        description: a.description || '',
        phone: '',
        owner_name: numericId || ownerName || a.owner_id?.slice(0, 8) || '—',
        owner_photo: ownerPhoto,
        created_at: a.created_at,
      };
    }));
    return mapList<HostAgencyModel>(enriched)
  } catch { return [] }
}

export async function createHostAgency(name: string, ownerId: string, commissionRate: number, specialty: string): Promise<HostAgencyModel | null> {
  try {
    const { data } = await supabase.from('agencies').insert({
      name, owner_id: ownerId, commission_rate: commissionRate, agency_type: specialty,
      description: '', is_activated: true, members: [], total_earnings: 0, rating: 5,
    }).select('*').single()
    return data as HostAgencyModel
  } catch { return null }
}

export async function updateHostAgency(id: string, updates: Partial<HostAgencyModel>): Promise<boolean> {
  try {
    const dbUpdates: any = {};
    if (updates.name !== undefined) dbUpdates.name = updates.name;
    if (updates.is_active !== undefined) dbUpdates.is_activated = updates.is_active;
    if (updates.description !== undefined) dbUpdates.description = updates.description;
    if (updates.commission_rate !== undefined) dbUpdates.commission_rate = updates.commission_rate;
    if (updates.specialty !== undefined) dbUpdates.agency_type = updates.specialty;
    if (updates.photo_url !== undefined) dbUpdates.photo_url = updates.photo_url;
    await supabase.from('agencies').update(dbUpdates).eq('id', id);
    return true
  } catch { return false }
}

export async function deleteHostAgency(id: string): Promise<boolean> {
  try {
    const BACKEND_URL = 'https://backend-seven-brown-72.vercel.app';

    // 1. Get auth token (service role key or admin password fallback)
    let token = 'ayam-admin';
    try {
      const raw = localStorage.getItem('supabase_admin_config');
      if (raw) {
        const cfg = JSON.parse(raw);
        const key = (cfg.serviceRoleKey || '').trim();
        if (key) token = key;
      }
    } catch {}

    // 2. Call backend to do full cascade delete + auth delete
    const resp = await fetch(`${BACKEND_URL}/api/admin/delete-agency`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify({ agency_id: id }),
    });
    const data = await resp.json();
    if (data.ok === false) {
      console.warn('Backend delete-agency failed:', data);
      return false;
    }
    return true;
  } catch (e) { console.warn('deleteHostAgency error:', e); return false; }
}

export async function openAgencyForUser(targetNumericId: string, agencyType: string = 'shipping', agencyName: string = ''): Promise<{ ok: boolean; error?: string; agency_id?: string; dashboard_email?: string; dashboard_password?: string }> {
  try {
    let token = 'ayam-admin';
    try {
      const raw = localStorage.getItem('supabase_admin_config');
      if (raw) { const cfg = JSON.parse(raw); const key = (cfg.serviceRoleKey || '').trim(); if (key) token = key; }
    } catch {}

    const resp = await fetch(`${BACKEND_URL}/api/admin/open-agency`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ numeric_id: targetNumericId, agency_type: agencyType, agency_name: agencyName }),
    });
    const data = await resp.json();
    if (data.ok === false) return { ok: false, error: data.error || 'فشل فتح الوكالة' };
    return { ok: true, agency_id: data.agency_id, dashboard_email: data.dashboard_email, dashboard_password: data.dashboard_password };
  } catch (e: any) {
    return { ok: false, error: e.message };
  }
}

export async function getCommissionSettings(): Promise<CommissionSettingModel[]> {
  try {
    const { data } = await supabase.from('commission_settings').select('*').order('key')
    return mapList<CommissionSettingModel>(data ?? [])
  } catch { return [] }
}

export async function updateCommissionSetting(id: string, value: number): Promise<boolean> {
  try {
    await supabase.from('commission_settings').update({ value, updated_at: new Date().toISOString() }).eq('id', id)
    return true
  } catch { return false }
}

export async function getHostAgencyMembers(agencyId?: string): Promise<HostAgencyMemberModel[]> {
  try {
    let query = supabase.from('host_agency_members').select('*').order('joined_at')
    if (agencyId) query = query.eq('agency_id', agencyId)
    const { data } = await query
    return mapList<HostAgencyMemberModel>((data ?? []).map((m: any) => ({
      ...m,
      user_name: m.user_id?.slice(0, 8),
    })))
  } catch { return [] }
}

export async function getHostMilestones(): Promise<HostMilestoneModel[]> {
  try {
    const { data } = await supabase.from('host_milestones').select('*').order('sort_order')
    return mapList<HostMilestoneModel>(data ?? [])
  } catch { return [] }
}

export async function updateHostMilestone(id: string, updates: Partial<HostMilestoneModel>): Promise<boolean> {
  try { await supabase.from('host_milestones').update(updates).eq('id', id); return true } catch { return false }
}

export async function createHostMilestone(milestone: Omit<HostMilestoneModel, 'id'>): Promise<boolean> {
  try { await supabase.from('host_milestones').insert(milestone); return true } catch { return false }
}

export async function deleteHostMilestone(id: string): Promise<boolean> {
  try { await supabase.from('host_milestones').delete().eq('id', id); return true } catch { return false }
}

// ---- Agency Join Requests ----

async function adjustAgencyMemberCount(agencyId: string, delta: number) {
  try {
    const { data } = await supabase.from('agencies').select('members').eq('id', agencyId).single()
    const members = Array.isArray((data as any)?.members) ? (data as any).members : []
    const count = members.length + delta
    await supabase.from('agencies').update({ members }).eq('id', agencyId)
  } catch { /* ignore */ }
}

export async function getHostAgencyJoinRequests(status?: string): Promise<AgencyJoinRequestModel[]> {
  try {
    let query = supabase.from('host_agency_join_requests').select('*').order('created_at', { ascending: false })
    if (status) query = query.eq('status', status)
    const { data } = await query
    const enriched = await Promise.all((data ?? []).map(async (r: any) => {
      let agencyName = r.agency_id?.slice(0, 8) || '—';
      try {
        const { data: ag } = await supabase.from('agencies').select('name').eq('id', r.agency_id).maybeSingle();
        if (ag?.name) agencyName = ag.name;
      } catch {}
      return { ...r, user_name: r.user_id?.slice(0, 8), agency_name: agencyName };
    }));
    return mapList<AgencyJoinRequestModel>(enriched)
  } catch { return [] }
}

export async function approveJoinRequest(id: string): Promise<boolean> {
  try {
    const { data: req } = await supabase.from('host_agency_join_requests').select('*').eq('id', id).single()
    if (!req) return false
    await supabase.from('host_agency_members').insert({
      agency_id: req.agency_id, user_id: req.user_id, role: 'host', status: 'active',
    })
    await supabase.from('host_agency_join_requests').update({ status: 'approved' }).eq('id', id)
    await adjustAgencyMemberCount(req.agency_id, 1)
    return true
  } catch { return false }
}

export async function rejectJoinRequest(id: string): Promise<boolean> {
  try { await supabase.from('host_agency_join_requests').update({ status: 'rejected' }).eq('id', id); return true } catch { return false }
}

// ---- Agency Members ----

export async function updateAgencyMemberRole(agencyId: string, userId: string, role: string): Promise<boolean> {
  try {
    await supabase.from('host_agency_members').update({ role }).eq('agency_id', agencyId).eq('user_id', userId)
    return true
  } catch { return false }
}

export async function removeAgencyMember(agencyId: string, userId: string): Promise<boolean> {
  try {
    await supabase.from('host_agency_members').update({ status: 'kicked' }).eq('agency_id', agencyId).eq('user_id', userId)
    await adjustAgencyMemberCount(agencyId, -1)
    return true
  } catch { return false }
}

// ---- Agency Ledger ----

export async function getAgencyLedger(agencyId?: string, limit = 100): Promise<AgencyLedgerEntryModel[]> {
  try {
    let query = supabase.from('agency_diamond_ledger').select('*').order('created_at', { ascending: false }).limit(limit)
    if (agencyId) query = query.eq('agency_id', agencyId)
    const { data } = await query
    const enriched = await Promise.all((data ?? []).map(async (e: any) => {
      let agencyName = e.agency_id?.slice(0, 8) || '—';
      try {
        const { data: ag } = await supabase.from('agencies').select('name').eq('id', e.agency_id).maybeSingle();
        if (ag?.name) agencyName = ag.name;
      } catch {}
      return { ...e, user_name: e.user_id?.slice(0, 8), agency_name: agencyName };
    }));
    return mapList<AgencyLedgerEntryModel>(enriched)
  } catch { return [] }
}

// ---- Withdrawal Requests ----

export async function getWithdrawalRequests(status?: string): Promise<AgencyWithdrawalRequestModel[]> {
  try {
    let query = supabase.from('agency_withdrawal_requests').select('*').order('created_at', { ascending: false })
    if (status) query = query.eq('status', status)
    const { data } = await query
    const enriched = await Promise.all((data ?? []).map(async (w: any) => {
      let agencyName = w.agency_id?.slice(0, 8) || '—';
      try {
        const { data: ag } = await supabase.from('agencies').select('name').eq('id', w.agency_id).maybeSingle();
        if (ag?.name) agencyName = ag.name;
      } catch {}
      return { ...w, user_name: w.user_id?.slice(0, 8), agency_name: agencyName };
    }));
    return mapList<AgencyWithdrawalRequestModel>(enriched)
  } catch { return [] }
}

export async function approveWithdrawal(id: string): Promise<boolean> {
  try {
    await supabase.from('agency_withdrawal_requests').update({ status: 'approved' }).eq('id', id)
    return true
  } catch { return false }
}

export async function rejectWithdrawal(id: string): Promise<boolean> {
  try {
    await supabase.from('agency_withdrawal_requests').update({ status: 'rejected' }).eq('id', id)
    return true
  } catch { return false }
}

// ---- CPs ----

export async function getCPs(): Promise<CPModel[]> {
  try {
    const { data } = await supabase.from('cps').select('*').order('id')
    return mapList<CPModel>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeCPs(cb: (cps: CPModel[]) => void) {
  const sub = supabase.channel('cps').on('postgres_changes', { event: '*', schema: 'public', table: 'cps' }, () => {
    getCPs().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

// ---- BDs ----

export async function getBDs(): Promise<BDModel[]> {
  try {
    const { data } = await supabase.from('bds').select('*').order('id')
    return mapList<BDModel>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeBDs(cb: (bds: BDModel[]) => void) {
  const sub = supabase.channel('bds').on('postgres_changes', { event: '*', schema: 'public', table: 'bds' }, () => {
    getBDs().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

// ---- Gifted Items ----

export async function getGiftedItems(): Promise<GiftedItem[]> {
  try {
    const { data } = await supabase.from('gifted_items').select('*').order('sent_at', { ascending: false })
    return mapList<GiftedItem>(data ?? [])
  } catch {
    return []
  }
}

export function subscribeGiftedItems(cb: (items: GiftedItem[]) => void) {
  const sub = supabase.channel('gifted_items').on('postgres_changes', { event: '*', schema: 'public', table: 'gifted_items' }, () => {
    getGiftedItems().then(cb)
  }).subscribe()
  return () => { try { supabase.removeChannel(sub) } catch {} }
}

export async function sendGiftedItem(uid: string, item: StoreItemModel, sentBy: string, sentByName: string, expiryDays: number): Promise<string> {
  try {
    const id = `gi_${Date.now()}_${Math.random().toString(36).slice(2, 6)}`
    const now = Date.now()
    await supabase.from('gifted_items').insert({
      id,
      uid,
      item_id: item.itemId,
      item_category: item.category,
      item_name: item.name,
      item_icon: item.iconAsset,
      svga_asset: item.svgaAsset,
      video_asset: item.videoAsset,
      sent_by: sentBy,
      sent_by_name: sentByName,
      sent_at: now,
      expires_at: now + expiryDays * 86400000,
    })
    return id
  } catch (e) {
    console.warn('sendGiftedItem failed:', e)
    throw e
  }
}

export async function revokeGiftedItem(id: string) {
  try {
    await supabase.from('gifted_items').delete().eq('id', id)
  } catch (e) {
    console.warn('revokeGiftedItem failed:', e)
  }
}

// ---- Necklaces ----

export async function getNecklaces(): Promise<NecklaceConfig[]> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('necklaces').select('*').order('sort_order')
    return (data ?? []).map((item: any): NecklaceConfig => ({
      id: item.id,
      name: item.name || '',
      name_ar: item.name_ar || '',
      name_en: item.name_en || '',
      description_ar: item.description_ar || '',
      description_en: item.description_en || '',
      svgaUrl: item.svga_url || item.svgaUrl || undefined,
      imageUrl: item.image_url || item.imageUrl || undefined,
      price: item.price || 0,
      sortOrder: item.sort_order ?? item.sortOrder ?? 0,
      isActive: item.is_active ?? item.isActive ?? true,
      type: item.type || 'admin',
      requiredRechargeLevel: item.required_recharge_level || item.requiredRechargeLevel || 0,
    }))
  } catch (e) {
    console.warn('getNecklaces failed:', e)
    return []
  }
}

export async function updateNecklace(id: string, data: Partial<NecklaceConfig>) {
  try {
    const client = getAdminSupabase() || supabase
    const payload = toSnakeCase(data as Record<string, unknown>)
    const { data: existing } = await client.from('necklaces').select('id').eq('id', id).maybeSingle()
    if (existing) {
      await client.from('necklaces').update(payload).eq('id', id)
    } else {
      await client.from('necklaces').upsert({ id, ...payload })
    }
  } catch (e) {
    console.warn('Necklace table not found or error:', e)
    throw e
  }
}

export async function deleteNecklace(id: string) {
  try {
    const client = getAdminSupabase() || supabase
    await client.from('necklaces').delete().eq('id', id)
  } catch (e) {
    console.warn('deleteNecklace failed:', e)
    throw e
  }
}

// ---- User VIPs ----

export async function getUserVIPs(): Promise<UserVIP[]> {
  try {
    const client = getAdminSupabase() || supabase
    const { data: vips } = await client.from('user_vips').select('*, user:users(*)').order('purchased_at', { ascending: false })
    const rows = vips ?? []
    const uids = [...new Set(rows.map(r => (r as any).uid).filter(Boolean))] as string[]
    const usersMap: Record<string, any> = {}
    for (const uid of uids) {
      const { data: u } = await supabase.from('users').select('*').eq('auth_uid', uid).single()
      if (u) usersMap[uid] = u
    }
    const enriched = rows.map((r: any) => ({ ...r, user: usersMap[r.uid] ?? null }))
    return mapList<UserVIP>(enriched)
  } catch {
    return []
  }
}

export async function giftVIP(uid: string, tier: number, giftedBy: string, expiryDays?: number): Promise<void> {
  try {
    const expiresAt = expiryDays ? new Date(Date.now() + expiryDays * 86400000).toISOString() : null
    await supabase.from('user_vips').upsert({
      uid,
      tier,
      purchased_at: new Date().toISOString(),
      expires_at: expiresAt,
      gifted_by: giftedBy,
    })
  } catch (e) {
    console.warn('giftVIP failed:', e)
  }
}

export async function revokeUserVIP(uid: string, tier: number) {
  try {
    await supabase.from('user_vips').delete().eq('uid', uid).eq('tier', tier)
  } catch (e) {
    console.warn('revokeUserVIP failed:', e)
  }
}

// ---- Stats ----

export async function getStats(): Promise<{
  totalUsers: number;
  totalRooms: number;
  totalGifts: number;
  totalRevenue: number;
}> {
  try {
    const { count: totalUsers } = await supabase.from('users').select('*', { count: 'exact', head: true })
    const { count: totalRooms } = await supabase.from('rooms').select('*', { count: 'exact', head: true })
    const { data: gifts } = await supabase.from('gifts').select('value')

    let totalRevenue = 0
    if (gifts) {
      gifts.forEach(g => { totalRevenue += (g.value as number) || 0 })
    }
    return {
      totalUsers: totalUsers ?? 0,
      totalRooms: totalRooms ?? 0,
      totalGifts: gifts?.length ?? 0,
      totalRevenue,
    }
  } catch {
    return {
      totalUsers: 0,
      totalRooms: 0,
      totalGifts: 0,
      totalRevenue: 0,
    }
  }
}

// ---- Admin Management ----

export async function getAdminUsers(): Promise<AdminUser[]> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('admin_users').select('*').order('created_at', { ascending: false })
    return mapList<AdminUser>(data ?? [])
  } catch { return [] }
}

export async function getAdminUser(uid: string): Promise<AdminUser | null> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('admin_users').select('*').eq('uid', uid).maybeSingle()
    return mapSingle<AdminUser>(data)
  } catch { return null }
}

export async function createAdminUser(uid: string, data: Partial<AdminUser>, password: string) {
  const adminClient = getAdminSupabase()
  if (!adminClient) throw new Error('Admin client not available')
  try {
    await adminClient.auth.admin.createUser({ email: data.email, password, email_confirm: true })
  } catch (e: any) {
    if (!e?.message?.includes('already exists') && !e?.message?.includes('already registered')) {
      throw e
    }
  }
  const payload: Record<string, unknown> = {
    uid,
    email: data.email || '',
    display_name: data.displayName || '',
    role: data.role || 'moderator',
    permissions: data.permissions || {},
    photo_url: data.photoUrl || '',
    is_active: data.isActive !== false,
    created_by: data.createdBy || '',
  }
  const { error } = await adminClient.from('admin_users').upsert(payload as any)
  if (error) throw error
}

export async function updateAdminUser(uid: string, data: Partial<AdminUser>) {
  const client = getAdminSupabase() || supabase
  const { error } = await client.from('admin_users').update(toSnakeCase(data as Record<string, unknown>)).eq('uid', uid)
  if (error) throw error
}

export async function deleteAdminUser(uid: string) {
  const adminClient = getAdminSupabase()
  if (!adminClient) throw new Error('Admin client not available')
  await adminClient.from('admin_users').delete().eq('uid', uid)
  try { await adminClient.auth.admin.deleteUser(uid) } catch {}
}

export async function logAdminAction(
  adminUid: string,
  adminName: string,
  action: string,
  targetType: string,
  targetId: string,
  details: Record<string, unknown> = {}
) {
  try {
    const client = getAdminSupabase() || supabase
    await client.from('admin_action_logs').insert({
      admin_uid: adminUid,
      admin_name: adminName,
      action,
      target_type: targetType,
      target_id: targetId,
      details,
    })
  } catch (e) { console.warn('logAdminAction failed:', e) }
}

export async function getAdminActionLogs(limit = 200): Promise<AdminActionLog[]> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('admin_action_logs').select('*').order('created_at', { ascending: false }).limit(limit)
    return mapList<AdminActionLog>(data ?? [])
  } catch { return [] }
}

export async function clearActionLogs(adminUid?: string) {
  try {
    const client = getAdminSupabase() || supabase
    let query = client.from('admin_action_logs').delete()
    if (adminUid) query = query.eq('admin_uid', adminUid)
    await query
  } catch (e) { console.warn('clearActionLogs failed:', e) }
}

export async function getDashboardBans(): Promise<DashboardBan[]> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('dashboard_bans').select('*').order('banned_at', { ascending: false })
    return mapList<DashboardBan>(data ?? [])
  } catch { return [] }
}

export async function banFromDashboard(uid: string, email: string, reason: string, bannedBy: string) {
  const client = getAdminSupabase() || supabase
  const { error } = await client.from('dashboard_bans').upsert({ uid, email, reason, banned_by: bannedBy })
  if (error) throw error
}

export async function unbanFromDashboard(uid: string) {
  const client = getAdminSupabase() || supabase
  await client.from('dashboard_bans').delete().eq('uid', uid)
}

export async function isBannedFromDashboard(uid: string): Promise<boolean> {
  try {
    const client = getAdminSupabase() || supabase
    const { data } = await client.from('dashboard_bans').select('uid').eq('uid', uid).maybeSingle()
    return !!data
  } catch { return false }
}

// ---- App Assets (unified catalog) ----

export async function getAppAssets(options?: {
  type?: string;
  category?: string;
  isActive?: boolean;
  search?: string;
  limit?: number;
  offset?: number;
}): Promise<{ data: AppAssetRecord[]; total: number }> {
  try {
    let query = supabase.from('app_assets').select('*', { count: 'exact' });

    if (options?.type) query = query.eq('type', options.type);
    if (options?.category) query = query.eq('category', options.category);
    if (options?.isActive !== undefined) query = query.eq('is_active', options.isActive);
    if (options?.search) {
      query = query.or(`key.ilike.%${options.search}%,name.ilike.%${options.search}%,local_path.ilike.%${options.search}%`);
    }

    query = query.order('sort_order', { ascending: true }).order('key', { ascending: true });

    if (options?.limit) query = query.range(options.offset || 0, (options.offset || 0) + options.limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;
    return { data: mapList<AppAssetRecord>(data ?? []), total: count ?? 0 };
  } catch (e) {
    console.warn('getAppAssets failed:', e);
    return { data: [], total: 0 };
  }
}

export async function getAppAssetByKey(key: string): Promise<AppAssetRecord | null> {
  try {
    const { data } = await supabase.from('app_assets').select('*').eq('key', key).maybeSingle();
    return mapSingle<AppAssetRecord>(data);
  } catch {
    return null;
  }
}

function getAppAssetsClient() {
  return getAdminSupabase() || supabase;
}

export async function updateAppAsset(id: string, data: Partial<AppAssetRecord>) {
  try {
    const client = getAppAssetsClient();
    const payload = toSnakeCase(data as Record<string, unknown>);
    payload.updated_at = new Date().toISOString();
    await client.from('app_assets').update(payload).eq('id', id);
  } catch (e) {
    console.warn('updateAppAsset failed:', e);
    throw e;
  }
}

export async function upsertAppAsset(data: AppAssetRecord) {
  try {
    const client = getAppAssetsClient();
    const payload = toSnakeCase(data as unknown as Record<string, unknown>);
    await client.from('app_assets').upsert(payload, { onConflict: 'key' });
  } catch (e) {
    console.warn('upsertAppAsset failed:', e);
    throw e;
  }
}

export async function deleteAppAsset(id: string) {
  try {
    const client = getAppAssetsClient();
    await client.from('app_assets').delete().eq('id', id);
  } catch (e) {
    console.warn('deleteAppAsset failed:', e);
    throw e;
  }
}

export async function getAppAssetCategories(): Promise<string[]> {
  try {
    const { data } = await supabase.from('app_assets').select('category').not('category', 'is', null);
    if (!data) return [];
    const cats = new Set<string>(data.map((r: any) => r.category as string).filter(Boolean));
    return Array.from(cats).sort();
  } catch {
    return [];
  }
}

export async function getAppAssetTypes(): Promise<string[]> {
  try {
    const { data } = await supabase.from('app_assets').select('type').not('type', 'is', null);
    if (!data) return [];
    const types = new Set<string>(data.map((r: any) => r.type as string).filter(Boolean));
    return Array.from(types).sort();
  } catch {
    return [];
  }
}

// Migrate existing assetsOverrides from app_config to app_assets.remote_url
export async function migrateAssetOverridesFromConfig(config: Record<string, any>) {
  try {
    const overrides = config.assetsOverrides as Record<string, string> | undefined;
    if (!overrides) return;

    for (const [key, remoteUrl] of Object.entries(overrides)) {
      if (!remoteUrl) continue;
      const existing = await getAppAssetByKey(key);
      if (existing) {
        await updateAppAsset(existing.id, { remoteUrl } as Partial<AppAssetRecord>);
      }
    }
  } catch (e) {
    console.warn('migrateAssetOverridesFromConfig failed:', e);
  }
}

// ---- Gift Categories ----

export async function getGiftCategories(): Promise<import('../types').GiftCategory[]> {
  try {
    const { data } = await supabase.from('gift_categories').select('*').order('sort_order')
    return mapList<import('../types').GiftCategory>(data ?? [])
  } catch { return [] }
}

export async function addGiftCategory(id: string, data: import('../types').GiftCategory) {
  try {
    await supabase.from('gift_categories').upsert({ id, ...toSnakeCase(data as unknown as Record<string, unknown>) })
  } catch (e) {
    console.warn('addGiftCategory failed:', e)
  }
}

export async function updateGiftCategory(id: string, data: Partial<import('../types').GiftCategory>) {
  try {
    await supabase.from('gift_categories').update(toSnakeCase(data as Record<string, unknown>)).eq('id', id)
  } catch (e) {
    console.warn('updateGiftCategory failed:', e)
  }
}

export async function deleteGiftCategory(id: string) {
  try {
    await supabase.from('gift_categories').delete().eq('id', id)
  } catch (e) {
    console.warn('deleteGiftCategory failed:', e)
  }
}

// ---- Gift Banner Configs ----

export async function getGiftBannerConfigs(): Promise<import('../types').GiftBannerConfig[]> {
  try {
    const { data } = await supabase.from('gift_banner_configs').select('*').order('threshold_coins')
    return mapList<import('../types').GiftBannerConfig>(data ?? [])
  } catch { return [] }
}

export async function addGiftBannerConfig(id: string, data: import('../types').GiftBannerConfig) {
  try {
    await supabase.from('gift_banner_configs').upsert({ id, ...toSnakeCase(data as unknown as Record<string, unknown>) })
  } catch (e) {
    console.warn('addGiftBannerConfig failed:', e)
  }
}

export async function updateGiftBannerConfig(id: string, data: Partial<import('../types').GiftBannerConfig>) {
  try {
    await supabase.from('gift_banner_configs').update(toSnakeCase(data as Record<string, unknown>)).eq('id', id)
  } catch (e) {
    console.warn('updateGiftBannerConfig failed:', e)
  }
}

export async function deleteGiftBannerConfig(id: string) {
  try {
    await supabase.from('gift_banner_configs').delete().eq('id', id)
  } catch (e) {
    console.warn('deleteGiftBannerConfig failed:', e)
  }
}

// ---- CP Features ----

export async function getCpGifts(): Promise<CpGiftModel[]> {
  try {
    const { data } = await supabase.from('cp_gifts').select('*').order('sort_order')
    return mapList<CpGiftModel>(data ?? [])
  } catch { return [] }
}

export async function addCpGift(id: string, data: CpGiftModel) {
  try {
    await supabase.from('cp_gifts').upsert({ id, ...toSnakeCase(data as unknown as Record<string, unknown>) })
  } catch (e) { console.warn('addCpGift failed:', e) }
}

export async function updateCpGift(id: string, data: Partial<CpGiftModel>) {
  try {
    await supabase.from('cp_gifts').update(toSnakeCase(data as Record<string, unknown>)).eq('id', id)
  } catch (e) { console.warn('updateCpGift failed:', e) }
}

export async function deleteCpGift(id: string) {
  try { await supabase.from('cp_gifts').delete().eq('id', id) }
  catch (e) { console.warn('deleteCpGift failed:', e) }
}

export async function getCpCars(): Promise<CpCarModel[]> {
  try {
    const { data } = await supabase.from('cp_cars').select('*').order('sort_order')
    return mapList<CpCarModel>(data ?? [])
  } catch { return [] }
}

export async function addCpCar(id: string, data: CpCarModel) {
  try {
    await supabase.from('cp_cars').upsert({ id, ...toSnakeCase(data as unknown as Record<string, unknown>) })
  } catch (e) { console.warn('addCpCar failed:', e) }
}

export async function updateCpCar(id: string, data: Partial<CpCarModel>) {
  try {
    await supabase.from('cp_cars').update(toSnakeCase(data as Record<string, unknown>)).eq('id', id)
  } catch (e) { console.warn('updateCpCar failed:', e) }
}

export async function deleteCpCar(id: string) {
  try { await supabase.from('cp_cars').delete().eq('id', id) }
  catch (e) { console.warn('deleteCpCar failed:', e) }
}

export async function getCpSettings(): Promise<Record<string, string>> {
  try {
    const { data } = await supabase.from('cp_settings').select('key, value')
    const map: Record<string, string> = {}
    for (const row of data ?? []) map[row.key] = row.value
    return map
  } catch { return {} }
}

export async function updateCpSetting(key: string, value: string) {
  try {
    await supabase.from('cp_settings').upsert({ key, value, updated_at: new Date().toISOString() })
  } catch (e) { console.warn('updateCpSetting failed:', e) }
}

// ---- Weekly Sign-In Rewards (7-day daily login) ----

export async function getSigninRewards(): Promise<SigninRewardModel[]> {
  try {
    const { data } = await supabase.from('signin_rewards').select('*').order('day_number')
    return mapList<SigninRewardModel>(data ?? [])
  } catch { return [] }
}

export async function upsertSigninReward(id: string, data: Partial<SigninRewardModel>) {
  try {
    await supabase.from('signin_rewards').upsert({ id, ...toSnakeCase(data as unknown as Record<string, unknown>) })
  } catch (e) { console.warn('upsertSigninReward failed:', e) }
}

export async function updateSigninReward(id: string, data: Partial<SigninRewardModel>) {
  try {
    await supabase.from('signin_rewards').update(toSnakeCase(data as Record<string, unknown>)).eq('id', id)
  } catch (e) { console.warn('updateSigninReward failed:', e) }
}

export async function deleteSigninReward(id: string) {
  try { await supabase.from('signin_rewards').delete().eq('id', id) }
  catch (e) { console.warn('deleteSigninReward failed:', e) }
}

// ---- CP Rank Rewards (via cp_settings JSON fallback — migration pending) ----
// TODO: بعد تشغيل PENDING_MIGRATIONS.sql، أرجع استخدم الجدول مباشرة

const REWARDS_KEY = 'cp_rank_rewards_data';

async function _readRewards(): Promise<CpRankRewardModel[]> {
  try {
    const { data } = await supabase.from('cp_settings').select('value').eq('key', REWARDS_KEY).maybeSingle();
    if (data?.value) return JSON.parse(data.value);
  } catch { /* ignore */ }
  return [];
}

async function _writeRewards(items: CpRankRewardModel[]) {
  await supabase.from('cp_settings').upsert(
    { key: REWARDS_KEY, value: JSON.stringify(items), updated_at: new Date().toISOString() },
    { onConflict: 'key' }
  );
}

export async function getCpRankRewards(period?: string): Promise<CpRankRewardModel[]> {
  try {
    const all = await _readRewards();
    if (period) return all.filter(r => r.period === period).sort((a, b) => a.rank_position - b.rank_position || a.slot_index - b.slot_index);
    return all.sort((a, b) => a.rank_position - b.rank_position || a.slot_index - b.slot_index);
  } catch { return []; }
}

export async function upsertCpRankReward(id: number | null, data: Partial<CpRankRewardModel>) {
  try {
    const all = await _readRewards();
    if (id) {
      const idx = all.findIndex(r => r.id === id);
      if (idx >= 0) all[idx] = { ...all[idx], ...data } as CpRankRewardModel;
    } else {
      const newId = Date.now() + Math.floor(Math.random() * 1000);
      all.push({ id: newId, period: 'weekly', rank_position: 1, slot_index: 0, reward_type: 'frame_svga', label_ar: '', label_en: '', svga_url: '', image_url: '', ...data } as CpRankRewardModel);
    }
    await _writeRewards(all);
  } catch (e) { console.warn('upsertCpRankReward failed:', e); }
}

export async function deleteCpRankReward(id: number) {
  try {
    const all = await _readRewards();
    const filtered = all.filter(r => r.id !== id);
    await _writeRewards(filtered);
  } catch (e) { console.warn('deleteCpRankReward failed:', e); }
}

// ─── CP Auto-Distribution Functions ───

interface ActiveRewardEntry {
  user_uid: string;
  couple_id: string;
  rank: number;
  period: string;
  period_start: string;
  period_end: string;
  rewards: {
    type: string;
    label_ar: string;
    label_en: string;
    svga_url: string;
    image_url: string;
    slot_index: number;
    expires_at: string;
  }[];
  awarded_at: string;
}

export async function getCpRewardConfig(): Promise<{
  period_type: string;
  custom_days: number;
  reward_duration_days: number;
  last_distribution: string;
  next_distribution: string;
  last_period_start: string;
}> {
  try {
    const { data } = await supabase.from('cp_settings').select('value').eq('key', 'cp_reward_period_config').maybeSingle();
    if (data?.value) return JSON.parse(data.value);
  } catch { /* */ }
  return { period_type: 'weekly', custom_days: 0, reward_duration_days: 7, last_distribution: '', next_distribution: '', last_period_start: '' };
}

export async function saveCpRewardConfig(cfg: any) {
  await supabase.from('cp_settings').upsert({ key: 'cp_reward_period_config', value: JSON.stringify(cfg), updated_at: new Date().toISOString() }, { onConflict: 'key' });
}

export async function getActiveRewards(): Promise<ActiveRewardEntry[]> {
  try {
    const { data } = await supabase.from('cp_settings').select('value').eq('key', 'cp_active_rewards').maybeSingle();
    if (data?.value) return JSON.parse(data.value);
  } catch { /* */ }
  return [];
}

export async function getDistributionHistory(): Promise<any[]> {
  try {
    const { data } = await supabase.from('cp_settings').select('value').eq('key', 'cp_distribution_history').maybeSingle();
    if (data?.value) return JSON.parse(data.value);
  } catch { /* */ }
  return [];
}

export async function distributeCpRewards(): Promise<{ success: boolean; message: string; details?: any }> {
  try {
    const { data: cfgData } = await supabase.from('cp_settings').select('value').eq('key', 'cp_reward_period_config').maybeSingle();
    const cfg = cfgData?.value ? JSON.parse(cfgData.value) : { period_type: 'weekly', custom_days: 0, reward_duration_days: 7, last_distribution: '', next_distribution: '', last_period_start: '' };

    const { data: rewardsData } = await supabase.from('cp_settings').select('value').eq('key', 'cp_rank_rewards_data').maybeSingle();
    const rankRewards: any[] = rewardsData?.value ? JSON.parse(rewardsData.value) : [];

    const periodKey = cfg.period_type === 'monthly' ? 'month_score' : 'week_score';
    const periodCol = cfg.period_type === 'monthly' ? 'month_score' : 'week_score';

    const { data: couples, error: couplesError } = await supabase
      .from('cp_couples')
      .select('id, user1_uid, user2_uid, week_score, month_score, total_score')
      .is('ended_at', null)
      .order(periodCol, { ascending: false })
      .limit(3);

    if (couplesError) return { success: false, message: couplesError.message };

    if (!couples || couples.length === 0) {
      const now = new Date().toISOString();
      cfg.last_distribution = now;
      cfg.last_period_start = now;
      cfg.next_distribution = calcNext(cfg);
      await saveCpRewardConfig(cfg);
      return { success: true, message: 'No couples to reward. Period advanced.' };
    }

    const { data: existingActive } = await supabase.from('cp_settings').select('value').eq('key', 'cp_active_rewards').maybeSingle();
    const activeRewards: ActiveRewardEntry[] = existingActive?.value ? JSON.parse(existingActive.value) : [];

    const now = new Date();
    const nowStr = now.toISOString();
    const expiresAt = new Date(now.getTime() + (cfg.reward_duration_days || 7) * 86400000).toISOString();
    const details: any[] = [];

    for (let rank = 1; rank <= Math.min(couples.length, 3); rank++) {
      const couple = couples[rank - 1];
      const slotRewards = rankRewards.filter((r: any) => r.rank_position === rank);

      const entries = slotRewards.map((sr: any) => ({
        type: sr.label_ar?.includes('إطار') || sr.label_ar?.includes('frame') || sr.label_ar?.includes('ايطار') ? 'frame'
          : sr.label_ar?.includes('وسام') || sr.label_ar?.includes('badge') ? 'badge'
          : sr.label_ar?.includes('قلادة') || sr.label_ar?.includes('necklace') ? 'necklace'
          : 'frame',
        label_ar: sr.label_ar || '',
        label_en: sr.label_en || '',
        svga_url: sr.svga_url || '',
        image_url: sr.image_url || '',
        slot_index: sr.slot_index || 0,
        expires_at: expiresAt,
      }));

      for (const uid of [couple.user1_uid, couple.user2_uid]) {
        activeRewards.push({
          user_uid: uid,
          couple_id: couple.id,
          rank,
          period: cfg.period_type || 'weekly',
          period_start: nowStr,
          period_end: expiresAt,
          rewards: entries,
          awarded_at: nowStr,
        });
        await _assignToUser(uid, entries);
      }

      details.push({
        rank,
        user1: couple.user1_uid,
        user2: couple.user2_uid,
        score: couple[periodCol] || 0,
        rewards: slotRewards.length,
      });
    }

    await supabase.from('cp_settings').upsert({ key: 'cp_active_rewards', value: JSON.stringify(activeRewards), updated_at: nowStr }, { onConflict: 'key' });

    await supabase.from('cp_couples').update({ [periodCol]: 0 }).is('ended_at', null);

    cfg.last_distribution = nowStr;
    cfg.last_period_start = nowStr;
    cfg.next_distribution = calcNext(cfg);
    await saveCpRewardConfig(cfg);

    const { data: histData } = await supabase.from('cp_settings').select('value').eq('key', 'cp_distribution_history').maybeSingle();
    const history = histData?.value ? JSON.parse(histData.value) : [];
    history.push({ timestamp: nowStr, details });
    if (history.length > 100) history.splice(0, history.length - 100);
    await supabase.from('cp_settings').upsert({ key: 'cp_distribution_history', value: JSON.stringify(history), updated_at: nowStr }, { onConflict: 'key' });

    return { success: true, message: `تم توزيع المكافآت على ${couples.length} زوج/أزواج`, details };
  } catch (err: any) {
    return { success: false, message: err.message };
  }
}

async function _assignToUser(userUid: string, rewards: ActiveRewardEntry['rewards']) {
  const { data: user } = await supabase.from('users').select('owned_level_frames, owned_level_badges, owned_level_necklaces').eq('auth_uid', userUid).single();
  if (!user) return;

  let frames: any[] = user.owned_level_frames || [];
  let badges: any[] = user.owned_level_badges || [];
  let necklaces: any[] = user.owned_level_necklaces || [];
  let changed = false;

  for (const r of rewards) {
    const entry = { id: `cp_rank_${r.slot_index}_${Date.now()}`, name_ar: r.label_ar, name_en: r.label_en, svga_url: r.svga_url, image_url: r.image_url, source: 'cp_reward', expires_at: r.expires_at };
    if (r.type === 'frame') { frames.push({ ...entry, type: 'frame' }); changed = true; }
    else if (r.type === 'badge') { badges.push({ ...entry, type: 'badge' }); changed = true; }
    else if (r.type === 'necklace') { necklaces.push({ ...entry, type: 'necklace' }); changed = true; }
  }

  if (changed) {
    const updates: any = {};
    if (frames.length > 0) updates.owned_level_frames = frames;
    if (badges.length > 0) updates.owned_level_badges = badges;
    if (necklaces.length > 0) updates.owned_level_necklaces = necklaces;
    await supabase.from('users').update(updates).eq('auth_uid', userUid);
  }
}

export async function expireCpRewards(): Promise<{ removed: number }> {
  try {
    const { data: activeData } = await supabase.from('cp_settings').select('value').eq('key', 'cp_active_rewards').maybeSingle();
    if (!activeData?.value) return { removed: 0 };

    const activeRewards: ActiveRewardEntry[] = JSON.parse(activeData.value);
    const now = new Date();
    const before = activeRewards.length;

    const expiredUids = new Set<string>();
    const valid = activeRewards.filter(ar => {
      if (new Date(ar.period_end) <= now) { expiredUids.add(ar.user_uid); return false; }
      return true;
    });

    await supabase.from('cp_settings').upsert({ key: 'cp_active_rewards', value: JSON.stringify(valid), updated_at: now.toISOString() }, { onConflict: 'key' });

    for (const uid of expiredUids) {
      const { data: user } = await supabase.from('users').select('owned_level_frames, owned_level_badges, owned_level_necklaces, active_frame').eq('auth_uid', uid).single();
      if (!user) continue;
      const updates: any = {};
      for (const col of ['owned_level_frames', 'owned_level_badges', 'owned_level_necklaces'] as const) {
        const items: any[] = (user as any)[col] || [];
        const filtered = items.filter((i: any) => !i.expires_at || new Date(i.expires_at) > now);
        if (filtered.length !== items.length) updates[col] = filtered;
      }
      if (Object.keys(updates).length > 0) {
        if (user.active_frame && !(updates.owned_level_frames || user.owned_level_frames).some((f: any) => f.id === user.active_frame)) {
          updates.active_frame = null;
        }
        await supabase.from('users').update(updates).eq('auth_uid', uid);
      }
    }

    return { removed: before - valid.length };
  } catch (e) {
    return { removed: 0 };
  }
}

function calcNext(cfg: any): string {
  const now = new Date();
  const next = new Date(now);
  switch (cfg.period_type) {
    case 'daily': next.setDate(next.getDate() + 1); next.setHours(0, 0, 0, 0); break;
    case 'weekly': next.setDate(next.getDate() + (7 - next.getDay())); next.setHours(0, 0, 0, 0); break;
    case 'monthly': next.setMonth(next.getMonth() + 1); next.setDate(1); next.setHours(0, 0, 0, 0); break;
    default: next.setDate(next.getDate() + (cfg.custom_days > 0 ? cfg.custom_days : 7)); next.setHours(0, 0, 0, 0); break;
  }
  return next.toISOString();
}

export { supabase };
