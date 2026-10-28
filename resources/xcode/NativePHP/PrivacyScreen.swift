import UIKit

/// Privacy screen: while it is on, an opaque cover goes over each window
/// scene as that scene enters the background, so the snapshot iOS saves for
/// the app switcher shows the cover rather than the app's content. Backs
/// `System::setPrivacyScreen()` (`System.SetPrivacyScreen`). Android twin:
/// `ui/PrivacyScreen.kt`.
///
/// iOS has no equivalent of Android's FLAG_SECURE, so screenshots and screen
/// recording are not blocked here.
///
/// The cover goes up when a scene enters the background, not when it resigns
/// active. Face ID, permission alerts, Control Center and Notification Center
/// only make the app inactive, and covering on those would flash over the
/// app. The trade-off: while the user has the app switcher open straight over
/// the app, its card still shows the live app until they move on.
///
/// Covers are kept per scene, so an iPad window sent to the background while
/// another one stays in front is covered on its own.
///
/// The setting lives in process memory, like Android's: an app that wants it
/// everywhere turns it on from PHP at startup. Main thread only.
final class PrivacyScreen {
    static let shared = PrivacyScreen()

    private(set) var enabled = false
    private var observers: [NSObjectProtocol] = []
    private var covers: [ObjectIdentifier: UIWindow] = [:]

    private init() {}

    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled

        guard enabled else {
            covers.values.forEach { $0.isHidden = true }
            covers.removeAll()
            return
        }

        observeLifecycle()

        // Turned on while some scenes are already in the background (e.g. from
        // a background task): cover those now, or their next snapshot and the
        // return to the foreground would go uncovered.
        for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
        where scene.activationState == .background {
            cover(scene)
        }
    }

    private func observeLifecycle() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] note in
                guard let scene = note.object as? UIWindowScene else { return }
                self?.cover(scene)
            },
            center.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] note in
                guard let scene = note.object as? UIWindowScene else { return }
                self?.uncover(scene)
            },
            center.addObserver(forName: UIScene.didDisconnectNotification, object: nil, queue: .main) { [weak self] note in
                guard let scene = note.object as? UIWindowScene else { return }
                self?.uncover(scene)
            },
        ]
    }

    private func cover(_ scene: UIWindowScene) {
        let key = ObjectIdentifier(scene)
        guard enabled, covers[key] == nil else { return }

        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.rootViewController = controller
        window.isHidden = false
        covers[key] = window
    }

    private func uncover(_ scene: UIWindowScene) {
        covers.removeValue(forKey: ObjectIdentifier(scene))?.isHidden = true
    }
}
