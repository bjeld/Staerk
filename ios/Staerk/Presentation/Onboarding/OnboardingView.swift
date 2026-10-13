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
                topBar
                TabView(selection: $step) {
                    welcome.tag(0)
                    namePage.tag(1)
                    unitsPage.tag(2)
                    habitsPage.tag(3)
                    programPage.tag(4)
                    donePage.tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(Motion.snappy, value: step)

                PrimaryButton(title: primaryTitle, symbol: step == 5 ? "arrow.right" : nil, enabled: canContinue && !saving) {
                    advance()
                }
                .padding(.horizontal, Space.screen)
                .padding(.bottom, Space.l)
                .padding(.top, Space.s)
            }
            .background(Palette.canvas.ignoresSafeArea())
            .staerkKeyboardImmediate()
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var topBar: some View {
        HStack(spacing: Space.m) {
            Button {
                Haptics.tap()
                withAnimation(Motion.snappy) { step -= 1 }
            } label: {
                CircleIcon(symbol: "chevron.left", size: 36)
            }
            .buttonStyle(PressableStyle(scale: 0.9))
            .opacity(step > 0 ? 1 : 0)
            .disabled(step == 0)
            .accessibilityLabel(L10n.string("onboarding.back"))

            HStack(spacing: Space.xs) {
                ForEach(0..<6, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? Palette.accent : Palette.track)
                        .frame(height: 5)
                }
            }
            .animation(Motion.snappy, value: step)
            .accessibilityElement(children: .ignore)
            .accessibilityValue("\(step + 1) / 6")

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, Space.m)
        .padding(.top, Space.s)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Spacer()
            ZStack {
                ProgressRing(progress: 0.82, tint: Palette.accent, lineWidth: 18)
                    .frame(width: 168, height: 168)
                ProgressRing(progress: 0.64, tint: Palette.accent.opacity(0.7), lineWidth: 18)
                    .frame(width: 124, height: 124)
                ProgressRing(progress: 0.46, tint: Palette.accent.opacity(0.45), lineWidth: 18)
                    .frame(width: 80, height: 80)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Space.xl)
            .accessibilityHidden(true)

            Text(L10n.string("app.name"))
                .font(Typeface.display(64))
                .foregroundStyle(Palette.ink)
            Text(L10n.string("onboarding.welcome.title"))
                .font(Typeface.cardTitle)
                .foregroundStyle(Palette.accentInk)
            Text(L10n.string("onboarding.welcome.body"))
                .font(.body)
                .foregroundStyle(Palette.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, Space.screen + Space.xs)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var namePage: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            ScreenHeader(title: L10n.string("onboarding.name.title"), subtitle: L10n.string("onboarding.name.body"))
            TextField(L10n.string("onboarding.name.placeholder"), text: $name)
                .textContentType(.givenName)
                .submitLabel(.done)
                .font(Typeface.display(34))
                .foregroundStyle(Palette.ink)
                .padding(.horizontal, Space.xl)
                .frame(minHeight: 76)
                .cardSurface(radius: Radius.inner + 4)
            Spacer()
        }
        .padding(.horizontal, Space.screen)
        .padding(.top, Space.l)
    }

    private var unitsPage: some View {
        VStack(alignment: .leading, spacing: Space.xl) {
            ScreenHeader(title: L10n.string("onboarding.units.title"), subtitle: L10n.string("onboarding.units.body"))
            Card {
                Eyebrow(text: L10n.string("settings.weight.unit"))
                Picker("", selection: $weightUnit) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.localizedName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, Space.s)

                Eyebrow(text: L10n.string("settings.length.unit"))
                    .padding(.top, Space.xl)
                Picker("", selection: $lengthUnit) {
                    ForEach(LengthUnit.allCases) { unit in
                        Text(unit.localizedName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.top, Space.s)
            }
            Spacer()
        }
        .padding(.horizontal, Space.screen)
        .padding(.top, Space.l)
    }

    private var habitsPage: some View {
        Screen(spacing: Space.xl, keyboardDismiss: .immediately) {
            ScreenHeader(title: L10n.string("onboarding.habits.title"), subtitle: L10n.string("onboarding.habits.body"))
            Card(padding: 0) {
                ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                    let on = selectedHabitIDs.contains(template.id)
                    Button {
                        Haptics.selection()
                        withAnimation(Motion.bouncy) {
                            if on {
                                selectedHabitIDs.remove(template.id)
                            } else {
                                selectedHabitIDs.insert(template.id)
                            }
                        }
                    } label: {
                        ListRow(title: L10n.string(template.nameKey), detail: L10n.string(template.kind.localizationKey)) {
                            IconBadge(symbol: template.symbol, tint: Color(hexString: template.tintHex), size: 40, style: on ? .solid : .soft)
                        } trailing: {
                            SelectionIndicator(isOn: on)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    if index < templates.count - 1 {
                        RowDivider(inset: 68)
                    }
                }
            }
        }
    }

    private var programPage: some View {
        Screen(spacing: Space.m, keyboardDismiss: .immediately) {
            ScreenHeader(title: L10n.string("onboarding.program.title"), subtitle: L10n.string("onboarding.program.body"))
                .padding(.bottom, Space.m)
            ForEach(programs) { program in
                let on = programID == program.id
                Button {
                    Haptics.selection()
                    withAnimation(Motion.snappy) { programID = program.id }
                } label: {
                    HStack(alignment: .top, spacing: Space.m) {
                        VStack(alignment: .leading, spacing: Space.xs) {
                            Text(ProgramCatalog.localizedName(program))
                                .font(Typeface.title(22))
                                .foregroundStyle(Palette.ink)
                            Text(ProgramCatalog.localizedNotes(program))
                                .font(.subheadline)
                                .foregroundStyle(Palette.inkSecondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        SelectionIndicator(isOn: on)
                    }
                    .padding(Space.card)
                    .cardSurface(radius: Radius.inner + 6)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.inner + 6, style: .continuous)
                            .strokeBorder(on ? Palette.accentInk : Color.clear, lineWidth: 2)
                    }
                }
                .buttonStyle(.pressable)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
            Button {
                Haptics.selection()
                withAnimation(Motion.snappy) { programID = "" }
            } label: {
                HStack(spacing: Space.s) {
                    SelectionIndicator(isOn: programID.isEmpty)
                    Text(L10n.string("onboarding.program.skip"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, Space.xs)
                .padding(.top, Space.s)
                .frame(minHeight: 44)
            }
            .buttonStyle(.pressable)
        }
    }

    private var donePage: some View {
        VStack(alignment: .leading, spacing: Space.l) {
            Spacer()
            HeroRing(progress: step == 5 ? 1 : 0, size: 120, lineWidth: 14) {
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .black))
                    .foregroundStyle(Palette.accentInk)
                    .symbolEffect(.bounce, value: step == 5)
            }
            .padding(.bottom, Space.l)
            .accessibilityHidden(true)
            Text(L10n.string("onboarding.done.title"))
                .font(Typeface.screenTitle)
                .foregroundStyle(Palette.ink)
            Text(L10n.string("onboarding.done.body"))
                .font(.body)
                .foregroundStyle(Palette.inkSecondary)
            Spacer()
        }
        .padding(.horizontal, Space.screen + Space.xs)
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
