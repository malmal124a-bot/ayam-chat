export interface UserModel {
  uid: string;
  customId: string;
  name: string;
  email: string;
  photoUrl: string;
  coins: number;
  diamonds: number;
  gender: string;
  activeFrame: string | null;
  activeBubble: string | null;
  activeEntrance: string | null;
  activeCar: string | null;
  activeCover: string | null;
  activeNecklace: string | null;
  ownedItems: string[];
  ownedBadges: string[];
  ownedNecklaces: string[];
  hostedRoomId: string | null;
  followedRooms: string[];
  totalGiftsReceived: number;
  level: number;
  experience: number;
  followers: number;
  following: number;
  visitors: number;
  charm: number;
  wealthLevel: number;
  wealthExp: number;
  rechargeLevel: number;
  rechargeExp: number;
  gemsLevel: number;
  gemsExp: number;
  ownedLevelFrames: string[];
  ownedLevelBadges: string[];
  phone: string;
  lastIp: string;
  banned: boolean;
  banReason: string;
}

export interface RoomModel {
  roomId: string;
  name: string;
  description: string;
  roomPhotoUrl: string;
  hostUid: string;
  hostName: string;
  hostPhotoUrl: string;
  memberCount: number;
  maxMembers: number;
  isLocked: boolean;
  category: string;
  createdAt: number;
  password: string;
  seatCount: number;
  totalGifts: number;
  hotValue: number;
}

export interface GiftModel {
  id: string;
  name: string;
  value: number;
  iconAsset: string;
  animationAsset: string | null;
  isVap: boolean;
  isLucky: boolean;
  isStar: boolean;
  isMusic: boolean;
  packageCount: number;
  sortOrder: number;
  nameKey?: string;
  photoKey?: string;
  defaultImage?: string;
  wealthXp?: number;
  gemsXp?: number;
  categoryId?: string;
  isCpGift?: boolean;
  cpGiftDurationHours?: number;
}

export interface SentGiftModel {
  id: string;
  giftId: string;
  senderId: string;
  senderName: string;
  senderPhotoUrl: string | null;
  receiverId: string;
  receiverName: string;
  roomId: string;
  value: number;
  count: number;
  timestamp: number;
}

export interface StoreItemModel {
  itemId: string;
  name: string;
  category: 'frame' | 'bubble' | 'entrance' | 'car';
  iconAsset: string;
  price: number;
  svgaAsset: string | null;
  videoAsset: string | null;
  isPremium: boolean;
  nameKey?: string;
  photoKey?: string;
  defaultImage?: string;
}

export interface UnionModel {
  id: string;
  name: string;
  description: string;
  creatorId: string;
  creatorName: string;
  logoUrl: string;
  memberCount: number;
  level: number;
  createdAt: number;
}

export interface ConversationModel {
  id: string;
  name: string;
  avatar: string;
  lastMessage: string;
  lastMessageTime: number;
  unreadCount: number;
}

export interface BugReport {
  id: string;
  userId?: string;
  message: string;
  stackTrace?: string;
  timestamp: number;
  deviceInfo?: string;
  appVersion?: string;
}

export interface AdminUser {
  uid: string;
  email: string;
  role: 'superadmin' | 'admin' | 'moderator';
  displayName: string;
  permissions: Record<string, boolean>;
  photoUrl: string;
  isActive: boolean;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

export interface AdminActionLog {
  id: string;
  adminUid: string;
  adminName: string;
  action: string;
  targetType: string;
  targetId: string;
  details: Record<string, unknown>;
  createdAt: string;
}

export interface DashboardBan {
  uid: string;
  email: string;
  reason: string;
  bannedBy: string;
  bannedAt: string;
}

export interface AppConfig {
  primaryBg?: string;
  textPrimary?: string;
  textSecondary?: string;
  goldColor?: string;
  appName?: string;
  splashGifUrl?: string;
  audioProvider?: string;
  maintenanceMode?: boolean;
  fontFamily?: string;
  borderRadius?: number;
  buttonColor?: string;
  buttonTextColor?: string;
  headerColor?: string;
  tabBarColor?: string;
  screenTitles?: Record<string, string>;
  banners?: BannerConfig[];
  levelIcons?: Record<string, string>;
  giftUploadPath?: string;
  storeUploadPath?: string;
  assetsOverrides?: Record<string, string>;
  assetSizes?: Record<string, AssetSizeOverride>;
  cloudinary?: { cloudName?: string; apiKey?: string; apiSecret?: string };
  coinsPerRechargeXp?: number;
  diamondToCoinRate?: number;

