import Foundation

public enum MeasurementType: String, Codable, Sendable {
    case strength
    case aerobic
}

public enum AerobicIntervalKind: String, Codable, Sendable {
    case work
    case rest
}

public struct WorkoutEvent: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let move: String
    public let moveId: UUID?
    public let startedAt: Date
    public let endedAt: Date?
    public let measurementType: MeasurementType
    public let weight: Double?
    public let reps: Int?
    public let durationSeconds: Int?
    public let weightRecordedAt: Date?
    public let repsRecordedAt: Date?
    public let intensity: Double?
    public let intensityMetric: String?
    public let intervalKind: AerobicIntervalKind?
    public let intervalLabel: String?
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        move: String,
        moveId: UUID? = nil,
        startedAt: Date,
        endedAt: Date? = nil,
        measurementType: MeasurementType,
        weight: Double? = nil,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        weightRecordedAt: Date? = nil,
        repsRecordedAt: Date? = nil,
        intensity: Double? = nil,
        intensityMetric: String? = nil,
        intervalKind: AerobicIntervalKind? = nil,
        intervalLabel: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.move = move
        self.moveId = moveId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.measurementType = measurementType
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
        self.weightRecordedAt = weightRecordedAt
        self.repsRecordedAt = repsRecordedAt
        self.intensity = intensity
        self.intensityMetric = intensityMetric
        self.intervalKind = intervalKind
        self.intervalLabel = intervalLabel
        self.updatedAt = updatedAt
    }
}
