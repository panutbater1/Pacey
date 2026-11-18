import Foundation

// Pure logic shared by the screens. Foundation only, so it can be unit tested anywhere.

// MARK: - Drink types and sizes

enum DrinkType: String, CaseIterable, Codable, Identifiable {
    case shot, wine, beer, cocktail, other

    var id: String { rawValue }

    /// Name in lists, e.g. on the Drink type settings page.
    var label: String {
        switch self {
        case .shot: return "Shots"
        case .wine: return "Wine"
        case .beer: return "Beer"
        case .cocktail: return "Cocktails"
        case .other: return "Other"
        }
    }

    /// Short name on buttons and in logs, e.g. "+ Beer", "Drink 2 · Beer".
    var buttonName: String {
        switch self {
        case .shot: return "Shot"
        case .wine: return "Wine"
        case .beer: return "Beer"
        case .cocktail: return "Cocktail"
        case .other: return "Drink"
        }
    }

    var singular: String {
        switch self {
        case .shot: return "shot"
        case .wine: return "glass"
        case .beer: return "beer"
        case .cocktail: return "cocktail"
        case .other: return "drink"
        }
    }

    var plural: String {
        switch self {
        case .shot: return "shots"
        case .wine: return "glasses"
        case .beer: return "beers"
        case .cocktail: return "cocktails"
        case .other: return "drinks"
        }
    }

    var sizeHint: String {
        switch self {
        case .shot: return "A single shot, about 25 to 30 ml"
        case .wine: return "A standard glass, about 150 ml"
        case .beer: return "A bottle or can, about 330 ml"
        case .cocktail: return "Often more than one shot in each"
        case .other: return "Anything else, counted as one"
        }
    }

    var defaultSize: DrinkSize {
        switch self {
        case .shot: return DrinkSize(ml: 30, abv: 40)
        case .wine: return DrinkSize(ml: 150, abv: 12)
        case .beer: return DrinkSize(ml: 330, abv: 5)
        case .cocktail: return DrinkSize(ml: 200, abv: 15)
        case .other: return DrinkSize(ml: 250, abv: 5)
        }
    }

    /// Grams of sugar and other carbs per ml, for the calorie estimate.
    var carbsPerML: Double {
        switch self {
        case .shot: return 0
        case .wine: return 0.15
        case .beer: return 0.13
        case .cocktail: return 0.3
        case .other: return 0.12
        }
    }

    /// Step for the size stepper in Settings > Drink sizes.
    var volumeStep: Double {
        switch self {
        case .shot: return 5
        case .beer: return 10
        default: return 25
        }
    }
}

struct DrinkSize: Codable, Equatable {
    var ml: Double
    /// Alcohol by volume, in percent.
    var abv: Double

    var alcoholML: Double { ml * abv / 100 }

    /// About 7 kcal per gram of alcohol, plus the sugar in the drink.
    func kcal(carbsPerML: Double) -> Double {
        alcoholML * 0.789 * 7 + ml * carbsPerML
    }

    func clamped() -> DrinkSize {
        DrinkSize(
            ml: min(1000, max(10, ml)),
            abv: min(60, max(0.5, (abv * 2).rounded() / 2))
        )
    }
}

// MARK: - Getting home, body type, presets

enum RideHome: String, CaseIterable, Codable, Identifiable {
    case taxi, rideshare, publicTransport, lift, walking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .taxi: return "Taxi"
        case .rideshare: return "Rideshare"
        case .publicTransport: return "Public transport"
        case .lift: return "Lift from a friend"
        case .walking: return "Walking"
        }
    }
}

enum BodyType: String, CaseIterable, Codable, Identifiable {
    case female, male, unset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .unset: return "Not set"
        }
    }

    /// Widmark body water ratio.
    var widmarkR: Double {
        switch self {
        case .female: return 0.55
        case .male: return 0.68
        case .unset: return 0.6
        }
    }
}

