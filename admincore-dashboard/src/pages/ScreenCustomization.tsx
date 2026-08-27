import { useEffect, useState, useContext } from 'react';
import { I18nContext } from '../lib/i18n';
import { getAppConfig, updateAppConfig } from '../lib/db';
import { uploadAppAsset } from '../lib/storage';
import { Save, RotateCcw, Upload, Check, Image, Type, Layers } from 'lucide-react';
import { to6Hex } from '../lib/colors';

interface ScreenVisuals {
  agency: Record<string, string>;
  badges: Record<string, string>;
  necklaces: Record<string, string>;
  rank: Record<string, string>;
  checkbox: Record<string, string>;
  store: Record<string, string>;
  backpack: Record<string, string>;
  wallet: Record<string, string>;
  level: Record<string, string>;
  cp: Record<string, string>;
  signin: Record<string, string>;
}

const defaultVisuals: ScreenVisuals = {
  agency: {
    backgroundImage: '',
    headerBgColor: '#1a1a2e',
    headerTextColor: '#ffffff',
    cardBgColor: '#16213e',
    cardBorderColor: '#0f3460',
    textColor: '#ffffff',
    subTextColor: '#a0a0b0',
    accentColor: '#e94560',
    checkboxCheckedImage: '',
    checkboxUncheckedImage: '',
    tabActiveColor: '#e94560',
    tabInactiveColor: '#555',
    coinIcon: '',
    diamondIcon: '',
    rankIcon: '',
    memberAvatarBorder: '#e94560',
  },
  badges: {
    backgroundImage: '',
    headerBgColor: '#1a1a2e',
    headerBgImage: '',
    headerTextColor: '#ffffff',
    headerTextImage: '',
    cardBgColor: '#16213e',
    cardBgImage: '',
    cardBorderColor: '#0f3460',
    cardBorderImage: '',
    textColor: '#ffffff',
    textImage: '',
    subTextColor: '#a0a0b0',
    subTextImage: '',
    accentColor: '#f0c724',
    accentImage: '',
    sectionBgColor: '#0d0d12',
    sectionBgImage: '',
    badgeBorderColor: '#f0c724',
    badgeBorderImage: '',
    badgeBgColor: '#1a1a2e',
    badgeBgImage: '',
    lockImage: '',
  },
  necklaces: {
    backgroundImage: '',
    headerBgColor: '#1a1a2e',
    headerBgImage: '',
    headerTextColor: '#ffffff',
    headerTextImage: '',
    cardBgColor: '#16213e',
    cardBgImage: '',
    cardBorderColor: '#0f3460',
    cardBorderImage: '',
    textColor: '#ffffff',
    textImage: '',
    subTextColor: '#a0a0b0',
    subTextImage: '',
    accentColor: '#e94560',
    accentImage: '',
    sectionBgColor: '#0d0d12',
    sectionBgImage: '',
    necklaceBorderColor: '#e94560',
    necklaceBorderImage: '',
    necklaceBgColor: '#1a1a2e',
    necklaceBgImage: '',
    lockImage: '',
  },
  rank: {
    backgroundImage: '',
    headerBgColor: '#1a1a2e',
    headerBgImage: '',
    headerTextColor: '#ffffff',
    headerTextImage: '',
    cardBgColor: '#16213e',
    cardBgImage: '',
    cardBorderColor: '#0f3460',
    cardBorderImage: '',
    textColor: '#ffffff',
    textImage: '',
    subTextColor: '#a0a0b0',
    subTextImage: '',
    accentColor: '#ffd700',
    accentImage: '',
    goldColor: '#FFD700',
    silverColor: '#C0C0C0',
    bronzeColor: '#CD7F32',
    pointsColor: '#FFD700',
    trophyIcon: 'emoji_events',
    crownIcon: '',
    rankBgImage: '',
  },
  checkbox: {
    checkedImage: '',
    uncheckedImage: '',
  },
  store: {
    backgroundImage: '',
    headerBgColor: '#1a1a2e',
    headerBgImage: '',
    headerTextColor: '#ffffff',
    headerTextImage: '',
    cardBgColor: '#16151A',
    cardBgImage: '',
    cardBorderColor: '#ffffff',
    cardBorderImage: '',
    textColor: '#ffffff',
    textImage: '',
    subTextColor: '#9BA1B6',
    subTextImage: '',
    accentColor: '#DE880F',
    accentImage: '',
    lockImage: '',
    sectionBgColor: '#0d0d12',
    sectionBgImage: '',
  },
  backpack: {
    backgroundImage: '',
    headerBgColor: '#1a1a2e',
    headerBgImage: '',
    headerTextColor: '#ffffff',
    headerTextImage: '',
    cardBgColor: '#16151A',
    cardBgImage: '',
    cardBorderColor: '#ffffff',
    cardBorderImage: '',
    textColor: '#ffffff',
    textImage: '',
    subTextColor: '#9BA1B6',
    subTextImage: '',
    accentColor: '#DE880F',
    accentImage: '',
    lockImage: '',
    sectionBgColor: '#0d0d12',
    sectionBgImage: '',
  },
  wallet: {
    backgroundImage: '',
    headerBgColor: '#1a1a2e',
    headerBgImage: '',
    headerTextColor: '#ffffff',
    headerTextImage: '',
    cardBgColor: '#16151A',
    cardBgImage: '',
    cardBorderColor: '#ffffff',
    cardBorderImage: '',
    textColor: '#ffffff',
    textImage: '',
    subTextColor: '#9BA1B6',
    subTextImage: '',
    accentColor: '#DE880F',
    accentImage: '',
    lockImage: '',
    sectionBgColor: '#0d0d12',
    sectionBgImage: '',
  },
  level: {
    backgroundImage: '',
    headerBgColor: '#1a1a2e',
    headerBgImage: '',
    headerTextColor: '#ffffff',
    headerTextImage: '',
    cardBgColor: '#1a1a2e',
    cardBgImage: '',
    cardBorderColor: '#0f3460',
    cardBorderImage: '',
    textColor: '#ffffff',
    textImage: '',
    subTextColor: '#a0a0b0',
    subTextImage: '',
    accentColor: '#f0c724',
    accentImage: '',
    lockImage: '',
    sectionBgColor: '#0d0d12',
    sectionBgImage: '',
  },
  cp: {
    backgroundImage: '',
    headerBgColor: '#E91E8C',
    headerBgImage: '',
    headerTextColor: '#ffffff',
    headerTextImage: '',
    cardBgColor: '#ffffff',
    cardBgImage: '',
    cardBorderColor: '#E91E8C',
    cardBorderImage: '',
    textColor: '#5D1A3A',
    textImage: '',
    subTextColor: '#a0a0b0',
    subTextImage: '',
    accentColor: '#FF4FA3',
    accentImage: '',
    primaryColor: '#E91E8C',
    gradientStart: '#E91E8C',
    gradientEnd: '#FF4FA3',
    goldColor: '#FFD700',
    silverColor: '#C0C0C0',
    bronzeColor: '#CD7F32',
    sectionBgColor: '#FCE4EC',
    sectionBgImage: '',
    lockImage: '',
    fullScreenBg: '',
    cabinBg: '',
    cabinDefaultBg: '',
    leftFrame: '',
    rightFrame: '',
    heartImage: '',
    noCpHeartSvg: '',
    tokenBg: '',
    mineBg: '',
    countdownDaySvg: '',
    countdownHourSvg: '',
    countdownMinSvg: '',
    countdownSecSvg: '',
    rankTagGoldSvg: '',
    rankTagSilverSvg: '',
    rankTagBronzeSvg: '',
    historyCardSvg: '',
    giftsBannerSvg: '',
    rankBgImage: '',
    tabActiveColor: '#E91E8C',
    tabInactiveColor: '#ffffff',
    tabBgColor: '#E91E8C',
    tabBgImage: '',
    countdownTextColor: '#E91E8C',
    countdownLabelColor: '#000000',
    invitationBgColor: '#ffffff',
    invitationBgImage: '',
    buttonColor: '#E91E8C',
    buttonTextColor: '#ffffff',
    buttonOutlineColor: '#E91E8C',
    giftButtonGradientStart: '#FF4FA3',
    giftButtonGradientEnd: '#E91E8C',
    sectionHeaderColor: '#E91E8C',
    avatarBorderColor: '#E91E8C',
    scoreTokenColor: '#FFD700',
    scoreTokenLabelColor: '#ffffff',
    scoreTokenBgColor: '#E91E8C',
    podiumBgStart: '#FCE4EC',
    podiumBgEnd: '#ffffff',
    periodButtonActiveBg: '#E91E8C',
    periodButtonActiveText: '#ffffff',
    periodButtonInactiveBg: '#0000000D',
    periodButtonInactiveText: '#00000073',
    rankItemBg: '#ffffff',
    rankShadowColor: '#E91E8C',
    myRankPillGradientStart: '#FF4FA3',
    myRankPillGradientEnd: '#E91E8C',
    myRankPillText: '#ffffff',
    myRankScoreColor: '#FFD700',
    // Profile CP card colors (user_profile_screen CP section)
    profileDaysBadgeBg: '#260105',
    profileDaysBadgeBorder: '#81050f',
    profileDaysBadgeBg2: '#a40b25',
    profileDaysBadgeBorder2: '#e73d46',
    profileDaysText: '#b3b3b3',
    profileDaysTogetherText: '#cccccc',
    profileLevelGradientStart: '#fff19f',
    profileLevelGradientEnd: '#ffb565',
    profileHeartIcon: 'assets/cp/ic_cp_val_heart.png',
    profileLevelBg: 'assets/cp/ic_rs_lv_bg_cp.png',
    profileNameFrame: 'assets/cp/ic_send_invitation_name_frame.png',
    profileTopBgSvga: 'assets/svga/relationship_act_top_bg.svga',
  },
  signin: {
    backgroundImage: '',
    headerBgColor: '#2e0d15',
    headerBgImage: '',
    headerTextColor: '#FFD700',
    headerTextImage: '',
    cardBgColor: '#3d1520',
    cardBgImage: '',
    cardBorderColor: '#DE880F',
    cardBorderImage: '',
    textColor: '#ffffff',
    textImage: '',
    subTextColor: '#B8A88A',
    subTextImage: '',
    accentColor: '#FFD700',
    accentImage: '',
    goldColor: '#FFD700',
    buttonColor: '#DE880F',
    buttonTextColor: '#ffffff',
    buttonGradientStart: '#FFD700',
    buttonGradientEnd: '#DE880F',
    dayBgColor: '#3d1520',
    dayActiveColor: '#5a2030',
    dayClaimedColor: '#1a4a1a',
    dayLockedColor: '#2a1018',
    dayBorderColor: '#DE880F',
    dayClaimedBorderColor: '#4CAF50',
    checkmarkImage: '',
    lockImage: '',
    streakIcon: '',
    topBgSvga: '',
    buttonImage: '',
    sectionBgColor: '#2e0d15',
    sectionBgImage: '',
  },
};

