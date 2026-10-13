import type { AppSettings, DayLog } from '../db/types'
import { isTrainingWeekday } from './schedule'
import { todayKey } from './dates'

const CREATINE_TAG = 'staerk-creatine'
const WORKOUT_TAG = 'staerk-workout'

function minutesNow(): number {
  const n = new Date()
  return n.getHours() * 60 + n.getMinutes()
}

function parseTime(hhmm: string): number {
  const [h, m] = hhmm.split(':').map((x) => Number(x))
  return (h || 0) * 60 + (m || 0)
}

export async function ensureNotificationPermission(): Promise<boolean> {
  if (!('Notification' in window)) return false
  if (Notification.permission === 'granted') return true
  if (Notification.permission === 'denied') return false
  const result = await Notification.requestPermission()
  return result === 'granted'
}

export function notificationsSupported(): boolean {
  return typeof window !== 'undefined' && 'Notification' in window
}

function notify(title: string, body: string, tag: string): void {
  if (!('Notification' in window) || Notification.permission !== 'granted') return
  try {
    new Notification(title, { body, tag, silent: false })
  } catch {
    // iOS and some browsers require a service worker registration
  }
}

export function maybeFireReminders(settings: AppSettings, today: DayLog | undefined): void {
  if (Notification.permission !== 'granted') return
  const now = minutesNow()
  const due = parseTime(settings.reminderTime)
  if (now < due) return

  const firedKey = `staerk-fired-${todayKey()}`
  const fired = JSON.parse(localStorage.getItem(firedKey) || '{}') as Record<string, boolean>

  if (settings.creatineReminder && !today?.creatine && !fired[CREATINE_TAG]) {
    notify('Kreatin', 'Har du taget din kreatin i dag?', CREATINE_TAG)
    fired[CREATINE_TAG] = true
  }

  if (settings.workoutReminder && isTrainingWeekday() && !fired[WORKOUT_TAG]) {
    notify('Træning', 'Styrkepas i morges? Log sætene, mens de er i frisk erindring.', WORKOUT_TAG)
    fired[WORKOUT_TAG] = true
  }

  localStorage.setItem(firedKey, JSON.stringify(fired))
}

export function scheduleOpenReminders(settings: AppSettings, today: DayLog | undefined): number | null {
  if (Notification.permission !== 'granted') return null
  const now = minutesNow()
  const due = parseTime(settings.reminderTime)
  if (now >= due) {
    maybeFireReminders(settings, today)
    return null
  }
  const waitMs = (due - now) * 60 * 1000
  return window.setTimeout(() => maybeFireReminders(settings, today), waitMs)
}