/// A time of day, stored as hour and minute (minutes in 5-minute steps in the UI).
struct ClockTime: Codable, Equatable {
    var hour: Int
    var minute: Int

    var label: String { String(format: "%02d:%02d", hour, minute) }

    /// The next time this clock time happens after `start` (so 01:30 means after midnight).
    func nextDate(after start: Date, calendar: Calendar = .current) -> Date {
        var parts = calendar.dateComponents([.year, .month, .day], from: start)
        parts.hour = hour
        parts.minute = minute
        parts.second = 0
        let sameDay = calendar.date(from: parts) ?? start
        if sameDay > start { return sameDay }
        return calendar.date(byAdding: .day, value: 1, to: sameDay) ?? sameDay
    }
}

/// Quick starts, named after the kind of night so new people know which to pick.
/// (The raw values stay the same as version 1.0, so saved presets keep working.)
enum PresetKind: String, CaseIterable, Codable, Identifiable {
    case quiet, steady, usual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiet: return "Dinner & drinks"
        case .steady: return "Night out"
        case .usual: return "Big occasion"
        }
    }

    /// SF Symbol on the chip.
    var symbol: String {
        switch self {
        case .quiet: return "fork.knife"
        case .steady: return "moon"
        case .usual: return "star"
        }
    }

    /// The one recommended before someone's first night.
    static let recommended: PresetKind = .steady

    func defaultPreset(usualLimit: Int) -> QuickPreset {
        switch self {
        case .quiet: return QuickPreset(drinks: 2, homeBy: ClockTime(hour: 23, minute: 30), ride: .taxi)
        case .steady: return QuickPreset(drinks: usualLimit, homeBy: ClockTime(hour: 1, minute: 30), ride: .taxi)
        case .usual: return QuickPreset(drinks: usualLimit, homeBy: ClockTime(hour: 2, minute: 30), ride: .taxi)
        }
    }
}

struct QuickPreset: Codable, Equatable {
    var drinks: Int
    var homeBy: ClockTime
    var ride: RideHome
}

// MARK: - Preferences (everything set in onboarding and Settings)

struct Preferences: Codable, Equatable {
    var onboarded = false
    var name = ""
    var trustedFriend = ""

    /// Drinks on a usual night out. Set by the first-launch quiz, editable in Settings > Pace plan.
    var averageDrinks = 4

    var drinkTypes: [DrinkType] = [.shot]
    var currentType: DrinkType = .shot
    var sizes: [String: DrinkSize] = [:]
    var useOunces = false

    var presets: [String: QuickPreset] = [:]

    var weightKg: Int? = nil
    var body: BodyType = .unset

    var remindWater = true
    var remindNextDrink = true
    var remindHomeTime = true
    var remindPastPlan = true
    var waterFirst = true

    /// When the person ticked the Terms box on the first screen.
    var termsAcceptedAt: Date? = nil
    /// "Signed in with Apple", an email address, or nil without an account.
    var accountLabel: String? = nil
    /// Use weight and body type for the blood alcohol estimate (Settings › Data and privacy).
    var bodyConsent = true
    /// First-visit tips on Home: 1 to 3 while showing, 0 when done.
    var tipStep = 0
    /// Getting ready: the "Before you go" ticks and tonight's reason.
    var checklist: [String: Bool] = [:]
    var reason = ""
    /// After ending a night, the Tonight tab shows Last night until "Plan my night".
    var morningAfter = false
    /// Said "Yes, I'm sure" to a plan above 10 drinks.
    var bigPlanOK = false

    /// Tonight's plan as last set on Home.
    var planDrinks = 4
    var planHomeBy = ClockTime(hour: 1, minute: 30)
    var planRide: RideHome = .taxi

    init() {}

