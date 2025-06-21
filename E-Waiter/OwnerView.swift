import SwiftUI

struct OwnerView: View {
    @State private var showLogoutAlert = false
    @EnvironmentObject var appState: AppStateManager
    @State private var selectedTab = 0
    @State private var animateCards = false
    @State private var showWelcomeAnimation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.15),
                        Color(red: 0.1, green: 0.15, blue: 0.2)
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
                    Text("Owner Dashboard")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showWelcomeAnimation ? 1 : 0)
                        .offset(y: showWelcomeAnimation ? 0 : -20)
                    
                    Text("Restaurant Management System")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showWelcomeAnimation ? 1 : 0)
                        .offset(y: showWelcomeAnimation ? 0 : -10)
                }
                
                Spacer()
                
                // Stats cards
                HStack(spacing: 20) {
                    StatCard(title: "Orders", value: "24", icon: "list.bullet", color: .blue)
                    StatCard(title: "Revenue", value: "$1,234", icon: "dollarsign.circle", color: .green)
                    StatCard(title: "Staff", value: "8", icon: "person.2", color: .orange)
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
                    overviewTab
                case 1:
                    staffTab
                case 2:
                    tablesTab
                case 3:
                    analyticsTab
                default:
                    overviewTab
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        VStack(spacing: 30) {
            // Quick actions grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                ForEach(0..<6) { index in
                    QuickActionCard(
                        title: quickActionTitles[index],
                        subtitle: quickActionSubtitles[index],
                        icon: quickActionIcons[index],
                        color: quickActionColors[index]
                    )
                    .offset(y: animateCards ? 0 : 50)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
                }
            }
            
            // Recent activity
            RecentActivityView()
                .offset(y: animateCards ? 0 : 30)
                .opacity(animateCards ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: animateCards)
        }
    }
    
    // MARK: - Staff Tab
    private var staffTab: some View {
        VStack(spacing: 30) {
            // Staff management cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                ForEach(0..<4) { index in
                    StaffManagementCard(
                        title: staffTitles[index],
                        subtitle: staffSubtitles[index],
                        icon: staffIcons[index],
                        color: staffColors[index]
                    )
                    .offset(y: animateCards ? 0 : 50)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
                }
            }
        }
    }
    
    // MARK: - Tables Tab
    private var tablesTab: some View {
        VStack(spacing: 30) {
            // Table management
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                ForEach(0..<4) { index in
                    TableManagementCard(
                        title: tableTitles[index],
                        subtitle: tableSubtitles[index],
                        icon: tableIcons[index],
                        color: tableColors[index]
                    )
                    .offset(y: animateCards ? 0 : 50)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
                }
            }
        }
    }
    
    // MARK: - Analytics Tab
    private var analyticsTab: some View {
        VStack(spacing: 30) {
            // Analytics cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                ForEach(0..<4) { index in
                    AnalyticsCard(
                        title: analyticsTitles[index],
                        subtitle: analyticsSubtitles[index],
                        icon: analyticsIcons[index],
                        color: analyticsColors[index]
                    )
                    .offset(y: animateCards ? 0 : 50)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.1), value: animateCards)
                }
            }
        }
    }
    
    // MARK: - Data Arrays
    private let tabIcons = ["house.fill", "person.2.fill", "table.furniture", "chart.bar.fill"]
    private let tabTitles = ["Overview", "Staff", "Tables", "Analytics"]
    
    private let quickActionTitles = ["New Order", "Add Staff", "Menu Update", "View Reports", "Settings", "Notifications"]
    private let quickActionSubtitles = ["Create order", "Hire new staff", "Update menu", "View analytics", "Configure", "Check alerts"]
    private let quickActionIcons = ["plus.circle", "person.badge.plus", "doc.text", "chart.bar", "gear", "bell"]
    private let quickActionColors: [Color] = [.blue, .green, .orange, .purple, .gray, .red]
    
    private let staffTitles = ["Add Staff", "Schedule", "Performance", "Payroll"]
    private let staffSubtitles = ["Hire new employees", "Manage shifts", "Track performance", "Handle payments"]
    private let staffIcons = ["person.badge.plus", "calendar", "chart.line.uptrend.xyaxis", "dollarsign.circle"]
    private let staffColors: [Color] = [.green, .blue, .orange, .purple]
    
    private let tableTitles = ["Add Table", "Layout", "Status", "Reservations"]
    private let tableSubtitles = ["Add new table", "Manage layout", "Check status", "Handle bookings"]
    private let tableIcons = ["plus.rectangle", "square.grid.3x3", "circle.fill", "calendar.badge.clock"]
    private let tableColors: [Color] = [.green, .blue, .orange, .purple]
    
    private let analyticsTitles = ["Sales Report", "Customer Data", "Trends", "Forecasting"]
    private let analyticsSubtitles = ["View sales data", "Customer insights", "Market trends", "Future predictions"]
    private let analyticsIcons = ["chart.bar.fill", "person.3.fill", "chart.line.uptrend.xyaxis", "crystal.ball"]
    private let analyticsColors: [Color] = [.blue, .green, .orange, .purple]
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 100, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(24)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                // Handle tap
            }
        }
    }
}

struct StaffManagementCard: View {
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

struct TableManagementCard: View {
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

struct AnalyticsCard: View {
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

struct RecentActivityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Activity")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ForEach(0..<5) { index in
                    HStack {
                        Circle()
                            .fill(activityColors[index])
                            .frame(width: 8, height: 8)
                        
                        Text(activityItems[index])
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        Text(activityTimes[index])
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.03))
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private let activityItems = [
        "New order received - Table 5",
        "Staff member John clocked in",
        "Menu item 'Pasta Carbonara' updated",
        "Payment processed - $45.50",
        "Table 3 reservation confirmed"
    ]
    
    private let activityTimes = ["2 min ago", "5 min ago", "12 min ago", "15 min ago", "23 min ago"]
    
    private let activityColors: [Color] = [.green, .blue, .orange, .purple, .red]
}

#Preview {
    OwnerView()
        .environmentObject(AppStateManager.shared)
} 