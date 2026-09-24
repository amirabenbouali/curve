import Foundation
import Observation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

/// Wraps Firebase Auth for Curve's optional account layer. The app is fully
/// usable signed-out (local SwiftData only); signing in additionally enables
/// sync via SyncManager. All failures surface Firebase's own message text
/// rather than a generic "something went wrong".
@Observable
final class AuthManager {
    static let shared = AuthManager()

    private(set) var currentUserID: String?
    private(set) var currentUserEmail: String?
    var isSignedIn: Bool { currentUserID != nil }

    /// True once GoogleService-Info.plist is present and FirebaseApp.configure()
    /// has actually run — lets the UI fail gracefully instead of crashing
    /// while that file hasn't been added yet.
    private(set) var isFirebaseConfigured = false

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        isFirebaseConfigured = FirebaseApp.app() != nil
        guard isFirebaseConfigured else { return }
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUserID = user?.uid
            self?.currentUserEmail = user?.email
        }
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }

    // MARK: - Email / password

    func signUp(email: String, password: String) async throws {
        try ensureConfigured()
        try await Auth.auth().createUser(withEmail: email, password: password)
    }

    func logIn(email: String, password: String) async throws {
        try ensureConfigured()
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func sendPasswordReset(email: String) async throws {
        try ensureConfigured()
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    // MARK: - Google

    @MainActor
    func signInWithGoogle() async throws {
        try ensureConfigured()
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.notConfigured
        }
        guard let presenter = Self.topViewController() else {
            throw AuthError.noPresenter
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.noGoogleToken
        }
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
        try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Sign out

    func signOut() throws {
        try ensureConfigured()
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Helpers

    private func ensureConfigured() throws {
        guard isFirebaseConfigured else { throw AuthError.notConfigured }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              var top = scene.keyWindow?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    enum AuthError: LocalizedError {
        case notConfigured
        case noPresenter
        case noGoogleToken

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Sign-in isn't set up yet — GoogleService-Info.plist is missing from the project."
            case .noPresenter:
                return "Couldn't find a screen to present sign-in from."
            case .noGoogleToken:
                return "Google didn't return a valid sign-in token. Please try again."
            }
        }
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first { $0.isKeyWindow }
    }
}