    // Tolerant decoding, so adding a setting in a later version never wipes the others.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Preferences()
        onboarded = (try? c.decodeIfPresent(Bool.self, forKey: .onboarded)) ?? d.onboarded
        name = (try? c.decodeIfPresent(String.self, forKey: .name)) ?? d.name
        trustedFriend = (try? c.decodeIfPresent(String.self, forKey: .trustedFriend)) ?? d.trustedFriend
        averageDrinks = (try? c.decodeIfPresent(Int.self, forKey: .averageDrinks)) ?? d.averageDrinks
        drinkTypes = (try? c.decodeIfPresent([DrinkType].self, forKey: .drinkTypes)) ?? d.drinkTypes
        currentType = (try? c.decodeIfPresent(DrinkType.self, forKey: .currentType)) ?? d.currentType
        sizes = (try? c.decodeIfPresent([String: DrinkSize].self, forKey: .sizes)) ?? d.sizes
        useOunces = (try? c.decodeIfPresent(Bool.self, forKey: .useOunces)) ?? d.useOunces
        presets = (try? c.decodeIfPresent([String: QuickPreset].self, forKey: .presets)) ?? d.presets
        weightKg = try? c.decodeIfPresent(Int.self, forKey: .weightKg)
        body = (try? c.decodeIfPresent(BodyType.self, forKey: .body)) ?? d.body
        remindWater = (try? c.decodeIfPresent(Bool.self, forKey: .remindWater)) ?? d.remindWater
        remindNextDrink = (try? c.decodeIfPresent(Bool.self, forKey: .remindNextDrink)) ?? d.remindNextDrink
        remindHomeTime = (try? c.decodeIfPresent(Bool.self, forKey: .remindHomeTime)) ?? d.remindHomeTime
        remindPastPlan = (try? c.decodeIfPresent(Bool.self, forKey: .remindPastPlan)) ?? d.remindPastPlan
        waterFirst = (try? c.decodeIfPresent(Bool.self, forKey: .waterFirst)) ?? d.waterFirst
        planDrinks = (try? c.decodeIfPresent(Int.self, forKey: .planDrinks)) ?? d.planDrinks
        planHomeBy = (try? c.decodeIfPresent(ClockTime.self, forKey: .planHomeBy)) ?? d.planHomeBy
        planRide = (try? c.decodeIfPresent(RideHome.self, forKey: .planRide)) ?? d.planRide
        termsAcceptedAt = try? c.decodeIfPresent(Date.self, forKey: .termsAcceptedAt)
        accountLabel = try? c.decodeIfPresent(String.self, forKey: .accountLabel)
        bodyConsent = (try? c.decodeIfPresent(Bool.self, forKey: .bodyConsent)) ?? d.bodyConsent
        tipStep = (try? c.decodeIfPresent(Int.self, forKey: .tipStep)) ?? d.tipStep
        checklist = (try? c.decodeIfPresent([String: Bool].self, forKey: .checklist)) ?? d.checklist
        reason = (try? c.decodeIfPresent(String.self, forKey: .reason)) ?? d.reason
        morningAfter = (try? c.decodeIfPresent(Bool.self, forKey: .morningAfter)) ?? d.morningAfter
        bigPlanOK = (try? c.decodeIfPresent(Bool.self, forKey: .bigPlanOK)) ?? d.bigPlanOK
        if drinkTypes.isEmpty { drinkTypes = [.shot] }
    }

    // MARK: Derived values

    /// Never above 4 and never above the person's average.
    var suggestedLimit: Int { max(1, min(4, averageDrinks)) }

    var paceProfile: String {
        averageDrinks <= 2 ? "Light" : averageDrinks <= 4 ? "Social" : "Regular"
    }

    /// The drink the + button logs: the current type if still selected, else the first selected.
    var activeType: DrinkType {
        drinkTypes.contains(currentType) ? currentType : (drinkTypes.first ?? .shot)
    }

    /// "shots" when one type is picked, "drinks" when several are.
    var drinkNounPlural: String {
        drinkTypes.count == 1 ? drinkTypes[0].plural : "drinks"
    }

    /// Singular or plural noun for a count, e.g. "1 shot", "3 drinks".
    func drinkNoun(_ count: Int) -> String {
        if count != 1 { return drinkNounPlural }
        return drinkTypes.count == 1 ? drinkTypes[0].singular : "drink"
    }

    /// Weight and body water ratio for the estimate; an average body if the person turned this off.
    var estimateWeightKg: Double { Double((bodyConsent ? weightKg : nil) ?? 70) }
    var estimateR: Double { bodyConsent ? body.widmarkR : BodyType.unset.widmarkR }

    func kcal(for type: DrinkType) -> Double {
        size(for: type).kcal(carbsPerML: type.carbsPerML)
    }

    /// The most drinks a plan can hold. Above 10 asks "Are you sure?" first.
    static let maxPlan = 99
    static let bigPlan = 10

    func size(for type: DrinkType) -> DrinkSize {
        sizes[type.rawValue] ?? type.defaultSize
    }

    mutating func setSize(_ size: DrinkSize, for type: DrinkType) {
        sizes[type.rawValue] = size.clamped()
    }

    /// Quick start presets; drinks can't go above the average.
    func preset(_ kind: PresetKind) -> QuickPreset {
        var p = presets[kind.rawValue] ?? kind.defaultPreset(usualLimit: suggestedLimit)
        p.drinks = max(1, min(averageDrinks, p.drinks))
        return p
    }

    mutating func setPreset(_ preset: QuickPreset, for kind: PresetKind) {
        var p = preset
        p.drinks = max(1, min(averageDrinks, p.drinks))
        presets[kind.rawValue] = p
    }

    mutating func toggleDrinkType(_ type: DrinkType) {
        if let i = drinkTypes.firstIndex(of: type) {
            guard drinkTypes.count > 1 else { return } // keep at least one
            drinkTypes.remove(at: i)
        } else {
            drinkTypes.append(type)
            drinkTypes.sort { DrinkType.allCases.firstIndex(of: $0)! < DrinkType.allCases.firstIndex(of: $1)! }
        }
    }

    func volumeText(_ ml: Double) -> String {
        useOunces ? String(format: "%.1f fl oz", ml / 29.574) : "\(Int(ml.rounded())) ml"
    }

    var weightText: String {
        let kg = weightKg ?? 70
        return useOunces ? "\(Int((Double(kg) * 2.2046).rounded())) lb" : "\(kg) kg"
    }
}

