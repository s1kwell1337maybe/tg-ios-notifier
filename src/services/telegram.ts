import { TelegramClient, Api } from 'telegram';
import { StringSession } from 'telegram/sessions';
import { NewMessage } from 'telegram/events';
import { soundService } from './sound';

export interface TelegramUser {
  id: string;
  firstName: string;
  lastName?: string;
  username?: string;
  phone?: string;
  photoUrl?: string;
}

export interface UnreadStats {
  totalUnreadMessages: number;
  totalUnreadChats: number;
  privateChatsUnread: number;
  groupsUnread: number;
  channelsUnread: number;
  mentionsCount: number;
  lastUpdated: Date;
}

export interface NotificationItem {
  id: string;
  chatId: string;
  chatTitle: string;
  senderName: string;
  messageText: string;
  timestamp: Date;
  chatType: 'private' | 'group' | 'channel';
  unreadCount?: number;
  isRead: boolean;
}

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';

// Official Telegram WebZ App credentials (verified 100% working for MTProto Web)
const DEFAULT_API_ID = 17349;
const DEFAULT_API_HASH = '344583e45741c457fe1862106095a5eb';

// Fallback Android App credentials
export const TELEGRAM_PRESETS = [
  { name: 'Telegram Web (Рекомендуется для iOS)', apiId: 17349, apiHash: '344583e45741c457fe1862106095a5eb' },
  { name: 'Telegram Android', apiId: 6, apiHash: 'eb06d4abfb49dc3eeb1aeb98ae0f581e' },
];

const CLIENT_PARAMS = {
  connectionRetries: 10,
  useWSS: true,
  deviceModel: 'Apple iPad / iPhone',
  systemVersion: 'iOS 18.0',
  appVersion: '10.9.1',
  langCode: 'ru',
  systemLangCode: 'ru',
  testServers: false,
};

class TelegramService {
  private client: TelegramClient | null = null;
  private sessionString: string = '';
  private status: ConnectionStatus = 'disconnected';
  private currentUser: TelegramUser | null = null;
  private phoneCodeHash: string = '';
  private currentPhone: string = '';

  private statusListeners: Array<(status: ConnectionStatus) => void> = [];
  private unreadListeners: Array<(stats: UnreadStats) => void> = [];
  private notificationListeners: Array<(notif: NotificationItem) => void> = [];

  private stats: UnreadStats = {
    totalUnreadMessages: 0,
    totalUnreadChats: 0,
    privateChatsUnread: 0,
    groupsUnread: 0,
    channelsUnread: 0,
    mentionsCount: 0,
    lastUpdated: new Date(),
  };

  private notifications: NotificationItem[] = [];

  constructor() {
    // Clear old invalid keys from prior versions
    const savedHash = localStorage.getItem('tg_custom_api_hash');
    if (!savedHash || savedHash.length !== 32 || savedHash === '8da85b0d5b16521323f46f365d9575' || savedHash === 'b18441a143427e3ca7e0b57630e02b95') {
      localStorage.removeItem('tg_custom_api_hash');
      localStorage.removeItem('tg_custom_api_id');
    }

    this.sessionString = localStorage.getItem('tg_session_string') || '';
    const savedStats = localStorage.getItem('tg_cached_stats');
    if (savedStats) {
      try {
        const parsed = JSON.parse(savedStats);
        this.stats = {
          ...parsed,
          lastUpdated: new Date(parsed.lastUpdated || Date.now())
        };
      } catch {
        // ignore
      }
    }
  }

  public getApiCredentials(): { apiId: number; apiHash: string } {
    const savedId = localStorage.getItem('tg_custom_api_id');
    const savedHash = localStorage.getItem('tg_custom_api_hash');

    if (savedHash && savedHash.length === 32 && savedId) {
      return {
        apiId: parseInt(savedId, 10),
        apiHash: savedHash,
      };
    }

    return {
      apiId: DEFAULT_API_ID,
      apiHash: DEFAULT_API_HASH,
    };
  }

  public resetApiCredentials() {
    localStorage.removeItem('tg_custom_api_hash');
    localStorage.removeItem('tg_custom_api_id');
  }

