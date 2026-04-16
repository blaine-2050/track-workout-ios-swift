import Foundation

/// Generates a synthetic HR CSV at runtime whose timestamps are anchored
/// to `now`, so the samples naturally fall inside any workout that was
/// just logged during a demo/test. Used by Settings → "Import demo HR
/// data" and by the Maestro flow for script 07.
enum HRFixture {
    /// Build a CSV covering the `seconds` seconds that end at `endingAt`
    /// (default: now). One sample per second. Columns include optional
    /// elevation / speed / distance so the importer's full shape is
    /// exercised.
    ///
    /// The shape mirrors what a Polar/Garmin/COROS CSV export looks
    /// like after the user runs it through a vendor app's "Export CSV"
    /// option (which is the real import path — this fixture is for
    /// testing without requiring a physical device).
    static func syntheticCSV(seconds: Int = 60, endingAt: Date = Date()) -> String {
        var lines: [String] = ["timestamp,heart_rate_bpm,elevation_m,speed_kmh,distance_km"]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        // Walking-pace synthetic data: HR ramps 120→135 over the span,
        // elevation drifts a couple of meters, speed ~5 km/h, distance
        // accumulates ~0.083 km total at 5 km/h over 60s.
        let startTime = endingAt.addingTimeInterval(TimeInterval(-seconds))
        for i in 0..<seconds {
            let t = startTime.addingTimeInterval(TimeInterval(i))
            let bpm = 120 + Int(Double(i) / Double(max(1, seconds - 1)) * 15.0)
            let elevation = 100.0 + sin(Double(i) / 10.0) * 1.2
            let speed = 5.0
            let distance = Double(i + 1) * (speed / 3600.0) // km
            lines.append(String(format: "%@,%d,%.2f,%.2f,%.4f",
                                formatter.string(from: t),
                                bpm,
                                elevation,
                                speed,
                                distance))
        }
        return lines.joined(separator: "\n")
    }
}
