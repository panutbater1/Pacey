import SwiftUI
import SwiftData

/// Settings laid out like a health app: a profile card, then grouped sections you tap into.
struct SettingsView: View {
    @Binding var path: [SettingsPage]
    let onHelp: () -> Void

    @EnvironmentObject private var settings: AppSettings

    private struct Row {
        let page: SettingsPage
        let title: String
        let value: String
        let icon: String
        let tile: Color
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                TopBar(showHelp: false, onHelp: {})
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        AccentHeading(plain: "Your", accent: "settings")
                        profileCard
                        ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                            VStack(alignment: .leading, spacing: 8) {
                                SectionLabel(text: group.0)
                                VStack(spacing: 0) {
                                    ForEach(Array(group.1.enumerated()), id: \.offset) { i, row in
                                        if i > 0 { CardDivider() }
                                        NavigationLink(value: row.page) { rowView(row) }
                                            .buttonStyle(.plain)
                                    }
                                }
                                .background(Color.paceyCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            }
                        }
                        Text("Pacey \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.outfit(13))
                            .foregroundStyle(Color.paceySecondaryText)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .foregroundStyle(.white)
            .background(Color.paceyBackground)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsPage.self) { page in
                destination(page)
            }
        }
    }

    private var groups: [(String, [Row])] {
        let p = settings.prefs
        let reminders = [p.remindWater, p.remindNextDrink, p.remindHomeTime, p.remindPastPlan, p.waterFirst].filter { $0 }.count
        return [
            ("Your plan", [
                Row(page: .pacePlan, title: "Pace plan", value: "Limit \(p.suggestedLimit)", icon: "wineglass", tile: .paceyMint),
                Row(page: .quickStart, title: "Quick start", value: "3 presets", icon: "bolt.fill", tile: .paceyAmber),
                Row(page: .drinkType, title: "Drink type", value: p.drinkTypes.count == 1 ? p.drinkTypes[0].label : "\(p.drinkTypes.count) types", icon: "takeoutbag.and.cup.and.straw", tile: .paceyLavender),
                Row(page: .drinkSizes, title: "Drink sizes", value: p.useOunces ? "fl oz" : "ml", icon: "ruler", tile: .paceyPink),
                Row(page: .reminders, title: "Reminders", value: "\(reminders) on", icon: "bell", tile: .paceySky)
            ]),
            ("Safety", [
                Row(page: .safety, title: "Emergency and safety", value: "", icon: "shield", tile: .paceySoftRed)
            ]),
            ("Privacy and legal", [
                Row(page: .privacy, title: "Data and privacy", value: "", icon: "lock", tile: .paceyBodyText),
                Row(page: .about, title: "About Pacey", value: "", icon: "info.circle", tile: .paceyBodyText)
            ])
        ]
    }

    private var profileCard: some View {
        let name = settings.prefs.name.trimmingCharacters(in: .whitespaces)
        return NavigationLink(value: SettingsPage.profile) {
            HStack(spacing: 14) {
                Text(String(name.first ?? "P").uppercased())
                    .font(.outfit(22, .extraBold))
                    .foregroundStyle(Color.paceyBackground)
                    .frame(width: 56, height: 56)
                    .background(Color.paceyMint, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(name.isEmpty ? "Your profile" : name).font(.outfit(18, .bold))
                    Text("Profile and trusted friend")
                        .font(.outfit(14))
                        .foregroundStyle(Color.paceySecondaryText)
                }
                Spacer()
                chevron
            }
            .paceyCard(corner: 26, padding: 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func rowView(_ row: Row) -> some View {
        HStack(spacing: 14) {
            Image(systemName: row.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.paceyBackground)
                .frame(width: 36, height: 36)
                .background(row.tile, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(row.title).font(.outfit(16, .semibold))
            Spacer()
            Text(row.value).font(.outfit(15)).foregroundStyle(Color.paceySecondaryText)
            chevron
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.paceySecondaryText)
    }

    @ViewBuilder
    private func destination(_ page: SettingsPage) -> some View {
        switch page {
        case .profile: ProfileSettings()
        case .pacePlan: PacePlanSettings()
        case .quickStart: QuickStartSettings()
        case .drinkType: DrinkTypeSettings()
        case .drinkSizes: DrinkSizeSettings()
        case .reminders: ReminderSettings()
        case .safety: SafetySettings(onHelp: onHelp)
        case .privacy: PrivacySettings()
        case .about: AboutSettings()
        }
    }
}

// MARK: - Page frame

private struct SettingsPageView<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .foregroundStyle(.white)
        .background(Color.paceyBackground.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct Note: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.outfit(14))
            .foregroundStyle(Color.paceySecondaryText)
            .lineSpacing(3)
    }
}

private extension View {
    func settingsCard(vertical: CGFloat = 4) -> some View {
        self
            .padding(.horizontal, 18)
            .padding(.vertical, vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paceyCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Profile

private struct ProfileSettings: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        SettingsPageView(title: "Profile") {
            VStack(alignment: .leading, spacing: 14) {
                field("Your name", placeholder: "Add your name", text: $settings.prefs.name)
                field("Trusted friend, for sending your location", placeholder: "Name or phone number", text: $settings.prefs.trustedFriend)
            }
            .settingsCard(vertical: 18)

            CardRow(title: "Age") {
                Text("Confirmed · \(RegionRules.legalDrinkingAge) or older")
                    .font(.outfit(15))
                    .foregroundStyle(Color.paceySecondaryText)
            }
            .settingsCard()

            SectionLabel(text: "For your blood alcohol estimate")
            VStack(alignment: .leading, spacing: 8) {
                CardRow(title: "Weight", minHeight: 60) {
                    RoundStepper(
                        value: settings.prefs.weightText,
                        valueWidth: 64,
                        valueFont: .outfit(17, .extraBold),
                        lessLabel: "Lower weight",
                        moreLabel: "Raise weight",
                        onLess: { settings.prefs.weightKg = max(35, (settings.prefs.weightKg ?? 70) - 1) },
                        onMore: { settings.prefs.weightKg = min(200, (settings.prefs.weightKg ?? 70) + 1) }
                    )
                }
                CardDivider()
                Text("Body type").font(.outfit(16, .semibold)).padding(.top, 4)
                HStack(spacing: 8) {
                    ForEach(BodyType.allCases) { type in
                        let on = settings.prefs.body == type
                        Button(type.title) { settings.prefs.body = type }
                            .font(.outfit(14, .bold))
                            .foregroundStyle(on ? Color.paceyBackground : .white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(on ? Color.paceyMint : Color.paceyTile, in: Capsule())
                            .accessibilityAddTraits(on ? .isSelected : [])
                    }
                }
                .padding(.bottom, 12)
            }
            .settingsCard()

            Note(text: "Used only on this phone to estimate blood alcohol in your night summary.")
        }
    }

    private func field(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.outfit(13, .semibold))
                .foregroundStyle(Color.paceySecondaryText)
            TextField(placeholder, text: text)
                .font(.outfit(16))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.paceyTile, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityLabel(label)
        }
    }
}

// MARK: - Pace plan

private struct PacePlanSettings: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        let p = settings.prefs
        SettingsPageView(title: "Pace plan") {
            VStack(spacing: 0) {
                CardRow(title: "Pace profile") {
                    Text(p.paceProfile).font(.outfit(15, .bold)).foregroundStyle(Color.paceyMint)
                }
                CardDivider()
                CardRow(title: "Your average", subtitle: "Drinks on a usual night out", minHeight: 64) {
                    RoundStepper(
                        value: "\(p.averageDrinks)",
                        valueWidth: 28,
                        lessLabel: "Lower your average",
                        moreLabel: "Raise your average",
                        onLess: { settings.prefs.averageDrinks = max(1, p.averageDrinks - 1) },
                        onMore: { settings.prefs.averageDrinks = min(12, p.averageDrinks + 1) }
                    )
                }
                CardDivider()
                CardRow(title: "Suggested limit", minHeight: 52) {
                    Text(p.suggestedLimit == 1 ? "1 drink" : "\(p.suggestedLimit) drinks")
                        .font(.outfit(15, .bold))
                        .foregroundStyle(Color.paceyMint)
                }
                CardDivider()
                CardRow(title: "Home by", minHeight: 52) {
                    Text(p.planHomeBy.label).font(.outfit(15)).foregroundStyle(Color.paceySecondaryText)
                }
                CardDivider()
                CardRow(title: "Getting home", minHeight: 52) {
                    Text(p.planRide.title).font(.outfit(15)).foregroundStyle(Color.paceySecondaryText)
                }
            }
            .settingsCard()

            Note(text: "Your suggested limit is worked out from your average, and is never more than 4 or more than your average.")
        }
    }
}

