import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum UserType: String, CaseIterable {
    case owner = "Owner"
    case staff = "Staff"
    case table = "Table"
}

struct DeviceRole {
    let userType: UserType?
    let tableNumber: Int
    
    var displayText: String {
        guard let userType = userType else { return "Unknown Role" }
        switch userType {
        case .owner:
            return "Owner Device"
        case .staff:
            return "Staff Device"
        case .table:
            return "Table \(tableNumber)"
        }
    }
    
    var icon: String {
        guard let userType = userType else { return "questionmark.circle" }
        switch userType {
        case .owner:
            return "crown.fill"
        case .staff:
            return "person.2.fill"
        case .table:
            return "table.furniture.fill"
        }
    }
    
    var color: Color {
        guard let userType = userType else { return .gray }
        switch userType {
        case .owner:
            return .orange
        case .staff:
            return .blue
        case .table:
            return .green
        }
    }
}

struct DeviceRoleDisplay: View {
    let role: DeviceRole
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: role.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(role.color)
            
            VStack(alignment: .leading, spacing: 3) {
                Text("Device Assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(role.displayText)
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(role.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct LogIn: View {
    @State private var email = ""
    @State private var password = ""
    @State private var restaurantId = ""
    @State private var selectedUserType: UserType = .owner
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var deviceRole: DeviceRole?
    @State private var isCheckingDeviceRole = true
    
    let onLoginSuccess: (UserType, String) -> Void
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !restaurantId.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Static gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.85),
                    Color.blue.opacity(0.7),
                    Color.cyan.opacity(0.6),
                    Color.mint.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    ZStack {
                        // Floating glass card
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.12), radius: 30, x: 0, y: 20)
                            .blur(radius: 0.5)
                        
                        VStack(spacing: 40) {
                            // Glowing app icon
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.25), Color.blue.opacity(0.18)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 130, height: 130)
                                    .shadow(color: Color.purple.opacity(0.25), radius: 30, x: 0, y: 10)
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 76))
                                    .foregroundStyle(LinearGradient(colors: [.white, .mint], startPoint: .top, endPoint: .bottom))
                                    .shadow(color: .white.opacity(0.7), radius: 10, x: 0, y: 4)
                            }
                            .padding(.top, 12)
                            
                            // Title & subtitle
                            VStack(spacing: 6) {
                                Text("E-Waiter")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Sign in to your restaurant")
                                    .font(.title2.weight(.medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Material fields
                            VStack(spacing: 22) {
                                materialField(icon: "envelope", placeholder: "Email", text: $email, isSecure: false)
                                materialField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)
                                materialField(icon: "building.2", placeholder: "Restaurant ID", text: $restaurantId, isSecure: false)
                            }
                            
                            // Device role display or selection
                            if isCheckingDeviceRole {
                                ProgressView("Checking device role...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            } else if let role = deviceRole {
                                // Show assigned role
                                DeviceRoleDisplay(role: role)
                            } else {
                                // Allow role selection for new device
                                SegmentedUserType(selected: $selectedUserType)
                            }
                            
                            // Sign In Button
                            Button(action: performLogin) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 22, weight: .bold))
                                    }
                                    Text(isLoading ? "Signing in..." : "Sign In")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(32)
                                .shadow(color: Color.purple.opacity(0.18), radius: 10, x: 0, y: 6)
                                .scaleEffect(isLoading ? 0.98 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
                            }
                            .disabled(isLoading || !isFormValid || isCheckingDeviceRole)
                            .opacity(isLoading || !isFormValid || isCheckingDeviceRole ? 0.6 : 1.0)
                            
                            // Powered by AppLab Studios
                            VStack(spacing: 4) {
                                Text("Powered by")
                                    .font(.caption)
                                    .foregroundColor(.secondary.opacity(0.7))
                                Text("AppLab Studios")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 12)
                        }
                        .padding(34)
                        .frame(maxWidth: 500)
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            checkDeviceRole()
        }
    }
    
    // MARK: - Material Field
    @ViewBuilder
    private func materialField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 26)
                .font(.system(size: 18))
            if isSecure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.primary)
                    .font(.system(size: 18))
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .foregroundColor(.primary)
                    .font(.system(size: 18))
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 22)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.blue.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Segmented User Type
    struct SegmentedUserType: View {
        @Binding var selected: UserType
        var body: some View {
            HStack(spacing: 0) {
                ForEach(UserType.allCases, id: \.self) { userType in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selected = userType
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: icon(for: userType))
                                .font(.system(size: 18, weight: .medium))
                            Text(userType.rawValue)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(backgroundForUserType(userType))
                        .foregroundColor(selected == userType ? .white : .primary)
                        .cornerRadius(24)
                        .shadow(color: selected == userType ? Color.purple.opacity(0.12) : .clear, radius: 6, x: 0, y: 2)
                        .overlay(overlayForUserType(userType))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.18))
            .clipShape(Capsule())
        }
        
        @ViewBuilder
        private func backgroundForUserType(_ userType: UserType) -> some View {
            if selected == userType {
                LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
            } else {
                Color.white.opacity(0.12)
            }
        }
        
        @ViewBuilder
        private func overlayForUserType(_ userType: UserType) -> some View {
            RoundedRectangle(cornerRadius: 22)
                .stroke(selected == userType ? Color.purple.opacity(0.3) : Color.blue.opacity(0.12), lineWidth: 1)
        }
        
        private func icon(for userType: UserType) -> String {
            switch userType {
            case .owner: return "crown"
            case .staff: return "person.2"
            case .table: return "table.furniture"
            }
        }
    }
    
    private func checkDeviceRole() {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let db = Firestore.firestore()
        
        // Add timeout for device role check
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if self.isCheckingDeviceRole {
                self.isCheckingDeviceRole = false
                // If timeout, treat as new device
            }
        }
        
        // Check if this device has been used in any restaurant
        db.collectionGroup("Sessions")
            .whereField("deviceId", isEqualTo: deviceId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isCheckingDeviceRole = false
                    
                    if let error = error {
                        print("Error checking device role: \(error.localizedDescription)")
                        // If error, treat as new device
                        return
                    }
                    
                    if let sessionDoc = snapshot?.documents.first {
                        let data = sessionDoc.data()
                        let userType = UserType(rawValue: data["userType"] as? String ?? "")
                        let tableNumber = data["tableNumber"] as? Int ?? 0
                        
                        self.deviceRole = DeviceRole(userType: userType, tableNumber: tableNumber)
                        self.selectedUserType = userType ?? .owner
                    }
                    // If no session found, deviceRole remains nil (new device)
                }
            }
    }
    
    private func performLogin() {
        // Don't allow login if still checking device role
        guard !isCheckingDeviceRole else { return }
        
        isLoading = true
        
        // Use the assigned role if available, otherwise use selected role
        let loginUserType = deviceRole?.userType ?? selectedUserType
        
        // Use Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    isLoading = false
                    alertMessage = "Login failed: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let userId = Auth.auth().currentUser?.uid else {
                    isLoading = false
                    alertMessage = "Could not get user ID."
                    showAlert = true
                    return
                }
                
                // Check if restaurantId exists in Firestore and userId matches
                let db = Firestore.firestore()
                let docRef = db.collection("Restaurants").document(restaurantId)
                docRef.getDocument { document, error in
                    DispatchQueue.main.async {
                        isLoading = false
                        if let error = error {
                            alertMessage = "Error checking restaurant ID: \(error.localizedDescription)"
                            showAlert = true
                            return
                        }
                        if let document = document, document.exists {
                            let data = document.data()
                            let restaurantUserId = data?["userId"] as? String
                            if restaurantUserId == userId {
                                // Login successful - call the callback
                                onLoginSuccess(loginUserType, restaurantId)
                            } else {
                                alertMessage = "You are not authorized for this restaurant ID."
                                showAlert = true
                            }
                        } else {
                            alertMessage = "Invalid Restaurant ID. Please check and try again."
                            showAlert = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LogIn { userType, restaurantId in
        print("Login successful: \(userType) for restaurant \(restaurantId)")
    }
} 