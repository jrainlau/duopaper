import { createRoot } from 'react-dom/client';
import App from './App.jsx';
import { systemLanguage } from './i18n/index.js';
import './styles/tokens.css';
import './styles/app.css';
import './styles/device.css';

// <html lang> 跟随解析出的系统语言，方便读屏与翻译工具。
document.documentElement.lang = systemLanguage();

// 不用 StrictMode：开发期双调用会重复消耗 Unsplash Demo 应用 50 次/小时的配额。
createRoot(document.getElementById('root')).render(<App />);
