import Foundation

public enum SyncMerge {
    // Initial deterministic strategy while product requirements are evolving.
    public static func merge(local: [WorkoutEvent], remote: [WorkoutEvent]) -> [WorkoutEvent] {
        var merged: [UUID: WorkoutEvent] = [:]

        for event in remote {
            merged[event.id] = event
        }

        for event in local {
            guard let existing = merged[event.id] else {
                merged[event.id] = event
                continue
            }

            if event.updatedAt >= existing.updatedAt {
                merged[event.id] = event
            }
        }

        return merged.values.sorted(by: { $0.startedAt > $1.startedAt })
    }
}
