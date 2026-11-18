import SwiftUI

/// First launch: confirm legal drinking age and show the short disclaimer.
struct AgeGateView: View {
    let onConfirm: () -> Void

    @State private var underAge = false

    private let age = RegionRules.legalDrinkingAge

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityHidden(true)
                .padding(.top, 40)

            if underAge {
                AccentHeading(plain: "See you", accent: "later")
                Text("Pacey is only for people of legal drinking age. Thanks for being honest.")
                    .font(.outfit(17))
                    .foregroundStyle(Color.paceyBodyText)
                    .lineSpacing(4)

                Spacer()

                Button("Go back") { underAge = false }
                    .buttonStyle(PillButtonStyle(fill: .paceyCard, foreground: .white))
            } else {
                AccentHeading(plain: "Welcome to", accent: "Pacey")
                Text("Pacey helps you pace one night out, so you have a good time and get home feeling fine.")
                    .font(.outfit(17))
                    .foregroundStyle(Color.paceyBodyText)
                    .lineSpacing(4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Before you start")
                        .font(.outfit(15, .semibold))
                    Text("Pacey is not medical advice and can't measure your blood alcohol. Never use it to decide whether you're safe to drive.")
                        .font(.outfit(15))
                        .foregroundStyle(Color.paceySecondaryText)
                        .lineSpacing(3)
                }
                .paceyCard(corner: 22)

                Spacer()

                Button("I'm \(age) or older") { onConfirm() }
                    .buttonStyle(PillButtonStyle())

                Button("I'm under \(age)") { underAge = true }
                    .font(.outfit(16, .semibold))
                    .foregroundStyle(Color.paceySecondaryText)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    AgeGateView {}
        .background(Color.paceyBackground)
}
