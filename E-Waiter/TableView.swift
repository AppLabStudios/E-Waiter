import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct TableView: View {
    let restaurantId: String
    let deviceId: String
    let tableNumber: Int
    @State private var restaurantName: String = ""
    @State private var isLoading: Bool = true
    @State private var showLogoutAlert = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.85),
                    Color.mint.opacity(0.7),
                    Color.teal.opacity(0.6)
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
                                Image(systemName: "table.furniture.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom))
                                    .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                                
                                Text(restaurantName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Table \(tableNumber)")
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
                                StatCard(title: "Current Order", value: "None", icon: "list.clipboard", color: .orange)
                                StatCard(title: "Total Items", value: "0", icon: "number.circle", color: .blue)
                                StatCard(title: "Order Total", value: "$0.00", icon: "dollarsign.circle", color: .green)
                                StatCard(title: "Status", value: "Available", icon: "checkmark.circle", color: .green)
                            }
                            
                            // Action Buttons
                            VStack(spacing: 16) {
                                ActionButton(title: "View Menu", icon: "fork.knife", action: {})
                                ActionButton(title: "Place Order", icon: "plus.circle", action: {})
                                ActionButton(title: "Call Waiter", icon: "phone.circle", action: {})
                                ActionButton(title: "Request Bill", icon: "creditcard", action: {})
                                
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

#Preview {
    TableView(restaurantId: "preview", deviceId: "device1", tableNumber: 1)
} 