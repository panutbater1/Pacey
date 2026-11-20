import SwiftUI
import SwiftData

/// The night in progress: glass, countdown, + Drink (with a drink switcher) and + Water.
struct DrinkModeView: View {
    let night: Night
    let onEnd: () -> Void
    let onHelp: () -> Void
    let onEditDrinkTypes: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    @State private var confirmEnd = false
    @State private var showWaterFirst = false
    @State private var animation: LogAnimation?

    var body: some View {
        VStack(spacing: 0) {
            TopBar(showHelp: true, onHelp: onHelp, onEndNight: { confirmEnd = true })
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                content(now: timeline.date)
            }
        }
        .foregroundStyle(.white)
        .background(Color.paceyBackground)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .overlay {
            if let animation {
                LogAnimationCard(animation: animation)
                    .id(animation.id)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.impact, trigger: night.entries.count)
        .confirmationDialog("End your night?", isPresented: $confirmEnd, titleVisibility: .visible) {
            Button("End night") { onEnd() }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("You'll see a summary of tonight.")
        }
        .sheet(isPresented: $showWaterFirst) { waterFirstSheet }
    }

    private var prefs: Preferences { settings.prefs }

    // MARK: Content

    private func content(now: Date) -> some View {
        let reached = night.planReached
        let accent: Color = reached ? .paceyOrange : .paceyMint

        return ScrollView {
            VStack(spacing: 14) {
                Text("\(now.formatted(date: .omitted, time: .shortened)) · home by \(night.homeBy.formatted(date: .omitted, time: .shortened))")
                    .font(.outfit(15, .medium))
                    .foregroundStyle(Color.paceySecondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AccentHeading(
                    plain: reached ? "Plan" : "Nice and",
                    accent: reached ? "reached" : "steady",
                    size: 36,
                    accentColor: accent
                )

                glassCard(accent: accent)
                paceCard(now: now, reached: reached)

                HStack(spacing: 10) {
                    waterCard
                    lastDrinkCard(now: now)
                }

                if !night.entries.isEmpty {
                    Button(action: undoLast) {
                        Label("Undo last entry", systemImage: "arrow.uturn.backward")
                            .font(.outfit(15, .semibold))
                            .foregroundStyle(Color.paceySecondaryText)
                            .frame(minHeight: 44)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func glassCard(accent: Color) -> some View {
        let level = min(1, Double(night.drinkCount) / Double(max(night.plannedDrinks, 1)))
        let totals = night.totals(prefs: prefs)

        return HStack(spacing: 24) {
            GlassView(level: level, fill: accent)
                .frame(width: 96, height: 120)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(night.drinkCount)")
                    .font(.outfit(56, .extraBold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy, value: night.drinkCount)
                Text("of \(night.plannedDrinks) \(prefs.drinkNounPlural)")
                    .font(.outfit(17, .semibold))
                    .foregroundStyle(Color.paceySecondaryText)
                Text(prefs.volumeText(totals.volume))
                    .font(.outfit(20, .extraBold))
                    .padding(.top, 8)
                Text("drunk · \(prefs.volumeText(totals.alcohol)) alcohol")
                    .font(.outfit(13))
                    .foregroundStyle(Color.paceySecondaryText)
            }
            Spacer(minLength: 0)
        }
        .paceyCard(corner: 26, padding: 18)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func paceCard(now: Date, reached: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if reached {
                Text("You've reached your plan")
                    .font(.outfit(20, .bold))
                    .foregroundStyle(Color.paceyOrange)
                Text("Switch to water from here.")
                    .font(.outfit(16))
                    .foregroundStyle(Color.paceyBodyText)
            } else if let next = night.nextDrinkAt, next > now {
                Text("Your next drink fits your plan in")
                    .font(.outfit(15, .semibold))
                    .foregroundStyle(Color.paceySecondaryText)
                Text(countdown(from: now, to: next))
                    .font(.outfit(44, .extraBold))
                    .monospacedDigit()
                ProgressBar(value: min(1, max(0, 1 - next.timeIntervalSince(now) / night.paceInterval)))
            } else {
                Text("Your next drink fits your plan now")
                    .font(.outfit(20, .bold))
                Text("No rush. Whenever you're ready.")
                    .font(.outfit(16))
                    .foregroundStyle(Color.paceyBodyText)
            }
        }
        .paceyCard(corner: 24, padding: 18)
        .accessibilityElement(children: .combine)
    }

    private var waterCard: some View {
        let target = max(1, night.drinkCount)
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Water")
                    .font(.outfit(13, .semibold))
                    .foregroundStyle(Color.paceySecondaryText)
                Text("\(night.waterCount)").font(.outfit(22, .extraBold))
            }
            Spacer(minLength: 0)
            // Fills towards one water per drink.
            CupView(level: min(1, Double(night.waterCount) / Double(target)))
                .frame(width: 34, height: 42)
        }
        .paceyCard(corner: 20, padding: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(night.waterCount) water for \(night.drinkCount) drinks")
    }

    private func lastDrinkCard(now: Date) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Last drink")
                .font(.outfit(13, .semibold))
                .foregroundStyle(Color.paceySecondaryText)
            Text(night.lastDrinkAt?.formatted(date: .omitted, time: .shortened) ?? "–")
                .font(.outfit(22, .extraBold))
                .monospacedDigit()
            Text(sinceLastDrink(now: now))
                .font(.outfit(13))
                .foregroundStyle(Color.paceySecondaryText)
        }
        .paceyCard(corner: 20, padding: 14)
        .accessibilityElement(children: .combine)
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        let reached = night.planReached
        let active = prefs.activeType

        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { log(.water) } label: { Text("+ Water") }
                    .buttonStyle(reached ? PillButtonStyle() : PillButtonStyle(fill: .paceyCard, foreground: .paceySky))

                HStack(spacing: 0) {
                    Button(action: tapDrink) {
                        Text("+ \(active.buttonName)")
                            .font(.outfit(18, .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.leading, 12)
                            .contentShape(Rectangle())
                    }
                    Rectangle()
                        .fill((reached ? Color.white : Color.paceyBackground).opacity(0.25))
                        .frame(width: 1, height: 30)
                    Menu {
                        Section("What are you drinking?") {
                            ForEach(prefs.drinkTypes) { type in
                                Button {
                                    settings.prefs.currentType = type
                                } label: {
                                    if type == active {
                                        Label(type.label, systemImage: "checkmark")
                                    } else {
                                        Text(type.label)
                                    }
                                }
                            }
                        }
                        Button("Edit drink types", action: onEditDrinkTypes)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 48)
                            .frame(maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Change drink type")
                }
                .foregroundStyle(reached ? Color.white : Color.paceyBackground)
                .frame(height: 62)
                .background(reached ? Color.paceyCard : Color.paceyMint, in: Capsule())
            }

            Button {
                Actions.bookTaxi()
            } label: {
                Label(night.rideHome == .taxi ? "Book a taxi" : "Ride home", systemImage: "car")
                    .font(.outfit(16, .semibold))
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color.paceyBackground)
    }

    // MARK: Water first

    private var waterFirstSheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            IconTile(systemName: "drop.fill", size: 56, corner: 18, foreground: .paceySky)
            AccentHeading(plain: "Water", accent: "first?", size: 30, accentColor: .paceySky)
            Text("You've reached your plan of \(night.plannedDrinks). A glass of water now keeps the night feeling good.")
                .font(.outfit(16))
                .foregroundStyle(Color.paceyBodyText)
            Button("Log a water") {
                showWaterFirst = false
                log(.water)
            }
            .buttonStyle(PillButtonStyle())
            Button("Log the \(prefs.activeType.singular) anyway") {
                showWaterFirst = false
                log(.drink)
            }
            .font(.outfit(16, .semibold))
            .foregroundStyle(Color.paceySecondaryText)
            .frame(maxWidth: .infinity, minHeight: 48)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.paceyCard)
    }

    // MARK: Logic

    private func tapDrink() {
        if prefs.waterFirst && night.planReached {
            showWaterFirst = true
        } else {
            log(.drink)
        }
    }

    private func log(_ kind: LogKind) {
        let type = prefs.activeType
        let entry = LogEntry(kind: kind, type: kind == .drink ? type : nil)
        context.insert(entry)
        entry.night = night
        try? context.save()
        Reminders.reschedule(for: night, prefs: prefs)

        let drinks = night.drinkCount
        let plan = night.plannedDrinks
        if kind == .drink && prefs.remindPastPlan && drinks >= plan {
            Reminders.notifyLimit(over: drinks - plan, nextDrinkName: type.singular)
        }

        // Calm, drink-specific animation. It confirms the log; it doesn't celebrate drinking.
        let waters = night.waterCount
        let next: LogAnimation
        if kind == .water {
            next = LogAnimation(
                style: .water,
                title: "Water logged",
                subtitle: waters == 1 ? "Your first water tonight. Nice." : "\(waters) waters tonight. Nice pacing."
            )
        } else {
            next = LogAnimation(
                style: LogAnimation.Style(type),
                title: "\(type.buttonName) logged",
                subtitle: drinks <= plan ? "\(drinks) of \(plan) tonight" : "That's \(drinks - plan) over your plan. Water next?"
            )
        }
        withAnimation(.easeOut(duration: 0.15)) { animation = next }
        let id = next.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.9))
            if animation?.id == id {
                withAnimation(.easeIn(duration: 0.2)) { animation = nil }
            }
        }
    }

    private func undoLast() {
        guard let last = night.sortedEntries.last else { return }
        night.entries.removeAll { $0.persistentModelID == last.persistentModelID }
        context.delete(last)
        try? context.save()
        Reminders.reschedule(for: night, prefs: prefs)
    }

    private func countdown(from now: Date, to next: Date) -> String {
        let seconds = max(0, Int(next.timeIntervalSince(now).rounded(.up)))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    private func sinceLastDrink(now: Date) -> String {
        guard let last = night.lastDrinkAt else { return "None yet" }
        let minutes = max(0, Int(now.timeIntervalSince(last) / 60))
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes) min ago" }
        return "\(minutes / 60) h \(minutes % 60) min ago"
    }
}

// MARK: - Glass and cup

/// A tumbler that fills from the bottom as drinks are logged.
struct GlassView: View {
    let level: Double
    let fill: Color
    var lineWidth: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.paceyTrack
                fill
                    .frame(height: geo.size.height * level)
                    .animation(.spring(duration: 0.5), value: level)
            }
            .animation(.easeInOut(duration: 0.3), value: fill)
            .clipShape(GlassShape(closed: true))
            .overlay {
                GlassShape(closed: false)
                    .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .padding(lineWidth / 2 + 1)
        .accessibilityHidden(true)
    }
}

/// The small water cup on the Water card.
struct CupView: View {
    let level: Double

    var body: some View {
        GlassView(level: level, fill: .paceySky, lineWidth: 3)
    }
}

struct GlassShape: Shape {
    /// Closed for clipping the fill, open at the top for the outline.
    let closed: Bool

    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.14
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        if closed { path.closeSubpath() }
        return path
    }
}

struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.paceyTile)
                Capsule()
                    .fill(LinearGradient.paceyProgress)
                    .frame(width: max(10, geo.size.width * value))
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}