  // VIP card colors
  vipCardBgColor?: string;
  vipCardBorderColor?: string;

  // VIP image overrides
  vipCardBgImgUrl?: string;
  vipPurchaseBarImgUrl?: string;
  vipCoinImgUrl?: string;
  vipBuyBtnImgUrl?: string;

  // Room theme gradients (each is [color1, color2])
  roomGradients?: Record<string, [string, string]>;

  // Chat bubble colors
  chatColors?: {
    bubbleSelf?: string;
    bubbleOther?: string;
    bubbleSelfBorder?: string;
    bubbleOtherBorder?: string;
    bubbleSelfText?: string;
    bubbleOtherText?: string;
  };

  // Ranking screen config
  rankConfig?: Record<string, string>;

  // Gift box (gift sheet) customization — read by the app's gift sheet
  giftBoxBgColor?: string;
  giftBoxRadius?: string | number;
  giftBoxBgImage?: string;
  giftTileBgColor?: string;
  giftTileSelectedColor?: string;
  giftTileRadius?: string | number;
  giftTileBgImage?: string;
  giftTileBorderColor?: string;
  giftTileSelectedBorderColor?: string;

  // Icon overrides (Icons.xxx name → URL)
  iconOverrides?: Record<string, string>;
}

export interface AppAsset {
  key: string;
  name: string;
  category: string;
  subcategory: string;
  localPath: string;
  defaultWidth?: number;
  defaultHeight?: number;
}

export interface AppAssetRecord {
  id: string;
  key: string;
  name: string;
  type: AppAssetType;
  category: string;
  subcategory: string;
  localPath: string;
  remoteUrl: string | null;
  defaultValue: string | null;
  mimeType: string | null;
  fileSize: number;
  width: number | null;
  height: number | null;
  sortOrder: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export type AppAssetType = 'image' | 'svga' | 'vap' | 'lottie' | 'mp4' | 'mp3' | 'wav' | 'gif' | 'color' | 'text' | 'font' | 'json' | 'css' | 'js' | 'html' | 'xml' | 'other';

export interface AssetSizeOverride {
  width?: number;
  height?: number;
}

export interface BannerConfig {
  id: string;
  imageUrl: string;
  linkUrl?: string;
  title?: string;
  sortOrder: number;
  active: boolean;
  createdAt: number;
}

export interface NotificationPayload {
  id: string;
  title: string;
  body: string;
  targetUsers: 'all' | 'specific' | 'level';
  targetValue?: string;
  sentAt: number;
  status: 'draft' | 'sent';
}

export interface LevelConfig {
  level: number;
  minExp: number;
  maxExp: number;
  title: string;
  type: 'wealth' | 'recharge' | 'gems';
  imageUrl?: string;
  frameUrl?: string;
  badgeUrl?: string;
  rewards: { coins?: number; diamonds?: number; frame?: string; badge?: string };
  progressColor?: string;
  boxImageUrl?: string;
}

export interface LevelType {
  id: 'wealth' | 'recharge' | 'gems';
  name: string;
  icon: string;
  color: string;
}

export interface VIPConfig {
  tier: number;
  name: string;
  minSpend: number;
  price?: number;
  color: string;
  imageUrl?: string;
  bgUrl?: string;
  logoUrl?: string;
  medalUrl?: string;
  medalImgUrl?: string;
  medalName?: string;
  headwearUrl?: string;
  headwearImgUrl?: string;
  headwearName?: string;
  headwearKey?: string;
  headwearCardBg?: string;
  entranceUrl?: string;
  entranceImgUrl?: string;
  entranceName?: string;
  entranceKey?: string;
  entranceCardBg?: string;
  bubbleUrl?: string;
  bubbleImgUrl?: string;
  bubbleName?: string;
  bubbleKey?: string;
  bubbleCardBg?: string;
  necklaceUrl?: string;
  necklaceImgUrl?: string;
  necklaceName?: string;
  necklaceKey?: string;
  necklaceCardBg?: string;
  carUrl?: string;
  carImgUrl?: string;
  carName?: string;
  carKey?: string;
  carCardBg?: string;
  coverUrl?: string;
  coverImgUrl?: string;
  coverName?: string;
  coverKey?: string;
  coverCardBg?: string;
  buyBtnImgUrl?: string;
  coinImgUrl?: string;
  purchaseBarBg?: string;
  cardBgUrl?: string;
  cardRadius?: number;
  benefits: string[];
  accessories?: any[];
  items?: VIPBenefitItem[];
  additionalFiles?: VIPAdditionalFile[];
}

export interface VIPAdditionalFile {
  name: string;
  url: string;
  type: string;
  key?: string;
}

export interface VIPBenefitItem {
  name: string;
  img?: string;
  svgaUrl?: string;
  key?: string;
  peculiarityId?: number;
  title?: string;
}

export interface UserVIP {
  uid: string;
  tier: number;
  purchased_at: string;
  expires_at: string | null;
  gifted_by: string | null;
  user?: UserModel;
}

export interface BadgeConfig {
  id: string;
  name: string;
  name_ar?: string;
  name_en?: string;
  iconAsset: string;
  description: string;
  description_ar?: string;
  description_en?: string;
  unlockCondition: string;
  svgaUrl?: string;
  imageUrl?: string;
  sortOrder?: number;
  isActive?: boolean;
  type?: 'admin' | 'level'; // Admin gift or Level reward
  levelType?: 'wealth' | 'recharge' | 'gems'; // Which level type?
  levelNumber?: number; // Which level number?
}

export interface NecklaceConfig {
  id: string;
  name: string;
  name_ar?: string;
  name_en?: string;
  description_ar?: string;
  description_en?: string;
  svgaUrl?: string;
  imageUrl?: string;
  price: number;
  sortOrder: number;
  createdAt?: string;
  isActive?: boolean;
  type?: 'event' | 'admin' | 'recharge';
  requiredRechargeLevel?: number;
}

export interface ScreenVisualConfig {
  screen: 'agency' | 'badges' | 'necklaces' | 'rank' | 'checkbox';
  backgroundImage?: string;
  headerBgColor?: string;
  headerTextColor?: string;
  cardBgColor?: string;
  cardBorderColor?: string;
  textColor?: string;
  subTextColor?: string;
  accentColor?: string;
  checkboxCheckedImage?: string;
  checkboxUncheckedImage?: string;
  customImages?: Record<string, string>;
  [key: string]: unknown;
}

export interface AgencyModel {
  id: string;
  name: string;
  ownerId: string;
  ownerName: string;
  memberCount: number;
  totalRevenue: number;
  commissionRate: number;
  createdAt: number;
}

export interface HostAgencyModel {
  id: string;
  name: string;
  owner_id: string;
  commission_rate: number;
  specialty: 'singing' | 'gaming' | 'talk' | 'mixed';
  is_active: boolean;
  member_count: number;
  total_diamonds_earned: number;
  monthly_diamonds: number;
  tier?: 'bronze' | 'silver' | 'gold' | 'platinum' | 'diamond';
  photo_url?: string;
  country?: string;
  is_hall_of_fame?: boolean;
  description?: string;
  phone?: string;
  owner_name?: string;
  created_at: string;
}

export interface HostAgencyMemberModel {
  id: string;
  agency_id: string;
  user_id: string;
  role: 'owner' | 'supervisor' | 'host';
  status: 'active' | 'pending' | 'rejected' | 'kicked' | 'left';
  diamonds_earned_monthly?: number;
  diamonds_earned_cumulative?: number;
  diamonds_balance?: number;
  trial_ends_at?: string;
  user_name?: string;
  joined_at: string;
}

export interface CommissionSettingModel {
  id: string;
  key: string;
  value: number;
  description: string | null;
  updated_at: string;
  updated_by: string | null;
}

export interface HostMilestoneModel {
  id: string;
  title: string;
  target_diamonds: number;
  reward_type: 'gold' | 'diamonds' | 'vip_days' | 'badge' | 'gift_item';
  reward_value: number;
  reward_item_id: string | null;
  period_type: 'monthly' | 'weekly' | 'all_time';
  is_active: boolean;
  sort_order: number;
}

export interface AgencyJoinRequestModel {
  id: string;
  agency_id: string;
  user_id: string;
  status: 'pending' | 'approved' | 'rejected';
  user_name?: string;
  agency_name?: string;
  created_at: string;
}

export interface AgencyLedgerEntryModel {
  id: string;
  user_id: string;
  agency_id: string;
  txn_type: 'earned' | 'exchange' | 'withdrawal' | 'transfer' | 'penalty' | 'bonus';
  amount: number;
  direction: 'in' | 'out';
  balance_after: number;
  note?: string;
  user_name?: string;
  agency_name?: string;
  created_at: string;
}

export interface AgencyWithdrawalRequestModel {
  id: string;
  user_id: string;
  agency_id: string;
  amount: number;
  status: 'pending' | 'approved' | 'rejected';
  payment_method?: string;
  payment_details?: string;
  user_name?: string;
  agency_name?: string;
  created_at: string;
}
export interface AgencyOpenRequestModel {
  id: string;
  requested_by: string;
  agency_name: string;
  phone?: string;
  agency_id?: string;
  photo_url?: string;
  id_card_url?: string;
  agency_type?: string;
  status: 'pending' | 'approved' | 'rejected';
  note?: string;
  reviewed_by?: string;
  reviewed_at?: string;
  created_at: string;
  updated_at?: string;
  requester?: {
    numeric_id?: string;
    name?: string;
    photo_url?: string;
  };
}

export interface AgencyDetailModel extends HostAgencyModel {
  owner_name: string;
  owner_photo?: string;
  active_members: number;
  pending_requests: number;
  total_earned: number;
  monthly_earned: number;
  withdrawal_pending: number;
}

export interface CPModel {
  id: string;
  name: string;
  contactName: string;
  contactEmail: string;
  revenueShare: number;
  contentCount: number;
  status: 'active' | 'suspended';
  createdAt: number;
}

export interface BDModel {
  id: string;
  name: string;
  region: string;
  contactName: string;
  contactEmail: string;
  partnerSince: number;
  dealValue: number;
  status: 'active' | 'inactive';
}

export interface GiftCategory {
  id: string;
  name: string;
  sortOrder: number;
  createdAt?: number;
}

export interface GiftBannerConfig {
  id: string;
  categoryId?: string;
  thresholdCoins: number;
  svgaUrl: string;
  userRKey: string;
  userLKey: string;
  numberKey: string;
  giftKey: string;
  isActive: boolean;
  createdAt?: number;
}

export interface CpGiftModel {
  id: string;
  name: string;
  nameAr: string;
  nameEn?: string;
  iconUrl: string;
  svgaUrl?: string;
  value: number;
  sortOrder: number;
  isActive: boolean;
  createdAt?: string;
}

export interface CpCarModel {
  id: string;
  name: string;
  nameAr: string;
  nameEn?: string;
  svgaUrl: string;
  thumbnailUrl?: string;
  sortOrder: number;
  isActive: boolean;
  createdAt?: string;
}

export interface CpRankRewardModel {
  id: number;
  period: string;
  rank_position: number;
  slot_index: number;
  reward_type: string;
  label_ar: string;
  label_en: string;
  svga_url: string;
  image_url: string;
}

export interface SigninRewardModel {
  id: string;
  day_number: number;
  label_ar: string;
  label_en: string;
  icon_url: string;
  svga_url?: string;
  value: number;
  value_type: 'coins' | 'diamonds' | 'xp' | 'gift' | 'custom';
  gift_id?: string;
  is_double: boolean;
  is_active: boolean;
  created_at?: string;
}

export interface CpEventSettings {
  weeklyResetDay: string;
  eventStartDate: string;
  eventDurationDays: number;
  prize1Name: string;
  prize1Svga: string;
  prize1Image: string;
  prize1Coins: number;
  prize2Name: string;
  prize2Svga: string;
  prize2Image: string;
  prize2Coins: number;
  prize3Name: string;
  prize3Svga: string;
  prize3Image: string;
  prize3Coins: number;
  minScoreForPrize: number;
  prizeNotification: string;
}

export interface GiftedItem {
  id: string;
  uid: string;
  itemId: string;
  itemCategory: string;
  itemName: string;
  itemIcon: string;
  svgaAsset: string | null;
  videoAsset: string | null;
  sentBy: string;
  sentByName: string;
  sentAt: number;
  expiresAt: number;
}
