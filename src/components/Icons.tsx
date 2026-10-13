type IconProps = { active?: boolean; color?: string; size?: number }

function stroke(active?: boolean, color?: string) {
  return color ?? (active ? 'var(--accent)' : 'currentColor')
}

export function HouseIcon({ active, color, size = 26 }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke(active, color)} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 10.8 12 4l8 6.8V20a1 1 0 0 1-1 1h-5.2v-6.2H9.2V21H5a1 1 0 0 1-1-1v-9.2Z" />
    </svg>
  )
}

export function DumbbellIcon({ active, color, size = 26 }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke(active, color)} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M4 9.2h2.2v5.6H4zM17.8 9.2H20v5.6h-2.2zM6.2 11.2h11.6v1.6H6.2zM7.4 7.4h1.6v9.2H7.4zM15 7.4h1.6v9.2H15z" />
    </svg>
  )
}

export function FlameIcon({ active, color, size = 26 }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke(active, color)} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 3.5s5.4 5.2 5.4 10.2a5.4 5.4 0 1 1-10.8 0c0-1.9 1.4-4.6 2.8-6.5 0 1.8.9 2.7 2.6 2.7 0-2.6 0-4.5 0-6.4Z" />
    </svg>
  )
}

export function FigureIcon({ active, color, size = 26 }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke(active, color)} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="5.2" r="1.8" />
      <path d="M8.2 21.2v-2.6l-1.8-5.6 3.6-2.6 2 1.6 2-1.6 3.6 2.6-1.8 5.6v2.6" />
    </svg>
  )
}

export function GearIcon({ active, color, size = 26 }: IconProps) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={stroke(active, color)} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3.1" />
      <path d="M12 3.6v1.8M12 18.6v1.8M3.6 12h1.8M18.6 12h1.8M6.1 6.1l1.3 1.3M16.6 16.6l1.3 1.3M17.9 6.1 16.6 7.4M7.4 16.6 6.1 17.9" />
    </svg>
  )
}

export function ChevronIcon() {
  return (
    <svg width="10" height="16" viewBox="0 0 10 16" fill="none" aria-hidden>
      <path d="M2 2.2 7.6 8 2 13.8" stroke="var(--muted)" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}

export function PillIcon({ color = 'var(--pink)' }: { color?: string }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.7" strokeLinecap="round">
      <rect x="4.2" y="9.2" width="15.6" height="5.6" rx="2.8" />
      <path d="M12 9.2v5.6" />
    </svg>
  )
}

export function DropIcon({ color = 'var(--cyan)' }: { color?: string }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M12 4.2C12 4.2 6.8 10.4 6.8 14.2a5.2 5.2 0 0 0 10.4 0C17.2 10.4 12 4.2 12 4.2Z" />
    </svg>
  )
}

export function BanIcon({ color = 'var(--orange)' }: { color?: string }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.7">
      <circle cx="12" cy="12" r="7.4" />
      <path d="m7.2 16.8 9.6-9.6" />
    </svg>
  )
}

export function FlagIcon({ color = 'var(--accent)' }: { color?: string }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6.4 20.2V5.2" />
      <path d="M6.4 5.2h10.4l-2.2 3.4 2.2 3.4H6.4" />
    </svg>
  )
}

export function BackIcon() {
  return (
    <svg width="12" height="20" viewBox="0 0 12 20" fill="none">
      <path d="M10 2 2 10l8 8" stroke="var(--blue)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  )
}
