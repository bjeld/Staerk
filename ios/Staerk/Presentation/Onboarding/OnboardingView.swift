import SwiftUI

struct OnboardingView: View {
    @Environment(AppContainer.self) private var app

    @State private var step = 0
    @State private var name = ""
    @State private var weightUnit: WeightUnit = .kilogram
    @State private var lengthUnit: LengthUnit = .centimeter
    @State private var selectedHabitIDs: Set<String> = [
        HabitCatalog.creatine.id,
        HabitCatalog.water.id,
        HabitCatalog.alcoholFree.id,
        HabitCatalog.workout.id
    ]
    @State private var programID: String = ProgramCatalog.fullBody.id
    @State private var saving = false

    private var templates: [HabitTemplate] { HabitCatalog.all }
    private var programs: [ProgramBlueprint] { ProgramCatalog.all }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                TabView(selection: $step) {
                    welcome.tag(0)
                    namePage.tag(1)
                    unitsPage.tag(2)
                    habitsPage.tag(3)
                    programPage.tag(4)
                    donePage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)

                VStack(spacing: 12) {
                    PrimaryButton(title: primaryTitle, enabled: canContinue && !saving) {
                        advance()
                    }
                    if step > 0 {
                        Button(L10n.string("onboarding.back")) {
                            withAnimation { step -= 1 }
                        }
                        .font(.body.weight(.semibold))
                        .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .padding(.top, 8)
            }
            .staerkScreen()
            .staerkKeyboardImmediate()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            Capsule()
                .fill(Palette.fill)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Palette.volt)
                        .frame(width: geo.size.width * CGFloat(step + 1) / 6)
                }
        }
        .frame(height: 6)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text(L10n.string("app.name"))
                .font(Typeface.hero)
                .foregroundStyle(Palette.volt)
            Text(L10n.string("onboarding.welcome.title"))
                .font(Typeface.screen)
            Text(L10n.string("onboarding.welcome.body"))
                .font(.body)
                .foregroundStyle(Palette.muted)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var namePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            StaerkHeader(title: L10n.string("onboarding.name.title"), subtitle: L10n.string("onboarding.name.body"))
            TextField(L10n.string("onboarding.name.placeholder"), text: $name)
                .textContentType(.givenName)
                .font(Typeface.title(28))
                .padding(16)
                .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer()
        }
        .padding(24)
    }

    private var unitsPage: some View {
        VStack(alignment: .leading, spacing: 20) {
            StaerkHeader(title: L10n.string("onboarding.units.title"), subtitle: L10n.string("onboarding.units.body"))
            labeled(L10n.string("settings.weight.unit")) {
                Picker("", selection: $weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.localizedName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            labeled(L10n.string("settings.length.unit")) {
                Picker("", selection: $lengthUnit) {
                    ForEach(LengthUnit.allCases) { unit in
                        Text(unit.localizedName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }
            Spacer()
        }
        .padding(24)
    }

    private var habitsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StaerkHeader(title: L10n.string("onboarding.habits.title"), subtitle: L10n.string("onboarding.habits.body"))
                ForEach(templates) { template in
                    let on = selectedHabitIDs.contains(template.id)
                    Button {
                        Haptics.tap()
                        if on {
                            selectedHabitIDs.remove(template.id)
                        } else {
                            selectedHabitIDs.insert(template.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            SymbolCircle(symbol: template.symbol, tint: Color(hexString: template.tintHex))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L10n.string(template.nameKey))
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text(L10n.string(template.kind.localizationKey))
                                    .font(.footnote)
                                    .foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(on ? Palette.volt : Palette.muted)
                                .frame(width: 44, height: 44)
                        }
                        .padding(12)
                        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .staerkKeyboardImmediate()
    }

    private var programPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                StaerkHeader(title: L10n.string("onboarding.program.title"), subtitle: L10n.string("onboarding.program.body"))
                ForEach(programs) { program in
                    let on = programID == program.id
                    Button {
                        Haptics.tap()
                        programID = program.id
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(ProgramCatalog.localizedName(program))
                                    .font(Typeface.title(20))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(on ? Palette.volt : Palette.muted)
                            }
                            Text(ProgramCatalog.localizedNotes(program))
                                .font(.footnote)
                                .foregroundStyle(Palette.muted)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .background(Palette.elevated, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(on ? Palette.volt : Color.clear, lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    programID = ""
                } label: {
                    Text(L10n.string("onboarding.program.skip"))
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }
            }
            .padding(24)
        }
        .staerkKeyboardImmediate()
    }

    private var donePage: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Text(L10n.string("onboarding.done.title"))
                .font(Typeface.screen)
            Text(L10n.string("onboarding.done.body"))
                .foregroundStyle(Palette.muted)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var primaryTitle: String {
        step == 5 ? L10n.string("onboarding.start") : L10n.string("onboarding.next")
    }

    private var canContinue: Bool {
        switch step {
        case 1: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        case 3: return !selectedHabitIDs.isEmpty
        default: return true
        }
    }

    private func labeled<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            content()
        }
    }

    private func advance() {
        if step < 5 {
            withAnimation { step += 1 }
            return
        }
        saving = true
        Task {
            var habits: [Habit] = []
            for (index, template) in templates.enumerated() where selectedHabitIDs.contains(template.id) {
                habits.append(HabitCatalog.make(template, sortOrder: index))
            }
            let blueprint = programs.first { $0.id == programID }
            do {
                try DataSeeder.applyOnboarding(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    weightUnit: weightUnit,
                    lengthUnit: lengthUnit,
                    habits: habits,
                    blueprint: blueprint,
                    context: app.modelContext
                )
                await app.refreshReminders()
                Haptics.success()
            } catch {
                saving = false
            }
        }
    }
}
