import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.telegram.notifier',
  appName: 'TG Notifier',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    iosScheme: 'ionic'
  },
  ios: {
    contentInset: 'always',
    backgroundColor: '#0b1320',
    preferredContentMode: 'mobile'
  },
  plugins: {
    LocalNotifications: {
      smallIcon: 'ic_stat_icon_config_sample',
      iconColor: '#24A1DE',
      sound: 'beep.wav'
    }
  }
};

export default config;
