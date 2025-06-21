import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthManager: ObservableObject {
    private let db = Firestore.firestore()
    private let deviceManager = DeviceManager()
    
    @Published var currentUser: User?
    @Published var userRole: UserRole = .unactivated
    @Published var deviceInfo: DeviceInfo?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    // Authenticate user and check device
    func authenticateUser(email: String, password: String, restaurantId: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = ""
        
        print("🔍 Starting authentication for email: \(email), restaurant: \(restaurantId)")
        
        // First, check if the device is already assigned to any restaurant
        deviceManager.checkDeviceAssignedToAnyRestaurant { [weak self] existingDevice in
            guard let self = self else { return }
            
            if let existingDevice = existingDevice {
                // Device is already assigned to a restaurant
                if existingDevice.restaurantId == restaurantId {
                    // Device is assigned to the same restaurant, proceed with normal flow
                    print("✅ Device is already assigned to this restaurant")
                    self.proceedWithAuthentication(email: email, password: password, restaurantId: restaurantId, completion: completion)
                } else {
                    // Device is assigned to a different restaurant
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "This device is already assigned to another restaurant. Please use a different device or contact the restaurant owner to reassign this device."
                        completion(false)
                    }
                }
            } else {
                // Device is not assigned to any restaurant, proceed with normal flow
                print("✅ Device is not assigned to any restaurant, proceeding with authentication")
                self.proceedWithAuthentication(email: email, password: password, restaurantId: restaurantId, completion: completion)
            }
        }
    }
    
    // Proceed with the actual authentication process
    private func proceedWithAuthentication(email: String, password: String, restaurantId: String, completion: @escaping (Bool) -> Void) {
        // First, authenticate with Firebase
        print("🔐 Starting Firebase authentication for email: \(email)")
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firebase auth error: \(error.localizedDescription)")
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }
                
                guard let user = result?.user else {
                    print("❌ Firebase auth failed - no user returned")
                    self.isLoading = false
                    self.errorMessage = "Authentication failed"
                    completion(false)
                    return
                }
                
                print("✅ Firebase authentication successful for user: \(user.email ?? "unknown")")
                self.currentUser = user
                
                // Now check if the restaurant exists and user has access
                self.checkRestaurantAccess(restaurantId: restaurantId, userEmail: email) { [weak self] hasAccess in
                    guard let self = self else { return }
                    
                    if !hasAccess {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "You don't have access to this restaurant. Please check your credentials or contact the restaurant owner."
                            completion(false)
                        }
                        return
                    }
                    
                    print("✅ User has access to restaurant, checking device status")
                    
                    // Now check if this device exists in the restaurant's devices collection
                    self.deviceManager.checkDeviceExists(restaurantId: restaurantId) { deviceInfo in
                        if let deviceInfo = deviceInfo {
                            // Device exists, check if it's activated
                            self.deviceInfo = deviceInfo
                            print("📱 Device found: \(deviceInfo.deviceId), role: \(deviceInfo.deviceRole), activated: \(deviceInfo.activated)")
                            
                            if deviceInfo.activated {
                                // Device is activated, determine role and proceed
                                self.userRole = UserRole(from: deviceInfo.deviceRole)
                                self.isAuthenticated = true
                                
                                print("✅ Device activated, role: \(deviceInfo.deviceRole)")
                                
                                // Update last login time
                                self.deviceManager.updateLastLogin(restaurantId: restaurantId) { _ in }
                                
                                self.isLoading = false
                                completion(true)
                            } else {
                                // Device exists but not activated
                                self.userRole = .unactivated
                                self.isAuthenticated = false
                                self.isLoading = false
                                self.errorMessage = "This device is not activated. Please contact the restaurant owner."
                                completion(false)
                            }
                        } else {
                            // Device doesn't exist, save it as new unactivated device
                            print("📱 Device not found, creating new device")
                            self.deviceManager.saveNewDevice(restaurantId: restaurantId) { success in
                                if success {
                                    self.userRole = .unactivated
                                    self.isAuthenticated = false
                                    self.isLoading = false
                                    self.errorMessage = "New device registered. Please contact the restaurant owner to activate this device."
                                    completion(false)
                                } else {
                                    self.isLoading = false
                                    self.errorMessage = "Failed to register device. Please try again."
                                    completion(false)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Check if restaurant exists and user has access
    func checkRestaurantAccess(restaurantId: String, userEmail: String, completion: @escaping (Bool) -> Void) {
        let restaurantRef = db.collection("Restaurants").document(restaurantId)
        
        print("🔍 Checking restaurant access for ID: \(restaurantId)")
        
        restaurantRef.getDocument { document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error checking restaurant: \(error)")
                    completion(false)
                    return
                }
                
                guard let document = document, document.exists else {
                    print("❌ Restaurant document does not exist: \(restaurantId)")
                    completion(false)
                    return
                }
                
                print("✅ Restaurant document found")
                
                // Get all document data for debugging
                let data = document.data() ?? [:]
                print("📄 Restaurant data: \(data)")
                
                // Check if the authenticated user's email matches any of the access fields
                let possibleFieldNames = ["userId", "userEmail", "email", "ownerEmail", "user_id", "owner_id"]
                var foundMatch = false
                
                for fieldName in possibleFieldNames {
                    if let fieldValue = data[fieldName] as? String {
                        print("🔍 Checking field '\(fieldName)': '\(fieldValue)' against email: '\(userEmail)'")
                        if fieldValue.lowercased() == userEmail.lowercased() {
                            print("✅ Match found in field '\(fieldName)'")
                            foundMatch = true
                            break
                        }
                    }
                }
                
                if foundMatch {
                    print("✅ User has access to restaurant")
                    completion(true)
                } else {
                    print("❌ User does not have access to restaurant")
                    print("❌ Available fields: \(data.keys)")
                    print("❌ User email: \(userEmail)")
                    completion(false)
                }
            }
        }
    }
    
    // Sign out user
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            userRole = .unactivated
            deviceInfo = nil
            isAuthenticated = false
            errorMessage = ""
        } catch {
            errorMessage = "Error signing out: \(error.localizedDescription)"
        }
    }
} 