import { useEffect, useMemo, useState, type ReactNode } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import { db } from '../db/db'
import { uid } from '../lib/ids'
import { formatDayShort, todayKey } from '../lib/dates'
import { compressImage } from '../lib/image'
import type { ProgressPhoto } from '../db/types'

export function ProgressPage() {
  const settings = useLiveQuery(() => db.settings.get('settings'))
  const measurements = useLiveQuery(() => db.measurements.orderBy('date').toArray()) ?? []
  const photos = useLiveQuery(() => db.photos.orderBy('createdAt').reverse().toArray()) ?? []
  const [weight, setWeight] = useState('')
  const [waist, setWaist] = useState('')
  const [date, setDate] = useState(todayKey())
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [beforeId, setBeforeId] = useState<string>('')
  const [afterId, setAfterId] = useState<string>('')

  const urls = usePhotoUrls(photos)
  const before = photos.find((p) => p.id === beforeId) ?? photos[photos.length - 1]
  const after = photos.find((p) => p.id === afterId) ?? photos[0]

  const weightData = measurements
    .filter((m) => m.weightKg)
    .map((m) => ({ date: formatDayShort(m.date), kg: m.weightKg }))
  const waistData = measurements
    .filter((m) => m.waistCm)
    .map((m) => ({ date: formatDayShort(m.date), cm: m.waistCm }))

  const latestWeight = [...measurements].reverse().find((m) => m.weightKg)?.weightKg
  const latestWaist = [...measurements].reverse().find((m) => m.waistCm)?.waistCm

  async function saveMeasurement() {
    const weightKg = weight === '' ? undefined : Number(weight)
    const waistCm = waist === '' ? undefined : Number(waist)
    if (weightKg === undefined && waistCm === undefined) return
    await db.measurements.add({
      id: uid('m'),
      date,
      weightKg: Number.isFinite(weightKg) ? weightKg : undefined,
      waistCm: Number.isFinite(waistCm) ? waistCm : undefined,
    })
    setWeight('')
    setWaist('')
  }

  async function onPhoto(file: File | undefined) {
    if (!file) return
    setBusy(true)
    setError(null)
    try {
      const blob = await compressImage(file)
      await db.photos.add({
        id: uid('ph'),
        date: todayKey(),
        createdAt: Date.now(),
        blob,
        mimeType: 'image/jpeg',
      })
    } catch {
      setError('Billedet kunne ikke gemmes. Prøv et andet foto.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="space-y-5 pb-2">
      <header className="pt-2">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Krop</p>
        <h1 className="font-display text-4xl font-extrabold leading-none">Fremskridt</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Vægt, talje og fotos bor kun på denne enhed. Tag billedet under samme lys, hvis du kan.
        </p>
      </header>

      <section className="grid grid-cols-2 gap-2">
        <MetricCard
          label="Vægt"
          value={latestWeight ? `${latestWeight} kg` : '—'}
          goal={settings?.weightGoalKg ? `mål ${settings.weightGoalKg} kg` : 'intet mål sat'}
        />
        <MetricCard
          label="Talje"
          value={latestWaist ? `${latestWaist} cm` : '—'}
          goal={settings?.waistGoalCm ? `mål ${settings.waistGoalCm} cm` : 'intet mål sat'}
        />
      </section>

      <section className="space-y-3 rounded-3xl border p-4" style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}>
        <h2 className="font-display text-xl font-bold">Log mål</h2>
        <label className="block text-sm font-semibold text-[var(--muted)]">
          Dato
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="mt-1 h-12 w-full rounded-2xl border px-3"
            style={{ background: 'var(--bg)', borderColor: 'var(--line)', color: 'var(--fg)' }}
          />
        </label>
        <div className="grid grid-cols-2 gap-2">
          <label className="block text-sm font-semibold text-[var(--muted)]">
            Kg
            <input
              type="number"
              inputMode="decimal"
              step="0.1"
              value={weight}
              onChange={(e) => setWeight(e.target.value)}
              className="mt-1 h-12 w-full rounded-2xl border px-3"
              style={{ background: 'var(--bg)', borderColor: 'var(--line)', color: 'var(--fg)' }}
            />
          </label>
          <label className="block text-sm font-semibold text-[var(--muted)]">
            Talje cm
            <input
              type="number"
              inputMode="decimal"
              step="0.5"
              value={waist}
              onChange={(e) => setWaist(e.target.value)}
              className="mt-1 h-12 w-full rounded-2xl border px-3"
              style={{ background: 'var(--bg)', borderColor: 'var(--line)', color: 'var(--fg)' }}
            />
          </label>
        </div>
        <button
          type="button"
          onClick={() => void saveMeasurement()}
          className="h-12 w-full rounded-2xl font-bold"
          style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
        >
          Gem måling
        </button>
      </section>

      <ChartCard title="Vægt" empty={weightData.length === 0} emptyText="Log din første vægt, så kommer kurven.">
        <LinePlot data={weightData} dataKey="kg" />
      </ChartCard>
      <ChartCard title="Talje" empty={waistData.length === 0} emptyText="Taljemål er ofte et ærligere spejl end vægten.">
        <LinePlot data={waistData} dataKey="cm" />
      </ChartCard>

      <section className="space-y-3 rounded-3xl border p-4" style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}>
        <h2 className="font-display text-xl font-bold">Fremskridtsfotos</h2>
        <label
          className="flex h-14 cursor-pointer items-center justify-center rounded-2xl font-bold"
          style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
        >
          {busy ? 'Komprimerer…' : 'Tilføj foto'}
          <input
            type="file"
            accept="image/*"
            capture="environment"
            className="sr-only"
            onChange={(e) => void onPhoto(e.target.files?.[0])}
          />
        </label>
        {error ? <p className="text-sm text-red-600">{error}</p> : null}

        {photos.length >= 2 ? (
          <div>
            <h3 className="mb-2 font-display text-lg font-bold">Før / efter</h3>
            <div className="grid grid-cols-2 gap-2">
              <PhotoPick
                label="Før"
                photos={photos}
                value={before?.id ?? ''}
                onChange={setBeforeId}
                url={before ? urls[before.id] : undefined}
              />
              <PhotoPick
                label="Efter"
                photos={photos}
                value={after?.id ?? ''}
                onChange={setAfterId}
                url={after ? urls[after.id] : undefined}
              />
            </div>
          </div>
        ) : (
          <p className="text-sm text-[var(--muted)]">
            Tilføj mindst to fotos for at sammenligne side om side.
          </p>
        )}

        <div className="grid grid-cols-3 gap-2">
          {photos.map((p) => (
            <figure key={p.id} className="relative">
              <img
                src={urls[p.id]}
                alt={`Fremskridt ${p.date}`}
                className="aspect-[3/4] w-full rounded-2xl object-cover"
              />
              <figcaption className="mt-1 text-center text-[11px] text-[var(--muted)]">
                {formatDayShort(p.date)}
              </figcaption>
              <button
                type="button"
                className="absolute right-1 top-1 grid h-8 w-8 place-items-center rounded-full bg-black/55 text-white"
                onClick={() => void db.photos.delete(p.id)}
                aria-label="Slet foto"
              >
                ×
              </button>
            </figure>
          ))}
        </div>
      </section>
    </div>
  )
}

