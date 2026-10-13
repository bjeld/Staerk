import Dexie, { type EntityTable } from 'dexie'
import type {
  AppSettings,
  DayLog,
  Exercise,
  Measurement,
  ProgressPhoto,
  WorkoutSession,
} from './types'
import { defaultExercises, defaultSettings } from './seed'

export class StaerkDB extends Dexie {
  exercises!: EntityTable<Exercise, 'id'>
  sessions!: EntityTable<WorkoutSession, 'id'>
  days!: EntityTable<DayLog, 'date'>
  measurements!: EntityTable<Measurement, 'id'>
  photos!: EntityTable<ProgressPhoto, 'id'>
  settings!: EntityTable<AppSettings, 'id'>

  constructor() {
    super('staerk-martin')
    this.version(1).stores({
      exercises: 'id, workout, muscleGroup, order, archived',
      sessions: 'id, date, workout, completed',
      days: 'date',
      measurements: 'id, date',
      photos: 'id, date, createdAt',
      settings: 'id',
    })
  }
}

export const db = new StaerkDB()

export async function ensureSeed(): Promise<void> {
  await db.transaction('rw', db.exercises, db.settings, async () => {
    const exerciseCount = await db.exercises.count()
    if (exerciseCount === 0) {
      await db.exercises.bulkAdd(defaultExercises)
    }
    const settings = await db.settings.get('settings')
    if (!settings) {
      await db.settings.put(defaultSettings)
    }
  })
}

export async function getOrCreateDay(date: string): Promise<DayLog> {
  const existing = await db.days.get(date)
  if (existing) return existing
  const fresh: DayLog = {
    date,
    creatine: false,
    waterGlasses: 0,
    alcoholFree: true,
    golf: false,
  }
  await db.days.put(fresh)
  return fresh
}

export async function patchDay(date: string, patch: Partial<DayLog>): Promise<void> {
  const current = await getOrCreateDay(date)
  await db.days.put({ ...current, ...patch, date })
}
