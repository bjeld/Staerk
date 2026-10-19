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
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(title: L10n.string("settings.title"), subtitle: L10n.string("settings.subtitle"))

                labeled(L10n.string("settings.profile")) {
                    GroupedCard {
                        HStack {
                            Text(L10n.string("settings.name"))
                            Spacer()
                            TextField(L10n.string("settings.name"), text: bind(\.displayName))
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }

                labeled(L10n.string("settings.units")) {
                    GroupedCard {
                        Picker(L10n.string("settings.weight.unit"), selection: bind(\.weightUnit)) {
                            ForEach(WeightUnit.allCases) { unit in
                                Text(unit.localizedName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(12)
                        Divider().overlay(Palette.hairline)
                        Picker(L10n.string("settings.length.unit"), selection: bind(\.lengthUnit)) {
                            ForEach(LengthUnit.allCases) { unit in
                                Text(unit.localizedName).tag(unit)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(12)
                    }
                }

                labeled(L10n.string("settings.goals")) {
                    GroupedCard {
                        optionalDoubleRow(
                            L10n.string("settings.weight.goal"),
                            placeholder: settings.weightUnit.symbol,
                            get: { settings.weightGoalKg.map { settings.weightUnit.fromKilograms($0) } },
                            set: { value in
                                var copy = settings
                                copy.weightGoalKg = value.map { settings.weightUnit.toKilograms($0) }
                                try? app.settings.save(copy)
                            }
                        )
                        Divider().overlay(Palette.hairline)
                        optionalDoubleRow(
                            L10n.string("settings.waist.goal"),
                            placeholder: settings.lengthUnit.symbol,
                            get: { settings.waistGoalCm.map { settings.lengthUnit.fromCentimeters($0) } },
                            set: { value in
                                var copy = settings
                                copy.waistGoalCm = value.map { settings.lengthUnit.toCentimeters($0) }
                                try? app.settings.save(copy)
                            }
                        )
                    }
                }

                labeled(L10n.string("settings.appearance")) {
                    GroupedCard {
                        Picker(L10n.string("settings.appearance"), selection: bind(\.theme)) {
                            ForEach(ThemeMode.allCases) { mode in
                                Text(mode.localizedName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(12)
                    }
                }

                labeled(L10n.string("health.title")) {
                    GroupedCard { healthSection }
                }

                labeled(L10n.string("settings.reminders")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.format("settings.reminders.status", permissionLabel))
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                        PrimaryButton(title: L10n.string("settings.reminders.allow")) {
                            Task { await enableReminders() }
                        }
                        Text(L10n.string("settings.reminders.hint"))
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                            .staerkWrappingText()
                    }
                }

                NavigationLink {
                    HabitsView()
                } label: {
                    settingsLink(L10n.string("settings.habits"))
                }
                .buttonStyle(.plain)

                NavigationLink {
                    ProgramEditorView()
                } label: {
                    settingsLink(L10n.string("settings.program"))
                }
                .buttonStyle(.plain)

                labeled(L10n.string("settings.backup")) {
                    GroupedCard {
                        Button(L10n.string("settings.export")) {
                            Task { await exportData() }
                        }
                        .foregroundStyle(Palette.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        Divider().overlay(Palette.hairline)
                        Button(L10n.string("settings.import")) { importing = true }
                            .foregroundStyle(Palette.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                    }
                    Text(L10n.string("settings.backup.hint"))
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                        .staerkWrappingText()
                }

                Button(L10n.string("settings.reset.onboarding")) {
                    showOnboardingReset = true
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.danger)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)

                if let status {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity)
                }

                Text(L10n.string("settings.footer"))
                    .font(.caption)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .staerkWrappingText()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .staerkKeyboard()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill").foregroundStyle(Color(hex: 0xFF3B5C))
                Text(L10n.string("health.title")).font(.headline)
                Spacer()
                Text(healthStatusLabel).font(.subheadline).foregroundStyle(Palette.muted)
            }
            Text(L10n.string("health.detail"))
                .font(.footnote)
                .foregroundStyle(Palette.muted)
                .staerkWrappingText()
            if health.showsDeniedHelp {
                Text(L10n.string("health.denied")).font(.footnote).foregroundStyle(Palette.muted)
                Button(L10n.string("health.open.settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.headline)
                .foregroundStyle(Palette.blue)
            } else {
                Button(health.didRequestAuthorization ? L10n.string("health.refresh") : L10n.string("health.allow")) {
                    Task {
                        if health.didRequestAuthorization {
                            await health.refreshToday()
                        } else {
                            await health.requestAccess()
                        }
                    }
                }
                .font(.headline)
                .foregroundStyle(Palette.blue)
            }
            if let error = health.lastError {
                Text(error).font(.caption).foregroundStyle(Palette.danger)
            }
        }
        .padding(16)
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

    private func settingsLink(_ title: String) -> some View {
        GroupedCard {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Palette.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            content()
        }
    }

    private func optionalDoubleRow(_ title: String, placeholder: String, get: @escaping () -> Double?, set: @escaping (Double?) -> Void) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: Binding(
                get: { get().map { UnitConversion.format($0) } ?? "" },
                set: { text in set(UnitConversion.parse(text)) }
            ))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(Palette.muted)
            .frame(maxWidth: 120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
