import SwiftUI

struct TableView: View {
    @State private var showLogoutAlert = false
    @EnvironmentObject var appState: AppStateManager
    @State private var selectedCategory = 0
    @State private var animateCards = false
    @State private var showWelcomeAnimation = false
    @State private var cartItems: [CartItem] = []
    @State private var showCart = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.15, blue: 0.2),
                        Color(red: 0.15, green: 0.2, blue: 0.25)
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
                
                // Cart overlay
                if showCart {
                    cartOverlay
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
                    Text("Table Menu")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(showWelcomeAnimation ? 1 : 0)
                        .offset(y: showWelcomeAnimation ? 0 : -20)
                    
                    Text("Customer Ordering System")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showWelcomeAnimation ? 1 : 0)
                        .offset(y: showWelcomeAnimation ? 0 : -10)
                }
                
                Spacer()
                
                // Cart button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCart.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("Cart (\(cartItems.count))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if cartItems.count > 0 {
                            Text("$\(String(format: "%.2f", cartTotal))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .opacity(showWelcomeAnimation ? 1 : 0)
                .offset(x: showWelcomeAnimation ? 0 : 50)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            // Category tabs
            categoryTabsView
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
    
    // MARK: - Category Tabs
    private var categoryTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<categories.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCategory = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: categoryIcons[index])
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(selectedCategory == index ? .white : .white.opacity(0.6))
                            
                            Text(categories[index])
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedCategory == index ? .white : .white.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedCategory == index ? Color.white.opacity(0.15) : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedCategory == index ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Main Content
    private func mainContentView(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 30) {
                // Menu items grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                    ForEach(menuItems[selectedCategory], id: \.id) { item in
                        MenuItemCard(
                            item: item,
                            onAddToCart: {
                                addToCart(item)
                            }
                        )
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(Double(menuItems[selectedCategory].firstIndex(where: { $0.id == item.id }) ?? 0) * 0.1), value: animateCards)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Cart Overlay
    private var cartOverlay: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCart = false
                    }
                }
            
            // Cart content
            VStack(spacing: 0) {
                // Cart header
                HStack {
                    Text("Your Cart")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Close") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showCart = false
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(24)
                .background(Color.white.opacity(0.1))
                
                // Cart items
                if cartItems.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Your cart is empty")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(cartItems.indices, id: \.self) { index in
                                CartItemRow(
                                    item: cartItems[index],
                                    onIncrement: {
                                        cartItems[index].quantity += 1
                                    },
                                    onDecrement: {
                                        if cartItems[index].quantity > 1 {
                                            cartItems[index].quantity -= 1
                                        } else {
                                            cartItems.remove(at: index)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(24)
                    }
                }
                
                // Cart footer
                if !cartItems.isEmpty {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Total:")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", cartTotal))")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)
                        }
                        
                        Button("Place Order") {
                            // Handle order placement
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.1))
                }
            }
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.15, blue: 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .offset(y: showCart ? 0 : 1000)
            .animation(.easeInOut(duration: 0.3), value: showCart)
        }
    }
    
    // MARK: - Helper Methods
    private func addToCart(_ item: MenuItem) {
        if let existingIndex = cartItems.firstIndex(where: { $0.menuItem.id == item.id }) {
            cartItems[existingIndex].quantity += 1
        } else {
            cartItems.append(CartItem(menuItem: item, quantity: 1))
        }
    }
    
    private var cartTotal: Double {
        cartItems.reduce(0) { $0 + ($1.menuItem.price * Double($1.quantity)) }
    }
    
    // MARK: - Data Arrays
    private let categories = ["Appetizers", "Main Courses", "Beverages", "Desserts", "Specials"]
    private let categoryIcons = ["fork.knife", "leaf.fill", "cup.and.saucer.fill", "birthday.cake.fill", "star.fill"]
    
    private let menuItems: [[MenuItem]] = [
        // Appetizers
        [
            MenuItem(id: "app1", name: "Bruschetta", description: "Toasted bread with tomatoes, garlic, and basil", price: 8.99, image: "🍅"),
            MenuItem(id: "app2", name: "Mozzarella Sticks", description: "Crispy breaded mozzarella with marinara", price: 7.99, image: "🧀"),
            MenuItem(id: "app3", name: "Garlic Bread", description: "Fresh baked bread with garlic butter", price: 4.99, image: "🍞"),
            MenuItem(id: "app4", name: "Soup of the Day", description: "Chef's daily special soup", price: 6.99, image: "🥣")
        ],
        // Main Courses
        [
            MenuItem(id: "main1", name: "Pasta Carbonara", description: "Spaghetti with eggs, cheese, and pancetta", price: 16.99, image: "🍝"),
            MenuItem(id: "main2", name: "Pizza Margherita", description: "Fresh mozzarella, tomato, and basil", price: 14.99, image: "🍕"),
            MenuItem(id: "main3", name: "Grilled Salmon", description: "Atlantic salmon with seasonal vegetables", price: 24.99, image: "🐟"),
            MenuItem(id: "main4", name: "Beef Tenderloin", description: "8oz tenderloin with mashed potatoes", price: 28.99, image: "🥩")
        ],
        // Beverages
        [
            MenuItem(id: "bev1", name: "Fresh Lemonade", description: "Homemade lemonade with mint", price: 4.99, image: "🍋"),
            MenuItem(id: "bev2", name: "Iced Tea", description: "House blend iced tea", price: 3.99, image: "🥤"),
            MenuItem(id: "bev3", name: "Espresso", description: "Single shot of premium espresso", price: 3.50, image: "☕"),
            MenuItem(id: "bev4", name: "Red Wine", description: "Glass of house red wine", price: 8.99, image: "🍷")
        ],
        // Desserts
        [
            MenuItem(id: "des1", name: "Tiramisu", description: "Classic Italian coffee-flavored dessert", price: 8.99, image: "🍰"),
            MenuItem(id: "des2", name: "Chocolate Lava Cake", description: "Warm chocolate cake with vanilla ice cream", price: 9.99, image: "🍫"),
            MenuItem(id: "des3", name: "Cheesecake", description: "New York style cheesecake", price: 7.99, image: "🧀"),
            MenuItem(id: "des4", name: "Gelato", description: "Three scoops of Italian gelato", price: 6.99, image: "🍨")
        ],
        // Specials
        [
            MenuItem(id: "sp1", name: "Chef's Special", description: "Today's chef-recommended dish", price: 22.99, image: "👨‍🍳"),
            MenuItem(id: "sp2", name: "Wine Pairing", description: "Three-course meal with wine", price: 45.99, image: "🍷"),
            MenuItem(id: "sp3", name: "Family Platter", description: "Serves 4-6 people", price: 39.99, image: "👨‍👩‍👧‍👦"),
            MenuItem(id: "sp4", name: "Date Night", description: "Romantic dinner for two", price: 59.99, image: "💕")
        ]
    ]
}

// MARK: - Data Models
struct MenuItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let image: String
}

struct CartItem: Identifiable {
    let id = UUID()
    let menuItem: MenuItem
    var quantity: Int
}

// MARK: - Supporting Views
struct MenuItemCard: View {
    let item: MenuItem
    let onAddToCart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Item image and price
            HStack {
                Text(item.image)
                    .font(.system(size: 40))
                
                Spacer()
                
                Text("$\(String(format: "%.2f", item.price))")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(item.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            // Add to cart button
            Button(action: onAddToCart) {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Add to Cart")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green)
                )
            }
        }
        .padding(20)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Text(item.menuItem.image)
                .font(.system(size: 30))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.menuItem.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("$\(String(format: "%.2f", item.menuItem.price))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Quantity controls
            HStack(spacing: 12) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.3))
                        )
                }
                
                Text("\(item.quantity)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minWidth: 30)
                
                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.3))
                        )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

#Preview {
    TableView()
        .environmentObject(AppStateManager.shared)
} 