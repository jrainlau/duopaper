import { useEffect, useRef, useState } from 'react';
import { IconClose, IconSettings } from './Icons.jsx';

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
          <button className="btn btn--ghost btn--icon" type="button" onClick={onClose} aria-label="关闭"><IconClose /></button>
        </div>
        <p className="sheet__text">
          到 <a href="https://unsplash.com/developers" target="_blank" rel="noopener noreferrer">Unsplash Developers</a> 免费创建应用，复制 <strong>Access Key</strong>（不是 Secret Key）。Demo 应用限额 <strong>50 次 / 小时</strong>。
          Unsplash 要求两个密钥都保密，公开部署请改用服务端代理保存密钥；本机自用可直接填在这里。
        </p>
        <form className="sheet__row" onSubmit={submit}>
          <input
            ref={inputRef}
            type="password"
            value={value}
            onChange={(event) => setValue(event.target.value)}
            placeholder={configured ? '已配置 · 输入新 key 可替换' : '粘贴 Access Key'}
            autoComplete="off"
            spellCheck="false"
            aria-label="Unsplash Access Key"
          />
          <button className="btn" type="submit"><IconSettings size={15} /> 保存</button>
          {configured && <button className="btn btn--ghost" type="button" onClick={onClear}>清除</button>}
        </form>
        {error && <p className="sheet__note" style={{ color: 'var(--danger)' }}>{error}</p>}
        {!error && <p className="sheet__note">密钥只存在本机 localStorage，只发送给 api.unsplash.com；页面不内置也不回退到任何默认密钥。</p>}
      </section>
    </>
  );
}
