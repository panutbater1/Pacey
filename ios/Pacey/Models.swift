import Foundation
import SwiftData

enum LogKind: String {
    case drink
    case water
}

@Model
final class Night {
    var startedAt: Date
    var endedAt: Date?
    var plannedDrinks: Int
    var homeBy: Date
    var rideHomeRaw: String
    /// Morning check-in answer: "Great", "OK" or "Rough".
    var feel: String?

    @Relationship(deleteRule: .cascade, inverse: \LogEntry.night)
    var entries: [LogEntry] = []

    init(startedAt: Date = .now, plannedDrinks: Int, homeBy: Date, rideHome: RideHome) {
        self.startedAt = startedAt
        self.plannedDrinks = plannedDrinks
        self.homeBy = homeBy
        self.rideHomeRaw = rideHome.rawValue
    }
}

@Model
final class LogEntry {
    var timestamp: Date
    var kindRaw: String
    var drinkTypeRaw: String?
    /// Added the morning after, from the Last night page.
    var isLate: Bool = false
    var night: Night?

    init(kind: LogKind, type: DrinkType? = nil, timestamp: Date = .now, isLate: Bool = false) {
        self.kindRaw = kind.rawValue
        self.drinkTypeRaw = type?.rawValue
        self.timestamp = timestamp
        self.isLate = isLate
    }

    var kind: LogKind { LogKind(rawValue: kindRaw) ?? .drink }
    var drinkType: DrinkType? { drinkTypeRaw.flatMap(DrinkType.init(rawValue:)) }
}

// MARK: - Night helpers

extension Night {
    var rideHome: RideHome { RideHome(rawValue: rideHomeRaw) ?? .taxi }

    var sortedEntries: [LogEntry] { entries.sorted { $0.timestamp < $1.timestamp } }
    var drinkEntries: [LogEntry] { sortedEntries.filter { $0.kind == .drink } }
    var waterEntries: [LogEntry] { sortedEntries.filter { $0.kind == .water } }

    var drinkCount: Int { entries.filter { $0.kind == .drink }.count }
    var waterCount: Int { entries.filter { $0.kind == .water }.count }

    var lastDrinkAt: Date? { drinkEntries.last?.timestamp }

    var planReached: Bool { drinkCount >= plannedDrinks }
    var stuckToPlan: Bool { drinkCount <= plannedDrinks }

    var end: Date { endedAt ?? .now }
    var duration: TimeInterval { end.timeIntervalSince(startedAt) }

    var paceInterval: TimeInterval {
        Pacing.interval(start: startedAt, homeBy: homeBy, planned: plannedDrinks)
    }

    /// When the next drink fits the plan. `nil` once the plan is reached.
    var nextDrinkAt: Date? {
        guard !planReached else { return nil }
        guard let last = lastDrinkAt else { return startedAt }
        return last.addingTimeInterval(paceInterval)
    }

    /// Average minutes between drinks logged during the night (not ones added the morning after).
    var averageGapMinutes: Int? {
        Pacing.averageGapMinutes(drinkEntries.filter { !$0.isLate }.map(\.timestamp))
    }

    var dateTitle: String {
        startedAt.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var timeRange: String {
        "\(startedAt.formatted(date: .omitted, time: .shortened)) – \(end.formatted(date: .omitted, time: .shortened))"
    }

    // MARK: Amounts (use the sizes set in Settings > Drink sizes)

    func size(of entry: LogEntry, prefs: Preferences) -> DrinkSize {
        prefs.size(for: entry.drinkType ?? prefs.drinkTypes.first ?? .shot)
    }

    func totals(prefs: Preferences) -> (volume: Double, alcohol: Double) {
        drinkEntries.reduce((0, 0)) { sum, entry in
            let s = size(of: entry, prefs: prefs)
            return (sum.0 + s.ml, sum.1 + s.alcoholML)
        }
    }

    func bloodAlcohol(prefs: Preferences) -> BACEstimate {
        BloodAlcohol.estimate(
            doses: drinkEntries.map { ($0.timestamp, size(of: $0, prefs: prefs).alcoholML) },
            weightKg: Double(prefs.weightKg ?? 70),
            r: prefs.body.widmarkR,
            start: startedAt,
            end: end
        )
    }

    /// Rows for "Logged tonight" and the summary's "What you logged".
    func records(prefs: Preferences) -> [LogRecord] {
        var drinkNumber = 0
        var previous: Date?
        return sortedEntries.map { entry in
            let isDrink = entry.kind == .drink
            var note = ""
            var label = "Water"
            var amount: String?
            if isDrink {
                drinkNumber += 1
                note = previous.map { "\(Int(entry.timestamp.timeIntervalSince($0) / 60)) min after last" } ?? "First drink"
                previous = entry.timestamp
                label = "Drink \(drinkNumber)" + (entry.drinkType.map { " · \($0.buttonName)" } ?? "")
                let s = size(of: entry, prefs: prefs)
                amount = "\(prefs.volumeText(s.ml)) · \(prefs.volumeText(s.alcoholML)) alcohol"
            }
            if entry.isLate { note = "Added the morning after" }
            return LogRecord(
                id: entry.persistentModelID.hashValue,
                time: entry.timestamp.formatted(date: .omitted, time: .shortened),
                label: label,
                amount: amount,
                note: note,
                isDrink: isDrink
            )
        }
    }
}

struct LogRecord: Identifiable {
    let id: Int
    let time: String
    let label: String
    let amount: String?
    let note: String
    let isDrink: Bool
}
