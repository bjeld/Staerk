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
        ScrollView {
            if let session {
                VStack(alignment: .leading, spacing: 16) {
                    StaerkHeader(
                        title: session.workoutName,
                        subtitle: "\(Dates.prettyLong(key: session.dateKey)) · \(session.completed ? L10n.string("session.completed") : L10n.string("session.draft.status"))"
                    )

                    ForEach(session.exercises) { block in
                        GroupedCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(block.name.isEmpty ? block.exerciseId : block.name)
                                            .font(Typeface.title(20))
                                        Text(block.muscleGroup.localizedName)
                                            .font(.footnote)
                                            .foregroundStyle(Palette.muted)
                                    }
                                    Spacer()
                                    NavigationLink(L10n.string("session.chart")) {
                                        ExerciseHistoryView(exerciseID: block.exerciseId)
                                    }
                                    .font(.subheadline)
                                    .foregroundStyle(Palette.blue)
                                }
                                ForEach(Array(block.sets.enumerated()), id: \.element.id) { index, set in
                                    HStack {
                                        Text(L10n.format("session.set", index + 1))
                                            .foregroundStyle(Palette.muted)
                                        Spacer()
                                        Text(setLine(block: block, set: set))
                                            .monospacedDigit()
                                    }
                                    .font(.subheadline)
                                }
                            }
                            .padding(16)
                        }
                    }

                    GroupedCard {
                        DangerButton(title: L10n.string("session.delete")) {
                            confirmDelete = true
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            } else {
                Text(L10n.string("session.missing"))
                    .foregroundStyle(Palette.muted)
                    .padding()
            }
        }
        .staerkKeyboard()
        .background(Palette.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L10n.string("session.delete.confirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L10n.string("session.delete"), role: .destructive) {
                try? app.sessions.delete(id: sessionID)
                dismiss()
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        }
    }

    private func setLine(block: SessionExerciseBlock, set: SetLog) -> String {
        let body = AdviceFormatter.formatSet(logType: block.logType, set: set, unit: settings.weightUnit)
        return set.done ? "\(body) ✓" : body
    }
}
