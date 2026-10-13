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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(title: L10n.string("body.title"), subtitle: L10n.string("body.subtitle"))

                HStack(spacing: 12) {
                    metricCard(
                        title: L10n.string("body.weight"),
                        value: latestWeight.map { "\(UnitConversion.format(settings.weightUnit.fromKilograms($0))) \(settings.weightUnit.symbol)" } ?? "—",
                        goal: settings.weightGoalKg.map {
                            L10n.format("body.goal", UnitConversion.format(settings.weightUnit.fromKilograms($0)), settings.weightUnit.symbol)
                        } ?? L10n.string("body.nogoal")
                    )
                    metricCard(
                        title: L10n.string("body.waist"),
                        value: latestWaist.map { "\(UnitConversion.format(settings.lengthUnit.fromCentimeters($0))) \(settings.lengthUnit.symbol)" } ?? "—",
                        goal: settings.waistGoalCm.map {
                            L10n.format("body.goal", UnitConversion.format(settings.lengthUnit.fromCentimeters($0)), settings.lengthUnit.symbol)
                        } ?? L10n.string("body.nogoal")
                    )
                }

                logCard
                charts
                photosSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .staerkKeyboard()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: pickerItem) { _, item in
            Task { await importPhoto(item) }
        }
    }

    private func metricCard(title: String, value: String, goal: String) -> some View {
        GroupedCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.footnote).foregroundStyle(Palette.muted)
                Text(value).font(Typeface.display(28)).minimumScaleFactor(0.6).lineLimit(1)
                Text(goal).font(.footnote).foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: L10n.string("body.log"))
            GroupedCard {
                DatePicker(L10n.string("body.date"), selection: $date, displayedComponents: .date)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                Divider().overlay(Palette.hairline)
                HStack {
                    Text(settings.weightUnit.symbol)
                    Spacer()
                    TextField(settings.weightUnit.symbol, text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                Divider().overlay(Palette.hairline)
                HStack {
                    Text(settings.lengthUnit.symbol)
                    Spacer()
                    TextField(settings.lengthUnit.symbol, text: $waistText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            PrimaryButton(title: L10n.string("body.save")) {
                saveMeasurement()
            }
        }
    }

    private var charts: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupedCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.string("body.weight")).font(Typeface.card)
                    let points = measurements.compactMap { row -> ChartPoint? in
                        guard let kg = row.weightKg else { return nil }
                        return ChartPoint(id: row.id, date: row.dateKey, value: settings.weightUnit.fromKilograms(kg))
                    }
                    if points.isEmpty {
                        Text(L10n.string("body.weight.empty")).foregroundStyle(Palette.muted)
                    } else {
                        lineChart(points)
                    }
                }
                .padding(16)
            }
            GroupedCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.string("body.waist")).font(Typeface.card)
                    let points = measurements.compactMap { row -> ChartPoint? in
                        guard let cm = row.waistCm else { return nil }
                        return ChartPoint(id: row.id, date: row.dateKey, value: settings.lengthUnit.fromCentimeters(cm))
                    }
                    if points.isEmpty {
                        Text(L10n.string("body.waist.empty")).foregroundStyle(Palette.muted)
                    } else {
                        lineChart(points)
                    }
                }
                .padding(16)
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: L10n.string("body.photos"))
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text(busy ? L10n.string("body.compressing") : L10n.string("body.addphoto"))
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Palette.voltForeground)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .background(Palette.volt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(busy)

            if let error {
                Text(error).font(.footnote).foregroundStyle(Palette.danger)
            }

            if photos.count >= 2, let before, let after {
                GroupedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.string("body.beforeafter")).font(Typeface.card)
                        HStack(spacing: 8) {
                            comparisonColumn(title: L10n.string("body.before"), photo: before, selection: $beforeID)
                            comparisonColumn(title: L10n.string("body.after"), photo: after, selection: $afterID)
                        }
                    }
                    .padding(16)
                }
            } else {
                Text(L10n.string("body.photos.hint")).font(.subheadline).foregroundStyle(Palette.muted)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(photos, id: \.id) { photo in
                    ZStack(alignment: .topTrailing) {
                        if let image = UIImage(data: photo.imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        Button {
                            try? app.photos.delete(id: photo.id)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(.black.opacity(0.55), in: Circle())
                        }
                        .padding(6)
                        .frame(width: 44, height: 44, alignment: .topTrailing)
                    }
                }
            }
        }
    }

    private func comparisonColumn(title: String, photo: ProgressImage, selection: Binding<String?>) -> some View {
        VStack(spacing: 8) {
            if let image = UIImage(data: photo.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(3 / 4, contentMode: .fill)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        }
        .frame(maxWidth: .infinity)
    }

    private func lineChart(_ points: [ChartPoint]) -> some View {
        Chart(points) { point in
            LineMark(x: .value("D", point.date), y: .value("V", point.value))
                .foregroundStyle(Palette.volt)
                .interpolationMethod(.catmullRom)
            PointMark(x: .value("D", point.date), y: .value("V", point.value))
                .foregroundStyle(Palette.volt)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let key = value.as(String.self) {
                        Text(Dates.prettyShort(key: key))
                    }
                }
            }
        }
        .frame(height: 180)
    }

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
