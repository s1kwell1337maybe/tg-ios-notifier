// Runtime polyfill for WebKit / iOS WKWebView
if (typeof window !== 'undefined') {
  const osMock = {
    type: () => 'iOS',
    release: () => '18.0',
    platform: () => 'darwin',
    arch: () => 'arm64',
    homedir: () => '/home',
    tmpdir: () => '/tmp',
    hostname: () => 'iphone',
    endianness: () => 'LE',
    totalmem: () => 4 * 1024 * 1024 * 1024,
    freemem: () => 2 * 1024 * 1024 * 1024,
    cpus: () => [],
    networkInterfaces: () => ({}),
  };
  (window as unknown as { os?: typeof osMock; global?: unknown }).os = osMock;
  (window as unknown as { global?: unknown }).global = window;
}

import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
