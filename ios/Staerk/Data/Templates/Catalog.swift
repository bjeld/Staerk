import Foundation

enum HabitCatalog {
    static let creatine = HabitTemplate(
        id: "tmpl_creatine",
        nameKey: "template.habit.creatine.name",
        notesKey: "template.habit.creatine.notes",
        kind: .boolean,
        symbol: "pills.fill",
        tintHex: "FF3B5C",
        weekdays: .all,
        goal: 1,
        reminderEnabled: true,
        reminderTime: "06:15"
    )

    static let water = HabitTemplate(
        id: "tmpl_water",
        nameKey: "template.habit.water.name",
        notesKey: "template.habit.water.notes",
        kind: .counter,
        symbol: "drop.fill",
        tintHex: "64D2FF",
        weekdays: .all,
        goal: 8,
        reminderEnabled: false,
        reminderTime: "09:00"
    )

    static let alcoholFree = HabitTemplate(
        id: "tmpl_alcohol",
        nameKey: "template.habit.alcohol.name",
        notesKey: "template.habit.alcohol.notes",
        kind: .boolean,
        symbol: "nosign",
        tintHex: "FF9F0A",
        weekdays: .all,
        goal: 1,
        reminderEnabled: false,
        reminderTime: "20:00"
    )

    static let workout = HabitTemplate(
        id: "tmpl_workout",
        nameKey: "template.habit.workout.name",
        notesKey: "template.habit.workout.notes",
        kind: .workout,
        symbol: "dumbbell.fill",
        tintHex: "2563FF",
        weekdays: .trainingDefault,
        goal: 1,
        reminderEnabled: true,
        reminderTime: "06:15"
    )

    static let steps = HabitTemplate(
        id: "tmpl_steps",
        nameKey: "template.habit.steps.name",
        notesKey: "template.habit.steps.notes",
        kind: .counter,
        symbol: "figure.walk",
        tintHex: "0A84FF",
        weekdays: .all,
        goal: 8,
        reminderEnabled: false,
        reminderTime: "18:00"
    )

    static let mobility = HabitTemplate(
        id: "tmpl_mobility",
        nameKey: "template.habit.mobility.name",
        notesKey: "template.habit.mobility.notes",
        kind: .boolean,
        symbol: "figure.flexibility",
        tintHex: "BF5AF2",
        weekdays: .all,
        goal: 1,
        reminderEnabled: false,
        reminderTime: "07:30"
    )

    static let protein = HabitTemplate(
        id: "tmpl_protein",
        nameKey: "template.habit.protein.name",
        notesKey: "template.habit.protein.notes",
        kind: .boolean,
        symbol: "fork.knife",
        tintHex: "30D158",
        weekdays: .all,
        goal: 1,
        reminderEnabled: false,
        reminderTime: "12:00"
    )

    static let golf = HabitTemplate(
        id: "tmpl_golf",
        nameKey: "template.habit.golf.name",
        notesKey: "template.habit.golf.notes",
        kind: .boolean,
        symbol: "figure.golf",
        tintHex: "00A884",
        weekdays: .weekend,
        goal: 1,
        reminderEnabled: false,
        reminderTime: "09:00"
    )

    static let all: [HabitTemplate] = [
        creatine, water, alcoholFree, workout, steps, mobility, protein, golf
    ]

    static func make(_ template: HabitTemplate, sortOrder: Int) -> Habit {
        template.makeHabit(
            sortOrder: sortOrder,
            localizedName: String(localized: String.LocalizationValue(template.nameKey)),
            localizedNotes: String(localized: String.LocalizationValue(template.notesKey))
        )
    }
}

struct ProgramBlueprint: Identifiable {
    var id: String
    var nameKey: String
    var notesKey: String
    var workouts: [WorkoutBlueprint]
    var weekdays: [[Int]]
}

struct WorkoutBlueprint {
    var nameKey: String
    var exercises: [ExerciseBlueprint]
}

