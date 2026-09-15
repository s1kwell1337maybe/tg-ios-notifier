import React, { useState, useEffect, useCallback } from 'react';
import { IOSHeader } from './components/IOSHeader';
import { UnreadCounter } from './components/UnreadCounter';
import { NotificationFeed } from './components/NotificationFeed';
import { LoginModal } from './components/LoginModal';
import { SettingsModal } from './components/SettingsModal';
import {
  telegramService,
  TelegramUser,
  ConnectionStatus,
  UnreadStats,
  NotificationItem,
} from './services/telegram';
import { MessageCircle, Bell, Shield, Sparkles, Send, Smartphone } from 'lucide-react';

export const App: React.FC = () => {
  const [user, setUser] = useState<TelegramUser | null>(telegramService.getCurrentUser());
  const [status, setStatus] = useState<ConnectionStatus>(telegramService.getStatus());
  const [stats, setStats] = useState<UnreadStats>(telegramService.getStats());
  const [notifications, setNotifications] = useState<NotificationItem[]>(telegramService.getNotifications());

  const [isLoginOpen, setIsLoginOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Initialize Telegram client on mount
  useEffect(() => {
    const unsubStatus = telegramService.onStatusChange((newStatus) => {
      setStatus(newStatus);
      setUser(telegramService.getCurrentUser());
    });

    const unsubUnread = telegramService.onUnreadChange((newStats) => {
      setStats({ ...newStats });
    });

    const unsubNotif = telegramService.onNotification(() => {
      setNotifications([...telegramService.getNotifications()]);
    });

    // Auto connect if saved session exists
    telegramService.init().then((success) => {
      if (success) {
        setUser(telegramService.getCurrentUser());
      }
    });

    return () => {
      unsubStatus();
      unsubUnread();
      unsubNotif();
    };
  }, []);

  const handleRefresh = useCallback(async () => {
    setIsRefreshing(true);
    try {
      const updated = await telegramService.refreshUnreadStats();
      setStats({ ...updated });
    } finally {
      setTimeout(() => setIsRefreshing(false), 500);
    }
  }, []);

  const handleSimulateNotification = () => {
    const demos = [
      {
        chatTitle: 'Павел Дуров',
        senderName: 'Pavel Durov',
        text: 'Новое обновление Telegram доступно! Проверь счетчик в своем iOS приложении 🚀',
        type: 'private' as const,
      },
      {
        chatTitle: 'Разработка iOS & TG',
        senderName: 'Алексей',
        text: 'Сборка .ipa готова к установке на iPhone через TrollStore или Sideloadly!',
        type: 'group' as const,
      },
      {
        chatTitle: 'Telegram Info RU',
        senderName: 'Telegram Info',
        text: '🔥 В Telegram зафиксирован рекорд по количеству активных пользователей.',
        type: 'channel' as const,
      },
      {
        chatTitle: 'Анна',
        senderName: 'Анна',
        text: 'Привет! Ты видел новое сообщение в Telegram? Ответь как сможешь 😊',
        type: 'private' as const,
      },
    ];

    const randomDemo = demos[Math.floor(Math.random() * demos.length)];
    telegramService.simulateIncomingNotification(
      randomDemo.chatTitle,
      randomDemo.senderName,
      randomDemo.text,
      randomDemo.type
    );
  };

  const handleClearNotifications = () => {
    telegramService.clearAllNotifications();
    setNotifications([]);
  };

  const handleResetCounters = () => {
    telegramService.resetCounters();
    setStats(telegramService.getStats());
  };

  const handleLogout = () => {
    telegramService.logout();
    setUser(null);
    setStatus('disconnected');
    setIsLoginOpen(false);
  };

  return (
    <div className="min-h-screen w-full max-w-lg mx-auto flex flex-col justify-between pb-6">
      {/* Top Header with iOS Status & Navigation */}
      <div>
        <IOSHeader
          user={user}
          status={status}
          unreadCount={stats.totalUnreadMessages}
          onRefresh={handleRefresh}
          onOpenSettings={() => setIsSettingsOpen(true)}
          onOpenLogin={() => setIsLoginOpen(true)}
          isRefreshing={isRefreshing}
        />

        {/* Hero Banner if not logged in */}
        {!user && (
          <div className="px-4 mb-4">
            <div className="glass-panel p-4 bg-gradient-to-r from-sky-900/40 via-blue-900/30 to-indigo-900/40 border border-sky-400/20 flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded-2xl bg-sky-500/20 text-sky-400 flex items-center justify-center flex-shrink-0">
                  <MessageCircle size={20} />
                </div>
                <div>
                  <h3 className="text-xs font-bold text-white">Вход через Telegram</h3>
                  <p className="text-[11px] text-slate-300">
                    Авторизуйтесь, чтобы отслеживать реальные уведомления своего аккаунта
                  </p>
                </div>
              </div>
              <button
                onClick={() => setIsLoginOpen(true)}
                className="ios-btn ios-btn-primary px-3 py-1.5 text-xs font-bold whitespace-nowrap ml-2"
              >
                Войти
              </button>
            </div>
          </div>
        )}

        {/* Main Big Unread Counter Widget */}
        <UnreadCounter
          stats={stats}
          isLoggedIn={Boolean(user)}
          onSimulateTestNotification={handleSimulateNotification}
          onOpenLogin={() => setIsLoginOpen(true)}
        />

        {/* Live Notification Stream */}
        <NotificationFeed
          notifications={notifications}
          onClear={handleClearNotifications}
        />
      </div>

      {/* iOS Floating Bottom Bar info */}
      <footer className="px-4 text-center">
        <div className="inline-flex items-center space-x-2 text-[11px] text-slate-400 px-3 py-1 rounded-full bg-white/5 border border-white/10">
          <Smartphone size={12} className="text-sky-400" />
          <span>Telegram Notifier iOS • Сборка IPA готова</span>
        </div>
      </footer>

      {/* Login Modal */}
      <LoginModal
        isOpen={isLoginOpen}
        onClose={() => setIsLoginOpen(false)}
        currentUser={user}
        onLoginSuccess={(loggedUser) => {
          setUser(loggedUser);
          setIsLoginOpen(false);
          handleRefresh();
        }}
        onLogout={handleLogout}
      />

      {/* Settings Modal */}
      <SettingsModal
        isOpen={isSettingsOpen}
        onClose={() => setIsSettingsOpen(false)}
        onResetCounters={handleResetCounters}
      />
    </div>
  );
};
