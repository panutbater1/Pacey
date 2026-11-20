import SwiftUI
import CoreText

// MARK: - Colours

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }

    /// Charcoal app background, also used for text on mint.
    static let paceyBackground = Color(hex: 0x1A1A1C)
    /// Rounded cards.
    static let paceyCard = Color(hex: 0x262628)
    /// Buttons on cards and icon tiles.
    static let paceyTile = Color(hex: 0x353538)
    /// The only main accent.
    static let paceyMint = Color(hex: 0x6EE7C1)
    /// Water and the end of the progress gradient.
    static let paceySky = Color(hex: 0x5CC8F5)
    /// "Plan reached" / slow down.
    static let paceyOrange = Color(hex: 0xFF8A3D)
    /// Emergency only.
    static let paceyRed = Color(hex: 0xE5484D)
    static let paceySoftRed = Color(hex: 0xFF9B8F)
    static let paceySecondaryText = Color(hex: 0x9A9AA0)
    static let paceyBodyText = Color(hex: 0xB8B8BE)
    /// Ticks on the pace streak and plan circles.
    static let paceyDeepGreen = Color(hex: 0x2FAE86)
    /// Settings icon tiles and the Usual preset.
    static let paceyAmber = Color(hex: 0xFFC56B)
    static let paceyLavender = Color(hex: 0xB9A4FF)
    static let paceyPink = Color(hex: 0xF5A3D3)
    static let paceyLine = Color(hex: 0x4A4A4E)
    static let paceyTrack = Color(hex: 0x2F2F32)
    // Drink colours for the log animations.
    static let beerAmber = Color(hex: 0xF5B83D)
    static let beerFoam = Color(hex: 0xFFF4DA)
    static let wineRed = Color(hex: 0xB23A62)
    static let olive = Color(hex: 0x9BCB5B)
}