struct ExerciseBlueprint {
    var id: String
    var nameKey: String
    var muscle: MuscleGroup
    var sets: Int
    var repsMin: Int
    var repsMax: Int
    var logType: LogType
    var notesKey: String
}

enum ProgramCatalog {
    static let fullBody = ProgramBlueprint(
        id: "tmpl_fullbody",
        nameKey: "template.program.fullbody.name",
        notesKey: "template.program.fullbody.notes",
        workouts: [
            WorkoutBlueprint(nameKey: "template.workout.a", exercises: fullBodyA),
            WorkoutBlueprint(nameKey: "template.workout.b", exercises: fullBodyB)
        ],
        weekdays: [[0, 4], [2]]
    )

    static let upperLower = ProgramBlueprint(
        id: "tmpl_upperlower",
        nameKey: "template.program.upperlower.name",
        notesKey: "template.program.upperlower.notes",
        workouts: [
            WorkoutBlueprint(nameKey: "template.workout.upper", exercises: upper),
            WorkoutBlueprint(nameKey: "template.workout.lower", exercises: lower)
        ],
        weekdays: [[0, 3], [1, 4]]
    )

    static let pushPullLegs = ProgramBlueprint(
        id: "tmpl_ppl",
        nameKey: "template.program.ppl.name",
        notesKey: "template.program.ppl.notes",
        workouts: [
            WorkoutBlueprint(nameKey: "template.workout.push", exercises: push),
            WorkoutBlueprint(nameKey: "template.workout.pull", exercises: pull),
            WorkoutBlueprint(nameKey: "template.workout.legs", exercises: legs)
        ],
        weekdays: [[0], [2], [4]]
    )

    static let martin = ProgramBlueprint(
        id: "tmpl_martin",
        nameKey: "template.program.martin.name",
        notesKey: "template.program.martin.notes",
        workouts: [
            WorkoutBlueprint(nameKey: "template.workout.a", exercises: martinA),
            WorkoutBlueprint(nameKey: "template.workout.b", exercises: martinB)
        ],
        weekdays: [[0], [2], [4]]
    )

    static let all: [ProgramBlueprint] = [fullBody, upperLower, pushPullLegs, martin]

    static func localizedName(_ blueprint: ProgramBlueprint) -> String {
        String(localized: String.LocalizationValue(blueprint.nameKey))
    }

    static func localizedNotes(_ blueprint: ProgramBlueprint) -> String {
        String(localized: String.LocalizationValue(blueprint.notesKey))
    }

    static func materialize(_ blueprint: ProgramBlueprint) -> MaterializedProgram {
        let program = TrainingProgram(
            name: localizedName(blueprint),
            notes: localizedNotes(blueprint),
            isActive: true,
            templateID: blueprint.id
        )
        var workouts: [WorkoutPlan] = []
        var exercises: [ExerciseDefinition] = []
        for (index, workoutBlue) in blueprint.workouts.enumerated() {
            let workout = WorkoutPlan(
                programID: program.id,
                name: String(localized: String.LocalizationValue(workoutBlue.nameKey)),
                sortOrder: index
            )
            workouts.append(workout)
            for (exerciseIndex, item) in workoutBlue.exercises.enumerated() {
                exercises.append(
                    ExerciseDefinition(
                        id: StaerkID.make("ex"),
                        workoutID: workout.id,
                        name: String(localized: String.LocalizationValue(item.nameKey)),
                        muscleGroup: item.muscle,
                        defaultSets: item.sets,
                        defaultRepsMin: item.repsMin,
                        defaultRepsMax: item.repsMax,
                        logType: item.logType,
                        notes: String(localized: String.LocalizationValue(item.notesKey)),
                        sortOrder: exerciseIndex + 1
                    )
                )
            }
        }
        var ids: [String?] = Array(repeating: nil, count: 7)
        for (workoutIndex, days) in blueprint.weekdays.enumerated() where workouts.indices.contains(workoutIndex) {
            for day in days {
                ids[day] = workouts[workoutIndex].id
            }
        }
        // Martin's original A/B rotation: Mon A, Wed B, Fri A — weekdays [[0],[2],[4]]
        // with 2 workouts maps Mon->A, Wed->B, Fri->A if we cycle.
        if blueprint.id == "tmpl_martin" || blueprint.id == "tmpl_fullbody" {
            ids = Array(repeating: nil, count: 7)
            let a = workouts[0].id
            let b = workouts.count > 1 ? workouts[1].id : a
            ids[0] = a
            ids[2] = b
            ids[4] = a
        }
        return MaterializedProgram(
            program: program,
            workouts: workouts,
            exercises: exercises,
            schedule: WeeklySchedule(workoutIDs: ids)
        )
    }
}

