import type { WorkoutLetter, WorkoutSession } from '../db/types'

export type DayKind = 'gym' | 'home' | 'weekend'

export function weekdayIndex(date = new Date()): number {
  return (date.getDay() + 6) % 7
}

export function dayKind(date = new Date()): DayKind {
  const i = weekdayIndex(date)
  if (i === 0 || i === 2 || i === 4) return 'gym'
  if (i === 1 || i === 3) return 'home'
  return 'weekend'
}

export function isTrainingWeekday(date = new Date()): boolean {
  return dayKind(date) === 'gym'
}

export function pickWorkoutLetter(sessions: WorkoutSession[], date = new Date()): WorkoutLetter {
  const completed = sessions
    .filter((s) => s.completed)
    .sort((a, b) => b.date.localeCompare(a.date) || (b.finishedAt ?? 0) - (a.finishedAt ?? 0))

  if (completed.length > 0) {
    return completed[0].workout === 'A' ? 'B' : 'A'
  }

  const i = weekdayIndex(date)
  return i === 2 ? 'B' : 'A'
}

export function dayKindLabel(kind: DayKind): string {
  if (kind === 'gym') return 'Styrketræning på jobbet · før kl. 7'
  if (kind === 'home') return 'Hjemmearbejdsdag · gåtur, golf eller hvile'
  return 'Weekend · golf, gåtur eller restitution'
}
