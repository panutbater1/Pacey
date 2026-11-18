import SwiftUI

/// Need help? Always free, reachable from Home, Drink mode and Settings.
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var location = LocationFetcher()

    private let urgentSigns = [
        "Can't be woken up, or keeps passing out",
        "Slow or irregular breathing",
        "Being sick while drowsy or unconscious",
        "Pale, bluish or cold, clammy skin",
        "A seizure or fit",
        "Very confused or can't stand up"
    ]

    private let whileWaiting = [
        "Stay with them. Never leave them alone.",
        "Keep them sitting up and awake if you can.",
        "If they're lying down, roll them onto their side.",
        "Keep them warm.",
        "If they're awake, offer small sips of water.",
        "No coffee, no cold shower, no more alcohol, and don't make them sick."
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .frame(width: 44, height: 44)
                            .background(Color.paceyCard, in: Circle())
                    }
                    .accessibilityLabel("Close")
                }

                AccentHeading(plain: "Need", accent: "help?")

                Button {
                    Actions.callEmergencyServices()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 22, weight: .semibold))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Call emergency services")
                                .font(.outfit(19, .bold))
                            Text("Calls \(RegionRules.emergencyNumber)")
                                .font(.outfit(14, .medium))
                                .opacity(0.85)
                        }
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity, minHeight: 84)
                    .background(Color.paceyRed, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                }

                VStack(spacing: 10) {
                    actionRow(
                        icon: "location",
                        title: "Send my location to a friend",
                        subtitle: location.isFetching ? "Finding you…" : "Opens a message you can send"
                    ) {
                        Task {
                            let found = await location.current()
                            Actions.messageFriend(location: found)
                        }
                    }
                    .disabled(location.isFetching)

                    actionRow(
                        icon: "car",
                        title: "Get a ride home",
                        subtitle: "Find a taxi nearby"
                    ) {
                        Actions.bookTaxi()
                    }
                }

                listCard(title: "Signs someone needs urgent help", items: urgentSigns, bullet: .paceySoftRed)
                listCard(title: "While you wait for help", items: whileWaiting, bullet: .paceyMint)

                Text("If you're not sure, call. Pacey is not medical advice.")
                    .font(.outfit(14))
                    .foregroundStyle(Color.paceySecondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .foregroundStyle(.white)
        .background(Color.paceyBackground.ignoresSafeArea())
    }

    private func actionRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                IconTile(systemName: icon, size: 44, corner: 14)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.outfit(16, .semibold))
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.outfit(14))
                        .foregroundStyle(Color.paceySecondaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.paceySecondaryText)
            }
            .paceyCard(corner: 22, padding: 14)
        }
        .buttonStyle(.plain)
    }

    private func listCard(title: String, items: [String], bullet: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.outfit(16, .bold))
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Circle()
                        .fill(bullet)
                        .frame(width: 7, height: 7)
                        .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 3 }
                    Text(item)
                        .font(.outfit(15))
                        .foregroundStyle(Color.paceyBodyText)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .paceyCard(corner: 24, padding: 18)
    }
}

#Preview {
    HelpView()
}