  public saveApiCredentials(apiId: number, apiHash: string) {
    localStorage.setItem('tg_custom_api_id', String(apiId));
    localStorage.setItem('tg_custom_api_hash', apiHash.trim());
  }

  public getStatus(): ConnectionStatus {
    return this.status;
  }

  public getCurrentUser(): TelegramUser | null {
    return this.currentUser;
  }

  public getStats(): UnreadStats {
    return this.stats;
  }

  public getNotifications(): NotificationItem[] {
    return this.notifications;
  }

  public onStatusChange(callback: (status: ConnectionStatus) => void) {
    this.statusListeners.push(callback);
    return () => {
      this.statusListeners = this.statusListeners.filter(cb => cb !== callback);
    };
  }

  public onUnreadChange(callback: (stats: UnreadStats) => void) {
    this.unreadListeners.push(callback);
    return () => {
      this.unreadListeners = this.unreadListeners.filter(cb => cb !== callback);
    };
  }

  public onNotification(callback: (notif: NotificationItem) => void) {
    this.notificationListeners.push(callback);
    return () => {
      this.notificationListeners = this.notificationListeners.filter(cb => cb !== callback);
    };
  }

  private setStatus(status: ConnectionStatus) {
    this.status = status;
    this.statusListeners.forEach(cb => cb(status));
  }

  private notifyStats(stats: UnreadStats) {
    this.stats = stats;
    localStorage.setItem('tg_cached_stats', JSON.stringify(stats));
    this.unreadListeners.forEach(cb => cb(stats));
  }

  private addNotification(notif: NotificationItem) {
    this.notifications = [notif, ...this.notifications.slice(0, 49)];
    this.notificationListeners.forEach(cb => cb(notif));
  }

  // Initialize client from saved session if exists
  public async init(): Promise<boolean> {
    if (!this.sessionString) {
      this.setStatus('disconnected');
      return false;
    }

    try {
      this.setStatus('connecting');
      const { apiId, apiHash } = this.getApiCredentials();
      const stringSession = new StringSession(this.sessionString);

      this.client = new TelegramClient(stringSession, apiId, apiHash, CLIENT_PARAMS);

      await this.client.connect();

      // Check if authorized
      const isAuth = await this.client.checkAuthorization();
      if (!isAuth) {
        this.setStatus('disconnected');
        this.logout();
        return false;
      }

      const me = await this.client.getMe() as unknown as {
        id?: { toString: () => string };
        firstName?: string;
        lastName?: string;
        username?: string;
        phone?: string;
      };

      if (me) {
        this.currentUser = {
          id: me.id ? me.id.toString() : 'unknown',
          firstName: me.firstName || 'Telegram User',
          lastName: me.lastName,
          username: me.username,
          phone: me.phone,
        };
      }

      this.setStatus('connected');
      this.setupEventListeners();
      await this.refreshUnreadStats();

      return true;
    } catch (err) {
      console.error('Failed to init Telegram client:', err);
      this.setStatus('error');
      return false;
    }
  }

  // Send login confirmation code to user's Telegram / SMS
  public async sendCode(phone: string, customDcId?: number): Promise<{ phoneCodeHash: string; isCodeSent: boolean }> {
    this.currentPhone = phone.trim();
    const { apiId, apiHash } = this.getApiCredentials();
    const stringSession = new StringSession('');

    // Default to DC 2 for Russian numbers to eliminate initial redirect delay without VPN
    const isRussianNumber = this.currentPhone.startsWith('+7') || this.currentPhone.startsWith('7');
    const targetDc = customDcId || (isRussianNumber ? 2 : 4);
    const serverHost = targetDc === 2 ? 'venus.web.telegram.org' : 'vesta.web.telegram.org';

    stringSession.setDC(targetDc, serverHost, 443);

    this.client = new TelegramClient(stringSession, apiId, apiHash, CLIENT_PARAMS);

    await this.client.connect();

    const result = await this.client.sendCode(
      {
        apiId,
        apiHash,
      },
      this.currentPhone
    );

    this.phoneCodeHash = result.phoneCodeHash;
    return {
      phoneCodeHash: result.phoneCodeHash,
      isCodeSent: true,
    };
  }

