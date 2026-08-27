import { useEffect, useState } from 'react';
import Layout from './components/Layout';
import { ToastProvider } from './lib/ui';
import AdminManagement from './pages/AdminManagement';
import Agency from './pages/Agency';
import AppAssets from './pages/AppAssets';
import AppIcons from './pages/AppIcons';
import BadgeNecklaceGifts from './pages/BadgeNecklaceGifts';
import Badges from './pages/Badges';
import Banners from './pages/Banners';
import BD from './pages/BD';
import ColorCustomize from './pages/ColorCustomize';
import CP from './pages/CP';
import CpFeatures from './pages/CpFeatures';
import CpVisualManager from './pages/CpVisualManager';
import Dashboard from './pages/Dashboard';
import DMs from './pages/DMs';
import ErrorAnalysis from './pages/ErrorAnalysis';
import GiftBannerConfigs from './pages/GiftBannerConfigs';
import GiftBoxCustomize from './pages/GiftBoxCustomize';
import GiftCategories from './pages/GiftCategories';
import GiftItems from './pages/GiftItems';
import Gifts from './pages/Gifts';
import ImageCustomize from './pages/ImageCustomize';
import Levels from './pages/Levels';
import Login from './pages/Login';
import Messages from './pages/Messages';
import Necklaces from './pages/Necklaces';
import Notifications from './pages/Notifications';
import Overview from './pages/Overview';
import ProfileCustomize from './pages/ProfileCustomize';
import Rooms from './pages/Rooms';
import ScreenCustomization from './pages/ScreenCustomization';
import Settings from './pages/Settings';
import SigninFeatures from './pages/SigninFeatures';
import Store from './pages/Store';
import SvgaOverrides from './pages/SvgaOverrides';
import Unions from './pages/Unions';
import Users from './pages/Users';
import VIP from './pages/VIP';
import VIPGifting from './pages/VIPGifting';
import VisualManager from './pages/VisualManager';

const AUTH_KEY = 'ayam_admin_auth';

export default function App() {
  const [authed, setAuthed] = useState(() => sessionStorage.getItem(AUTH_KEY) === '1');
  const [page, setPage] = useState('overview');

  useEffect(() => {
    document.title = 'لوحة تحكم Ayam Chat';
  }, []);

  if (!authed) {
    return <Login onLogin={() => setAuthed(true)} />;
  }

  const logout = () => {
    sessionStorage.removeItem(AUTH_KEY);
    setAuthed(false);
  };

  return (
    <ToastProvider>
      <Layout page={page} onNavigate={setPage} onLogout={logout}>
        {page === 'overview' && <Overview />}
        {page === 'dashboard' && <Dashboard />}
        {page === 'users' && <Users />}
        {page === 'rooms' && <Rooms />}
        {page === 'messages' && <Messages />}
        {page === 'dms' && <DMs />}
        {page === 'store' && <Store />}
        {page === 'svgaOverrides' && <SvgaOverrides />}
        {page === 'banners' && <Banners />}
        {page === 'gifts' && <Gifts />}
        {page === 'giftCategories' && <GiftCategories />}
        {page === 'giftItems' && <GiftItems />}
        {page === 'giftBannerConfigs' && <GiftBannerConfigs />}
        {page === 'giftBoxCustomize' && <GiftBoxCustomize />}
        {page === 'badges' && <Badges />}
        {page === 'necklaces' && <Necklaces />}
        {page === 'badgeNecklaceGifts' && <BadgeNecklaceGifts />}
        {page === 'levels' && <Levels />}
        {page === 'vip' && <VIP />}
        {page === 'vipGifting' && <VIPGifting />}
        {page === 'cp' && <CP />}
        {page === 'cpFeatures' && <CpFeatures />}
        {page === 'cpVisualManager' && <CpVisualManager />}
        {page === 'unions' && <Unions />}
        {page === 'agency' && <Agency />}
        {page === 'appAssets' && <AppAssets />}
        {page === 'appIcons' && <AppIcons />}
        {page === 'imageCustomize' && <ImageCustomize />}
        {page === 'colorCustomize' && <ColorCustomize />}
        {page === 'screenCustomization' && <ScreenCustomization />}
        {page === 'visualManager' && <VisualManager />}
        {page === 'profileCustomize' && <ProfileCustomize />}
        {page === 'notifications' && <Notifications />}
        {page === 'signinFeatures' && <SigninFeatures />}
        {page === 'adminManagement' && <AdminManagement currentUser={null} />}
        {page === 'bd' && <BD />}
        {page === 'errorAnalysis' && <ErrorAnalysis />}
        {page === 'settings' && <Settings />}
      </Layout>
    </ToastProvider>
  );
}
