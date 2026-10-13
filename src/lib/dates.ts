import { addDays, format, startOfWeek, parseISO, isToday, differenceInCalendarDays } from 'date-fns'
import { da } from 'date-fns/locale'

export function todayKey(date = new Date()): string {
  return format(date, 'yyyy-MM-dd')
}

export function parseDay(key: string): Date {
  return parseISO(key)
}

export function formatDayLong(key: string): string {
  return format(parseDay(key), 'EEEE d. MMMM', { locale: da })
}

export function formatDayShort(key: string): string {
  return format(parseDay(key), 'd. MMM', { locale: da })
}

export function formatPrettyDate(date: Date): string {
  return format(date, 'EEEE d. MMMM', { locale: da })
}

export function mondayOf(date = new Date()): Date {
  return startOfWeek(date, { weekStartsOn: 1 })
}

export function weekKeys(date = new Date()): string[] {
  const start = mondayOf(date)
  return Array.from({ length: 7 }, (_, i) => todayKey(addDays(start, i)))
}

export function monthGrid(date: Date): (string | null)[] {
  const start = new Date(date.getFullYear(), date.getMonth(), 1)
  const end = new Date(date.getFullYear(), date.getMonth() + 1, 0)
  const mondayIndex = (start.getDay() + 6) % 7
  const cells: (string | null)[] = Array.from({ length: mondayIndex }, () => null)
  for (let d = 1; d <= end.getDate(); d++) {
    cells.push(todayKey(new Date(date.getFullYear(), date.getMonth(), d)))
  }
  while (cells.length % 7 !== 0) cells.push(null)
  return cells
}

export function isSameDayKey(key: string, date = new Date()): boolean {
  return key === todayKey(date)
}

export { isToday, differenceInCalendarDays, addDays, format }