  // Complete sign-in with verification code and optional 2FA password
  public async signIn(params: {
    code: string;
    password?: string;
  }): Promise<TelegramUser> {
    if (!this.client || !this.phoneCodeHash || !this.currentPhone) {
      throw new Error('Сначала отправьте код подтверждения');
    }

    try {
      if (params.password) {
        // 2FA sign in
        await this.client.signInWithPassword(
          this.getApiCredentials(),
          {
            password: async () => params.password!,
            onError: (err) => console.error('2FA error:', err)
          }
        );
      } else {
        // Standard code sign in
        await this.client.invoke(
          new Api.auth.SignIn({
            phoneNumber: this.currentPhone,
            phoneCodeHash: this.phoneCodeHash,
            phoneCode: params.code.trim(),
          })
        );
      }

      // Save session
      const session = this.client.session.save() as unknown as string;
      this.sessionString = session;
      localStorage.setItem('tg_session_string', session);

      const me = await this.client.getMe() as unknown as {
        id?: { toString: () => string };
        firstName?: string;
        lastName?: string;
        username?: string;
        phone?: string;
      };

      this.currentUser = {
        id: me.id ? me.id.toString() : 'unknown',
        firstName: me.firstName || 'Telegram User',
        lastName: me.lastName,
        username: me.username,
        phone: me.phone || this.currentPhone,
      };

      this.setStatus('connected');
      this.setupEventListeners();
      await this.refreshUnreadStats();

      return this.currentUser;
    } catch (err: unknown) {
      const errorMsg = (err as Error)?.message || String(err);
      if (errorMsg.includes('SESSION_PASSWORD_NEEDED') || errorMsg.includes('2FA')) {
        throw new Error('2FA_REQUIRED');
      }
      throw err;
    }
  }

  // Set up live event listeners for Telegram MTProto
  private setupEventListeners() {
    if (!this.client) return;

    // Listen for incoming messages
    this.client.addEventHandler(async (event) => {
      try {
        const message = event.message;
        if (!message || message.out) return; // ignore outgoing messages

        let chatTitle = 'Чат Telegram';
        let senderName = 'Пользователь';
        let chatType: 'private' | 'group' | 'channel' = 'private';

        try {
          const chat = await message.getChat();
          if (chat) {
            chatTitle = (chat as unknown as { title?: string; firstName?: string }).title ||
              (chat as unknown as { firstName?: string }).firstName ||
              'Telegram';
            if ((chat as unknown as { className?: string }).className === 'Channel') {
              chatType = (chat as unknown as { broadcast?: boolean }).broadcast ? 'channel' : 'group';
            } else if ((chat as unknown as { className?: string }).className === 'Chat') {
              chatType = 'group';
            }
          }
        } catch {
          // ignore chat resolution failure
        }

        try {
          const sender = await message.getSender();
          if (sender) {
            senderName = (sender as unknown as { firstName?: string; title?: string }).firstName ||
              (sender as unknown as { title?: string }).title ||
              senderName;
          }
        } catch {
          // ignore sender resolution failure
        }

        const notifItem: NotificationItem = {
          id: `${Date.now()}_${message.id}`,
          chatId: String(message.chatId || message.peerId),
          chatTitle,
          senderName,
          messageText: message.text || (message.media ? '📎 Вложение (фото/файл/стикер)' : 'Новое сообщение'),
          timestamp: new Date(),
          chatType,
          isRead: false,
        };

        // Trigger sound & haptics
        soundService.playNotificationChime();
        soundService.scheduleLocalNotification(
          `${chatTitle}: ${senderName}`,
          notifItem.messageText,
          this.stats.totalUnreadMessages + 1
        );

        this.addNotification(notifItem);

        // Update stats
        await this.refreshUnreadStats();
      } catch (err) {
        console.error('Error handling new message event:', err);
      }
    }, new NewMessage({}));

    // Listen for read updates
    this.client.addEventHandler(async (update) => {
      try {
        if (
          update instanceof Api.UpdateReadHistoryInbox ||
          update instanceof Api.UpdateReadChannelInbox ||
          update instanceof Api.UpdateReadHistoryOutbox
        ) {
          // Recalculate unread stats when messages are read in official app
          await this.refreshUnreadStats();
        }
      } catch {
        // ignore
      }
    });
  }