const screenTabs = ['colors', 'agency', 'badges', 'necklaces', 'rank', 'checkbox', 'store', 'backpack', 'wallet', 'level', 'cp', 'signin'] as const;

const screenLabels: Record<string, Record<string, string>> = {
  colors: { ar: '🎨 ألوان التطبيق', en: '🎨 App Colors' },
  agency: { ar: 'شاشة الوكالة', en: 'Agency Screen' },
  badges: { ar: 'شاشة الشارات', en: 'Badges Screen' },
  necklaces: { ar: 'شاشة القلائد', en: 'Necklaces Screen' },
  rank: { ar: 'شاشة الترتيب', en: 'Rank Screen' },
  checkbox: { ar: 'صور الاختيار', en: 'Checkbox Images' },
  store: { ar: 'شاشة المتجر', en: 'Store Screen' },
  backpack: { ar: 'شاشة الحقيبة', en: 'Backpack Screen' },
  wallet: { ar: 'شاشة المحفظة', en: 'Wallet Screen' },
  level: { ar: 'شاشة المستويات', en: 'Levels Screen' },
  cp: { ar: '💑 شاشة CP', en: '💑 CP Screen' },
  signin: { ar: '📅 تسجيل الدخول اليومي', en: '📅 Weekly Sign-In' },
};

