import Foundation
import SwiftData
import FirebaseFirestore

/// Deliberately simple v1 sync: push-on-write, pull-on-sign-in, last-write-wins.
/// No realtime listeners, no conflict resolution — a reasonable scope for
/// Curve's mostly-additive logging pattern. Every function is a safe no-op
/// when signed out or when Firebase isn't configured yet, so local-only use
/// is completely unaffected.
enum SyncManager {
    private static var db: Firestore? {
        guard AuthManager.shared.isFirebaseConfigured else { return nil }
        return Firestore.firestore()
    }

    private static func userCollection(_ name: String) -> CollectionReference? {
        guard let db, let uid = AuthManager.shared.currentUserID else { return nil }
        return db.collection("users").document(uid).collection(name)
    }

    // MARK: - Push

    static func pushSession(_ session: WorkoutSession) {
        guard let collection = userCollection("sessions") else { return }
        let dto = WorkoutSessionDTO(session: session)
        try? collection.document(dto.id).setData(from: dto)
    }

    static func deleteSession(id: UUID) {
        userCollection("sessions")?.document(id.uuidString).delete()
    }

    static func pushTemplate(_ template: WorkoutTemplate) {
        guard let collection = userCollection("templates") else { return }
        let dto = WorkoutTemplateDTO(template: template)
        try? collection.document(dto.id).setData(from: dto)
    }

    static func deleteTemplate(id: UUID) {
        userCollection("templates")?.document(id.uuidString).delete()
    }

    static func pushBodyStat(_ entry: BodyStatEntry) {
        guard let collection = userCollection("bodyStats") else { return }
        let dto = BodyStatEntryDTO(entry: entry)
        try? collection.document(dto.id).setData(from: dto)
    }

    static func deleteBodyStat(id: UUID) {
        userCollection("bodyStats")?.document(id.uuidString).delete()
    }

    static func pushCustomExercise(_ exercise: Exercise) {
        guard exercise.isCustom, let collection = userCollection("customExercises") else { return }
        let dto = CustomExerciseDTO(exercise: exercise)
        try? collection.document(dto.id).setData(from: dto)
    }

    /// Deletes every document across all of this user's collections — backs
    /// Settings' "Reset All Data" when signed in, so it still means what it says.
    static func deleteAllRemoteData() async {
        guard AuthManager.shared.currentUserID != nil else { return }
        for name in ["sessions", "templates", "bodyStats", "customExercises"] {
            guard let collection = userCollection(name) else { continue }
            guard let snapshot = try? await collection.getDocuments() else { continue }
            for doc in snapshot.documents {
                try? await doc.reference.delete()
            }
        }
    }

    // MARK: - Pull

    /// Fetches everything under the signed-in user and inserts anything not
    /// already present locally (dedup by UUID). Call once right after sign-in.
    @MainActor
    static func pullAll(context: ModelContext) async {
        guard AuthManager.shared.currentUserID != nil else { return }
        await pullCustomExercises(context: context)
        await pullTemplates(context: context)
        await pullSessions(context: context)
        await pullBodyStats(context: context)
        try? context.save()
    }

    private static func findOrCreateExercise(name: String, muscleGroupRaw: String, context: ModelContext) -> Exercise {
        let predicate = #Predicate<Exercise> { $0.name == name }
        if let existing = try? context.fetch(FetchDescriptor(predicate: predicate)).first {
            return existing
        }
        let exercise = Exercise(name: name, muscleGroup: MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody, isCustom: true)
        context.insert(exercise)
        return exercise
    }

    private static func pullCustomExercises(context: ModelContext) async {
        guard let collection = userCollection("customExercises") else { return }
        guard let snapshot = try? await collection.getDocuments() else { return }
        let existingIDs = Set(((try? context.fetch(FetchDescriptor<Exercise>())) ?? []).map(\.id))
        for doc in snapshot.documents {
            guard let dto = try? doc.data(as: CustomExerciseDTO.self),
                  let uuid = UUID(uuidString: dto.id), !existingIDs.contains(uuid) else { continue }
            let exercise = Exercise(name: dto.name, muscleGroup: MuscleGroup(rawValue: dto.muscleGroupRaw) ?? .fullBody, isCustom: true)
            exercise.id = uuid
            context.insert(exercise)
        }
    }

    private static func pullSessions(context: ModelContext) async {
        guard let collection = userCollection("sessions") else { return }
        guard let snapshot = try? await collection.getDocuments() else { return }
        let existingIDs = Set(((try? context.fetch(FetchDescriptor<WorkoutSession>())) ?? []).map(\.id))
        for doc in snapshot.documents {
            guard let dto = try? doc.data(as: WorkoutSessionDTO.self),
                  let uuid = UUID(uuidString: dto.id), !existingIDs.contains(uuid) else { continue }

            let session = WorkoutSession(name: dto.name, templateNameSnapshot: dto.templateNameSnapshot, startedAt: dto.startedAt)
            session.id = uuid
            session.endedAt = dto.endedAt
            session.notes = dto.notes
            context.insert(session)

            for exerciseDTO in dto.exercises {
                guard let exerciseUUID = UUID(uuidString: exerciseDTO.id) else { continue }
                let matched = findOrCreateExercise(name: exerciseDTO.exerciseName, muscleGroupRaw: exerciseDTO.muscleGroupRaw, context: context)
                let logged = LoggedExercise(exercise: matched, order: exerciseDTO.order)
                logged.id = exerciseUUID
                logged.session = session
                context.insert(logged)

                for setDTO in exerciseDTO.sets {
                    guard let setUUID = UUID(uuidString: setDTO.id) else { continue }
                    let set = WorkoutSet(setIndex: setDTO.setIndex, reps: setDTO.reps, weight: setDTO.weight, restSeconds: setDTO.restSeconds, isWarmup: setDTO.isWarmup)
                    set.id = setUUID
                    set.isCompleted = setDTO.isCompleted
                    set.loggedExercise = logged
                    context.insert(set)
                }
            }
        }
    }

