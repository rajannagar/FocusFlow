import Foundation

struct AuthSessionSnapshot {
    let userId: UUID
    let accessToken: String   // Supabase user JWT
    let isGuest: Bool
}

protocol AuthSessionProviding {
    func snapshot() -> AuthSessionSnapshot?
}

final class AuthSessionProvider: AuthSessionProviding {
    static let shared = AuthSessionProvider()
    private init() {}

    func snapshot() -> AuthSessionSnapshot? {
        guard let session = AuthManager.shared.currentUserSession else { return nil }

        if session.isGuest {
            return AuthSessionSnapshot(userId: session.userId, accessToken: "", isGuest: true)
        }

        guard let token = session.accessToken, token.isEmpty == false else {
            // No token stored => keep sync OFF
            return nil
        }

        // ✅ If token is expired, clear it so engines stop hammering Supabase with 401s
        if JWTToken.isExpired(token) {
            AuthManager.shared.clearAccessTokenButKeepUser()
            return nil
        }

        return AuthSessionSnapshot(userId: session.userId, accessToken: token, isGuest: false)
    }
}
