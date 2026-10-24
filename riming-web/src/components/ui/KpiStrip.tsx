type KpiItem = {
  label: string;
  value: string;
  hint?: string;
};

type KpiStripProps = {
  items: KpiItem[];
};

/**
 * Dense ledger-style metrics row — not a grid of identical SaaS cards.
 * One panel, hairline dividers, tabular values.
 */
export function KpiStrip({ items }: KpiStripProps) {
  if (items.length === 0) return null;

  return (
    <div className="kpi-strip">
      {items.map((item) => (
        <div key={item.label} className="kpi-cell">
          <p className="kpi-label">{item.label}</p>
          <p className="kpi-value">{item.value}</p>
          {item.hint ? <p className="kpi-hint">{item.hint}</p> : null}
        </div>
      ))}
    </div>
  );
}
