import { db } from './db'
import { blobToDataUrl, dataUrlToBlob } from '../lib/image'
import type { AppSettings, DayLog, Exercise, Measurement, WorkoutSession } from './types'

interface PhotoExport {
  id: string
  date: string
  createdAt: number
  mimeType: string
  dataUrl: string
}

export interface BackupPayload {
  version: 1
  exportedAt: string
  exercises: Exercise[]
  sessions: WorkoutSession[]
  days: DayLog[]
  measurements: Measurement[]
  settings: AppSettings | undefined
  photos: PhotoExport[]
}

export async function exportBackup(): Promise<string> {
  const [exercises, sessions, days, measurements, settings, photos] = await Promise.all([
    db.exercises.toArray(),
    db.sessions.toArray(),
    db.days.toArray(),
    db.measurements.toArray(),
    db.settings.get('settings'),
    db.photos.toArray(),
  ])

  const photoExports: PhotoExport[] = []
  for (const photo of photos) {
    photoExports.push({
      id: photo.id,
      date: photo.date,
      createdAt: photo.createdAt,
      mimeType: photo.mimeType,
      dataUrl: await blobToDataUrl(photo.blob),
    })
  }

  const payload: BackupPayload = {
    version: 1,
    exportedAt: new Date().toISOString(),
    exercises,
    sessions,
    days,
    measurements,
    settings,
    photos: photoExports,
  }

  return JSON.stringify(payload)
}

export async function importBackup(json: string): Promise<void> {
  const parsed = JSON.parse(json) as BackupPayload
  if (!parsed || parsed.version !== 1) {
    throw new Error('Ukendt backup-format')
  }

  await db.transaction(
    'rw',
    [db.exercises, db.sessions, db.days, db.measurements, db.photos, db.settings],
    async () => {
      await Promise.all([
        db.exercises.clear(),
        db.sessions.clear(),
        db.days.clear(),
        db.measurements.clear(),
        db.photos.clear(),
        db.settings.clear(),
      ])

      if (parsed.exercises?.length) await db.exercises.bulkAdd(parsed.exercises)
      if (parsed.sessions?.length) await db.sessions.bulkAdd(parsed.sessions)
      if (parsed.days?.length) await db.days.bulkAdd(parsed.days)
      if (parsed.measurements?.length) await db.measurements.bulkAdd(parsed.measurements)
      if (parsed.settings) await db.settings.put(parsed.settings)

      for (const photo of parsed.photos ?? []) {
        const blob = await dataUrlToBlob(photo.dataUrl)
        await db.photos.put({
          id: photo.id,
          date: photo.date,
          createdAt: photo.createdAt,
          mimeType: photo.mimeType || blob.type || 'image/jpeg',
          blob,
        })
      }
    },
  )
}

export function downloadText(filename: string, text: string, mime = 'application/json'): void {
  const blob = new Blob([text], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)
}
