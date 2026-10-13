export function uid(prefix = 'id'): string {
  return `${prefix}_${crypto.randomUUID()}`
}
