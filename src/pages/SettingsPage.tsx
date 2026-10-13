import { useRef, useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/db'
import type { AppSettings, ThemeMode } from '../db/types'
import { applyTheme } from '../lib/theme'
import { downloadText, exportBackup, importBackup } from '../db/backup'
import { ensureNotificationPermission, notificationsSupported } from '../lib/notifications'
import { todayKey } from '../lib/dates'
import { Group, IosToggle, PageHeader, PrimaryButton, Row, SectionLabel, Segmented } from '../components/ui'

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
    <div className="space-y-6 pb-2">
      <PageHeader title="Indstillinger" subtitle="Alt ligger lokalt. Ingen konto, ingen sky." />

      <div>
        <SectionLabel>Profil</SectionLabel>
        <Group>
          <Row>
            <span className="text-[17px]">Navn</span>
            <input
              className="ios-input"
              value={settings.displayName}
              onChange={(e) => void patch({ displayName: e.target.value })}
            />
          </Row>
        </Group>
      </div>

      <div>
        <SectionLabel>Mål</SectionLabel>
        <Group>
          <Row>
            <span className="flex-1 text-[17px]">Glas vand</span>
            <input
              type="number"
              min={1}
              max={20}
              className="ios-input max-w-20"
              value={settings.waterGoal}
              onChange={(e) => void patch({ waterGoal: Math.max(1, Number(e.target.value) || 8) })}
            />
          </Row>
          <Row>
            <span className="flex-1 text-[17px]">Vægtmål</span>
            <input
              type="number"
              step="0.1"
              className="ios-input max-w-24"
              placeholder="kg"
              value={settings.weightGoalKg ?? ''}
              onChange={(e) =>
                void patch({ weightGoalKg: e.target.value === '' ? undefined : Number(e.target.value) })
              }
            />
          </Row>
          <Row>
            <span className="flex-1 text-[17px]">Taljemål</span>
            <input
              type="number"
              step="0.5"
              className="ios-input max-w-24"
              placeholder="cm"
              value={settings.waistGoalCm ?? ''}
              onChange={(e) =>
                void patch({ waistGoalCm: e.target.value === '' ? undefined : Number(e.target.value) })
              }
            />
          </Row>
        </Group>
      </div>

      <div>
        <SectionLabel>Udseende</SectionLabel>
        <Group className="p-3">
          <Segmented<ThemeMode>
            value={settings.theme}
            onChange={(theme) => void patch({ theme })}
            options={[
              { value: 'light', label: 'Lys' },
              { value: 'dark', label: 'Mørk' },
              { value: 'system', label: 'System' },
            ]}
          />
        </Group>
      </div>

      <div>
        <SectionLabel>Påmindelser</SectionLabel>
        <Group>
          <Row>
            <span className="flex-1 text-[17px]">Tidspunkt</span>
            <input
              type="time"
              className="ios-input max-w-28"
              value={settings.reminderTime}
              onChange={(e) => void patch({ reminderTime: e.target.value })}
            />
          </Row>
          <Row>
            <span className="flex-1 text-[17px]">Kreatin</span>
            <IosToggle
              checked={settings.creatineReminder}
              onChange={(creatineReminder) => void patch({ creatineReminder })}
              label="Kreatin-påmindelse"
            />
          </Row>
          <Row>
            <span className="min-w-0 flex-1 text-[17px]">Træning man/ons/fre</span>
            <IosToggle
              checked={settings.workoutReminder}
              onChange={(workoutReminder) => void patch({ workoutReminder })}
              label="Træningspåmindelse"
            />
          </Row>
        </Group>
        <p className="mt-2 px-4 text-[13px] text-[var(--muted)]">
          Browser-notifikationer virker bedst, når appen er åben eller på hjemmeskærmen. iPhone: iOS 16.4+.
          Status: {perm}.
        </p>
        <div className="mt-3">
          <PrimaryButton onClick={() => void enableReminders()}>Tillad notifikationer</PrimaryButton>
        </div>
      </div>

      <div>
        <SectionLabel>Backup</SectionLabel>
        <Group>
          <Row onClick={() => void onExport()}>
            <span className="flex-1 text-[17px]" style={{ color: 'var(--blue)' }}>
              Eksporter data
            </span>
          </Row>
          <Row onClick={() => fileRef.current?.click()}>
            <span className="flex-1 text-[17px]" style={{ color: 'var(--blue)' }}>
              Importer data
            </span>
          </Row>
        </Group>
        <input
          ref={fileRef}
          type="file"
          accept="application/json"
          className="sr-only"
          onChange={(e) => void onImport(e.target.files?.[0])}
        />
        <p className="mt-2 px-4 text-[13px] text-[var(--muted)]">
          JSON med vaner, træning, mål og fotos. Import overskriver alt på enheden.
        </p>
      </div>

      <div>
        <SectionLabel>Installér på iPhone</SectionLabel>
        <Group className="px-4 py-3 text-[15px] text-[var(--muted)]">
          <ol className="list-decimal space-y-1 pl-5">
            <li>Åbn siden i Safari.</li>
            <li>Tryk på del-ikonet.</li>
            <li>Vælg «Føj til hjemmeskærm».</li>
          </ol>
        </Group>
      </div>

      {status ? <p className="px-4 text-center text-[13px] text-[var(--muted)]">{status}</p> : null}
      <p className="pb-2 text-center text-[12px] text-[var(--muted)]">STÆRK · data forlader aldrig din browser</p>
    </div>
  )
}
