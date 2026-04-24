import Foundation

/// Formats GPS travel distance so sub‑hundred‑meter jitter does not show as creeping 0.1 mi/km.
enum TravelDistanceFormatting {
    /// Below this travel (meters), show **0.0** in the chosen unit (no fake 0.1 from noise).
    private static let minimumMetersToShowTenths: Double = 185

    static func displayString(meters: Double, usesMetric: Bool) -> String {
        let m = max(0, meters)
        guard m >= minimumMetersToShowTenths else {
            return "0.0"
        }
        let unitMeters = usesMetric ? 1000.0 : 1609.34
        let value = m / unitMeters
        return String(format: "%.1f", value)
    }
}
