import { useMemo } from 'react';
import PhotoCard from './PhotoCard.jsx';
import { IconAperture } from './Icons.jsx';
import { useColumns } from '../hooks/useColumns.js';

function Empty({ phase, onSetup }) {
  const isError = phase === 'error';
  return (
    <div className="empty">
      <div className="empty__mark"><IconAperture /></div>
      <h2 className="empty__title">
        {isError ? 'Something went wrong' : phase === 'idle' ? 'The room is dark' : 'No frames found'}
      </h2>
      <p className="empty__text">
        {isError
          ? '先看上方的错误码，检查 Access Key 与配额后再试一次。'
          : phase === 'idle'
            ? '填入 Unsplash Access Key，让光进来。页面不内置任何密钥，也不会回退到默认值。'
            : '换个关键词或方向，再取一次片。'}
      </p>
      {phase === 'idle' && <button className="btn empty__action" type="button" onClick={onSetup}>设置 Access Key</button>}
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
      <div className="grid" style={{ '--cols': columns }} aria-busy="true" aria-label="正在加载">
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
