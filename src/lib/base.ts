/** React Router basename from Vite `base` ('' when serving from '/'). */
export function routerBasename(): string | undefined {
  const trimmed = import.meta.env.BASE_URL.replace(/\/$/, '')
  return trimmed.length > 0 ? trimmed : undefined
}