// MARK: - Quick start

private struct QuickStartSettings: View {
    @EnvironmentObject private var settings: AppSettings

    private enum Edit: Identifiable {
        case time(PresetKind), ride(PresetKind)
        var id: String {
            switch self {
            case .time(let k): return "time-\(k.rawValue)"
            case .ride(let k): return "ride-\(k.rawValue)"
            }
        }
    }

    @State private var editing: Edit?

    var body: some View {
        SettingsPageView(title: "Quick start") {
            Text("Set up the quick start buttons on Home. Tap one and your whole plan is filled in.")
                .font(.outfit(15))
                .foregroundStyle(Color.paceyBodyText)

            ForEach(PresetKind.allCases) { kind in
                presetCard(kind)
            }

            Note(text: "Drinks for each quick start can go up to your average of \(settings.prefs.averageDrinks).")
        }
        .sheet(item: $editing) { edit in
            switch edit {
            case .time(let kind):
                TimeWheelSheet(title: "Home by · \(kind.title)", time: presetBinding(kind).homeBy)
            case .ride(let kind):
                RideWheelSheet(title: "Getting home · \(kind.title)", ride: presetBinding(kind).ride)
            }
        }
    }

    private func presetBinding(_ kind: PresetKind) -> Binding<QuickPreset> {
        Binding(
            get: { settings.prefs.preset(kind) },
            set: { settings.prefs.setPreset($0, for: kind) }
        )
    }

