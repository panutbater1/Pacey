import SwiftUI

/// First launch only: age gate, a short quiz, the suggested plan and how Pacey works.
/// The quiz can't be taken again; the average is changed later in Settings > Pace plan.
struct OnboardingFlow: View {
    @EnvironmentObject private var settings: AppSettings

    private enum Step: Equatable {
        case age, quiz(Int), result, overview
    }

    @State private var step: Step = .age
    @State private var answers: [Int?] = [nil, nil, nil]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                switch step {
                case .age:
                    AgeGateView { step = .quiz(0) }
                case .quiz(let index):
                    quiz(index)
                case .result:
                    result
                case .overview:
                    overview
                }
            }
            .transition(.opacity)

            #if DEBUG
            // Development builds only: never in an App Store build.
            Button("Skip setup · debug only") {
                var p = settings.prefs
                p.averageDrinks = 4
                p.planDrinks = 4
                p.onboarded = true
                settings.prefs = p
            }
            .font(.outfit(13, .bold))
            .foregroundStyle(Color.paceyAmber)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .overlay(Capsule().strokeBorder(Color.paceyAmber, style: StrokeStyle(lineWidth: 1.5, dash: [4])))
            .padding(.trailing, 12)
            .padding(.top, 4)
            #endif
        }
        .animation(.easeInOut(duration: 0.2), value: step)
        .foregroundStyle(.white)
    }

    // MARK: Quiz

    private func quiz(_ index: Int) -> some View {
        let questions: [(String, String, String, [(String, String)])] = [
            ("How often do you", "go out?", "There are no wrong answers. This only sets your starting plan.", Quiz.goingOut),
            ("On a usual night, how", "many drinks?", "A rough guess is fine.", Quiz.usualDrinks),
            ("What matters most", "on a night out?", "Pick the one that fits you best.", Quiz.priorities)
        ]
        let q = questions[index]

        return VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Button {
                    step = index == 0 ? .age : .quiz(index - 1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Color.paceyCard, in: Circle())
                }
                .accessibilityLabel("Back")
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question \(index + 1) of 3")
                        .font(.outfit(14, .semibold))
                        .foregroundStyle(Color.paceySecondaryText)
                    ProgressBar(value: Double(index + 1) / 3)
                }
            }
            .padding(.top, 48)

            AccentHeading(plain: q.0, accent: q.1, size: 34)
            Text(q.2)
                .font(.outfit(16))
                .foregroundStyle(Color.paceyBodyText)

            VStack(spacing: 10) {
                ForEach(Array(q.3.enumerated()), id: \.offset) { i, option in
                    Button {
                        answers[index] = i
                        step = index < 2 ? .quiz(index + 1) : .result
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.0).font(.outfit(17, .bold))
                            Text(option.1)
                                .font(.outfit(14))
                                .foregroundStyle(Color.paceySecondaryText)
                        }
                        .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
                        .padding(.horizontal, 18)
                        .background(Color.paceyCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(answers[index] == i ? Color.paceyMint : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: Result

    private var quizResult: QuizResult {
        Quiz.result(goingOut: answers[0] ?? 0, usual: answers[1] ?? 1, priority: answers[2] ?? 1)
    }

    private var result: some View {
        let r = quizResult
        let usual = answers[1] ?? 1
        let drinks = r.limit == 1 ? "1 drink" : "\(r.limit) drinks"

        return VStack(alignment: .leading, spacing: 20) {
            IconTile(systemName: "wineglass", size: 60, corner: 18, fill: .paceyMint, foreground: .paceyBackground)
                .padding(.top, 64)
            Text("Your suggested plan")
                .font(.outfit(15, .medium))
                .foregroundStyle(Color.paceySecondaryText)
            AccentHeading(plain: "A limit of", accent: drinks)
            Text(usual >= 2
                 ? "That is under your usual, which is the point: a steadier night and an easier morning."
                 : "That fits how you usually go out. Pacey spreads it evenly across your night.")
                .font(.outfit(17))
                .foregroundStyle(Color.paceyBodyText)
                .lineSpacing(4)

            VStack(spacing: 0) {
                CardRow(title: "Your pace profile", minHeight: 52) {
                    Text(r.profile).font(.outfit(16, .bold)).foregroundStyle(Color.paceyMint)
                }
                CardDivider()
                CardRow(title: "Plan for a night", minHeight: 52) {
                    Text(drinks).font(.outfit(16, .bold))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
            .background(Color.paceyCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text("This is a limit, not a target, and you can lower it any night. It's an estimate from your answers, not medical advice.")
                .font(.outfit(14))
                .foregroundStyle(Color.paceySecondaryText)

            Spacer()

            Button("Use this plan") {
                var p = settings.prefs
                p.averageDrinks = r.average
                p.planDrinks = r.limit
                p.presets = [:]
                settings.prefs = p
                step = .overview
            }
            .buttonStyle(PillButtonStyle())

            Button("Change my answers") { step = .quiz(0) }
                .font(.outfit(16, .semibold))
                .foregroundStyle(Color.paceySecondaryText)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: Overview

    private var overview: some View {
        let points: [(String, String, String, Color)] = [
            ("moon", "Plan your night", "Set a drink limit and a time to be home.", .white),
            ("wineglass", "Log in one tap", "Tap once per drink and watch your glass fill.", .white),
            ("timer", "Stay on pace", "A timer shows when your next drink fits, with water reminders in between.", .white),
            ("chart.bar", "See your night", "A simple summary of drinks, water and pace when you're done.", .white),
            ("exclamationmark.triangle", "Help is always there", "Emergency call, a ride home and location sharing. Always free.", .paceySoftRed)
        ]

        return VStack(alignment: .leading, spacing: 20) {
            AccentHeading(plain: "How Pacey", accent: "works")
                .padding(.top, 64)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    HStack(spacing: 14) {
                        IconTile(systemName: point.0, size: 44, corner: 14, foreground: point.3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(point.1).font(.outfit(16, .bold))
                            Text(point.2)
                                .font(.outfit(14))
                                .foregroundStyle(Color.paceySecondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .paceyCard(corner: 26, padding: 18)

            Spacer()

            Button("Get started") {
                settings.prefs.onboarded = true
            }
            .buttonStyle(PillButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}
