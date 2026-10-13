import type { ReactNode } from 'react'
import { IosToggle, Row, RowGlyph } from './ui'

type Props = {
  checked: boolean
  onChange: (next: boolean) => void
  title: string
  hint: string
  tint?: string
  glyph: ReactNode
}

export function HabitToggle({ checked, onChange, title, hint, tint, glyph }: Props) {
  return (
    <Row onClick={() => onChange(!checked)}>
      <RowGlyph tint={tint}>{glyph}</RowGlyph>
      <span className="min-w-0 flex-1">
        <span className="block text-[17px] leading-tight">{title}</span>
        <span className="block text-[13px] text-[var(--muted)]">{hint}</span>
      </span>
      <IosToggle checked={checked} onChange={onChange} label={title} />
    </Row>
  )
}
