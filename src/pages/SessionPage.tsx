import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/db'
import type { Exercise, SessionExercise, WorkoutLetter, WorkoutSession } from '../db/types'
import { MUSCLE_LABELS } from '../db/types'
import { uid } from '../lib/ids'
import { todayKey } from '../lib/dates'
import { pickWorkoutLetter } from '../lib/schedule'
import { defaultSetsFromLast, lastForExercise, suggestNext } from '../lib/progression'
import { NumberStepper } from '../components/NumberStepper'
import { Group, PageHeader, PlainButton, PrimaryButton, Segmented } from '../components/ui'

export function SessionPage() {
  const navigate = useNavigate()
  const exercises = useLiveQuery(() => db.exercises.filter((e) => !e.archived).toArray()) ?? []
  const sessions = useLiveQuery(() => db.sessions.toArray()) ?? []
  const [letter, setLetter] = useState<WorkoutLetter | null>(null)
  const [blocks, setBlocks] = useState<SessionExercise[] | null>(null)
  const [saving, setSaving] = useState(false)

  const resolvedLetter = letter ?? pickWorkoutLetter(sessions)
  const plan = useMemo(
    () => exercises.filter((e) => e.workout === resolvedLetter).sort((a, b) => a.order - b.order),
    [exercises, resolvedLetter],
  )

  useEffect(() => {
    if (!exercises.length || blocks) return
    const pick = pickWorkoutLetter(sessions)
    setLetter(pick)
    const chosen = exercises.filter((e) => e.workout === pick).sort((a, b) => a.order - b.order)
    setBlocks(chosen.map((e) => defaultSetsFromLast(e, lastForExercise(sessions, e.id))))
  }, [exercises, sessions, blocks])

  function switchLetter(next: WorkoutLetter) {
    setLetter(next)
    const chosen = exercises.filter((e) => e.workout === next).sort((a, b) => a.order - b.order)
    setBlocks(chosen.map((e) => defaultSetsFromLast(e, lastForExercise(sessions, e.id))))
  }

  function updateSet(exerciseId: string, index: number, patch: Partial<SessionExercise['sets'][number]>) {
    setBlocks((prev) =>
      (prev ?? []).map((block) =>
        block.exerciseId === exerciseId
          ? {
              ...block,
              sets: block.sets.map((s, i) => (i === index ? { ...s, ...patch } : s)),
            }
          : block,
      ),
    )
  }

  async function complete(done: boolean) {
    if (!blocks) return
    setSaving(true)
    const session: WorkoutSession = {
      id: uid('ses'),
      date: todayKey(),
      workout: resolvedLetter,
      completed: done,
      exercises: blocks,
      startedAt: Date.now(),
      finishedAt: Date.now(),
    }
    await db.sessions.add(session)
    setSaving(false)
    navigate(done ? `/traening/${session.id}` : '/traening')
  }

  if (!blocks) {
    return <p className="pt-8 text-[var(--muted)]">Indlæser program…</p>
  }

  const doneSets = blocks.reduce((n, b) => n + b.sets.filter((s) => s.done).length, 0)
  const totalSets = blocks.reduce((n, b) => n + b.sets.length, 0)

  return (
    <div className="space-y-5 pb-4">
      <PageHeader
        title={`Program ${resolvedLetter}`}
        subtitle={`Opvarm 5 min + ét let sæt. 1–2 reps i reserve. ${doneSets}/${totalSets} sæt.`}
        backTo="/traening"
        backLabel="Træning"
      />
      <Segmented
        value={resolvedLetter}
        onChange={switchLetter}
        options={[
          { value: 'A', label: 'Program A' },
          { value: 'B', label: 'Program B' },
        ]}
      />

      {plan.map((exercise) => {
        const block = blocks.find((b) => b.exerciseId === exercise.id)
        if (!block) return null
        return (
          <ExerciseCard
            key={exercise.id}
            exercise={exercise}
            block={block}
            last={lastForExercise(sessions, exercise.id)}
            onChange={updateSet}
          />
        )
      })}

      <div className="grid gap-1">
        <PrimaryButton disabled={saving} onClick={() => void complete(true)}>
          Gem og afslut pas
        </PrimaryButton>
        <PlainButton onClick={() => void complete(false)}>Gem som kladde</PlainButton>
      </div>
    </div>
  )
}

function ExerciseCard({
  exercise,
  block,
  last,
  onChange,
}: {
  exercise: Exercise
  block: SessionExercise
  last: ReturnType<typeof lastForExercise>
  onChange: (exerciseId: string, index: number, patch: Partial<SessionExercise['sets'][number]>) => void
}) {
  return (
    <Group className="p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <h2 className="text-[20px] font-semibold leading-tight">{exercise.name}</h2>
          <p className="text-[13px] text-[var(--muted)]">
            {MUSCLE_LABELS[exercise.muscleGroup]} · {exercise.defaultSets} sæt
          </p>
        </div>
        <Link to={`/traening/ovelse/${exercise.id}`} className="text-[15px]" style={{ color: 'var(--blue)' }}>
          Historik
        </Link>
      </div>
      {last ? (
        <p className="mt-2 text-sm">
          Sidste gang ({last.date}): {last.sets.map((s) => formatSet(exercise, s)).join(' · ')}
        </p>
      ) : (
        <p className="mt-2 text-sm text-[var(--muted)]">Ingen tidligere tal — start konservativt.</p>
      )}
      <p className="mt-1 text-[13px] font-medium" style={{ color: 'var(--accent)' }}>
        {suggestNext(exercise, last)}
      </p>
      {exercise.notes ? <p className="mt-2 text-[13px] text-[var(--muted)]">{exercise.notes}</p> : null}

      <div className="mt-3 space-y-3">
        {block.sets.map((set, i) => (
          <div key={i} className="rounded-[12px] p-2" style={{ background: 'var(--fill)' }}>
            <div className="mb-1 flex items-center justify-between px-1">
              <span className="text-[12px] text-[var(--muted)]">Sæt {i + 1}</span>
              <button
                type="button"
                onClick={() => onChange(exercise.id, i, { done: !set.done })}
                className="press h-8 rounded-full px-3 text-[13px] font-semibold"
                style={{
                  background: set.done ? 'var(--accent)' : 'var(--bg-elevated)',
                  color: set.done ? 'var(--accent-fg)' : 'var(--fg)',
                }}
              >
                {set.done ? 'Sat' : 'Markér'}
              </button>
            </div>
            <div className="flex gap-2">
              {exercise.logType === 'reps' ? (
                <NumberStepper
                  label="Kg"
                  value={set.weight}
                  step={2.5}
                  onChange={(weight) => onChange(exercise.id, i, { weight })}
                />
              ) : null}
              <NumberStepper
                label={exercise.logType === 'seconds' ? 'Sekunder' : 'Reps'}
                value={set.reps}
                step={exercise.logType === 'seconds' ? 5 : 1}
                onChange={(reps) => onChange(exercise.id, i, { reps })}
              />
            </div>
          </div>
        ))}
      </div>
    </Group>
  )
}

function formatSet(exercise: Exercise, set: { weight: number; reps: number }): string {
  if (exercise.logType === 'seconds') return `${set.reps}s`
  return `${set.weight} kg × ${set.reps}`
}