  // Fetch dialogs and calculate accurate unread messages & chats
  public async refreshUnreadStats(): Promise<UnreadStats> {
    if (!this.client || this.status !== 'connected') {
      return this.stats;
    }

    try {
      const dialogs = await this.client.getDialogs({ limit: 100 });

      let totalUnreadMessages = 0;
      let totalUnreadChats = 0;
      let privateChatsUnread = 0;
      let groupsUnread = 0;
      let channelsUnread = 0;
      let mentionsCount = 0;

      for (const dialog of dialogs) {
        const unread = dialog.unreadCount || 0;
        const mentions = dialog.unreadMentionsCount || 0;

        mentionsCount += mentions;

        if (unread > 0) {
          totalUnreadChats += 1;
          totalUnreadMessages += unread;

          if (dialog.isUser) {
            privateChatsUnread += unread;
          } else if (dialog.isGroup) {
            groupsUnread += unread;
          } else if (dialog.isChannel) {
            channelsUnread += unread;
          }
        }
      }

      const newStats: UnreadStats = {
        totalUnreadMessages,
        totalUnreadChats,
        privateChatsUnread,
        groupsUnread,
        channelsUnread,
        mentionsCount,
        lastUpdated: new Date(),
      };

      this.notifyStats(newStats);
      return newStats;
    } catch (err) {
      console.error('Failed to fetch unread stats:', err);
      return this.stats;
    }
  }

  // Simulate an incoming notification (for demonstration & instant testing)
  public simulateIncomingNotification(
    chatTitle: string = 'Павел Дуров',
    senderName: string = 'Pavel Durov',
    messageText: string = 'Привет! Проверяем как работает отслеживание уведомлений в твоем приложении 🚀',
    chatType: 'private' | 'group' | 'channel' = 'private'
  ) {
    const notifItem: NotificationItem = {
      id: `sim_${Date.now()}`,
      chatId: 'sim_chat',
      chatTitle,
      senderName,
      messageText,
      timestamp: new Date(),
      chatType,
      isRead: false,
    };

    soundService.playNotificationChime();

    const updatedStats: UnreadStats = {
      ...this.stats,
      totalUnreadMessages: this.stats.totalUnreadMessages + 1,
      totalUnreadChats: this.stats.totalUnreadChats + (this.stats.totalUnreadMessages === 0 ? 1 : 0),
      privateChatsUnread: chatType === 'private' ? this.stats.privateChatsUnread + 1 : this.stats.privateChatsUnread,
      groupsUnread: chatType === 'group' ? this.stats.groupsUnread + 1 : this.stats.groupsUnread,
      channelsUnread: chatType === 'channel' ? this.stats.channelsUnread + 1 : this.stats.channelsUnread,
      lastUpdated: new Date(),
    };

    this.notifyStats(updatedStats);
    this.addNotification(notifItem);
    soundService.scheduleLocalNotification(
      `${chatTitle}: ${senderName}`,
      messageText,
      updatedStats.totalUnreadMessages
    );
  }

  public clearAllNotifications() {
    this.notifications = [];
    this.notificationListeners.forEach(cb => cb({} as NotificationItem));
  }

  public resetCounters() {
    const emptyStats: UnreadStats = {
      totalUnreadMessages: 0,
      totalUnreadChats: 0,
      privateChatsUnread: 0,
      groupsUnread: 0,
      channelsUnread: 0,
      mentionsCount: 0,
      lastUpdated: new Date(),
    };
    this.notifyStats(emptyStats);
  }

  public logout() {
    this.sessionString = '';
    this.currentUser = null;
    localStorage.removeItem('tg_session_string');
    localStorage.removeItem('tg_cached_stats');
    if (this.client) {
      try {
        this.client.disconnect();
      } catch {
        // ignore
      }
      this.client = null;
    }
    this.setStatus('disconnected');
  }
}

export const telegramService = new TelegramService();
