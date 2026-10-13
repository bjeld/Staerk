import SwiftUI

struct SectionLabel: View {
    var text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Palette.muted)
            .tracking(-0.2)
            .padding(.horizontal, 4)
    }
}

struct StaerkHeader: View {
    var title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.8)
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}

struct WeekStripView: View {
    var today: String
    var marks: [String: Bool]

    var body: some View {
        let keys = Dates.weekKeys()
        HStack(spacing: 0) {
            ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                let active = key == today
                let marked = marks[key] ?? false
                let day = Dates.parse(key)
                VStack(spacing: 6) {
                    Text(WeekdayLabel.short[index])
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Palette.muted)
                    Text("\(Dates.calendar.component(.day, from: day))")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(active ? Color.white : Color.primary)
                        .frame(width: 34, height: 34)
                        .background(active ? Palette.pink : Color.clear, in: Circle())
                    Circle()
                        .fill(marked ? (active ? Color.white : Palette.accent) : Color.clear)
                        .frame(width: 5, height: 5)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
    }
}

struct HabitToggleRow: View {
    var title: String
    var hint: String
    var tint: Color
    var symbol: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(tint)
                        .frame(width: 30, height: 30)
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                    Text(hint)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(tint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct WaterCounterRow: View {
    @Binding var value: Int
    var goal: Int

    private var percent: Int {
        guard goal > 0 else { return 0 }
        return Int((Double(value) / Double(goal) * 100).rounded())
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Palette.cyan)
                    .frame(width: 30, height: 30)
                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Vand")
                    .font(.system(size: 17))
                Text("\(value) / \(goal) glas · \(percent)%")
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            HStack(spacing: 0) {
                Button {
                    value = max(0, value - 1)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 36, height: 36)
                }
                Text("\(value)")
                    .font(.system(size: 18, weight: .semibold).monospacedDigit())
                    .frame(minWidth: 24)
                Button {
                    value += 1
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                }
            }
            .foregroundStyle(.primary)
            .background(Palette.fill, in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct NumberStepper: View {
    var label: String
    @Binding var value: Double
    var step: Double
    var minValue: Double = 0
    var integer: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Palette.muted)
            HStack(spacing: 0) {
                Button {
                    bump(-step)
                } label: {
                    Text("−")
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                }
                TextField("", text: Binding(
                    get: {
                        integer ? String(Int(value.rounded())) : value.staerkWeight
                    },
                    set: { text in
                        let parsed = Double(text.replacingOccurrences(of: ",", with: "."))
                        if let parsed {
                            value = max(minValue, parsed)
                        }
                    }
                ))
                    .keyboardType(integer ? .numberPad : .decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 22, weight: .semibold).monospacedDigit())
                    .frame(maxWidth: .infinity)
                Button {
                    bump(step)
                } label: {
                    Text("+")
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                }
            }
            .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    private func bump(_ delta: Double) {
        let next = max(minValue, (value + delta).rounded(toPlaces: integer ? 0 : 2))
        value = next
    }
}

struct PrimaryButton: View {
    var title: String
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.accentForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Palette.accent.opacity(enabled ? 1 : 0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(!enabled)
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Palette.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct DangerButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Palette.danger)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .buttonStyle(.plain)
    }
}

struct ChevronRow<Destination: View>: View {
    var title: String
    var subtitle: String?
    var destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17))
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Palette.muted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
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

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
