import SwiftUI

struct SectionLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Palette.muted)
            .textCase(.uppercase)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

struct StaerkHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Typeface.screen)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }
}

struct WeekStripView: View {
    var today: String
    var marks: [String: Double]

    var body: some View {
        let keys = Dates.weekKeys()
        HStack(spacing: 0) {
            ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                let active = key == today
                let ratio = marks[key] ?? 0
                let day = Dates.parse(key)
                VStack(spacing: 8) {
                    Text(String(localized: String.LocalizationValue(WeekdayLabel.shortKeys[index])))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Palette.muted)
                    Text("\(Dates.calendar.component(.day, from: day))")
                        .font(Typeface.title(17))
                        .foregroundStyle(active ? Palette.voltForeground : Color.primary)
                        .frame(width: 36, height: 36)
                        .background(active ? Palette.volt : Color.clear, in: Circle())
                    Circle()
                        .fill(ratio >= 1 ? (active ? Color.primary : Palette.volt) : Color.clear)
                        .frame(width: 6, height: 6)
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Dates.prettyLong(key: key))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
    }
}

struct GroupedCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .staerkCard()
    }
}

struct PrimaryButton: View {
    var title: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(Palette.voltForeground)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Palette.volt.opacity(enabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

struct SecondaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .background(Palette.fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct DangerButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.warn()
            action()
        } label: {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Palette.danger)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
        }
        .buttonStyle(.plain)
    }
}

struct HabitToggleRow: View {
    var title: String
    var hint: String
    var tint: Color
    var symbol: String
    var isOn: Bool
    var action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                action()
            }
            if !isOn { Haptics.success() }
        }) {
            HStack(spacing: 14) {
                icon
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    if !hint.isEmpty {
                        Text(hint)
                            .font(.footnote)
                            .foregroundStyle(Palette.muted)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(isOn ? tint : Palette.muted)
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOn ? String(localized: "a11y.done") : String(localized: "a11y.todo"))
    }

    private var icon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(tint)
                .frame(width: 40, height: 40)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black.opacity(0.85))
        }
    }
}

struct CounterHabitRow: View {
    var title: String
    var hint: String
    var tint: Color
    var symbol: String
    var value: Int
    var goal: Int
    var onChange: (Int) -> Void

    private var percent: Int {
        guard goal > 0 else { return 0 }
        return Int((Double(value) / Double(goal) * 100).rounded())
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint)
                    .frame(width: 40, height: 40)
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black.opacity(0.85))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text("\(value) / \(goal) · \(percent)%")
                    .font(.footnote)
                    .foregroundStyle(Palette.muted)
                if !hint.isEmpty {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(Palette.muted)
                }
            }
            Spacer()
            HStack(spacing: 0) {
                Button {
                    Haptics.tap()
                    onChange(max(0, value - 1))
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                }
                Text("\(value)")
                    .font(Typeface.title(20))
                    .monospacedDigit()
                    .frame(minWidth: 28)
                Button {
                    Haptics.tap()
                    onChange(value + 1)
                    if value + 1 >= goal { Haptics.success() }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                }
            }
            .foregroundStyle(.primary)
            .background(Palette.fill, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct NumberStepper: View {
    var label: String
    @Binding var value: Double
    var step: Double
    var minValue: Double = 0
    var integer: Bool = false
    var unit: String = ""

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Palette.muted)
            HStack(spacing: 0) {
                Button {
                    Haptics.tap()
                    bump(-step)
                } label: {
                    Text("−")
                        .font(.title2)
                        .frame(width: 48, height: 52)
                }
                TextField("", text: Binding(
                    get: {
                        integer ? String(Int(value.rounded())) : UnitConversion.format(value)
                    },
                    set: { text in
                        if let parsed = UnitConversion.parse(text) {
                            value = max(minValue, parsed)
                        }
                    }
                ))
                .keyboardType(integer ? .numberPad : .decimalPad)
                .multilineTextAlignment(.center)
                .font(Typeface.title(24))
                .monospacedDigit()
                .focused($focused)
                .frame(maxWidth: .infinity)
                .onChange(of: focused) { _, isFocused in
                    if !isFocused { Keyboard.dismiss() }
                }
                Button {
                    Haptics.tap()
                    bump(step)
                } label: {
                    Text("+")
                        .font(.title2)
                        .frame(width: 48, height: 52)
                }
            }
            .background(Palette.fill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(Palette.muted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func bump(_ delta: Double) {
        let next = max(minValue, (value + delta).rounded(toPlaces: integer ? 0 : 2))
        value = next
    }
}

struct WeekdayPicker: View {
    @Binding var selection: WeekdaySet

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(WeekdaySet.ordered.enumerated()), id: \.offset) { index, day in
                let on = selection.contains(day)
                Button {
                    Haptics.tap()
                    selection.formSymmetricDifference(day)
                    if selection.isEmpty {
                        selection = day
                    }
                } label: {
                    Text(String(localized: String.LocalizationValue(WeekdayLabel.shortKeys[index])))
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(on ? Palette.volt : Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(on ? Palette.voltForeground : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct SymbolCircle: View {
    var symbol: String
    var tint: Color
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(tint)
                .frame(width: size, height: size)
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(.black.opacity(0.85))
        }
    }
}
