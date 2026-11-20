import Foundation

// Numbers for the Nights tab: weeks, months, all time, the graphs and the tip on Getting ready.
// Foundation only, so it can be unit tested anywhere.

/// The plain facts about one finished night that the Nights tab needs.
struct NightFacts: Equatable {
    var start: Date
    var drinks: Int
    var planned: Int
    var water: Int
    var alcoholML: Double
    var kcal: Double
    /// Average minutes between drinks logged during the night, nil with fewer than two.
    var gapMinutes: Double?
    /// Logged a water within the first hour.
    var earlyWater: Bool

    var onPlan: Bool { drinks <= planned }
}

struct PeriodStats: Equatable {
    var nights: Int
    var drinks: Int
    var water: Int
    var alcoholML: Double
    var kcal: Double
    var onPlan: Int
    /// Most nights in a row on plan, oldest to newest.
    var bestStreak: Int
    /// Average minutes between drinks, nil when no night had two drinks.
    var paceMinutes: Int?

    var perNight: Double { nights == 0 ? 0 : (Double(drinks) / Double(nights) * 10).rounded() / 10 }
    var onPlanPercent: Int { nights == 0 ? 0 : Int((Double(onPlan) / Double(nights) * 100).rounded()) }

    init(_ list: [NightFacts]) {
        let chrono = list.sorted { $0.start < $1.start }
        nights = list.count
        drinks = list.reduce(0) { $0 + $1.drinks }
        water = list.reduce(0) { $0 + $1.water }
        alcoholML = list.reduce(0) { $0 + $1.alcoholML }
        kcal = list.reduce(0) { $0 + $1.kcal }
        onPlan = list.filter(\.onPlan).count
        var best = 0
        var run = 0
        for night in chrono {
            run = night.onPlan ? run + 1 : 0
            best = max(best, run)
        }
        bestStreak = best
        let gaps = list.compactMap(\.gapMinutes)
        paceMinutes = gaps.isEmpty ? nil : Int((gaps.reduce(0, +) / Double(gaps.count)).rounded())
    }
}

/// A week (starting Monday) or a calendar month, with the indexes of its nights.
struct Period: Equatable {
    var start: Date
    var indexes: [Int]
}

enum History {
    /// A Monday-first Gregorian calendar in the phone's time zone.
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        return c
    }

    /// Groups nights by week or month, newest period first. Indexes point into `nights`.
    static func periods(_ nights: [NightFacts], by component: Calendar.Component, calendar: Calendar = History.calendar) -> [Period] {
        var map: [Date: [Int]] = [:]
        for (i, night) in nights.enumerated() {
            let start = calendar.dateInterval(of: component == .month ? .month : .weekOfYear, for: night.start)?.start ?? night.start
            map[start, default: []].append(i)
        }
        return map.keys.sorted(by: >).map { Period(start: $0, indexes: map[$0] ?? []) }
    }

    static func stats(_ period: Period, in nights: [NightFacts]) -> PeriodStats {
        PeriodStats(period.indexes.map { nights[$0] })
    }

    /// One tip for Getting ready, from what worked on past nights.
    static func tip(_ nights: [NightFacts]) -> String {
        let withEarly = nights.filter(\.earlyWater)
        if withEarly.count >= 2 && withEarly.allSatisfy(\.onPlan) {
            return "You stayed on plan every night you had a water in the first hour."
        }
        func average(_ xs: [Double]) -> Int? {
            xs.isEmpty ? nil : Int((xs.reduce(0, +) / Double(xs.count)).rounded())
        }
        let onGap = average(nights.filter(\.onPlan).compactMap(\.gapMinutes))
        let offGap = average(nights.filter { !$0.onPlan }.compactMap(\.gapMinutes))
        if let onGap, let offGap, onGap > offGap {
            return "On nights you kept to your plan, your drinks were about \(onGap) min apart. Over-plan nights were closer to \(offGap) min."
        }
        return "Log a water early in the night. It makes the rest of the night easier to pace."
    }

    /// "1,234"
    static func number(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "en_GB")
        return f.string(from: NSNumber(value: value.rounded())) ?? "\(Int(value.rounded()))"
    }

    static func kcalText(_ value: Double) -> String { number(value) + " kcal" }

    /// "1.5" or "2"
    static func oneDecimal(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

/// A point on one of the Nights graphs.
struct ChartPoint: Identifiable, Equatable {
    let id: Int
    let label: String
    let value: Int
    let detail: String
    /// Only on the All time graph: whether the night was on plan.
    var onPlan: Bool? = nil
}