// MARK: - First-launch quiz

struct QuizResult: Equatable {
    var limit: Int
    var average: Int
    var profile: String
}

enum Quiz {
    static let goingOut = [
        ("Rarely", "A few times a year"),
        ("Now and then", "Once or twice a month"),
        ("Most weekends", "Around once a week"),
        ("More often", "More than once a week")
    ]
    static let usualDrinks = [
        ("1 to 2", "A couple over the evening"),
        ("3 to 4", "A few through the night"),
        ("5 to 6", "A fair few"),
        ("7 or more", "A big night")
    ]
    /// Question 4 (pick several): the drink types, in DrinkType order.
    static let drinkTypes: [(String, String)] = DrinkType.allCases.map { ($0.label, $0.sizeHint) }

    static let questionCount = 4

    static let priorities = [
        ("Staying sharp", "I want to feel fully in control"),
        ("Feeling fine tomorrow", "A good night without the rough morning"),
        ("Just keeping track", "I want to see my pace")
    ]

    /// The suggestion never goes above 4 drinks and never above what the person usually has.
    static func result(goingOut: Int, usual: Int, priority: Int) -> QuizResult {
        var limit = [2, 4, 4, 4][max(0, min(3, usual))]
        if priority == 0 { limit -= 1 }
        let profile = usual == 0 ? "Light" : (usual >= 2 || goingOut >= 2) ? "Regular" : "Social"
        return QuizResult(limit: max(1, limit), average: [2, 4, 6, 8][max(0, min(3, usual))], profile: profile)
    }
}

// MARK: - Pacing

enum Pacing {
    static let minimumInterval: TimeInterval = 30 * 60

