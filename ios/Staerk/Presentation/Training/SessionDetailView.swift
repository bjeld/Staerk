import SwiftData
import SwiftUI

struct SessionDetailView: View {
    var sessionID: String

    @Environment(AppContainer.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Query private var sessionRows: [SessionRecord]
    @Query private var settingsRows: [SettingsRecord]
    @State private var confirmDelete = false

    private var session: SessionLog? { sessionRows.first { $0.id == sessionID }?.asDomain() }
    private var settings: UserSettings { settingsRows.first?.asDomain() ?? UserSettings() }

    var body: some View {
        Group {
            if let session {
                Screen {
                    ScreenHeader(
                        eyebrow: Dates.prettyLong(key: session.dateKey),
                        title: session.workoutName
                    ) {
                        Pill(
                            text: session.completed ? L10n.string("session.completed") : L10n.string("session.draft.status"),
                            tint: session.completed ? Palette.accent : Palette.inkSecondary,
                            filled: session.completed
                        )
                    }

                    summary(session)

                    ForEach(session.exercises) { block in
                        exerciseCard(block)
                    }

                    DangerButton(title: L10n.string("session.delete")) {
                        confirmDelete = true
                    }
                }
            } else {
                Screen {
                    EmptyState(symbol: "hourglass", message: L10n.string("session.missing"))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L10n.string("session.delete.confirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L10n.string("session.delete"), role: .destructive) {
                try? app.sessions.delete(id: sessionID)
                dismiss()
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        }
    }

    private func summary(_ session: SessionLog) -> some View {
        let minutes = session.finishedAt.map { max(1, Int($0.timeIntervalSince(session.startedAt) / 60)) }
        return Card(padding: Space.l) {
            HStack(spacing: 0) {
                stat(value: "\(session.doneSetCount)", label: L10n.string("session.sets"))
                divider
                stat(value: "\(session.exercises.count)", label: L10n.string("training.exercises"))
                if let minutes {
                    divider
                    stat(value: "\(minutes)", label: "min")
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.hairline)
            .frame(width: 1, height: 36)
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: Space.xxs) {
            Text(value)
                .font(Typeface.metric)
                .monospacedDigit()
                .foregroundStyle(Palette.ink)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func exerciseCard(_ block: SessionExerciseBlock) -> some View {
        Card {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Space.xxs) {
                    Text(block.name.isEmpty ? block.exerciseId : block.name)
                        .font(Typeface.cardTitle)
                        .foregroundStyle(Palette.ink)
                    Text(block.muscleGroup.localizedName)
                        .font(.footnote)
                        .foregroundStyle(Palette.inkSecondary)
                }
                Spacer()
                NavigationLink {
                    ExerciseHistoryView(exerciseID: block.exerciseId)
                } label: {
                    CircleIcon(symbol: "chart.xyaxis.line", size: 36, tint: Palette.inkSecondary)
                }
                .buttonStyle(PressableStyle(scale: 0.92))
                .accessibilityLabel(L10n.string("session.chart"))
            }
            .padding(.bottom, Space.m)

            ForEach(Array(block.sets.enumerated()), id: \.element.id) { index, set in
                HStack(spacing: Space.m) {
                    CompletionCheck(isOn: set.done, tint: Palette.accent, size: 26, label: "\(index + 1)")
                    Text(L10n.format("session.set", index + 1))
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSecondary)
                    Spacer()
                    Text(AdviceFormatter.formatSet(logType: block.logType, set: set, unit: settings.weightUnit))
                        .font(.body.weight(.semibold).monospacedDigit())
                        .foregroundStyle(set.done ? Palette.ink : Palette.inkTertiary)
                }
                .padding(.vertical, Space.s)
                .accessibilityElement(children: .combine)
                .accessibilityValue(set.done ? L10n.string("a11y.done") : L10n.string("a11y.todo"))
                if index < block.sets.count - 1 {
                    RowDivider(inset: 38)
                }
            }
        }
    }
}