    private func presetCard(_ kind: PresetKind) -> some View {
        let p = settings.prefs
        let preset = p.preset(kind)
        let accent: Color = [PresetKind.quiet: Color.paceySky, .steady: .paceyMint, .usual: .paceyAmber][kind] ?? .paceyMint
        let noun = preset.drinks == 1 ? (p.drinkTypes.count == 1 ? p.drinkTypes[0].singular : "drink") : p.drinkNounPlural

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("\(preset.drinks)")
                    .font(.outfit(20, .extraBold))
                    .foregroundStyle(Color.paceyBackground)
                    .frame(width: 44, height: 44)
                    .background(accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title).font(.outfit(24, .extraBold)).tracking(-0.4)
                    Text("\(preset.drinks) \(noun) · home by \(preset.homeBy.label) · \(preset.ride.title)")
                        .font(.outfit(14))
                        .foregroundStyle(Color.paceyBodyText)
                }
            }
            .padding(.top, 14)
            .padding(.bottom, 12)
            .accessibilityElement(children: .combine)

            CardDivider()
            CardRow(title: p.drinkNounPlural.prefix(1).uppercased() + String(p.drinkNounPlural.dropFirst())) {
                RoundStepper(
                    value: "\(preset.drinks)",
                    valueWidth: 28,
                    lessLabel: "Fewer for \(kind.title)",
                    moreLabel: "More for \(kind.title)",
                    onLess: { var q = preset; q.drinks -= 1; settings.prefs.setPreset(q, for: kind) },
                    onMore: { var q = preset; q.drinks += 1; settings.prefs.setPreset(q, for: kind) }
                )
            }
            CardDivider()
            CardRow(title: "Home by") {
                ValuePill(text: preset.homeBy.label) { editing = .time(kind) }
                    .accessibilityLabel("Home by for \(kind.title), \(preset.homeBy.label). Change")
            }
            CardDivider()
            CardRow(title: "Getting home") {
                ValuePill(text: preset.ride.title) { editing = .ride(kind) }
                    .accessibilityLabel("Getting home for \(kind.title), \(preset.ride.title). Change")
            }
            .padding(.bottom, 4)
        }
        .settingsCard(vertical: 0)
    }
}

// MARK: - Drink type

