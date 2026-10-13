import Charts
import PhotosUI
import SwiftData
import SwiftUI

struct BodyProgressView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthKitService.self) private var health
    @Query private var settingsRows: [AppSettings]
    @Query(sort: \Measurement.dateKey) private var measurements: [Measurement]
    @Query(sort: \ProgressPhoto.createdAt, order: .reverse) private var photos: [ProgressPhoto]

    @State private var weightText = ""
    @State private var waistText = ""
    @State private var date = Date()
    @State private var pickerItem: PhotosPickerItem?
    @State private var busy = false
    @State private var error: String?
    @State private var beforeID: String?
    @State private var afterID: String?

    private var settings: AppSettings { settingsRows.first ?? AppSettings.makeDefault() }

    private var latestWeight: Double? {
        measurements.reversed().first(where: { $0.weightKg != nil })?.weightKg
    }

    private var latestWaist: Double? {
        measurements.reversed().first(where: { $0.waistCm != nil })?.waistCm
    }

    private var before: ProgressPhoto? {
        photos.first(where: { $0.id == beforeID }) ?? photos.last
    }

    private var after: ProgressPhoto? {
        photos.first(where: { $0.id == afterID }) ?? photos.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StaerkHeader(
                    title: "Fremskridt",
                    subtitle: "Vægt, talje og fotos bor kun på denne enhed."
                )

                HStack(spacing: 12) {
                    metricCard(
                        title: "Vægt",
                        value: latestWeight.map { "\($0.staerkWeight) kg" } ?? "—",
                        goal: settings.weightGoalKg.map { "mål \($0.staerkWeight) kg" } ?? "intet mål sat"
                    )
                    metricCard(
                        title: "Talje",
                        value: latestWaist.map { "\($0.staerkWeight) cm" } ?? "—",
                        goal: settings.waistGoalCm.map { "mål \($0.staerkWeight) cm" } ?? "intet mål sat"
                    )
                }

                logCard
                charts
                photosSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
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
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
                Text(value)
                    .font(.system(size: 28, weight: .bold).monospacedDigit())
                Text(goal)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Log mål")
            GroupedCard {
                DatePicker("Dato", selection: $date, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "da_DK"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                Divider().overlay(Palette.hairline)
                HStack {
                    Text("Kg")
                    Spacer()
                    TextField("kg", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                Divider().overlay(Palette.hairline)
                HStack {
                    Text("Talje cm")
                    Spacer()
                    TextField("cm", text: $waistText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(Palette.muted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            PrimaryButton(title: "Gem måling") {
                saveMeasurement()
            }
        }
    }

    private var charts: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupedCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vægt")
                        .font(.system(size: 20, weight: .semibold))
                    let points = measurements.compactMap { row -> ChartPoint? in
                        guard let kg = row.weightKg else { return nil }
                        return ChartPoint(id: row.id, date: row.dateKey, value: kg)
                    }
                    if points.isEmpty {
                        Text("Log din første vægt, så kommer kurven.")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.muted)
                    } else {
                        lineChart(points, color: Palette.pink)
                    }
                }
                .padding(16)
            }

            GroupedCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Talje")
                        .font(.system(size: 20, weight: .semibold))
                    let points = measurements.compactMap { row -> ChartPoint? in
                        guard let cm = row.waistCm else { return nil }
                        return ChartPoint(id: row.id, date: row.dateKey, value: cm)
                    }
                    if points.isEmpty {
                        Text("Taljemål er ofte et ærligere spejl end vægten.")
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.muted)
                    } else {
                        lineChart(points, color: Palette.cyan)
                    }
                }
                .padding(16)
            }
        }
    }

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Fremskridtsfotos")
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text(busy ? "Komprimerer…" : "Tilføj foto")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.accentForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(busy)

            if let error {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.danger)
            }

            if photos.count >= 2, let before, let after {
                GroupedCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Før / efter")
                            .font(.system(size: 20, weight: .semibold))
                        HStack(spacing: 8) {
                            comparisonColumn(title: "Før", photo: before, selection: $beforeID)
                            comparisonColumn(title: "Efter", photo: after, selection: $afterID)
                        }
                    }
                    .padding(16)
                }
            } else {
                Text("Tilføj mindst to fotos for at sammenligne side om side.")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.muted)
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
                            context.delete(photo)
                            try? context.save()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(.black.opacity(0.55), in: Circle())
                        }
                        .padding(6)
                    }
                    .accessibilityLabel("Fremskridt \(photo.dateKey)")
                }
            }
        }
    }

    private func comparisonColumn(title: String, photo: ProgressPhoto, selection: Binding<String?>) -> some View {
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

    private func lineChart(_ points: [ChartPoint], color: Color) -> some View {
        Chart(points) { point in
            LineMark(
                x: .value("Dato", point.date),
                y: .value("Værdi", point.value)
            )
            .foregroundStyle(color)
            .interpolationMethod(.catmullRom)
            PointMark(
                x: .value("Dato", point.date),
                y: .value("Værdi", point.value)
            )
            .foregroundStyle(color)
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
        let weight = Double(weightText.replacingOccurrences(of: ",", with: "."))
        let waist = Double(waistText.replacingOccurrences(of: ",", with: "."))
        guard weight != nil || waist != nil else { return }
        let row = Measurement(dateKey: Dates.key(date), weightKg: weight, waistCm: waist)
        context.insert(row)
        try? context.save()
        if let weight {
            Task { await health.saveBodyMass(kg: weight, at: date) }
        }
        weightText = ""
        waistText = ""
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
                error = "Billedet kunne ikke gemmes. Prøv et andet foto."
                return
            }
            let photo = ProgressPhoto(dateKey: Dates.key(), imageData: compressed)
            context.insert(photo)
            try context.save()
        } catch {
            self.error = "Billedet kunne ikke gemmes. Prøv et andet foto."
        }
    }
}

private struct ChartPoint: Identifiable {
    var id: String
    var date: String
    var value: Double
}