extension LinearGradient {
    static let paceyProgress = LinearGradient(
        colors: [.paceyMint, .paceySky],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Font

enum OutfitWeight: String, CaseIterable {
    case regular = "Outfit-Regular"
    case medium = "Outfit-Medium"
    case semibold = "Outfit-SemiBold"
    case bold = "Outfit-Bold"
    case extraBold = "Outfit-ExtraBold"
}

enum OutfitFont {
    /// Registers the bundled Outfit files at launch, so no Info.plist entry is needed.
    static func register() {
        for weight in OutfitWeight.allCases {
            guard let url = Bundle.main.url(forResource: weight.rawValue, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    static func outfit(_ size: CGFloat, _ weight: OutfitWeight = .regular) -> Font {
        .custom(weight.rawValue, size: size)
    }
}

// MARK: - Components

/// Main heading with one mint word, e.g. "Going out tonight?".
struct AccentHeading: View {
    let plain: String
    let accent: String
    var size: CGFloat = 38
    var accentColor: Color = .paceyMint

    var body: some View {
        (Text(plain + " ").foregroundColor(.white) + Text(accent).foregroundColor(accentColor))
            .font(.outfit(size, .extraBold))
            .tracking(-0.8)
            .lineSpacing(-2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Fully rounded 62 pt button. Mint by default.
struct PillButtonStyle: ButtonStyle {
    var fill: Color = .paceyMint
    var foreground: Color = .paceyBackground
    var height: CGFloat = 62

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.outfit(18, .bold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(fill, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Small grey pill used on cards ("Book a taxi", "End night").
struct ChipButtonStyle: ButtonStyle {
    var fill: Color = .paceyTile
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.outfit(15, .bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(fill, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct IconTile: View {
    let systemName: String
    var size: CGFloat = 40
    var corner: CGFloat = 12
    var fill: Color = .paceyTile
    var foreground: Color = .white

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(fill, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .accessibilityHidden(true)
    }
}

extension View {
    func paceyCard(corner: CGFloat = 24, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paceyCard, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

// MARK: - Shared pieces

/// The tilted-glass logo with the wordmark.
struct LogoMark: View {
    var body: some View {
        HStack(spacing: 8) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)
            Text("pacey")
                .font(.outfit(24, .bold))
                .tracking(-0.3)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pacey")
    }
}

/// Logo on the left; End night and Need help on the right while a night is running.
struct TopBar: View {
    var showHelp: Bool
    var onHelp: () -> Void
    var onEndNight: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            LogoMark()
            Spacer(minLength: 8)
            if let onEndNight {
                Button("End night", action: onEndNight)
                    .buttonStyle(ChipButtonStyle(fill: .paceyCard))
            }
            if showHelp {
                Button(action: onHelp) {
                    Label("Need help?", systemImage: "exclamationmark.triangle")
                        .font(.outfit(15, .bold))
                        .foregroundStyle(Color.paceySoftRed)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(Color.paceyCard, in: Capsule())
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
}

/// − value + with 44 pt round buttons.
struct RoundStepper: View {
    let value: String
    var valueWidth: CGFloat = 34
    var valueFont: Font = .outfit(24, .extraBold)
    let lessLabel: String
    let moreLabel: String
    let onLess: () -> Void
    let onMore: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            circle("minus", lessLabel, onLess)
            Text(value)
                .font(valueFont)
                .monospacedDigit()
                .frame(minWidth: valueWidth)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            circle("plus", moreLabel, onMore)
        }
    }

    private func circle(_ symbol: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.paceyTile, in: Circle())
        }
        .accessibilityLabel(label)
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.outfit(13, .semibold))
            .foregroundStyle(Color.paceySecondaryText)
            .padding(.leading, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CardDivider: View {
    var body: some View {
        Rectangle().fill(Color.paceyTile).frame(height: 1)
    }
}

/// A row inside a settings card: title (and optional subtitle) on the left, anything on the right.
struct CardRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var minHeight: CGFloat = 56
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.outfit(16, .semibold))
                if let subtitle {
                    Text(subtitle)
                        .font(.outfit(13))
                        .foregroundStyle(Color.paceySecondaryText)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .frame(minHeight: minHeight)
    }
}

/// Grey pill showing a value that opens a picker.
struct ValuePill: View {
    let text: String
    var highlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.outfit(17, .bold))
                .foregroundStyle(highlighted ? Color.paceyMint : .white)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(Color.paceyTile, in: Capsule())
        }
    }
}

/// Bottom sheet with hour and minute wheels (minutes in 5-minute steps).
struct TimeWheelSheet: View {
    let title: String
    @Binding var time: ClockTime
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            SheetHeader(title: title) { dismiss() }
            HStack(spacing: 0) {
                Picker("Hour", selection: $time.hour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h)).font(.outfit(22, .bold)).tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Text(":").font(.outfit(22, .extraBold))
                Picker("Minutes", selection: $time.minute) {
                    ForEach(0..<12, id: \.self) { i in
                        Text(String(format: "%02d", i * 5)).font(.outfit(22, .bold)).tag(i * 5)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.paceyCard)
    }
}

/// Bottom sheet with a wheel of ways to get home.
struct RideWheelSheet: View {
    let title: String
    @Binding var ride: RideHome
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            SheetHeader(title: title) { dismiss() }
            Picker("Getting home", selection: $ride) {
                ForEach(RideHome.allCases) { r in
                    Text(r.title).font(.outfit(20, .bold)).tag(r)
                }
            }
            .pickerStyle(.wheel)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.paceyCard)
    }
}

struct SheetHeader: View {
    let title: String
    let onDone: () -> Void

    var body: some View {
        HStack {
            Text(title).font(.outfit(20, .extraBold))
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(ChipButtonStyle(fill: .paceyMint, foreground: .paceyBackground))
        }
    }
}

/// Small check circle used for plan dots and the pace streak.
struct CheckDot: View {
    let filled: Bool
    var color: Color = .paceyDeepGreen
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            Circle().fill(filled ? color : Color.paceyTile)
            if filled {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.42, weight: .heavy))
                    .foregroundStyle(Color.paceyBackground)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
