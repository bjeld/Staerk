import Charts
import PhotosUI
import SwiftData
import SwiftUI

struct BodyProgressView: View {
    @Environment(AppContainer.self) private var app
    @Environment(HealthKitService.self) private var health
    @Query private var settingsRows: [SettingsRecord]
    @Query(sort: \MeasurementRecord.dateKey) private var measurementRows: [MeasurementRecord]
    @Query(sort: \PhotoRecord.createdAt, order: .reverse) private var photoRows: [PhotoRecord]

    @State private var weightText = ""
    @State private var waistText = ""
    @State private var date = Date()
    @State private var pickerItem: PhotosPickerItem?
    @State private var busy = false
    @State private var error: String?
    @State private var beforeID: String?
    @State private var afterID: String?
    @State private var trend: Trend = .weight

    private enum Trend: Hashable {
        case weight
        case waist
    }

    private var settings: UserSettings { settingsRows.first?.asDomain() ?? UserSettings() }
    private var measurements: [BodyMeasurement] { measurementRows.map { $0.asDomain() } }
    private var photos: [ProgressImage] { photoRows.map { $0.asDomain() } }

    private var latestWeight: Double? {
        measurements.reversed().first(where: { $0.weightKg != nil })?.weightKg
    }

    private var latestWaist: Double? {
        measurements.reversed().first(where: { $0.waistCm != nil })?.waistCm
    }

    private var before: ProgressImage? {
        photos.first(where: { $0.id == beforeID }) ?? photos.last
    }

    private var after: ProgressImage? {
        photos.first(where: { $0.id == afterID }) ?? photos.first
    }

    private var weightPoints: [ChartPoint] {
        measurements.compactMap { row in
            row.weightKg.map { ChartPoint(id: row.id, date: row.dateKey, value: settings.weightUnit.fromKilograms($0)) }
        }
    }

    private var waistPoints: [ChartPoint] {
        measurements.compactMap { row in
            row.waistCm.map { ChartPoint(id: row.id, date: row.dateKey, value: settings.lengthUnit.fromCentimeters($0)) }
        }
    }

