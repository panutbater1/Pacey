import SwiftUI
import SwiftData
import UIKit
import UserNotifications

@main
struct PaceyApp: App {
    @StateObject private var settings = AppSettings()

    init() {
        OutfitFont.register()
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared

        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = UIColor(Color.paceyBackground)
        tabBar.shadowColor = UIColor(Color.paceyCard)
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(Color.paceyBackground)
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(settings)
                .preferredColorScheme(.dark)
                .tint(.paceyMint)
                .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        }
        .modelContainer(for: [Night.self, LogEntry.self])
    }
}
