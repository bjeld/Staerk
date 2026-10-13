import { NavLink, Outlet } from 'react-router-dom'
import { DumbbellIcon, FigureIcon, FlameIcon, GearIcon, HouseIcon } from './Icons'

const links = [
  { to: '/', label: 'I dag', icon: HouseIcon, tint: 'var(--pink)' },
  { to: '/traening', label: 'Træning', icon: DumbbellIcon, tint: 'var(--accent)' },
  { to: '/vaner', label: 'Vaner', icon: FlameIcon, tint: 'var(--orange)' },
  { to: '/fremskridt', label: 'Krop', icon: FigureIcon, tint: 'var(--cyan)' },
  { to: '/indstillinger', label: 'Mere', icon: GearIcon, tint: 'var(--muted)' },
]

export function Layout() {
  return (
    <div className="mx-auto flex min-h-dvh w-full max-w-lg flex-col">
      <main className="safe-bottom flex-1 px-4 pt-[max(0.75rem,env(safe-area-inset-top))]">
        <Outlet />
      </main>
      <nav
        className="fixed inset-x-0 bottom-0 z-20"
        style={{
          background: 'var(--tab-bg)',
          backdropFilter: 'saturate(180%) blur(24px)',
          WebkitBackdropFilter: 'saturate(180%) blur(24px)',
          borderTop: '0.5px solid var(--hairline)',
          paddingBottom: 'env(safe-area-inset-bottom)',
        }}
      >
        <div className="mx-auto grid max-w-lg grid-cols-5 px-1 pt-1.5 pb-1">
          {links.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.to === '/'}
              className="press flex min-h-12 flex-col items-center justify-center gap-0.5 rounded-lg"
            >
              {({ isActive }) => (
                <>
                  <link.icon active={isActive} color={isActive ? link.tint : 'var(--muted)'} />
                  <span
                    className="text-[10px] font-medium"
                    style={{ color: isActive ? link.tint : 'var(--muted)' }}
                  >
                    {link.label}
                  </span>
                </>
              )}
            </NavLink>
          ))}
        </div>
      </nav>
    </div>
  )
}
