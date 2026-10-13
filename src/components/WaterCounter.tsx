import { IosStepper, Row, RowGlyph } from './ui'
import { DropIcon } from './Icons'

type Props = {
  value: number
  goal: number
  onChange: (next: number) => void
}

export function WaterCounter({ value, goal, onChange }: Props) {
  const pct = Math.round((Math.min(value, goal) / Math.max(goal, 1)) * 100)
  return (
    <Row>
      <RowGlyph tint="var(--cyan)">
        <DropIcon color="#fff" />
      </RowGlyph>
      <span className="min-w-0 flex-1">
        <span className="block text-[17px] leading-tight">Vand</span>
        <span className="block text-[13px] text-[var(--muted)]">
          {value} / {goal} glas · {pct}%
        </span>
      </span>
      <IosStepper value={value} min={0} onChange={onChange} />
    </Row>
  )
}
