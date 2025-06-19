import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @State private var isAuthenticated = false
    @State private var currentUser: User?
    @State private var userType: UserType?
    @State private var restaurantId: String = ""
    @State private var deviceId: String = ""
    @State private var tableNumber: Int = 0
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Loading screen
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.85),
                            Color.blue.opacity(0.7),
                            Color.cyan.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(LinearGradient(colors: [.white, .mint], startPoint: .top, endPoint: .bottom))
                            .shadow(color: .white.opacity(0.7), radius: 15, x: 0, y: 8)
                        
                        Text("E-Waiter")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    }
                }
            } else if isAuthenticated, let user = currentUser, let type = userType {
                // Authenticated user - show appropriate view
                switch type {
                case .owner:
                    OwnerView(restaurantId: restaurantId, deviceId: deviceId)
                case .staff:
                    StaffView(restaurantId: restaurantId, deviceId: deviceId)
                case .table:
                    TableView(restaurantId: restaurantId, deviceId: deviceId, tableNumber: tableNumber)
                }
            } else {
                // Not authenticated - show login
                LogIn(onLoginSuccess: handleLoginSuccess)
            }
        }
        .onAppear {
            checkAuthenticationStatus()
        }
    }
    
    private func checkAuthenticationStatus() {
        Auth.auth().addStateDidChangeListener { auth, user in
            DispatchQueue.main.async {
                if let user = user {
                    // User is signed in, check if we have stored session data
                    checkStoredSessionData(userId: user.uid)
                } else {
                    // User is signed out
                    isAuthenticated = false
                    currentUser = nil
                    userType = nil
                    restaurantId = ""
                    deviceId = ""
                    tableNumber = 0
                    isLoading = false
                }
            }
        }
    }
    
    private func checkStoredSessionData(userId: String) {
        let db = Firestore.firestore()
        
        // Check if user has an active session in any restaurant's sessions subcollection
        db.collection("Restaurants").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                if let documents = snapshot?.documents {
                    // Search through all restaurants for active sessions
                    self.searchForActiveSession(in: documents, userId: userId, currentIndex: 0)
                } else {
                    isLoading = false
                }
            }
        }
    }
    
    private func searchForActiveSession(in documents: [QueryDocumentSnapshot], userId: String, currentIndex: Int) {
        guard currentIndex < documents.count else {
            // No active session found in any restaurant
            isAuthenticated = false
            currentUser = nil
            userType = nil
            restaurantId = ""
            deviceId = ""
            tableNumber = 0
            isLoading = false
            return
        }
        
        let restaurantDoc = documents[currentIndex]
        let currentRestaurantId = restaurantDoc.documentID
        let db = Firestore.firestore()
        
        // Check sessions subcollection for this restaurant
        db.collection("Restaurants").document(currentRestaurantId)
            .collection("Sessions")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { sessionSnapshot, sessionError in
                DispatchQueue.main.async {
                    if let sessionDoc = sessionSnapshot?.documents.first {
                        let data = sessionDoc.data()
                        userType = UserType(rawValue: data["userType"] as? String ?? "")
                        self.restaurantId = currentRestaurantId
                        deviceId = data["deviceId"] as? String ?? ""
                        tableNumber = data["tableNumber"] as? Int ?? 0
                        currentUser = Auth.auth().currentUser
                        isAuthenticated = true
                        isLoading = false
                    } else {
                        // Continue searching in next restaurant
                        self.searchForActiveSession(in: documents, userId: userId, currentIndex: currentIndex + 1)
                    }
                }
            }
    }
    
    private func handleLoginSuccess(userType: UserType, restaurantId: String) {
        self.userType = userType
        self.restaurantId = restaurantId
        self.currentUser = Auth.auth().currentUser
        
        // Generate device ID and handle table numbering
        generateDeviceIdAndSaveSession(userType: userType, restaurantId: restaurantId)
    }
    
    private func generateDeviceIdAndSaveSession(userType: UserType, restaurantId: String) {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        self.deviceId = deviceId
        
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // First, check if this device has ever been used before (any role)
        db.collection("Restaurants").document(restaurantId)
            .collection("Sessions")
            .whereField("deviceId", isEqualTo: deviceId)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error checking device sessions: \(error.localizedDescription)")
                        // If error, treat as new device
                        self.createNewSession(userType: userType, restaurantId: restaurantId, deviceId: deviceId)
                        return
                    }
                    
                    if let existingSession = snapshot?.documents.first {
                        // Device has been used before - check if it's trying to change roles
                        let existingData = existingSession.data()
                        let existingUserType = UserType(rawValue: existingData["userType"] as? String ?? "")
                        let existingTableNumber = existingData["tableNumber"] as? Int ?? 0
                        
                        if existingUserType != userType {
                            // Device is trying to change roles - not allowed
                            self.showRoleChangeError(existingUserType: existingUserType, existingTableNumber: existingTableNumber)
                            return
                        }
                        
                        // Same role - update existing session
                        existingSession.reference.updateData([
                            "userId": userId,
                            "lastActivity": FieldValue.serverTimestamp(),
                            "isActive": true
                        ]) { error in
                            DispatchQueue.main.async {
                                if error == nil {
                                    self.userType = existingUserType
                                    self.tableNumber = existingTableNumber
                                    self.isAuthenticated = true
                                }
                            }
                        }
                    } else {
                        // New device - create first session
                        self.createNewSession(userType: userType, restaurantId: restaurantId, deviceId: deviceId)
                    }
                }
            }
    }
    
    private func createNewSession(userType: UserType, restaurantId: String, deviceId: String) {
        if userType == .table {
            // For tables, we need to determine the table number
            self.determineTableNumber(restaurantId: restaurantId, deviceId: deviceId) { tableNumber in
                self.tableNumber = tableNumber
                self.saveSessionToDatabase(userType: userType, restaurantId: restaurantId, deviceId: deviceId, tableNumber: tableNumber)
            }
        } else {
            // For owner and staff, table number is 0
            self.tableNumber = 0
            self.saveSessionToDatabase(userType: userType, restaurantId: restaurantId, deviceId: deviceId, tableNumber: 0)
        }
    }
    
    private func showRoleChangeError(existingUserType: UserType?, existingTableNumber: Int) {
        var errorMessage = "This device is already assigned to "
        
        if let userType = existingUserType {
            switch userType {
            case .owner:
                errorMessage += "Owner role"
            case .staff:
                errorMessage += "Staff role"
            case .table:
                errorMessage += "Table \(existingTableNumber)"
            }
        } else {
            errorMessage += "another role"
        }
        
        errorMessage += ". Each device can only be used for one specific role. Please use a different device or contact your administrator."
        
        // Show error alert
        let alert = UIAlertController(title: "Device Role Locked", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Sign out the user
            try? Auth.auth().signOut()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func determineTableNumber(restaurantId: String, deviceId: String, completion: @escaping (Int) -> Void) {
        let db = Firestore.firestore()
        
        // Get all active table sessions for this restaurant
        db.collection("Restaurants").document(restaurantId)
            .collection("Sessions")
            .whereField("userType", isEqualTo: UserType.table.rawValue)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                let existingTableNumbers = snapshot?.documents.compactMap { doc in
                    doc.data()["tableNumber"] as? Int
                } ?? []
                
                // Find the next available table number
                let nextTableNumber = (existingTableNumbers.max() ?? 0) + 1
                completion(nextTableNumber)
            }
    }
    
    private func saveSessionToDatabase(userType: UserType, restaurantId: String, deviceId: String, tableNumber: Int) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let sessionData: [String: Any] = [
            "userId": userId,
            "deviceId": deviceId,
            "userType": userType.rawValue,
            "tableNumber": tableNumber,
            "isActive": true,
            "loginTime": FieldValue.serverTimestamp(),
            "lastActivity": FieldValue.serverTimestamp()
        ]
        
        // Save session to the restaurant's Sessions subcollection
        db.collection("Restaurants").document(restaurantId)
            .collection("Sessions")
            .addDocument(data: sessionData) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        self.isAuthenticated = true
                    }
                }
            }
    }
}

#Preview {
    MainView()
} 