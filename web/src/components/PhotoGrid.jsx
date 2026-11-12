import { useMemo } from 'react';
import PhotoCard from './PhotoCard.jsx';
import { IconAperture } from './Icons.jsx';
import { useColumns } from '../hooks/useColumns.js';
import { t } from '../i18n/index.js';

function Empty({ phase, onSetup }) {
  const isError = phase === 'error';
  return (
    <div className="empty">
      <div className="empty__mark"><IconAperture /></div>
      <h2 className="empty__title">
        {isError ? t('empty.error.title') : phase === 'idle' ? t('empty.idle.title') : t('empty.none.title')}
      </h2>
      <p className="empty__text">
        {isError
          ? t('empty.error.text')
          : phase === 'idle'
            ? t('empty.idle.text')
            : t('empty.none.text')}
      </p>
      {phase === 'idle' && <button className="btn empty__action" type="button" onClick={onSetup}>{t('empty.setupKey')}</button>}
    </div>
  );
}

// round-robin 分桶：01/02/03… 依次落在第 1/2/3 列，保证视觉上从左往右读。
function distribute(items, columns) {
  const buckets = Array.from({ length: columns }, () => []);
  items.forEach((photo, index) => {
    buckets[index % columns].push({ photo, index });
  });
  return buckets;
}

export default function PhotoGrid({ items, phase, size, onSave, savingId, savingLabel, onSetup }) {
  const columns = useColumns();
  const buckets = useMemo(() => distribute(items, columns), [items, columns]);

  if (phase === 'loading') {
    return (
      <div className="grid" style={{ '--cols': columns }} aria-busy="true" aria-label={t('grid.loadingAria')}>
        {Array.from({ length: columns }, (_, column) => (
          <div className="grid__col" key={column}>
            {Array.from({ length: 4 }, (_, row) => (
              <div key={row} className={`card card--skeleton card--skeleton--${(row + column) % 3}`} />
            ))}
          </div>
        ))}
      </div>
    );
  }

  if (!items.length) return <Empty phase={phase} onSetup={onSetup} />;

  return (
    <div className="grid" style={{ '--cols': columns }}>
      {buckets.map((bucket, column) => (
        <div className="grid__col" key={column}>
          {bucket.map(({ photo, index }) => (
            <PhotoCard
              key={photo.id}
              photo={photo}
              index={index}
              size={size}
              onSave={onSave}
              saving={savingId === photo.id ? savingLabel : ''}
            />
          ))}
        </div>
      ))}
    </div>
  );
}
