import SwiftUI

struct TableView: View {
    @State private var showLogoutAlert = false
    @EnvironmentObject var appState: AppStateManager
    @State private var selectedCategory = 0
    @State private var animateCards = false
    @State private var showWelcomeAnimation = false
    @State private var cartItems: [CartItem] = []
    @State private var showCart = false
    @StateObject private var menuManager = MenuManager()
    @State private var isLoading = false
    @State private var showDishDetail = false
    @State private var selectedDish: MenuDish?
    
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
                
                // Dish detail overlay
                if showDishDetail, let dish = selectedDish {
                    dishDetailOverlay(dish: dish)
                }
            }
        }
        .onAppear {
            // Initialize restaurant ID if needed
            if let storedRestaurantId = UserDefaults.standard.string(forKey: "currentRestaurantId") {
                menuManager.setRestaurantId(storedRestaurantId)
            }
            
            loadMenuData()
            
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
        .alert("Error", isPresented: .constant(!menuManager.errorMessage.isEmpty)) {
            Button("OK") {
                menuManager.errorMessage = ""
            }
        } message: {
            Text(menuManager.errorMessage)
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
                ForEach(Array(menuManager.categories.enumerated()), id: \.element.id) { index, category in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCategory = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(selectedCategory == index ? .white : .white.opacity(0.6))
                            
                            Text(category.name)
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
                if isLoading {
                    loadingView
                } else if menuManager.categories.isEmpty {
                    emptyMenuView
                } else {
                    // Menu items grid
                    let dishesForCategory = getDishesForSelectedCategory()
                    if dishesForCategory.isEmpty {
                        emptyCategoryView
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                            ForEach(dishesForCategory, id: \.id) { dish in
                                MenuItemCard(
                                    item: convertDishToMenuItem(dish),
                                    onAddToCart: {
                                        addToCart(convertDishToMenuItem(dish))
                                    },
                                    onTap: {
                                        selectedDish = dish
                                        showDishDetail = true
                                    }
                                )
                                .offset(y: animateCards ? 0 : 50)
                                .opacity(animateCards ? 1 : 0)
                                .animation(.easeOut(duration: 0.6).delay(Double(dishesForCategory.firstIndex(where: { $0.id == dish.id }) ?? 0) * 0.1), value: animateCards)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Cart Overlay
    private func dishDetailOverlay(dish: MenuDish) -> some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDishDetail = false
                        selectedDish = nil
                    }
                }
            
            // Dish detail content
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button("Close") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDishDetail = false
                            selectedDish = nil
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("Dish Details")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Add to Cart") {
                        addToCart(convertDishToMenuItem(dish))
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showDishDetail = false
                            selectedDish = nil
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                }
                .padding(24)
                .background(Color.white.opacity(0.1))
                
                // Dish content
                ScrollView {
                    VStack(spacing: 24) {
                        // Dish image
                        if let imageURL = dish.imageURL, !imageURL.isEmpty {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(16)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 250)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    )
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 250)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: "fork.knife.circle")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white.opacity(0.5))
                                        Text("No Image Available")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                )
                        }
                        
                        // Dish information
                        VStack(spacing: 20) {
                            // Title and price
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(dish.name)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(dish.categoryName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Text("$\(String(format: "%.2f", dish.price))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            
                            // Description
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text(dish.description)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(nil)
                            }
                            
                            // Preparation time
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.orange)
                                
                                Text("Preparation Time: \(dish.preparationTime) minutes")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Spacer()
                            }
                            
                            // Availability status
                            HStack {
                                Image(systemName: dish.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(dish.isAvailable ? .green : .red)
                                
                                Text(dish.isAvailable ? "Available" : "Currently Unavailable")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(dish.isAvailable ? .green : .red)
                                
                                Spacer()
                            }
                            
                            // Allergens
                            if !dish.allergens.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Allergens")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                                        ForEach(dish.allergens, id: \.self) { allergen in
                                            HStack {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.orange)
                                                
                                                Text(allergen)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.8))
                                                
                                                Spacer()
                                            }
                                            .padding(8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.orange.opacity(0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: 500, maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.1, green: 0.15, blue: 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .offset(y: showDishDetail ? 0 : 1000)
            .animation(.easeInOut(duration: 0.3), value: showDishDetail)
        }
    }
    
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
    private func loadMenuData() {
        isLoading = true
        menuManager.loadMenuData { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    print("Menu data loaded successfully")
                } else {
                    print("Failed to load menu data")
                }
            }
        }
    }
    
    private func getDishesForSelectedCategory() -> [MenuDish] {
        guard selectedCategory < menuManager.categories.count else { return [] }
        let category = menuManager.categories[selectedCategory]
        return menuManager.getDishesForCategory(category.id)
    }
    
    private func convertDishToMenuItem(_ dish: MenuDish) -> MenuItem {
        return MenuItem(
            id: dish.id,
            name: dish.name,
            description: dish.description,
            price: dish.price,
            image: dish.imageURL ?? "🍽️"
        )
    }
    
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
    
    // MARK: - Loading and Empty States
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading menu...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyMenuView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Menu Available")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("The restaurant menu is currently being set up.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyCategoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Dishes in This Category")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("This category is empty. Check back later for new dishes!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    

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
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Item image and price
            HStack {
                if item.image.hasPrefix("http") {
                    // Load image from URL
                    AsyncImage(url: URL(string: item.image)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 60, height: 60)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            )
                    }
                } else {
                    // Use emoji or default icon
                    Text(item.image)
                        .font(.system(size: 40))
                }
                
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
            
            // Action buttons
            HStack(spacing: 12) {
                // View details button
                Button(action: onTap) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Details")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                // Add to cart button
                Button(action: onAddToCart) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Add to Cart")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                    )
                }
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
        .onTapGesture {
            onTap()
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: true)
    }
}

struct CartItemRow: View {
    let item: CartItem
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if item.menuItem.image.hasPrefix("http") {
                // Load image from URL
                AsyncImage(url: URL(string: item.menuItem.image)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipped()
                        .cornerRadius(6)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.6)
                        )
                }
            } else {
                // Use emoji or default icon
                Text(item.menuItem.image)
                    .font(.system(size: 30))
            }
            
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