    private static func pullTemplates(context: ModelContext) async {
        guard let collection = userCollection("templates") else { return }
        guard let snapshot = try? await collection.getDocuments() else { return }
        let existingIDs = Set(((try? context.fetch(FetchDescriptor<WorkoutTemplate>())) ?? []).map(\.id))
        for doc in snapshot.documents {
            guard let dto = try? doc.data(as: WorkoutTemplateDTO.self),
                  let uuid = UUID(uuidString: dto.id), !existingIDs.contains(uuid) else { continue }

            let template = WorkoutTemplate(name: dto.name, iconName: dto.iconName)
            template.id = uuid
            context.insert(template)

            for exerciseDTO in dto.exercises {
                guard let exerciseUUID = UUID(uuidString: exerciseDTO.id) else { continue }
                let matched = findOrCreateExercise(name: exerciseDTO.exerciseName, muscleGroupRaw: exerciseDTO.muscleGroupRaw, context: context)
                let templateExercise = TemplateExercise(
                    exercise: matched,
                    order: exerciseDTO.order,
                    targetSets: exerciseDTO.targetSets,
                    targetReps: exerciseDTO.targetReps,
                    targetWeight: exerciseDTO.targetWeight,
                    restSeconds: exerciseDTO.restSeconds
                )
                templateExercise.id = exerciseUUID
                templateExercise.template = template
                context.insert(templateExercise)
            }
        }
    }

    private static func pullBodyStats(context: ModelContext) async {
        guard let collection = userCollection("bodyStats") else { return }
        guard let snapshot = try? await collection.getDocuments() else { return }
        let existingIDs = Set(((try? context.fetch(FetchDescriptor<BodyStatEntry>())) ?? []).map(\.id))
        for doc in snapshot.documents {
            guard let dto = try? doc.data(as: BodyStatEntryDTO.self),
                  let uuid = UUID(uuidString: dto.id), !existingIDs.contains(uuid) else { continue }
            let entry = BodyStatEntry(date: dto.date, weight: dto.weight, bodyFatPercentage: dto.bodyFatPercentage, notes: dto.notes)
            entry.id = uuid
            context.insert(entry)
        }
    }
}

// MARK: - DTOs

private struct WorkoutSetDTO: Codable {
    var id: String
    var setIndex: Int
    var reps: Int
    var weight: Double
    var restSeconds: Int
    var isWarmup: Bool
    var isCompleted: Bool

    init(set: WorkoutSet) {
        id = set.id.uuidString
        setIndex = set.setIndex
        reps = set.reps
        weight = set.weight
        restSeconds = set.restSeconds
        isWarmup = set.isWarmup
        isCompleted = set.isCompleted
    }
}

private struct LoggedExerciseDTO: Codable {
    var id: String
    var exerciseName: String
    var muscleGroupRaw: String
    var order: Int
    var sets: [WorkoutSetDTO]

    init(exercise: LoggedExercise) {
        id = exercise.id.uuidString
        exerciseName = exercise.displayName
        muscleGroupRaw = exercise.muscleGroupRaw
        order = exercise.order
        sets = exercise.sortedSets.map(WorkoutSetDTO.init)
    }
}

private struct WorkoutSessionDTO: Codable {
    var id: String
    var name: String
    var templateNameSnapshot: String?
    var startedAt: Date
    var endedAt: Date?
    var notes: String
    var exercises: [LoggedExerciseDTO]

    init(session: WorkoutSession) {
        id = session.id.uuidString
        name = session.name
        templateNameSnapshot = session.templateNameSnapshot
        startedAt = session.startedAt
        endedAt = session.endedAt
        notes = session.notes
        exercises = session.sortedExercises.map(LoggedExerciseDTO.init)
    }
}

private struct TemplateExerciseDTO: Codable {
    var id: String
    var exerciseName: String
    var muscleGroupRaw: String
    var order: Int
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double
    var restSeconds: Int

    init(templateExercise: TemplateExercise) {
        id = templateExercise.id.uuidString
        exerciseName = templateExercise.displayName
        muscleGroupRaw = templateExercise.muscleGroupRaw
        order = templateExercise.order
        targetSets = templateExercise.targetSets
        targetReps = templateExercise.targetReps
        targetWeight = templateExercise.targetWeight
        restSeconds = templateExercise.restSeconds
    }
}

private struct WorkoutTemplateDTO: Codable {
    var id: String
    var name: String
    var iconName: String
    var createdAt: Date
    var exercises: [TemplateExerciseDTO]

    init(template: WorkoutTemplate) {
        id = template.id.uuidString
        name = template.name
        iconName = template.iconName
        createdAt = template.createdAt
        exercises = template.sortedExercises.map(TemplateExerciseDTO.init)
    }
}

private struct BodyStatEntryDTO: Codable {
    var id: String
    var date: Date
    var weight: Double?
    var bodyFatPercentage: Double?
    var notes: String

    init(entry: BodyStatEntry) {
        id = entry.id.uuidString
        date = entry.date
        weight = entry.weight
        bodyFatPercentage = entry.bodyFatPercentage
        notes = entry.notes
    }
}

private struct CustomExerciseDTO: Codable {
    var id: String
    var name: String
    var muscleGroupRaw: String
    var createdAt: Date

    init(exercise: Exercise) {
        id = exercise.id.uuidString
        name = exercise.name
        muscleGroupRaw = exercise.muscleGroupRaw
        createdAt = exercise.createdAt
    }
}
