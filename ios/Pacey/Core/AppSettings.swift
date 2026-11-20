import Foundation
import Combine

/// Holds the person's preferences and saves them on the phone whenever they change.
final class AppSettings: ObservableObject {
    private static let storageKey = "pacey.preferences"

    @Published var prefs: Preferences {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(Preferences.self, from: data) {
            prefs = saved
        } else {
            prefs = Preferences()
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(prefs) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
