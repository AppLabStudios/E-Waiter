import SwiftUI

struct StaffView: View {
    @State private var showLogoutAlert = false
    @EnvironmentObject var appState: AppStateManager
    @State private var selectedTab = 0
    @State private var animateCards = false
    @State private var showWelcomeAnimation = false
    @State private var searchText = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.08, green: 0.12, blue: 0.18),
                        Color(red: 0.12, green: 0.16, blue: 0.22)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Main content
                    mainContentView(geometry: geometry)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showWelcomeAnimation = true
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animateCards = true
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                appState.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Staff Dashboard")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showWelcomeAnimation ? 1 : 0)
                        .offset(y: showWelcomeAnimation ? 0 : -20)
                    
                    Text("Service Management System")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showWelcomeAnimation ? 1 : 0)
                        .offset(y: showWelcomeAnimation ? 0 : -10)
                }
                
                Spacer()
                
                // Stats cards
                HStack(spacing: 20) {
                    StatCard(title: "Active Orders", value: "12", icon: "list.bullet", color: .blue)
                    StatCard(title: "Pending", value: "5", icon: "clock", color: .orange)
                    StatCard(title: "Completed", value: "18", icon: "checkmark.circle", color: .green)
                }
                .opacity(showWelcomeAnimation ? 1 : 0)
                .offset(x: showWelcomeAnimation ? 0 : 50)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            // Tab bar
            tabBarView
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.1), Color.clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(height: 1)
                        .offset(y: 1)
                )
        )
    }
    
    // MARK: - Tab Bar
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tabIcons[index])
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                        
                        Text(tabTitles[index])
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedTab == index ? .white : .white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Rectangle()
                            .fill(selectedTab == index ? Color.white.opacity(0.1) : Color.clear)
                            .cornerRadius(12)
                    )
                }
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }
    
    // MARK: - Main Content
    private func mainContentView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 30) {
                switch selectedTab {
                case 0:
                    ordersTab
                case 1:
                    tablesTab
                case 2:
                    communicationTab
                case 3:
                    notificationsTab
                default:
                    ordersTab
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Orders Tab
    private var ordersTab: some View {
        VStack(spacing: 30) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))
                
                TextField("Search orders...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .offset(y: animateCards ? 0 : 30)
            .opacity(animateCards ? 1 : 0)
            .animation(.easeOut(duration: 0.6).delay(0.1), value: animateCards)
            
            // Orders grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                ForEach(0..<6) { index in
                    OrderCard(
                        orderNumber: "Order #\(1001 + index)",
                        tableNumber: "Table \(index + 1)",
                        status: orderStatuses[index],
                        items: orderItems[index],
                        time: orderTimes[index],
                        color: orderColors[index]
                    )
                    .offset(y: animateCards ? 0 : 50)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1 + 0.2), value: animateCards)
                }
            }
        }
    }
    
    // MARK: - Tables Tab
    private var tablesTab: some View {
        VStack(spacing: 30) {
            // Table status overview
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                ForEach(0..<9) { index in
                    TableStatusCard(
                        tableNumber: "\(index + 1)",
                        status: tableStatuses[index],
                        customers: tableCustomers[index],
                        time: tableTimes[index]
                    )
                    .offset(y: animateCards ? 0 : 50)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
                }
            }
        }
    }
    
    // MARK: - Communication Tab
    private var communicationTab: some View {
        VStack(spacing: 30) {
            // Communication tools
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                ForEach(0..<4) { index in
                    CommunicationCard(
                        title: communicationTitles[index],
                        subtitle: communicationSubtitles[index],
                        icon: communicationIcons[index],
                        color: communicationColors[index]
                    )
                    .offset(y: animateCards ? 0 : 50)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
                }
            }
        }
    }
    
    // MARK: - Notifications Tab
    private var notificationsTab: some View {
        VStack(spacing: 30) {
            // Notifications list
            VStack(spacing: 16) {
                ForEach(0..<8) { index in
                    NotificationItem(
                        title: notificationTitles[index],
                        message: notificationMessages[index],
                        time: notificationTimes[index],
                        type: notificationTypes[index]
                    )
                    .offset(y: animateCards ? 0 : 30)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
                }
            }
        }
    }
    
    // MARK: - Data Arrays
    private let tabIcons = ["list.bullet", "table.furniture", "message.fill", "bell.fill"]
    private let tabTitles = ["Orders", "Tables", "Communication", "Notifications"]
    
    private let orderStatuses = ["Pending", "In Progress", "Ready", "Delivered", "Pending", "In Progress"]
    private let orderItems = ["Pasta Carbonara", "Pizza Margherita", "Caesar Salad", "Steak", "Burger", "Fish & Chips"]
    private let orderTimes = ["5 min ago", "12 min ago", "8 min ago", "15 min ago", "3 min ago", "20 min ago"]
    private let orderColors: [Color] = [.orange, .blue, .green, .purple, .orange, .blue]
    
    private let tableStatuses = ["Occupied", "Available", "Reserved", "Occupied", "Available", "Occupied", "Available", "Reserved", "Occupied"]
    private let tableCustomers = ["4 guests", "Empty", "Reserved", "2 guests", "Empty", "6 guests", "Empty", "Reserved", "3 guests"]
    private let tableTimes = ["45 min", "", "7:30 PM", "20 min", "", "15 min", "", "8:00 PM", "30 min"]
    
    private let communicationTitles = ["Customer Chat", "Kitchen Communication", "Manager Alert", "Team Broadcast"]
    private let communicationSubtitles = ["Chat with customers", "Talk to kitchen", "Alert management", "Send team message"]
    private let communicationIcons = ["message.fill", "mic.fill", "exclamationmark.triangle", "megaphone.fill"]
    private let communicationColors: [Color] = [.blue, .green, .red, .purple]
    
    private let notificationTitles = ["New Order", "Table Ready", "Customer Request", "Kitchen Alert", "Payment Received", "Table Available", "Reservation", "System Update"]
    private let notificationMessages = ["Order #1005 received", "Table 3 is ready", "Customer needs assistance", "Kitchen is backed up", "Payment of $45.50 received", "Table 7 is now available", "New reservation for 8:00 PM", "System maintenance in 10 minutes"]
    private let notificationTimes = ["2 min ago", "5 min ago", "8 min ago", "12 min ago", "15 min ago", "18 min ago", "25 min ago", "30 min ago"]
    private let notificationTypes = ["order", "table", "customer", "alert", "payment", "table", "reservation", "system"]
}

