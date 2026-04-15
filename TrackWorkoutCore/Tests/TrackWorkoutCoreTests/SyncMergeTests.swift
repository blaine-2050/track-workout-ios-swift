import Foundation
import Testing
@testable import TrackWorkoutCore

struct SyncMergeTests {
    @Test
    func newerLocalWinsOnConflict() {
        let id = UUID()
        let now = Date()
        let old = now.addingTimeInterval(-60)

        let remote = WorkoutEvent(
            id: id,
            move: "Squat",
            startedAt: old,
            measurementType: .strength,
            weight: 100,
            reps: 5,
            updatedAt: old
        )

        let local = WorkoutEvent(
            id: id,
            move: "Squat",
            startedAt: old,
            measurementType: .strength,
            weight: 102.5,
            reps: 5,
            updatedAt: now
        )

        let merged = SyncMerge.merge(local: [local], remote: [remote])
        #expect(merged.count == 1)
        #expect(merged.first?.weight == 102.5)
    }
}
