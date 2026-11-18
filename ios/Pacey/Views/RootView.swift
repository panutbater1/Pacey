import SwiftUI
import SwiftData

enum MainTab: Hashable {
    case home, tonight, nights, settings
}

enum SettingsPage: Hashable {
    case profile, pacePlan, quickStart, drinkType, drinkSizes, reminders, safety, privacy, about
}

/// Onboarding the first time, then four tabs: Home, Tonight (or Last night), Nights and Settings.
struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \Night.startedAt, order: .reverse) private var nights: [Night]

    @State private var tab: MainTab = .home
    @State private var settingsPath: [SettingsPage] = []
    @State private var summaryNight: Night?
    @State private var showHelp = false

    private var activeNight: Night? { nights.first { $0.endedAt == nil } }
    private var endedNights: [Night] { nights.filter { $0.endedAt != nil } }

    var body: some View {
        ZStack {
            Color.paceyBackground.ignoresSafeArea()

            if !settings.prefs.onboarded {
                OnboardingFlow()
                    .transition(.opacity)
            } else {
                tabs
            }
        }
        .animation(.easeInOut(duration: 0.25), value: settings.prefs.onboarded)
        .fullScreenCover(isPresented: $showHelp) {
            HelpView()
        }
        .fullScreenCover(item: $summaryNight) { night in
            SummaryView(night: night, onClose: { summaryNight = nil })
                .environmentObject(settings)
        }
        .task { closeForgottenNight() }
    }

    private var tabs: some View {
        TabView(selection: $tab) {
            HomeView(
                activeNight: activeNight,
                endedNights: endedNights,
                onStarted: { tab = .tonight },
                onShowTonight: { tab = .tonight },
                onHelp: { showHelp = true }
            )
            .tabItem { Label("Home", systemImage: "house") }
            .tag(MainTab.home)

            Group {
                if let night = activeNight {
                    DrinkModeView(
                        night: night,
                        onEnd: { end(night) },
                        onHelp: { showHelp = true },
                        onEditDrinkTypes: {
                            settingsPath = [.drinkType]
                            tab = .settings
                        }
                    )
                } else {
                    LastNightView(
                        lastNight: endedNights.first,
                        onShowSummary: { summaryNight = $0 },
                        onPlan: { tab = .home }
                    )
                }
            }
            .tabItem { Label(activeNight == nil ? "Last night" : "Tonight", systemImage: "wineglass") }
            .tag(MainTab.tonight)

            NightsView(nights: endedNights)
                .tabItem { Label("Nights", systemImage: "chart.bar") }
                .tag(MainTab.nights)

            SettingsView(path: $settingsPath, onHelp: { showHelp = true })
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(MainTab.settings)
        }
    }

    private func end(_ night: Night) {
        night.endedAt = .now
        try? context.save()
        Reminders.cancelAll()
        summaryNight = night
    }

    /// A night left running long past "home by" is closed quietly at its last logged moment.
    private func closeForgottenNight() {
        guard let night = activeNight,
              Date.now > night.homeBy.addingTimeInterval(6 * 3600) else { return }
        night.endedAt = night.sortedEntries.last?.timestamp ?? night.homeBy
        try? context.save()
        Reminders.cancelAll()
    }
}
