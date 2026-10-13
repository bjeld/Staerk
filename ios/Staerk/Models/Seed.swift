import Foundation
import SwiftData

enum Seed {
    static func ensure(in context: ModelContext) {
        let settingsCount = (try? context.fetchCount(FetchDescriptor<AppSettings>())) ?? 0
        if settingsCount == 0 {
            context.insert(AppSettings.makeDefault())
        }

        let exerciseCount = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        if exerciseCount == 0 {
            for exercise in defaultExercises() {
                context.insert(exercise)
            }
        }

        try? context.save()
    }

    static func restoreDefaultProgram(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        for exercise in existing {
            context.delete(exercise)
        }
        for exercise in defaultExercises() {
            context.insert(exercise)
        }
        try? context.save()
    }

    static func defaultExercises() -> [Exercise] {
        [
            Exercise(
                id: "ex_a_legpress",
                name: "Benpres",
                muscleGroup: .legs,
                workout: .A,
                defaultSets: 3,
                defaultRepsMin: 8,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Fødder midt på pladen, knæ i samme retning som tæerne. Stop før knæene falder ind. Fuld, kontrolleret bevægelse.",
                order: 1
            ),
            Exercise(
                id: "ex_a_chestpress",
                name: "Brystpres (maskine)",
                muscleGroup: .chest,
                workout: .A,
                defaultSets: 3,
                defaultRepsMin: 8,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Skulderblade tilbage. Pres ud uden at låse hårdt. 1–2 reps i reserve — ikke til failure.",
                order: 2
            ),
            Exercise(
                id: "ex_a_latpulldown",
                name: "Lat pulldown",
                muscleGroup: .back,
                workout: .A,
                defaultSets: 3,
                defaultRepsMin: 8,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Træk stangen til øvre bryst. Brystet frem, undgå at svaje lænden. Langsom retur.",
                order: 3
            ),
            Exercise(
                id: "ex_a_shoulderpress",
                name: "Skulderpres",
                muscleGroup: .shoulders,
                workout: .A,
                defaultSets: 3,
                defaultRepsMin: 8,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Maskine eller håndvægte. Neutral nakke. Stop hvis det strammer foran i skulderen.",
                order: 4
            ),
            Exercise(
                id: "ex_a_triceps",
                name: "Triceps-pres",
                muscleGroup: .arms,
                workout: .A,
                defaultSets: 3,
                defaultRepsMin: 10,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Albuer tæt på kroppen. Kun underarmen bevæger sig. Let vægt, ren lockout.",
                order: 5
            ),
            Exercise(
                id: "ex_a_plank",
                name: "Planke",
                muscleGroup: .core,
                workout: .A,
                defaultSets: 3,
                defaultRepsMin: 20,
                defaultRepsMax: 40,
                logType: .seconds,
                notes: "Stram baller og mave. Neutral ryg — ikke sænk hoften. Log sekunder pr. sæt.",
                order: 6
            ),
            Exercise(
                id: "ex_b_rdl",
                name: "Rumænsk dødløft",
                muscleGroup: .legs,
                workout: .B,
                defaultSets: 3,
                defaultRepsMin: 8,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Håndvægte eller stang. Bløde knæ, skyd hoften tilbage. Mærk bagsiden af lårene. Start let — ryggen skal holde sig neutral.",
                order: 1
            ),
            Exercise(
                id: "ex_b_row",
                name: "Siddende roning",
                muscleGroup: .back,
                workout: .B,
                defaultSets: 3,
                defaultRepsMin: 8,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Træk til maven, klem skulderbladene. Ingen ryk. Pause 1 sek i sammentrækningen.",
                order: 2
            ),
            Exercise(
                id: "ex_b_incline",
                name: "Skrå brystpres",
                muscleGroup: .chest,
                workout: .B,
                defaultSets: 3,
                defaultRepsMin: 8,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Let skrå bænk eller maskine. Kontrolleret sænkning. Godt supplement til fladt pres.",
                order: 3
            ),
            Exercise(
                id: "ex_b_lateral",
                name: "Sidehev",
                muscleGroup: .shoulders,
                workout: .B,
                defaultSets: 3,
                defaultRepsMin: 10,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Lette håndvægte. Albuer bløde, løft til skulderhøjde. Ingen sving med overkroppen.",
                order: 4
            ),
            Exercise(
                id: "ex_b_curl",
                name: "Biceps curl",
                muscleGroup: .arms,
                workout: .B,
                defaultSets: 3,
                defaultRepsMin: 10,
                defaultRepsMax: 12,
                logType: .reps,
                notes: "Håndvægte eller stang. Albuer faste. Sænk langsomt — det er her musklen bygges.",
                order: 5
            ),
            Exercise(
                id: "ex_b_deadbug",
                name: "Dead bug",
                muscleGroup: .core,
                workout: .B,
                defaultSets: 3,
                defaultRepsMin: 8,
                defaultRepsMax: 10,
                logType: .reps,
                notes: "Lænden i gulvet hele tiden. Modsat arm/ben strækkes. Log reps pr. side.",
                order: 6
            ),
        ]
    }
}
