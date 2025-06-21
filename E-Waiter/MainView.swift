import SwiftUI

struct MainView: View {
    @Binding var isLoggedIn: Bool
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Welcome section
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Welcome to E-Waiter")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Restaurant Management System")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Main content placeholder
                VStack(spacing: 30) {
                    Text("Main Application Content")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("This is where your main app functionality will be implemented.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Logout button
                Button(action: {
                    showLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Logout")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red)
                    )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .navigationBarHidden(true)
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                // Clear user session and return to login
                isLoggedIn = false
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

#Preview {
    MainView(isLoggedIn: .constant(true))
} 