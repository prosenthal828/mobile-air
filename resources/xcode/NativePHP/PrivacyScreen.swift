import UIKit

/// Privacy screen: while it is on, an opaque cover goes over the app's window
/// scenes when the app enters the background, so the snapshot iOS keeps for
/// the app switcher shows the cover rather than the app's content. Backs
/// `System::setPrivacyScreen()` (`System.SetPrivacyScreen`). Android twin:
/// `ui/PrivacyScreen.kt`.
///
/// iOS has no equivalent of Android's FLAG_SECURE, so screenshots and screen
/// recording are not blocked here.
///
/// The cover goes up on didEnterBackground rather than willResignActive.
/// Face ID, permission alerts, Control Center and Notification Center only
/// make the app inactive, and covering on those would flash over the app.
///
/// The setting lives in process memory, like Android's: an app that wants it
/// everywhere turns it on from PHP at boot. Main thread only.
final class PrivacyScreen {
    static let shared = PrivacyScreen()

    private(set) var enabled = false
    private var observers: [NSObjectProtocol] = []
    private var covers: [UIWindow] = []

    private init() {}

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled

        if enabled {
            observeLifecycle()
        } else {
            hideCover()
        }
    }

    private func observeLifecycle() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
                self?.showCover()
            },
            center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
                self?.hideCover()
            },
        ]
    }

    private func showCover() {
        guard enabled, covers.isEmpty else { return }

        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
            let controller = UIViewController()
            controller.view.backgroundColor = .systemBackground

            let window = UIWindow(windowScene: scene)
            window.windowLevel = .alert + 1
            window.rootViewController = controller
            window.isHidden = false
            covers.append(window)
        }
    }

    private func hideCover() {
        covers.forEach { $0.isHidden = true }
        covers.removeAll()
    }
}
