import Foundation
import SwiftUI

class AppStateManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userRole: UserRole = .unactivated
    @Published var authManager = AuthManager()
    
    // Singleton pattern for global access
    static let shared = AppStateManager()
    
    private init() {}
    
    // Logout function that can be called from any view
    func logout() {
        authManager.signOut()
        isLoggedIn = false
        userRole = .unactivated
    }
    
    // Update authentication state
    func updateAuthState(isAuthenticated: Bool, role: UserRole) {
        isLoggedIn = isAuthenticated
        userRole = role
    }
} 