    var body: some View {
        Screen {
            ScreenHeader(title: L10n.string("body.title"), subtitle: L10n.string("body.subtitle"))

            HStack(spacing: Space.m) {
                metricCard(
                    title: L10n.string("body.weight"),
                    latest: latestWeight.map { settings.weightUnit.fromKilograms($0) },
                    goal: settings.weightGoalKg.map { settings.weightUnit.fromKilograms($0) },
                    unit: settings.weightUnit.symbol,
                    points: weightPoints
                )
                metricCard(
                    title: L10n.string("body.waist"),
                    latest: latestWaist.map { settings.lengthUnit.fromCentimeters($0) },
                    goal: settings.waistGoalCm.map { settings.lengthUnit.fromCentimeters($0) },
                    unit: settings.lengthUnit.symbol,
                    points: waistPoints
                )
            }

            trendCard
            logCard
            photosSection
        }
        .navigationTitle(L10n.string("body.title"))
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pickerItem) { _, item in
            Task { await importPhoto(item) }
        }
    }

    // MARK: Metrics

    private func metricCard(title: String, latest: Double?, goal: Double?, unit: String, points: [ChartPoint]) -> some View {
        Card(padding: Space.l) {
            Eyebrow(text: title)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(latest.map { UnitConversion.format($0) } ?? "—")
                    .font(Typeface.metric)
                    .monospacedDigit()
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                if latest != nil {
                    Text(unit)
                        .font(Typeface.unit)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            .padding(.top, Space.xs)

            Sparkline(values: points.suffix(12).map(\.value))
                .frame(height: 28)
                .padding(.vertical, Space.s)
                .opacity(points.count > 1 ? 1 : 0)

            Text(goalLine(latest: latest, goal: goal, unit: unit))
                .font(.caption.weight(.medium))
                .foregroundStyle(Palette.inkSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private func goalLine(latest: Double?, goal: Double?, unit: String) -> String {
        guard let goal else { return L10n.string("body.nogoal") }
        if let latest {
            let remaining = abs(latest - goal)
            if remaining >= 0.05 {
                return L10n.format("body.togo", UnitConversion.format(remaining), unit)
            }
        }
        return L10n.format("body.goal", UnitConversion.format(goal), unit)
    }

    // MARK: Trend

    private var trendCard: some View {
        let points = trend == .weight ? weightPoints : waistPoints
        let goal = trend == .weight
            ? settings.weightGoalKg.map { settings.weightUnit.fromKilograms($0) }
            : settings.waistGoalCm.map { settings.lengthUnit.fromCentimeters($0) }
        return Card(padding: Space.l) {
            Picker("", selection: $trend.animation(Motion.snappy)) {
                Text(L10n.string("body.weight")).tag(Trend.weight)
                Text(L10n.string("body.waist")).tag(Trend.waist)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if points.isEmpty {
                EmptyState(
                    symbol: "chart.xyaxis.line",
                    message: L10n.string(trend == .weight ? "body.weight.empty" : "body.waist.empty")
                )
                .padding(.horizontal, -Space.l)
                .padding(.bottom, -Space.l)
            } else {
                lineChart(points, goal: goal)
                    .padding(.top, Space.l)
            }
        }
    }

    private func lineChart(_ points: [ChartPoint], goal: Double?) -> some View {
        Chart {
            ForEach(points) { point in
                AreaMark(x: .value("D", point.date), y: .value("V", point.value))
                    .foregroundStyle(
                        LinearGradient(colors: [Palette.accent.opacity(0.26), Palette.accent.opacity(0)], startPoint: .top, endPoint: .bottom)
                    )
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("D", point.date), y: .value("V", point.value))
                    .foregroundStyle(Palette.accentInk)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("D", point.date), y: .value("V", point.value))
                    .foregroundStyle(Palette.accentInk)
                    .symbolSize(point.id == points.last?.id ? 70 : 22)
            }
            if let goal {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(Palette.inkTertiary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let key = value.as(String.self) {
                        Text(Dates.prettyShort(key: key))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(Palette.hairline)
                AxisValueLabel()
            }
        }
        .frame(height: 190)
    }

    // MARK: Log

    private var logCard: some View {
        TitledSection(title: L10n.string("body.log")) {
            VStack(spacing: Space.m) {
                Card(padding: 0) {
                    DatePicker(selection: $date, displayedComponents: .date) {
                        Text(L10n.string("body.date"))
                            .font(Typeface.rowTitle)
                            .foregroundStyle(Palette.ink)
                    }
                    .padding(.horizontal, Space.l)
                    .frame(minHeight: 56)
                    RowDivider(inset: Space.l)
                    measurementField(L10n.string("body.weight"), unit: settings.weightUnit.symbol, text: $weightText)
                    RowDivider(inset: Space.l)
                    measurementField(L10n.string("body.waist"), unit: settings.lengthUnit.symbol, text: $waistText)
                }
                PrimaryButton(
                    title: L10n.string("body.save"),
                    enabled: UnitConversion.parse(weightText) != nil || UnitConversion.parse(waistText) != nil
                ) {
                    saveMeasurement()
                }
            }
        }
    }

    private func measurementField(_ title: String, unit: String, text: Binding<String>) -> some View {
        HStack(spacing: Space.s) {
            Text(title)
                .font(Typeface.rowTitle)
                .foregroundStyle(Palette.ink)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Typeface.title(22))
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: 120)
            Text(unit)
                .font(Typeface.unit)
                .foregroundStyle(Palette.inkSecondary)
                .frame(minWidth: 24, alignment: .leading)
        }
        .padding(.horizontal, Space.l)
        .frame(minHeight: 56)
    }

    // MARK: Photos

    private var photosSection: some View {
        TitledSection(title: L10n.string("body.photos"), detail: photos.isEmpty ? nil : "\(photos.count)") {
            VStack(alignment: .leading, spacing: Space.m) {
                if photos.count >= 2, let before, let after {
                    Card(padding: Space.m) {
                        HStack(spacing: Space.s) {
                            comparisonColumn(title: L10n.string("body.before"), photo: before, selection: $beforeID)
                            comparisonColumn(title: L10n.string("body.after"), photo: after, selection: $afterID)
                        }
                    }
                } else {
                    Card(padding: 0) {
                        EmptyState(symbol: "photo.on.rectangle.angled", message: L10n.string("body.photos.hint"))
                    }
                }

                if !photos.isEmpty {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Space.s), count: 3), spacing: Space.s) {
                        ForEach(photos, id: \.id) { photo in
                            photoCell(photo)
                        }
                    }
                }

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    ButtonLabel(
                        title: busy ? L10n.string("body.compressing") : L10n.string("body.addphoto"),
                        symbol: busy ? nil : "camera.fill"
                    )
                }
                .buttonStyle(.staerkSecondary)
                .disabled(busy)

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Palette.danger)
                }
            }
        }
    }

    private func photoCell(_ photo: ProgressImage) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image = UIImage(data: photo.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.inner, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button {
                    Haptics.warn()
                    try? app.photos.delete(id: photo.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(.ultraThinMaterial.opacity(0.9), in: Circle())
                        .environment(\.colorScheme, .dark)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle(scale: 0.88))
            }
    }

    private func comparisonColumn(title: String, photo: ProgressImage, selection: Binding<String?>) -> some View {
        VStack(spacing: Space.s) {
            Color.clear
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    if let image = UIImage(data: photo.imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.inner, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Pill(text: title, tint: Palette.accent)
                        .padding(Space.s)
                }
            Picker(title, selection: Binding(
                get: { selection.wrappedValue ?? photo.id },
                set: { selection.wrappedValue = $0 }
            )) {
                ForEach(photos, id: \.id) { item in
                    Text(Dates.prettyShort(key: item.dateKey)).tag(item.id)
                }
            }
            .pickerStyle(.menu)
            .tint(Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Actions

    private func saveMeasurement() {
        let weight = UnitConversion.parse(weightText).map { settings.weightUnit.toKilograms($0) }
        let waist = UnitConversion.parse(waistText).map { settings.lengthUnit.toCentimeters($0) }
        guard weight != nil || waist != nil else { return }
        let row = BodyMeasurement(dateKey: Dates.key(date), weightKg: weight, waistCm: waist)
        try? app.measurements.save(row)
        if let weight {
            Task { await health.saveBodyMass(kg: weight, at: date) }
        }
        weightText = ""
        waistText = ""
        Keyboard.dismiss()
        Haptics.success()
    }

    private func importPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        busy = true
        error = nil
        defer {
            busy = false
            pickerItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let compressed = PhotoCompressor.compress(data)
            else {
                error = L10n.string("body.photo.error")
                return
            }
            try app.photos.save(ProgressImage(dateKey: Dates.key(), imageData: compressed))
        } catch {
            self.error = L10n.string("body.photo.error")
        }
    }
}

private struct ChartPoint: Identifiable {
    var id: String
    var date: String
    var value: Double
}
