export const MUSCLE_GROUPS = ['legs', 'chest', 'back', 'shoulders', 'arms', 'core'] as const
export type MuscleGroup = (typeof MUSCLE_GROUPS)[number]

export const WORKOUT_LETTERS = ['A', 'B'] as const
export type WorkoutLetter = (typeof WORKOUT_LETTERS)[number]

export const THEMES = ['light', 'dark', 'system'] as const
export type ThemeMode = (typeof THEMES)[number]

export const LOG_TYPES = ['reps', 'seconds'] as const
export type LogType = (typeof LOG_TYPES)[number]

export interface Exercise {
  id: string
  name: string
  muscleGroup: MuscleGroup
  workout: WorkoutLetter
  defaultSets: number
  defaultRepsMin: number
  defaultRepsMax: number
  logType: LogType
  notes: string
  order: number
  archived: boolean
}

export interface SetLog {
  weight: number
  reps: number
  done: boolean
}

export interface SessionExercise {
  exerciseId: string
  sets: SetLog[]
}

export interface WorkoutSession {
  id: string
  date: string
  workout: WorkoutLetter
  completed: boolean
  exercises: SessionExercise[]
  startedAt: number
  finishedAt?: number
  note?: string
}

export interface DayLog {
  date: string
  creatine: boolean
  waterGlasses: number
  alcoholFree: boolean
  steps?: number
  walkMinutes?: number
  golf: boolean
}

export interface Measurement {
  id: string
  date: string
  weightKg?: number
  waistCm?: number
}

export interface ProgressPhoto {
  id: string
  date: string
  createdAt: number
  blob: Blob
  mimeType: string
}

export interface AppSettings {
  id: 'settings'
  displayName: string
  waterGoal: number
  creatineReminder: boolean
  reminderTime: string
  workoutReminder: boolean
  theme: ThemeMode
  weightGoalKg?: number
  waistGoalCm?: number
}

export const MUSCLE_LABELS: Record<MuscleGroup, string> = {
  legs: 'Ben',
  chest: 'Bryst',
  back: 'Ryg',
  shoulders: 'Skuldre',
  arms: 'Arme',
  core: 'Core',
}

export const WEEKDAY_SHORT = ['man', 'tir', 'ons', 'tor', 'fre', 'lør', 'søn'] as const
export const WEEKDAY_LONG = [
  'mandag',
  'tirsdag',
  'onsdag',
  'torsdag',
  'fredag',
  'lørdag',
  'søndag',
] as const
