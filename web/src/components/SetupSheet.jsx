import { useEffect, useRef, useState } from 'react';
import { IconClose, IconSettings } from './Icons.jsx';
import { t } from '../i18n/index.js';

export default function SetupSheet({ configured, onSave, onClear, onClose }) {
  const [value, setValue] = useState('');
  const [error, setError] = useState('');
  const inputRef = useRef(null);

  useEffect(() => {
    inputRef.current?.focus();
    const onKey = (event) => { if (event.key === 'Escape') onClose(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  function submit(event) {
    event.preventDefault();
    try {
      onSave(value);
      setValue('');
      setError('');
      onClose();
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <>
      <div className="scrim" onClick={onClose} aria-hidden="true" />
      <section className="sheet" role="dialog" aria-modal="true" aria-labelledby="setup-title">
        <div className="sheet__head">
          <h2 className="sheet__title" id="setup-title">Access Key</h2>
          <button className="btn btn--ghost btn--icon" type="button" onClick={onClose} aria-label={t('setup.close')}><IconClose /></button>
        </div>
        <p className="sheet__text">
          {t('setup.body1')}
          <a href="https://unsplash.com/developers" target="_blank" rel="noopener noreferrer">Unsplash Developers</a>
          {t('setup.body2')}
        </p>
        <form className="sheet__row" onSubmit={submit}>
          <input
            ref={inputRef}
            type="password"
            value={value}
            onChange={(event) => setValue(event.target.value)}
            placeholder={configured ? t('setup.configuredPlaceholder') : t('setup.pastePlaceholder')}
            autoComplete="off"
            spellCheck="false"
            aria-label="Unsplash Access Key"
          />
          <button className="btn" type="submit"><IconSettings size={15} /> {t('setup.save')}</button>
          {configured && <button className="btn btn--ghost" type="button" onClick={onClear}>{t('setup.clear')}</button>}
        </form>
        {error && <p className="sheet__note" style={{ color: 'var(--danger)' }}>{error}</p>}
        {!error && <p className="sheet__note">{t('setup.note')}</p>}
      </section>
    </>
  );
}