const fieldLabels: Record<string, Record<string, string>> = {
  backgroundImage: { ar: 'صورة الخلفية', en: 'Background Image' },
  headerBgColor: { ar: 'لون خلفية الرأس', en: 'Header Background' },
  headerBgImage: { ar: 'صورة خلفية الرأس', en: 'Header Background Image' },
  headerTextColor: { ar: 'لون نص الرأس', en: 'Header Text Color' },
  headerTextImage: { ar: 'صورة نص الرأس', en: 'Header Text Image' },
  cardBgColor: { ar: 'لون خلفية البطاقة', en: 'Card Background' },
  cardBgImage: { ar: 'صورة خلفية البطاقة', en: 'Card Background Image' },
  cardBorderColor: { ar: 'لون حدود البطاقة', en: 'Card Border Color' },
  cardBorderImage: { ar: 'صورة حدود البطاقة', en: 'Card Border Image' },
  textColor: { ar: 'لون النص', en: 'Text Color' },
  textImage: { ar: 'صورة النص', en: 'Text Image' },
  subTextColor: { ar: 'لون النص الثانوي', en: 'Sub Text Color' },
  subTextImage: { ar: 'صورة النص الثانوي', en: 'Sub Text Image' },
  accentColor: { ar: 'لون التمييز', en: 'Accent Color' },
  accentImage: { ar: 'صورة التمييز', en: 'Accent Image' },
  checkboxCheckedImage: { ar: 'صورة الاختيار (محدد)', en: 'Checked Image' },
  checkboxUncheckedImage: { ar: 'صورة الاختيار (غير محدد)', en: 'Unchecked Image' },
  tabActiveColor: { ar: 'لون التبويب النشط', en: 'Tab Active Color' },
  tabInactiveColor: { ar: 'لون التبويب غير النشط', en: 'Tab Inactive Color' },
  coinIcon: { ar: 'أيقونة العملة', en: 'Coin Icon' },
  diamondIcon: { ar: 'أيقونة الماس', en: 'Diamond Icon' },
  rankIcon: { ar: 'أيقونة الترتيب', en: 'Rank Icon' },
  memberAvatarBorder: { ar: 'حدود الصورة الرمزية', en: 'Avatar Border' },
  sectionBgColor: { ar: 'لون خلفية القسم', en: 'Section Background' },
  sectionBgImage: { ar: 'صورة خلفية القسم', en: 'Section Background Image' },
  badgeBorderColor: { ar: 'لون حدود الشارة', en: 'Badge Border Color' },
  badgeBorderImage: { ar: 'صورة حدود الشارة', en: 'Badge Border Image' },
  badgeBgColor: { ar: 'لون خلفية الشارة', en: 'Badge Background' },
  badgeBgImage: { ar: 'صورة خلفية الشارة', en: 'Badge Background Image' },
  necklaceBorderColor: { ar: 'لون حدود القلادة', en: 'Necklace Border Color' },
  necklaceBorderImage: { ar: 'صورة حدود القلادة', en: 'Necklace Border Image' },
  necklaceBgColor: { ar: 'لون خلفية القلادة', en: 'Necklace Background' },
  necklaceBgImage: { ar: 'صورة خلفية القلادة', en: 'Necklace Background Image' },
  goldColor: { ar: 'الذهبية', en: 'Gold Color' },
  silverColor: { ar: 'الفضية', en: 'Silver Color' },
  bronzeColor: { ar: 'البرونزية', en: 'Bronze Color' },
  pointsColor: { ar: 'لون النقاط', en: 'Points Color' },
  trophyIcon: { ar: 'أيقونة الكأس', en: 'Trophy Icon' },
  crownIcon: { ar: 'أيقونة التاج', en: 'Crown Icon' },
  rankBgImage: { ar: 'صورة خلفية الترتيب', en: 'Rank Background' },
  checkedImage: { ar: 'صورة محدد', en: 'Checked Image' },
  uncheckedImage: { ar: 'صورة غير محدد', en: 'Unchecked Image' },
  lockImage: { ar: 'صورة القفل (لم تحصل عليه)', en: 'Lock Image (Not Owned)' },
  primaryColor: { ar: 'اللون الأساسي', en: 'Primary Color' },
  gradientStart: { ar: 'بداية التدرج', en: 'Gradient Start' },
  gradientEnd: { ar: 'نهاية التدرج', en: 'Gradient End' },
  fullScreenBg: { ar: 'صورة خلفية كاملة (شاشة الكل)', en: 'Full Screen Background Image' },
  cabinBg: { ar: 'خلفية الكابينة (SVG/URL)', en: 'Cabin Background (SVG/URL)' },
  cabinDefaultBg: { ar: 'خلفية الكابينة الافتراضية (SVG)', en: 'Cabin Default Background (SVG)' },
  leftFrame: { ar: 'إطار الأفاتار الأيسر (SVG)', en: 'Left Avatar Frame (SVG)' },
  rightFrame: { ar: 'إطار الأفاتار الأيمن (SVG)', en: 'Right Avatar Frame (SVG)' },
  heartImage: { ar: 'صورة القلب في البانر (SVG/URL)', en: 'Banner Heart Image (SVG/URL)' },
  noCpHeartSvg: { ar: 'صورة القلب (بدون شريك) (SVG)', en: 'No-CP Heart Image (SVG)' },
  tokenBg: { ar: 'خلفية النقاط (SVG)', en: 'Token Background (SVG)' },
  mineBg: { ar: 'خلفية My CP (SVG)', en: 'My CP Background (SVG)' },
  countdownDaySvg: { ar: 'أيقونة الأيام (SVG)', en: 'Days Icon (SVG)' },
  countdownHourSvg: { ar: 'أيقونة الساعات (SVG)', en: 'Hours Icon (SVG)' },
  countdownMinSvg: { ar: 'أيقونة الدقائق (SVG)', en: 'Minutes Icon (SVG)' },
  countdownSecSvg: { ar: 'أيقونة الثواني (SVG)', en: 'Seconds Icon (SVG)' },
  rankTagGoldSvg: { ar: 'وسام الذهبية (SVG)', en: 'Gold Rank Tag (SVG)' },
  rankTagSilverSvg: { ar: 'وسام الفضية (SVG)', en: 'Silver Rank Tag (SVG)' },
  rankTagBronzeSvg: { ar: 'وسام البرونزية (SVG)', en: 'Bronze Rank Tag (SVG)' },
  historyCardSvg: { ar: 'خلفية بطاقة التاريخ (SVG)', en: 'History Card BG (SVG)' },
  giftsBannerSvg: { ar: 'خلفية هدايا CP (SVG)', en: 'CP Gifts Banner BG (SVG)' },
  tabBgColor: { ar: 'لون خلفية التبويب', en: 'Tab Background Color' },
  tabBgImage: { ar: 'صورة خلفية التبويب', en: 'Tab Background Image' },
  countdownTextColor: { ar: 'لون نص العد التنازلي', en: 'Countdown Text Color' },
  countdownLabelColor: { ar: 'لون تسمية العد التنازلي', en: 'Countdown Label Color' },
  invitationBgColor: { ar: 'لون خلفية دعوة CP', en: 'Invitation Background Color' },
  invitationBgImage: { ar: 'صورة خلفية دعوة CP', en: 'Invitation Background Image' },
  buttonColor: { ar: 'لون الأزرار', en: 'Button Color' },
  buttonTextColor: { ar: 'لون نص الأزرار', en: 'Button Text Color' },
  buttonOutlineColor: { ar: 'لون حدود الأزرار', en: 'Button Outline Color' },
  giftButtonGradientStart: { ar: 'بداية تدرج زر الهدية', en: 'Gift Button Gradient Start' },
  giftButtonGradientEnd: { ar: 'نهاية تدرج زر الهدية', en: 'Gift Button Gradient End' },
  sectionHeaderColor: { ar: 'لون عنوان القسم', en: 'Section Header Color' },
  avatarBorderColor: { ar: 'لون حدود الصورة الرمزية', en: 'Avatar Border Color' },
  scoreTokenColor: { ar: 'لون نص النقاط', en: 'Score Token Color' },
  scoreTokenLabelColor: { ar: 'لون تسمية النقاط', en: 'Score Token Label Color' },
  scoreTokenBgColor: { ar: 'لون خلفية النقاط', en: 'Score Token BG Color' },
  podiumBgStart: { ar: 'بداية خلفية المنصة', en: 'Podium Background Start' },
  podiumBgEnd: { ar: 'نهاية خلفية المنصة', en: 'Podium Background End' },
  periodButtonActiveBg: { ar: 'لون زر الفترة النشط', en: 'Period Button Active BG' },
  periodButtonActiveText: { ar: 'لون نص زر الفترة النشط', en: 'Period Button Active Text' },
  periodButtonInactiveBg: { ar: 'لون زر الفترة غير النشط', en: 'Period Button Inactive BG' },
  periodButtonInactiveText: { ar: 'لون نص زر الفترة غير النشط', en: 'Period Button Inactive Text' },
  rankItemBg: { ar: 'لون خلفية عنصر الترتيب', en: 'Rank Item Background' },
  rankShadowColor: { ar: 'لون ظل الترتيب', en: 'Rank Shadow Color' },
  myRankPillGradientStart: { ar: 'بداية تدرج ترتيبي', en: 'My Rank Gradient Start' },
  myRankPillGradientEnd: { ar: 'نهاية تدرج ترتيبي', en: 'My Rank Gradient End' },
  myRankPillText: { ar: 'لون نص ترتيبي', en: 'My Rank Text Color' },
  myRankScoreColor: { ar: 'لون نقاط ترتيبي', en: 'My Rank Score Color' },
  // Profile CP card fields
  profileDaysBadgeBg: { ar: 'لون خلفية شارة الأيام (البروفايل)', en: 'Profile Days Badge Background' },
  profileDaysBadgeBorder: { ar: 'لون حدود شارة الأيام (البروفايل)', en: 'Profile Days Badge Border' },
  profileDaysBadgeBg2: { ar: 'لون خلفية شارة الأيام 2 (البروفايل)', en: 'Profile Days Badge BG 2' },
  profileDaysBadgeBorder2: { ar: 'لون حدود شارة الأيام 2 (البروفايل)', en: 'Profile Days Badge Border 2' },
  profileDaysText: { ar: 'لون نص الأيام (البروفايل)', en: 'Profile Days Text Color' },
  profileDaysTogetherText: { ar: 'لون نص معاً منذ (البروفايل)', en: 'Profile "Together Since" Text' },
  profileLevelGradientStart: { ar: 'بداية تدرج مستوى CP (البروفايل)', en: 'Profile CP Level Gradient Start' },
  profileLevelGradientEnd: { ar: 'نهاية تدرج مستوى CP (البروفايل)', en: 'Profile CP Level Gradient End' },
  profileHeartIcon: { ar: 'أيقونة قلب CP (البروفايل)', en: 'Profile CP Heart Icon' },
  profileLevelBg: { ar: 'خلفية مستوى CP (البروفايل)', en: 'Profile CP Level Background' },
  profileNameFrame: { ar: 'إطار اسم CP (البروفايل)', en: 'Profile CP Name Frame' },
  profileTopBgSvga: { ar: 'SVGA خلفية CP العلوية (البروفايل)', en: 'Profile CP Top BG SVGA' },
  buttonGradientStart: { ar: 'بداية تدرج الزر', en: 'Button Gradient Start' },
  buttonGradientEnd: { ar: 'نهاية تدرج الزر', en: 'Button Gradient End' },
  dayBgColor: { ar: 'لون خلفية الخلية (متاح)', en: 'Day Cell BG (Available)' },
  dayActiveColor: { ar: 'لون خلفية الخلية (اليوم)', en: 'Day Cell BG (Today)' },
  dayClaimedColor: { ar: 'لون خلفية الخلية (تم)', en: 'Day Cell BG (Claimed)' },
  dayLockedColor: { ar: 'لون خلفية الخلية (مقفل)', en: 'Day Cell BG (Locked)' },
  dayBorderColor: { ar: 'لون حدود الخلية', en: 'Day Cell Border Color' },
  dayClaimedBorderColor: { ar: 'لون حدود الخلية (تم)', en: 'Day Cell Border (Claimed)' },
  checkmarkImage: { ar: 'صورة علامة التسجيل', en: 'Checkmark Image' },
  streakIcon: { ar: 'أيقونة السلسلة', en: 'Streak Icon' },
  topBgSvga: { ar: 'SVGA الخلفية العلوية', en: 'Top BG SVGA' },
  buttonImage: { ar: 'صورة زر التسجيل', en: 'Sign-In Button Image' },
};

