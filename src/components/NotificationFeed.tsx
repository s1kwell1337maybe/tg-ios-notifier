import React from 'react';
import { Bell, Trash2, Volume2, MessageSquare, Users, Radio } from 'lucide-react';
import { NotificationItem } from '../services/telegram';
import { soundService } from '../services/sound';

interface NotificationFeedProps {
  notifications: NotificationItem[];
  onClear: () => void;
}

export const NotificationFeed: React.FC<NotificationFeedProps> = ({
  notifications,
  onClear,
}) => {
  const formatTime = (date: Date) => {
    const now = new Date();
    const diffMs = now.getTime() - new Date(date).getTime();
    const diffSec = Math.floor(diffMs / 1000);

    if (diffSec < 10) return 'Только что';
    if (diffSec < 60) return `${diffSec} сек назад`;
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin < 60) return `${diffMin} мин назад`;
    return new Date(date).toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
  };

  const getChatIcon = (type: string) => {
    switch (type) {
      case 'group':
        return <Users size={12} className="text-indigo-400" />;
      case 'channel':
        return <Radio size={12} className="text-amber-400" />;
      default:
        return <MessageSquare size={12} className="text-sky-400" />;
    }
  };

  return (
    <div className="w-full px-4 mb-20">
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="flex items-center space-x-2">
          <Bell size={16} className="text-sky-400" />
          <h2 className="text-sm font-bold text-white tracking-wide">Лента уведомлений</h2>
          <span className="text-xs bg-white/10 px-2 py-0.5 rounded-full text-slate-300 font-semibold">
            {notifications.length}
          </span>
        </div>

        {notifications.length > 0 && (
          <button
            onClick={onClear}
            className="text-xs text-rose-400 hover:text-rose-300 flex items-center space-x-1 px-2 py-1 rounded-lg hover:bg-rose-500/10 transition-all"
          >
            <Trash2 size={13} />
            <span>Очистить</span>
          </button>
        )}
      </div>

      {notifications.length === 0 ? (
        <div className="glass-panel p-8 text-center">
          <div className="w-12 h-12 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center mx-auto mb-3 text-slate-400">
            <Bell size={22} />
          </div>
          <p className="text-sm font-medium text-slate-300">Пока нет новых уведомлений</p>
          <p className="text-xs text-slate-500 mt-1 max-w-xs mx-auto">
            Когда вам кто-то напишет в Telegram, здесь мгновенно появится пуш и счетчик обновится
          </p>
        </div>
      ) : (
        <div className="space-y-2.5">
          {notifications.map((item) => (
            <div
              key={item.id}
              className="glass-panel p-3.5 pop-in hover:border-white/20 transition-all cursor-pointer relative group"
              onClick={() => soundService.playNotificationChime()}
            >
              <div className="flex items-start space-x-3">
                {/* Avatar / Icon */}
                <div className="w-10 h-10 rounded-full bg-gradient-to-tr from-sky-500 to-indigo-600 flex-shrink-0 flex items-center justify-center text-white font-bold text-sm shadow-md border border-white/20">
                  {item.senderName ? item.senderName.charAt(0).toUpperCase() : 'TG'}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-1.5 truncate pr-2">
                      <span className="text-xs font-bold text-white truncate">
                        {item.senderName}
                      </span>
                      {item.chatTitle !== item.senderName && (
                        <span className="text-xs text-slate-400 truncate">
                          в {item.chatTitle}
                        </span>
                      )}
                    </div>
                    <span className="text-[10px] text-slate-400 flex-shrink-0 font-medium">
                      {formatTime(item.timestamp)}
                    </span>
                  </div>

                  <p className="text-xs text-slate-300 mt-1 line-clamp-2 leading-relaxed">
                    {item.messageText}
                  </p>

                  <div className="mt-2 flex items-center justify-between text-[10px] text-slate-400">
                    <span className="inline-flex items-center space-x-1 px-2 py-0.5 rounded-md bg-white/5 border border-white/10">
                      {getChatIcon(item.chatType)}
                      <span className="capitalize">
                        {item.chatType === 'private' ? 'Личный чат' : item.chatType === 'group' ? 'Группа' : 'Канал'}
                      </span>
                    </span>

                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        soundService.playNotificationChime();
                      }}
                      className="p-1 rounded-md hover:bg-white/10 text-slate-400 hover:text-sky-400 transition-all"
                      title="Воспроизвести звук"
                    >
                      <Volume2 size={12} />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
