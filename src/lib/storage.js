// 应用从 darkroom 更名为 duopaper：把旧的 localStorage 键一次性搬到新键，
// 避免用户升级后需要重新填 Access Key、丢失筛选偏好。新键已存在时不覆盖。
export function migrateLegacyKey(legacyKey, nextKey) {
  try {
    const legacy = localStorage.getItem(legacyKey);
    if (legacy === null) return;
    if (localStorage.getItem(nextKey) === null) localStorage.setItem(nextKey, legacy);
    localStorage.removeItem(legacyKey);
  } catch {
    // 隐私模式 / 存储被禁用时忽略，按「无历史数据」处理
  }
}