function MetricCard({ label, value, goal }: { label: string; value: string; goal: string }) {
  return (
    <div className="rounded-3xl border p-4" style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}>
      <div className="text-sm text-[var(--muted)]">{label}</div>
      <div className="font-display text-2xl font-extrabold">{value}</div>
      <div className="text-xs text-[var(--muted)]">{goal}</div>
    </div>
  )
}

function ChartCard({
  title,
  empty,
  emptyText,
  children,
}: {
  title: string
  empty: boolean
  emptyText: string
  children: ReactNode
}) {
  return (
    <section className="rounded-3xl border p-4" style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}>
      <h2 className="font-display text-xl font-bold">{title}</h2>
      {empty ? <p className="mt-2 text-sm text-[var(--muted)]">{emptyText}</p> : <div className="mt-2 h-52">{children}</div>}
    </section>
  )
}

function LinePlot({ data, dataKey }: { data: object[]; dataKey: string }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={data}>
        <CartesianGrid stroke="var(--line)" strokeDasharray="3 3" />
        <XAxis dataKey="date" tick={{ fill: 'var(--muted)', fontSize: 11 }} />
        <YAxis tick={{ fill: 'var(--muted)', fontSize: 11 }} width={36} domain={['auto', 'auto']} />
        <Tooltip
          contentStyle={{ background: 'var(--surface)', border: '1px solid var(--line)', borderRadius: 12 }}
        />
        <Line type="monotone" dataKey={dataKey} stroke="var(--accent)" strokeWidth={3} dot={{ r: 3 }} />
      </LineChart>
    </ResponsiveContainer>
  )
}

function PhotoPick({
  label,
  photos,
  value,
  onChange,
  url,
}: {
  label: string
  photos: ProgressPhoto[]
  value: string
  onChange: (id: string) => void
  url?: string
}) {
  return (
    <div>
      <select
        className="mb-2 h-11 w-full rounded-xl border px-2 text-sm"
        style={{ background: 'var(--bg)', borderColor: 'var(--line)', color: 'var(--fg)' }}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      >
        <option value="">{label}</option>
        {photos.map((p) => (
          <option key={p.id} value={p.id}>
            {p.date}
          </option>
        ))}
      </select>
      {url ? <img src={url} alt={label} className="aspect-[3/4] w-full rounded-2xl object-cover" /> : null}
    </div>
  )
}

function usePhotoUrls(photos: ProgressPhoto[]): Record<string, string> {
  const [urls, setUrls] = useState<Record<string, string>>({})

  const signature = useMemo(() => photos.map((p) => p.id).join('|'), [photos])

  useEffect(() => {
    const next: Record<string, string> = {}
    for (const p of photos) next[p.id] = URL.createObjectURL(p.blob)
    setUrls(next)
    return () => {
      for (const url of Object.values(next)) URL.revokeObjectURL(url)
    }
    // photos identity changes; signature captures membership
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [signature])

  return urls
}
