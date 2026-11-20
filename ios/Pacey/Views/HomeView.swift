import SwiftUI
import SwiftData

/// Plan a night (quick starts, streak, plan card) or, during a night, a timer and what's been logged.
struct HomeView: View {
    let activeNight: Night?
    let endedNights: [Night]
    let onStarted: () -> Void
    let onShowTonight: () -> Void
    let onHelp: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    private enum PlanPicker: Identifiable {
        case homeBy, ride
        var id: Self { self }
    }

    @State private var picker: PlanPicker?
    @State private var logOpen = false

    var body: some View {
        VStack(spacing: 0) {
            TopBar(showHelp: activeNight != nil, onHelp: onHelp)
            if let night = activeNight {
                activeContent(night)
            } else {
                planContent
            }
        }
        .foregroundStyle(.white)
        .background(Color.paceyBackground)
        .sheet(item: $picker) { kind in
            switch kind {
            case .homeBy:
                TimeWheelSheet(title: "Home by", time: $settings.prefs.planHomeBy)
            case .ride:
                RideWheelSheet(title: "Getting home", ride: $settings.prefs.planRide)
            }
        }
    }

    // MARK: Planning (no scrolling on a normal-size phone)

    private var planContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greeting)
                        .font(.outfit(15, .medium))
                        .foregroundStyle(Color.paceySecondaryText)
                    AccentHeading(plain: "Going out", accent: "tonight?")
                }

                quickStart
                streakCard
                planCard

                Button("Start my night", action: startNight)
                    .buttonStyle(PillButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private var quickStart: some View {
        let prefs = settings.prefs
        return VStack(alignment: .leading, spacing: 10) {
            Text("Quick start")
                .font(.outfit(13, .semibold))
                .foregroundStyle(Color.paceySecondaryText)
            HStack(spacing: 8) {
                ForEach(PresetKind.allCases) { kind in
                    let preset = prefs.preset(kind)
                    let on = prefs.planDrinks == preset.drinks && prefs.planHomeBy == preset.homeBy && prefs.planRide == preset.ride
                    Button {
                        var p = settings.prefs
                        p.planDrinks = preset.drinks
                        p.planHomeBy = preset.homeBy
                        p.planRide = preset.ride
                        settings.prefs = p
                    } label: {
                        Text("\(kind.title) · \(preset.drinks)")
                            .font(.outfit(15, .bold))
                            .foregroundStyle(on ? Color.paceyBackground : .white)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(on ? Color.paceyMint : Color.paceyCard, in: Capsule())
                    }
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    private var streakCard: some View {
        let recent = Array(endedNights.prefix(5).reversed())
        var streak = 0
        for night in endedNights {
            if night.stuckToPlan { streak += 1 } else { break }
        }
        let label = streak == 0 ? "Start a new streak tonight" : "\(streak) \(streak == 1 ? "night" : "nights") in a row on plan"

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pace streak")
                    .font(.outfit(13, .semibold))
                    .foregroundStyle(Color.paceySecondaryText)
                Text(label).font(.outfit(17, .bold))
            }
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                ForEach(Array(recent.enumerated()), id: \.offset) { _, night in
                    CheckDot(filled: night.stuckToPlan, size: 22)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Last \(recent.count) nights: \(recent.filter(\.stuckToPlan).count) on plan")
        }
        .paceyCard(corner: 22, padding: 14)
    }

    private var planCard: some View {
        let prefs = settings.prefs
        let noun = prefs.drinkNounPlural
        return VStack(alignment: .leading, spacing: 16) {
            Text("Tonight's plan").font(.outfit(15, .semibold))

            planRow(icon: "wineglass", title: noun.prefix(1).uppercased() + String(noun.dropFirst())) {
                RoundStepper(
                    value: "\(prefs.planDrinks)",
                    valueFont: .outfit(30, .extraBold),
                    lessLabel: "One less",
                    moreLabel: "One more",
                    onLess: { settings.prefs.planDrinks = max(1, prefs.planDrinks - 1) },
                    onMore: { settings.prefs.planDrinks = min(12, prefs.planDrinks + 1) }
                )
            }
            planRow(icon: "moon", title: "Home by") {
                ValuePill(text: prefs.planHomeBy.label, highlighted: picker == .homeBy) { picker = .homeBy }
                    .accessibilityLabel("Home by \(prefs.planHomeBy.label). Change")
            }
            planRow(icon: "car", title: "Getting home") {
                ValuePill(text: prefs.planRide.title, highlighted: picker == .ride) { picker = .ride }
                    .accessibilityLabel("Getting home: \(prefs.planRide.title). Change")
            }
        }
        .paceyCard(corner: 26, padding: 18)
    }

    private func planRow<Trailing: View>(icon: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon)
            Text(title).font(.outfit(16, .semibold))
            Spacer(minLength: 8)
            trailing()
        }
    }

    private func startNight() {
        let prefs = settings.prefs
        let now = Date.now
        let night = Night(
            startedAt: now,
            plannedDrinks: prefs.planDrinks,
            homeBy: prefs.planHomeBy.nextDate(after: now),
            rideHome: prefs.planRide
        )
        context.insert(night)
        try? context.save()
        onStarted()

        Task {
            await Reminders.requestPermission()
            Reminders.reschedule(for: night, prefs: prefs)
        }
    }

    private var greeting: String {
        let weekday = Date.now.formatted(.dateTime.weekday(.wide))
        let hour = Calendar.current.component(.hour, from: .now)
        let part: String
        switch hour {
        case 5..<12: part = "morning"
        case 12..<17: part = "afternoon"
        case 17..<22: part = "evening"
        default: part = "night"
        }
        return "\(weekday) \(part)"
    }

    // MARK: During a night

    private func activeContent(_ night: Night) -> some View {
        let records = Array(night.records(prefs: settings.prefs).reversed())

        return VStack(spacing: 22) {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                VStack(spacing: 10) {
                    Text("Your night so far")
                        .font(.outfit(15, .semibold))
                        .foregroundStyle(Color.paceySecondaryText)
                    Text(elapsed(since: night.startedAt, now: timeline.date))
                        .font(.outfit(76, .extraBold))
                        .tracking(-2)
                        .monospacedDigit()
                        .foregroundStyle(Color.paceyMint)
                    Text("Started \(night.startedAt.formatted(date: .omitted, time: .shortened)) · home by \(night.homeBy.formatted(date: .omitted, time: .shortened))")
                        .font(.outfit(16))
                        .foregroundStyle(Color.paceyBodyText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { logOpen.toggle() }
                } label: {
                    HStack(spacing: 14) {
                        IconTile(systemName: "list.bullet", size: 44, corner: 14, foreground: .paceyMint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Logged tonight").font(.outfit(16, .bold))
                            Text("\(night.drinkCount) \(night.drinkCount == 1 ? "drink" : "drinks") · \(night.waterCount) water")
                                .font(.outfit(14))
                                .foregroundStyle(Color.paceySecondaryText)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.paceySecondaryText)
                            .rotationEffect(.degrees(logOpen ? 90 : 0))
                    }
                    .padding(.horizontal, 16)
                    .frame(minHeight: 68)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityValue(logOpen ? "Open" : "Closed")

                if logOpen {
                    CardDivider()
                    ScrollView {
                        VStack(spacing: 0) {
                            if records.isEmpty {
                                Text("Nothing logged yet. Tap + Drink or + Water on the Tonight tab.")
                                    .font(.outfit(15))
                                    .foregroundStyle(Color.paceySecondaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 16)
                            }
                            ForEach(Array(records.enumerated()), id: \.offset) { i, r in
                                if i > 0 { CardDivider() }
                                LogRow(record: r)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .frame(maxHeight: 236)
                }
            }
            .background(Color.paceyCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Button("Back to my night", action: onShowTonight)
                .buttonStyle(PillButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private func elapsed(since start: Date, now: Date) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(start) / 60))
        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }
}

/// One row of a night's log: dot, time, label with amount, gap note.
struct LogRow: View {
    let record: LogRecord

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(record.isDrink ? Color.paceyMint : Color.paceySky)
                .frame(width: 10, height: 10)
            Text(record.time)
                .font(.outfit(16, .extraBold))
                .monospacedDigit()
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(record.label).font(.outfit(15, .semibold))
                if let amount = record.amount {
                    Text(amount)
                        .font(.outfit(13, .semibold))
                        .foregroundStyle(Color.paceyMint)
                }
            }
            Spacer(minLength: 6)
            Text(record.note)
                .font(.outfit(13))
                .foregroundStyle(Color.paceySecondaryText)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }
}
