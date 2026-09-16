import { TelegramClient, Api } from 'telegram';
import { StringSession } from 'telegram/sessions';
import { NewMessage } from 'telegram/events';

declare global {
  interface Window {
    tgBridgeClient: TelegramClient | null;
    phoneCodeHash: string;
    currentDc: number;
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
window.currentDc = 4;

const DC_SERVERS: Record<number, string> = {
  1: 'pluto.web.telegram.org',
  2: 'venus.web.telegram.org',
  3: 'aurora.web.telegram.org',
  4: 'vesta.web.telegram.org',
  5: 'flora.web.telegram.org',
};

window.sendToNative = function (type: string, payload: any) {
  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.tgNativeBridge) {
    window.webkit.messageHandlers.tgNativeBridge.postMessage({ type, payload });
  } else {
    console.log('[NativeBridge]', type, payload);
  }
};

async function createClient(apiId: number, apiHash: string, dcId: number, sessionStr: string = '') {
  const session = new StringSession(sessionStr || '');
  const dc = Number(dcId) || 4;
  const server = DC_SERVERS[dc] || 'vesta.web.telegram.org';
  session.setDC(dc, server, 443);

  const client = new TelegramClient(session, Number(apiId), apiHash, {
    connectionRetries: 10,
    useWSS: true,
    deviceModel: 'Apple iPhone (Native iOS)',
    systemVersion: 'iOS 18.0',
    appVersion: '1.0.0',
    langCode: 'ru',
    systemLangCode: 'ru',
  });

  await client.connect();
  return client;
}

window.initTelegram = async function (apiId: number, apiHash: string, sessionStr: string, dcId: number) {
  try {
    if (window.tgBridgeClient) {
      try { await window.tgBridgeClient.disconnect(); } catch {}
    }

    const client = await createClient(Number(apiId), apiHash, Number(dcId) || 4, sessionStr);
    window.tgBridgeClient = client;
    window.currentDc = Number(dcId) || 4;
    window.sendToNative('CONNECTED', { dc: window.currentDc });

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
        dc: window.currentDc,
      });
      setupListener(client);
      window.fetchUnreads();
    }
  } catch (err: any) {
    console.error('initTelegram error:', err);
    window.sendToNative('ERROR', { message: err?.message || String(err) });
  }
};

window.sendCode = async function (phone: string, apiId: number, apiHash: string, initialDcId: number) {
  let targetDc = Number(initialDcId) || 4;
  const cleanPhone = phone.replace(/[^\d+]/g, '').trim();

  for (let attempt = 0; attempt < 4; attempt++) {
    try {
      console.log(`Attempting sendCode on DC ${targetDc} for ${cleanPhone}...`);
      if (window.tgBridgeClient) {
        try { await window.tgBridgeClient.disconnect(); } catch {}
      }

      const client = await createClient(Number(apiId), apiHash, targetDc, '');
      window.tgBridgeClient = client;
      window.currentDc = targetDc;

      const res = await client.sendCode(
        {
          apiId: Number(apiId),
          apiHash: apiHash,
        },
        cleanPhone
      );

      window.phoneCodeHash = res.phoneCodeHash;
      window.sendToNative('CODE_SENT', { phoneCodeHash: res.phoneCodeHash, dc: targetDc });
      return;
    } catch (err: any) {
      console.error(`sendCode failed on DC ${targetDc}:`, err);
      const msg = err?.message || err?.errorMessage || String(err);

      // Auto DC Migration Detection (PHONE_MIGRATE_X, NETWORK_MIGRATE_X, USER_MIGRATE_X)
      const match = msg.match(/(?:PHONE|NETWORK|USER)_MIGRATE_(\d+)/i);
      if (match && match[1]) {
        const newDc = parseInt(match[1], 10);
        console.log(`Telegram requested migration from DC ${targetDc} -> DC ${newDc}`);
        targetDc = newDc;
        continue;
      }

      // If failed on DC 2 due to connection timeout or network issue, fallback to DC 4
      if (targetDc === 2 && (msg.includes('TIMEOUT') || msg.includes('network') || msg.includes('Failed to fetch') || msg.includes('CONNECTION'))) {
        console.log('DC 2 connection issue, retrying on DC 4...');
        targetDc = 4;
        continue;
      }

      // If failed on DC 4 due to connection, try DC 2 as alternate
      if (targetDc === 4 && attempt === 0 && (msg.includes('TIMEOUT') || msg.includes('CONNECTION'))) {
        console.log('DC 4 timeout, trying DC 2...');
        targetDc = 2;
        continue;
      }

      window.sendToNative('SEND_CODE_ERROR', { message: msg, dc: targetDc });
      return;
    }
  }
};

window.signIn = async function (phone: string, code: string, password?: string) {
  try {
    const client = window.tgBridgeClient;
    if (!client) throw new Error('MTProto клиент не подключен');
    const cleanPhone = phone.replace(/[^\d+]/g, '').trim();

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
          phoneNumber: cleanPhone,
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
      phone: me.phone || cleanPhone,
      session: savedSession,
      dc: window.currentDc,
    });
    setupListener(client);
    window.fetchUnreads();
  } catch (err: any) {
    const msg = err?.message || err?.errorMessage || String(err);
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