private struct DrinkTypeSettings: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        SettingsPageView(title: "Drink type") {
            Text("Pick everything you might drink. You can switch between them in Drink mode with the arrow next to + Drink.")
                .font(.outfit(15))
                .foregroundStyle(Color.paceyBodyText)

            VStack(spacing: 0) {
                ForEach(Array(DrinkType.allCases.enumerated()), id: \.offset) { i, type in
                    let on = settings.prefs.drinkTypes.contains(type)
                    if i > 0 { CardDivider() }
                    Button {
                        settings.prefs.toggleDrinkType(type)
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.label).font(.outfit(16, .bold))
                                Text(type.sizeHint).font(.outfit(13)).foregroundStyle(Color.paceySecondaryText)
                            }
                            Spacer()
                            ZStack {
                                Circle().strokeBorder(on ? Color.paceyMint : Color.paceyLine, lineWidth: 2)
                                if on {
                                    Circle().fill(Color.paceyMint)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundStyle(Color.paceyBackground)
                                }
                            }
                            .frame(width: 26, height: 26)
                        }
                        .frame(minHeight: 64)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .settingsCard()

            Note(text: "At least one type stays ticked.")
        }
    }
}

// MARK: - Drink sizes

private struct DrinkSizeSettings: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        let p = settings.prefs
        SettingsPageView(title: "Drink sizes") {
            Text("Set the size and strength of what you drink. Pacey uses this to estimate the alcohol you've had.")
                .font(.outfit(15))
                .foregroundStyle(Color.paceyBodyText)

            Toggle(isOn: $settings.prefs.useOunces) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show in fluid ounces").font(.outfit(16, .semibold))
                    Text(p.useOunces ? "Sizes show in fl oz" : "Sizes show in ml")
                        .font(.outfit(13))
                        .foregroundStyle(Color.paceySecondaryText)
                }
            }
            .tint(.paceyMint)
            .frame(minHeight: 64)
            .settingsCard()

            ForEach(p.drinkTypes) { type in
                let size = p.size(for: type)
                let abvStep = size.abv < 10 ? 0.5 : 1.0
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(type.label).font(.outfit(22, .extraBold))
                        Spacer()
                        Text("\(p.volumeText(size.alcoholML)) alcohol each")
                            .font(.outfit(14, .bold))
                            .foregroundStyle(Color.paceyMint)
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 10)
                    CardDivider()
                    CardRow(title: "Size") {
                        RoundStepper(
                            value: p.volumeText(size.ml),
                            valueWidth: 72,
                            valueFont: .outfit(17, .extraBold),
                            lessLabel: "Smaller \(type.singular)",
                            moreLabel: "Bigger \(type.singular)",
                            onLess: { settings.prefs.setSize(DrinkSize(ml: size.ml - type.volumeStep, abv: size.abv), for: type) },
                            onMore: { settings.prefs.setSize(DrinkSize(ml: size.ml + type.volumeStep, abv: size.abv), for: type) }
                        )
                    }
                    CardDivider()
                    CardRow(title: "Strength") {
                        RoundStepper(
                            value: size.abv == size.abv.rounded() ? "\(Int(size.abv))%" : String(format: "%.1f%%", size.abv),
                            valueWidth: 72,
                            valueFont: .outfit(17, .extraBold),
                            lessLabel: "Weaker \(type.singular)",
                            moreLabel: "Stronger \(type.singular)",
                            onLess: { settings.prefs.setSize(DrinkSize(ml: size.ml, abv: size.abv - abvStep), for: type) },
                            onMore: { settings.prefs.setSize(DrinkSize(ml: size.ml, abv: size.abv + abvStep), for: type) }
                        )
                    }
                    .padding(.bottom, 4)
                }
                .settingsCard(vertical: 0)
            }

            Note(text: "Only the drink types you picked show here. The alcohol amount is an estimate from these numbers. Pacey can't measure your blood alcohol.")
        }
    }
}

// MARK: - Reminders

