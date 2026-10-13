import { Link, useNavigate, useParams } from 'react-router-dom'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/db'
import { MUSCLE_LABELS } from '../db/types'
import { formatDayLong } from '../lib/dates'

export function SessionDetailPage() {
  const { sessionId } = useParams()
  const navigate = useNavigate()
  const session = useLiveQuery(() => (sessionId ? db.sessions.get(sessionId) : undefined), [sessionId])
  const exercises = useLiveQuery(() => db.exercises.toArray()) ?? []

  if (!session) {
    return <p className="pt-8 text-[var(--muted)]">Finder passet…</p>
  }

  const byId = Object.fromEntries(exercises.map((e) => [e.id, e]))

  return (
    <div className="space-y-4 pb-2">
      <header className="pt-2">
        <Link to="/traening" className="text-sm font-semibold text-[var(--muted)]">
          ← Træning
        </Link>
        <h1 className="mt-2 font-display text-4xl font-extrabold leading-none">Program {session.workout}</h1>
        <p className="mt-1 capitalize text-[var(--muted)]">
          {formatDayLong(session.date)} · {session.completed ? 'Afsluttet' : 'Kladde'}
        </p>
      </header>

      {session.exercises.map((block) => {
        const exercise = byId[block.exerciseId]
        if (!exercise) return null
        return (
          <article
            key={block.exerciseId}
            className="rounded-3xl border p-4"
            style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}
          >
            <div className="flex items-start justify-between gap-3">
              <div>
                <h2 className="font-display text-xl font-extrabold">{exercise.name}</h2>
                <p className="text-sm text-[var(--muted)]">{MUSCLE_LABELS[exercise.muscleGroup]}</p>
              </div>
              <Link to={`/traening/ovelse/${exercise.id}`} className="text-sm font-semibold" style={{ color: 'var(--accent)' }}>
                Graf
              </Link>
            </div>
            <ul className="mt-3 space-y-1.5">
              {block.sets.map((set, i) => (
                <li key={i} className="flex justify-between text-sm">
                  <span className="text-[var(--muted)]">Sæt {i + 1}</span>
                  <span className="font-semibold">
                    {exercise.logType === 'seconds'
                      ? `${set.reps} sek`
                      : `${set.weight} kg × ${set.reps}`}
                    {set.done ? ' ✓' : ''}
                  </span>
                </li>
              ))}
            </ul>
          </article>
        )
      })}

      <button
        type="button"
        onClick={async () => {
          if (!confirm('Slet dette pas?')) return
          await db.sessions.delete(session.id)
          navigate('/traening')
        }}
        className="h-12 w-full rounded-2xl border font-semibold text-red-600"
        style={{ borderColor: 'var(--line)' }}
      >
        Slet pas
      </button>
    </div>
  )
}