const imageFields = ['backgroundImage', 'checkboxCheckedImage', 'checkboxUncheckedImage', 'coinIcon', 'diamondIcon', 'rankIcon', 'crownIcon', 'rankBgImage', 'checkedImage', 'uncheckedImage', 'cardBgImage', 'sectionBgImage', 'badgeBgImage', 'necklaceBgImage', 'headerBgImage', 'headerTextImage', 'cardBorderImage', 'textImage', 'subTextImage', 'accentImage', 'badgeBorderImage', 'necklaceBorderImage', 'lockImage', 'fullScreenBg', 'cabinBg', 'cabinDefaultBg', 'leftFrame', 'rightFrame', 'heartImage', 'noCpHeartSvg', 'tokenBg', 'mineBg', 'tabBgImage', 'invitationBgImage', 'countdownDaySvg', 'countdownHourSvg', 'countdownMinSvg', 'countdownSecSvg', 'rankTagGoldSvg', 'rankTagSilverSvg', 'rankTagBronzeSvg', 'historyCardSvg', 'giftsBannerSvg', 'profileHeartIcon', 'profileLevelBg', 'profileNameFrame', 'profileTopBgSvga', 'checkmarkImage', 'streakIcon', 'topBgSvga', 'buttonImage'];

const colorRegex = /^(bg|header|text|card|border|accent|tab|gold|silver|bronze|points|section|badge|necklace|member|primary|gradient|countdown|invitation|button|avatar|score|period|rank|shadow|Color)/i;

