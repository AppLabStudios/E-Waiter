import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OwnerView: View {
    let restaurantId: String
    let deviceId: String
    @State private var restaurantName: String = ""
    @State private var isLoading: Bool = true
    @State private var showLogoutAlert = false
    
    var body: some View {
        ZStack {
            // Background gradient
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
            
            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            } else {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header Card
                            VStack(spacing: 16) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                                    .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 5)
                                
                                Text(restaurantName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Owner Dashboard")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Device ID: \(deviceId)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            )
                            
                            // Quick Stats
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                StatCard(title: "Active Tables", value: "0", icon: "table.furniture", color: .green)
                                StatCard(title: "Customer Satisfaction", value: "4.8★", icon: "star.fill", color: .yellow)
                                StatCard(title: "Orders Today", value: "0", icon: "list.clipboard", color: .orange)
                                StatCard(title: "Revenue", value: "$0", icon: "dollarsign.circle", color: .purple)
                            }
                            
                            // Action Buttons
                            VStack(spacing: 16) {
                                ActionButton(title: "Manage Menu", icon: "fork.knife", action: {})
                                ActionButton(title: "View Orders", icon: "list.bullet", action: {})
                                ActionButton(title: "Analytics", icon: "chart.bar", action: {})
                                
                                // Logout Button
                                Button(action: {
                                    showLogoutAlert = true
                                }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.red)
                                            .frame(width: 30)
                                        
                                        Text("Logout")
                                            .font(.headline)
                                            .foregroundColor(.red)
                                        
                                        Spacer()
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: 600)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .onAppear {
            loadRestaurantData()
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    private func loadRestaurantData() {
        let db = Firestore.firestore()
        db.collection("Restaurants").document(restaurantId).getDocument { document, error in
            DispatchQueue.main.async {
                isLoading = false
                if let document = document, document.exists {
                    restaurantName = document.data()?["restaurantName"] as? String ?? "Restaurant"
                }
            }
        }
    }
    
    private func logout() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Deactivate the current session in the restaurant's Sessions subcollection
        db.collection("Restaurants").document(restaurantId)
            .collection("Sessions")
            .whereField("userId", isEqualTo: userId)
            .whereField("deviceId", isEqualTo: deviceId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let document = snapshot?.documents.first {
                    document.reference.updateData([
                        "isActive": false,
                        "logoutTime": FieldValue.serverTimestamp()
                    ])
                }
                
                // Sign out from Firebase Auth
                try? Auth.auth().signOut()
            }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            if title == "Customer Satisfaction" {
                VStack(spacing: 0) {
                    Text("Customer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Satisfaction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
            } else {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    OwnerView(restaurantId: "preview", deviceId: "device1")
} 