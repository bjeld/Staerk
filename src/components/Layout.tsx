import { NavLink, Outlet } from 'react-router-dom'

const links = [
  { to: '/', label: 'I dag', icon: HomeIcon },
  { to: '/traening', label: 'Træning', icon: DumbbellIcon },
  { to: '/vaner', label: 'Vaner', icon: FireIcon },
  { to: '/fremskridt', label: 'Krop', icon: BodyIcon },
  { to: '/indstillinger', label: 'Mere', icon: GearIcon },
]

export function Layout() {
  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-lg flex-col">
      <main className="safe-bottom flex-1 px-4 pt-[max(1rem,env(safe-area-inset-top))]">
        <Outlet />
      </main>
      <nav
        className="fixed inset-x-0 bottom-0 z-20 border-t backdrop-blur-xl"
        style={{
          background: 'color-mix(in oklab, var(--surface) 88%, transparent)',
          borderColor: 'var(--line)',
          paddingBottom: 'env(safe-area-inset-bottom)',
        }}
      >
        <div className="mx-auto grid max-w-lg grid-cols-5 px-1 pt-1.5 pb-1">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.to === '/'}
              className="tap flex flex-col items-center justify-center gap-0.5 rounded-xl px-1 py-1.5 text-[11px] font-semibold"
            >
              {({ isActive }) => (
                <>
                  <link.icon active={isActive} />
                  <span style={{ color: isActive ? 'var(--accent)' : 'var(--muted)' }}>{link.label}</span>
                </>
              )}
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  )
}

function HomeIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={active ? 'var(--accent)' : 'var(--muted)'} strokeWidth="2">
      <path d="M4 10.5 12 4l8 6.5V20a1 1 0 0 1-1 1h-5v-6H10v6H5a1 1 0 0 1-1-1v-9.5Z" />
    </svg>
  )
}

function DumbbellIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={active ? 'var(--accent)' : 'var(--muted)'} strokeWidth="2">
      <path d="M3 9h3v6H3zM18 9h3v6h-3zM6 11h12v2H6zM7 7h2v10H7zM15 7h2v10h-2z" />
    </svg>
  )
}

function FireIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={active ? 'var(--accent)' : 'var(--muted)'} strokeWidth="2">
      <path d="M12 3s6 6 6 11a6 6 0 1 1-12 0c0-2 1.5-5 3-7 0 2 1 3 3 3 0-3 0-5 0-7Z" />
    </svg>
  )
}

function BodyIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={active ? 'var(--accent)' : 'var(--muted)'} strokeWidth="2">
      <circle cx="12" cy="5" r="2" />
      <path d="M8 22v-3l-2-6 4-3 2 2 2-2 4 3-2 6v3" />
    </svg>
  )
}

function GearIcon({ active }: { active: boolean }) {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={active ? 'var(--accent)' : 'var(--muted)'} strokeWidth="2">
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9c.3.7.9 1.1 1.5 1.1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z" />
    </svg>
  )
}
