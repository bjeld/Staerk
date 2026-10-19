import SwiftUI

// MARK: - Week strip

/// Monday–Sunday with a mini ring per day showing how complete that day was.
struct WeekStrip: View {
    var today: String
    var marks: [String: Double]

    var body: some View {
        let keys = Dates.weekKeys()
        HStack(spacing: 0) {
            ForEach(Array(keys.enumerated()), id: \.offset) { index, key in
                let isToday = key == today
                let isFuture = key > today
                let ratio = marks[key] ?? 0
                VStack(spacing: Space.s) {
                    Text(String(L10n.string(WeekdayLabel.shortKeys[index]).prefix(1)).uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isToday ? Palette.accentInk : Palette.inkTertiary)
                    ZStack {
                        if isToday {
                            Circle().fill(Palette.accentSoft)
                        }
                        ProgressRing(progress: isFuture ? 0 : ratio, lineWidth: 3.5)
                        Text("\(Dates.calendar.component(.day, from: Dates.parse(key)))")
                            .font(.system(size: 13, weight: .bold).monospacedDigit())
                            .foregroundStyle(isFuture ? Palette.inkTertiary : Palette.ink)
                    }
                    .frame(width: 38, height: 38)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Dates.prettyLong(key: key))
                .accessibilityValue("\(Int((ratio * 100).rounded()))%")
            }
        }
    }
}

// MARK: - Metric tile

struct MetricTile: View {
    var symbol: String
    var tint: Color
    var value: String
    var unit: String?
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: Space.s) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint.legible)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.16), in: Circle())
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(Typeface.metricSmall)
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Palette.inkSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(Space.m + 2)
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .cardSurface(radius: Radius.inner + 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue([value, unit].compactMap { $0 }.joined(separator: " "))
    }
}

// MARK: - Bars

struct WeekBars: View {
    var values: [Double]
    var todayIndex: Int?
    var height: CGFloat = 96

    var body: some View {
        HStack(alignment: .bottom, spacing: Space.s + 2) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                let isToday = index == todayIndex
                let clamped = min(1, max(0, value))
                VStack(spacing: Space.s) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Palette.track)
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Palette.accent)
                            .frame(height: clamped > 0 ? max(10, height * clamped) : 0)
                    }
                    .frame(height: height)
                    Text(String(L10n.string(WeekdayLabel.shortKeys[index]).prefix(1)).uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isToday ? Palette.accentInk : Palette.inkTertiary)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.string(WeekdayLabel.longKeys[index]))
                .accessibilityValue("\(Int((clamped * 100).rounded()))%")
            }
        }
        .animation(Motion.fill, value: values)
    }
}

struct BarListItem: Identifiable {
    var id: String
    var label: String
    var value: Int
}

/// Horizontal bars with labels and values — volume per muscle and similar breakdowns.
struct BarList: View {
    var items: [BarListItem]
    var tint: Color = Palette.accent

    var body: some View {
        let peak = max(1, items.map(\.value).max() ?? 1)
        VStack(spacing: Space.m) {
            ForEach(items) { item in
                HStack(spacing: Space.m) {
                    Text(item.label)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(item.value > 0 ? Palette.ink : Palette.inkTertiary)
                        .frame(width: 84, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    GeometryReader { geo in
                        Capsule()
                            .fill(Palette.track)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(tint)
                                    .frame(width: item.value > 0 ? max(10, geo.size.width * CGFloat(item.value) / CGFloat(peak)) : 0)
                            }
                    }
                    .frame(height: 10)
                    Text("\(item.value)")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(item.value > 0 ? Palette.ink : Palette.inkTertiary)
                        .frame(minWidth: 22, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .animation(Motion.fill, value: items.map(\.value))
    }
}

// MARK: - Sparkline

struct Sparkline: View {
    var values: [Double]
    var tint: Color = Palette.accentInk

    var body: some View {
        GeometryReader { geo in
            let points = normalized(in: geo.size)
            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.addLines(points)
                    }
                    .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
                if let last = points.last {
                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                        .position(last)
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func normalized(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let low = values.min() ?? 0
        let high = values.max() ?? 1
        let span = max(high - low, 0.0001)
        let step = values.count > 1 ? size.width / CGFloat(values.count - 1) : 0
        return values.enumerated().map { index, value in
            let x = values.count > 1 ? CGFloat(index) * step : size.width
            let y = size.height - CGFloat((value - low) / span) * (size.height - 6) - 3
            return CGPoint(x: x, y: values.count > 1 ? y : size.height / 2)
        }
    }
}