struct MaterializedProgram {
    var program: TrainingProgram
    var workouts: [WorkoutPlan]
    var exercises: [ExerciseDefinition]
    var schedule: WeeklySchedule
}

private let fullBodyA: [ExerciseBlueprint] = [
    .init(id: "fb_a_squat", nameKey: "ex.squat", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.squat.notes"),
    .init(id: "fb_a_bench", nameKey: "ex.chestpress", muscle: .chest, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.chestpress.notes"),
    .init(id: "fb_a_row", nameKey: "ex.row", muscle: .back, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.row.notes"),
    .init(id: "fb_a_press", nameKey: "ex.shoulderpress", muscle: .shoulders, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.shoulderpress.notes"),
    .init(id: "fb_a_plank", nameKey: "ex.plank", muscle: .core, sets: 3, repsMin: 20, repsMax: 40, logType: .seconds, notesKey: "ex.plank.notes")
]

private let fullBodyB: [ExerciseBlueprint] = [
    .init(id: "fb_b_rdl", nameKey: "ex.rdl", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.rdl.notes"),
    .init(id: "fb_b_pulldown", nameKey: "ex.latpulldown", muscle: .back, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.latpulldown.notes"),
    .init(id: "fb_b_incline", nameKey: "ex.incline", muscle: .chest, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.incline.notes"),
    .init(id: "fb_b_curl", nameKey: "ex.curl", muscle: .arms, sets: 3, repsMin: 10, repsMax: 12, logType: .reps, notesKey: "ex.curl.notes"),
    .init(id: "fb_b_deadbug", nameKey: "ex.deadbug", muscle: .core, sets: 3, repsMin: 8, repsMax: 10, logType: .reps, notesKey: "ex.deadbug.notes")
]

private let upper: [ExerciseBlueprint] = [
    .init(id: "ul_u_bench", nameKey: "ex.chestpress", muscle: .chest, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.chestpress.notes"),
    .init(id: "ul_u_row", nameKey: "ex.row", muscle: .back, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.row.notes"),
    .init(id: "ul_u_press", nameKey: "ex.shoulderpress", muscle: .shoulders, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.shoulderpress.notes"),
    .init(id: "ul_u_pulldown", nameKey: "ex.latpulldown", muscle: .back, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.latpulldown.notes"),
    .init(id: "ul_u_curl", nameKey: "ex.curl", muscle: .arms, sets: 3, repsMin: 10, repsMax: 12, logType: .reps, notesKey: "ex.curl.notes"),
    .init(id: "ul_u_triceps", nameKey: "ex.triceps", muscle: .arms, sets: 3, repsMin: 10, repsMax: 12, logType: .reps, notesKey: "ex.triceps.notes")
]

private let lower: [ExerciseBlueprint] = [
    .init(id: "ul_l_squat", nameKey: "ex.squat", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.squat.notes"),
    .init(id: "ul_l_rdl", nameKey: "ex.rdl", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.rdl.notes"),
    .init(id: "ul_l_press", nameKey: "ex.legpress", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.legpress.notes"),
    .init(id: "ul_l_plank", nameKey: "ex.plank", muscle: .core, sets: 3, repsMin: 20, repsMax: 40, logType: .seconds, notesKey: "ex.plank.notes")
]

private let push: [ExerciseBlueprint] = [
    .init(id: "ppl_p_bench", nameKey: "ex.chestpress", muscle: .chest, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.chestpress.notes"),
    .init(id: "ppl_p_press", nameKey: "ex.shoulderpress", muscle: .shoulders, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.shoulderpress.notes"),
    .init(id: "ppl_p_incline", nameKey: "ex.incline", muscle: .chest, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.incline.notes"),
    .init(id: "ppl_p_triceps", nameKey: "ex.triceps", muscle: .arms, sets: 3, repsMin: 10, repsMax: 12, logType: .reps, notesKey: "ex.triceps.notes")
]

private let pull: [ExerciseBlueprint] = [
    .init(id: "ppl_u_pulldown", nameKey: "ex.latpulldown", muscle: .back, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.latpulldown.notes"),
    .init(id: "ppl_u_row", nameKey: "ex.row", muscle: .back, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.row.notes"),
    .init(id: "ppl_u_curl", nameKey: "ex.curl", muscle: .arms, sets: 3, repsMin: 10, repsMax: 12, logType: .reps, notesKey: "ex.curl.notes"),
    .init(id: "ppl_u_deadbug", nameKey: "ex.deadbug", muscle: .core, sets: 3, repsMin: 8, repsMax: 10, logType: .reps, notesKey: "ex.deadbug.notes")
]

private let legs: [ExerciseBlueprint] = [
    .init(id: "ppl_l_legpress", nameKey: "ex.legpress", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.legpress.notes"),
    .init(id: "ppl_l_rdl", nameKey: "ex.rdl", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.rdl.notes"),
    .init(id: "ppl_l_plank", nameKey: "ex.plank", muscle: .core, sets: 3, repsMin: 20, repsMax: 40, logType: .seconds, notesKey: "ex.plank.notes")
]

private let martinA: [ExerciseBlueprint] = [
    .init(id: "ex_a_legpress", nameKey: "ex.legpress", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.legpress.notes"),
    .init(id: "ex_a_chestpress", nameKey: "ex.chestpress", muscle: .chest, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.chestpress.notes"),
    .init(id: "ex_a_latpulldown", nameKey: "ex.latpulldown", muscle: .back, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.latpulldown.notes"),
    .init(id: "ex_a_shoulderpress", nameKey: "ex.shoulderpress", muscle: .shoulders, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.shoulderpress.notes"),
    .init(id: "ex_a_triceps", nameKey: "ex.triceps", muscle: .arms, sets: 3, repsMin: 10, repsMax: 12, logType: .reps, notesKey: "ex.triceps.notes"),
    .init(id: "ex_a_plank", nameKey: "ex.plank", muscle: .core, sets: 3, repsMin: 20, repsMax: 40, logType: .seconds, notesKey: "ex.plank.notes")
]

private let martinB: [ExerciseBlueprint] = [
    .init(id: "ex_b_rdl", nameKey: "ex.rdl", muscle: .legs, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.rdl.notes"),
    .init(id: "ex_b_row", nameKey: "ex.row", muscle: .back, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.row.notes"),
    .init(id: "ex_b_incline", nameKey: "ex.incline", muscle: .chest, sets: 3, repsMin: 8, repsMax: 12, logType: .reps, notesKey: "ex.incline.notes"),
    .init(id: "ex_b_lateral", nameKey: "ex.lateral", muscle: .shoulders, sets: 3, repsMin: 10, repsMax: 12, logType: .reps, notesKey: "ex.lateral.notes"),
    .init(id: "ex_b_curl", nameKey: "ex.curl", muscle: .arms, sets: 3, repsMin: 10, repsMax: 12, logType: .reps, notesKey: "ex.curl.notes"),
    .init(id: "ex_b_deadbug", nameKey: "ex.deadbug", muscle: .core, sets: 3, repsMin: 8, repsMax: 10, logType: .reps, notesKey: "ex.deadbug.notes")
]
