import SwiftUI

/// Every finished night, newest first. Tap one for its summary.
struct NightsView: View {
    let nights: [Night]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TopBar(showHelp: false, onHelp: {})
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AccentHeading(plain: "Your", accent: "nights")
                        Text(nights.isEmpty ? "Your nights will show here after you end one." : "Tap a night to see its summary.")
                            .font(.outfit(16))
                            .foregroundStyle(Color.paceyBodyText)

                        VStack(spacing: 10) {
                            ForEach(nights) { night in
                                NavigationLink {
                                    SummaryView(night: night, onClose: nil)
                                } label: {
                                    row(night)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                }
            }
            .foregroundStyle(.white)
            .background(Color.paceyBackground)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func row(_ night: Night) -> some View {
        HStack(spacing: 14) {
            IconTile(systemName: night.stuckToPlan ? "checkmark" : "moon", size: 44, corner: 14, foreground: .paceyMint)
            VStack(alignment: .leading, spacing: 2) {
                Text(night.dateTitle).font(.outfit(16, .semibold))
                Text((night.stuckToPlan ? "Stuck to your plan · " : "") + "\(night.drinkCount) of \(night.plannedDrinks) drinks")
                    .font(.outfit(14))
                    .foregroundStyle(Color.paceySecondaryText)
                Text(night.timeRange)
                    .font(.outfit(13))
                    .foregroundStyle(Color.paceySecondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.paceySecondaryText)
        }
        .paceyCard(corner: 22, padding: 14)
        .contentShape(Rectangle())
    }
}
