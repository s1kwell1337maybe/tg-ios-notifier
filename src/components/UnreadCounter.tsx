import React from 'react';
import { MessageSquare, Users, Radio, AtSign, BellRing, Sparkles, Send } from 'lucide-react';
import { UnreadStats } from '../services/telegram';

interface UnreadCounterProps {
  stats: UnreadStats;
  isLoggedIn: boolean;
  onSimulateTestNotification: () => void;
  onOpenLogin: () => void;
}

export const UnreadCounter: React.FC<UnreadCounterProps> = ({
  stats,
  isLoggedIn,
  onSimulateTestNotification,
  onOpenLogin,
}) => {
  return (
    <div className="w-full px-4 mb-4">
      {/* Main Big Glow Counter Card */}
      <div className="glass-panel p-6 relative overflow-hidden text-center mb-4">
        {/* Subtle Background Glow Accent */}
        <div className="absolute -top-12 left-1/2 -translate-x-1/2 w-48 h-48 bg-red-500/20 rounded-full blur-3xl pointer-events-none" />
        
        <div className="relative z-10">
          <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-white/10 text-slate-300 text-xs font-medium mb-3 border border-white/10">
            <BellRing size={13} className="text-red-400 animate-bounce" />
            <span>Новые уведомления Telegram</span>
          </div>

          {/* Big Number Badge */}
          <div className="my-2 flex items-center justify-center">
            <div className="unread-badge-glow inline-flex items-center justify-center min-w-[110px] h-[110px] px-6 rounded-3xl text-white shadow-2xl">
              <span className="text-6xl font-black tracking-tight drop-shadow-md">
                {stats.totalUnreadMessages}
              </span>
            </div>
          </div>

          <p className="text-sm font-semibold text-white mt-3">
            {stats.totalUnreadMessages === 0
              ? 'Все сообщения прочитаны 🎉'
              : stats.totalUnreadMessages === 1
              ? '1 новое непрочитанное сообщение'
              : `${stats.totalUnreadMessages} непрочитанных сообщений в ${stats.totalUnreadChats} чатах`}
          </p>

          <p className="text-xs text-slate-400 mt-1">
            Синхронизировано: {new Date(stats.lastUpdated).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
          </p>

          {/* Quick Action Buttons */}
          <div className="mt-5 flex flex-wrap gap-2 justify-center">
            <button
              onClick={onSimulateTestNotification}
              className="ios-btn ios-btn-secondary px-3.5 py-2 text-xs font-semibold flex items-center space-x-1.5"
            >
              <Sparkles size={14} className="text-amber-400" />
              <span>Тест уведомления</span>
            </button>

            {!isLoggedIn && (
              <button
                onClick={onOpenLogin}
                className="ios-btn ios-btn-primary px-4 py-2 text-xs font-semibold flex items-center space-x-1.5"
              >
                <Send size={14} />
                <span>Подключить свой Telegram</span>
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Breakdown Categorized Grid */}
      <div className="grid grid-cols-2 gap-3">
        {/* Private DMs */}
        <div className="glass-panel p-3.5 flex items-center justify-between">
          <div className="flex items-center space-x-2.5">
            <div className="w-8 h-8 rounded-xl bg-sky-500/20 border border-sky-400/30 flex items-center justify-center text-sky-400">
              <MessageSquare size={16} />
            </div>
            <div>
              <div className="text-xs text-slate-400 font-medium">Личные</div>
              <div className="text-sm font-bold text-white">Чаты</div>
            </div>
          </div>
          <span className={`text-base font-extrabold px-2.5 py-0.5 rounded-full ${
            stats.privateChatsUnread > 0 ? 'bg-sky-500/30 text-sky-300 border border-sky-400/40' : 'text-slate-500'
          }`}>
            {stats.privateChatsUnread}
          </span>
        </div>

        {/* Groups */}
        <div className="glass-panel p-3.5 flex items-center justify-between">
          <div className="flex items-center space-x-2.5">
            <div className="w-8 h-8 rounded-xl bg-indigo-500/20 border border-indigo-400/30 flex items-center justify-center text-indigo-400">
              <Users size={16} />
            </div>
            <div>
              <div className="text-xs text-slate-400 font-medium">Группы</div>
              <div className="text-sm font-bold text-white">Беседы</div>
            </div>
          </div>
          <span className={`text-base font-extrabold px-2.5 py-0.5 rounded-full ${
            stats.groupsUnread > 0 ? 'bg-indigo-500/30 text-indigo-300 border border-indigo-400/40' : 'text-slate-500'
          }`}>
            {stats.groupsUnread}
          </span>
        </div>

        {/* Channels */}
        <div className="glass-panel p-3.5 flex items-center justify-between">
          <div className="flex items-center space-x-2.5">
            <div className="w-8 h-8 rounded-xl bg-amber-500/20 border border-amber-400/30 flex items-center justify-center text-amber-400">
              <Radio size={16} />
            </div>
            <div>
              <div className="text-xs text-slate-400 font-medium">Каналы</div>
              <div className="text-sm font-bold text-white">Лента</div>
            </div>
          </div>
          <span className={`text-base font-extrabold px-2.5 py-0.5 rounded-full ${
            stats.channelsUnread > 0 ? 'bg-amber-500/30 text-amber-300 border border-amber-400/40' : 'text-slate-500'
          }`}>
            {stats.channelsUnread}
          </span>
        </div>

        {/* Mentions */}
        <div className="glass-panel p-3.5 flex items-center justify-between">
          <div className="flex items-center space-x-2.5">
            <div className="w-8 h-8 rounded-xl bg-rose-500/20 border border-rose-400/30 flex items-center justify-center text-rose-400">
              <AtSign size={16} />
            </div>
            <div>
              <div className="text-xs text-slate-400 font-medium">Упоминания</div>
              <div className="text-sm font-bold text-white">Ответы</div>
            </div>
          </div>
          <span className={`text-base font-extrabold px-2.5 py-0.5 rounded-full ${
            stats.mentionsCount > 0 ? 'bg-rose-500/30 text-rose-300 border border-rose-400/40' : 'text-slate-500'
          }`}>
            {stats.mentionsCount}
          </span>
        </div>
      </div>
    </div>
  );
};
