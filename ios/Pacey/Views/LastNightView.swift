import SwiftUI
import SwiftData

/// The Tonight tab when no night is running: a morning check-in and a fix-up for anything not logged.
struct LastNightView: View {
    let lastNight: Night?
    let onShowSummary: (Night) -> Void
    let onPlan: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    private let feelings: [(String, String)] = [
        ("Great", "Good to hear. Pacing did its job."),
        ("OK", "Not bad. A big glass of water and some breakfast will help."),
        ("Rough", "Sorry it's a rough one. Water, food and rest today. A lower limit next time might feel better.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TopBar(showHelp: false, onHelp: {})
            if let night = lastNight {
                content(night)
            } else {
                empty
            }
        }
        .foregroundStyle(.white)
        .background(Color.paceyBackground)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 16) {
            AccentHeading(plain: "No nights", accent: "yet")
            Text("Once you've had a night out with Pacey, you can check in here the morning after.")
                .font(.outfit(17))
                .foregroundStyle(Color.paceyBodyText)
            Spacer()
            Button("Plan my night", action: onPlan)
                .buttonStyle(PillButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private func content(_ night: Night) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(night.dateTitle) · \(night.timeRange)")
                        .font(.outfit(15, .medium))
                        .foregroundStyle(Color.paceySecondaryText)
                    AccentHeading(plain: "Your last", accent: "night")
                }

                checkIn(night)
                fixUp(night)

                HStack(spacing: 12) {
                    Text(summaryLine(night))
                        .font(.outfit(15, .semibold))
                    Spacer(minLength: 8)
                    Button("Full summary") { onShowSummary(night) }
                        .buttonStyle(ChipButtonStyle())
                }
                .paceyCard(corner: 22, padding: 14)

                Button("Plan my night", action: onPlan)
                    .buttonStyle(PillButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func checkIn(_ night: Night) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Morning check-in")
                .font(.outfit(13, .semibold))
                .foregroundStyle(Color.paceySecondaryText)
            Text("How are you feeling today?").font(.outfit(18, .bold))
            HStack(spacing: 8) {
                ForEach(Array(feelings.enumerated()), id: \.offset) { _, feeling in
                    let on = night.feel == feeling.0
                    Button {
                        night.feel = feeling.0
                        try? context.save()
                    } label: {
                        Text(feeling.0)
                            .font(.outfit(15, .bold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.paceyTile, in: Capsule())
                            .overlay(Capsule().strokeBorder(on ? Color.paceyMint : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            if let message = feelings.first(where: { $0.0 == night.feel })?.1 {
                Text(message)
                    .font(.outfit(15))
                    .foregroundStyle(Color.paceyBodyText)
            }
        }
        .paceyCard(corner: 26, padding: 18)
    }

    private func fixUp(_ night: Night) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Forgot to log something?").font(.outfit(18, .bold))
                Text("Fix the count here so your summary is right.")
                    .font(.outfit(14))
                    .foregroundStyle(Color.paceySecondaryText)
            }
            fixRow(icon: "wineglass", color: .paceyMint, title: "Drinks", count: night.drinkCount,
                   onLess: { removeLast(.drink, from: night) }, onMore: { addLate(.drink, to: night) })
            fixRow(icon: "drop", color: .paceySky, title: "Water", count: night.waterCount,
                   onLess: { removeLast(.water, from: night) }, onMore: { addLate(.water, to: night) })
        }
        .paceyCard(corner: 26, padding: 18)
    }

    private func fixRow(icon: String, color: Color, title: String, count: Int, onLess: @escaping () -> Void, onMore: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon, foreground: color)
            Text(title).font(.outfit(16, .semibold))
            Spacer()
            RoundStepper(value: "\(count)", lessLabel: "Remove one \(title.lowercased()) from last night",
                         moreLabel: "Add one \(title.lowercased()) to last night", onLess: onLess, onMore: onMore)
        }
    }

    private func addLate(_ kind: LogKind, to night: Night) {
        let entry = LogEntry(kind: kind, type: kind == .drink ? settings.prefs.activeType : nil,
                             timestamp: night.end, isLate: true)
        context.insert(entry)
        entry.night = night
        try? context.save()
    }

    private func removeLast(_ kind: LogKind, from night: Night) {
        guard let last = night.sortedEntries.last(where: { $0.kind == kind }) else { return }
        night.entries.removeAll { $0.persistentModelID == last.persistentModelID }
        context.delete(last)
        try? context.save()
    }

    private func summaryLine(_ night: Night) -> String {
        let count = "\(night.drinkCount) of \(night.plannedDrinks) drinks"
        return night.stuckToPlan ? "Stuck to your plan · \(count)" : count
    }
}
