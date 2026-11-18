import SwiftUI

/// Shown after "End night", and from the Nights tab.
struct SummaryView: View {
    let night: Night
    /// Set when shown full screen after ending a night; nil when pushed from the Nights list.
    let onClose: (() -> Void)?

    @EnvironmentObject private var settings: AppSettings

    private var prefs: Preferences { settings.prefs }

    var body: some View {
        VStack(spacing: 0) {
            if let onClose {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(Color.paceyCard, in: Circle())
                    }
                    .accessibilityLabel("Back")
                    Spacer()
                    header
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if onClose == nil {
                        header.frame(maxWidth: .infinity)
                    }
                    planCard
                    durationCard
                    amountCards
                    bloodAlcoholCard
                    statCards
                    hourBars
                    logged
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .foregroundStyle(.white)
        .background(Color.paceyBackground.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("Night summary").font(.outfit(18, .bold))
            Text("\(night.startedAt.formatted(.dateTime.weekday(.wide))) · \(night.timeRange)")
                .font(.outfit(13, .medium))
                .foregroundStyle(Color.paceySecondaryText)
        }
    }

    // MARK: Cards

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            IconTile(systemName: night.stuckToPlan ? "checkmark" : "moon.stars", size: 60, corner: 18,
                     fill: .paceyMint, foreground: .paceyBackground)
            if night.stuckToPlan {
                AccentHeading(plain: "You stuck to your", accent: "plan", size: 36)
            } else {
                AccentHeading(plain: "That's a", accent: "wrap", size: 36)
            }
            Text(message)
                .font(.outfit(16))
                .foregroundStyle(Color.paceyBodyText)
                .lineSpacing(3)
            Text("Your plan · \(night.drinkCount) of \(night.plannedDrinks) drinks")
                .font(.outfit(13, .semibold))
                .foregroundStyle(Color.paceySecondaryText)
            FlowDots(planned: night.plannedDrinks, had: night.drinkCount)
        }
        .paceyCard(corner: 26, padding: 18)
    }

    private var durationCard: some View {
        HStack(spacing: 14) {
            IconTile(systemName: "timer", size: 44, corner: 14, foreground: .paceyMint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your night lasted")
                    .font(.outfit(13, .semibold))
                    .foregroundStyle(Color.paceySecondaryText)
                Text(Pacing.durationText(night.duration)).font(.outfit(24, .extraBold))
            }
            Spacer(minLength: 8)
            Text(night.timeRange)
                .font(.outfit(14, .semibold))
                .foregroundStyle(Color.paceyBodyText)
        }
        .paceyCard(corner: 22, padding: 14)
        .accessibilityElement(children: .combine)
    }

    private var amountCards: some View {
        let totals = night.totals(prefs: prefs)
        return HStack(spacing: 10) {
            stat("You drank", prefs.volumeText(totals.volume), note: "all drinks together")
            stat("Alcohol in it", prefs.volumeText(totals.alcohol), note: "estimate from your sizes", color: .paceyMint)
        }
    }

    private var bloodAlcoholCard: some View {
        let estimate = night.bloodAlcohol(prefs: prefs)
        let top = max(0.08, estimate.peak * 1.25)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Estimated blood alcohol").font(.outfit(15, .semibold))
                Spacer()
                Text("Estimate only")
                    .font(.outfit(12, .bold))
                    .foregroundStyle(Color.paceyBodyText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.paceyTile, in: Capsule())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(estimate.rangeText).font(.outfit(30, .extraBold))
                Text(estimate.peak < 0.005 ? "Very little alcohol that night"
                     : "Highest point, around \(estimate.peakTime.formatted(date: .omitted, time: .shortened))")
                    .font(.outfit(14))
                    .foregroundStyle(Color.paceySecondaryText)
            }
            ZStack {
                BACCurve(values: estimate.series, top: top, closed: true)
                    .fill(LinearGradient(colors: [Color.paceyMint.opacity(0.45), Color.paceyMint.opacity(0)],
                                         startPoint: .top, endPoint: .bottom))
                BACCurve(values: estimate.series, top: top, closed: false)
                    .stroke(Color.paceyMint, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
            .frame(height: 84)
            .accessibilityHidden(true)
            HStack {
                Text(night.startedAt.formatted(date: .omitted, time: .shortened))
                Spacer()
                Text(night.end.formatted(date: .omitted, time: .shortened))
            }
            .font(.outfit(12))
            .foregroundStyle(Color.paceySecondaryText)

            Text("A rough guess from your drinks, sizes, weight and body type. Your real level can be much higher. It can't tell you if you're safe to drive, so don't drive after drinking.")
                .font(.outfit(13))
                .foregroundStyle(Color.paceyBodyText)
                .lineSpacing(2)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.paceyTrack, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if prefs.weightKg == nil {
                Text("Using an average body. Add your weight in Settings › Profile for a better estimate.")
                    .font(.outfit(14, .semibold))
                    .foregroundStyle(Color.paceyMint)
            }
        }
        .paceyCard(corner: 24, padding: 16)
    }

    private var statCards: some View {
        HStack(spacing: 10) {
            stat("Drinks", "\(night.drinkCount)")
            stat("Water", "\(night.waterCount)")
            stat("Pace", night.averageGapMinutes.map { "\($0) min" } ?? "–", note: "between drinks")
        }
    }

    private func stat(_ title: String, _ value: String, note: String? = nil, color: Color = .white) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.outfit(13, .semibold))
                .foregroundStyle(Color.paceySecondaryText)
            Text(value)
                .font(.outfit(24, .extraBold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let note {
                Text(note)
                    .font(.outfit(12))
                    .foregroundStyle(Color.paceySecondaryText)
            }
        }
        .paceyCard(corner: 20, padding: 12)
        .accessibilityElement(children: .combine)
    }

    private struct HourBucket: Identifiable {
        let id: Date
        let drinks: Int
        let water: Int
    }

    /// One bucket per clock hour from the start of the night to its end (8 at most).
    private var buckets: [HourBucket] {
        let calendar = Calendar.current
        var start = calendar.dateInterval(of: .hour, for: night.startedAt)?.start ?? night.startedAt
        var result: [HourBucket] = []
        while start <= night.end && result.count < 8 {
            let end = start.addingTimeInterval(3600)
            let inHour = night.entries.filter { $0.timestamp >= start && $0.timestamp < end }
            result.append(HourBucket(id: start,
                                     drinks: inHour.filter { $0.kind == .drink }.count,
                                     water: inHour.filter { $0.kind == .water }.count))
            start = end
        }
        return result
    }

    private var hourBars: some View {
        let hours = buckets
        let busiest = max(4, hours.map { $0.drinks + $0.water }.max() ?? 0)

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your night, hour by hour").font(.outfit(15, .semibold))
                Spacer()
                legend("Drinks", .paceyMint)
                legend("Water", .paceySky)
            }
            ForEach(hours) { hour in
                HStack(spacing: 12) {
                    Text(hour.id.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)))
                        .font(.outfit(14, .semibold))
                        .foregroundStyle(Color.paceyBodyText)
                        .frame(width: 46, alignment: .leading)
                    GeometryReader { geo in
                        let width = geo.size.width - 6
                        HStack(spacing: 3) {
                            if hour.drinks > 0 {
                                Capsule().fill(Color.paceyMint)
                                    .frame(width: max(8, width * CGFloat(hour.drinks) / CGFloat(busiest) - 2))
                            }
                            if hour.water > 0 {
                                Capsule().fill(Color.paceySky)
                                    .frame(width: max(8, width * CGFloat(hour.water) / CGFloat(busiest) - 2))
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(3)
                        .frame(maxHeight: .infinity)
                        .background(Color.paceyTile, in: Capsule())
                    }
                    .frame(height: 26)
                    HStack(spacing: 8) {
                        Text("\(hour.drinks)").foregroundStyle(Color.paceyMint)
                        Text("\(hour.water)").foregroundStyle(Color.paceySky)
                    }
                    .font(.outfit(14, .extraBold))
                    .frame(width: 44, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(hour.id.formatted(date: .omitted, time: .shortened)): \(hour.drinks) drinks, \(hour.water) water")
            }
        }
        .paceyCard(corner: 24, padding: 16)
    }

    private func legend(_ title: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(title).font(.outfit(13)).foregroundStyle(Color.paceySecondaryText)
        }
    }

    private var logged: some View {
        let records = night.records(prefs: prefs)
        return VStack(alignment: .leading, spacing: 10) {
            Text("What you logged").font(.outfit(22, .extraBold)).tracking(-0.3)
            if records.isEmpty {
                Text("Nothing was logged that night.")
                    .font(.outfit(15))
                    .foregroundStyle(Color.paceySecondaryText)
                    .paceyCard(corner: 22, padding: 16)
            }
            ForEach(records) { r in
                HStack(spacing: 14) {
                    IconTile(systemName: r.isDrink ? "wineglass" : "drop", size: 44, corner: 22,
                             foreground: r.isDrink ? .paceyMint : .paceySky)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.time).font(.outfit(18, .bold))
                        Text(r.label).font(.outfit(14)).foregroundStyle(Color.paceySecondaryText)
                        if let amount = r.amount {
                            Text(amount).font(.outfit(13, .semibold)).foregroundStyle(Color.paceyMint)
                        }
                    }
                    Spacer(minLength: 8)
                    Text(r.note)
                        .font(.outfit(14, .semibold))
                        .foregroundStyle(Color.paceyBodyText)
                        .multilineTextAlignment(.trailing)
                }
                .paceyCard(corner: 22, padding: 14)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var message: String {
        let water = "Have a glass of water before bed."
        if night.drinkCount == 0 { return "No drinks that night. \(water)" }
        if night.stuckToPlan {
            let hours = max(1, night.duration / 3600)
            let spread = Double(night.drinkCount) / hours <= 1.25 ? ", nicely spread out" : ""
            return "\(night.drinkCount) of \(night.plannedDrinks) drinks\(spread). \(water)"
        }
        return "\(night.drinkCount) drinks on a plan of \(night.plannedDrinks). It happens, and tomorrow is a fresh start. \(water)"
    }
}

/// One circle per planned drink, ticked for each drink had; drinks over the plan are orange.
private struct FlowDots: View {
    let planned: Int
    let had: Int

    var body: some View {
        let total = max(planned, had)
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 34, maximum: 34), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                CheckDot(filled: i < had, color: i < planned ? .paceyDeepGreen : .paceyOrange)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(had) of \(planned) drinks")
    }
}

/// The estimated blood alcohol curve across the night.
struct BACCurve: Shape {
    let values: [Double]
    let top: Double
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 1 else { return path }
        let span = CGFloat(values.count - 1)
        let points = values.enumerated().map { i, v in
            CGPoint(x: rect.minX + rect.width * CGFloat(i) / span,
                    y: rect.maxY - 4 - (rect.height - 8) * CGFloat(min(1, v / top)))
        }
        path.addLines(points)
        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}
