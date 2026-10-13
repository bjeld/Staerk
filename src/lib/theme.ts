import type { ThemeMode } from '../db/types'

export function resolveDark(mode: ThemeMode): boolean {
  if (mode === 'dark') return true
  if (mode === 'light') return false
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}

export function applyTheme(mode: ThemeMode): void {
  const dark = resolveDark(mode)
  document.documentElement.classList.toggle('dark', dark)
  document.documentElement.style.colorScheme = dark ? 'dark' : 'light'
  localStorage.setItem('staerk-theme', mode)

  const color = dark ? '#000000' : '#f2f2f7'
  const meta = document.querySelector('meta[name="theme-color"]')
  if (meta) meta.setAttribute('content', color)
}
