import SwiftUI
import FirebaseFirestore
import FirebaseAuth

enum UserType: String, CaseIterable {
    case owner = "Owner"
    case staff = "Staff"
    case table = "Table"
}

struct LogIn: View {
    @State private var email = ""
    @State private var password = ""
    @State private var restaurantId = ""
    @State private var selectedUserType: UserType = .owner
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
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
                        
                        VStack(spacing: 32) {
                            // Glowing app icon
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.25), Color.blue.opacity(0.18)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 110, height: 110)
                                    .shadow(color: Color.purple.opacity(0.25), radius: 30, x: 0, y: 10)
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(LinearGradient(colors: [.white, .mint], startPoint: .top, endPoint: .bottom))
                                    .shadow(color: .white.opacity(0.7), radius: 10, x: 0, y: 4)
                            }
                            .padding(.top, 8)
                            
                            // Title & subtitle
                            VStack(spacing: 4) {
                                Text("E-Waiter")
                                    .font(.system(size: 38, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Sign in to your restaurant")
                                    .font(.title3.weight(.medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            // Material fields
                            VStack(spacing: 18) {
                                materialField(icon: "envelope", placeholder: "Email", text: $email, isSecure: false)
                                materialField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)
                                materialField(icon: "building.2", placeholder: "Restaurant ID", text: $restaurantId, isSecure: false)
                            }
                            
                            // User type segmented control
                            SegmentedUserType(selected: $selectedUserType)
                            
                            // Sign In Button
                            Button(action: performLogin) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 20, weight: .bold))
                                    }
                                    Text(isLoading ? "Signing in..." : "Sign In")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(30)
                                .shadow(color: Color.purple.opacity(0.18), radius: 10, x: 0, y: 6)
                                .scaleEffect(isLoading ? 0.98 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
                            }
                            .disabled(isLoading || !isFormValid)
                            .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
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
        .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
            Button("OK") {
                if isSuccess {
                    resetForm()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Material Field
    @ViewBuilder
    private func materialField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 22)
            if isSecure {
                SecureField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.primary)
            } else {
                TextField(placeholder, text: text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.blue.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
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
                                .font(.system(size: 16, weight: .medium))
                            Text(userType.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selected == userType {
                                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                                        .clipShape(Capsule())
                                        .matchedGeometryEffect(id: "selectedType", in: Namespace().wrappedValue)
                                } else {
                                    Color.white.opacity(0.12)
                                }
                            }
                        )
                        .foregroundColor(selected == userType ? .white : .primary)
                        .cornerRadius(22)
                        .shadow(color: selected == userType ? Color.purple.opacity(0.12) : .clear, radius: 6, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(selected == userType ? Color.purple.opacity(0.3) : Color.blue.opacity(0.12), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.18))
            .clipShape(Capsule())
        }
        private func icon(for userType: UserType) -> String {
            switch userType {
            case .owner: return "crown"
            case .staff: return "person.2"
            case .table: return "table.furniture"
            }
        }
    }
    
    private func resetForm() {
        email = ""
        password = ""
        restaurantId = ""
        selectedUserType = .owner
    }
    
    private func performLogin() {
        isLoading = true
        
        // Use Firebase Authentication
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    isLoading = false
                    isSuccess = false
                    alertMessage = "Login failed: \(error.localizedDescription)"
                    showAlert = true
                    return
                }
                
                guard let userId = Auth.auth().currentUser?.uid else {
                    isLoading = false
                    isSuccess = false
                    alertMessage = "Could not get user ID."
                    showAlert = true
                    return
                }
                
                // Check if restaurantId exists in Firestore and userId matches
                let db = Firestore.firestore()
                let docRef = db.collection("Restaurants").document(restaurantId)
                docRef.getDocument { document, error in
                    isLoading = false
                    if let error = error {
                        isSuccess = false
                        alertMessage = "Error checking restaurant ID: \(error.localizedDescription)"
                        showAlert = true
                        return
                    }
                    if let document = document, document.exists {
                        let data = document.data()
                        let restaurantUserId = data?["userId"] as? String
                        if restaurantUserId == userId {
                            isSuccess = true
                            alertMessage = "Login successful! Welcome to E-Waiter"
                            showAlert = true
                        } else {
                            isSuccess = false
                            alertMessage = "You are not authorized for this restaurant ID."
                            showAlert = true
                        }
                    } else {
                        isSuccess = false
                        alertMessage = "Invalid Restaurant ID. Please check and try again."
                        showAlert = true
                    }
                }
            }
        }
    }
}

#Preview {
    LogIn()
} 