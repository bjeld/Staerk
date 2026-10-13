import { useMemo } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/db'
import { MUSCLE_LABELS, type WorkoutLetter } from '../db/types'
import { formatDayShort, todayKey } from '../lib/dates'
import { dayKind, pickWorkoutLetter } from '../lib/schedule'
import { EmptyState, Group, PageHeader, PrimaryButton, Row, RowChevron, SectionLabel } from '../components/ui'

export function TrainingPage() {
  const exercises = useLiveQuery(() => db.exercises.filter((e) => !e.archived).toArray()) ?? []
  const sessions = useLiveQuery(() => db.sessions.orderBy('date').reverse().toArray()) ?? []
  const letter = pickWorkoutLetter(sessions)
  const kind = dayKind()
  const date = todayKey()
  const todayDone = sessions.find((s) => s.date === date && s.completed)

  const byLetter = (w: WorkoutLetter) =>
    exercises.filter((e) => e.workout === w).sort((a, b) => a.order - b.order)

  const recent = useMemo(() => sessions.filter((s) => s.completed).slice(0, 8), [sessions])

  return (
    <div className="space-y-6 pb-2">
      <PageHeader
        title="Træning"
        subtitle="Fuldkropsstyrke 3× om ugen, ~45 min. Man/ons/fre tidligt på jobbet."
      />

      <Group className="px-4 py-4">
        <p className="text-[13px] font-medium" style={{ color: 'var(--accent)' }}>
          {kind === 'gym' ? 'Næste pas' : 'Næste gym-dag'}
        </p>
        <h2 className="mt-1 text-[28px] font-bold tracking-tight">
          {todayDone ? `Program ${todayDone.workout}` : `Program ${letter}`}
        </h2>
        <p className="mt-1 text-[15px] text-[var(--muted)]">
          {kind === 'gym'
            ? 'Log sæt, mens pulsen stadig er oppe — så husker du tallene.'
            : 'I dag er restitution. Programmet venter til næste mandag, onsdag eller fredag.'}
        </p>
        <div className="mt-4 grid grid-cols-2 gap-2">
          <PrimaryButton to="/traening/session">{todayDone ? 'Nyt pas' : 'Start pas'}</PrimaryButton>
          <Row to="/traening/program" className="justify-center rounded-[12px] !px-0" >
            <span className="w-full text-center text-[17px] font-semibold" style={{ color: 'var(--blue)' }}>
              Rediger
            </span>
          </Row>
        </div>
      </Group>

      <ProgramList letter="A" active={letter === 'A' && !todayDone} exercises={byLetter('A')} />
      <ProgramList letter="B" active={letter === 'B' && !todayDone} exercises={byLetter('B')} />

      <div>
        <SectionLabel>Historik</SectionLabel>
        <Group>
          {recent.length === 0 ? (
            <EmptyState>Ingen pas logget endnu. Første uge er den sværeste — så bliver det vane.</EmptyState>
          ) : (
            recent.map((s) => {
              const doneSets = s.exercises.reduce((n, e) => n + e.sets.filter((x) => x.done).length, 0)
              return (
                <Row key={s.id} to={`/traening/${s.id}`}>
                  <span className="min-w-0 flex-1">
                    <span className="block text-[17px]">Program {s.workout}</span>
                    <span className="block text-[13px] text-[var(--muted)]">
                      {formatDayShort(s.date)} · {doneSets} sæt
                    </span>
                  </span>
                  <RowChevron />
                </Row>
              )
            })
          )}
        </Group>
      </div>
    </div>
  )
}

function ProgramList({
  letter,
  active,
  exercises,
}: {
  letter: WorkoutLetter
  active: boolean
  exercises: {
    id: string
    name: string
    muscleGroup: keyof typeof MUSCLE_LABELS
    defaultSets: number
    defaultRepsMin: number
    defaultRepsMax: number
    logType: string
  }[]
}) {
  return (
    <div>
      <SectionLabel>
        Program {letter}
        {active ? ' · i dag' : ''}
      </SectionLabel>
      <Group>
        {exercises.map((e, i) => (
          <Row key={e.id}>
            <span
              className="grid h-7 w-7 shrink-0 place-items-center rounded-full text-[13px] font-semibold"
              style={{ background: 'var(--fill)' }}
            >
              {i + 1}
            </span>
            <span className="min-w-0 flex-1">
              <span className="block text-[17px]">{e.name}</span>
              <span className="block text-[13px] text-[var(--muted)]">
                {MUSCLE_LABELS[e.muscleGroup]} · {e.defaultSets} ×{' '}
                {e.logType === 'seconds'
                  ? `${e.defaultRepsMin}–${e.defaultRepsMax} sek`
                  : `${e.defaultRepsMin}–${e.defaultRepsMax}`}
              </span>
            </span>
          </Row>
        ))}
      </Group>
    </div>
  )
}
