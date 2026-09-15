import { Haptics, ImpactStyle } from '@capacitor/haptics';
import { LocalNotifications } from '@capacitor/local-notifications';

class SoundService {
  private audioCtx: AudioContext | null = null;
  private soundEnabled: boolean = true;
  private hapticsEnabled: boolean = true;

  constructor() {
    // Check stored preferences
    const savedSound = localStorage.getItem('tg_notify_sound');
    if (savedSound !== null) {
      this.soundEnabled = savedSound === 'true';
    }
    const savedHaptics = localStorage.getItem('tg_notify_haptics');
    if (savedHaptics !== null) {
      this.hapticsEnabled = savedHaptics === 'true';
    }
  }

  public setSoundEnabled(enabled: boolean) {
    this.soundEnabled = enabled;
    localStorage.setItem('tg_notify_sound', String(enabled));
  }

  public isSoundEnabled(): boolean {
    return this.soundEnabled;
  }

  public setHapticsEnabled(enabled: boolean) {
    this.hapticsEnabled = enabled;
    localStorage.setItem('tg_notify_haptics', String(enabled));
  }

  public isHapticsEnabled(): boolean {
    return this.hapticsEnabled;
  }

  // Play realistic iOS Tri-Tone / Note notification chime
  public async playNotificationChime() {
    if (this.hapticsEnabled) {
      try {
        await Haptics.impact({ style: ImpactStyle.Heavy });
      } catch {
        // Fallback for web browsers
        if ('vibrate' in navigator) {
          navigator.vibrate([40, 60, 40]);
        }
      }
    }

    if (!this.soundEnabled) return;

    try {
      const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (!AudioContextClass) return;

      if (!this.audioCtx || this.audioCtx.state === 'suspended') {
        this.audioCtx = new AudioContextClass();
      }

      const ctx = this.audioCtx;
      if (ctx.state === 'suspended') {
        await ctx.resume();
      }

      const now = ctx.currentTime;

      // Note 1: 880Hz (A5)
      const osc1 = ctx.createOscillator();
      const gain1 = ctx.createGain();
      osc1.type = 'sine';
      osc1.frequency.setValueAtTime(880, now);
      gain1.gain.setValueAtTime(0, now);
      gain1.gain.linearRampToValueAtTime(0.25, now + 0.02);
      gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.18);
      osc1.connect(gain1);
      gain1.connect(ctx.destination);
      osc1.start(now);
      osc1.stop(now + 0.2);

      // Note 2: 1318.51Hz (E6)
      const osc2 = ctx.createOscillator();
      const gain2 = ctx.createGain();
      osc2.type = 'sine';
      osc2.frequency.setValueAtTime(1318.51, now + 0.09);
      gain2.gain.setValueAtTime(0, now + 0.09);
      gain2.gain.linearRampToValueAtTime(0.3, now + 0.11);
      gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.start(now + 0.09);
      osc2.stop(now + 0.38);

      // Note 3: 1760Hz (A6 chime)
      const osc3 = ctx.createOscillator();
      const gain3 = ctx.createGain();
      osc3.type = 'sine';
      osc3.frequency.setValueAtTime(1760, now + 0.18);
      gain3.gain.setValueAtTime(0, now + 0.18);
      gain3.gain.linearRampToValueAtTime(0.28, now + 0.20);
      gain3.gain.exponentialRampToValueAtTime(0.0001, now + 0.55);
      osc3.connect(gain3);
      gain3.connect(ctx.destination);
      osc3.start(now + 0.18);
      osc3.stop(now + 0.6);
    } catch (e) {
      console.warn('Audio playback error:', e);
    }
  }

  // Push local notification in iOS background/foreground
  public async scheduleLocalNotification(title: string, body: string, count: number) {
    try {
      await LocalNotifications.schedule({
        notifications: [
          {
            title: `💬 ${title}`,
            body: body,
            id: Date.now() % 100000,
            schedule: { at: new Date(Date.now() + 100) },
            sound: 'beep.wav',
            actionTypeId: '',
            extra: { badge: count },
          }
        ]
      });
    } catch {
      // Local notifications plugin not active on web desktop preview
    }
  }
}

export const soundService = new SoundService();