    /// Planned drinks spread evenly between the start of the night and "home by".
    static func interval(start: Date, homeBy: Date, planned: Int) -> TimeInterval {
        max(minimumInterval, homeBy.timeIntervalSince(start) / Double(max(planned, 1)))
    }

    /// Average minutes between drinks, or nil with fewer than two.
    static func averageGapMinutes(_ times: [Date]) -> Int? {
        let sorted = times.sorted()
        guard sorted.count >= 2, let first = sorted.first, let last = sorted.last else { return nil }
        return Int((last.timeIntervalSince(first) / 60 / Double(sorted.count - 1)).rounded())
    }

    /// Planned drinks between `start` and a home-by clock time, e.g. for a quick start preview.
    static func intervalMinutes(from start: Date, homeBy: ClockTime, planned: Int, calendar: Calendar = .current) -> Int {
        Int((interval(start: start, homeBy: homeBy.nextDate(after: start, calendar: calendar), planned: planned) / 60).rounded())
    }

    /// "66 min" or "1 h 20 min".
    static func minutesText(_ minutes: Int) -> String {
        minutes >= 90 ? "\(minutes / 60) h \(minutes % 60) min" : "\(minutes) min"
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        let minutes = max(0, Int(seconds / 60))
        if minutes < 60 { return "\(minutes) min" }
        return String(format: "%d h %02d min", minutes / 60, minutes % 60)
    }

    /// Kind notification text when a drink reaches or passes the plan. `over` is 0 at the plan.
    static func limitMessage(over: Int, next: String) -> (title: String, body: String) {
        if over <= 0 {
            return ("You've reached your plan", "Nice pacing. Switch to water from here and enjoy the rest of the night.")
        }
        let messages: [(String, String)] = [
            ("One past your plan", "No stress. A glass of water now will make tomorrow a lot kinder."),
            ("Time for a water round?", "You are over your plan. Grab a water and check in with your friends."),
            ("How are you feeling?", "Still out there? Make sure your ride home is sorted before the next \(next)."),
            ("Look after yourself", "You are well past your plan. Water, some food and a sit-down would help right now."),
            ("Maybe call it a night?", "Heading home now means a better morning. Need a ride? Open Pacey.")
        ]
        return messages[min(over - 1, messages.count - 1)]
    }
}

// MARK: - Blood alcohol estimate

struct BACEstimate: Equatable {
    /// Highest estimated level, in percent (g/100 ml).
    var peak: Double
    var peakTime: Date
    /// Level every 5 minutes from start to end, for the curve.
    var series: [Double]

    var low: Double { peak * 0.8 }
    var high: Double { peak * 1.2 }

    var rangeText: String {
        peak < 0.005 ? "Below 0.01%" : String(format: "%.2f–%.2f%%", low, high)
    }
}

enum BloodAlcohol {
    static let eliminationPerHour = 0.015
    static let gramsPerML = 0.789

    /// Rough Widmark-style estimate: each drink adds grams / (weight × r), the body clears about 0.015% an hour.
    static func estimate(doses: [(time: Date, alcoholML: Double)], weightKg: Double, r: Double, start: Date, end: Date) -> BACEstimate {
        let step: TimeInterval = 5 * 60
        let perDose = doses.map { d -> (Date, Double) in
            let grams = d.alcoholML * gramsPerML
            return (min(d.time, end), grams / (weightKg * 1000 * r) * 100)
        }
        var level = 0.0
        var peak = 0.0
        var peakTime = start
        var series: [Double] = []
        var t = start
        var first = true
        while t <= end.addingTimeInterval(1) {
            level = max(0, level - eliminationPerHour * step / 3600)
            for (time, pct) in perDose {
                let inStep = time > t.addingTimeInterval(-step) && time <= t
                if inStep || (first && time < start) { level += pct }
            }
            first = false
            if level > peak { peak = level; peakTime = t }
            series.append(level)
            t = t.addingTimeInterval(step)
        }
        return BACEstimate(peak: peak, peakTime: peakTime, series: series)
    }
}
