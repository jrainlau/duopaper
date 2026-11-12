// 轻量 i18n：跟随系统语言（navigator.languages），会话内固定，无需响应式切换。
// 用法：t('key')、t('key', { author })，模板里用 {name} 占位。
import en from './en.js';
import zhHans from './zh-Hans.js';
import zhHant from './zh-Hant.js';

const TABLES = { en, 'zh-Hans': zhHans, 'zh-Hant': zhHant };

// zh-HK / zh-MO / zh-TW / zh-Hant 归繁体，其余 zh 归简体。
export function systemLanguage() {
  for (const lang of navigator.languages ?? [navigator.language]) {
    const l = (lang || '').toLowerCase();
    if (l.startsWith('zh')) {
      if (l.includes('hant') || l.includes('-tw') || l.includes('-hk') || l.includes('-mo')) return 'zh-Hant';
      return 'zh-Hans';
    }
    if (l.startsWith('en')) return 'en';
  }
  return 'en';
}

const table = TABLES[systemLanguage()] ?? TABLES.en;

export function t(key, params) {
  let text = table[key] ?? en[key] ?? key;
  if (params) {
    for (const [name, value] of Object.entries(params)) {
      text = text.replaceAll(`{${name}}`, String(value));
    }
  }
  return text;
}
