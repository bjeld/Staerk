import { useRef, useState, type ReactNode } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/db'
import type { AppSettings, ThemeMode } from '../db/types'
import { THEMES } from '../db/types'
import { applyTheme } from '../lib/theme'
import { downloadText, exportBackup, importBackup } from '../db/backup'
import { ensureNotificationPermission, notificationsSupported } from '../lib/notifications'
import { todayKey } from '../lib/dates'

const themeLabels: Record<ThemeMode, string> = {
  light: 'Lys',
  dark: 'Mørk',
  system: 'System',
}

export function SettingsPage() {
  const settings = useLiveQuery(() => db.settings.get('settings'))
  const fileRef = useRef<HTMLInputElement>(null)
  const [status, setStatus] = useState<string | null>(null)
  const [perm, setPerm] = useState(() =>
    notificationsSupported() ? Notification.permission : 'unsupported',
  )

  if (!settings) return <p className="pt-8 text-[var(--muted)]">Indlæser…</p>

  async function patch(partial: Partial<AppSettings>) {
    await db.settings.update('settings', partial)
    if (partial.theme) applyTheme(partial.theme)
  }

  async function enableReminders() {
    const ok = await ensureNotificationPermission()
    setPerm(notificationsSupported() ? Notification.permission : 'unsupported')
    if (ok) {
      await db.settings.update('settings', { creatineReminder: true })
      setStatus('Påmindelser er slået til. Hold appen åben, eller åbn den om morgenen.')
    } else {
      setStatus('Notifikationer blev ikke tilladt. Du kan stadig bruge vanerne uden dem.')
    }
  }

  async function onExport() {
    setStatus('Bygger backup…')
    const json = await exportBackup()
    downloadText(`staerk-backup-${todayKey()}.json`, json)
    setStatus('Backup hentet. Gem filen et sted, du kan finde igen.')
  }

  async function onImport(file: File | undefined) {
    if (!file) return
    if (!confirm('Import overskriver al data på denne enhed. Fortsæt?')) return
    try {
      const text = await file.text()
      await importBackup(text)
      const imported = await db.settings.get('settings')
      if (imported) applyTheme(imported.theme)
      setStatus('Backup er indlæst.')
    } catch {
      setStatus('Filen kunne ikke læses. Tjek at det er en STÆRK-backup.')
    }
  }

  return (
    <div className="space-y-5 pb-2">
      <header className="pt-2">
        <p className="text-sm font-semibold uppercase tracking-[0.18em] text-[var(--muted)]">Konto</p>
        <h1 className="font-display text-4xl font-extrabold leading-none">Indstillinger</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Alt ligger lokalt i browseren. Ingen konto, ingen sky — kun din backup-fil.
        </p>
      </header>

      <Card title="Profil">
        <Field label="Navn">
          <input
            className="field"
            value={settings.displayName}
            onChange={(e) => void patch({ displayName: e.target.value })}
          />
        </Field>
      </Card>

      <Card title="Mål">
        <Field label="Glas vand om dagen">
          <input
            type="number"
            min={1}
            max={20}
            className="field"
            value={settings.waterGoal}
            onChange={(e) => void patch({ waterGoal: Math.max(1, Number(e.target.value) || 8) })}
          />
        </Field>
        <Field label="Vægtmål (kg)">
          <input
            type="number"
            step="0.1"
            className="field"
            value={settings.weightGoalKg ?? ''}
            placeholder="valgfrit"
            onChange={(e) =>
              void patch({
                weightGoalKg: e.target.value === '' ? undefined : Number(e.target.value),
              })
            }
          />
        </Field>
        <Field label="Taljemål (cm)">
          <input
            type="number"
            step="0.5"
            className="field"
            value={settings.waistGoalCm ?? ''}
            placeholder="valgfrit"
            onChange={(e) =>
              void patch({
                waistGoalCm: e.target.value === '' ? undefined : Number(e.target.value),
              })
            }
          />
        </Field>
      </Card>

      <Card title="Tema">
        <div className="grid grid-cols-3 gap-2">
          {THEMES.map((mode) => (
            <button
              key={mode}
              type="button"
              onClick={() => void patch({ theme: mode })}
              className="h-12 rounded-2xl border font-bold"
              style={{
                background: settings.theme === mode ? 'var(--accent)' : 'var(--bg)',
                color: settings.theme === mode ? 'var(--accent-fg)' : 'var(--fg)',
                borderColor: settings.theme === mode ? 'var(--accent)' : 'var(--line)',
              }}
            >
              {themeLabels[mode]}
            </button>
          ))}
        </div>
      </Card>

      <Card title="Påmindelser">
        <p className="text-sm text-[var(--muted)]">
          Browser-notifikationer virker bedst, når appen er åben eller installeret på hjemmeskærmen.
          iPhone kræver iOS 16.4+ og «Føj til hjemmeskærm». Status: {perm}.
        </p>
        <Field label="Tidspunkt">
          <input
            type="time"
            className="field"
            value={settings.reminderTime}
            onChange={(e) => void patch({ reminderTime: e.target.value })}
          />
        </Field>
        <Toggle
          label="Kreatin-påmindelse"
          checked={settings.creatineReminder}
          onChange={(creatineReminder) => void patch({ creatineReminder })}
        />
        <Toggle
          label="Træningspåmindelse (man/ons/fre)"
          checked={settings.workoutReminder}
          onChange={(workoutReminder) => void patch({ workoutReminder })}
        />
        <button
          type="button"
          onClick={() => void enableReminders()}
          className="mt-2 h-12 w-full rounded-2xl font-bold"
          style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
        >
          Tillad notifikationer
        </button>
      </Card>

      <Card title="Backup">
        <p className="text-sm text-[var(--muted)]">
          Eksporter JSON med vaner, træning, mål og fotos (komprimeret). Import erstatter alt på enheden.
        </p>
        <div className="mt-3 grid gap-2">
          <button
            type="button"
            onClick={() => void onExport()}
            className="h-12 rounded-2xl font-bold"
            style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
          >
            Eksporter data
          </button>
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="h-12 rounded-2xl border font-bold"
            style={{ borderColor: 'var(--line)' }}
          >
            Importer data
          </button>
          <input
            ref={fileRef}
            type="file"
            accept="application/json"
            className="sr-only"
            onChange={(e) => void onImport(e.target.files?.[0])}
          />
        </div>
      </Card>

      <Card title="Installér på iPhone">
        <ol className="list-decimal space-y-1 pl-5 text-sm text-[var(--muted)]">
          <li>Åbn siden i Safari.</li>
          <li>Tryk på del-ikonet.</li>
          <li>Vælg «Føj til hjemmeskærm».</li>
        </ol>
        <p className="mt-2 text-sm text-[var(--muted)]">
          På Android: menuen i Chrome → «Tilføj til startskærm». Virker offline, når den er installeret.
        </p>
      </Card>

      {status ? (
        <p className="rounded-2xl px-4 py-3 text-sm" style={{ background: 'var(--bg-2)' }}>
          {status}
        </p>
      ) : null}

      <p className="pb-2 text-center text-xs text-[var(--muted)]">
        STÆRK · bygget til Martin · data forlader aldrig din browser
      </p>

      <style>{`
        .field {
          width: 100%;
          height: 3rem;
          border-radius: 1rem;
          border: 1px solid var(--line);
          background: var(--bg);
          color: var(--fg);
          padding: 0 0.9rem;
          outline: none;
          margin-top: 0.25rem;
        }
      `}</style>
    </div>
  )
}

function Card({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="space-y-3 rounded-3xl border p-4" style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}>
      <h2 className="font-display text-xl font-bold">{title}</h2>
      {children}
    </section>
  )
}

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="block text-sm font-semibold">
      {label}
      {children}
    </label>
  )
}

function Toggle({
  label,
  checked,
  onChange,
}: {
  label: string
  checked: boolean
  onChange: (v: boolean) => void
}) {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className="flex h-14 w-full items-center justify-between rounded-2xl px-3 text-left"
      style={{ background: 'var(--bg)' }}
    >
      <span className="font-semibold">{label}</span>
      <span
        className="relative h-7 w-12 rounded-full"
        style={{ background: checked ? 'var(--accent)' : 'var(--line)' }}
      >
        <span
          className="absolute top-0.5 h-6 w-6 rounded-full bg-white transition-[left]"
          style={{ left: checked ? '1.4rem' : '0.15rem' }}
        />
      </span>
    </button>
  )
}
