import Foundation
import UIKit

// MARK: - System Function Namespace
//
// Core built-in (migrated from the `nativephp/mobile-system` plugin). Registered
// directly in `BridgeFunctionRegistration.swift` alongside Edge/Perf/UI/Device —
// no plugin install required. Android twin: `bridge/functions/SystemFunctions.kt`.

/// Functions related to system-level operations
/// Namespace: "System.*"
enum SystemFunctions {

    /// The current app window orientation. This intentionally describes the
    /// window, not the physical device: iPad multitasking can make a window
    /// landscape while the device itself is portrait (and vice versa).
    static func currentWindowOrientation() -> String {
        let size = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.bounds.size
            ?? UIScreen.main.bounds.size
        return size.width > size.height ? "landscape" : "portrait"
    }

    // MARK: - System.OpenAppSettings

    /// Open the app's settings screen in the device settings
    /// This allows users to manage permissions they've granted or denied
    /// Returns:
    ///   - success: boolean - True if successfully opened
    class OpenAppSettings: BridgeFunction {
        func execute(parameters: [String: Any]) throws -> [String: Any] {
            DispatchQueue.main.async {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            return ["success": true]
        }
    }

    // MARK: - System.SetPrivacyScreen

    /// Turn the privacy screen on or off. While it is on, each scene is
    /// covered when it goes to the background, so the app-switcher snapshot
    /// shows the cover. iOS cannot block screenshots. See `PrivacyScreen.swift`.
    /// Parameters:
    ///   - enabled: boolean - Required, so a malformed call can't turn it off
    /// Returns:
    ///   - enabled: boolean - The state now applied
    class SetPrivacyScreen: BridgeFunction {
        func execute(parameters: [String: Any]) throws -> [String: Any] {
            guard let enabled = parameters["enabled"] as? Bool else {
                throw BridgeError.invalidParameters("enabled must be a boolean")
            }

            DispatchQueue.main.async {
                PrivacyScreen.shared.setEnabled(enabled)
            }

            return ["enabled": enabled]
        }
    }

    // MARK: - System.GetAppearance

    /// Current system appearance (light / dark). Backs `System::appearance()` /
    /// `isDark()` for the cold read before the first AppearanceChanged push.
    /// Returns:
    ///   - appearance: string - "light" or "dark"
    class GetAppearance: BridgeFunction {
        func execute(parameters: [String: Any]) throws -> [String: Any] {
            func read() -> String {
                let style = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.windows.first?.traitCollection.userInterfaceStyle
                    ?? UITraitCollection.current.userInterfaceStyle
                return style == .dark ? "dark" : "light"
            }
            // Bridge functions may run off the main thread; UIKit trait reads
            // must be on main.
            let mode = Thread.isMainThread ? read() : DispatchQueue.main.sync { read() }
            return ["appearance": mode]
        }
    }

    // MARK: - System.GetOrientation

    /// Current app window orientation (portrait / landscape), derived from the
    /// window's aspect — the same signal the OrientationChanged push uses.
    /// Backs `System::orientation()` / `isLandscape()` for the cold read before
    /// the first OrientationChanged push.
    /// Returns:
    ///   - orientation: string - "portrait" or "landscape"
    class GetOrientation: BridgeFunction {
        func execute(parameters: [String: Any]) throws -> [String: Any] {
            func read() -> String {
                SystemFunctions.currentWindowOrientation()
            }
            // Bridge functions may run off the main thread; UIKit window reads
            // must be on main.
            let orientation = Thread.isMainThread ? read() : DispatchQueue.main.sync { read() }
            return ["orientation": orientation]
        }
    }
}
