import { TelegramClient, Api } from 'telegram';
import { StringSession } from 'telegram/sessions';
import { NewMessage } from 'telegram/events';

declare global {
  interface Window {
    tgBridgeClient: TelegramClient | null;
    phoneCodeHash: string;
    sendToNative: (type: string, payload: any) => void;
    initTelegram: (apiId: number, apiHash: string, sessionStr: string, dcId: number) => Promise<void>;
    sendCode: (phone: string, apiId: number, apiHash: string, dcId: number) => Promise<void>;
    signIn: (phone: string, code: string, password?: string) => Promise<void>;
    fetchUnreads: () => Promise<void>;
    logOut: () => Promise<void>;
    webkit?: {
      messageHandlers?: {
        tgNativeBridge?: {
          postMessage: (msg: any) => void;
        };
      };
    };
  }
}

window.tgBridgeClient = null;
window.phoneCodeHash = '';

window.sendToNative = function (type: string, payload: any) {
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.tgNativeBridge) {
    window.webkit.messageHandlers.tgNativeBridge.postMessage({ type, payload });
  } else {
    console.log('[NativeBridge]', type, payload);
  }
};

window.initTelegram = async function (apiId: number, apiHash: string, sessionStr: string, dcId: number) {
  try {
    const session = new StringSession(sessionStr || '');
    if (Number(dcId) === 2) {
      session.setDC(2, 'venus.web.telegram.org', 443);
    } else {
      session.setDC(4, 'vesta.web.telegram.org', 443);
    }

    const client = new TelegramClient(session, Number(apiId), apiHash, {
      connectionRetries: 10,
      useWSS: true,
      deviceModel: 'Apple iPad / iPhone',
      systemVersion: 'iOS 18.0',
      appVersion: '1.0.0',
      langCode: 'ru',
      systemLangCode: 'ru',
    });

    window.tgBridgeClient = client;
    await client.connect();
    window.sendToNative('CONNECTED', { dc: dcId });

    const isAuth = await client.checkAuthorization();
    if (isAuth) {
      const me: any = await client.getMe();
      const savedSession = client.session.save() as unknown as string;
      window.sendToNative('AUTH_SUCCESS', {
        id: String(me.id || ''),
        firstName: me.firstName || 'User',
        lastName: me.lastName || '',
        username: me.username || '',
        phone: me.phone || '',
        session: savedSession,
      });
      setupListener(client);
      window.fetchUnreads();
    }
  } catch (err: any) {
    console.error('initTelegram error:', err);
    window.sendToNative('ERROR', { message: err?.message || String(err) });
  }
};

window.sendCode = async function (phone: string, apiId: number, apiHash: string, dcId: number) {
  try {
    const session = new StringSession('');
    if (Number(dcId) === 2) {
      session.setDC(2, 'venus.web.telegram.org', 443);
    } else {
      session.setDC(4, 'vesta.web.telegram.org', 443);
    }

    const client = new TelegramClient(session, Number(apiId), apiHash, {
      connectionRetries: 10,
      useWSS: true,
      deviceModel: 'Apple iPad / iPhone',
      systemVersion: 'iOS 18.0',
      appVersion: '1.0.0',
      langCode: 'ru',
      systemLangCode: 'ru',
    });

    window.tgBridgeClient = client;
    await client.connect();

    const res = await client.sendCode(
      {
        apiId: Number(apiId),
        apiHash: apiHash,
      },
      phone.trim()
    );

    window.phoneCodeHash = res.phoneCodeHash;
    window.sendToNative('CODE_SENT', { phoneCodeHash: res.phoneCodeHash });
  } catch (err: any) {
    console.error('sendCode error:', err);
    window.sendToNative('SEND_CODE_ERROR', { message: err?.message || String(err) });
  }
};

window.signIn = async function (phone: string, code: string, password?: string) {
  try {
    const client = window.tgBridgeClient;
    if (!client) throw new Error('MTProto клиент не подключен');

    if (password) {
      await client.signInWithPassword(
        {
          apiId: 17349,
          apiHash: '344583e45741c457fe1862106095a5eb',
        },
        {
          password: async () => password,
          onError: (err) => console.error('2FA error:', err),
        }
      );
    } else {
      await client.invoke(
        new Api.auth.SignIn({
          phoneNumber: phone.trim(),
          phoneCodeHash: window.phoneCodeHash,
          phoneCode: code.trim(),
        })
      );
    }

    const savedSession = client.session.save() as unknown as string;
    const me: any = await client.getMe();
    window.sendToNative('AUTH_SUCCESS', {
      id: String(me.id || ''),
      firstName: me.firstName || 'User',
      lastName: me.lastName || '',
      username: me.username || '',
      phone: me.phone || phone,
      session: savedSession,
    });
    setupListener(client);
    window.fetchUnreads();
  } catch (err: any) {
    const msg = err?.message || String(err);
    if (msg.includes('SESSION_PASSWORD_NEEDED') || msg.includes('2FA')) {
      window.sendToNative('2FA_REQUIRED', {});
    } else {
      window.sendToNative('SIGN_IN_ERROR', { message: msg });
    }
  }
};

function setupListener(client: TelegramClient) {
  client.addEventHandler(async (event: any) => {
    try {
      const message = event.message;
      if (!message || message.out) return;

      let chatTitle = 'Чат Telegram';
      let senderName = 'Пользователь';
      let chatType = 'private';

      try {
        const chat = await message.getChat();
        if (chat) {
          chatTitle = chat.title || chat.firstName || 'Telegram';
          if (chat.className === 'Channel') chatType = chat.broadcast ? 'channel' : 'group';
          else if (chat.className === 'Chat') chatType = 'group';
        }
      } catch {}

      try {
        const sender = await message.getSender();
        if (sender) senderName = sender.firstName || sender.title || senderName;
      } catch {}

      window.sendToNative('NEW_MESSAGE', {
        id: String(message.id),
        chatId: String(message.chatId || message.peerId),
        chatTitle: chatTitle,
        senderName: senderName,
        messageText: message.text || '📎 Новое вложение',
        chatType: chatType,
      });

      window.fetchUnreads();
    } catch {}
  }, new NewMessage({}));
}

window.fetchUnreads = async function () {
  try {
    const client = window.tgBridgeClient;
    if (!client) return;
    const dialogs = await client.getDialogs({ limit: 100 });
    let total = 0, chats = 0, priv = 0, grp = 0, chn = 0, mentions = 0;
    for (const d of dialogs) {
      const unread = d.unreadCount || 0;
      mentions += (d as any).unreadMentionsCount || 0;
      if (unread > 0) {
        chats++;
        total += unread;
        if (d.isUser) priv += unread;
        else if (d.isGroup) grp += unread;
        else if (d.isChannel) chn += unread;
      }
    }
    window.sendToNative('UNREAD_STATS', {
      totalUnreadMessages: total,
      totalUnreadChats: chats,
      privateChatsUnread: priv,
      groupsUnread: grp,
      channelsUnread: chn,
      mentionsCount: mentions,
    });
  } catch {}
};

window.logOut = async function () {
  try {
    if (window.tgBridgeClient) {
      await window.tgBridgeClient.invoke(new Api.auth.LogOut());
      window.tgBridgeClient = null;
    }
    window.sendToNative('LOGOUT_SUCCESS', {});
  } catch {}
};

// Signal ready to native iOS
setTimeout(() => {
  window.sendToNative('ENGINE_READY', {});
}, 100);
