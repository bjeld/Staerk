import SwiftUI

// MARK: - Completion

/// The circle you tap to complete something. Fills with the tint and bounces on completion.
struct CompletionCheck: View {
    var isOn: Bool
    var tint: Color = Palette.accent
    var size: CGFloat = 30
    var label: String?

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isOn ? Color.clear : Palette.inkTertiary, lineWidth: 2)
            Circle()
                .fill(tint)
                .scaleEffect(isOn ? 1 : 0.2)
                .opacity(isOn ? 1 : 0)
            if let label, !isOn {
                Text(label)
                    .font(.system(size: size * 0.44, weight: .bold).monospacedDigit())
                    .foregroundStyle(Palette.inkSecondary)
            }
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.46, weight: .heavy))
                .foregroundStyle(tint.onTint)
                .scaleEffect(isOn ? 1 : 0.4)
                .opacity(isOn ? 1 : 0)
                .symbolEffect(.bounce, value: isOn)
        }
        .frame(width: size, height: size)
        .animation(Motion.bouncy, value: isOn)
        .accessibilityHidden(true)
    }
}

// MARK: - Progress

struct LinearProgress: View {
    var progress: Double
    var tint: Color = Palette.accent
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(Palette.track)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(tint)
                        .frame(width: max(progress > 0 ? height : 0, geo.size.width * clamped))
                }
        }
        .frame(height: height)
        .animation(Motion.fill, value: clamped)
        .accessibilityHidden(true)
    }

    private var clamped: Double { min(1, max(0, progress)) }
}

/// Discrete progress for small goals (glasses of water); falls back to a bar for large ones.
struct SegmentedProgress: View {
    var value: Int
    var goal: Int
    var tint: Color

    var body: some View {
        if goal <= 12 {
            HStack(spacing: 3) {
                ForEach(0..<max(1, goal), id: \.self) { index in
                    Capsule()
                        .fill(index < value ? tint : Palette.track)
                        .frame(height: 6)
                }
            }
            .animation(Motion.snappy, value: value)
            .accessibilityHidden(true)
        } else {
            LinearProgress(progress: goal > 0 ? Double(value) / Double(goal) : 0, tint: tint)
        }
    }
}

// MARK: - Counter

struct CounterControl: View {
    var value: Int
    var goal: Int
    var onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            stepButton(symbol: "minus", label: "−", enabled: value > 0) {
                onChange(max(0, value - 1))
            }
            Text("\(value)")
                .font(Typeface.title(20))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(value)))
                .frame(minWidth: 26)
                .foregroundStyle(Palette.ink)
            stepButton(symbol: "plus", label: "+", enabled: true) {
                onChange(value + 1)
                if value + 1 == goal { Haptics.success() }
            }
        }
        .background(Palette.surfaceInsetStrong, in: Capsule())
        .animation(Motion.snappy, value: value)
    }

    private func stepButton(symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .frame(width: 42, height: 42)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.88))
        .foregroundStyle(Palette.ink)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(Text(verbatim: label))
    }
}

// MARK: - Value stepper

/// Compact −/value/+ control for logging sets. The value is directly editable.
struct ValueStepper: View {
    var label: String
    @Binding var value: Double
    var step: Double
    var minValue: Double = 0
    var integer: Bool = false

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 0) {
            bumpButton("minus", delta: -step)
            TextField("", text: Binding(
                get: { integer ? String(Int(value.rounded())) : UnitConversion.format(value) },
                set: { text in
                    if let parsed = UnitConversion.parse(text) {
                        value = max(minValue, parsed)
                    }
                }
            ))
            .keyboardType(integer ? .numberPad : .decimalPad)
            .multilineTextAlignment(.center)
            .font(Typeface.title(20))
            .monospacedDigit()
            .foregroundStyle(Palette.ink)
            .focused($focused)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(label)
            .onChange(of: focused) { _, isFocused in
                if !isFocused { Keyboard.dismiss() }
            }
            bumpButton("plus", delta: step)
        }
        .frame(height: 46)
        .background(Palette.surfaceInset, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(focused ? Palette.accentInk : Color.clear, lineWidth: 1.5)
        }
        .animation(Motion.snappy, value: focused)
    }

    private func bumpButton(_ symbol: String, delta: Double) -> some View {
        Button {
            Haptics.tap()
            value = max(minValue, (value + delta).rounded(toPlaces: integer ? 0 : 2))
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.inkSecondary)
                .frame(width: 36, height: 46)
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle(scale: 0.85))
        .accessibilityLabel("\(label) \(delta < 0 ? "−" : "+")")
    }
}

// MARK: - Weekday picker

struct WeekdayPicker: View {
    @Binding var selection: WeekdaySet

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(WeekdaySet.ordered.enumerated()), id: \.offset) { index, day in
                let on = selection.contains(day)
                Button {
                    Haptics.selection()
                    selection.formSymmetricDifference(day)
                    if selection.isEmpty {
                        selection = day
                    }
                } label: {
                    Text(String(String(localized: String.LocalizationValue(WeekdayLabel.shortKeys[index])).prefix(2)))
                        .font(.footnote.weight(.bold))
                        .textCase(.uppercase)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(on ? Palette.accent : Palette.surfaceInsetStrong, in: Circle())
                        .foregroundStyle(on ? Palette.onAccent : Palette.inkSecondary)
                }
                .buttonStyle(PressableStyle(scale: 0.9))
                .accessibilityLabel(L10n.string(WeekdayLabel.longKeys[index]))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .animation(Motion.snappy, value: selection)
    }
}

/// Radio-style indicator for single and multi select lists.
struct SelectionIndicator: View {
    var isOn: Bool

    var body: some View {
        CompletionCheck(isOn: isOn, tint: Palette.accent, size: 26)
    }
}
