import SwiftUI
import FirebaseAuth

struct LogIn: View {
    @State private var email = ""
    @State private var password = ""
    @State private var restaurantId = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var isLoggedIn: Bool
    @Binding var userRole: UserRole
    
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.3),
                        Color(red: 0.2, green: 0.3, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Logo and title section
                        VStack(spacing: geometry.size.height > 800 ? 25 : 20) {
                            // App icon placeholder
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: geometry.size.height > 800 ? 100 : 80, height: geometry.size.height > 800 ? 100 : 80)
                                .overlay(
                                    Image(systemName: "fork.knife.circle.fill")
                                        .font(.system(size: geometry.size.height > 800 ? 50 : 40))
                                        .foregroundColor(.white)
                                )
                            
                            Text("E-Waiter")
                                .font(.system(size: geometry.size.height > 800 ? 42 : 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Restaurant Management System")
                                .font(.system(size: geometry.size.height > 800 ? 18 : 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, geometry.size.height * 0.08)
                        
                        Spacer(minLength: geometry.size.height * 0.1)
                        
                        // Login form
                        VStack(spacing: geometry.size.height > 800 ? 30 : 25) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: geometry.size.height > 800 ? 18 : 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 20)
                                    
                                    TextField("Enter your email", text: $email)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .foregroundColor(.white)
                                        .font(.system(size: geometry.size.height > 800 ? 18 : 16))
                                        .placeholder(when: email.isEmpty) {
                                            Text("Enter your email")
                                                .foregroundColor(.white.opacity(0.5))
                                                .font(.system(size: geometry.size.height > 800 ? 18 : 16))
                                        }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: geometry.size.height > 800 ? 18 : 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 20)
                                    
                                    SecureField("Enter your password", text: $password)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .foregroundColor(.white)
                                        .font(.system(size: geometry.size.height > 800 ? 18 : 16))
                                        .placeholder(when: password.isEmpty) {
                                            Text("Enter your password")
                                                .foregroundColor(.white.opacity(0.5))
                                                .font(.system(size: geometry.size.height > 800 ? 18 : 16))
                                        }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Restaurant ID field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Restaurant ID")
                                    .font(.system(size: geometry.size.height > 800 ? 18 : 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Image(systemName: "building.2.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(width: 20)
                                    
                                    TextField("Enter restaurant ID", text: $restaurantId)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        .foregroundColor(.white)
                                        .font(.system(size: geometry.size.height > 800 ? 18 : 16))
                                        .placeholder(when: restaurantId.isEmpty) {
                                            Text("Enter restaurant ID")
                                                .foregroundColor(.white.opacity(0.5))
                                                .font(.system(size: geometry.size.height > 800 ? 18 : 16))
                                        }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Sign In button
                            Button(action: signIn) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: geometry.size.height > 800 ? 20 : 18, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.size.height > 800 ? 55 : 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.2, green: 0.6, blue: 1.0),
                                                    Color(red: 0.1, green: 0.4, blue: 0.8)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || restaurantId.isEmpty)
                            .opacity((email.isEmpty || password.isEmpty || restaurantId.isEmpty) ? 0.6 : 1.0)
                        }
                        .padding(.horizontal, geometry.size.width > 768 ? 60 : 40)
                        .frame(maxWidth: min(geometry.size.width * 0.8, 500))
                        
                        Spacer(minLength: geometry.size.height * 0.1)
                        
                        // AppLab Studios branding
                        VStack(spacing: 8) {
                            Text("Powered by")
                                .font(.system(size: geometry.size.height > 800 ? 16 : 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("AppLab Studios")
                                .font(.system(size: geometry.size.height > 800 ? 20 : 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.bottom, geometry.size.height > 800 ? 40 : 30)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .alert("Login Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(authManager.$errorMessage) { errorMessage in
            if !errorMessage.isEmpty {
                alertMessage = errorMessage
                showAlert = true
            }
        }
        .onReceive(authManager.$isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                userRole = authManager.userRole
                isLoggedIn = true
            }
        }
    }
    
    private func signIn() {
        guard !email.isEmpty && !password.isEmpty && !restaurantId.isEmpty else {
            alertMessage = "Please fill in all fields"
            showAlert = true
            return
        }
        
        // Authenticate user and check device
        authManager.authenticateUser(email: email, password: password, restaurantId: restaurantId) { success in
            // The authentication result is handled by the onReceive modifiers above
        }
    }
}

// Extension for placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LogIn(isLoggedIn: .constant(false), userRole: .constant(.unactivated))
} 