private struct ReminderSettings: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        SettingsPageView(title: "Reminders") {
            VStack(spacing: 0) {
                toggle("Water reminders", "20 minutes after a drink", $settings.prefs.remindWater)
                CardDivider()
                toggle("Next drink fits your plan", "When your pace timer ends", $settings.prefs.remindNextDrink)
                CardDivider()
                toggle("Heading home", "15 minutes before your home by time", $settings.prefs.remindHomeTime)
                CardDivider()
                toggle("Past your plan", "A kind nudge when you go over your limit", $settings.prefs.remindPastPlan)
                CardDivider()
                toggle("Water first", "Offer a water before each drink past your plan", $settings.prefs.waterFirst)
            }
            .settingsCard()
        }
    }

    private func toggle(_ title: String, _ subtitle: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.outfit(16, .semibold))
                Text(subtitle).font(.outfit(13)).foregroundStyle(Color.paceySecondaryText)
            }
        }
        .tint(.paceyMint)
        .frame(minHeight: 64)
    }
}

// MARK: - Safety, privacy, about

private struct SafetySettings: View {
    let onHelp: () -> Void
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        SettingsPageView(title: "Emergency and safety") {
            VStack(spacing: 0) {
                CardRow(title: "Emergency number") {
                    Text(RegionRules.emergencyNumber).font(.outfit(15)).foregroundStyle(Color.paceySecondaryText)
                }
                CardDivider()
                CardRow(title: "Trusted friend") {
                    let friend = settings.prefs.trustedFriend.trimmingCharacters(in: .whitespaces)
                    Text(friend.isEmpty ? "Not set" : friend).font(.outfit(15)).foregroundStyle(Color.paceySecondaryText)
                }
            }
            .settingsCard()

            Button(action: onHelp) {
                Label("Open Need help", systemImage: "exclamationmark.triangle")
                    .font(.outfit(16, .bold))
                    .foregroundStyle(Color.paceySoftRed)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .padding(.horizontal, 18)
                    .background(Color.paceyCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            Note(text: "Safety features are always free.")
        }
    }
}

private struct PrivacySettings: View {
    @Environment(\.modelContext) private var context
    @Query private var nights: [Night]
    @State private var confirmDelete = false

    var body: some View {
        SettingsPageView(title: "Data and privacy") {
            VStack(alignment: .leading, spacing: 12) {
                point("Stored on your phone.", "Your nights and details never leave this device.")
                point("No account needed.", "Pacey works without signing up.")
                point("Location only when you ask.", "It is used only when you send it to a friend.")
            }
            .settingsCard(vertical: 18)

            if !nights.isEmpty {
                Button("Delete my saved nights") { confirmDelete = true }
                    .font(.outfit(16, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .padding(.horizontal, 18)
                    .background(Color.paceyCard, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
        .confirmationDialog("Delete all saved nights?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete nights", role: .destructive) {
                for night in nights { context.delete(night) }
                try? context.save()
                Reminders.cancelAll()
            }
            Button("Keep them", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func point(_ title: String, _ text: String) -> some View {
        (Text(title + " ").font(.outfit(15, .bold)).foregroundColor(.white)
         + Text(text).font(.outfit(15)).foregroundColor(.paceyBodyText))
            .lineSpacing(3)
    }
}

private struct AboutSettings: View {
    var body: some View {
        SettingsPageView(title: "About Pacey") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Not medical advice").font(.outfit(16, .bold))
                Text("Pacey gives estimates to help you pace a night out. It can't measure your blood alcohol. Never use it to decide whether you're safe to drive.")
                    .font(.outfit(15))
                    .foregroundStyle(Color.paceyBodyText)
                    .lineSpacing(3)
            }
            .settingsCard(vertical: 18)

            VStack(spacing: 0) {
                // TODO: link these to the published Terms and Privacy policy before release.
                CardRow(title: "Terms and conditions", minHeight: 52) {
                    Image(systemName: "chevron.right").foregroundStyle(Color.paceySecondaryText)
                }
                CardDivider()
                CardRow(title: "Privacy policy", minHeight: 52) {
                    Image(systemName: "chevron.right").foregroundStyle(Color.paceySecondaryText)
                }
                CardDivider()
                CardRow(title: "Version", minHeight: 52) {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(.outfit(15))
                        .foregroundStyle(Color.paceySecondaryText)
                }
            }
            .settingsCard()
        }
    }
}
