import { useNavigate, useParams } from 'react-router-dom'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/db'
import { MUSCLE_LABELS } from '../db/types'
import { formatDayLong } from '../lib/dates'
import { Group, PageHeader, PlainButton, Row } from '../components/ui'

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
    <div className="space-y-5 pb-2">
      <PageHeader
        title={`Program ${session.workout}`}
        subtitle={`${capitalize(formatDayLong(session.date))} · ${session.completed ? 'Afsluttet' : 'Kladde'}`}
        backTo="/traening"
        backLabel="Træning"
      />

      {session.exercises.map((block) => {
        const exercise = byId[block.exerciseId]
        if (!exercise) return null
        return (
          <Group key={block.exerciseId} className="p-4">
            <div className="flex items-start justify-between gap-3">
              <div>
                <h2 className="text-[20px] font-semibold">{exercise.name}</h2>
                <p className="text-[13px] text-[var(--muted)]">{MUSCLE_LABELS[exercise.muscleGroup]}</p>
              </div>
              <Row to={`/traening/ovelse/${exercise.id}`} className="!min-h-0 !px-0 !py-0">
                <span className="text-[15px]" style={{ color: 'var(--blue)' }}>
                  Graf
                </span>
              </Row>
            </div>
            <ul className="mt-3 space-y-2">
              {block.sets.map((set, i) => (
                <li key={i} className="flex justify-between text-[15px]">
                  <span className="text-[var(--muted)]">Sæt {i + 1}</span>
                  <span className="tabular-nums">
                    {exercise.logType === 'seconds'
                      ? `${set.reps} sek`
                      : `${set.weight} kg × ${set.reps}`}
                    {set.done ? ' ✓' : ''}
                  </span>
                </li>
              ))}
            </ul>
          </Group>
        )
      })}

      <Group>
        <PlainButton
          danger
          onClick={async () => {
            if (!confirm('Slet dette pas?')) return
            await db.sessions.delete(session.id)
            navigate('/traening')
          }}
        >
          Slet pas
        </PlainButton>
      </Group>
    </div>
  )
}

function capitalize(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1)
}