function isColorField(field: string): boolean {
  return colorRegex.test(field) && !imageFields.includes(field);
}

export default function ScreenCustomizationPage() {
  const { t, lang } = useContext(I18nContext);
  const [activeTab, setActiveTab] = useState<string>('colors');
  const [visuals, setVisuals] = useState<ScreenVisuals>(defaultVisuals);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState('');
  const [colorConfig, setColorConfig] = useState<Record<string, string>>({});
  const [screenTitles, setScreenTitles] = useState<Record<string, string>>({});

  useEffect(() => {
    (async () => {
      try {
        const cfg = await getAppConfig();
        const stored = (cfg as any)?.screenVisuals;
        if (stored && typeof stored === 'object') {
          const merged: ScreenVisuals = { ...defaultVisuals };
          for (const screen of screenTabs) {
            if (screen === 'colors') continue;
            if (stored[screen] && typeof stored[screen] === 'object') {
              merged[screen] = { ...defaultVisuals[screen], ...stored[screen] };
            }
          }
          setVisuals(merged);
        }
        const colors = (cfg as any)?.colorCustomize;
        if (colors && typeof colors === 'object') setColorConfig(colors);
        const titles = (cfg as any)?.screenTitles;
        if (titles && typeof titles === 'object') setScreenTitles(titles);
      } catch (e) { console.warn(e); }
      setLoading(false);
    })();
  }, []);

  const showMsg = (text: string) => { setMsg(text); setTimeout(() => setMsg(''), 3000); };

  const updateField = (screen: string, field: string, value: string) => {
    setVisuals(prev => ({
      ...prev,
      [screen]: { ...prev[screen as keyof ScreenVisuals], [field]: value },
    }));
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      if (activeTab === 'colors') {
        await updateAppConfig({ colorCustomize: colorConfig, screenTitles } as any);
      } else {
        const clean: ScreenVisuals = { ...defaultVisuals };
        for (const screen of screenTabs) {
          if (screen === 'colors') continue;
          clean[screen] = {};
          for (const [key, val] of Object.entries(visuals[screen])) {
            if (val && val.trim()) clean[screen][key] = val.trim();
          }
        }
        await updateAppConfig({ screenVisuals: clean } as any);
      }
      showMsg(lang === 'ar' ? 'تم الحفظ!' : 'Saved!');
    } catch (e) {
      showMsg(lang === 'ar' ? 'فشل الحفظ' : 'Save failed');
      console.warn(e);
    }
    setSaving(false);
  };

  const handleReset = () => {
    if (confirm(lang === 'ar' ? 'إعادة تعيين جميع الإعدادات؟' : 'Reset all visuals?')) {
      setVisuals(defaultVisuals);
      handleSave();
    }
  };

  const handleImageUpload = async (file: File, screen: string, field: string) => {
    try {
      const path = `screen_visuals/${screen}_${field}_${Date.now()}`;
      const url = await uploadAppAsset(file, path);
      if (url) updateField(screen, field, url);
    } catch (e) {
      showMsg(lang === 'ar' ? 'فشل رفع الصورة' : 'Upload failed');
    }
  };

  if (loading) return <div className="text-slate-400 text-sm p-6">{t('loading')}</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-white text-lg font-semibold">
          {lang === 'ar' ? 'تخصيص الشاشات' : 'Screen Customization'}
        </h2>
        <div className="flex gap-2">
          <button onClick={handleReset} className="px-3 py-1.5 bg-rose-600/20 hover:bg-rose-600/30 text-rose-400 text-xs font-semibold rounded-lg flex items-center gap-1">
            <RotateCcw className="w-3.5 h-3.5" /> {lang === 'ar' ? 'إعادة تعيين' : 'Reset'}
          </button>
          <button onClick={handleSave} disabled={saving} className="px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-xs text-white font-semibold rounded-lg flex items-center gap-1">
            <Save className="w-3.5 h-3.5" /> {saving ? t('saving') : t('save')}
          </button>
        </div>
      </div>

      {msg && <div className="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs px-4 py-2 rounded-lg">{msg}</div>}

      <div className="flex gap-1 border-b border-white/5 overflow-x-auto">
        {screenTabs.map(s => (
          <button
            key={s}
            onClick={() => setActiveTab(s)}
            className={`px-3 py-2 text-xs font-medium whitespace-nowrap border-b-2 transition-all ${
              activeTab === s
                ? 'text-indigo-300 border-indigo-500'
                : 'text-slate-400 border-transparent hover:text-white'
            }`}
          >
            {lang === 'ar' ? screenLabels[s].ar : screenLabels[s].en}
          </button>
        ))}
      </div>

      {/* Colors Tab */}
      {activeTab === 'colors' && (
        <div className="space-y-6">
          <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
            <h3 className="text-white text-sm font-semibold">
              {lang === 'ar' ? 'ألوان التطبيق' : 'App Colors'}
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {[
                { key: 'primaryBg', label: 'الخلفية', def: '#1A1A2E' },
                { key: 'cardColor', label: 'البطاقات والأسطح', def: '#6F4E37' },
                { key: 'headerColor', label: 'شريط العنوان', def: '#1A1A2E' },
                { key: 'tabBarColor', label: 'شريط التنقل', def: '#6F4E37' },
                { key: 'goldColor', label: 'اللون الذهبي / التمييز', def: '#B9F2FF' },
                { key: 'accentColor', label: 'اللون الثاني للتمييز', def: '#B9F2FF' },
                { key: 'buttonColor', label: 'لون الأزرار', def: '#6F4E37' },
                { key: 'buttonTextColor', label: 'نص الأزرار', def: '#FFFFFF' },
                { key: 'textPrimary', label: 'النص الأساسي', def: '#FFFFFF' },
                { key: 'textSecondary', label: 'النص الثانوي', def: '#9BA1B6' },
              ].map(({ key, label, def }) => (
                <div key={key}>
                  <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1.5">{label}</label>
                  <div className="flex gap-2 items-center">
                    <input
                      type="color"
                      value={to6Hex(colorConfig[key] || def)}
                      onChange={e => setColorConfig(p => ({ ...p, [key]: e.target.value }))}
                      className="w-10 h-10 rounded cursor-pointer bg-transparent border border-white/10 shrink-0"
                    />
                    <input
                      type="text"
                      value={colorConfig[key] || def}
                      onChange={e => setColorConfig(p => ({ ...p, [key]: e.target.value }))}
                      className="flex-1 bg-[#161618] border border-white/10 rounded-lg py-2 px-3 text-xs text-white font-mono"
                    />
                    <button
                      onClick={() => setColorConfig(p => ({ ...p, [key]: def }))}
                      className="text-[10px] text-slate-500 hover:text-white p-1"
                      title="Reset"
                    >
                      <RotateCcw className="w-3 h-3" />
                    </button>
                  </div>
                  <div className="mt-1 h-2 rounded" style={{ backgroundColor: colorConfig[key] || def }} />
                </div>
              ))}
            </div>
          </div>

          {/* Screen Titles */}
          <div className="bg-[#141417] rounded-2xl border border-white/5 p-6">
            <h3 className="text-white text-sm font-semibold mb-4">
              {lang === 'ar' ? 'عناوين الشاشات' : 'Screen Titles'}
            </h3>
            <div className="grid grid-cols-2 gap-3">
              {[
                { key: 'home', label: 'الرئيسية' }, { key: 'rooms', label: 'الغرف' },
                { key: 'store', label: 'المتجر' }, { key: 'profile', label: 'الملف الشخصي' },
                { key: 'gifts', label: 'الهدايا' }, { key: 'ranking', label: 'التصنيف' },
                { key: 'unions', label: 'الاتحادات' }, { key: 'vip', label: 'VIP' },
                { key: 'settings', label: 'الإعدادات' }, { key: 'chat', label: 'المحادثة' },
              ].map(({ key, label }) => (
                <div key={key}>
                  <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{label}</label>
                  <input
                    type="text"
                    value={screenTitles[key] || ''}
                    onChange={e => setScreenTitles(p => ({ ...p, [key]: e.target.value }))}
                    placeholder={label}
                    className="w-full bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white"
                  />
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Screen Visual Tabs */}
      {activeTab !== 'colors' && (
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6 space-y-4">
        {Object.entries(visuals[activeTab as keyof ScreenVisuals] || {}).map(([field, value]) => {
          const label = fieldLabels[field]?.[lang === 'ar' ? 'ar' : 'en'] || field;
          const isImg = imageFields.includes(field);
          const isColor = isColorField(field);

          return (
            <div key={field}>
              <label className="block text-[10px] uppercase text-slate-400 font-bold mb-1">{label}</label>
              <div className="flex gap-2 items-start">
                <input
                  type={isColor ? 'color' : 'text'}
                  value={isColor ? to6Hex(value || '') : value || ''}
                  onChange={e => updateField(activeTab, field, e.target.value)}
                  className={`${isColor ? 'w-10 h-10 p-0.5' : 'flex-1'} bg-[#161618] border border-white/10 rounded-lg py-1.5 px-2 text-xs text-white`}
                />
                {isImg && (
                  <label className="cursor-pointer px-2 py-1.5 bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-400 rounded-lg">
                    <Upload className="w-3.5 h-3.5" />
                    <input type="file" accept="image/*,.svga,.mp4,.gif,.vap,.json,.webp,.mp3,.wav,.lottie" className="hidden" onChange={e => {
                      const file = e.target.files?.[0];
                      if (file) handleImageUpload(file, activeTab, field);
                    }} />
                  </label>
                )}
              </div>
              {isImg && value && (
                value.endsWith('.mp4') || value.endsWith('.webm') ? (
                  <video src={value} className="mt-1 w-16 h-16 object-contain rounded border border-white/5" controls />
                ) : value.endsWith('.mp3') || value.endsWith('.wav') ? (
                  <audio src={value} className="mt-1 w-full h-8" controls />
                ) : (
                  <img src={value} alt={label} className="mt-1 w-16 h-16 object-contain rounded border border-white/5" onError={e => { (e.target as HTMLImageElement).style.display = 'none'; }} />
                )
              )}
            </div>
          );
        })}
      </div>
      )}

      {/* Preview */}
      {activeTab !== 'colors' && (
      <div className="bg-[#141417] rounded-2xl border border-white/5 p-6">
        <h3 className="text-white text-sm font-semibold mb-3">{lang === 'ar' ? 'معاينة' : 'Preview'}</h3>
        <div
          className="rounded-xl p-4 space-y-3"
          style={{
            background: visuals[activeTab as keyof ScreenVisuals]?.backgroundImage
              ? `url(${visuals[activeTab as keyof ScreenVisuals]?.backgroundImage}) center/cover no-repeat`
              : visuals[activeTab as keyof ScreenVisuals]?.headerBgColor || '#1a1a2e',
            color: visuals[activeTab as keyof ScreenVisuals]?.textColor || '#fff',
          }}
        >
          <div
            className="rounded-lg p-3"
            style={{
              background: visuals[activeTab as keyof ScreenVisuals]?.cardBgColor || '#16213e',
              border: `1px solid ${visuals[activeTab as keyof ScreenVisuals]?.cardBorderColor || '#0f3460'}`,
            }}
          >
            <p style={{ color: visuals[activeTab as keyof ScreenVisuals]?.accentColor || '#e94560' }}>
              {activeTab === 'badges' ? (lang === 'ar' ? 'الشارات' : 'Badges') :
               activeTab === 'necklaces' ? (lang === 'ar' ? 'القلائد' : 'Necklaces') :
               activeTab === 'rank' ? (lang === 'ar' ? 'الترتيب' : 'Rank') :
               activeTab === 'checkbox' ? (lang === 'ar' ? 'الاختيار' : 'Checkbox') :
               activeTab === 'store' ? (lang === 'ar' ? 'المتجر' : 'Store') :
               activeTab === 'backpack' ? (lang === 'ar' ? 'الحقيبة' : 'Backpack') :
               activeTab === 'wallet' ? (lang === 'ar' ? 'المحفظة' : 'Wallet') :
               activeTab === 'level' ? (lang === 'ar' ? 'المستويات' : 'Levels') :
               activeTab === 'cp' ? (lang === 'ar' ? '💑 CP' : '💑 CP') :
               activeTab === 'signin' ? (lang === 'ar' ? '📅 تسجيل الدخول' : '📅 Weekly Sign-In') :
                (lang === 'ar' ? 'الوكالة' : 'Agency')}
            </p>
            <p className="text-xs mt-1" style={{ color: visuals[activeTab as keyof ScreenVisuals]?.subTextColor || '#a0a0b0' }}>
              {lang === 'ar' ? 'نموذج توضيحي للمعاينة' : 'Sample preview text'}
            </p>
          </div>
          <div className="flex items-center gap-2 mt-2">
            <div className="w-5 h-5 rounded border flex items-center justify-center text-[8px] bg-white/10">✓</div>
            <span className="text-xs">{lang === 'ar' ? 'محدد' : 'Checked'}</span>
            <div className="w-5 h-5 rounded border flex items-center justify-center text-[8px] bg-white/5"></div>
            <span className="text-xs">{lang === 'ar' ? 'غير محدد' : 'Unchecked'}</span>
          </div>
        </div>
      </div>
      )}
    </div>
  );
}
