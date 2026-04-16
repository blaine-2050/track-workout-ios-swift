import Foundation
import CoreData

/// Parsed-but-not-yet-persisted HR sample. Mirrors
/// `DATA_MODEL.md § CSV Import Schema` minus the IDs that get assigned
/// at persist time.
struct ParsedHRSample {
    let timestamp: Date
    let bpm: Int
    let elevationMeters: Double?
    let speedKmh: Double?
    let distanceKm: Double?
}

struct HRImportResult {
    let batchId: UUID
    let parsed: Int
    let skipped: Int
    let persisted: Int
    let aligned: Int
    let source: String
}

enum HRImporter {
    /// Parse a CSV string. Case-insensitive headers. Unknown columns
    /// ignored. Rows missing required columns or with non-parseable
    /// values are skipped silently (counted in result.skipped).
    ///
    /// Required columns (any casing): `timestamp`, `heart_rate_bpm`.
    /// Optional: `elevation_m`, `speed_kmh`, `distance_km`.
    static func parse(_ csv: String) -> (samples: [ParsedHRSample], skipped: Int) {
        let lines = csv.split(whereSeparator: \.isNewline).map(String.init)
        guard let header = lines.first else { return ([], 0) }

        let columns = header.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        guard let tsIdx = columns.firstIndex(of: "timestamp"),
              let bpmIdx = columns.firstIndex(of: "heart_rate_bpm") else {
            return ([], max(0, lines.count - 1))
        }
        let elIdx = columns.firstIndex(of: "elevation_m")
        let spIdx = columns.firstIndex(of: "speed_kmh")
        let dsIdx = columns.firstIndex(of: "distance_km")

        var samples: [ParsedHRSample] = []
        var skipped = 0

        let isoWithFraction = ISO8601DateFormatter()
        isoWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoPlain = ISO8601DateFormatter()
        isoPlain.formatOptions = [.withInternetDateTime]

        for line in lines.dropFirst() {
            let cells = line.split(separator: ",", omittingEmptySubsequences: false).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard cells.count > max(tsIdx, bpmIdx) else {
                skipped += 1
                continue
            }
            let tsString = cells[tsIdx]
            guard let ts = isoWithFraction.date(from: tsString) ?? isoPlain.date(from: tsString) else {
                skipped += 1
                continue
            }
            guard let bpm = Int(cells[bpmIdx]), bpm > 0 else {
                // Sentinel 0 and non-integer cells are treated as "no real reading".
                skipped += 1
                continue
            }
            let elevation: Double? = elIdx.flatMap { idx in idx < cells.count ? Double(cells[idx]) : nil }
            let speed: Double? = spIdx.flatMap { idx in idx < cells.count ? Double(cells[idx]) : nil }
            let distance: Double? = dsIdx.flatMap { idx in idx < cells.count ? Double(cells[idx]) : nil }

            samples.append(ParsedHRSample(
                timestamp: ts,
                bpm: bpm,
                elevationMeters: elevation,
                speedKmh: speed,
                distanceKm: distance
            ))
        }

        return (samples, skipped)
    }

    /// Persist parsed samples, assign `importBatchId`, and align to the
    /// Workout whose time window contains each sample's timestamp.
    /// Runs on the given context synchronously — caller decides the
    /// isolation/progress semantics.
    @discardableResult
    static func persistAndAlign(
        _ samples: [ParsedHRSample],
        source: String,
        userId: UUID,
        in context: NSManagedObjectContext
    ) -> HRImportResult {
        let batchId = UUID()

        // Load all workouts once for alignment. Cheap until thousands of
        // workouts exist; revisit when that matters.
        let workoutsRequest: NSFetchRequest<Workout> = Workout.fetchRequest()
        let workouts = (try? context.fetch(workoutsRequest)) ?? []

        var persisted = 0
        var aligned = 0

        for parsed in samples {
            let sample = HeartRateSample(context: context)
            sample.id = UUID()
            sample.userId = userId
            sample.timestamp = parsed.timestamp
            sample.bpm = Int16(clamping: parsed.bpm)
            sample.source = source
            sample.importBatchId = batchId
            sample.elevationMeters = parsed.elevationMeters ?? 0  // scalar 0 is "unset" since attribute is Double non-scalar and Optional in Swift — see model contents
            sample.speedKmh = parsed.speedKmh ?? 0
            sample.distanceKm = parsed.distanceKm ?? 0

            if let matching = workouts.first(where: { workoutContains($0, date: parsed.timestamp) }) {
                sample.workoutId = matching.id
                aligned += 1
            }
            persisted += 1
        }

        do {
            try context.save()
        } catch {
            print("[HRImporter] save failed: \(error)")
        }

        return HRImportResult(
            batchId: batchId,
            parsed: samples.count + 0,
            skipped: 0,
            persisted: persisted,
            aligned: aligned,
            source: source
        )
    }

    private static func workoutContains(_ workout: Workout, date: Date) -> Bool {
        guard let start = workout.startTime else { return false }
        let end = workout.endTime ?? Date()
        return date >= start && date <= end
    }
}
