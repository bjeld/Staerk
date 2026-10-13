import type { Exercise, SessionExercise, WorkoutSession } from '../db/types'

export interface LastPerformance {
  date: string
  sets: { weight: number; reps: number }[]
  topWeight: number
  topReps: number
}

export function lastForExercise(
  sessions: WorkoutSession[],
  exerciseId: string,
): LastPerformance | null {
  const hits = sessions
    .filter((s) => s.completed)
    .sort((a, b) => b.date.localeCompare(a.date) || (b.finishedAt ?? 0) - (a.finishedAt ?? 0))

  for (const session of hits) {
    const block = session.exercises.find((e) => e.exerciseId === exerciseId)
    const done = block?.sets.filter((s) => s.done && s.reps > 0)
    if (done && done.length > 0) {
      const top = done.reduce((best, set) => (set.weight > best.weight ? set : best), done[0])
      return {
        date: session.date,
        sets: done.map((s) => ({ weight: s.weight, reps: s.reps })),
        topWeight: top.weight,
        topReps: top.reps,
      }
    }
  }
  return null
}

export function suggestNext(exercise: Exercise, last: LastPerformance | null): string {
  if (!last) {
    return exercise.logType === 'seconds'
      ? `Start roligt: ${exercise.defaultRepsMin}–${exercise.defaultRepsMax} sek. Hold teknikken ren.`
      : `Find en vægt du kan løfte ${exercise.defaultRepsMin}–${exercise.defaultRepsMax} gange med 2 reps i reserve.`
  }

  const allTopRange = last.sets.every((s) => s.reps >= exercise.defaultRepsMax)
  const allInRange = last.sets.every((s) => s.reps >= exercise.defaultRepsMin)
  const sameWeight = last.sets.every((s) => s.weight === last.sets[0].weight)

  if (exercise.logType === 'seconds') {
    if (allTopRange) return `Sidste gang ${last.sets.map((s) => `${s.reps}s`).join(', ')}. Prøv +5–10 sek.`
    return `Sigte efter ${exercise.defaultRepsMin}–${exercise.defaultRepsMax} sek. med rolig vejrtrækning.`
  }

  if (allTopRange && sameWeight) {
    const next = Number((last.topWeight + 2.5).toFixed(1))
    return `Sidste gang ${last.topWeight} kg × ${exercise.defaultRepsMax}. Prøv ${next} kg × ${exercise.defaultRepsMin}–${exercise.defaultRepsMax}.`
  }

  if (allInRange) {
    return `Hold ${last.topWeight} kg og jag ${exercise.defaultRepsMax} reps i alle sæt, før du går op.`
  }

  return `Bliv på ${last.topWeight} kg. Få mindst ${exercise.defaultRepsMin} rene reps før du øger.`
}

export function defaultSetsFromLast(
  exercise: Exercise,
  last: LastPerformance | null,
): SessionExercise {
  const count = exercise.defaultSets
  const weight = last?.topWeight ?? 0
  const reps =
    last && last.sets[0]
      ? last.sets[0].reps
      : Math.round((exercise.defaultRepsMin + exercise.defaultRepsMax) / 2)

  return {
    exerciseId: exercise.id,
    sets: Array.from({ length: count }, () => ({
      weight,
      reps,
      done: false,
    })),
  }
}

export function weeklySetVolume(
  sessions: WorkoutSession[],
  weekStart: string,
  weekEnd: string,
  muscleOf: (exerciseId: string) => string | undefined,
): Record<string, number> {
  const volume: Record<string, number> = {}
  for (const session of sessions) {
    if (!session.completed) continue
    if (session.date < weekStart || session.date > weekEnd) continue
    for (const block of session.exercises) {
      const muscle = muscleOf(block.exerciseId)
      if (!muscle) continue
      const sets = block.sets.filter((s) => s.done).length
      volume[muscle] = (volume[muscle] ?? 0) + sets
    }
  }
  return volume
}
