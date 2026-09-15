import { defineConfig } from 'vite';
import { nodePolyfills } from 'vite-plugin-node-polyfills';
import path from 'path';

export default defineConfig({
  plugins: [
    nodePolyfills({
      include: ['buffer', 'crypto', 'stream', 'util', 'process', 'events', 'os', 'path', 'net', 'fs', 'constants'],
      globals: {
        Buffer: true,
        global: true,
        process: true,
      },
    }),
  ],
  define: {
    'process.env': {},
    global: 'window',
  },
  build: {
    outDir: 'TelegramNotifier/Resources',
    emptyOutDir: false,
    lib: {
      entry: path.resolve(__dirname, 'src/engine/telegramBridge.ts'),
      name: 'TelegramBridge',
      formats: ['iife'],
      fileName: () => 'telegram_engine.js',
    },
    sourcemap: false,
    minify: true,
  },
});
