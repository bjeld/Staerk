import SwiftData
import SwiftUI
import UIKit
import UserNotifications
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthKitService.self) private var health
    @Query private var settingsRows: [AppSettings]
    @State private var status: String?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var exporting = false
    @State private var importing = false
    @State private var exportDocument = JSONFileDocument(text: "{}")
    @State private var confirmImport = false
    @State private var pendingImport: String?
    @State private var reminderDate = Self.date(from: "06:15")

    private var settings: AppSettings {
        settingsRows.first ?? StaerkStore.settings(in: context)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(title: "Indstillinger", subtitle: "Alt ligger lokalt. Ingen konto, ingen sky.")

                labeled("Profil") {
                    GroupedCard {
                        HStack {
                            Text("Navn")
                                .font(.system(size: 17))
                            Spacer()
                            TextField("Navn", text: bindSettings(\.displayName))
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(Palette.muted)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }

                labeled("Mål") {
                    GroupedCard {
                        stepperRow("Glas vand", value: bindSettings(\.waterGoal), range: 1...20)
                        Divider().overlay(Palette.hairline).padding(.leading, 16)
                        optionalDoubleRow("Vægtmål", placeholder: "kg", value: bindOptional(\.weightGoalKg))
                        Divider().overlay(Palette.hairline).padding(.leading, 16)
                        optionalDoubleRow("Taljemål", placeholder: "cm", value: bindOptional(\.waistGoalCm))
                    }
                }

                labeled("Udseende") {
                    GroupedCard {
                        Picker("Udseende", selection: bindSettings(\.themeRaw)) {
                            Text("Lys").tag(ThemeMode.light.rawValue)
                            Text("Mørk").tag(ThemeMode.dark.rawValue)
                            Text("System").tag(ThemeMode.system.rawValue)
                        }
                        .pickerStyle(.segmented)
                        .padding(12)
                    }
                }

                labeled("Apple Health") {
                    GroupedCard {
                        healthSection
                    }
                }

                labeled("Påmindelser") {
                    GroupedCard {
                        DatePicker("Tidspunkt", selection: $reminderDate, displayedComponents: .hourAndMinute)
                            .environment(\.locale, Locale(identifier: "da_DK"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .onChange(of: reminderDate) { _, newValue in
                                settings.reminderTime = Self.hhmm(from: newValue)
                                try? context.save()
                                Task { await NotificationService.reschedule(settings: settings) }
                            }
                        Divider().overlay(Palette.hairline)
                        toggleRow("Kreatin", isOn: bindSettings(\.creatineReminder))
                        Divider().overlay(Palette.hairline)
                        toggleRow("Træning man/ons/fre", isOn: bindSettings(\.workoutReminder))
                    }
                    Text("Lokale påmindelser kan vække iPhone, også når appen er lukket. Status: \(permissionLabel).")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                        .padding(.horizontal, 4)
                    PrimaryButton(title: "Tillad notifikationer") {
                        Task { await enableReminders() }
                    }
                }

                labeled("Backup") {
                    GroupedCard {
                        Button("Eksporter data") {
                            Task { await exportData() }
                        }
                        .foregroundStyle(Palette.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        Divider().overlay(Palette.hairline)
                        Button("Importer data") {
                            importing = true
                        }
                        .foregroundStyle(Palette.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    Text("JSON med vaner, træning, mål og fotos. Import overskriver alt på enheden.")
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                        .padding(.horizontal, 4)
                }

                if let status {
                    Text(status)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity)
                }

                Text("Styrke · vaner og træning forlader aldrig din iPhone. Apple Health deles kun, hvis du giver lov.")
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            reminderDate = Self.date(from: settings.reminderTime)
            notificationStatus = await NotificationService.currentStatus()
        }
        .fileExporter(
            isPresented: $exporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "staerk-backup-\(Dates.key())"
        ) { result in
            if case .success = result {
                status = "Backup hentet. Gem filen et sted, du kan finde igen."
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else {
                    status = "Filen kunne ikke læses. Tjek at det er en Styrke-backup."
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    pendingImport = text
                    confirmImport = true
                } else {
                    status = "Filen kunne ikke læses. Tjek at det er en Styrke-backup."
                }
            case .failure:
                status = "Filen kunne ikke læses. Tjek at det er en Styrke-backup."
            }
        }
        .confirmationDialog(
            "Import overskriver al data på denne enhed. Fortsæt?",
            isPresented: $confirmImport,
            titleVisibility: .visible
        ) {
            Button("Importér", role: .destructive) {
                if let pendingImport {
                    do {
                        try BackupService.importJSON(pendingImport, into: context)
                        status = "Backup er indlæst."
                    } catch {
                        status = "Filen kunne ikke læses. Tjek at det er en Styrke-backup."
                    }
                }
            }
            Button("Annuller", role: .cancel) {}
        }
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Palette.pink)
                Text("Apple Health")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text(healthStatusLabel)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.muted)
            }
            Text("Styrke læser skridt, gang/løb, aktiv energi, træningspas (inkl. golf) og kropsvægt. Styrkepas og vægt kan skrives tilbage til Sundhed.")
                .font(.system(size: 13))
                .foregroundStyle(Palette.muted)

            if health.didRequestAuthorization, health.today.hasActivity {
                Text("I dag: \(stepsText) skridt · \(energyText) kcal")
                    .font(.system(size: 15).monospacedDigit())
            }

            if health.showsDeniedHelp {
                Text("Adgang er slået fra. Åbn Indstillinger → Sundhed → Dataadgang og vælg Styrke.")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
                Button("Åbn Indstillinger") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.blue)
            } else {
                Button(health.didRequestAuthorization ? "Opdater Health-data" : "Tillad adgang") {
                    Task {
                        if health.didRequestAuthorization {
                            await health.refreshToday()
                        } else {
                            await health.requestAccess()
                        }
                    }
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.blue)
            }

            if let error = health.lastError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(Palette.danger)
            }
        }
        .padding(16)
    }

    private var healthStatusLabel: String {
        if !health.isAvailable { return "Ikke tilgængelig" }
        if !health.didRequestAuthorization { return "Ikke sat op" }
        switch health.authorizationStatus {
        case .sharingAuthorized: return "Tilsluttet"
        case .sharingDenied: return "Afvist"
        default: return "Delvis"
        }
    }

    private var stepsText: String {
        guard let steps = health.today.steps else { return "—" }
        return Int(steps.rounded()).formatted(.number)
    }

    private var energyText: String {
        guard let kcal = health.today.activeEnergyKcal else { return "—" }
        return "\(Int(kcal.rounded()))"
    }

    private var permissionLabel: String {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return "tilladt"
        case .denied: return "afvist"
        default: return "ikke sat"
        }
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            content()
        }
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .tint(Palette.accent)
    }

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        Stepper(value: value, in: range) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue)")
                    .foregroundStyle(Palette.muted)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func optionalDoubleRow(_ title: String, placeholder: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(placeholder, text: Binding(
                get: { value.wrappedValue.map { $0.staerkWeight } ?? "" },
                set: { text in
                    let trimmed = text.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
                    value.wrappedValue = trimmed.isEmpty ? nil : Double(trimmed)
                }
            ))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .foregroundStyle(Palette.muted)
            .frame(maxWidth: 120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func bindSettings<T>(_ keyPath: ReferenceWritableKeyPath<AppSettings, T>) -> Binding<T> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                let row = StaerkStore.settings(in: context)
                row[keyPath: keyPath] = newValue
                try? context.save()
            }
        )
    }

    private func bindOptional(_ keyPath: ReferenceWritableKeyPath<AppSettings, Double?>) -> Binding<Double?> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { newValue in
                let row = StaerkStore.settings(in: context)
                row[keyPath: keyPath] = newValue
                try? context.save()
            }
        )
    }

    private func enableReminders() async {
        let ok = await NotificationService.requestAuthorization()
        notificationStatus = await NotificationService.currentStatus()
        if ok {
            settings.creatineReminder = true
            try? context.save()
            await NotificationService.reschedule(settings: settings)
            status = "Påmindelser er slået til."
        } else {
            status = "Notifikationer blev ikke tilladt. Du kan stadig bruge vanerne uden dem."
        }
    }

    private func exportData() async {
        status = "Bygger backup…"
        do {
            let json = try BackupService.exportJSON(from: context)
            exportDocument = JSONFileDocument(text: json)
            exporting = true
        } catch {
            status = "Filen kunne ikke læses. Tjek at det er en Styrke-backup."
        }
    }

    private static func date(from hhmm: String) -> Date {
        let comps = Dates.reminderComponents(hhmm)
        return Dates.calendar.date(from: DateComponents(
            year: 2020,
            month: 1,
            day: 1,
            hour: comps.hour,
            minute: comps.minute
        )) ?? Date()
    }

    private static func hhmm(from date: Date) -> String {
        let hour = Dates.calendar.component(.hour, from: date)
        let minute = Dates.calendar.component(.minute, from: date)
        return String(format: "%02d:%02d", hour, minute)
    }
}
