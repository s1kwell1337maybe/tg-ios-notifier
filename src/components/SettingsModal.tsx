import React, { useState } from 'react';
import { X, Volume2, Vibrate, Key, RotateCcw, Smartphone, ExternalLink, Check, Download } from 'lucide-react';
import { soundService } from '../services/sound';
import { telegramService } from '../services/telegram';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  onResetCounters: () => void;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({
  isOpen,
  onClose,
  onResetCounters,
}) => {
  const [soundEnabled, setSoundEnabled] = useState(soundService.isSoundEnabled());
  const [hapticsEnabled, setHapticsEnabled] = useState(soundService.isHapticsEnabled());
  
  const currentCreds = telegramService.getApiCredentials();
  const [apiId, setApiId] = useState(String(currentCreds.apiId));
  const [apiHash, setApiHash] = useState(currentCreds.apiHash);
  const [savedSavedMsg, setSavedSavedMsg] = useState(false);

  if (!isOpen) return null;

  const handleToggleSound = () => {
    const next = !soundEnabled;
    setSoundEnabled(next);
    soundService.setSoundEnabled(next);
    if (next) soundService.playNotificationChime();
  };

  const handleToggleHaptics = () => {
    const next = !hapticsEnabled;
    setHapticsEnabled(next);
    soundService.setHapticsEnabled(next);
    if (next) soundService.playNotificationChime();
  };

  const handleSaveApiCreds = (e: React.FormEvent) => {
    e.preventDefault();
    if (apiId && apiHash) {
      telegramService.saveApiCredentials(parseInt(apiId, 10), apiHash.trim());
      setSavedSavedMsg(true);
      setTimeout(() => setSavedSavedMsg(false), 2500);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-md">
      <div className="glass-panel w-full max-w-md p-6 relative shadow-2xl border border-white/15 pop-in max-h-[90vh] overflow-y-auto">
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-2 rounded-full bg-white/10 hover:bg-white/20 text-slate-300 hover:text-white transition-all"
        >
          <X size={18} />
        </button>

        <h3 className="text-lg font-bold text-white mb-5 flex items-center space-x-2">
          <span>Настройки приложения</span>
        </h3>

        {/* Audio & Haptic section */}
        <div className="space-y-3 mb-6">
          <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Уведомления</h4>

          {/* Sound Toggle */}
          <div className="glass-panel p-3.5 flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 rounded-xl bg-sky-500/20 text-sky-400 flex items-center justify-center">
                <Volume2 size={16} />
              </div>
              <div>
                <div className="text-sm font-semibold text-white">Звук iOS уведомлений</div>
                <div className="text-xs text-slate-400">Проигрывать фирменный сигнал</div>
              </div>
            </div>
            <div
              className={`ios-toggle ${soundEnabled ? 'active' : ''}`}
              onClick={handleToggleSound}
            >
              <div className="ios-toggle-knob" />
            </div>
          </div>

          {/* Haptics Toggle */}
          <div className="glass-panel p-3.5 flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 rounded-xl bg-purple-500/20 text-purple-400 flex items-center justify-center">
                <Vibrate size={16} />
              </div>
              <div>
                <div className="text-sm font-semibold text-white">Вибрация (Haptic Feedback)</div>
                <div className="text-xs text-slate-400">Тактильный отклик Taptic Engine</div>
              </div>
            </div>
            <div
              className={`ios-toggle ${hapticsEnabled ? 'active' : ''}`}
              onClick={handleToggleHaptics}
            >
              <div className="ios-toggle-knob" />
            </div>
          </div>
        </div>

        {/* Telegram API Credentials */}
        <div className="space-y-3 mb-6">
          <div className="flex items-center justify-between">
            <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">Telegram API</h4>
            <a
              href="https://my.telegram.org/apps"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[11px] text-sky-400 hover:underline inline-flex items-center space-x-1"
            >
              <span>my.telegram.org</span>
              <ExternalLink size={10} />
            </a>
          </div>

          <form onSubmit={handleSaveApiCreds} className="space-y-3">
            <div>
              <label className="block text-[11px] font-semibold text-slate-300 mb-1">
                API ID
              </label>
              <input
                type="text"
                value={apiId}
                onChange={(e) => setApiId(e.target.value)}
                className="w-full px-3 py-2 rounded-xl bg-white/5 border border-white/15 text-white text-xs font-mono focus:outline-none focus:border-sky-400"
              />
            </div>

            <div>
              <label className="block text-[11px] font-semibold text-slate-300 mb-1">
                API Hash
              </label>
              <input
                type="text"
                value={apiHash}
                onChange={(e) => setApiHash(e.target.value)}
                className="w-full px-3 py-2 rounded-xl bg-white/5 border border-white/15 text-white text-xs font-mono focus:outline-none focus:border-sky-400"
              />
            </div>

            <div className="flex items-center justify-between pt-1">
              <span className="text-[10px] text-slate-400">По умолчанию используются официальные ключи Web</span>
              <button
                type="submit"
                className="ios-btn ios-btn-secondary px-3 py-1.5 text-xs font-semibold flex items-center space-x-1"
              >
                {savedSavedMsg ? (
                  <>
                    <Check size={12} className="text-emerald-400" />
                    <span className="text-emerald-400">Сохранено</span>
                  </>
                ) : (
                  <span>Сохранить</span>
                )}
              </button>
            </div>
          </form>
        </div>

        {/* IPA iOS Export Info */}
        <div className="space-y-3 mb-6">
          <h4 className="text-xs font-bold text-slate-400 uppercase tracking-wider">iOS IPA Сборка</h4>
          <div className="glass-panel p-3.5 space-y-2">
            <div className="flex items-center space-x-2 text-sky-400">
              <Smartphone size={16} />
              <span className="text-xs font-bold">Готово для установки на iPhone</span>
            </div>
            <p className="text-xs text-slate-300 leading-relaxed">
              Приложение готово к сборке в <b>.ipa</b> через встроенный GitHub Actions или Capacitor Xcode.
            </p>
            <div className="text-[11px] text-slate-400 space-y-1 pt-1">
              <div>• Поддерживается TrollStore, Sideloadly, AltStore, Scarlet</div>
              <div>• Bundle ID: <code className="text-sky-300 bg-white/10 px-1 py-0.5 rounded">com.telegram.notifier</code></div>
            </div>
          </div>
        </div>

        {/* Counter Reset */}
        <div className="pt-2 border-t border-white/10 flex justify-between items-center">
          <span className="text-xs text-slate-400">Сброс счетчиков</span>
          <button
            onClick={() => {
              onResetCounters();
              onClose();
            }}
            className="ios-btn ios-btn-danger px-3 py-1.5 text-xs font-semibold flex items-center space-x-1.5"
          >
            <RotateCcw size={13} />
            <span>Обнулить счетчики</span>
          </button>
        </div>
      </div>
    </div>
  );
};
