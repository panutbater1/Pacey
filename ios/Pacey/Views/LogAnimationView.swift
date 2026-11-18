import SwiftUI

/// What to show after a tap on + Drink or + Water.
struct LogAnimation: Identifiable, Equatable {
    enum Style: Equatable {
        case shot, beer, wine, cocktail, other, water

        init(_ type: DrinkType) {
            switch type {
            case .shot: self = .shot
            case .beer: self = .beer
            case .wine: self = .wine
            case .cocktail: self = .cocktail
            case .other: self = .other
            }
        }
    }

    let id = UUID()
    let style: Style
    let title: String
    let subtitle: String
}

/// A calm card in the middle of the screen with an animation that matches the drink.
struct LogAnimationCard: View {
    let animation: LogAnimation

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 8) {
                Group {
                    switch animation.style {
                    case .shot: ShotAnimation()
                    case .beer: BeerAnimation()
                    case .wine: WineAnimation()
                    case .cocktail: CocktailAnimation()
                    case .other: OtherAnimation()
                    case .water: WaterAnimation()
                    }
                }
                .frame(width: 140, height: 140)
                .accessibilityHidden(true)

                Text(animation.title)
                    .font(.outfit(20, .extraBold))
                Text(animation.subtitle)
                    .font(.outfit(14))
                    .foregroundStyle(Color.paceyBodyText)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 22)
            .frame(width: 220)
            .background(Color.paceyCard.opacity(0.98), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
            .modifier(PopIn())
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

private struct PopIn: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown || reduceMotion ? 1 : 0.6)
            .opacity(shown || reduceMotion ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.6)) { shown = true }
            }
    }
}

// MARK: - Drawing (all paths use a 140 × 140 canvas)

private struct DrinkPath: Shape {
    enum Kind {
        case shadow, shotGlass, shotFill, splashLeft, splashRight
        case pint, beerFill, foam
        case wineBowl, wineFill, wineStem, wineBase
        case martini, martiniFill, stem, base, olive, pick
        case tumbler, tumblerFill
        case drop, ripple
    }

    let kind: Kind

    func path(in rect: CGRect) -> Path {
        let s = rect.width / 140
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: rect.minX + x * s, y: rect.minY + y * s, width: w * s, height: h * s)
        }
        func poly(_ points: [(CGFloat, CGFloat)], closed: Bool = true) -> Path {
            var path = Path()
            path.addLines(points.map { p($0.0, $0.1) })
            if closed { path.closeSubpath() }
            return path
        }

        switch kind {
        case .shadow: return Path(ellipseIn: r(44, 114, 52, 8))
        case .shotGlass: return poly([(48, 52), (92, 52), (86, 114), (54, 114)])
        case .shotFill: return poly([(54, 72), (86, 72), (83, 110), (57, 110)])
        case .splashLeft: return Path(ellipseIn: r(56, 48, 8, 8))
        case .splashRight: return Path(ellipseIn: r(76, 48, 8, 8))
        case .pint: return poly([(46, 34), (94, 34), (89, 116), (51, 116)])
        case .beerFill: return Path(r(40, 50, 60, 70))
        case .foam: return Path(roundedRect: r(40, 38, 60, 16), cornerRadius: 8 * s)
        case .wineBowl:
            var path = Path()
            path.move(to: p(46, 26))
            path.addLine(to: p(94, 26))
            path.addCurve(to: p(70, 76), control1: p(94, 60), control2: p(84, 76))
            path.addCurve(to: p(46, 26), control1: p(56, 76), control2: p(46, 60))
            path.closeSubpath()
            return path
        case .wineFill: return Path(r(40, 48, 60, 32))
        case .wineStem, .stem: return poly([(70, 76), (70, 112)], closed: false)
        case .wineBase, .base: return poly([(54, 114), (86, 114)], closed: false)
        case .martini: return poly([(36, 34), (104, 34), (70, 76)])
        case .martiniFill: return poly([(48, 44), (92, 44), (70, 70)])
        case .olive: return Path(ellipseIn: r(63, 40, 14, 14))
        case .pick: return poly([(84, 18), (66, 54)], closed: false)
        case .tumbler: return poly([(46, 42), (94, 42), (90, 114), (50, 114)])
        case .tumblerFill: return Path(r(40, 62, 60, 56))
        case .drop:
            var path = Path()
            path.move(to: p(70, 24))
            path.addCurve(to: p(92, 68), control1: p(70, 24), control2: p(92, 50))
            path.addArc(center: p(70, 68), radius: 22 * s, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            path.addCurve(to: p(70, 24), control1: p(48, 50), control2: p(70, 24))
            path.closeSubpath()
            return path
        case .ripple: return Path(ellipseIn: r(40, 104, 60, 16))
        }
    }
}

private let outline = StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)

/// Runs `change` with animation, or straight away when Reduce Motion is on.
private func animate(_ reduceMotion: Bool, _ animation: Animation, _ change: @escaping () -> Void) {
    if reduceMotion { change() } else { withAnimation(animation, change) }
}

private struct ShotAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var landed = false
    @State private var splash = false

    var body: some View {
        ZStack {
            DrinkPath(kind: .shadow).fill(Color.paceyTile)
            DrinkPath(kind: .splashLeft).fill(Color.paceyMint)
                .offset(x: splash ? -24 : 0, y: splash ? -26 : 0)
                .opacity(splash ? 0 : (landed ? 1 : 0))
            DrinkPath(kind: .splashRight).fill(Color.paceyMint)
                .offset(x: splash ? 24 : 0, y: splash ? -26 : 0)
                .opacity(splash ? 0 : (landed ? 1 : 0))
            ZStack {
                DrinkPath(kind: .shotFill).fill(Color.paceyMint)
                DrinkPath(kind: .shotGlass).stroke(.white, style: outline)
            }
            .offset(y: landed ? 0 : -70)
            .opacity(landed ? 1 : 0)
        }
        .onAppear {
            animate(reduceMotion, .spring(response: 0.45, dampingFraction: 0.55).delay(0.1)) { landed = true }
            if !reduceMotion {
                withAnimation(.easeOut(duration: 0.6).delay(0.5)) { splash = true }
            }
        }
    }
}

