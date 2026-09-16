import React, { useState } from 'react';
import { X, Send, Key, Lock, CheckCircle2, AlertCircle, LogOut, Phone, Shield, Globe, SlidersHorizontal } from 'lucide-react';
import { telegramService, TelegramUser, TELEGRAM_PRESETS } from '../services/telegram';

interface LoginModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentUser: TelegramUser | null;
  onLoginSuccess: (user: TelegramUser) => void;
  onLogout: () => void;
}

function formatPhoneNumber(raw: string): string {
  const digits = raw.replace(/\D/g, '');
  if (!digits) return '+7 ';
  let d = digits;
  if (d.startsWith('8') && d.length > 1) {
    d = '7' + d.slice(1);
  } else if (!d.startsWith('7') && !d.startsWith('1') && !d.startsWith('3')) {
    d = '7' + d;
  }
  if (d.startsWith('7')) {
    const num = d.slice(1);
    let res = '+7';
    if (num.length > 0) res += ' ' + num.slice(0, 3);
    if (num.length > 3) res += ' ' + num.slice(3, 6);
    if (num.length > 6) res += ' ' + num.slice(6, 10);
    return res;
  }
  return '+' + d;
}

export const LoginModal: React.FC<LoginModalProps> = ({
  isOpen,
  onClose,
  currentUser,
  onLoginSuccess,
  onLogout,
}) => {
  const [step, setStep] = useState<'phone' | 'code' | 'password'>('phone');
  const [phone, setPhone] = useState('+7 925 043 1339');
  const [code, setCode] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [selectedDc, setSelectedDc] = useState<number>(4); // Default to DC 4 (World / Main) with auto-migration
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [customApiId, setCustomApiId] = useState(String(telegramService.getApiCredentials().apiId));
  const [customApiHash, setCustomApiHash] = useState(telegramService.getApiCredentials().apiHash);

  if (!isOpen) return null;

  const handleSelectPreset = (preset: typeof TELEGRAM_PRESETS[0]) => {
    setCustomApiId(String(preset.apiId));
    setCustomApiHash(preset.apiHash);
    telegramService.saveApiCredentials(preset.apiId, preset.apiHash);
  };

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');
    if (!phone || phone.length < 8) {
      setErrorMsg('Введите корректный номер телефона (например, +79250431339)');
      return;
    }

    if (customApiId && customApiHash) {
      telegramService.saveApiCredentials(parseInt(customApiId, 10), customApiHash.trim());
    }

    setIsLoading(true);
    try {
      await telegramService.sendCode(phone, selectedDc);
      setStep('code');
    } catch (err: unknown) {
      const msg = (err as Error)?.message || String(err);
      if (msg.includes('API_ID_INVALID')) {
        // Fallback to WebZ preset
        telegramService.saveApiCredentials(17349, '344583e45741c457fe1862106095a5eb');
        try {
          await telegramService.sendCode(phone, selectedDc);
          setStep('code');
          return;
        } catch (retryErr: unknown) {
          setErrorMsg(`Ошибка API: ${(retryErr as Error)?.message || 'Попробуйте сменить пресет ключей'}`);
        }
      } else if (msg.includes('PHONE_NUMBER_INVALID')) {
        setErrorMsg('Неверный формат номера телефона. Введите в формате +79250431339');
      } else if (msg.includes('FLOOD_WAIT')) {
        setErrorMsg('Слишком много запросов кода. Подождите несколько минут перед следующей попыткой');
      } else {
        setErrorMsg(`Ошибка отправки кода: ${msg}`);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');
    if (!code || code.length < 5) {
      setErrorMsg('Введите полученный в Telegram код подтверждения');
      return;
    }

    setIsLoading(true);
    try {
      const user = await telegramService.signIn({ code });
      onLoginSuccess(user);
      onClose();
    } catch (err: unknown) {
      const msg = (err as Error)?.message || String(err);
      if (msg === '2FA_REQUIRED' || msg.includes('SESSION_PASSWORD_NEEDED')) {
        setStep('password');
      } else if (msg.includes('PHONE_CODE_INVALID')) {
        setErrorMsg('Неверный код подтверждения. Проверьте сообщения в Telegram');
      } else if (msg.includes('PHONE_CODE_EXPIRED')) {
        setErrorMsg('Срок действия кода истек. Запросите новый код');
        setStep('phone');
      } else {
        setErrorMsg(`Ошибка входа: ${msg}`);
      }
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');
    if (!password) {
      setErrorMsg('Введите ваш 2FA пароль');
      return;
    }

    setIsLoading(true);
    try {
      const user = await telegramService.signIn({ code, password });
      onLoginSuccess(user);
      onClose();
    } catch (err: unknown) {
      const msg = (err as Error)?.message || String(err);
      if (msg.includes('PASSWORD_HASH_INVALID')) {
        setErrorMsg('Неверный пароль двухэтапной аутентификации');
      } else {
        setErrorMsg(`Ошибка авторизации: ${msg}`);
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-md">
      <div className="glass-panel w-full max-w-md p-6 relative shadow-2xl border border-white/15 pop-in max-h-[92vh] overflow-y-auto">
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 rounded-full bg-white/10 hover:bg-white/20 text-slate-300 hover:text-white transition-all"
        >
          <X size={18} />
        </button>

        {/* If already logged in */}
        {currentUser ? (
          <div className="text-center py-2">
            <div className="w-16 h-16 rounded-full bg-gradient-to-tr from-sky-400 to-blue-600 mx-auto flex items-center justify-center text-white text-2xl font-bold shadow-lg mb-3">
              {currentUser.firstName.charAt(0).toUpperCase()}
            </div>
            <h3 className="text-lg font-bold text-white">
              {currentUser.firstName} {currentUser.lastName || ''}
            </h3>
            <p className="text-sm text-sky-400 font-medium">
              {currentUser.username ? `@${currentUser.username}` : currentUser.phone}
            </p>
            <div className="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-400 text-xs font-semibold mt-2 border border-emerald-500/30">
              <CheckCircle2 size={13} />
              <span>Авторизован в Telegram MTProto</span>
            </div>

            <div className="mt-6 pt-4 border-t border-white/10 flex gap-3">
              <button
                onClick={onClose}
                className="ios-btn ios-btn-secondary flex-1 py-2.5 text-sm font-semibold"
              >
                Закрыть
              </button>
              <button
                onClick={() => {
                  onLogout();
                  setStep('phone');
                }}
                className="ios-btn ios-btn-danger flex-1 py-2.5 text-sm font-semibold flex items-center justify-center space-x-1.5"
              >
                <LogOut size={16} />
                <span>Выйти</span>
              </button>
            </div>
          </div>
        ) : (
          <div>
            {/* Header */}
            <div className="text-center mb-4">
              <div className="w-12 h-12 rounded-2xl bg-sky-500/20 border border-sky-400/30 mx-auto flex items-center justify-center text-sky-400 shadow-md mb-2">
                <Shield size={24} />
              </div>
              <h3 className="text-lg font-bold text-white">Авторизация в Telegram</h3>
              <p className="text-xs text-slate-400 mt-0.5">
                Прямое подключение к серверам Telegram по MTProto
              </p>
            </div>

            {errorMsg && (
              <div className="mb-4 p-3 rounded-xl bg-rose-500/20 border border-rose-500/40 text-rose-300 text-xs flex items-start space-x-2">
                <AlertCircle size={16} className="flex-shrink-0 mt-0.5 text-rose-400" />
                <span className="leading-relaxed">{errorMsg}</span>
              </div>
            )}

            {/* Step 1: Phone */}
            {step === 'phone' && (
              <form onSubmit={handleSendCode} className="space-y-4">
                {/* Region / DC selector */}
                <div>
                  <label className="block text-[11px] font-semibold text-slate-300 mb-1.5">
                    Шлюз подключения (Без VPN)
                  </label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setSelectedDc(2)}
                      className={`px-3 py-2 rounded-xl text-xs font-semibold flex items-center justify-center space-x-1.5 border transition-all ${
                        selectedDc === 2
                          ? 'bg-sky-500/20 border-sky-400 text-sky-300'
                          : 'bg-white/5 border-white/10 text-slate-400 hover:bg-white/10'
                      }`}
                    >
                      <Globe size={13} />
                      <span>🇷🇺 Россия (DC 2)</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setSelectedDc(4)}
                      className={`px-3 py-2 rounded-xl text-xs font-semibold flex items-center justify-center space-x-1.5 border transition-all ${
                        selectedDc === 4
                          ? 'bg-sky-500/20 border-sky-400 text-sky-300'
                          : 'bg-white/5 border-white/10 text-slate-400 hover:bg-white/10'
                      }`}
                    >
                      <Globe size={13} />
                      <span>🌍 Мир (DC 4)</span>
                    </button>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                    Номер телефона
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                      <Phone size={16} />
                    </div>
                    <input
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(formatPhoneNumber(e.target.value))}
                      placeholder="+7 925 043 1339"
                      required
                      className="w-full pl-10 pr-4 py-3 rounded-xl bg-white/5 border border-white/15 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-sky-400 transition-colors"
                    />
                  </div>
                  <span className="block text-[11px] text-slate-400 mt-1">
                    Официальный код безопасности придет в приложение Telegram
                  </span>
                </div>

                {/* Advanced API Config Collapsible */}
                <div className="pt-1">
                  <button
                    type="button"
                    onClick={() => setShowAdvanced(!showAdvanced)}
                    className="text-[11px] text-slate-400 hover:text-sky-300 flex items-center space-x-1"
                  >
                    <SlidersHorizontal size={12} />
                    <span>{showAdvanced ? 'Скрыть выбор API ключей' : 'Выбрать пресет API ключей (WebZ / Android)'}</span>
                  </button>

                  {showAdvanced && (
                    <div className="mt-2.5 p-3 rounded-xl bg-white/5 border border-white/10 space-y-2.5">
                      <div className="text-[10px] text-slate-400 font-semibold uppercase">Пресеты ключей:</div>
                      <div className="flex gap-2">
                        {TELEGRAM_PRESETS.map((p) => (
                          <button
                            key={p.apiId}
                            type="button"
                            onClick={() => handleSelectPreset(p)}
                            className={`flex-1 py-1.5 px-2 rounded-lg text-[11px] font-semibold border transition-all ${
                              customApiId === String(p.apiId)
                                ? 'bg-sky-500/20 border-sky-400 text-sky-300'
                                : 'bg-white/5 border-white/10 text-slate-400 hover:bg-white/10'
                            }`}
                          >
                            {p.name.split(' ')[1] || p.name}
                          </button>
                        ))}
                      </div>

                      <div>
                        <label className="block text-[10px] text-slate-400 mb-1">API ID:</label>
                        <input
                          type="text"
                          value={customApiId}
                          onChange={(e) => setCustomApiId(e.target.value)}
                          className="w-full px-2.5 py-1.5 rounded-lg bg-black/40 border border-white/15 text-white text-xs font-mono"
                        />
                      </div>
                      <div>
                        <label className="block text-[10px] text-slate-400 mb-1">API Hash:</label>
                        <input
                          type="text"
                          value={customApiHash}
                          onChange={(e) => setCustomApiHash(e.target.value)}
                          className="w-full px-2.5 py-1.5 rounded-lg bg-black/40 border border-white/15 text-white text-xs font-mono"
                        />
                      </div>
                    </div>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="ios-btn ios-btn-primary w-full py-3 text-sm font-semibold flex items-center justify-center space-x-2 shadow-lg"
                >
                  {isLoading ? (
                    <span className="animate-pulse">Подключение и отправка кода...</span>
                  ) : (
                    <>
                      <span>Получить код в Telegram</span>
                      <Send size={15} />
                    </>
                  )}
                </button>
              </form>
            )}

            {/* Step 2: Code */}
            {step === 'code' && (
              <form onSubmit={handleVerifyCode} className="space-y-4">
                <div>
                  <div className="flex justify-between items-center mb-1.5">
                    <label className="text-xs font-semibold text-slate-300">
                      Код из Telegram
                    </label>
                    <button
                      type="button"
                      onClick={() => setStep('phone')}
                      className="text-[11px] text-sky-400 hover:underline"
                    >
                      Изменить номер ({phone})
                    </button>
                  </div>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                      <Key size={16} />
                    </div>
                    <input
                      type="text"
                      value={code}
                      onChange={(e) => setCode(e.target.value)}
                      placeholder="12345"
                      autoFocus
                      required
                      className="w-full pl-10 pr-4 py-3 rounded-xl bg-white/5 border border-white/15 text-white placeholder-slate-500 text-base tracking-widest font-mono text-center focus:outline-none focus:border-sky-400 transition-colors"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="ios-btn ios-btn-primary w-full py-3 text-sm font-semibold flex items-center justify-center space-x-2"
                >
                  {isLoading ? (
                    <span className="animate-pulse">Вход в аккаунт...</span>
                  ) : (
                    <>
                      <span>Подтвердить и войти</span>
                      <CheckCircle2 size={16} />
                    </>
                  )}
                </button>
              </form>
            )}

            {/* Step 3: 2FA Password */}
            {step === 'password' && (
              <form onSubmit={handleVerifyPassword} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                    Пароль 2-факторной аутентификации (2FA)
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                      <Lock size={16} />
                    </div>
                    <input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Ваш облачный пароль"
                      autoFocus
                      required
                      className="w-full pl-10 pr-4 py-3 rounded-xl bg-white/5 border border-white/15 text-white placeholder-slate-500 text-sm focus:outline-none focus:border-sky-400 transition-colors"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="ios-btn ios-btn-primary w-full py-3 text-sm font-semibold flex items-center justify-center space-x-2"
                >
                  {isLoading ? (
                    <span className="animate-pulse">Проверка пароля...</span>
                  ) : (
                    <>
                      <span>Войти с паролем</span>
                      <CheckCircle2 size={16} />
                    </>
                  )}
                </button>
              </form>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
