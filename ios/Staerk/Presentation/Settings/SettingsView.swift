import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppContainer.self) private var app
    @Environment(HealthKitService.self) private var health
    @Query private var settingsRows: [SettingsRecord]
    @State private var status: String?
    @State private var notificationStatus: NotificationAuthStatus = .notDetermined
    @State private var exporting = false
    @State private var importing = false
    @State private var exportDocument = JSONFileDocument(text: "{}")
    @State private var confirmImport = false
    @State private var pendingImport: String?
    @State private var showOnboardingReset = false

    private var settings: UserSettings {
        settingsRows.first?.asDomain() ?? ((try? app.settings.settings()) ?? UserSettings())
    }

    var body: some View {
        Screen(spacing: Space.xxl) {
            ScreenHeader(title: L10n.string("settings.title"), subtitle: L10n.string("settings.subtitle"))

            profileCard

            TitledSection(title: L10n.string("settings.units")) {
                Card(padding: 0) {
                    segmentedRow(L10n.string("settings.weight.unit"), symbol: "scalemass.fill", tint: Palette.distance) {
                        Picker(L10n.string("settings.weight.unit"), selection: bind(\.weightUnit)) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.symbol).tag(unit)
                            }
                        }
                    }
                    RowDivider(inset: 64)
                    segmentedRow(L10n.string("settings.length.unit"), symbol: "ruler.fill", tint: Palette.energy) {
                        Picker(L10n.string("settings.length.unit"), selection: bind(\.lengthUnit)) {
                            ForEach(LengthUnit.allCases) { unit in
                                Text(unit.symbol).tag(unit)
                            }
                        }
                    }
                }
            }

            TitledSection(title: L10n.string("settings.goals")) {
                Card(padding: 0) {
                    optionalDoubleRow(
                        L10n.string("settings.weight.goal"),
                        symbol: "target",
                        unit: settings.weightUnit.symbol,
                        get: { settings.weightGoalKg.map { settings.weightUnit.fromKilograms($0) } },
                        set: { value in
                            var copy = settings
                            copy.weightGoalKg = value.map { settings.weightUnit.toKilograms($0) }
                            try? app.settings.save(copy)
                        }
                    )
                    RowDivider(inset: 64)
                    optionalDoubleRow(
                        L10n.string("settings.waist.goal"),
                        symbol: "figure.stand",
                        unit: settings.lengthUnit.symbol,
                        get: { settings.waistGoalCm.map { settings.lengthUnit.fromCentimeters($0) } },
                        set: { value in
                            var copy = settings
                            copy.waistGoalCm = value.map { settings.lengthUnit.toCentimeters($0) }
                            try? app.settings.save(copy)
                        }
                    )
                }
            }

            TitledSection(title: L10n.string("settings.appearance")) {
                Card(padding: Space.l) {
                    Picker(L10n.string("settings.appearance"), selection: bind(\.theme)) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }

            TitledSection(title: L10n.string("health.title")) {
                Card { healthSection }
            }

            TitledSection(title: L10n.string("settings.reminders")) {
                Card {
                    HStack(spacing: Space.m) {
                        IconBadge(symbol: "bell.badge.fill", tint: Palette.steps, size: 36)
                        Text(L10n.format("settings.reminders.status", permissionLabel))
                            .font(Typeface.rowTitle)
                            .foregroundStyle(Palette.ink)
                        Spacer()
                    }
                    Text(L10n.string("settings.reminders.hint"))
                        .font(.footnote)
                        .foregroundStyle(Palette.inkSecondary)
                        .staerkWrappingText()
                        .padding(.top, Space.m)
                    SecondaryButton(title: L10n.string("settings.reminders.allow")) {
                        Task { await enableReminders() }
                    }
                    .padding(.top, Space.l)
                }
            }

            Card(padding: 0) {
                NavigationLink {
                    HabitsView(embedded: true)
                } label: {
                    settingsLink(L10n.string("settings.habits"), symbol: "flame.fill", tint: Palette.energy)
                }
                .buttonStyle(.pressable)
                RowDivider(inset: 64)
                NavigationLink {
                    ProgramEditorView()
                } label: {
                    settingsLink(L10n.string("settings.program"), symbol: "dumbbell.fill", tint: Palette.accent)
                }
                .buttonStyle(.pressable)
            }

            TitledSection(title: L10n.string("settings.backup")) {
                VStack(alignment: .leading, spacing: Space.m) {
                    Card(padding: 0) {
                        Button {
                            Task { await exportData() }
                        } label: {
                            settingsLink(L10n.string("settings.export"), symbol: "square.and.arrow.up", tint: Palette.link, chevron: false)
                        }
                        .buttonStyle(.pressable)
                        RowDivider(inset: 64)
                        Button {
                            importing = true
                        } label: {
                            settingsLink(L10n.string("settings.import"), symbol: "square.and.arrow.down", tint: Palette.link, chevron: false)
                        }
                        .buttonStyle(.pressable)
                    }
                    Text(L10n.string("settings.backup.hint"))
                        .font(.footnote)
                        .foregroundStyle(Palette.inkSecondary)
                        .staerkWrappingText()
                        .padding(.horizontal, Space.xs)
                }
            }

            if let status {
                Callout(text: status, symbol: "info.circle.fill")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            VStack(spacing: Space.l) {
                Button(L10n.string("settings.reset.onboarding")) {
                    showOnboardingReset = true
                }
                .buttonStyle(.staerkDestructive)

                Text(L10n.string("settings.footer"))
                    .font(.caption)
                    .foregroundStyle(Palette.inkTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .animation(Motion.snappy, value: status)
        .navigationTitle(L10n.string("settings.title"))
        .toolbar(.hidden, for: .navigationBar)
        .task {
            notificationStatus = await app.notifications.currentStatus()
        }
        .fileExporter(
            isPresented: $exporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "staerk-backup-\(Dates.key())"
        ) { result in
            if case .success = result {
                status = L10n.string("backup.exported")
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else {
                    status = L10n.string("backup.error.encoding")
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    pendingImport = text
                    confirmImport = true
                } else {
                    status = L10n.string("backup.error.encoding")
                }
            case .failure:
                status = L10n.string("backup.error.encoding")
            }
        }
        .confirmationDialog(L10n.string("backup.import.confirm"), isPresented: $confirmImport, titleVisibility: .visible) {
            Button(L10n.string("settings.import"), role: .destructive) {
                if let pendingImport {
                    do {
                        try app.backup.importJSON(pendingImport)
                        status = L10n.string("backup.imported")
                        Task { await app.refreshReminders() }
                    } catch {
                        status = L10n.string("backup.error.encoding")
                    }
                }
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        }
        .confirmationDialog(L10n.string("settings.reset.confirm"), isPresented: $showOnboardingReset, titleVisibility: .visible) {
            Button(L10n.string("settings.reset.onboarding"), role: .destructive) {
                var copy = settings
                copy.onboardingCompleted = false
                try? app.settings.save(copy)
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        }
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Space.m) {
                IconBadge(symbol: "heart.fill", tint: Palette.health, size: 36)
                Text(L10n.string("health.title"))
                    .font(Typeface.rowTitle)
                    .foregroundStyle(Palette.ink)
                Spacer()
                Pill(text: healthStatusLabel, tint: healthStatusTint, filled: false)
            }
            Text(L10n.string("health.detail"))
                .font(.footnote)
                .foregroundStyle(Palette.inkSecondary)
                .staerkWrappingText()
                .padding(.top, Space.m)
            if health.showsDeniedHelp {
                Text(L10n.string("health.denied"))
                    .font(.footnote)
                    .foregroundStyle(Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.s)
                SecondaryButton(title: L10n.string("health.open.settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .padding(.top, Space.l)
            } else {
                SecondaryButton(
                    title: health.didRequestAuthorization ? L10n.string("health.refresh") : L10n.string("health.allow"),
                    symbol: health.didRequestAuthorization ? "arrow.clockwise" : nil
                ) {
                    Task {
                        if health.didRequestAuthorization {
                            await health.refreshToday()
                        } else {
                            await health.requestAccess()
                        }
                    }
                }
                .padding(.top, Space.l)
            }
            if let error = health.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Palette.danger)
                    .padding(.top, Space.s)
            }
        }
    }

    private var healthStatusTint: Color {
        guard health.isAvailable, health.didRequestAuthorization else { return Palette.inkSecondary }
        switch health.authorizationStatus {
        case .sharingAuthorized: return Palette.accent
        case .sharingDenied: return Palette.danger
        default: return Palette.energy
        }
    }

    private var profileCard: some View {
        Card {
            HStack(spacing: Space.l) {
                Text(String(settings.trimmedName.prefix(1)).uppercased())
                    .font(Typeface.display(26))
                    .foregroundStyle(Palette.onAccent)
                    .frame(width: 56, height: 56)
                    .background(Palette.accent, in: Circle())
                    .overlay {
                        if settings.trimmedName.isEmpty {
                            Image(systemName: "person.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Palette.onAccent)
                        }
                    }
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Eyebrow(text: L10n.string("settings.profile"))
                    TextField(L10n.string("settings.name"), text: bind(\.displayName))
                        .font(Typeface.cardTitle)
                        .foregroundStyle(Palette.ink)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                }
            }
        }
    }

    private var healthStatusLabel: String {
        if !health.isAvailable { return L10n.string("health.status.unavailable") }
        if !health.didRequestAuthorization { return L10n.string("health.status.unset") }
        switch health.authorizationStatus {
        case .sharingAuthorized: return L10n.string("health.status.connected")
        case .sharingDenied: return L10n.string("health.status.denied")
        default: return L10n.string("health.status.partial")
        }
    }

    private var permissionLabel: String {
        switch notificationStatus {
        case .authorized: return L10n.string("notify.allowed")
        case .denied: return L10n.string("notify.denied")
        case .notDetermined: return L10n.string("notify.unset")
        }
    }

    private func settingsLink(_ title: String, symbol: String, tint: Color, chevron: Bool = true) -> some View {
        ListRow(title: title) {
            IconBadge(symbol: symbol, tint: tint, size: 36)
        } trailing: {
            if chevron { Chevron() }
        }
    }

    private func segmentedRow<Control: View>(_ title: String, symbol: String, tint: Color, @ViewBuilder control: () -> Control) -> some View {
        HStack(spacing: Space.m) {
            IconBadge(symbol: symbol, tint: tint, size: 36)
            Text(title)
                .font(Typeface.rowTitle)
                .foregroundStyle(Palette.ink)
            Spacer(minLength: Space.m)
            control()
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
        }
        .padding(.horizontal, Space.l)
        .frame(minHeight: 60)
    }

    private func optionalDoubleRow(_ title: String, symbol: String, unit: String, get: @escaping () -> Double?, set: @escaping (Double?) -> Void) -> some View {
        HStack(spacing: Space.m) {
            IconBadge(symbol: symbol, tint: Palette.accent, size: 36)
            Text(title)
                .font(Typeface.rowTitle)
                .foregroundStyle(Palette.ink)
            Spacer()
            TextField("—", text: Binding(
                get: { get().map { UnitConversion.format($0) } ?? "" },
                set: { text in set(UnitConversion.parse(text)) }
            ))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .font(Typeface.title(20))
            .monospacedDigit()
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: 90)
            Text(unit)
                .font(Typeface.unit)
                .foregroundStyle(Palette.inkSecondary)
                .frame(minWidth: 22, alignment: .leading)
        }
        .padding(.horizontal, Space.l)
        .frame(minHeight: 60)
    }

    private func bind<T>(_ keyPath: WritableKeyPath<UserSettings, T>) -> Binding<T> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                var copy = settings
                copy[keyPath: keyPath] = newValue
                try? app.settings.save(copy)
            }
        )
    }

    private func enableReminders() async {
        let ok = await app.notifications.requestAuthorization()
        notificationStatus = await app.notifications.currentStatus()
        if ok {
            await app.refreshReminders()
            status = L10n.string("notify.enabled")
        } else {
            status = L10n.string("notify.rejected")
        }
    }

    private func exportData() async {
        status = L10n.string("backup.building")
        do {
            let json = try app.backup.exportJSON()
            exportDocument = JSONFileDocument(text: json)
            exporting = true
        } catch {
            status = L10n.string("backup.error.encoding")
        }
    }
}
