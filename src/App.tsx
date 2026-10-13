import { useEffect } from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { useLiveQuery } from 'dexie-react-hooks'
import { Layout } from './components/Layout'
import { db } from './db/db'
import { applyTheme } from './lib/theme'
import { scheduleOpenReminders } from './lib/notifications'
import { todayKey } from './lib/dates'
import { TodayPage } from './pages/TodayPage'
import { TrainingPage } from './pages/TrainingPage'
import { SessionPage } from './pages/SessionPage'
import { SessionDetailPage } from './pages/SessionDetailPage'
import { ProgramPage } from './pages/ProgramPage'
import { ExercisePage } from './pages/ExercisePage'
import { HabitsPage } from './pages/HabitsPage'
import { ProgressPage } from './pages/ProgressPage'
import { SettingsPage } from './pages/SettingsPage'
import { routerBasename } from './lib/base'

export default function App() {
  return (
    <BrowserRouter basename={routerBasename()}>
      <ThemeAndReminders />
      <Routes>
        <Route element={<Layout />}>
          <Route index element={<TodayPage />} />
          <Route path="traening" element={<TrainingPage />} />
          <Route path="traening/session" element={<SessionPage />} />
          <Route path="traening/program" element={<ProgramPage />} />
          <Route path="traening/ovelse/:exerciseId" element={<ExercisePage />} />
          <Route path="traening/:sessionId" element={<SessionDetailPage />} />
          <Route path="vaner" element={<HabitsPage />} />
          <Route path="fremskridt" element={<ProgressPage />} />
          <Route path="indstillinger" element={<SettingsPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}

function ThemeAndReminders() {
  const settings = useLiveQuery(() => db.settings.get('settings'))
  const today = useLiveQuery(() => db.days.get(todayKey()), [])

  useEffect(() => {
    if (!settings) return
    applyTheme(settings.theme)
    const media = window.matchMedia('(prefers-color-scheme: dark)')
    const onChange = () => {
      if (settings.theme === 'system') applyTheme('system')
    }
    media.addEventListener('change', onChange)
    return () => media.removeEventListener('change', onChange)
  }, [settings])

  useEffect(() => {
    if (!settings) return
    const handle = scheduleOpenReminders(settings, today)
    const onVis = () => scheduleOpenReminders(settings, today)
    document.addEventListener('visibilitychange', onVis)
    return () => {
      if (handle) window.clearTimeout(handle)
      document.removeEventListener('visibilitychange', onVis)
    }
  }, [settings, today])

  return null
}
