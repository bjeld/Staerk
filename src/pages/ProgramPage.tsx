import { useState, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '../db/db'
import {
  MUSCLE_GROUPS,
  MUSCLE_LABELS,
  WORKOUT_LETTERS,
  type Exercise,
  type LogType,
  type MuscleGroup,
  type WorkoutLetter,
} from '../db/types'
import { uid } from '../lib/ids'
import { defaultExercises } from '../db/seed'

export function ProgramPage() {
  const exercises = useLiveQuery(() => db.exercises.toArray()) ?? []
  const [editing, setEditing] = useState<Exercise | null>(null)

  const visible = exercises.filter((e) => !e.archived).sort((a, b) => a.order - b.order)

  async function save(ex: Exercise) {
    await db.exercises.put(ex)
    setEditing(null)
  }

  async function move(ex: Exercise, dir: -1 | 1) {
    const siblings = visible.filter((e) => e.workout === ex.workout)
    const i = siblings.findIndex((e) => e.id === ex.id)
    const j = i + dir
    if (j < 0 || j >= siblings.length) return
    const other = siblings[j]
    await db.exercises.bulkPut([
      { ...ex, order: other.order },
      { ...other, order: ex.order },
    ])
  }

  return (
    <div className="space-y-4 pb-2">
      <header className="pt-2">
        <Link to="/traening" className="text-sm font-semibold text-[var(--muted)]">
          ← Træning
        </Link>
        <h1 className="mt-2 font-display text-4xl font-extrabold leading-none">Øvelser</h1>
        <p className="mt-1 text-sm text-[var(--muted)]">
          Tilpas programmet til det, jobgymmet faktisk har. Gemte ændringer bliver på denne enhed.
        </p>
      </header>

      {WORKOUT_LETTERS.map((letter) => (
        <section key={letter} className="space-y-2">
          <h2 className="font-display text-2xl font-extrabold">Program {letter}</h2>
          {visible
            .filter((e) => e.workout === letter)
            .map((ex) => (
              <article
                key={ex.id}
                className="rounded-2xl border p-3"
                style={{ background: 'var(--surface-2)', borderColor: 'var(--line)' }}
              >
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <h3 className="font-display text-lg font-bold">{ex.name}</h3>
                    <p className="text-sm text-[var(--muted)]">
                      {MUSCLE_LABELS[ex.muscleGroup]} · {ex.defaultSets} × {ex.defaultRepsMin}–{ex.defaultRepsMax}
                      {ex.logType === 'seconds' ? ' sek' : ''}
                    </p>
                  </div>
                  <div className="flex gap-1">
                    <IconBtn label="Op" onClick={() => void move(ex, -1)}>
                      ↑
                    </IconBtn>
                    <IconBtn label="Ned" onClick={() => void move(ex, 1)}>
                      ↓
                    </IconBtn>
                  </div>
                </div>
                <div className="mt-2 flex gap-2">
                  <button
                    type="button"
                    onClick={() => setEditing(ex)}
                    className="h-11 flex-1 rounded-xl border font-semibold"
                    style={{ borderColor: 'var(--line)' }}
                  >
                    Rediger
                  </button>
                  <button
                    type="button"
                    onClick={() => void db.exercises.update(ex.id, { archived: true })}
                    className="h-11 rounded-xl px-4 font-semibold text-red-600"
                  >
                    Skjul
                  </button>
                </div>
              </article>
            ))}
        </section>
      ))}

      <button
        type="button"
        onClick={() =>
          setEditing({
            id: uid('ex'),
            name: '',
            muscleGroup: 'legs',
            workout: 'A',
            defaultSets: 3,
            defaultRepsMin: 8,
            defaultRepsMax: 12,
            logType: 'reps',
            notes: '',
            order: visible.length + 1,
            archived: false,
          })
        }
        className="h-12 w-full rounded-2xl font-bold"
        style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}
      >
        Tilføj øvelse
      </button>
      <button
        type="button"
        onClick={async () => {
          if (!confirm('Nulstil til standardprogrammet? Dine egne øvelser overskrives.')) return
          await db.exercises.clear()
          await db.exercises.bulkAdd(defaultExercises)
        }}
        className="h-12 w-full rounded-2xl border font-semibold"
        style={{ borderColor: 'var(--line)' }}
      >
        Gendan standardprogram
      </button>

      {editing ? (
        <Editor
          exercise={editing}
          onCancel={() => setEditing(null)}
          onSave={(ex) => void save(ex)}
        />
      ) : null}
    </div>
  )
}

