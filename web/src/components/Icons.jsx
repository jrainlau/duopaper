const base = {
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.7,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
};

export function IconSearch({ size = 16 }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" {...base} aria-hidden="true"><circle cx="11" cy="11" r="7" /><path d="M20 20l-4-4" /></svg>;
}

export function IconDownload({ size = 16 }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" {...base} aria-hidden="true"><path d="M12 3v12" /><path d="M7 11l5 5 5-5" /><path d="M4 20h16" /></svg>;
}

export function IconSettings({ size = 16 }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" {...base} aria-hidden="true"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.88l.06.06-2.83 2.83-.06-.06a1.7 1.7 0 0 0-2.9 1.2V21H10v-.09a1.7 1.7 0 0 0-2.9-1.2l-.06.06-2.83-2.83.06-.06A1.7 1.7 0 0 0 4.6 15H4.5V11h.09a1.7 1.7 0 0 0 1.2-2.9l-.06-.06 2.83-2.83.06.06A1.7 1.7 0 0 0 11 4.6V4.5h4v.09a1.7 1.7 0 0 0 2.9 1.2l.06-.06 2.83 2.83-.06.06A1.7 1.7 0 0 0 19.4 11h.09v4z" /></svg>;
}

export function IconChevron({ dir = 'right', size = 16 }) {
  const d = dir === 'left' ? 'M15 5l-7 7 7 7' : 'M9 5l7 7-7 7';
  return <svg width={size} height={size} viewBox="0 0 24 24" {...base} aria-hidden="true"><path d={d} /></svg>;
}

export function IconClose({ size = 16 }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" {...base} aria-hidden="true"><path d="M6 6l12 12M18 6L6 18" /></svg>;
}

export function IconShare({ size = 18 }) {
  return <svg width={size} height={size} viewBox="0 0 24 24" {...base} aria-hidden="true"><path d="M12 16V3" /><path d="M7 8l5-5 5 5" /><path d="M5 14v5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-5" /></svg>;
}

export function IconAperture({ size = 56 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
      <circle cx="32" cy="32" r="23" />
      <circle cx="32" cy="32" r="9" fill="currentColor" stroke="none" />
      <path d="M32 2v9M32 53v9M2 32h9M53 32h9" strokeLinecap="round" />
    </svg>
  );
}
