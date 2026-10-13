import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthKitService.self) private var health
    @Query private var settingsRows: [AppSettings]
    @Query private var days: [DayLog]
    @Query(sort: \WorkoutSession.dateKey, order: .reverse) private var sessions: [WorkoutSession]
    @Query(filter: #Predicate<Exercise> { !$0.archived }, sort: \Exercise.order) private var exercises: [Exercise]

    private var settings: AppSettings { settingsRows.first ?? AppSettings.makeDefault() }
    private var todayKey: String { Dates.key() }
    private var day: DayLog? { days.first(where: { $0.dateKey == todayKey }) }
    private var kind: DayKind { Schedule.dayKind() }
    private var letter: WorkoutLetter { Schedule.pickWorkoutLetter(sessions: sessions) }
    private var todaySession: WorkoutSession? { sessions.first(where: { $0.dateKey == todayKey && $0.completed }) }
    private var todaysPlan: [Exercise] {
        exercises.filter { $0.workout == letter }.sorted { $0.order < $1.order }
    }

    private var weekMarks: [String: Bool] {
        let goal = settings.waterGoal
        var map: [String: Bool] = [:]
        for item in days {
            map[item.dateKey] = item.creatine && item.waterGlasses >= goal && item.alcoholFree
        }
        return map
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(
                    title: "\(Dates.greeting()), \(settings.displayName)",
                    subtitle: Dates.prettyLong(Date())
                )

                GroupedCard {
                    WeekStripView(today: todayKey, marks: weekMarks)
                }

                if day != nil {
                    ringsCard
                    healthCard
                    habitsCard
                    movementCard
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            _ = StaerkStore.day(for: todayKey, in: context)
            if health.didRequestAuthorization {
                await health.refreshToday()
                applyHealthHints()
            }
        }
        .refreshable {
            if health.didRequestAuthorization {
                await health.refreshToday()
                applyHealthHints()
            }
        }
    }

    private var ringsCard: some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    FitnessRingsView(
                        move: (day?.creatine ?? false) ? 1 : 0,
                        exercise: settings.waterGoal > 0 ? Double(day?.waterGlasses ?? 0) / Double(settings.waterGoal) : 0,
                        stand: (day?.alcoholFree ?? false) ? 1 : 0,
                        size: 148
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(kind.shortLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Palette.pink)
                        Text(heroTitle)
                            .font(.system(size: 22, weight: .bold))
                            .tracking(-0.4)
                        Text(kind.scheduleLabel)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.muted)
                        VStack(alignment: .leading, spacing: 4) {
                            legend(color: Palette.ringMove, text: "Kreatin", done: day?.creatine ?? false)
                            legend(
                                color: Palette.ringExercise,
                                text: "Vand \(day?.waterGlasses ?? 0)/\(settings.waterGoal)",
                                done: (day?.waterGlasses ?? 0) >= settings.waterGoal
                            )
                            legend(color: Palette.ringStand, text: "Alkoholfri", done: day?.alcoholFree ?? false)
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                if kind == .gym {
                    Text("~45 min · \(todaysPlan.map(\.muscleGroup.label).joined(separator: " · "))")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                    NavigationLink {
                        if let todaySession {
                            SessionDetailView(sessionID: todaySession.id)
                        } else {
                            SessionView()
                        }
                    } label: {
                        Text(todaySession == nil ? "Start træning" : "Se dagens pas")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Palette.accentForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Ingen vægtløftning i dag. En gåtur eller en runde golf tæller — og så kreatin, vand og en alkoholfri aften.")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                }
            }
            .padding(20)
        }
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Aktivitet i dag")
            GroupedCard {
                if health.showsPermissionPrompt {
                    permissionPrompt
                } else if !health.isAvailable {
                    Text("Apple Health er ikke tilgængelig på denne enhed.")
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.muted)
                        .padding(16)
                } else {
                    activityMetrics
                }
            }
        }
    }

    private var permissionPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Palette.pink)
                Text("Apple Health")
                    .font(.system(size: 17, weight: .semibold))
            }
            Text("STÆRK kan vise skridt, gåafstand, aktiv energi og golf fra Apple Sundhed — og gemme styrketræning og vægt.")
                .font(.system(size: 15))
                .foregroundStyle(Palette.muted)
            PrimaryButton(title: "Tillad adgang") {
                Task { await health.requestAccess() }
            }
        }
        .padding(16)
    }

    private var activityMetrics: some View {
        VStack(spacing: 0) {
            if health.showsDeniedHelp {
                Text("Sundhedsadgang er slået fra. Du kan slå den til under Indstillinger → Sundhed → Dataadgang.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
                    .padding(16)
                Divider().overlay(Palette.hairline)
            }

            metricRow(
                symbol: "figure.walk",
                tint: Palette.pink,
                title: "Skridt",
                value: stepsLabel,
                hint: health.today.steps == nil ? "Ingen data endnu" : "fra Apple Health"
            )
            Divider().overlay(Palette.hairline).padding(.leading, 58)
            metricRow(
                symbol: "flame.fill",
                tint: Palette.orange,
                title: "Aktiv energi",
                value: energyLabel,
                hint: "kcal"
            )
            Divider().overlay(Palette.hairline).padding(.leading, 58)
            metricRow(
                symbol: "location.fill",
                tint: Palette.cyan,
                title: "Gang & løb",
                value: distanceLabel,
                hint: "km"
            )

            if !health.today.workouts.isEmpty {
                Divider().overlay(Palette.hairline)
                ForEach(health.today.workouts) { workout in
                    HStack(spacing: 12) {
                        Image(systemName: workout.kind.symbol)
                            .foregroundStyle(Palette.accent)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.kind.title)
                                .font(.system(size: 17))
                            Text("\(workout.durationMinutes) min")
                                .font(.system(size: 13))
                                .foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        if let kcal = workout.kcal {
                            Text("\(Int(kcal.rounded())) kcal")
                                .font(.system(size: 15).monospacedDigit())
                                .foregroundStyle(Palette.muted)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Dagens vaner")
            GroupedCard {
                HabitToggleRow(
                    title: "Kreatin taget",
                    hint: "5 g med morgenkaffen eller efter træning",
                    tint: Palette.pink,
                    symbol: "pills.fill",
                    isOn: bindDay(\.creatine)
                )
                Divider().overlay(Palette.hairline).padding(.leading, 58)
                WaterCounterRow(value: bindDay(\.waterGlasses), goal: settings.waterGoal)
                Divider().overlay(Palette.hairline).padding(.leading, 58)
                HabitToggleRow(
                    title: "Alkoholfri dag",
                    hint: "Søvn, restitution og talje siger tak",
                    tint: Palette.orange,
                    symbol: "nosign",
                    isOn: bindDay(\.alcoholFree)
                )
            }
        }
    }

    private var movementCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Bevægelse")
            GroupedCard {
                if !health.didRequestAuthorization {
                    HStack {
                        Text("Skridt")
                            .font(.system(size: 17))
                        Spacer()
                        TextField("Valgfrit", text: intTextBinding(\.steps))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Palette.muted)
                            .frame(maxWidth: 120)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    Divider().overlay(Palette.hairline).padding(.leading, 16)
                }

                HStack {
                    Text("Gåtur")
                        .font(.system(size: 17))
                    Spacer()
                    TextField("Minutter", text: intTextBinding(\.walkMinutes))
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: 120)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Divider().overlay(Palette.hairline).padding(.leading, 16)
                HabitToggleRow(
                    title: "Golf i dag",
                    hint: "Runden tæller som aktiv restitution",
                    tint: Palette.accent,
                    symbol: "flag.fill",
                    isOn: bindDay(\.golf)
                )
            }
        }
    }

    private var heroTitle: String {
        if kind == .gym {
            if let todaySession {
                return "Program \(todaySession.workout.rawValue) er klaret"
            }
            return "Program \(letter.rawValue)"
        }
        return "Aktiv restitution"
    }

    private var stepsLabel: String {
        guard let steps = health.today.steps else { return "—" }
        return Int(steps.rounded()).formatted(.number)
    }

    private var energyLabel: String {
        guard let kcal = health.today.activeEnergyKcal else { return "—" }
        return "\(Int(kcal.rounded()))"
    }

    private var distanceLabel: String {
        guard let km = health.today.distanceKm else { return "—" }
        return String(format: "%.1f", km)
    }

    private func legend(color: Color, text: String, done: Bool) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(done ? "\(text) ✓" : text)
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
        }
    }

    private func metricRow(symbol: String, tint: Color, title: String, value: String, hint: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint)
                    .frame(width: 30, height: 30)
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17))
                Text(hint)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            Text(value)
                .font(.system(size: 22, weight: .semibold).monospacedDigit())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func bindDay<T>(_ keyPath: ReferenceWritableKeyPath<DayLog, T>) -> Binding<T> {
        Binding(
            get: {
                let row = day ?? StaerkStore.day(for: todayKey, in: context)
                return row[keyPath: keyPath]
            },
            set: { newValue in
                let row = StaerkStore.day(for: todayKey, in: context)
                row[keyPath: keyPath] = newValue
                try? context.save()
            }
        )
    }

    private func intTextBinding(_ keyPath: ReferenceWritableKeyPath<DayLog, Int?>) -> Binding<String> {
        Binding(
            get: {
                day?[keyPath: keyPath].map(String.init) ?? ""
            },
            set: { text in
                let row = StaerkStore.day(for: todayKey, in: context)
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                row[keyPath: keyPath] = trimmed.isEmpty ? nil : Int(trimmed)
                try? context.save()
            }
        )
    }

    private func applyHealthHints() {
        let row = StaerkStore.day(for: todayKey, in: context)
        if let minutes = health.today.golfMinutes, minutes > 0 {
            row.golf = true
        }
        if row.walkMinutes == nil, let walk = health.today.walkMinutes, walk > 0 {
            row.walkMinutes = walk
        }
        if row.steps == nil, let steps = health.today.steps {
            row.steps = Int(steps.rounded())
        }
        try? context.save()
    }
}