private struct BeerAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filled = false
    @State private var foam = false
    @State private var bubbles = false

    var body: some View {
        ZStack {
            ZStack {
                DrinkPath(kind: .beerFill).fill(Color.beerAmber)
                    .scaleEffect(x: 1, y: filled ? 1 : 0.001, anchor: UnitPoint(x: 0.5, y: 120.0 / 140))
                DrinkPath(kind: .foam).fill(Color.beerFoam)
                    .opacity(foam ? 1 : 0)
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.beerFoam)
                        .frame(width: 5, height: 5)
                        .position(x: CGFloat([60, 72, 82][i]), y: CGFloat([110, 112, 106][i]))
                        .offset(y: bubbles ? -50 : 0)
                        .opacity(bubbles ? 0 : 0.9)
                        .animation(
                            reduceMotion ? nil : .easeIn(duration: 1.1).repeatForever(autoreverses: false).delay(0.9 + Double(i) * 0.15),
                            value: bubbles
                        )
                }
            }
            .clipShape(DrinkPath(kind: .pint))
            DrinkPath(kind: .pint).stroke(.white, style: outline)
        }
        .onAppear {
            animate(reduceMotion, .easeOut(duration: 0.9).delay(0.15)) { filled = true }
            animate(reduceMotion, .easeOut(duration: 0.4).delay(0.95)) { foam = true }
            if !reduceMotion { bubbles = true }
        }
    }
}

private struct WineAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filled = false
    @State private var tilt = -9.0

    var body: some View {
        ZStack {
            DrinkPath(kind: .wineFill).fill(Color.wineRed)
                .scaleEffect(x: 1, y: filled ? 1 : 0.001, anchor: UnitPoint(x: 0.5, y: 80.0 / 140))
                .clipShape(DrinkPath(kind: .wineBowl))
            DrinkPath(kind: .wineBowl).stroke(.white, style: outline)
            DrinkPath(kind: .wineStem).stroke(.white, style: outline)
            DrinkPath(kind: .wineBase).stroke(.white, style: outline)
        }
        .rotationEffect(.degrees(reduceMotion ? 0 : tilt), anchor: UnitPoint(x: 0.5, y: 114.0 / 140))
        .onAppear {
            animate(reduceMotion, .easeOut(duration: 0.9).delay(0.15)) { filled = true }
            if !reduceMotion {
                // A gentle swirl that settles.
                withAnimation(.interpolatingSpring(stiffness: 60, damping: 4).delay(0.3)) { tilt = 0 }
            }
        }
    }
}

private struct CocktailAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filled = false
    @State private var olive = false

    var body: some View {
        ZStack {
            DrinkPath(kind: .martiniFill).fill(Color.paceyMint)
                .scaleEffect(x: 1, y: filled ? 1 : 0.001, anchor: UnitPoint(x: 0.5, y: 70.0 / 140))
            ZStack {
                DrinkPath(kind: .pick).stroke(Color.paceyBodyText, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                DrinkPath(kind: .olive).fill(Color.olive)
            }
            .offset(y: olive ? 0 : -70)
            .opacity(olive ? 1 : 0)
            DrinkPath(kind: .martini).stroke(.white, style: outline)
            DrinkPath(kind: .stem).stroke(.white, style: outline)
            DrinkPath(kind: .base).stroke(.white, style: outline)
        }
        .onAppear {
            animate(reduceMotion, .easeOut(duration: 0.9).delay(0.15)) { filled = true }
            animate(reduceMotion, .spring(response: 0.45, dampingFraction: 0.55).delay(0.7)) { olive = true }
        }
    }
}

private struct OtherAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false
    @State private var filled = false

    var body: some View {
        ZStack {
            DrinkPath(kind: .tumblerFill).fill(Color.paceyLavender)
                .scaleEffect(x: 1, y: filled ? 1 : 0.001, anchor: UnitPoint(x: 0.5, y: 118.0 / 140))
                .clipShape(DrinkPath(kind: .tumbler))
            DrinkPath(kind: .tumbler).stroke(.white, style: outline)
        }
        .scaleEffect(shown ? 1 : 0.6, anchor: .bottom)
        .opacity(shown ? 1 : 0)
        .onAppear {
            animate(reduceMotion, .spring(response: 0.45, dampingFraction: 0.6).delay(0.1)) { shown = true }
            animate(reduceMotion, .easeOut(duration: 0.9).delay(0.2)) { filled = true }
        }
    }
}

private struct WaterAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fallen = false
    @State private var ripple = false

    var body: some View {
        ZStack {
            ForEach(0..<2, id: \.self) { i in
                DrinkPath(kind: .ripple)
                    .stroke(Color.paceySky, lineWidth: 3)
                    .scaleEffect(ripple ? 1.5 : 0.3)
                    .opacity(ripple ? 0 : (fallen ? 0.9 : 0))
                    .animation(reduceMotion ? nil : .easeOut(duration: 1).delay(0.55 + Double(i) * 0.25), value: ripple)
            }
            DrinkPath(kind: .drop).fill(Color.paceySky)
                .offset(y: fallen ? 0 : -60)
                .opacity(fallen ? 1 : 0)
        }
        .onAppear {
            animate(reduceMotion, .easeIn(duration: 0.5).delay(0.1)) { fallen = true }
            if !reduceMotion { ripple = true }
        }
    }
}