// MARK: - Supporting Views
struct OrderCard: View {
    let orderNumber: String
    let tableNumber: String
    let status: String
    let items: String
    let time: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(orderNumber)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(tableNumber)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text(status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(color.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(color, lineWidth: 1)
                            )
                    )
            }
            
            Text(items)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
            
            HStack {
                Text(time)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Button("View Details") {
                    // Handle tap
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
            }
        }
        .padding(20)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TableStatusCard: View {
    let tableNumber: String
    let status: String
    let customers: String
    let time: String
    
    var statusColor: Color {
        switch status {
        case "Available": return .green
        case "Occupied": return .orange
        case "Reserved": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Table \(tableNumber)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text(status)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(statusColor)
            
            if status != "Available" {
                Text(customers)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                if !time.isEmpty {
                    Text(time)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(20)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct CommunicationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(24)
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct NotificationItem: View {
    let title: String
    let message: String
    let time: String
    let type: String
    
    var typeColor: Color {
        switch type {
        case "order": return .blue
        case "table": return .green
        case "customer": return .orange
        case "alert": return .red
        case "payment": return .purple
        case "reservation": return .blue
        case "system": return .gray
        default: return .white
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(typeColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(typeColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    StaffView()
        .environmentObject(AppStateManager.shared)
} 