function IconBtn({ children, onClick, label }: { children: string; onClick: () => void; label: string }) {
  return (
    <button
      type="button"
      aria-label={label}
      onClick={onClick}
      className="grid h-11 w-11 place-items-center rounded-xl border text-lg"
      style={{ borderColor: 'var(--line)', background: 'var(--bg)' }}
    >
      {children}
    </button>
  )
}

function Editor({
  exercise,
  onCancel,
  onSave,
}: {
  exercise: Exercise
  onCancel: () => void
  onSave: (ex: Exercise) => void
}) {
  const [draft, setDraft] = useState(exercise)

  return (
    <div className="fixed inset-0 z-30 grid place-items-end bg-black/50 p-3 sm:place-items-center">
      <form
        className="max-h-[92dvh] w-full max-w-lg space-y-3 overflow-y-auto rounded-3xl p-4"
        style={{ background: 'var(--surface)', color: 'var(--fg)' }}
        onSubmit={(e) => {
          e.preventDefault()
          if (!draft.name.trim()) return
          onSave({ ...draft, name: draft.name.trim() })
        }}
      >
        <h2 className="font-display text-2xl font-extrabold">Rediger øvelse</h2>
        <Field label="Navn">
          <input
            required
            value={draft.name}
            onChange={(e) => setDraft({ ...draft, name: e.target.value })}
            className="field"
          />
        </Field>
        <div className="grid grid-cols-2 gap-2">
          <Field label="Program">
            <select
              className="field"
              value={draft.workout}
              onChange={(e) => setDraft({ ...draft, workout: e.target.value as WorkoutLetter })}
            >
              {WORKOUT_LETTERS.map((w) => (
                <option key={w} value={w}>
                  {w}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Muskel">
            <select
              className="field"
              value={draft.muscleGroup}
              onChange={(e) => setDraft({ ...draft, muscleGroup: e.target.value as MuscleGroup })}
            >
              {MUSCLE_GROUPS.map((g) => (
                <option key={g} value={g}>
                  {MUSCLE_LABELS[g]}
                </option>
              ))}
            </select>
          </Field>
        </div>
        <div className="grid grid-cols-3 gap-2">
          <Field label="Sæt">
            <input
              type="number"
              min={1}
              className="field"
              value={draft.defaultSets}
              onChange={(e) => setDraft({ ...draft, defaultSets: Number(e.target.value) || 1 })}
            />
          </Field>
          <Field label="Min">
            <input
              type="number"
              min={1}
              className="field"
              value={draft.defaultRepsMin}
              onChange={(e) => setDraft({ ...draft, defaultRepsMin: Number(e.target.value) || 1 })}
            />
          </Field>
          <Field label="Max">
            <input
              type="number"
              min={1}
              className="field"
              value={draft.defaultRepsMax}
              onChange={(e) => setDraft({ ...draft, defaultRepsMax: Number(e.target.value) || 1 })}
            />
          </Field>
        </div>
        <Field label="Logning">
          <select
            className="field"
            value={draft.logType}
            onChange={(e) => setDraft({ ...draft, logType: e.target.value as LogType })}
          >
            <option value="reps">Vægt og reps</option>
            <option value="seconds">Sekunder (planke)</option>
          </select>
        </Field>
        <Field label="Noter">
          <textarea
            rows={3}
            className="field min-h-20 py-3"
            value={draft.notes}
            onChange={(e) => setDraft({ ...draft, notes: e.target.value })}
          />
        </Field>
        <div className="grid grid-cols-2 gap-2 pt-1">
          <button type="button" onClick={onCancel} className="h-12 rounded-2xl border font-semibold" style={{ borderColor: 'var(--line)' }}>
            Annuller
          </button>
          <button type="submit" className="h-12 rounded-2xl font-bold" style={{ background: 'var(--accent)', color: 'var(--accent-fg)' }}>
            Gem
          </button>
        </div>
        <style>{`
          .field {
            width: 100%;
            height: 3rem;
            border-radius: 1rem;
            border: 1px solid var(--line);
            background: var(--bg);
            color: var(--fg);
            padding: 0 0.9rem;
            outline: none;
          }
        `}</style>
      </form>
    </div>
  )
}

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-semibold text-[var(--muted)]">{label}</span>
      {children}
    </label>
  )
}
