import React from 'react';
import { ShieldCheck, RefreshCw, Settings, UserCheck, AlertCircle, Wifi, WifiOff } from 'lucide-react';
import { TelegramUser, ConnectionStatus } from '../services/telegram';

interface IOSHeaderProps {
  user: TelegramUser | null;
  status: ConnectionStatus;
  unreadCount: number;
  onRefresh: () => void;
  onOpenSettings: () => void;
  onOpenLogin: () => void;
  isRefreshing: boolean;
}

export const IOSHeader: React.FC<IOSHeaderProps> = ({
  user,
  status,
  unreadCount,
  onRefresh,
  onOpenSettings,
  onOpenLogin,
  isRefreshing,
}) => {
  return (
    <header style={{ paddingTop: 'max(14px, env(safe-area-inset-top))' }} className="w-full px-4 mb-3">
      {/* iOS Dynamic Island Floating Capsule */}
      <div className="dynamic-island mx-auto max-w-sm px-4 py-2.5 flex items-center justify-between text-white text-xs mb-4">
        <div className="flex items-center space-x-2">
          <div className="relative flex items-center justify-center">
            {status === 'connected' ? (
              <>
                <span className="animate-ping absolute inline-flex h-2.5 w-2.5 rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
              </>
            ) : status === 'connecting' ? (
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-amber-400 animate-pulse"></span>
            ) : (
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-rose-500"></span>
            )}
          </div>
          <span className="font-semibold tracking-wide text-xs" style={{ color: status === 'connected' ? '#34C759' : '#8E9BAE' }}>
            {status === 'connected' ? 'TG MTProto Live' : status === 'connecting' ? 'Подключение...' : 'Не авторизован'}
          </span>
        </div>

        {unreadCount > 0 && (
          <div className="flex items-center space-x-1.5 bg-red-600/30 border border-red-500/40 px-2.5 py-0.5 rounded-full">
            <span className="w-1.5 h-1.5 rounded-full bg-red-500 animate-ping"></span>
            <span className="font-bold text-red-400 text-xs">{unreadCount} новых</span>
          </div>
        )}

        <div className="flex items-center space-x-1 text-slate-400">
          {status === 'connected' ? <Wifi size={14} className="text-emerald-400" /> : <WifiOff size={14} />}
        </div>
      </div>

      {/* Main Top Navigation Row */}
      <div className="flex items-center justify-between glass-panel px-4 py-3">
        {/* User profile / Login prompt */}
        {user ? (
          <div className="flex items-center space-x-3 cursor-pointer" onClick={onOpenLogin}>
            <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-sky-500 to-blue-600 flex items-center justify-center text-white font-bold text-base shadow-md border border-white/20">
              {user.firstName ? user.firstName.charAt(0).toUpperCase() : 'U'}
            </div>
            <div>
              <div className="flex items-center space-x-1">
                <span className="font-bold text-sm text-white">{user.firstName} {user.lastName || ''}</span>
                <ShieldCheck size={14} className="text-sky-400" />
              </div>
              <span className="text-xs text-slate-400">
                {user.username ? `@${user.username}` : user.phone || 'Telegram Account'}
              </span>
            </div>
          </div>
        ) : (
          <button
            onClick={onOpenLogin}
            className="ios-btn ios-btn-primary px-3.5 py-2 text-xs font-semibold flex items-center space-x-2"
          >
            <UserCheck size={15} />
            <span>Войти через Telegram</span>
          </button>
        )}

        {/* Action Buttons: Refresh & Settings */}
        <div className="flex items-center space-x-2">
          {user && (
            <button
              onClick={onRefresh}
              disabled={isRefreshing}
              className={`p-2.5 rounded-xl bg-white/10 hover:bg-white/15 text-white transition-all ${
                isRefreshing ? 'animate-spin text-sky-400' : ''
              }`}
              title="Обновить счетчик"
            >
              <RefreshCw size={17} />
            </button>
          )}

          <button
            onClick={onOpenSettings}
            className="p-2.5 rounded-xl bg-white/10 hover:bg-white/15 text-white transition-all"
            title="Настройки"
          >
            <Settings size={17} />
          </button>
        </div>
      </div>
    </header>
  );
};
