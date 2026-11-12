export function isStandalone() {
  if (typeof window === 'undefined') return false;
  return window.matchMedia('(display-mode: standalone)').matches || window.navigator.standalone === true;
}

export function isIOS() {
  if (typeof navigator === 'undefined') return false;
  return /iP(hone|ad|od)/.test(navigator.userAgent) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
}

export function canShareFiles(file) {
  return typeof navigator !== 'undefined' &&
    typeof navigator.share === 'function' &&
    typeof navigator.canShare === 'function' &&
    navigator.canShare({ files: [file] });
}

export function isTouchDevice() {
  if (typeof navigator === 'undefined') return false;
  return navigator.maxTouchPoints > 0 ||
    isIOS() ||
    (typeof window !== 'undefined' && window.matchMedia?.('(pointer: coarse)').matches) ||
    false;
}

export function isDualScreen() {
  if (typeof window === 'undefined' || !window.matchMedia) return false;
  return window.matchMedia('(horizontal-viewport-segments: 2)').matches ||
    window.matchMedia('(screen-spanning: single-fold-horizontal)').matches;
}

export function prefersReducedMotion() {
  return typeof window !== 'undefined' &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}
