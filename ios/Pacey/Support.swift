import SwiftUI
import CoreLocation

// MARK: - Region rules

enum RegionRules {
    private static var regionCode: String {
        Locale.current.region?.identifier ?? ""
    }

    /// Legal drinking age for the phone's region. Defaults to 18.
    static var legalDrinkingAge: Int {
        let ages: [String: Int] = [
            "US": 21, "ID": 21, "EG": 21, "LK": 21, "KZ": 21, "OM": 21, "AE": 21,
            "JP": 20, "TH": 20, "IS": 20, "PY": 20, "UZ": 20,
            "KR": 19, "CA": 19
        ]
        return ages[regionCode] ?? 18
    }

    /// Local emergency number. 112 works on mobile networks almost everywhere.
    static var emergencyNumber: String {
        let numbers: [String: String] = [
            "US": "911", "CA": "911", "MX": "911", "AR": "911", "PH": "911",
            "GB": "999", "HK": "999", "MY": "999",
            "AU": "000", "NZ": "111",
            "JP": "119", "KR": "119", "TW": "119",
            "CN": "120", "SG": "995", "BR": "192"
        ]
        return numbers[regionCode] ?? "112"
    }
}

// MARK: - Actions that leave the app

@MainActor
enum Actions {
    static func callEmergencyServices() {
        open("tel://\(RegionRules.emergencyNumber)")
    }

    /// Opens Maps with nearby taxis.
    static func bookTaxi() {
        open("https://maps.apple.com/?q=taxi")
    }

    /// Opens Messages with a prefilled text. The person picks who to send it to.
    static func messageFriend(location: CLLocation?) {
        var text = "Hey, I could use some help getting home."
        if let location {
            let lat = String(format: "%.5f", location.coordinate.latitude)
            let lon = String(format: "%.5f", location.coordinate.longitude)
            text += " I'm here: https://maps.apple.com/?ll=\(lat),\(lon)&q=I'm%20here"
        }
        let body = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        open("sms:&body=\(body)")
    }

    private static func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - One-shot location

@MainActor
final class LocationFetcher: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var isFetching = false

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    /// Returns the current location, or `nil` if permission is denied or it takes too long.
    func current() async -> CLLocation? {
        guard continuation == nil else { return nil }
        isFetching = true

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                finish(nil)
            }

            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(12))
                guard let self else { return }
                self.finish(self.manager.location)
            }
        }
    }

    private func finish(_ location: CLLocation?) {
        guard let continuation else { return }
        self.continuation = nil
        isFetching = false
        continuation.resume(returning: location)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard self.continuation != nil else { return }
            switch self.manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.manager.requestLocation()
            case .notDetermined:
                break
            default:
                self.finish(nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in
            self.finish(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.finish(self.manager.location)
        }
    }
}
